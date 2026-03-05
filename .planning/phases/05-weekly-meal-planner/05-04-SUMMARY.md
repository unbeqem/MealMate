---
phase: 05-weekly-meal-planner
plan: "04"
subsystem: ui
tags: [flutter, riverpod, go_router, drift, meal-planner, templates]

requires:
  - phase: 05-01
    provides: TemplateNotifier, TemplateRepository, PlanTemplate domain model
  - phase: 05-02
    provides: PlannerScreen with placeholder overflow menu, meal_planner_routes.dart

provides:
  - TemplateListScreen: ConsumerWidget with empty state, template cards, load flow, delete flow
  - Save as Template: name dialog + filled-slot validation in PlannerScreen overflow menu
  - Load Template: navigation to TemplateListScreen with weekStart query param
  - Route: /planner/templates parses week epochMs query param and passes weekStart to screen

affects: [05-05, 06-shopping-list, testing]

tech-stack:
  added: []
  patterns:
    - "Template load: date picker -> replace-all vs fill-empty dialog -> notifier call -> SnackBar + pop"
    - "Route param passing: epochMs in query string, parsed in route builder, falls back to current Monday"
    - "AsyncValue pattern matching: switch(asyncValue) { AsyncData(:final value) => value, _ => fallback }"

key-files:
  created:
    - meal_mate/lib/features/meal_planner/presentation/screens/template_list_screen.dart
  modified:
    - meal_mate/lib/features/meal_planner/presentation/screens/planner_screen.dart
    - meal_mate/lib/features/meal_planner/presentation/meal_planner_routes.dart

key-decisions:
  - "weekStart passed to TemplateListScreen via query param ?week=<epochMs> — avoids GoRouter extra complexity"
  - "AsyncValue read with switch pattern (not valueOrNull) — Riverpod 3.x stream notifier compat"
  - "Slot check before save dialog: read mealPlanNotifierProvider synchronously to avoid UX flicker"

patterns-established:
  - "Two-step load dialog: DatePicker -> AlertDialog for mode choice -> notifier -> SnackBar -> pop"
  - "Day-density preview: 7 colour-coded dots computed from template.slots.where(recipeId != null)"

requirements-completed: [PLAN-05, PLAN-06]

duration: 2min
completed: 2026-03-05
---

# Phase 5 Plan 04: Template Save/Load Summary

**Full template save/load UI: name-dialog save with slot validation, TemplateListScreen with 7-dot density preview, two-step load flow (week picker + replace/fill choice), and delete confirmation**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-05T22:25:34Z
- **Completed:** 2026-03-05T22:27:34Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- TemplateListScreen displays saved templates with name, creation date, and a 7-dot day-density preview row indicating which days have at least one meal
- Load action: DatePicker pre-filled with current week + AlertDialog for "Replace all" vs "Fill empty slots only" — calls TemplateNotifier.loadTemplate, shows SnackBar, pops back to planner
- Delete action: AlertDialog confirmation — calls TemplateNotifier.deleteTemplate, shows SnackBar
- Empty state: icon + two lines of guidance text when no templates exist
- PlannerScreen overflow menu "Save as Template": validates at least one filled slot, shows name TextField dialog (max 30 chars, autofocus), calls saveCurrentWeek, shows success SnackBar
- PlannerScreen "Load Template": navigates to /planner/templates?week=<epochMs>
- meal_planner_routes.dart: parses week query param (epochMs), passes resolved weekStart to TemplateListScreen; falls back to current Monday if param absent/malformed

## Task Commits

1. **Task 1: Template list screen with load and delete** - `a7f2cfd` (feat)
2. **Task 2: Wire planner overflow menu to save/load template actions** - `52afa04` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `meal_mate/lib/features/meal_planner/presentation/screens/template_list_screen.dart` - Full TemplateListScreen replacing placeholder; empty state, template card list with density dots, load + delete actions
- `meal_mate/lib/features/meal_planner/presentation/screens/planner_screen.dart` - Overflow menu wired: Save as Template (name dialog + slot validation), Load Template (navigation with weekStart)
- `meal_mate/lib/features/meal_planner/presentation/meal_planner_routes.dart` - /planner/templates route parses ?week= query param and injects weekStart into TemplateListScreen constructor

## Decisions Made

- weekStart passed via query param `?week=<epochMs>` rather than GoRouter `extra` — query params survive hot reload and are easier to test
- Used `switch(asyncValue) { AsyncData(:final value) => value, _ => fallback }` instead of `valueOrNull` — Riverpod 3.x stream notifiers do not expose `valueOrNull` on the `AsyncValue` type in the analyzer
- Synchronous `ref.read(mealPlanNotifierProvider(_weekStart))` for slot check before showing save dialog — avoids async gap that would cause mounted check issues in dialog flow

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced valueOrNull with switch pattern matching**
- **Found during:** Task 2 (wire planner overflow menu)
- **Issue:** `AsyncValue.valueOrNull` not available on `AsyncValue<List<MealSlot>>` from stream notifier in Riverpod 3.x — dart analyze returned `undefined_getter` error
- **Fix:** Used Dart 3 switch pattern: `switch(slotsAsync) { AsyncData(:final value) => value, _ => <MealSlot>[] }`; added `MealSlot` import
- **Files modified:** meal_mate/lib/features/meal_planner/presentation/screens/planner_screen.dart
- **Verification:** `dart analyze` reported no issues
- **Committed in:** 52afa04 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Fix required for the slot-check guard before saving. No scope creep.

## Issues Encountered

None beyond the valueOrNull API mismatch (handled automatically above).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Template save/load UI is fully wired end-to-end
- PlannerScreen and TemplateListScreen both rely on reactive Drift streams via MealPlanNotifier — grid updates automatically after template load without explicit refresh
- Plan 05-05 (sharing / export) or subsequent phases can proceed

---
*Phase: 05-weekly-meal-planner*
*Completed: 2026-03-05*
