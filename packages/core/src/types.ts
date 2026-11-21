export type BaseUnit = 'g' | 'ml' | 'pcs';

export type Aisle =
  | 'obst_gemuese'
  | 'brot_backwaren'
  | 'kuehlregal'
  | 'fleisch_fisch'
  | 'trockenwaren'
  | 'konserven'
  | 'gewuerze_oele'
  | 'tiefkuehl'
  | 'suesses_snacks'
  | 'getraenke'
  | 'sonstiges';

/** The 14 EU main allergens (LMIV Annex II). */
export type Allergen =
  | 'gluten'
  | 'krebstiere'
  | 'eier'
  | 'fisch'
  | 'erdnuesse'
  | 'soja'
  | 'milch'
  | 'schalenfruechte'
  | 'sellerie'
  | 'senf'
  | 'sesam'
  | 'sulfite'
  | 'lupinen'
  | 'weichtiere';

export type DietClass = 'vegan' | 'vegetarian' | 'pescetarian' | 'meat';
export type Diet = 'omnivore' | 'flexitarian' | 'pescetarian' | 'vegetarian' | 'vegan';

export interface PackageSize {
  id: string;
  /** amount in the ingredient's base unit */
  amount: number;
  label: string;
}

export interface Ingredient {
  id: string;
  name: string;
  aliases: string[];
  baseUnit: BaseUnit;
  gramsPerPiece?: number;
  densityGPerMl?: number;
  /** display unit → amount in base unit, e.g. { Zehe: 1, Knolle: 10 } */
  unitWeights?: Record<string, number>;
  aisle: Aisle;
  shelfLifeDays?: number;
  allergens: Allergen[];
  dietClass: DietClass;
  /** salt, pepper, oil … assumed to be in stock */
  isStaple?: boolean;
  packages: PackageSize[];
}

export type MealCategory = 'breakfast' | 'lunch' | 'dinner' | 'snack';
export type Slot = 'breakfast' | 'lunch' | 'dinner';
export const SLOTS: readonly Slot[] = ['breakfast', 'lunch', 'dinner'] as const;

export interface RecipeIngredient {
  ingredientId: string;
  amountBase: number;
  displayAmount: number;
  displayUnit: string;
  optional?: boolean;
}

export type RecipeSource = 'curated' | 'ai' | 'import' | 'user';

export interface Recipe {
  id: string;
  title: string;
  description: string;
  servings: number;
  prepMinutes: number;
  category: MealCategory;
  tags: string[];
  ingredients: RecipeIngredient[];
  steps: string[];
  source: RecipeSource;
  /** keeps a stable colour accent per recipe in the UI */
  hue?: number;
  createdBy?: string | null;
}

export interface PlanEntry {
  id: string;
  date: string; // YYYY-MM-DD
  slot: Slot;
  recipeId: string;
  servings: number;
  /** when set, this entry eats leftovers of another entry and creates no demand */
  leftoverOf?: string | null;
}

export interface Preferences {
  householdSize: number;
  diet: Diet;
  allergens: Allergen[];
  dislikes: string[]; // ingredient ids
  favoriteIngredients: string[];
  maxCookMinutes: number | null;
  includeBreakfast: boolean;
  cookForLeftovers: boolean;
}

export const DEFAULT_PREFERENCES: Preferences = {
  householdSize: 2,
  diet: 'omnivore',
  allergens: [],
  dislikes: [],
  favoriteIngredients: [],
  maxCookMinutes: null,
  includeBreakfast: false,
  cookForLeftovers: true,
};

export interface PackagePick {
  sizeId: string;
  label: string;
  amount: number;
  count: number;
}

export interface LeftoverSuggestion {
  recipeId: string;
  title: string;
  /** how much of the leftover the recipe uses at the household's servings */
  usesBase: number;
}

export interface ShoppingItem {
  /** stable merge key: ingredient id, or `manual:<normalized label>` */
  key: string;
  ingredientId: string | null;
  label: string;
  aisle: Aisle;
  unit: BaseUnit;
  requiredBase: number;
  packages: PackagePick[];
  purchaseBase: number;
  leftoverBase: number;
  source: 'auto' | 'manual';
  /** user-corrected purchase amount in base units; survives recalculation */
  manualOverride: number | null;
  checked: boolean;
  checkedAt: string | null;
  assumedStock: boolean;
  /** checked items that are no longer needed after recalculation are kept */
  orphaned: boolean;
  usedBy: string[];
  suggestions: LeftoverSuggestion[];
}

export interface ShoppingList {
  items: ShoppingItem[];
  generatedAt: string;
}
