---
phase: 05-weekly-meal-planner
plan: 05
subsystem: ui
tags: [flutter, riverpod, drift, ingredient-reuse, meal-planner, weekly-grid]

requires:
  - phase: 05-01
    provides: MealPlanNotifier (family StreamNotifier), MealSlot domain model, mealPlanNotifierProvider, CachedRecipes table with jsonData
  - phase: 05-02
    provides: RecipeBrowseScreen selectForSlot mode with week query param, PlannerScreen body column structure

provides:
  - weekIngredientNamesProvider (family FutureProvider, DateTime weekStart -> Set<String>)
  - ingredientOverlapCountProvider (family sync Provider, weekStart + candidateIngredientNames -> int)
  - IngredientOverlapBadge widget (eco icon + "N shared" label, hidden when count is 0)
  - WeekIngredientSummary widget (ExpansionTile listing all unique ingredient names for the week)
  - RecipeBrowseScreen selectForSlot badges: "Planned" chip + IngredientOverlapBadge on recipe cards
  - PlannerScreen WeekIngredientSummary panel below PlannerGrid

affects:
  - 06-shopping-list (weekIngredientNamesProvider is a preview of what the shopping list will aggregate)

tech-stack:
  added: []
  patterns:
    - "weekIngredientNamesProvider uses switch(asyncValue) { AsyncData(:final value) => value, _ => [] } pattern for safe slot list access"
    - "ingredientOverlapCountProvider is a sync @riverpod returning int — wraps async FutureProvider via .when() returning 0 on loading/error"
    - "RecipeSummary from complexSearch is summary-only — overlap badge best-effort (0 for standard search results, non-zero only when full recipe is cached)"
    - "_SelectableRecipeCard converted ConsumerWidget to watch mealPlanNotifierProvider for 'Planned' badge"

key-files:
  created:
    - meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.dart
    - meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.g.dart
    - meal_mate/lib/features/meal_planner/presentation/widgets/ingredient_overlap_badge.dart
    - meal_mate/lib/features/meal_planner/presentation/widgets/week_ingredient_summary.dart
  modified:
    - meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart
    - meal_mate/lib/features/meal_planner/presentation/screens/planner_screen.dart

key-decisions:
  - "[Phase 05-05]: weekIngredientNamesProvider skips summary-only CachedRecipes entries (isSummaryOnly=true) — extendedIngredients only present in full detail entries"
  - "[Phase 05-05]: ingredientOverlapCountProvider is synchronous (not Future) — wraps weekIngredientNamesProvider.when() to return 0 on loading, enabling instant render without skeleton states"
  - "[Phase 05-05]: Overlap badge is best-effort in RecipeBrowseScreen — RecipeSummary from complexSearch has no extendedIngredients, so badge shows 0 for all standard search cards; badge will show non-zero only for ingredient-mode results where full cache is populated"
  - "[Phase 05-05]: WeekIngredientSummary placed as fixed panel below PlannerGrid in body Column (not inside ScrollView) — keeps grid scrollable independently while summary always visible at bottom"
  - "[Phase 05-05]: 'Planned' badge uses mealPlanNotifierProvider + switch(AsyncData) pattern — consistent with existing codebase patterns, no new async pattern introduced"

patterns-established:
  - "Ingredient overlap detection: parse extendedIngredients[].name from CachedRecipes.jsonData, lowercase, intersect with candidate set"
  - "Best-effort badges: show when data available, hide gracefully (SizedBox.shrink / count==0) when data unavailable — no error states needed"

requirements-completed: [PLAN-07]

duration: 3min
completed: "2026-03-05"
---

# Phase 05 Plan 05: Ingredient Reuse Suggestions Summary

**Riverpod providers computing ingredient overlap between week's plan and candidate recipes, with an eco-icon overlap badge on recipe picker cards and an expandable ingredient summary panel on the planner screen.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-05T22:05:41Z
- **Completed:** 2026-03-05T22:08:41Z
- **Tasks:** 2
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments

- `weekIngredientNamesProvider(weekStart)` — family FutureProvider that watches `mealPlanNotifierProvider`, loads each filled slot's recipe from CachedRecipes, parses `extendedIngredients[].name` from the JSON, and returns a unified `Set<String>` of lowercased ingredient names
- `ingredientOverlapCountProvider(weekStart, candidateIngredientNames)` — synchronous family provider that intersects the week ingredient set with a candidate list; returns 0 while loading (no skeleton states needed)
- `IngredientOverlapBadge` — compact widget showing `Icons.eco` + "N shared" text, hidden via `SizedBox.shrink()` when count is 0; uses `withValues(alpha:)` per Flutter deprecation guidance
- `WeekIngredientSummary` — `ExpansionTile` ConsumerWidget listing all unique ingredient names as alphabetically-sorted `Chip` widgets; hidden when week is empty
- `RecipeBrowseScreen` updated: parses `week` millisecondsSinceEpoch query param, passes `weekStart` to `_SelectableRecipeCard` (now ConsumerWidget); "Planned" chip shown for recipes already in current week's slots
- `PlannerScreen` updated: `WeekIngredientSummary` placed below `PlannerGrid` in body column

## Task Commits

Each task was committed atomically:

1. **Task 1: Ingredient reuse providers and overlap badge widget** - `533244d` (feat)
2. **Task 2: Wire overlap badge into recipe picker + week ingredient summary panel** - `5c1e23f` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.dart` - weekIngredientNamesProvider + ingredientOverlapCountProvider
- `meal_mate/lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.g.dart` - Hand-crafted Riverpod 3.x codegen for both providers
- `meal_mate/lib/features/meal_planner/presentation/widgets/ingredient_overlap_badge.dart` - IngredientOverlapBadge StatelessWidget
- `meal_mate/lib/features/meal_planner/presentation/widgets/week_ingredient_summary.dart` - WeekIngredientSummary ConsumerWidget
- `meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart` - week param parsing, _SelectableRecipeCard badges, ConsumerWidget conversion
- `meal_mate/lib/features/meal_planner/presentation/screens/planner_screen.dart` - WeekIngredientSummary import and placement

## Decisions Made

- `weekIngredientNamesProvider` skips `isSummaryOnly=true` entries from CachedRecipes — summary entries lack `extendedIngredients` so parsing them would yield nothing; this correctly gates overlap computation on having full recipe detail.
- `ingredientOverlapCountProvider` is synchronous, returning 0 on loading — avoids async cascade through all callers; overlap badge simply stays hidden until data resolves.
- The overlap badge in `RecipeBrowseScreen` is intentionally best-effort: `RecipeSummary` from Spoonacular complexSearch has no `extendedIngredients`, so `candidateIngredientNames` is always empty for standard search results. The provider correctly returns 0. Non-zero overlap would appear for ingredient-mode results if those recipes have full cache entries.
- `WeekIngredientSummary` is placed as a fixed panel below `PlannerGrid` (not inside the grid's scroll area) — users can always see the summary without scrolling the grid.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- `dart analyze` flagged `withOpacity()` deprecation in `IngredientOverlapBadge` — fixed by using `.withValues(alpha:)` (Rule 1 auto-fix, verified clean).
- `valueOrNull` getter not available on `AsyncValue` in this Riverpod version — replaced with existing `switch(AsyncData(:final value) => value, _ => [])` pattern from the codebase (Rule 3 auto-fix, verified clean).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ingredient reuse providers are reactive — any slot change immediately updates both the overlap counts and the ingredient summary panel
- `weekIngredientNamesProvider` is the foundation for Phase 6 shopping list aggregation — the set of week ingredient names maps directly to what the shopping list needs to display
- Phase 6 can extend this by using the full `MealSlot.recipeId` list and loading quantities/units from `extendedIngredients` in addition to names

---
*Phase: 05-weekly-meal-planner*
*Completed: 2026-03-05*

## Self-Check: PASSED

All 4 created files verified on disk. Both task commits verified:
- `533244d` — feat(05-05): ingredient reuse providers and overlap badge widget
- `5c1e23f` — feat(05-05): wire overlap badge into recipe picker and add week ingredient summary panel
