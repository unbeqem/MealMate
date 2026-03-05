---
phase: 05-weekly-meal-planner
plan: 02
subsystem: ui
tags: [flutter, riverpod, go_router, meal-planner, weekly-grid, slot-cards]

requires:
  - phase: 05-01
    provides: MealPlanNotifier (family StreamNotifier), MealSlot domain model, mealPlanNotifierProvider

provides:
  - PlannerScreen (ConsumerStatefulWidget with week navigation + PlannerGrid)
  - PlannerGrid (7-day x 3-meal horizontally scrollable grid)
  - MealSlotCard (filled slot with thumbnail, title, replace/remove inline icons)
  - EmptySlotCard (dashed-style border with + icon, tap-to-pick flow)
  - mealPlannerRoutes (/planner, /planner/templates GoRouter routes)
  - TemplateListScreen placeholder (for Plan 05-04)
  - Home screen Meal Planner navigation card
  - RecipeBrowseScreen selectForSlot mode (pops back with recipe data)

affects:
  - 05-03 (drag-and-drop builds on MealSlotCard and PlannerGrid)
  - 05-04 (TemplateListScreen placeholder is replaced with full UI)
  - 05-05 (ingredient suggestions reads filled slots via getFilledSlots)

tech-stack:
  added: []
  patterns:
    - "GoRouter query param ?selectForSlot=true switches RecipeBrowseScreen to selection mode — pops Map<String,dynamic> with recipeId/recipeTitle/recipeImage"
    - "context.push<Map<String,dynamic>>(...).then((result) => assignRecipe(...)) pattern for slot assignment from sub-screen"
    - "Fixed left label column + horizontally scrollable day columns via Row + SingleChildScrollView for grid layout"
    - "Stack-based MealSlotCard: full-bleed thumbnail, bottom title bar, top-right action icons"

key-files:
  created:
    - meal_mate/lib/features/meal_planner/presentation/screens/planner_screen.dart
    - meal_mate/lib/features/meal_planner/presentation/widgets/planner_grid.dart
    - meal_mate/lib/features/meal_planner/presentation/widgets/meal_slot_card.dart
    - meal_mate/lib/features/meal_planner/presentation/widgets/empty_slot_card.dart
    - meal_mate/lib/features/meal_planner/presentation/meal_planner_routes.dart
    - meal_mate/lib/features/meal_planner/presentation/screens/template_list_screen.dart
  modified:
    - meal_mate/lib/app/router.dart
    - meal_mate/lib/features/home/presentation/screens/home_screen.dart
    - meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart

key-decisions:
  - "[Phase 05-02]: RecipeBrowseScreen reads GoRouterState.of(context).uri.queryParameters for selectForSlot mode — no constructor params required, backward compatible with all existing callers"
  - "[Phase 05-02]: Filter chips row hidden in selectForSlot mode to keep recipe picker UI focused"
  - "[Phase 05-02]: MealSlotCard uses Stack with full-bleed Image.network thumbnail — consistent with Image.network decision from Phase 04 (no CachedNetworkImage for new widgets)"
  - "[Phase 05-02]: _SelectableRecipeCard wraps existing RecipeCard via GestureDetector — avoids duplicating card rendering logic"
  - "[Phase 05-02]: PlannerScreen avoids intl package — uses manual month name array to format date range, keeping dependency count minimal"

patterns-established:
  - "Select-for-slot navigation pattern: push /recipes?selectForSlot=true, await pop result Map, call assignRecipe on notifier"
  - "Week navigation: mondayOf(DateTime) utility normalises any date to UTC midnight Monday"

requirements-completed: [PLAN-01, PLAN-02, PLAN-03]

duration: 4min
completed: "2026-03-05"
---

# Phase 05 Plan 02: Planner Grid UI Summary

**7-day x 3-meal planner grid with week navigation, MealSlotCard/EmptySlotCard widgets, GoRouter /planner route, home screen entry point, and RecipeBrowseScreen select-for-slot mode for tap-to-assign recipe flow.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-05T21:59:36Z
- **Completed:** 2026-03-05T22:03:18Z
- **Tasks:** 2
- **Files modified:** 8 (3 modified, 5 created)

## Accomplishments

- PlannerScreen with prev/next week navigation arrows and tappable date-range label opening `showDatePicker`
- PlannerGrid renders fixed meal-type label column (B/L/D) plus 7 horizontally scrollable day columns, each with 3 slot cells driven by `mealPlanNotifierProvider(weekStart)` stream
- MealSlotCard: full-bleed thumbnail via `Image.network`, semi-transparent bottom title bar, and top-right replace/remove icon buttons wired to `assignRecipe`/`clearSlot`
- EmptySlotCard: dashed-style container with centered `+` icon, tap navigates to recipe picker
- GoRouter routes `/planner` and `/planner/templates` registered and spread into app router
- Home screen Meal Planner card added below Browse Recipes
- `RecipeBrowseScreen` supports `?selectForSlot=true` query param — changes title, hides filter chips, wraps recipe cards with `_SelectableRecipeCard` that pops with `{recipeId, recipeTitle, recipeImage}` on tap

## Task Commits

Each task was committed atomically:

1. **Task 1: Planner screen, grid layout, and slot card widgets** - `7173b1a` (feat)
2. **Task 2: Route registration, home screen card, and select-for-slot mode** - `661df33` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `meal_mate/lib/features/meal_planner/presentation/screens/planner_screen.dart` - ConsumerStatefulWidget with week navigation and PlannerGrid body
- `meal_mate/lib/features/meal_planner/presentation/widgets/planner_grid.dart` - 7-column x 3-row grid with fixed label column and horizontal scroll
- `meal_mate/lib/features/meal_planner/presentation/widgets/meal_slot_card.dart` - Filled slot card with Stack layout (thumbnail, title, action icons)
- `meal_mate/lib/features/meal_planner/presentation/widgets/empty_slot_card.dart` - Dashed-style empty slot with + icon and navigate-to-picker on tap
- `meal_mate/lib/features/meal_planner/presentation/meal_planner_routes.dart` - GoRouter route definitions for /planner and /planner/templates
- `meal_mate/lib/features/meal_planner/presentation/screens/template_list_screen.dart` - Placeholder screen for Plan 05-04
- `meal_mate/lib/app/router.dart` - Added ...mealPlannerRoutes spread and import
- `meal_mate/lib/features/home/presentation/screens/home_screen.dart` - Added Meal Planner ListTile card
- `meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart` - Added selectForSlot mode, _SelectableRecipeCard, isSelectMode param propagation

## Decisions Made

- RecipeBrowseScreen reads `GoRouterState.of(context).uri.queryParameters` for select mode — no constructor params required, backward compatible with existing const usage in recipe_routes.dart.
- Filter chips row is hidden in select mode to keep the recipe picker UI focused on the task.
- `_SelectableRecipeCard` wraps existing `RecipeCard` via `GestureDetector` + `context.pop()` — avoids duplicating card rendering logic.
- `PlannerScreen` formats date range without `intl` package (manual month name array) — keeps dependency footprint minimal.
- `MealSlotCard` uses `Image.network` consistent with the Phase 04 decision (CachedNetworkImage not used for new widgets to keep consistent with project image loading pattern).

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Planner grid UI is fully functional: users can view the 7-day grid, tap empty slots to pick recipes, and tap replace/remove on filled slots
- Plan 05-03 (drag-and-drop swap) can build directly on `MealSlotCard` and `PlannerGrid` — `swapSlots` notifier method from 05-01 is ready
- Plan 05-04 (templates UI) replaces the `TemplateListScreen` placeholder — `TemplateNotifier` from 05-01 is ready
- Plan 05-05 (ingredient suggestions) reads `getFilledSlots` — data layer is ready

---
*Phase: 05-weekly-meal-planner*
*Completed: 2026-03-05*

## Self-Check: PASSED

All 6 created files verified on disk. Both task commits verified:
- `7173b1a` — feat(05-02): Planner screen, grid layout, and slot card widgets
- `661df33` — feat(05-02): Route registration, home screen card, and select-for-slot mode
