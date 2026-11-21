// POST { prompt: string, servings?: number }
// Generates a recipe with the configured LLM, maps it onto the ingredient table,
// checks allergens/diet HARD against the database, saves it for the user.
import { checkRecipe, indexIngredients, matchIngredient, toBase, type Recipe } from '../_shared/core/index.ts';
import { cors, json, loadIngredients, loadPreferences, serviceClient, userClient } from '../_shared/db.ts';
import { createRecipeModel, RefusedError } from '../_shared/llm.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Nur POST' }, 405);

  const db = userClient(req);
  const { data: auth } = await db.auth.getUser();
  if (!auth.user) return json({ error: 'Bitte melde dich an.' }, 401);

  let body: { prompt?: string; servings?: number };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Ungültige Anfrage.' }, 400);
  }
  const prompt = (body.prompt ?? '').trim().slice(0, 500);
  if (prompt.length < 3) return json({ error: 'Beschreibe kurz, was du kochen möchtest.' }, 400);

  const admin = serviceClient();
  const [ingredients, prefs] = await Promise.all([loadIngredients(admin), loadPreferences(db, auth.user.id)]);
  const ings = indexIngredients(ingredients);
  const servings = Math.min(8, Math.max(1, body.servings ?? prefs.householdSize));
  const model = createRecipeModel();

  const log = (row: Record<string, unknown>) =>
    admin.from('ai_generations').insert({ user_id: auth.user!.id, provider: model.provider, model: model.model, prompt, constraints: { servings, diet: prefs.diet, allergens: prefs.allergens }, ...row });

  let raw;
  try {
    raw = await model.generate({
      prompt,
      servings,
      maxMinutes: prefs.maxCookMinutes,
      diet: prefs.diet,
      allergens: prefs.allergens,
      dislikes: prefs.dislikes.map((id) => ings.get(id)?.name ?? id),
      catalog: ingredients.map((i) => i.name),
    });
  } catch (e) {
    await log({ status: 'error', error: String(e) });
    const msg = e instanceof RefusedError ? e.message : 'Die KI ist gerade nicht erreichbar. Versuch es gleich noch einmal.';
    return json({ error: msg }, 502);
  }

  // Map ingredients; unknown ones are reported for review, never silently invented.
  const unmapped: string[] = [];
  const lines: Recipe['ingredients'] = [];
  for (const line of raw.ingredients) {
    const ing = matchIngredient(ingredients, line.name);
    if (!ing) {
      unmapped.push(line.name);
      continue;
    }
    if (lines.some((l) => l.ingredientId === ing.id)) continue;
    try {
      lines.push({ ingredientId: ing.id, amountBase: Math.round(toBase(ing, line.amount, line.unit) * 100) / 100, displayAmount: line.amount, displayUnit: line.unit, optional: line.optional });
    } catch {
      unmapped.push(`${line.name} (${line.unit})`);
    }
  }

  const recipe: Recipe = {
    id: crypto.randomUUID(),
    title: raw.title.slice(0, 120),
    description: raw.description.slice(0, 300),
    servings: Math.max(1, raw.servings),
    prepMinutes: Math.max(1, raw.prep_minutes),
    category: raw.category,
    tags: raw.tags.slice(0, 3),
    ingredients: lines,
    steps: raw.steps.slice(0, 10),
    source: 'ai',
  };

  // Safety: never trust the model on allergens or diet.
  const reasons = checkRecipe(recipe, ings, prefs).filter((r) => r === 'allergen' || r === 'diet');
  if (reasons.length) {
    await log({ status: 'rejected', raw_output: raw, unmapped_ingredients: unmapped, error: reasons.join(',') });
    return json({ error: 'Das erzeugte Rezept passt nicht zu deinen Allergien oder deiner Ernährungsform. Formuliere den Wunsch anders.' }, 422);
  }

  const { error: insErr } = await db.from('recipes').insert({
    id: recipe.id,
    title: recipe.title,
    description: recipe.description,
    servings: recipe.servings,
    prep_minutes: recipe.prepMinutes,
    category: recipe.category,
    tags: recipe.tags,
    instructions: recipe.steps,
    source: 'ai',
    created_by: auth.user.id,
    is_public: false,
    needs_review: unmapped.length > 0,
  });
  if (insErr) {
    await log({ status: 'error', raw_output: raw, error: insErr.message });
    return json({ error: 'Rezept konnte nicht gespeichert werden.' }, 500);
  }
  await db.from('recipe_ingredients').insert(
    recipe.ingredients.map((ri, position) => ({
      recipe_id: recipe.id,
      ingredient_id: ri.ingredientId,
      position,
      amount_base: ri.amountBase,
      display_amount: ri.displayAmount,
      display_unit: ri.displayUnit,
      optional: !!ri.optional,
    })),
  );
  await log({ status: 'saved', raw_output: raw, unmapped_ingredients: unmapped, recipe_id: recipe.id });

  return json({ recipe: { ...recipe, createdBy: auth.user.id }, unmapped });
});
