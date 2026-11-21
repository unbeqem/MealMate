import type { Allergen, Diet, DietClass, Ingredient, Preferences, Recipe } from './types.ts';

const CLASS_RANK: Record<DietClass, number> = { vegan: 0, vegetarian: 1, pescetarian: 2, meat: 3 };
const DIET_MAX: Record<Diet, number> = { vegan: 0, vegetarian: 1, pescetarian: 2, flexitarian: 3, omnivore: 3 };

export type IngredientIndex = ReadonlyMap<string, Ingredient>;

export function indexIngredients(list: readonly Ingredient[]): Map<string, Ingredient> {
  return new Map(list.map((i) => [i.id, i]));
}

/** Diet class of a recipe, derived from its ingredients (never from tags). */
export function recipeDietClass(recipe: Recipe, ings: IngredientIndex): DietClass {
  let rank = 0;
  for (const ri of recipe.ingredients) {
    const ing = ings.get(ri.ingredientId);
    if (ing) rank = Math.max(rank, CLASS_RANK[ing.dietClass]);
  }
  return (Object.keys(CLASS_RANK) as DietClass[]).find((k) => CLASS_RANK[k] === rank)!;
}

/** All allergens of a recipe, optional ingredients included (safety first). */
export function recipeAllergens(recipe: Recipe, ings: IngredientIndex): Allergen[] {
  const set = new Set<Allergen>();
  for (const ri of recipe.ingredients) ings.get(ri.ingredientId)?.allergens.forEach((a) => set.add(a));
  return [...set];
}

export type RejectReason = 'diet' | 'allergen' | 'dislike' | 'time' | 'unknown-ingredient';

/**
 * Hard filter. Unknown ingredients reject the recipe, because we cannot prove it is safe.
 */
export function checkRecipe(recipe: Recipe, ings: IngredientIndex, prefs: Preferences): RejectReason[] {
  const reasons: RejectReason[] = [];
  if (recipe.ingredients.some((ri) => !ings.has(ri.ingredientId))) reasons.push('unknown-ingredient');
  if (CLASS_RANK[recipeDietClass(recipe, ings)] > DIET_MAX[prefs.diet]) reasons.push('diet');
  if (prefs.allergens.length) {
    const al = recipeAllergens(recipe, ings);
    if (al.some((a) => prefs.allergens.includes(a))) reasons.push('allergen');
  }
  if (recipe.ingredients.some((ri) => !ri.optional && prefs.dislikes.includes(ri.ingredientId))) reasons.push('dislike');
  if (prefs.maxCookMinutes != null && recipe.prepMinutes > prefs.maxCookMinutes) reasons.push('time');
  return reasons;
}

export function isRecipeAllowed(recipe: Recipe, ings: IngredientIndex, prefs: Preferences): boolean {
  return checkRecipe(recipe, ings, prefs).length === 0;
}

export const ALLERGEN_LABELS: Record<Allergen, string> = {
  gluten: 'Gluten',
  krebstiere: 'Krebstiere',
  eier: 'Eier',
  fisch: 'Fisch',
  erdnuesse: 'Erdnüsse',
  soja: 'Soja',
  milch: 'Milch / Laktose',
  schalenfruechte: 'Schalenfrüchte (Nüsse)',
  sellerie: 'Sellerie',
  senf: 'Senf',
  sesam: 'Sesam',
  sulfite: 'Sulfite',
  lupinen: 'Lupinen',
  weichtiere: 'Weichtiere',
};

export const DIET_LABELS: Record<Diet, string> = {
  omnivore: 'Alles',
  flexitarian: 'Flexitarisch',
  pescetarian: 'Pescetarisch',
  vegetarian: 'Vegetarisch',
  vegan: 'Vegan',
};

export const DIET_CLASS_LABELS: Record<DietClass, string> = {
  vegan: 'Vegan',
  vegetarian: 'Vegetarisch',
  pescetarian: 'Mit Fisch',
  meat: 'Mit Fleisch',
};
