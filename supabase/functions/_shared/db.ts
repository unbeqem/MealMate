import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@^2.50.0';
import type { Ingredient, Preferences, Recipe } from '../../../packages/core/src/index.ts';
import { DEFAULT_PREFERENCES } from '../../../packages/core/src/index.ts';

export const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });
}

/** Client acting as the calling user (RLS applies). */
export function userClient(req: Request): SupabaseClient {
  return createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
}

/** Service client (bypasses RLS) – only for reference data and logging. */
export function serviceClient(): SupabaseClient {
  return createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
}

export async function loadIngredients(db: SupabaseClient): Promise<Ingredient[]> {
  const [{ data: ings, error }, { data: aliases }, { data: packs }] = await Promise.all([
    db.from('ingredients').select('*'),
    db.from('ingredient_aliases').select('*'),
    db.from('package_sizes').select('*'),
  ]);
  if (error) throw error;
  return (ings ?? []).map((i) => ({
    id: i.id,
    name: i.name_de,
    aliases: (aliases ?? []).filter((a) => a.ingredient_id === i.id).map((a) => a.alias),
    baseUnit: i.base_unit,
    gramsPerPiece: i.grams_per_piece ?? undefined,
    densityGPerMl: i.density_g_per_ml ?? undefined,
    unitWeights: i.unit_weights ?? {},
    aisle: i.aisle,
    shelfLifeDays: i.shelf_life_days ?? undefined,
    allergens: i.allergens ?? [],
    dietClass: i.diet_class,
    isStaple: i.is_staple,
    packages: (packs ?? []).filter((p) => p.ingredient_id === i.id).map((p) => ({ id: p.id, amount: Number(p.amount), label: p.label })),
  }));
}

export async function loadRecipes(db: SupabaseClient): Promise<Recipe[]> {
  const { data, error } = await db.from('recipes').select('*, recipe_ingredients(*)');
  if (error) throw error;
  return (data ?? []).map((r) => ({
    id: r.id,
    title: r.title,
    description: r.description,
    servings: r.servings,
    prepMinutes: r.prep_minutes,
    category: r.category,
    tags: r.tags ?? [],
    steps: r.instructions ?? [],
    source: r.source,
    createdBy: r.created_by,
    ingredients: (r.recipe_ingredients ?? [])
      .sort((a: { position: number }, b: { position: number }) => a.position - b.position)
      .map((ri: Record<string, unknown>) => ({
        ingredientId: ri.ingredient_id as string,
        amountBase: Number(ri.amount_base),
        displayAmount: Number(ri.display_amount),
        displayUnit: ri.display_unit as string,
        optional: ri.optional as boolean,
      })),
  }));
}

export async function loadPreferences(db: SupabaseClient, userId: string): Promise<Preferences & { householdId: string }> {
  const { data: p, error } = await db.from('profiles').select('*').eq('id', userId).single();
  if (error) throw error;
  const { data: favs } = await db.from('favorite_ingredients').select('ingredient_id').eq('user_id', userId);
  return {
    ...DEFAULT_PREFERENCES,
    householdSize: p.household_size,
    diet: p.diet,
    allergens: p.allergens ?? [],
    dislikes: p.dislikes ?? [],
    favoriteIngredients: (favs ?? []).map((f) => f.ingredient_id),
    maxCookMinutes: p.max_cook_minutes,
    includeBreakfast: p.include_breakfast,
    cookForLeftovers: p.cook_for_leftovers,
    householdId: p.household_id,
  };
}
