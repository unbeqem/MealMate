import { addDays, weekDays } from './dates.ts';
import { isRecipeAllowed, type IngredientIndex } from './filters.ts';
import { buildShoppingList } from './shopping.ts';
import type { MealCategory, PlanEntry, Preferences, Recipe, Slot } from './types.ts';

let counter = 0;
export function newId(prefix = 'e'): string {
  counter = (counter + 1) % 1e6;
  return `${prefix}_${Date.now().toString(36)}${counter.toString(36)}${Math.random().toString(36).slice(2, 6)}`;
}

export function entryAt(entries: readonly PlanEntry[], date: string, slot: Slot): PlanEntry | undefined {
  return entries.find((e) => e.date === date && e.slot === slot);
}

/** Which recipe categories fit a slot. */
export function categoriesForSlot(slot: Slot): MealCategory[] {
  if (slot === 'breakfast') return ['breakfast'];
  return ['lunch', 'dinner'];
}

/**
 * "Rest morgen Mittag": the cook entry gets extra servings, and the next day's
 * lunch becomes a leftover entry that creates no demand.
 */
export function planLeftover(entries: readonly PlanEntry[], cookEntryId: string, servings: number): PlanEntry[] {
  const cook = entries.find((e) => e.id === cookEntryId);
  if (!cook) return [...entries];
  const date = cook.slot === 'dinner' ? addDays(cook.date, 1) : cook.date;
  const slot: Slot = cook.slot === 'dinner' ? 'lunch' : 'dinner';
  const occupied = entryAt(entries, date, slot);
  const rest = entries.filter((e) => e !== occupied).map((e) => (e.id === cook.id ? { ...e, servings: e.servings + servings } : e));
  return [...rest, { id: newId(), date, slot, recipeId: cook.recipeId, servings, leftoverOf: cook.id }];
}

/** Removing an entry also removes leftover entries that depend on it and gives the servings back. */
export function removeEntry(entries: readonly PlanEntry[], id: string): PlanEntry[] {
  const target = entries.find((e) => e.id === id);
  if (!target) return [...entries];
  if (target.leftoverOf) {
    return entries
      .filter((e) => e.id !== id)
      .map((e) => (e.id === target.leftoverOf ? { ...e, servings: Math.max(1, e.servings - target.servings) } : e));
  }
  return entries.filter((e) => e.id !== id && e.leftoverOf !== id);
}

/** First free lunch/dinner slot on or after `from` within the week. */
export function findFreeSlot(entries: readonly PlanEntry[], week: string, from: string): { date: string; slot: Slot } | null {
  for (const date of weekDays(week)) {
    if (date < from) continue;
    for (const slot of ['dinner', 'lunch'] as Slot[]) if (!entryAt(entries, date, slot)) return { date, slot };
  }
  return null;
}

export interface AutofillInput {
  week: string;
  entries: readonly PlanEntry[];
  recipes: readonly Recipe[];
  ingredients: IngredientIndex;
  prefs: Preferences;
  /** deterministic tie-breaks (tests); defaults to Math.random */
  random?: () => number;
}

/**
 * Greedy week fill. For each empty dinner (and breakfast when wanted):
 *  1. hard filter (diet, allergens, dislikes, time)
 *  2. score = leftover synergy (uses packages already bought) + favourites − repetition
 *  3. when cooking for leftovers, the next day's lunch becomes a leftover entry.
 * Existing entries are never touched.
 */
export function autofillWeek(input: AutofillInput): PlanEntry[] {
  const { week, recipes, ingredients, prefs } = input;
  const rnd = input.random ?? Math.random;
  let entries = [...input.entries];
  const allowed = recipes.filter((r) => isRecipeAllowed(r, ingredients, prefs));
  const mains = allowed.filter((r) => r.category === 'dinner' || r.category === 'lunch');
  const breakfasts = allowed.filter((r) => r.category === 'breakfast');
  const favs = new Set(prefs.favoriteIngredients);

  const leftoverPool = (): Map<string, number> => {
    const list = buildShoppingList({ entries, recipes, ingredients, prefs });
    return new Map(list.items.filter((i) => i.leftoverBase > 0).map((i) => [i.ingredientId!, i.leftoverBase]));
  };

  const pick = (pool: Recipe[]): Recipe | undefined => {
    if (pool.length === 0) return undefined;
    const used = new Map<string, number>();
    entries.forEach((e) => used.set(e.recipeId, (used.get(e.recipeId) ?? 0) + 1));
    const left = leftoverPool();
    let best: Recipe | undefined;
    let bestScore = -Infinity;
    for (const r of pool) {
      const factor = prefs.householdSize / r.servings;
      let synergy = 0;
      for (const ri of r.ingredients) {
        const l = left.get(ri.ingredientId);
        if (l) synergy += Math.min(1, (ri.amountBase * factor) / l) * 3;
      }
      const fav = r.ingredients.filter((ri) => favs.has(ri.ingredientId)).length * 1.5;
      const repeat = (used.get(r.id) ?? 0) * 6;
      const s = synergy + fav - repeat + rnd() * 1.2;
      if (s > bestScore) {
        bestScore = s;
        best = r;
      }
    }
    return best;
  };

  for (const date of weekDays(week)) {
    if (prefs.includeBreakfast && !entryAt(entries, date, 'breakfast')) {
      const r = pick(breakfasts);
      if (r) entries.push({ id: newId(), date, slot: 'breakfast', recipeId: r.id, servings: prefs.householdSize });
    }
    if (!entryAt(entries, date, 'dinner')) {
      const r = pick(mains);
      if (!r) continue;
      const entry: PlanEntry = { id: newId(), date, slot: 'dinner', recipeId: r.id, servings: prefs.householdSize };
      entries.push(entry);
      const next = addDays(date, 1);
      if (prefs.cookForLeftovers && weekDays(week).includes(next) && !entryAt(entries, next, 'lunch')) {
        entries = planLeftover(entries, entry.id, prefs.householdSize);
      }
    }
  }
  return entries;
}
