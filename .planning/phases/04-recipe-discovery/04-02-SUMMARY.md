---
phase: 04-recipe-discovery
plan: 02
subsystem: ui
tags: [flutter, riverpod, go_router, cached_network_image, recipe-search, pagination, filter-chips]

requires:
  - phase: 04-recipe-discovery
    provides: recipeRepositoryProvider, RecipeSearchResult, RecipeSummary, QuotaExhaustedException
  - phase: 03-ingredient-selection
    provides: selectedTodayProvider (SelectedTodayNotifier keepAlive), ingredient selection state

provides:
  - RecipeFilterStateNotifier: Riverpod notifier with query/cuisine/maxReadyTime/isIngredientMode state
  - recipeSearchPageProvider: paginated FutureProvider.family keyed by filters + page number
  - ingredientBasedRecipesProvider: FutureProvider.family for ingredient-based recipe discovery
  - RecipeBrowseScreen: search bar + filter chips + dual-mode paginated body at /recipes
  - RecipeCard: CachedNetworkImage thumbnail, title, onTap -> /recipes/:id
  - FilterChipsRow: 8 cuisine chips + 3 cook-time chips + 'Use my ingredients' ChoiceChip
  - recipe_routes.dart: /recipes and /recipes/:id GoRouter routes

affects:
  - 04-03-recipe-detail — /recipes/:id route placeholder already wired; detail screen replaces it
  - 05-meal-planning — recipe discovery surface from which recipes will be added to meal plans

tech-stack:
  added:
    - cached_network_image: ^3.4.1 (CachedNetworkImage for recipe thumbnails)
  patterns:
    - Dual-mode list body: isIngredientMode toggle switches between search results and ingredient-based results
    - Page-keyed provider caching: recipeSearchPageProvider keyed by (query, cuisine, maxReadyTime, page) — each page cached independently
    - Infinite scroll via setState: _loadedPages counter incremented via addPostFrameCallback on last-item visibility
    - Sentinel object pattern: _sentinel const Object for nullable fields in RecipeFilterState.copyWith

key-files:
  created:
    - meal_mate/lib/features/recipes/presentation/providers/recipe_search_provider.dart
    - meal_mate/lib/features/recipes/presentation/providers/recipe_search_provider.g.dart
    - meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart
    - meal_mate/lib/features/recipes/presentation/recipe_card.dart
    - meal_mate/lib/features/recipes/presentation/recipe_routes.dart
    - meal_mate/lib/features/recipes/presentation/widgets/filter_chips_row.dart
  modified:
    - meal_mate/lib/app/router.dart (added recipe_routes.dart import and ...recipeRoutes spread)
    - meal_mate/pubspec.yaml (added cached_network_image dependency)

key-decisions:
  - "recipeFilterStateProvider (not recipeFilterStateNotifierProvider) is the generated Riverpod 3.x provider name — callers use .notifier suffix for mutations"
  - "page parameter is required (not defaulted) in recipeSearchPageProvider to avoid Dart null-default-int issue with named params in @riverpod codegen"
  - "recipe_routes.dart created as separate file parallel to core/router/app_router.dart — mirrors ingredient route pattern, imported in router.dart alongside ingredientRoutes"
  - "Apostrophes in const Text strings avoided — used 'You have reached' instead of 'You've reached' to remain const-compatible"
  - "cached_network_image added to pubspec.yaml — plan required CachedNetworkImage but it was not in existing dependencies"

patterns-established:
  - "Pattern: Dual-mode browse screen — isIngredientMode bool in filter state toggles between search body and ingredient-body widgets"
  - "Pattern: Page-keyed Riverpod caching — each page index is a separate provider instance; ref.invalidate(recipeSearchPageProvider) clears all cached pages on filter change"
  - "Pattern: CachedNetworkImage with grey-box placeholder and restaurant icon error widget — used for all recipe thumbnails in this feature"

requirements-completed: [RECP-01, RECP-04]

duration: 6min
completed: 2026-03-05
---

# Phase 4 Plan 02: Recipe Browse Screen Summary

**Recipe browse screen with Riverpod paginated search, 3-dimension filter chips (cuisine/cook-time/ingredient mode), CachedNetworkImage recipe cards, and dual-mode list body wired to /recipes route**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-05T20:19:30Z
- **Completed:** 2026-03-05T20:25:30Z
- **Tasks:** 2
- **Files modified:** 8 (6 created, 2 modified including generated file)

## Accomplishments

- `RecipeFilterStateNotifier` with query/cuisine/maxReadyTime/isIngredientMode state and setQuery/setCuisine/setMaxReadyTime/toggleIngredientMode/clearFilters methods
- `recipeSearchPageProvider` family — pages cached independently by Riverpod; filters invalidate all cached pages
- `ingredientBasedRecipesProvider` — reads ingredient names from `selectedTodayProvider`, passes to `RecipeRepository.findByIngredients`
- `RecipeBrowseScreen` — 300ms debounced search bar, FilterChipsRow, dual-mode body with infinite scroll pagination
- `FilterChipsRow` — 8 cuisine chips (Italian/Mexican/Chinese/Indian/Japanese/Mediterranean/American/Thai), 3 cook-time chips (15/30/60 min), "Use my ingredients" ChoiceChip
- `RecipeCard` — `CachedNetworkImage` thumbnail (120x90 BoxFit.cover), title, onTap → `/recipes/:id`
- Route `/recipes` registered via `recipe_routes.dart` spread into `routerProvider`; `/recipes/:id` placeholder wired (replaced by Plan 04-03)

## Task Commits

Each task was committed atomically:

1. **Task 1: Riverpod search provider with pagination and filter state** - `a8eaef3` (feat)
2. **Task 2: Recipe browse screen, recipe card, filter chips row, and route registration** - `2814b16` (feat)

**Plan metadata:** (to be committed with docs commit)

## Files Created/Modified

- `meal_mate/lib/features/recipes/presentation/providers/recipe_search_provider.dart` - RecipeFilterStateNotifier, recipeSearchPageProvider, ingredientBasedRecipesProvider with @riverpod codegen
- `meal_mate/lib/features/recipes/presentation/providers/recipe_search_provider.g.dart` - Generated Riverpod provider code
- `meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart` - Main browse screen (394 lines): search bar, filter chips, search mode + ingredient mode bodies, error states
- `meal_mate/lib/features/recipes/presentation/recipe_card.dart` - RecipeCard with CachedNetworkImage (79 lines)
- `meal_mate/lib/features/recipes/presentation/recipe_routes.dart` - GoRouter route definitions for /recipes and /recipes/:id
- `meal_mate/lib/features/recipes/presentation/widgets/filter_chips_row.dart` - Horizontal scrollable FilterChip row (70 lines)
- `meal_mate/lib/app/router.dart` - Added recipe_routes.dart import and ...recipeRoutes spread
- `meal_mate/pubspec.yaml` - Added cached_network_image: ^3.4.1

## Decisions Made

- **`page` is required in recipeSearchPageProvider:** Removing the default `= 0` and making it required avoids the Dart null-default issue with named parameters in Riverpod codegen — callers always pass an explicit page.
- **`recipe_routes.dart` as separate file:** Mirrors the ingredient route pattern (`core/router/app_router.dart`). Both are imported and spread in `router.dart`. This gives Plan 04-03 a clear place to replace the detail placeholder without touching unrelated router code.
- **CachedNetworkImage instead of Image.network:** Plan requirement — all recipe thumbnails use `CachedNetworkImage` for disk caching and reduced bandwidth on repeated views.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `cached_network_image` dependency**
- **Found during:** Task 2 (recipe_card.dart creation)
- **Issue:** `CachedNetworkImage` required by plan was not in `pubspec.yaml`; import would fail without it
- **Fix:** Added `cached_network_image: ^3.4.1` to pubspec.yaml and ran `dart pub get`
- **Files modified:** `meal_mate/pubspec.yaml`
- **Verification:** `dart pub get` succeeded, import resolves, `dart analyze` passes
- **Committed in:** `a8eaef3` (Task 1 commit, as part of initial setup)

**2. [Rule 1 - Bug] Fixed generated provider name mismatch**
- **Found during:** Task 2 (dart analyze on browse screen)
- **Issue:** `recipeFilterStateNotifierProvider` referenced in browse screen and filter chips — actual generated name is `recipeFilterStateProvider` (Riverpod 3.x codegen drops `Notifier` suffix)
- **Fix:** Updated all references from `recipeFilterStateNotifierProvider` to `recipeFilterStateProvider`
- **Files modified:** `recipe_browse_screen.dart`, `filter_chips_row.dart`
- **Verification:** `dart analyze lib/features/recipes/presentation/` — no issues found
- **Committed in:** `2814b16` (Task 2 commit)

**3. [Rule 1 - Bug] Fixed `selectedTodayNotifierProvider` name**
- **Found during:** Task 2 (dart analyze)
- **Issue:** `selectedTodayNotifierProvider` referenced in ingredient mode body — generated name is `selectedTodayProvider`
- **Fix:** Updated reference to use correct generated provider name
- **Files modified:** `recipe_browse_screen.dart`
- **Verification:** `dart analyze lib/features/recipes/presentation/` — no issues found
- **Committed in:** `2814b16` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (1 Rule 3 blocking, 2 Rule 1 bugs)
**Impact on plan:** All three required for compilation. No scope creep — missing dep and wrong provider names are typical code completion issues.

## Issues Encountered

- `recipe_detail_provider.dart` was already present in the providers directory (pre-built for Plan 04-03) but its `.g.dart` hadn't been generated yet. Running `build_runner build` generated it, clearing those errors — not caused by this plan.
- `app_router.dart` (core/router) had an older version in one file state that included `recipeRoutes` — this was resolved by the linter auto-correcting `recipe_routes.dart` to the canonical form. The two files coexist without conflict.

## User Setup Required

None - no external service configuration required for this plan. The Spoonacular Edge Function was set up in Plan 04-01.

## Next Phase Readiness

- Recipe browse screen is fully functional — search, filter chips, paginated results, ingredient mode, and error handling all wired
- Plan 04-03 (recipe detail) can replace the `/recipes/:id` placeholder in `recipe_routes.dart` with `RecipeDetailScreen` — the provider (`recipeDetailProvider`) and screen skeleton are already in place from pre-built files
- `recipeFilterStateProvider` is auto-dispose (not keepAlive) — filter state resets on navigation away from `/recipes`, which is the correct behavior for a browse screen

---
*Phase: 04-recipe-discovery*
*Completed: 2026-03-05*
