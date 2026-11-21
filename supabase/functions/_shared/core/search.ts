import type { Ingredient, Recipe } from './types.ts';

/** lower-case, umlauts folded, whitespace collapsed: "Möhren " → "moehren" */
export function normalize(s: string): string {
  return s
    .toLowerCase()
    .replace(/ä/g, 'ae')
    .replace(/ö/g, 'oe')
    .replace(/ü/g, 'ue')
    .replace(/ß/g, 'ss')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function score(hay: string, q: string): number {
  if (hay === q) return 100;
  if (hay.startsWith(q)) return 80;
  if (hay.split(/[\s-]/).some((w) => w.startsWith(q))) return 60;
  if (hay.includes(q)) return 40;
  return 0;
}

export function searchIngredients(list: readonly Ingredient[], query: string, limit = 20): Ingredient[] {
  const q = normalize(query);
  if (!q) return list.slice(0, limit);
  return list
    .map((ing) => ({
      ing,
      s: Math.max(score(normalize(ing.name), q), ...ing.aliases.map((a) => score(normalize(a), q) - 5)),
    }))
    .filter((x) => x.s > 0)
    .sort((a, b) => b.s - a.s || a.ing.name.localeCompare(b.ing.name, 'de'))
    .slice(0, limit)
    .map((x) => x.ing);
}

/** Maps a free-text ingredient name (e.g. from an LLM) to a known ingredient. */
export function matchIngredient(list: readonly Ingredient[], name: string): Ingredient | null {
  const q = normalize(name);
  for (const ing of list) {
    if (normalize(ing.name) === q || ing.aliases.some((a) => normalize(a) === q)) return ing;
  }
  const best = searchIngredients(list, q, 1)[0];
  return best && normalize(best.name).length >= 3 && (normalize(best.name).startsWith(q) || q.startsWith(normalize(best.name)))
    ? best
    : null;
}

export function searchRecipes(
  list: readonly Recipe[],
  query: string,
  ingredientName: (id: string) => string,
): Recipe[] {
  const q = normalize(query);
  if (!q) return [...list];
  return list
    .map((r) => {
      const t = score(normalize(r.title), q);
      const i = Math.max(0, ...r.ingredients.map((ri) => score(normalize(ingredientName(ri.ingredientId)), q) - 20));
      const tag = Math.max(0, ...r.tags.map((tg) => score(normalize(tg), q) - 30));
      return { r, s: Math.max(t, i, tag) };
    })
    .filter((x) => x.s > 0)
    .sort((a, b) => b.s - a.s)
    .map((x) => x.r);
}
