---
status: diagnosed
trigger: "Investigate why favorites are completely non-functional in the MealMate Flutter app."
created: 2026-03-04T00:00:00Z
updated: 2026-03-04T00:00:00Z
---

## Current Focus

hypothesis: Three distinct root causes found — all confirmed by code inspection
test: Static code analysis complete
expecting: N/A — diagnosis complete
next_action: Return diagnosis to caller

## Symptoms

expected: Heart toggles filled/unfilled; Favorites tab shows favorited ingredients; "Add all to today" button appears; Quick-add chips appear on search screen
actual: Animation plays but heart never fills; Favorites tab always shows "no favourites yet"; No "Add all to today" button; No quick-add chips
errors: None (silent failures)
reproduction: Tap heart on any ingredient tile; Navigate to Favorites tab
started: Presumably since feature was first built — structural issues, not regressions

## Eliminated

- hypothesis: IngredientTile widget is broken internally
  evidence: Tile correctly uses isFavorite prop for icon/color, calls onFavoriteTap via _handleFavoriteTap, passes callback through correctly
  timestamp: 2026-03-04

- hypothesis: ingredientFavoritesProvider notifier is wired incorrectly
  evidence: toggleFavorite() does optimistic update AND persists to Drift AND refreshes from getFavorites() — logic is correct
  timestamp: 2026-03-04

- hypothesis: IngredientFavoritesScreen reads wrong provider
  evidence: It correctly watches ingredientFavoritesProvider and filters active = favorites.where((i) => i.isFavorite).toList()
  timestamp: 2026-03-04

## Evidence

- timestamp: 2026-03-04
  checked: ingredient_search_screen.dart lines 134-149
  found: Search results use raw name strings from OpenFoodFacts autocomplete, not Ingredient domain objects. The ingredient ID passed to toggleFavorite() is the ingredient NAME string (e.g. "Tomato"). The isFavorite prop is never passed to IngredientTile — it is omitted entirely.
  implication: (1) toggleFavorite(name) will call repo.getIngredient(name) which queries by ID — but ingredients from search are never stored in Drift with that name as ID, so getIngredient() returns null and the toggle silently does nothing. (2) Even if it did work, IngredientTile always renders with isFavorite: false (the default) because the search screen never passes the current favorite state.

- timestamp: 2026-03-04
  checked: ingredient_repository.dart toggleFavorite() lines 54-61
  found: toggleFavorite() calls _local.getIngredient(ingredientId). If the ingredient doesn't exist in the local Drift DB, it returns null and returns early — NO write happens, NO error is thrown.
  implication: Any ingredient favorited from the search screen (before it has been cached via category browsing) silently no-ops. This is the direct cause of "heart animation plays but status doesn't toggle."

- timestamp: 2026-03-04
  checked: ingredient_favorites_provider.dart toggleFavorite() optimistic update block lines 22-33
  found: The optimistic update maps over state.value. If the ingredient being toggled is NOT already in the favorites list (i.e., being favorited for the first time from search), the map loop finds no match and the list is unchanged. So the optimistic update also produces no visual change.
  implication: Even the in-memory state doesn't update for first-time favorites from search. Both layers silently fail.

- timestamp: 2026-03-04
  checked: ingredient_search_screen.dart lines 48-52 (unselectedFavorites) and lines 128-149 (search result IngredientTile)
  found: unselectedFavorites filters favoritesAsync.value by !selectedMap.containsKey(fav.id). Because favorites are always empty (due to the silent no-op), unselectedFavorites is always []. The if (unselectedFavorites.isNotEmpty) guard at line 58 is always false — chips section is never rendered.
  implication: Quick-add chips never appear because no favorites are ever successfully saved.

- timestamp: 2026-03-04
  checked: ingredient_favorites_screen.dart lines 37-38
  found: final active = favorites.where((i) => i.isFavorite).toList(). getFavorites() from local source already filters WHERE isFavorite = true, so this double-filter is redundant but harmless. The real problem is getFavorites() always returns [] because no favorites were ever written.
  implication: active is always empty; empty state is always shown; "Add all to today" button (inside the active.isEmpty guard) is never rendered.

- timestamp: 2026-03-04
  checked: ingredient_search_screen.dart IngredientTile at lines 139-149
  found: IngredientTile is constructed without isFavorite parameter. Default is false. No lookup against ingredientFavoritesProvider is performed to determine current favorite state.
  implication: Even if toggling worked, the heart icon would never visually reflect the favorited state on the search screen — it would always show the empty heart.

## Resolution

root_cause: |
  THREE compounding root causes, all in the search flow:

  ROOT CAUSE 1 — toggleFavorite() silently no-ops for unsaved ingredients
  File: meal_mate/lib/features/ingredients/data/ingredient_repository.dart, lines 54-61
  Problem: toggleFavorite() calls _local.getIngredient(ingredientId). For ingredients
  found via search autocomplete, no Ingredient row exists in Drift (only the name string
  is returned by OpenFoodFacts suggestions). getIngredient() returns null and the method
  returns early without writing anything. No error, no exception, no state change.

  ROOT CAUSE 2 — Optimistic update in provider cannot find the ingredient to toggle
  File: meal_mate/lib/features/ingredients/presentation/providers/ingredient_favorites_provider.dart, lines 22-33
  Problem: The optimistic update maps over the current favorites list looking for a
  matching id. For a brand-new favorite from search, there is no existing entry in the
  list, so the map produces no change. The visual state update is also a no-op.

  ROOT CAUSE 3 — IngredientTile in search results never receives isFavorite state
  File: meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart, lines 139-149
  Problem: IngredientTile is built with no isFavorite: parameter. The screen never
  reads ingredientFavoritesProvider to determine which search results are already
  favorited. So the heart icon is permanently empty regardless of database state.

fix: Not applied — diagnosis-only mode
verification: N/A
files_changed: []
