import { describe, expect, it } from 'vitest';
import {
  DEFAULT_PREFERENCES,
  INGREDIENTS,
  RECIPES,
  autofillWeek,
  buildShoppingList,
  checkRecipe,
  choosePackages,
  computeDemand,
  formatBase,
  formatAmount,
  formatPicks,
  indexIngredients,
  isoWeek,
  manualItem,
  matchIngredient,
  planLeftover,
  removeEntry,
  scaleDisplay,
  searchIngredients,
  setChecked,
  toBase,
  weekStart,
  type PlanEntry,
  type Preferences,
} from './index.ts';

const ings = indexIngredients(INGREDIENTS);
const ing = (id: string) => ings.get(id)!;
const prefs: Preferences = { ...DEFAULT_PREFERENCES, householdSize: 2 };
const WEEK = '2026-11-23';

describe('seed data', () => {
  it('has unique ids and every recipe maps to known ingredients', () => {
    expect(new Set(INGREDIENTS.map((i) => i.id)).size).toBe(INGREDIENTS.length);
    expect(new Set(RECIPES.map((r) => r.id)).size).toBe(RECIPES.length);
    for (const r of RECIPES) for (const ri of r.ingredients) expect(ings.has(ri.ingredientId), `${r.id}/${ri.ingredientId}`).toBe(true);
  });
  it('every non-staple ingredient has at least one package size', () => {
    for (const i of INGREDIENTS) if (!i.isStaple) expect(i.packages.length, i.id).toBeGreaterThan(0);
  });
  it('has enough recipes per slot for a week', () => {
    expect(RECIPES.filter((r) => r.category === 'breakfast').length).toBeGreaterThanOrEqual(5);
    expect(RECIPES.filter((r) => r.category !== 'breakfast').length).toBeGreaterThanOrEqual(25);
  });
});

describe('units', () => {
  it('converts kitchen units to base units', () => {
    expect(toBase(ing('olivenoel'), 2, 'EL')).toBe(30);
    expect(toBase(ing('knoblauch'), 1, 'Knolle')).toBe(10);
    expect(toBase(ing('dosentomaten'), 2, 'Dose')).toBe(800);
    expect(toBase(ing('moehre'), 2, 'Stk')).toBe(160);
    expect(toBase(ing('honig'), 1, 'EL')).toBeCloseTo(21);
    expect(toBase(ing('petersilie'), 1, 'Bund')).toBe(1);
  });
  it('throws on impossible conversions', () => {
    expect(() => toBase(ing('blattspinat'), 1, 'Bund')).toThrow();
  });
  it('formats amounts for humans', () => {
    expect(formatBase(450, 'g')).toBe('450 g');
    expect(formatBase(1250, 'g')).toBe('1,25 kg');
    expect(formatBase(3, 'pcs')).toBe('3 Stk');
    expect(formatAmount(ing('knoblauch'), 15)).toBe('15 Zehen');
    expect(formatAmount(ing('petersilie'), 0.5)).toBe('0,5 Bund');
    expect(formatPicks(ing('blattspinat'), [{ count: 3, amount: 450 }])).toBe('3 × 450 g');
    expect(formatPicks(ing('paprika'), [{ count: 1, amount: 3 }, { count: 2, amount: 1 }])).toBe('1 × 3 Stk · 2 Stk lose');
  });
  it('scales display amounts kitchen-friendly', () => {
    expect(scaleDisplay(250, 'g', 1.5)).toBe(375);
    expect(scaleDisplay(1, 'EL', 1.5)).toBe(1.5);
    expect(scaleDisplay(2, 'Stk', 0.5)).toBe(1);
  });
});

describe('choosePackages', () => {
  const eggs = ing('eier').packages;
  it('rounds up to the smallest total', () => {
    expect(choosePackages(4, eggs)!.total).toBe(6);
    expect(choosePackages(7, eggs)!.total).toBe(10);
    expect(choosePackages(11, eggs)!.total).toBe(12); // 2×6 beats 10+6
    expect(choosePackages(12, eggs)!.picks).toEqual([{ sizeId: 'eier-6', label: 'Packung 6 Stk', amount: 6, count: 2 }]);
  });
  it('prefers fewer packages on equal totals', () => {
    const c = choosePackages(16, eggs)!;
    expect(c.total).toBe(16);
    expect(c.picks.reduce((n, p) => n + p.count, 0)).toBe(2);
  });
  it('returns null without sizes and nothing for zero need', () => {
    expect(choosePackages(5, [])).toBeNull();
    expect(choosePackages(0, eggs)!.total).toBe(0);
  });
});

describe('filters', () => {
  const pasta = RECIPES.find((r) => r.id === 'spinat-feta-pasta')!;
  const chili = RECIPES.find((r) => r.id === 'chili-con-carne')!;
  it('derives diet from ingredients', () => {
    expect(checkRecipe(pasta, ings, { ...prefs, diet: 'vegetarian' })).toEqual([]);
    expect(checkRecipe(pasta, ings, { ...prefs, diet: 'vegan' })).toContain('diet');
    expect(checkRecipe(chili, ings, { ...prefs, diet: 'pescetarian' })).toContain('diet');
  });
  it('filters allergens hard, including optional ingredients', () => {
    expect(checkRecipe(pasta, ings, { ...prefs, allergens: ['gluten'] })).toContain('allergen');
    const shakshuka = RECIPES.find((r) => r.id === 'shakshuka')!; // optional feta (milch)
    expect(checkRecipe(shakshuka, ings, { ...prefs, allergens: ['milch'] })).toContain('allergen');
  });
  it('rejects unknown ingredients', () => {
    expect(checkRecipe({ ...pasta, ingredients: [{ ingredientId: 'drachenfrucht-x', amountBase: 1, displayAmount: 1, displayUnit: 'Stk' }] }, ings, prefs)).toContain('unknown-ingredient');
  });
  it('respects dislikes and time', () => {
    expect(checkRecipe(pasta, ings, { ...prefs, dislikes: ['feta'] })).toContain('dislike');
    expect(checkRecipe(pasta, ings, { ...prefs, maxCookMinutes: 20 })).toContain('time');
  });
});

describe('shopping list', () => {
  const entries: PlanEntry[] = [
    { id: 'a', date: WEEK, slot: 'dinner', recipeId: 'spinat-feta-pasta', servings: 2 },
    { id: 'b', date: '2026-11-25', slot: 'dinner', recipeId: 'gnocchi-rahmspinat', servings: 2 },
  ];

  it('sums demand and ignores leftover entries', () => {
    const map = new Map(RECIPES.map((r) => [r.id, r]));
    const d = computeDemand([...entries, { id: 'c', date: '2026-11-24', slot: 'lunch', recipeId: 'spinat-feta-pasta', servings: 2, leftoverOf: 'a' }], map);
    expect(d.get('blattspinat')!.amount).toBe(450);
  });

  it('uses the spinach bag completely (200 g + 250 g = 450 g)', () => {
    const list = buildShoppingList({ entries, recipes: RECIPES, ingredients: ings, prefs, now: 'x' });
    const spinach = list.items.find((i) => i.key === 'blattspinat')!;
    expect(spinach.purchaseBase).toBe(450);
    expect(spinach.leftoverBase).toBe(0);
    expect(spinach.suggestions).toEqual([]);
  });

  it('reports a leftover with suggestions when only one recipe is planned', () => {
    const list = buildShoppingList({ entries: [entries[0]!], recipes: RECIPES, ingredients: ings, prefs, now: 'x' });
    const spinach = list.items.find((i) => i.key === 'blattspinat')!;
    expect(spinach.leftoverBase).toBe(250);
    expect(spinach.suggestions.length).toBeGreaterThan(0);
    expect(spinach.suggestions[0]!.recipeId).toBe('gnocchi-rahmspinat');
    expect(spinach.suggestions.every((s) => s.recipeId !== 'spinat-feta-pasta')).toBe(true);
  });

  it('scales by servings', () => {
    const list = buildShoppingList({ entries: [{ ...entries[0]!, servings: 4 }], recipes: RECIPES, ingredients: ings, prefs, now: 'x' });
    expect(list.items.find((i) => i.key === 'nudeln')!.requiredBase).toBe(500);
  });

  it('does not flag long-life leftovers (garlic keeps for weeks)', () => {
    const list = buildShoppingList({ entries: [entries[0]!], recipes: RECIPES, ingredients: ings, prefs, now: 'x' });
    const garlic = list.items.find((i) => i.key === 'knoblauch')!;
    expect(garlic.leftoverBase).toBe(8);
    expect(garlic.suggestions).toEqual([]);
  });

  it('marks staples as assumed stock and sorts them last', () => {
    const list = buildShoppingList({ entries, recipes: RECIPES, ingredients: ings, prefs, now: 'x' });
    const salt = list.items.find((i) => i.key === 'salz')!;
    expect(salt.assumedStock).toBe(true);
    expect(salt.purchaseBase).toBe(0);
    expect(list.items.at(-1)!.assumedStock).toBe(true);
  });

  it('keeps manual items, overrides and checks across recalculation', () => {
    const first = buildShoppingList({ entries, recipes: RECIPES, ingredients: ings, prefs, now: 'x' });
    let edited = setChecked(first, 'feta', true, 't');
    edited = { ...edited, items: [...edited.items.map((i) => (i.key === 'nudeln' ? { ...i, manualOverride: 1000 } : i)), manualItem('Spülmittel')] };
    const second = buildShoppingList({ entries: [entries[0]!], recipes: RECIPES, ingredients: ings, prefs, previous: edited, now: 'y' });
    expect(second.items.find((i) => i.key === 'manual:spuelmittel')).toBeTruthy();
    expect(second.items.find((i) => i.key === 'nudeln')!.purchaseBase).toBe(1000);
    expect(second.items.find((i) => i.key === 'feta')!.checked).toBe(true);
  });

  it('keeps checked items that are no longer needed as orphaned', () => {
    const first = setChecked(buildShoppingList({ entries, recipes: RECIPES, ingredients: ings, prefs, now: 'x' }), 'gnocchi', true);
    const second = buildShoppingList({ entries: [entries[0]!], recipes: RECIPES, ingredients: ings, prefs, previous: first, now: 'y' });
    const g = second.items.find((i) => i.key === 'gnocchi')!;
    expect(g.orphaned).toBe(true);
    expect(g.checked).toBe(true);
  });
});

describe('planner', () => {
  it('plans leftovers for the next lunch without extra demand', () => {
    const base: PlanEntry[] = [{ id: 'a', date: WEEK, slot: 'dinner', recipeId: 'dal', servings: 2 }];
    const out = planLeftover(base, 'a', 2);
    expect(out.find((e) => e.id === 'a')!.servings).toBe(4);
    const lo = out.find((e) => e.leftoverOf === 'a')!;
    expect(lo).toMatchObject({ date: '2026-11-24', slot: 'lunch', servings: 2 });
    const back = removeEntry(out, lo.id);
    expect(back.find((e) => e.id === 'a')!.servings).toBe(2);
    expect(removeEntry(out, 'a')).toEqual([]);
  });

  it('autofills a week respecting filters and preferring leftover synergy', () => {
    let seed = 1;
    const random = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
    const p: Preferences = { ...prefs, diet: 'vegetarian', allergens: ['fisch'], includeBreakfast: true };
    const out = autofillWeek({ week: WEEK, entries: [], recipes: RECIPES, ingredients: ings, prefs: p, random });
    const dinners = out.filter((e) => e.slot === 'dinner');
    expect(dinners).toHaveLength(7);
    expect(out.filter((e) => e.slot === 'breakfast')).toHaveLength(7);
    expect(out.filter((e) => e.leftoverOf).length).toBe(6); // Sunday's leftover would fall into next week
    for (const e of out) expect(checkRecipe(RECIPES.find((r) => r.id === e.recipeId)!, ings, p)).toEqual([]);
    expect(new Set(dinners.map((d) => d.recipeId)).size).toBeGreaterThanOrEqual(5);
  });

  it('never overwrites existing entries', () => {
    const fixed: PlanEntry = { id: 'x', date: WEEK, slot: 'dinner', recipeId: 'bolognese', servings: 2 };
    const out = autofillWeek({ week: WEEK, entries: [fixed], recipes: RECIPES, ingredients: ings, prefs });
    expect(out.find((e) => e.date === WEEK && e.slot === 'dinner')).toEqual(fixed);
  });
});

describe('dates & search', () => {
  it('computes week start and iso week', () => {
    expect(weekStart('2026-11-26')).toBe('2026-11-23');
    expect(isoWeek('2026-11-23')).toBe(48);
  });
  it('finds ingredients by alias, umlaut-tolerant', () => {
    expect(searchIngredients(INGREDIENTS, 'karotte')[0]!.id).toBe('moehre');
    expect(searchIngredients(INGREDIENTS, 'moehren')[0]!.id).toBe('moehre');
    expect(matchIngredient(INGREDIENTS, 'Spinat')!.id).toBe('blattspinat');
    expect(matchIngredient(INGREDIENTS, 'Drachenfrucht')).toBeNull();
  });
});
