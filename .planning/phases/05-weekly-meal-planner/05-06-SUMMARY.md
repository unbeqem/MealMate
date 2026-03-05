---
phase: 05-weekly-meal-planner
plan: 06
subsystem: ui
tags: [riverpod, flutter, meal-planner, ingredient-reuse, cache]

# Dependency graph
requires:
  - phase: 05-weekly-meal-planner
    provides: weekIngredientNamesProvider, ingredientOverlapCountProvider, IngredientOverlapBadge — overlap infrastructure built in plan 05-05
  - phase: 04-recipe-discovery
    provides: CachedRecipes table with isSummaryOnly flag and jsonData containing extendedIngredients
provides:
  - cachedRecipeIngredientNamesProvider that looks up lowercased ingredient names from CachedRecipes for a given recipe ID
  - _SelectableRecipeCard wired to pass real ingredient names to ingredientOverlapCountProvider instead of const []
affects: [05-weekly-meal-planner, PLAN-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Best-effort overlap badge: provider returns empty list for summary-only cache entries rather than forcing API fetch"
    - "Positional-param FutureProvider family for single-entity cache lookup keyed on int ID"

key-files:
  created: []
  modified:
    - meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.dart
    - meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.g.dart
    - meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart

key-decisions:
  - "cachedRecipeIngredientNamesProvider is best-effort: returns empty list for summary-only CachedRecipes entries to avoid exhausting Spoonacular quota on every search result"
  - "Overlap badge wiring uses AsyncData switch pattern: candidateNames falls back to empty list while provider is loading — badge stays hidden during initial load"

patterns-established:
  - "cachedRecipeIngredientNamesProvider pattern: positional-param FutureProvider family keyed on int recipeId, returns List<String>, gracefully returns [] on missing or summary-only entries"

requirements-completed: [PLAN-07]

# Metrics
duration: 5min
completed: 2026-03-05
---

# Phase 5 Plan 06: Ingredient Overlap Badge Wiring Summary

**cachedRecipeIngredientNamesProvider added to look up cached extendedIngredients per recipe, wiring _SelectableRecipeCard's overlap badge to show real ingredient reuse counts instead of always 0**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-05T22:21:00Z
- **Completed:** 2026-03-05T22:26:13Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `cachedRecipeIngredientNamesProvider` — a positional-param FutureProvider family that looks up a recipe's lowercased ingredient names from CachedRecipes, returning empty list for summary-only (no extendedIngredients) entries
- Hand-crafted Riverpod 3.x codegen entry in `.g.dart` following the exact pattern of the two existing providers in the file
- Updated `_SelectableRecipeCard.build()` to watch `cachedRecipeIngredientNamesProvider(recipe.id)` and pass the resulting names to `ingredientOverlapCountProvider`, replacing the permanent `const []` that caused the badge to always show 0
- All 17 recipe tests pass; full project `dart analyze` shows no new errors from these changes

## Task Commits

Each task was committed atomically:

1. **Task 1: Add cachedRecipeIngredientNamesProvider and wire overlap badge** - `bafd4d0` (feat)
2. **Task 2: Full project verification and regression check** - verification only, no new code changes

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.dart` - Added `cachedRecipeIngredientNamesProvider` below existing two providers
- `meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.g.dart` - Added hand-crafted codegen entry for `CachedRecipeIngredientNamesProvider` / `CachedRecipeIngredientNamesFamily`
- `meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart` - Updated `_SelectableRecipeCard` to watch `cachedRecipeIngredientNamesProvider` and pass real names to `ingredientOverlapCountProvider`

## Decisions Made
- `cachedRecipeIngredientNamesProvider` is best-effort: returns `[]` for summary-only entries rather than fetching full detail from Spoonacular. This prevents quota exhaustion on every search result page load. Recipes the user has previously viewed in detail will show accurate overlap counts.
- Overlap badge falls back to `<String>[]` while the async provider is loading (using `AsyncData` switch pattern) — badge stays hidden during initial load, no flicker.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None - `dart analyze` ran cleanly on both modified files. `dart test` required `flutter test` instead (pre-existing project convention); all 17 recipe tests passed.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PLAN-07 gap closed: the recipe picker in selectForSlot mode now surfaces ingredient reuse information for recipes with full cached detail
- Recipes without full detail (never viewed) gracefully show 0 overlap — correct best-effort behavior
- Ingredient reuse infrastructure (weekIngredientNamesProvider + ingredientOverlapCountProvider + IngredientOverlapBadge + cachedRecipeIngredientNamesProvider) is complete and fully wired

---
*Phase: 05-weekly-meal-planner*
*Completed: 2026-03-05*
