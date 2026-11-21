import type { SupabaseClient } from '@supabase/supabase-js';
import {
  DEFAULT_PREFERENCES,
  type Ingredient,
  type PlanEntry,
  type Recipe,
  type ShoppingItem,
  type ShoppingList,
} from '@mealmate/core';
import { RepoError, type GenerateResult, type Repo, type StoredPreferences } from './repo';

/* eslint-disable @typescript-eslint/no-explicit-any */
type Row = Record<string, any>;

function fail(error: { message: string } | null, msg: string): void {
  if (error) throw new RepoError(`${msg}: ${error.message}`);
}

function mapRecipe(r: Row): Recipe {
  return {
    id: r.id,
    title: r.title,
    description: r.description ?? '',
    servings: r.servings,
    prepMinutes: r.prep_minutes,
    category: r.category,
    tags: r.tags ?? [],
    steps: r.instructions ?? [],
    source: r.source,
    createdBy: r.created_by,
    ingredients: [...(r.recipe_ingredients ?? [])]
      .sort((a: Row, b: Row) => a.position - b.position)
      .map((ri: Row) => ({
        ingredientId: ri.ingredient_id,
        amountBase: Number(ri.amount_base),
        displayAmount: Number(ri.display_amount),
        displayUnit: ri.display_unit,
        ...(ri.optional ? { optional: true } : {}),
      })),
  };
}

export function createSupabaseRepo(db: SupabaseClient, userId: string): Repo {
  let householdId: string | null = null;

  async function household(): Promise<string> {
    if (householdId) return householdId;
    const { data, error } = await db.from('profiles').select('household_id').eq('id', userId).single();
    fail(error, 'Profil nicht gefunden');
    householdId = data!.household_id as string;
    return householdId;
  }

  async function planId(week: string, create: boolean): Promise<string | null> {
    const hid = await household();
    const { data } = await db.from('meal_plans').select('id').eq('household_id', hid).eq('week_start', week).maybeSingle();
    if (data) return data.id as string;
    if (!create) return null;
    const ins = await db.from('meal_plans').insert({ household_id: hid, week_start: week }).select('id').single();
    fail(ins.error, 'Plan konnte nicht angelegt werden');
    return ins.data!.id as string;
  }

  return {
    mode: 'supabase',

    async getCatalog() {
      const [ings, aliases, packs, recipes] = await Promise.all([
        db.from('ingredients').select('*'),
        db.from('ingredient_aliases').select('*'),
        db.from('package_sizes').select('*'),
        db.from('recipes').select('*, recipe_ingredients(*)'),
      ]);
      fail(ings.error ?? recipes.error, 'Katalog konnte nicht geladen werden');
      const aliasBy = new Map<string, string[]>();
      for (const a of aliases.data ?? []) aliasBy.set(a.ingredient_id, [...(aliasBy.get(a.ingredient_id) ?? []), a.alias]);
      const packBy = new Map<string, Ingredient['packages']>();
      for (const p of packs.data ?? [])
        packBy.set(p.ingredient_id, [...(packBy.get(p.ingredient_id) ?? []), { id: p.id, amount: Number(p.amount), label: p.label }]);
      const ingredients: Ingredient[] = (ings.data ?? []).map((i: Row) => ({
        id: i.id,
        name: i.name_de,
        aliases: aliasBy.get(i.id) ?? [],
        baseUnit: i.base_unit,
        gramsPerPiece: i.grams_per_piece ?? undefined,
        densityGPerMl: i.density_g_per_ml ?? undefined,
        unitWeights: i.unit_weights ?? {},
        aisle: i.aisle,
        shelfLifeDays: i.shelf_life_days ?? undefined,
        allergens: i.allergens ?? [],
        dietClass: i.diet_class,
        isStaple: i.is_staple,
        packages: (packBy.get(i.id) ?? []).sort((a, b) => a.amount - b.amount),
      }));
      return { ingredients, recipes: (recipes.data ?? []).map(mapRecipe) };
    },

    async getPreferences() {
      const [{ data: p, error }, { data: favs }] = await Promise.all([
        db.from('profiles').select('*').eq('id', userId).single(),
        db.from('favorite_ingredients').select('ingredient_id').eq('user_id', userId),
      ]);
      fail(error, 'Profil konnte nicht geladen werden');
      householdId = p.household_id;
      return {
        ...DEFAULT_PREFERENCES,
        householdSize: p.household_size,
        diet: p.diet,
        allergens: p.allergens ?? [],
        dislikes: p.dislikes ?? [],
        favoriteIngredients: (favs ?? []).map((f: Row) => f.ingredient_id),
        maxCookMinutes: p.max_cook_minutes,
        includeBreakfast: p.include_breakfast,
        cookForLeftovers: p.cook_for_leftovers,
        onboarded: !!p.onboarded_at,
      } satisfies StoredPreferences;
    },

    async savePreferences(prefs) {
      const { error } = await db
        .from('profiles')
        .update({
          household_size: prefs.householdSize,
          diet: prefs.diet,
          allergens: prefs.allergens,
          dislikes: prefs.dislikes,
          max_cook_minutes: prefs.maxCookMinutes,
          include_breakfast: prefs.includeBreakfast,
          cook_for_leftovers: prefs.cookForLeftovers,
          onboarded_at: prefs.onboarded ? new Date().toISOString() : null,
        })
        .eq('id', userId);
      fail(error, 'Einstellungen konnten nicht gespeichert werden');
      await db.from('favorite_ingredients').delete().eq('user_id', userId);
      if (prefs.favoriteIngredients.length)
        await db.from('favorite_ingredients').insert(prefs.favoriteIngredients.map((ingredient_id) => ({ user_id: userId, ingredient_id })));
    },

    async getPlan(week) {
      const id = await planId(week, false);
      if (!id) return [];
      const { data, error } = await db.from('meal_plan_entries').select('*').eq('meal_plan_id', id);
      fail(error, 'Plan konnte nicht geladen werden');
      return (data ?? []).map((e: Row) => ({
        id: e.id,
        date: e.date,
        slot: e.slot,
        recipeId: e.recipe_id,
        servings: e.servings,
        leftoverOf: e.is_leftover_of,
      }));
    },

    async savePlan(week, entries) {
      const id = (await planId(week, true))!;
      const del = await db.from('meal_plan_entries').delete().eq('meal_plan_id', id);
      fail(del.error, 'Plan konnte nicht gespeichert werden');
      const toRow = (e: PlanEntry) => ({
        id: e.id,
        meal_plan_id: id,
        date: e.date,
        slot: e.slot,
        recipe_id: e.recipeId,
        servings: e.servings,
        is_leftover_of: e.leftoverOf ?? null,
      });
      // cook entries first: leftover rows reference them
      const cooks = entries.filter((e) => !e.leftoverOf).map(toRow);
      const leftovers = entries.filter((e) => e.leftoverOf).map(toRow);
      if (cooks.length) fail((await db.from('meal_plan_entries').insert(cooks)).error, 'Plan konnte nicht gespeichert werden');
      if (leftovers.length) fail((await db.from('meal_plan_entries').insert(leftovers)).error, 'Reste konnten nicht gespeichert werden');
      await db.from('meal_plans').update({ updated_at: new Date().toISOString() }).eq('id', id);
    },

    async getShoppingList(week) {
      const id = await planId(week, false);
      if (!id) return null;
      const { data } = await db.from('shopping_lists').select('generated_at, shopping_list_items(*)').eq('meal_plan_id', id).maybeSingle();
      if (!data) return null;
      return {
        generatedAt: data.generated_at,
        items: (data.shopping_list_items ?? []).map(
          (r: Row): ShoppingItem => ({
            key: r.key,
            ingredientId: r.ingredient_id,
            label: r.label,
            aisle: r.aisle,
            unit: r.unit,
            requiredBase: Number(r.required_base),
            packages: r.packages ?? [],
            purchaseBase: Number(r.purchase_base),
            leftoverBase: Number(r.leftover_base),
            source: r.source,
            manualOverride: r.manual_override == null ? null : Number(r.manual_override),
            checked: r.checked,
            checkedAt: r.checked_at,
            assumedStock: r.assumed_stock,
            orphaned: r.orphaned,
            usedBy: r.used_by ?? [],
            suggestions: r.leftover_suggestion ?? [],
          }),
        ),
      };
    },

    async saveShoppingList(week, list: ShoppingList) {
      const pid = (await planId(week, true))!;
      const hid = await household();
      const up = await db
        .from('shopping_lists')
        .upsert({ household_id: hid, meal_plan_id: pid, generated_at: list.generatedAt }, { onConflict: 'meal_plan_id' })
        .select('id')
        .single();
      fail(up.error, 'Liste konnte nicht gespeichert werden');
      const listId = up.data!.id;
      await db.from('shopping_list_items').delete().eq('list_id', listId);
      if (!list.items.length) return;
      const ins = await db.from('shopping_list_items').insert(
        list.items.map((i) => ({
          list_id: listId,
          key: i.key,
          ingredient_id: i.ingredientId,
          custom_name: i.ingredientId ? null : i.label,
          label: i.label,
          aisle: i.aisle,
          unit: i.unit,
          required_base: i.requiredBase,
          packages: i.packages,
          purchase_base: i.purchaseBase,
          leftover_base: i.leftoverBase,
          source: i.source,
          manual_override: i.manualOverride,
          checked: i.checked,
          checked_at: i.checkedAt,
          assumed_stock: i.assumedStock,
          orphaned: i.orphaned,
          used_by: i.usedBy,
          leftover_suggestion: i.suggestions,
        })),
      );
      fail(ins.error, 'Liste konnte nicht gespeichert werden');
    },

    async generateRecipe(prompt, servings): Promise<GenerateResult> {
      const { data, error } = await db.functions.invoke('generate-recipe', { body: { prompt, servings } });
      if (error) {
        let msg = 'Die KI ist gerade nicht erreichbar.';
        try {
          const body = await (error as { context?: Response }).context?.json();
          if (body?.error) msg = body.error;
        } catch {
          /* keep default */
        }
        throw new RepoError(msg);
      }
      return data as GenerateResult;
    },
  };
}
