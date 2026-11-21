import type { Ingredient, PlanEntry, Preferences, Recipe, ShoppingList } from '@mealmate/core';

export interface StoredPreferences extends Preferences {
  onboarded: boolean;
}

export interface GenerateResult {
  recipe: Recipe;
  unmapped: string[];
}

/** All data access goes through this interface (ADR-003). */
export interface Repo {
  readonly mode: 'supabase' | 'guest';
  getCatalog(): Promise<{ ingredients: Ingredient[]; recipes: Recipe[] }>;
  getPreferences(): Promise<StoredPreferences>;
  savePreferences(prefs: StoredPreferences): Promise<void>;
  getPlan(week: string): Promise<PlanEntry[]>;
  savePlan(week: string, entries: PlanEntry[]): Promise<void>;
  getShoppingList(week: string): Promise<ShoppingList | null>;
  saveShoppingList(week: string, list: ShoppingList): Promise<void>;
  generateRecipe(prompt: string, servings: number): Promise<GenerateResult>;
}

export class RepoError extends Error {}
