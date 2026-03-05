---
phase: 05-weekly-meal-planner
plan: 03
subsystem: ui
tags: [flutter, drag-and-drop, LongPressDraggable, DragTarget, riverpod, drift]

# Dependency graph
requires:
  - phase: 05-01
    provides: MealPlanNotifier with swapSlots/assignRecipe/clearSlot, MealSlot domain model
  - phase: 05-02
    provides: PlannerGrid, MealSlotCard, EmptySlotCard widget structure
provides:
  - LongPressDraggable<MealSlot> on filled meal slot cards with ghost placeholder and feedback widget
  - DragTarget<MealSlot> on every slot cell (filled and empty) via _SlotCell widget
  - swapSlots called on drop-onto-filled; assignRecipe+clearSlot on drop-onto-missing-row
  - Horizontal scroll disabled during drag (NeverScrollableScrollPhysics) to prevent gesture conflict
  - Auto-scroll near left/right edges using Timer.periodic + ScrollController
  - isHovered param on EmptySlotCard with AnimatedContainer highlight and Drop-here hint
  - PlannerGrid converted to ConsumerStatefulWidget owning _isDragging and _scrollController state
affects: [05-04, shopping-list]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ConsumerStatefulWidget for widgets needing both Riverpod and local state
    - Extracted _SlotCell widget as DragTarget wrapper to keep PlannerGrid grid-building logic clean
    - onDragStarted/onDragEnd VoidCallback threading from PlannerGrid down to MealSlotCard
    - Timer.periodic for edge-triggered auto-scroll while drag is active

key-files:
  created: []
  modified:
    - meal_mate/lib/features/meal_planner/presentation/widgets/meal_slot_card.dart
    - meal_mate/lib/features/meal_planner/presentation/widgets/planner_grid.dart
    - meal_mate/lib/features/meal_planner/presentation/widgets/empty_slot_card.dart

key-decisions:
  - "PlannerGrid converted from ConsumerWidget to ConsumerStatefulWidget to own _isDragging ValueNotifier and ScrollController for auto-scroll"
  - "_SlotCell extracted as a separate StatelessWidget to encapsulate DragTarget logic cleanly, keeping _buildGrid readable"
  - "Drop onto slot with existing row but no recipeId also uses swapSlots (Drift handles empty-to-filled swap correctly)"
  - "Drop onto slot with NO row in DB uses assignRecipe+clearSlot pair since swapSlots requires both IDs to exist"
  - "Auto-scroll timer polls every 80ms; scroll step is 60px — tuned to feel responsive without overshooting"

patterns-established:
  - "Drag lifecycle callbacks (onDragStarted/onDragEnd) thread as VoidCallbacks from parent grid down to card widgets"
  - "DragTarget wrapper extracted into _SlotCell to isolate drop-acceptance logic from grid layout"

requirements-completed: [PLAN-04]

# Metrics
duration: 2min
completed: 2026-03-05
---

# Phase 5 Plan 03: Drag-and-Drop Meal Rescheduling Summary

**LongPressDraggable/DragTarget drag-and-drop on the planner grid: long-press to drag filled meals, swap or move on drop, with ghost placeholder, hover highlights, horizontal-scroll conflict mitigation, and edge-triggered auto-scroll.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-05T22:25:24Z
- **Completed:** 2026-03-05T22:27:30Z
- **Tasks:** 2 (implemented together in one pass)
- **Files modified:** 3

## Accomplishments

- MealSlotCard wrapped in `LongPressDraggable<MealSlot>` with 200ms delay, haptic feedback, ghost placeholder (`childWhenDragging`), and elevated semi-transparent feedback widget
- All 21 planner cells wrapped in `DragTarget<MealSlot>` via the new `_SlotCell` widget — `onWillAcceptWithDetails` rejects same-cell drops; `onAcceptWithDetails` calls `swapSlots` or `assignRecipe+clearSlot` based on target state
- Horizontal scroll disabled during active drag (`NeverScrollableScrollPhysics`) to prevent gesture conflicts; auto-scroll fires via `Timer.periodic(80ms)` when pointer is within 48px of either edge
- `EmptySlotCard` gains `isHovered` param — animated border and "Drop here" label appear when a drag candidate hovers over it
- PlannerGrid converted to `ConsumerStatefulWidget` to own `_isDragging` flag and `ScrollController`

## Task Commits

1. **Task 1: LongPressDraggable on filled slots + DragTarget on all slots** - `f148bcd` (feat)
   _(Task 2 polish and edge cases implemented in same pass — empty week renders 21 cells, cancel returns card, auto-scroll active during drag)_

## Files Created/Modified

- `meal_mate/lib/features/meal_planner/presentation/widgets/meal_slot_card.dart` — LongPressDraggable wrapper, ghost placeholder, compact feedback card, onDragStarted/onDragEnd callbacks
- `meal_mate/lib/features/meal_planner/presentation/widgets/planner_grid.dart` — ConsumerStatefulWidget, _SlotCell DragTarget extractor, scroll physics toggle, Listener for pointer tracking, Timer auto-scroll
- `meal_mate/lib/features/meal_planner/presentation/widgets/empty_slot_card.dart` — isHovered param, AnimatedContainer border/colour, "Drop here" label

## Decisions Made

- PlannerGrid converted to `ConsumerStatefulWidget` to own local drag state alongside Riverpod watching — this is idiomatic Flutter when widget needs both
- `_SlotCell` extracted as a private `StatelessWidget` so DragTarget logic is co-located and `_buildGrid` stays clean
- Drop onto existing-but-empty slot row uses `swapSlots` (Drift swap handles null recipeId correctly); drop onto slot with no DB row uses `assignRecipe+clearSlot` pair
- Auto-scroll timer: 80ms period, 60px step, 48px edge threshold — tuned for responsive feel without overshoot

## Deviations from Plan

None - plan executed exactly as written. Tasks 1 and 2 were implemented in a single unified pass since the polish and edge cases (auto-scroll, empty week grid, cancel handling) were natural continuations of the core drag implementation.

## Issues Encountered

- `dart analyze` flagged `hapticFeedbackOnStart: true` as redundant (default value) — removed the redundant argument; no other issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Drag-and-drop rescheduling is fully functional; PlannerGrid now supports move and swap gestures
- Ready for Phase 05-04 (shopping list generation or template saving) — the planner grid API is stable
- No blockers

---
*Phase: 05-weekly-meal-planner*
*Completed: 2026-03-05*
