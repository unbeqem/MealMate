import { choosePackages } from './packages.ts';
import { isRecipeAllowed, type IngredientIndex } from './filters.ts';
import { normalize } from './search.ts';
import type {
  Ingredient,
  LeftoverSuggestion,
  PlanEntry,
  Preferences,
  Recipe,
  ShoppingItem,
  ShoppingList,
} from './types.ts';

export interface Demand {
  ingredientId: string;
  amount: number;
  usedBy: Set<string>;
}

/** Step 1: sum up demand in base units. Leftover entries create no demand. */
export function computeDemand(
  entries: readonly PlanEntry[],
  recipes: ReadonlyMap<string, Recipe>,
): Map<string, Demand> {
  const demand = new Map<string, Demand>();
  for (const e of entries) {
    if (e.leftoverOf) continue;
    const r = recipes.get(e.recipeId);
    if (!r) continue;
    const factor = e.servings / r.servings;
    for (const ri of r.ingredients) {
      if (ri.optional) continue;
      const d = demand.get(ri.ingredientId) ?? { ingredientId: ri.ingredientId, amount: 0, usedBy: new Set() };
      d.amount += ri.amountBase * factor;
      d.usedBy.add(r.id);
      demand.set(ri.ingredientId, d);
    }
  }
  return demand;
}

/** Ingredients that keep for weeks (garlic, rice, onions …) are not waste when something is left. */
export const LONG_SHELF_LIFE_DAYS = 21;

/**
 * A leftover is worth acting on when it spoils soon (shelf life < 21 days),
 * is ≥ 15 % of what was bought and ≥ 30 g/ml or ≥ 1 piece.
 */
export function isRelevantLeftover(ing: Ingredient, leftover: number, purchase: number): boolean {
  if (leftover <= 0 || purchase <= 0) return false;
  if ((ing.shelfLifeDays ?? 0) >= LONG_SHELF_LIFE_DAYS) return false;
  const abs = ing.baseUnit === 'pcs' ? 1 : 30;
  return leftover >= abs && leftover / purchase >= 0.15;
}

/**
 * Recipes that use up a leftover best: allowed by preferences, not yet planned,
 * and whose need (at household servings) comes closest to the leftover without
 * exceeding it by more than 25 %.
 */
export function suggestForLeftover(
  ingredientId: string,
  leftover: number,
  recipes: readonly Recipe[],
  ings: IngredientIndex,
  prefs: Preferences,
  exclude: ReadonlySet<string>,
  limit = 3,
): LeftoverSuggestion[] {
  const out: (LeftoverSuggestion & { gap: number })[] = [];
  for (const r of recipes) {
    if (exclude.has(r.id) || r.category === 'snack') continue;
    const ri = r.ingredients.find((x) => x.ingredientId === ingredientId && !x.optional);
    if (!ri) continue;
    if (!isRecipeAllowed(r, ings, prefs)) continue;
    const uses = ri.amountBase * (prefs.householdSize / r.servings);
    if (uses > leftover * 1.25) continue;
    out.push({ recipeId: r.id, title: r.title, usesBase: Math.min(uses, leftover), gap: Math.abs(leftover - uses) });
  }
  return out
    .sort((a, b) => a.gap - b.gap || a.title.localeCompare(b.title, 'de'))
    .slice(0, limit)
    .map(({ gap: _gap, ...s }) => s);
}

export interface BuildInput {
  entries: readonly PlanEntry[];
  recipes: readonly Recipe[];
  ingredients: IngredientIndex;
  prefs: Preferences;
  previous?: ShoppingList | null;
  now?: string;
}

/** Steps 2–4: round to packages, compute leftovers + suggestions, merge with the previous list. */
export function buildShoppingList(input: BuildInput): ShoppingList {
  const { entries, recipes, ingredients, prefs, previous } = input;
  const recipeMap = new Map(recipes.map((r) => [r.id, r]));
  const demand = computeDemand(entries, recipeMap);
  const planned = new Set(entries.map((e) => e.recipeId));
  const prevByKey = new Map((previous?.items ?? []).map((i) => [i.key, i]));

  const items: ShoppingItem[] = [];
  for (const d of demand.values()) {
    const ing = ingredients.get(d.ingredientId);
    if (!ing) continue;
    const prev = prevByKey.get(ing.id);
    const required = round(d.amount, ing.baseUnit === 'pcs' ? 2 : 0);

    let packages: ShoppingItem['packages'] = [];
    let purchase: number;
    if (ing.isStaple) {
      purchase = 0;
    } else {
      const choice = choosePackages(ing.baseUnit === 'pcs' ? Math.ceil(required - 1e-9) : required, ing.packages);
      if (choice) {
        packages = choice.picks;
        purchase = choice.total;
      } else {
        purchase = ing.baseUnit === 'pcs' ? Math.ceil(required - 1e-9) : Math.ceil(required);
      }
    }
    if (prev?.manualOverride != null) purchase = prev.manualOverride;

    const leftover = ing.isStaple ? 0 : Math.max(0, round(purchase - required, ing.baseUnit === 'pcs' ? 2 : 0));
    const suggestions = isRelevantLeftover(ing, leftover, purchase)
      ? suggestForLeftover(ing.id, leftover, recipes, ingredients, prefs, planned)
      : [];

    items.push({
      key: ing.id,
      ingredientId: ing.id,
      label: ing.name,
      aisle: ing.aisle,
      unit: ing.baseUnit,
      requiredBase: required,
      packages,
      purchaseBase: purchase,
      leftoverBase: leftover,
      source: 'auto',
      manualOverride: prev?.manualOverride ?? null,
      checked: prev?.checked ?? false,
      checkedAt: prev?.checkedAt ?? null,
      assumedStock: !!ing.isStaple,
      orphaned: false,
      usedBy: [...d.usedBy],
      suggestions,
    });
  }

  // manual items always survive; checked auto items that are no longer needed survive as orphaned
  const autoKeys = new Set(items.map((i) => i.key));
  for (const prev of previous?.items ?? []) {
    if (autoKeys.has(prev.key)) continue;
    if (prev.source === 'manual') items.push({ ...prev });
    else if (prev.checked) items.push({ ...prev, orphaned: true, suggestions: [], usedBy: [] });
  }

  items.sort(compareItems);
  return { items, generatedAt: input.now ?? new Date().toISOString() };
}

export const AISLE_ORDER = [
  'obst_gemuese',
  'brot_backwaren',
  'kuehlregal',
  'fleisch_fisch',
  'trockenwaren',
  'konserven',
  'gewuerze_oele',
  'tiefkuehl',
  'suesses_snacks',
  'getraenke',
  'sonstiges',
] as const;

export const AISLE_LABELS: Record<(typeof AISLE_ORDER)[number], string> = {
  obst_gemuese: 'Obst & Gemüse',
  brot_backwaren: 'Brot & Backwaren',
  kuehlregal: 'Kühlregal',
  fleisch_fisch: 'Fleisch & Fisch',
  trockenwaren: 'Nudeln, Reis & Trockenes',
  konserven: 'Konserven & Gläser',
  gewuerze_oele: 'Gewürze & Öle',
  tiefkuehl: 'Tiefkühl',
  suesses_snacks: 'Süßes & Snacks',
  getraenke: 'Getränke',
  sonstiges: 'Sonstiges',
};

function compareItems(a: ShoppingItem, b: ShoppingItem): number {
  if (a.assumedStock !== b.assumedStock) return a.assumedStock ? 1 : -1;
  const ai = AISLE_ORDER.indexOf(a.aisle);
  const bi = AISLE_ORDER.indexOf(b.aisle);
  return ai - bi || a.label.localeCompare(b.label, 'de');
}

export function manualItem(label: string, aisle: ShoppingItem['aisle'] = 'sonstiges'): ShoppingItem {
  return {
    key: `manual:${normalize(label)}`,
    ingredientId: null,
    label: label.trim(),
    aisle,
    unit: 'pcs',
    requiredBase: 0,
    packages: [],
    purchaseBase: 0,
    leftoverBase: 0,
    source: 'manual',
    manualOverride: null,
    checked: false,
    checkedAt: null,
    assumedStock: false,
    orphaned: false,
    usedBy: [],
    suggestions: [],
  };
}

export function setChecked(list: ShoppingList, key: string, checked: boolean, now = new Date().toISOString()): ShoppingList {
  return {
    ...list,
    items: list.items.map((i) => (i.key === key ? { ...i, checked, checkedAt: checked ? now : null } : i)),
  };
}

/** Totals for the receipt footer: what is left over and not yet planned. */
export function leftoverSummary(list: ShoppingList): { open: number; planned: number } {
  let open = 0;
  let planned = 0;
  for (const i of list.items) {
    if (i.leftoverBase <= 0 || i.assumedStock) continue;
    if (i.suggestions.length) open++;
    else planned++;
  }
  return { open, planned };
}

function round(n: number, digits: number): number {
  const f = 10 ** digits;
  return Math.round(n * f) / f;
}
