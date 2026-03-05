---
phase: 04-recipe-discovery
plan: 03
subsystem: ui
tags: [riverpod, flutter, serving-scaler, recipe-detail, go_router, freezed, tdd]

requires:
  - phase: 04-recipe-discovery/04-01
    provides: RecipeRepository with getRecipeDetail, Recipe Freezed model, ExtendedIngredient, AnalyzedInstruction domain models
  - phase: 04-recipe-discovery/04-02
    provides: recipe_routes.dart with /recipes placeholder route, RecipeBrowseScreen navigation to /recipes/:id

provides:
  - RecipeDetailScreen showing hero image, title, cook time, scaled ingredient list, numbered instructions
  - ServingScalerWidget with increment/decrement controls (min 1 serving enforced)
  - IngredientListTile with proportional scaling via formatAmount; original string fallback for unstructured data
  - servingSizeProvider (Riverpod notifier family keyed by originalServings) for ephemeral serving size state
  - recipeDetailProvider (FutureProvider.family keyed by recipe id) with cache-first fetch via RecipeRepository
  - formatAmount() pure utility: whole numbers as integers, max 2 decimal places, trailing zeros stripped
  - /recipes/:id route live (replaced placeholder with RecipeDetailScreen in recipe_routes.dart)
  - 9 unit tests for formatAmount (6 cases) and scaling math (3 cases)

affects:
  - 05-meal-planning — depends on Recipe detail view for adding to meal plan
  - 04-02-recipe-browse — /recipes/:id route now live for recipe card navigation

tech-stack:
  added: []
  patterns:
    - Ephemeral serving state: servingSizeProvider family keyed by originalServings — never persisted to Drift
    - formatAmount utility: whole number check before toStringAsFixed(2) + regex strip trailing zeros
    - Fallback display: ingredient.original string when amount == 0 or unit is empty
    - Route replacement: updated recipe_routes.dart placeholder route with real screen (not new route)

key-files:
  created:
    - meal_mate/lib/features/recipes/utils/format_amount.dart
    - meal_mate/lib/features/recipes/presentation/providers/recipe_detail_provider.dart
    - meal_mate/lib/features/recipes/presentation/providers/recipe_detail_provider.g.dart
    - meal_mate/lib/features/recipes/presentation/screens/recipe_detail_screen.dart
    - meal_mate/lib/features/recipes/presentation/widgets/serving_scaler_widget.dart
    - meal_mate/lib/features/recipes/presentation/widgets/ingredient_list_tile.dart
    - meal_mate/test/features/recipes/presentation/serving_scaler_test.dart
  modified:
    - meal_mate/lib/features/recipes/presentation/recipe_routes.dart (placeholder -> RecipeDetailScreen)
    - meal_mate/lib/core/router/app_router.dart (comment update only)
    - meal_mate/lib/app/router.dart (comment update for recipeRoutes)

key-decisions:
  - "servingSizeProvider generated name (not servingSizeNotifierProvider) — riverpod_generator 4.x names provider after the class stripping 'Notifier' suffix; callers must use servingSizeProvider(n)"
  - "Image.network used instead of CachedNetworkImage — cached_network_image not in pubspec; using error/loading builders for equivalent UX"
  - "recipe_routes.dart placeholder updated in-place rather than adding new route — avoids /recipes/:id conflict with existing nested route under /recipes"
  - "Scaling is pure ephemeral computation — original amounts in Drift never modified; scale formula applied at widget build time"

patterns-established:
  - "Pattern: formatAmount utility — centralized amount formatting in utils/; never inline in widgets"
  - "Pattern: servingSizeProvider family — one provider instance per originalServings key; scope bounded to detail screen lifecycle"

requirements-completed: [RECP-02, RECP-03]

duration: 5min
completed: 2026-03-05
---

# Phase 4 Plan 03: Recipe Detail Screen Summary

**Recipe detail screen with proportional serving scaler — formatAmount utility, servingSizeProvider notifier family, RecipeDetailScreen (hero image/ingredients/instructions), IngredientListTile with scaling math, and /recipes/:id route live replacing placeholder**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-05T20:19:48Z
- **Completed:** 2026-03-05T20:24:48Z
- **Tasks:** 2 (Task 1 TDD with 9 tests)
- **Files modified:** 10 (7 created, 3 modified)

## Accomplishments

- `formatAmount(double)` pure function: whole numbers as integers, max 2 decimal places, trailing zeros stripped — all 6 formatAmount test cases pass
- `ServingSizeNotifier` Riverpod notifier family: initializes to recipe's original servings, increment/decrement (min 1)/setTo; ephemeral UI state never written to Drift
- `RecipeDetailScreen` with loading spinner, error + retry button, hero image (Image.network with fallback), cook time, ServingScalerWidget, ingredient ListView, numbered instruction list
- `/recipes/:id` route live — replaced `_RecipeDetailPlaceholder` in `recipe_routes.dart` with `RecipeDetailScreen`

## Task Commits

Each task was committed atomically:

1. **Task 1: Serving scaler provider, formatAmount utility, and unit tests** - `d82b650` (feat) [TDD]
2. **Task 2: Recipe detail screen with ingredients, instructions, serving scaler, and route** - `b6bfa80` (feat)

**Plan metadata:** (to be committed with docs commit)

## Files Created/Modified

- `meal_mate/lib/features/recipes/utils/format_amount.dart` - Pure formatAmount utility (whole int, 2dp, strip trailing zeros)
- `meal_mate/lib/features/recipes/presentation/providers/recipe_detail_provider.dart` - recipeDetailProvider (FutureProvider.family) + ServingSizeNotifier
- `meal_mate/lib/features/recipes/presentation/providers/recipe_detail_provider.g.dart` - Generated Riverpod code
- `meal_mate/lib/features/recipes/presentation/screens/recipe_detail_screen.dart` - Full detail screen (140+ lines)
- `meal_mate/lib/features/recipes/presentation/widgets/serving_scaler_widget.dart` - Increment/decrement serving controls
- `meal_mate/lib/features/recipes/presentation/widgets/ingredient_list_tile.dart` - Scaled ingredient row with fallback
- `meal_mate/test/features/recipes/presentation/serving_scaler_test.dart` - 9 unit tests (formatAmount + scaling math)
- `meal_mate/lib/features/recipes/presentation/recipe_routes.dart` - Replaced placeholder with RecipeDetailScreen

## Decisions Made

- **servingSizeProvider not servingSizeNotifierProvider:** riverpod_generator 4.x strips the `Notifier` suffix when naming the family provider. Updated all callers to use `servingSizeProvider(originalServings)`.
- **Image.network over CachedNetworkImage:** `cached_network_image` is absent from `pubspec.yaml`; `Image.network` with `errorBuilder`/`loadingBuilder` provides equivalent UX without adding a new dependency.
- **recipe_routes.dart updated in-place:** Plan 02 had already created `/recipes/:id` as a nested route under `/recipes`. Adding a top-level `/recipes/:id` in `app_router.dart` would conflict. Correct approach: update the existing nested route's builder.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] servingSizeProvider name mismatch from codegen**
- **Found during:** Task 2 (dart analyze)
- **Issue:** Code used `servingSizeNotifierProvider` but riverpod_generator 4.x generates `servingSizeProvider` for `ServingSizeNotifier` class (strips `Notifier` suffix from provider family name)
- **Fix:** Replaced all `servingSizeNotifierProvider` references with `servingSizeProvider` in `recipe_detail_screen.dart` and `serving_scaler_widget.dart`
- **Files modified:** `recipe_detail_screen.dart`, `serving_scaler_widget.dart`
- **Verification:** `dart analyze` exits 0 on all new files
- **Committed in:** `b6bfa80` (Task 2 commit)

**2. [Rule 3 - Blocking] CachedNetworkImage not available — used Image.network**
- **Found during:** Task 2 (pubspec check before implementation)
- **Issue:** Plan specifies `CachedNetworkImage` but `cached_network_image` is not in `pubspec.yaml`; importing it would fail build
- **Fix:** Used `Image.network` with `errorBuilder` (placeholder icon) and `loadingBuilder` (progress indicator) — equivalent UX without new dependency
- **Files modified:** `recipe_detail_screen.dart`
- **Verification:** `dart analyze` exits 0
- **Committed in:** `b6bfa80` (Task 2 commit)

**3. [Rule 1 - Bug] /recipes/:id route already existed as nested route from Plan 02**
- **Found during:** Task 2 (code discovery)
- **Issue:** `recipe_routes.dart` from Plan 02 already defined `/recipes/:id` as a child route under `/recipes`. Adding a top-level route in `app_router.dart` would create a GoRouter conflict.
- **Fix:** Updated `recipe_routes.dart` in-place to replace `_RecipeDetailPlaceholder` with `RecipeDetailScreen`; removed the duplicate route from `app_router.dart`
- **Files modified:** `recipe_routes.dart`, `app_router.dart` (Core router)
- **Verification:** `dart analyze` exits 0; router structure intact
- **Committed in:** `b6bfa80` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking)
**Impact on plan:** All required for correctness and compilability. No scope creep.

## Issues Encountered

None beyond the three auto-fixed deviations above.

## User Setup Required

None — no external service configuration required for this plan.

## Next Phase Readiness

- Recipe detail screen complete — users can navigate from browse to `/recipes/:id` and see full recipe info
- Serving scaler is live — ingredient quantities update proportionally; ephemeral state scoped to screen
- 04-05 (meal planning) can link "Add to meal plan" button from `RecipeDetailScreen`
- Pre-existing errors in `recipe_browse_screen.dart` and `filter_chips_row.dart` (from Plan 04-02) are deferred and out of scope for this plan

## Self-Check: PASSED

All 8 files confirmed on disk. Both task commits (d82b650, b6bfa80) confirmed in git log. 17 tests passing.

---
*Phase: 04-recipe-discovery*
*Completed: 2026-03-05*
