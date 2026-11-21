import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useMemo } from 'react';
import {
  buildShoppingList,
  indexIngredients,
  isRecipeAllowed,
  type Ingredient,
  type PlanEntry,
  type Recipe,
  type ShoppingList,
} from '@mealmate/core';
import { useRepo, useSession } from '@/state/session';
import type { StoredPreferences } from './repo';

const keys = {
  catalog: (s: string) => ['catalog', s] as const,
  prefs: (s: string) => ['prefs', s] as const,
  plan: (s: string, w: string) => ['plan', s, w] as const,
  list: (s: string, w: string) => ['list', s, w] as const,
};

export interface Catalog {
  ingredients: Ingredient[];
  recipes: Recipe[];
  ings: Map<string, Ingredient>;
  recipeById: Map<string, Recipe>;
}

export function useCatalog() {
  const repo = useRepo();
  const { scope } = useSession();
  const q = useQuery({ queryKey: keys.catalog(scope), queryFn: () => repo.getCatalog(), staleTime: 1000 * 60 * 60 });
  const data = useMemo<Catalog | undefined>(
    () =>
      q.data && {
        ...q.data,
        ings: indexIngredients(q.data.ingredients),
        recipeById: new Map(q.data.recipes.map((r) => [r.id, r])),
      },
    [q.data],
  );
  return { ...q, data };
}

export function usePrefs() {
  const repo = useRepo();
  const { scope } = useSession();
  return useQuery({ queryKey: keys.prefs(scope), queryFn: () => repo.getPreferences() });
}

export function useSavePrefs() {
  const repo = useRepo();
  const { scope } = useSession();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (p: StoredPreferences) => repo.savePreferences(p),
    onMutate: (p) => qc.setQueryData(keys.prefs(scope), p),
    onSettled: () => qc.invalidateQueries({ queryKey: keys.prefs(scope) }),
  });
}

export function usePlan(week: string) {
  const repo = useRepo();
  const { scope } = useSession();
  return useQuery({ queryKey: keys.plan(scope, week), queryFn: () => repo.getPlan(week) });
}

/** Optimistic: the plan updates instantly, the server write follows. */
export function useSetPlan(week: string) {
  const repo = useRepo();
  const { scope } = useSession();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (entries: PlanEntry[]) => repo.savePlan(week, entries),
    onMutate: async (entries) => {
      await qc.cancelQueries({ queryKey: keys.plan(scope, week) });
      const prev = qc.getQueryData<PlanEntry[]>(keys.plan(scope, week));
      qc.setQueryData(keys.plan(scope, week), entries);
      return { prev };
    },
    onError: (_e, _v, ctx) => ctx?.prev && qc.setQueryData(keys.plan(scope, week), ctx.prev),
  });
}

export function useStoredList(week: string) {
  const repo = useRepo();
  const { scope } = useSession();
  return useQuery({ queryKey: keys.list(scope, week), queryFn: () => repo.getShoppingList(week) });
}

export function useSaveList(week: string) {
  const repo = useRepo();
  const { scope } = useSession();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (list: ShoppingList) => repo.saveShoppingList(week, list),
    onMutate: (list) => qc.setQueryData(keys.list(scope, week), list),
  });
}

/**
 * The live shopping list: recomputed from plan + catalog + prefs (packages/core),
 * merged with what the user checked, overrode or added (stored list).
 */
export function useShoppingList(week: string) {
  const catalog = useCatalog();
  const prefs = usePrefs();
  const plan = usePlan(week);
  const stored = useStoredList(week);
  const list = useMemo(() => {
    if (!catalog.data || !prefs.data || !plan.data || stored.isLoading) return undefined;
    return buildShoppingList({
      entries: plan.data,
      recipes: catalog.data.recipes,
      ingredients: catalog.data.ings,
      prefs: prefs.data,
      previous: stored.data ?? null,
    });
  }, [catalog.data, prefs.data, plan.data, stored.data, stored.isLoading]);
  return { list, isLoading: !list, error: catalog.error ?? plan.error ?? prefs.error };
}

/** Recipes the user may see (hard allergen/diet/dislike filter, time handled as a soft filter in UI). */
export function useAllowedRecipes() {
  const catalog = useCatalog();
  const prefs = usePrefs();
  return useMemo(() => {
    if (!catalog.data || !prefs.data) return { allowed: [] as Recipe[], hidden: 0 };
    const p = { ...prefs.data, maxCookMinutes: null };
    const allowed = catalog.data.recipes.filter((r) => isRecipeAllowed(r, catalog.data!.ings, p));
    return { allowed, hidden: catalog.data.recipes.length - allowed.length };
  }, [catalog.data, prefs.data]);
}

export { keys as queryKeys };
