---
status: diagnosed
phase: 03-ingredient-selection
source: [03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md]
started: 2026-03-04T10:00:00Z
updated: 2026-03-04T10:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Two-Tab Ingredient Screen
expected: Navigate to /ingredients. You should see a screen with two tabs: "Search" (or Search/Browse) and "Favorites". Tapping each tab switches the view. No nested app bars or visual glitches.
result: pass

### 2. Ingredient Search with Autocomplete
expected: On the Search tab, tap the search box and type a common ingredient (e.g., "chicken"). Results should appear quickly — common ingredients match locally first (near-instant). Results show ingredient name, category, and dietary badges if applicable.
result: issue
reported: "yes the search works but really slow"
severity: minor

### 3. Colored Category Cards
expected: Below the search box on the Search tab, you should see a grid of 12 category cards (Produce, Dairy, Meat, Grains, Seafood, Spices, Condiments, Beverages, Snacks, Frozen, Baking, Nuts & Seeds). Each card has a distinct background color and icon.
result: pass

### 4. Category Browse with Shimmer Loading
expected: Tap any category card. A new screen loads showing ingredients in that category. While loading, you should see shimmer placeholder tiles (animated grey/white pulsing rows) — NOT a spinning circle. Ingredients appear sorted alphabetically.
result: issue
reported: "they do have different colors but i see no animation since no results are loading but ig this will work later on"
severity: major

### 5. Dietary Filter Chips
expected: On the Search tab or category screen, dietary filter chips are available (Vegetarian, Vegan, Gluten-Free, Dairy-Free). Tapping a filter narrows results. When filtering by Gluten-Free or Dairy-Free, a note appears indicating results may be incomplete.
result: issue
reported: "the filters are there but they dont do anything, a note appears indicating results may be incomplete"
severity: major

### 6. Dietary Badges on Tiles
expected: Ingredient tiles show small badge chips (V, VG, GF, DF) next to the ingredient name for applicable dietary flags. For example, a vegan ingredient should show "VG" and "V" badges.
result: issue
reported: "no badge chips"
severity: major

### 7. Animated Heart Favorite Toggle
expected: Each ingredient tile has a heart icon. Tapping the heart should trigger a brief scale animation (heart grows then shrinks back) and you should feel a light haptic tap. The heart fills/unfills to indicate favorite status.
result: issue
reported: "the animation is there but it doesnt do anything"
severity: major

### 8. Favorites Tab with Saved Favorites
expected: After favoriting some ingredients, switch to the Favorites tab. Your favorited ingredients appear in a list with shimmer loading while data loads. The favorites persist if you navigate away and come back.
result: issue
reported: "nooone of that is happening"
severity: blocker

### 9. Add All Favorites to Today
expected: On the Favorites tab, there's an "Add all to today" button at the top. Tapping it adds all your favorited ingredients to the selected-today list in one action. The selected-today bar should update to reflect all added items.
result: issue
reported: "it only says, no favourites yet, there is no selected today list or add all to today button"
severity: blocker

### 10. Expandable Selected-Today Bar
expected: After selecting at least one ingredient (via heart or "select" action), a bar appears at the bottom showing the count and first 2-3 ingredient names as chips. Tapping the bar expands it to show all selected ingredients as deletable chips, plus a "Clear all" option and a "Find Recipes" button.
result: pass

### 11. Quick-Add Favorites Chips on Search
expected: On the Search tab, above the search field, you should see your favorited ingredients displayed as small chips. Tapping a chip adds that ingredient to today's selection (the chip disappears from the row once added).
result: issue
reported: "nothing that has to do with favourites works"
severity: major

### 12. Selections Persist Until Cleared
expected: Select some ingredients, then close and reopen the app (or navigate away and back). Your selected-today ingredients should still be there — they do NOT reset at midnight or on navigation. Only the "Clear all" action removes them.
result: pass

### 13. Pull-to-Refresh on Category Screen
expected: On a category browse screen, pull down to trigger a refresh. The list should reload from the API with fresh data.
result: issue
reported: "no pull down trigger"
severity: major

## Summary

total: 13
passed: 4
issues: 9
pending: 0
skipped: 0

## Gaps

- truth: "Search results appear quickly with local-first matching (near-instant for common ingredients)"
  status: failed
  reason: "User reported: yes the search works but really slow"
  severity: minor
  test: 2
  root_cause: "Local commonIngredients matching is inside the 300ms debounce callback instead of before it. Users wait the full debounce delay even when local results are immediately available. Also ref.onDispose is placed inside timer callback instead of at provider scope."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/presentation/providers/ingredient_search_provider.dart"
      issue: "Local match inside Timer callback; ref.onDispose inside timer body"
  missing:
    - "Move local commonIngredients check before the debounce Timer — if >= 5 local matches, emit immediately and skip API"
    - "Move ref.onDispose to build() method"
  debug_session: ""

- truth: "Category browse shows ingredients with shimmer loading, sorted alphabetically"
  status: failed
  reason: "User reported: no results loading at all on category screens"
  severity: major
  test: 4
  root_cause: "Double translation bug: ingredient_category_screen.dart pre-translates display name to OFf tag (e.g. 'Produce' -> 'en:fruits-and-vegetables'), then repository's _getCategoryTag receives the tag instead of display name and returns null — silently skipping the entire remote fetch. Cache also never hits because stored category is display name but query uses tag."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart"
      issue: "Lines 32-34 pre-translate display name to OFf tag before passing to provider"
    - path: "meal_mate/lib/features/ingredients/data/ingredient_repository.dart"
      issue: "_getCategoryTag expects display name but receives OFf tag — returns null, skips remote fetch"
  missing:
    - "Remove pre-translation from category screen — pass display name directly to ingredientsByCategoryProvider"
    - "Let repository own the tag lookup via _getCategoryTag (already correct internally)"
  debug_session: ".planning/debug/category-browse-no-results.md"

- truth: "Dietary filter chips narrow search/category results when tapped"
  status: failed
  reason: "User reported: filters are there but they dont do anything"
  severity: major
  test: 5
  root_cause: "Search screen watches only ingredientSearchProvider and has no awareness of ingredientFilterProvider. When a chip is tapped, filter state updates in IngredientFilterNotifier but the search provider is never invalidated. filteredIngredientsProvider exists but is dead code — never watched by any screen."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart"
      issue: "Never reads ingredientFilterProvider to re-trigger filtered search"
    - path: "meal_mate/lib/features/ingredients/presentation/providers/ingredient_filter_provider.dart"
      issue: "filteredIngredientsProvider is dead code — never watched"
  missing:
    - "Search screen must watch ingredientFilterProvider and re-trigger search or apply filters to results"
  debug_session: ".planning/debug/dietary-filter-and-badge-bugs.md"

- truth: "Ingredient tiles show dietary badge chips (V, VG, GF, DF)"
  status: failed
  reason: "User reported: no badge chips"
  severity: major
  test: 6
  root_cause: "OFf getSuggestions endpoint returns List<String> (bare name strings) with no product metadata. Search screen constructs IngredientTile with no dietaryFlags argument, defaulting to []. No Ingredient domain object exists in the search flow."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart"
      issue: "suggestions is List<String> — tile gets no flags, defaults to []"
    - path: "meal_mate/lib/features/ingredients/data/openfoodfacts_remote_source.dart"
      issue: "getSuggestions returns only strings by design — no metadata"
  missing:
    - "After getting suggestion strings, look up each name in local DB to get full Ingredient with flags, OR use OFf product search endpoint for richer data"
  debug_session: ".planning/debug/dietary-filter-and-badge-bugs.md"

- truth: "Heart toggle fills/unfills to persist favorite status"
  status: failed
  reason: "User reported: the animation is there but it doesnt do anything"
  severity: major
  test: 7
  root_cause: "toggleFavorite() in repository silently returns early when ingredient not in Drift (getIngredient returns null). Search results are bare strings never upserted to Drift. Optimistic update in favorites provider also no-ops (map finds no match for new favorites). Search screen never passes isFavorite state to IngredientTile."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/data/ingredient_repository.dart"
      issue: "toggleFavorite silently no-ops for ingredients not in Drift — null guard returns early"
    - path: "meal_mate/lib/features/ingredients/presentation/providers/ingredient_favorites_provider.dart"
      issue: "Optimistic update map loop finds no match for new favorites — returns unchanged list"
    - path: "meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart"
      issue: "Never reads favorites provider — isFavorite always defaults to false on tiles"
  missing:
    - "Repository: upsert minimal Ingredient row before toggling if not in Drift"
    - "Favorites provider: append new Ingredient on optimistic update if not in current list"
    - "Search screen: read ingredientFavoritesProvider and pass isFavorite to each IngredientTile"
  debug_session: ".planning/debug/favorites-non-functional.md"

- truth: "Favorites tab shows favorited ingredients with persistence"
  status: failed
  reason: "User reported: nooone of that is happening"
  severity: blocker
  test: 8
  root_cause: "Cascading from heart toggle bug — nothing is ever written to Drift as favorite, so favorites provider always returns empty list."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/data/ingredient_repository.dart"
      issue: "toggleFavorite no-op cascades to empty favorites list"
  missing:
    - "Fix toggleFavorite upsert (same fix as test 7)"
  debug_session: ".planning/debug/favorites-non-functional.md"

- truth: "Add all favorites to today button visible and functional on favorites tab"
  status: failed
  reason: "User reported: only says no favourites yet, no add all button or selected today list"
  severity: blocker
  test: 9
  root_cause: "Cascading from favorites being empty — 'Add all to today' button is behind active.isEmpty guard. With no favorites, button never shows."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/presentation/screens/ingredient_favorites_screen.dart"
      issue: "Button behind isEmpty guard — correct behavior once favorites work"
  missing:
    - "Fix toggleFavorite upsert (same root cause as test 7/8)"
  debug_session: ".planning/debug/favorites-non-functional.md"

- truth: "Quick-add favorites chips visible above search field"
  status: failed
  reason: "User reported: nothing that has to do with favourites works"
  severity: major
  test: 11
  root_cause: "Cascading from favorites being empty — chip section is behind unselectedFavorites.isNotEmpty guard."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart"
      issue: "Chips behind isNotEmpty guard — correct behavior once favorites work"
  missing:
    - "Fix toggleFavorite upsert (same root cause as test 7/8/9)"
  debug_session: ".planning/debug/favorites-non-functional.md"

- truth: "Pull-to-refresh triggers data reload on category screen"
  status: failed
  reason: "User reported: no pull down trigger"
  severity: major
  test: 13
  root_cause: "RefreshIndicator is only in the data: branch of ingredientsAsync.when(), not in loading: or error: branches. On first load or after error, pull-to-refresh is unavailable. Empty-state widget (filtered.isEmpty) also lacks RefreshIndicator."
  artifacts:
    - path: "meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart"
      issue: "RefreshIndicator only in data: branch — not available during loading/error/empty states"
  missing:
    - "Lift RefreshIndicator outside ingredientsAsync.when() to wrap all states"
  debug_session: ""
