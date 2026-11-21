// POST { weekStart: "YYYY-MM-DD" }
// Server-side twin of the client calculation (same packages/core code, ADR-002):
// builds the list for the household's week, merges with the stored list, saves it.
import { buildShoppingList, indexIngredients, type PlanEntry, type ShoppingItem, type ShoppingList } from '../../../packages/core/src/index.ts';
import { cors, json, loadIngredients, loadPreferences, loadRecipes, serviceClient, userClient } from '../_shared/db.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  const db = userClient(req);
  const { data: auth } = await db.auth.getUser();
  if (!auth.user) return json({ error: 'Bitte melde dich an.' }, 401);

  const { weekStart } = await req.json().catch(() => ({}));
  if (!/^\d{4}-\d{2}-\d{2}$/.test(weekStart ?? '')) return json({ error: 'weekStart fehlt.' }, 400);

  const prefs = await loadPreferences(db, auth.user.id);
  const { data: plan } = await db.from('meal_plans').select('id, meal_plan_entries(*)').eq('household_id', prefs.householdId).eq('week_start', weekStart).maybeSingle();
  if (!plan) return json({ list: { items: [], generatedAt: new Date().toISOString() } });

  const entries: PlanEntry[] = (plan.meal_plan_entries ?? []).map((e: Record<string, unknown>) => ({
    id: e.id as string,
    date: e.date as string,
    slot: e.slot as PlanEntry['slot'],
    recipeId: e.recipe_id as string,
    servings: e.servings as number,
    leftoverOf: (e.is_leftover_of as string | null) ?? null,
  }));

  const [ingredients, recipes] = await Promise.all([loadIngredients(serviceClient()), loadRecipes(db)]);

  const { data: stored } = await db.from('shopping_lists').select('id, shopping_list_items(*)').eq('meal_plan_id', plan.id).maybeSingle();
  const previous: ShoppingList | null = stored
    ? { generatedAt: '', items: (stored.shopping_list_items ?? []).map(rowToItem) }
    : null;

  const list = buildShoppingList({ entries, recipes, ingredients: indexIngredients(ingredients), prefs, previous });

  const listId =
    stored?.id ??
    (await db.from('shopping_lists').insert({ household_id: prefs.householdId, meal_plan_id: plan.id }).select('id').single()).data!.id;

  await db.from('shopping_list_items').delete().eq('list_id', listId);
  if (list.items.length) {
    const { error } = await db.from('shopping_list_items').insert(list.items.map((i) => itemToRow(listId, i)));
    if (error) return json({ error: error.message }, 500);
  }
  await db.from('shopping_lists').update({ generated_at: list.generatedAt }).eq('id', listId);
  return json({ list });
});

function itemToRow(listId: string, i: ShoppingItem) {
  return {
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
  };
}

function rowToItem(r: Record<string, any>): ShoppingItem {
  return {
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
  };
}
