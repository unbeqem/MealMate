---
status: diagnosed
trigger: "Investigate why dietary filter chips don't filter results and dietary badges don't appear on ingredient tiles"
created: 2026-03-04T00:00:00Z
updated: 2026-03-04T00:00:00Z
---

## Current Focus

hypothesis: Three distinct bugs identified — confirmed by full code trace
test: Static analysis complete (no runtime testing needed — bugs are structural)
expecting: N/A — root causes confirmed
next_action: Return diagnosis to caller

## Symptoms

expected: Tapping dietary filter chips (Vegetarian, Vegan, GF, DF) narrows displayed ingredient results; ingredient tiles show V/VG/GF/DF badge chips when the ingredient carries those flags
actual: Filter chips visually toggle (selected state changes) but results list is unchanged; no badge chips appear on any ingredient tile
errors: None — no runtime errors thrown
reproduction: 1) Open ingredient search screen, type a query, tap any filter chip — results unchanged. 2) Navigate to any category screen — ingredient tiles show no dietary badge chips despite ingredients potentially having flags
started: Unknown — likely since initial implementation (structural wiring gaps, not a regression)

## Eliminated

- hypothesis: IngredientTile does not support rendering dietary badges
  evidence: IngredientTile.dart lines 17, 73–98 show it accepts dietaryFlags and renders _DietaryBadge chips correctly
  timestamp: 2026-03-04

- hypothesis: DietaryFilterChips widget is not connected to any provider
  evidence: dietary_filter_chips.dart watches ingredientFilterProvider and calls notifier.toggle — state management is wired correctly within the chip widget itself
  timestamp: 2026-03-04

- hypothesis: The ingredient domain model lacks a dietaryFlags field
  evidence: ingredient.dart line 13 defines @Default([]) List<String> dietaryFlags
  timestamp: 2026-03-04

- hypothesis: filteredIngredientsProvider is broken
  evidence: The provider is correctly wired — the problem is that no screen reads from filteredIngredientsProvider at all
  timestamp: 2026-03-04

## Evidence

- timestamp: 2026-03-04
  checked: ingredient_search_screen.dart lines 43, 133–148
  found: ingredientSearchProvider returns List<String> (plain name strings, not Ingredient objects). IngredientTile is constructed at line 139 with NO dietaryFlags argument — it gets the default empty list.
  implication: Badges can never appear on search screen tiles because the search provider discards domain objects entirely.

- timestamp: 2026-03-04
  checked: ingredient_search_screen.dart line 43 vs ingredient_filter_provider.dart lines 34–39
  found: The search screen watches ONLY ingredientSearchProvider. It never watches ingredientFilterProvider. When filter chips are toggled, ingredientSearchProvider is not invalidated and search() is not re-called.
  implication: Filter chip state changes in complete isolation from the search results list.

- timestamp: 2026-03-04
  checked: ingredient_filter_provider.dart lines 33–39 (filteredIngredientsProvider)
  found: filteredIngredientsProvider exists and correctly calls repo.filterByDietary(). But grep across all presentation screens shows it is NEVER watched by any screen.
  implication: The filtering infrastructure exists but is dead code — no screen consumes it.

- timestamp: 2026-03-04
  checked: ingredient_category_screen.dart lines 32–34
  found: The category screen calls ingredientsByCategoryProvider(categoryTag) where categoryTag = ingredientCategories[categoryName] ?? categoryName. ingredientCategories maps display names (e.g. "Produce") to OFf tags (e.g. "en:fruits-and-vegetables").
  implication: The provider receives the OFf tag string (e.g. "en:fruits-and-vegetables").

- timestamp: 2026-03-04
  checked: ingredient_category_provider.dart lines 12–15 → ingredient_repository.dart lines 27–48 → ingredient_local_source.dart lines 17–23
  found: watchIngredientsByCategory passes category straight to local DB query: WHERE category = :category. But in _mapProductToIngredient (openfoodfacts_remote_source.dart lines 91–95), the ingredient is stored with category = displayCategory (the human-readable name like "Produce"), NOT the OFf tag. The local DB query uses the OFf tag as the WHERE clause value but rows were inserted with the display name.
  implication: The category screen passes the OFf tag to the provider, but the DB rows are keyed on display name — so cache lookups always return empty, forcing a remote fetch every time.

- timestamp: 2026-03-04
  checked: ingredient_category_screen.dart lines 64–71 (client-side dietary filter)
  found: The category screen DOES apply dietary filtering correctly — it filters the Ingredient list by dietaryFlags and passes ingredient.dietaryFlags to IngredientTile. This part works.
  implication: Badges and filtering work correctly in the category screen IF ingredients have dietaryFlags populated. The data population question depends on OFf API response quality.

- timestamp: 2026-03-04
  checked: openfoodfacts_remote_source.dart lines 69–103
  found: _mapProductToIngredient reads ingredientsAnalysisTags for vegan/vegetarian and labelsTags for gluten-free/dairy-free. These fields are requested in the API configuration (INGREDIENTS_ANALYSIS_TAGS, LABELS_TAGS). Flags are correctly extracted when the data is present in the OFf response.
  implication: Dietary flag population works for category-browsed ingredients. The OFf taxonomy suggestions endpoint used by search (getSuggestions) returns only strings — no product data at all.

## Resolution

root_cause: |
  Three separate bugs, all structural wiring gaps:

  BUG 1 — Search screen: filter chips have no effect on search results.
  The search screen (ingredient_search_screen.dart) watches only ingredientSearchProvider.
  Toggling filter chips updates ingredientFilterProvider state but the search provider
  never observes it and is never invalidated. The filter state and the displayed results
  are completely decoupled.

  BUG 2 — Search screen: dietary badges never appear on ingredient tiles.
  ingredientSearchProvider returns List<String> (bare name strings from the OFf taxonomy
  suggestions endpoint). The IngredientTile in the search screen is constructed without
  dietaryFlags (defaulting to []). There is no Ingredient domain object in the search flow —
  the suggestions API only returns names, not product metadata.

  BUG 3 — Category screen: cache always misses, causing repeated network fetches.
  ingredient_category_screen.dart resolves the OFf tag and passes it to
  ingredientsByCategoryProvider(categoryTag). The provider passes that OFf tag
  (e.g. "en:fruits-and-vegetables") through to ingredient_local_source.getIngredientsByCategory().
  But the local DB rows have category = display name (e.g. "Produce") because
  _mapProductToIngredient stores the human-readable display name. The WHERE clause
  never matches, so the cache is always empty on first render.

fix: Not applied — diagnose-only mode
verification: Not applicable
files_changed: []
