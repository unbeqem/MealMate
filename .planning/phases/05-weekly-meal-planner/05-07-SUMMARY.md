---
phase: 05-weekly-meal-planner
plan: 07
subsystem: meal-planner-ui
tags: [bug-fix, gap-closure, planner-grid, recipe-picker]
one_liner: "Fixed grid scroll showing only 3 days (LayoutBuilder constraint fix) and recipe picker double-tap freeze (GestureDetector removed, onTap routed through RecipeCard)"
dependency_graph:
  requires: []
  provides: [planner-grid-full-scroll, recipe-picker-clean-pop]
  affects: [planner_grid.dart, recipe_card.dart, recipe_browse_screen.dart]
tech_stack:
  added: []
  patterns:
    - "LayoutBuilder constraints.maxWidth for dynamic column sizing"
    - "Optional VoidCallback onTap override on RecipeCard for context-sensitive tap behavior"
key_files:
  modified:
    - meal_mate/lib/features/meal_planner/presentation/widgets/planner_grid.dart
    - meal_mate/lib/features/recipes/presentation/recipe_card.dart
    - meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart
decisions:
  - "columnWidth now derived from LayoutBuilder constraints.maxWidth * 0.35 — fully inside LayoutBuilder builder callback so it correctly reflects the scrollable area width, not the full screen width"
  - "RecipeCard gains optional VoidCallback? onTap param; default behavior (detail navigation) preserved when null; _SelectableRecipeCard passes pop callback via this param — eliminates GestureDetector + InkWell conflict"
metrics:
  duration: 2 min
  completed_date: "2026-03-05"
  tasks: 2
  files_modified: 3
---

# Phase 05 Plan 07: Gap Closure — Grid Scroll and Recipe Picker Bugs Summary

Fixed two UAT bugs identified in phase 05 user testing: the planner grid only showing ~3 day columns because columnWidth was derived from full screen width, and the recipe picker double-tap conflict causing navigator stack corruption and UI freeze.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fix planner grid columnWidth to use LayoutBuilder constraints | 172b8c8 | planner_grid.dart |
| 2 | Fix recipe picker double-tap by adding onTap param to RecipeCard | a74bcde | recipe_card.dart, recipe_browse_screen.dart |

## What Was Built

### Task 1: Planner Grid Scroll Fix

**Bug:** `columnWidth = MediaQuery.of(context).size.width * 0.35` was computed from the full screen width. With the fixed 32px label column subtracted, each day column was too wide, causing only ~3 columns to appear on screen with no effective horizontal scroll to reveal the remaining days.

**Fix:** Moved `columnWidth` declaration inside the `LayoutBuilder` builder callback (immediately after `_scrollAreaWidth = constraints.maxWidth`) and changed the computation to `constraints.maxWidth * 0.35`. Since `constraints.maxWidth` reflects the actual available width of the scrollable area (after the label column), each column is correctly sized to show ~2.8 days, with all 7 days accessible via horizontal scroll.

### Task 2: Recipe Picker Double-Tap Fix

**Bug:** `_SelectableRecipeCard` wrapped `RecipeCard` in a `GestureDetector`. When the user tapped, both the `GestureDetector.onTap` (pop) and `RecipeCard`'s internal `InkWell.onTap` (push to detail) fired, causing the navigator stack to get a push immediately followed by a pop — resulting in visible navigation corruption and occasional UI freeze.

**Fix:**
1. Added optional `VoidCallback? onTap` parameter to `RecipeCard`. The `InkWell.onTap` now evaluates `onTap ?? () => context.push('/recipes/${recipe.id}')` — default behavior is preserved for all existing callers.
2. Removed the `GestureDetector` wrapper from `_SelectableRecipeCard`. The pop callback is passed directly via `RecipeCard(onTap: () { context.pop(...); })`. Only one tap handler fires — the pop — so navigation is clean.

## Verification

All checks passed:

- `grep -n "constraints.maxWidth * 0.35" planner_grid.dart` — line 222 confirmed
- `grep -n "this.onTap" recipe_card.dart` — line 13 confirmed
- `grep -c "GestureDetector" recipe_browse_screen.dart` — returns 0 (removed)
- `flutter analyze --no-fatal-infos` — no errors in modified files (only pre-existing widget_test.dart unrelated error)

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

### Files Exist

- `meal_mate/lib/features/meal_planner/presentation/widgets/planner_grid.dart` — modified
- `meal_mate/lib/features/recipes/presentation/recipe_card.dart` — modified
- `meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart` — modified

### Commits Exist

- 172b8c8 — Task 1
- a74bcde — Task 2
