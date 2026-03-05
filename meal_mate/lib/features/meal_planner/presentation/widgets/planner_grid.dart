import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';
import 'package:meal_mate/features/meal_planner/presentation/widgets/empty_slot_card.dart';
import 'package:meal_mate/features/meal_planner/presentation/widgets/meal_slot_card.dart';

/// Maps each day-of-week string to its display abbreviation.
const _dayAbbreviations = {
  'monday': 'Mon',
  'tuesday': 'Tue',
  'wednesday': 'Wed',
  'thursday': 'Thu',
  'friday': 'Fri',
  'saturday': 'Sat',
  'sunday': 'Sun',
};

/// The ordered days of the week used to build columns.
const _orderedDays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// The three meal types, in display order.
const _mealTypes = ['breakfast', 'lunch', 'dinner'];

/// Label text shown in the fixed left label column.
const _mealLabels = ['B', 'L', 'D'];

/// The 7-day x 3-meal planner grid.
///
/// Renders a fixed left column of meal-type labels (B/L/D) next to a
/// horizontally scrollable set of 7 day columns. Each cell shows either a
/// [MealSlotCard] (recipe assigned) or [EmptySlotCard] (empty).
///
/// Supports drag-and-drop rescheduling:
/// - Long-pressing a filled slot initiates a drag via [LongPressDraggable].
/// - All slot cells are wrapped in [DragTarget] — dropping swaps or moves meals.
/// - Horizontal scroll is disabled during an active drag to prevent gesture
///   conflicts; auto-scroll near edges fires while a drag is in progress.
class PlannerGrid extends ConsumerStatefulWidget {
  const PlannerGrid({super.key, required this.weekStart});

  final DateTime weekStart;

  @override
  ConsumerState<PlannerGrid> createState() => _PlannerGridState();
}

class _PlannerGridState extends ConsumerState<PlannerGrid> {
  final _scrollController = ScrollController();

  /// True while any LongPressDraggable is active.
  bool _isDragging = false;

  /// Auto-scroll timer — fires repeatedly when pointer is near a scroll edge.
  Timer? _autoScrollTimer;

  /// Current pointer x position in the scroll area's local frame, used to
  /// determine edge-proximity for auto-scroll.
  double _pointerX = 0;

  /// Width of the scrollable area (set during layout via LayoutBuilder).
  double _scrollAreaWidth = 0;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Drag lifecycle
  // ---------------------------------------------------------------------------

  void _onDragStarted() {
    setState(() => _isDragging = true);
    _startAutoScrollTimer();
  }

  void _onDragEnd() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    setState(() => _isDragging = false);
  }

  void _startAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!_isDragging || !_scrollController.hasClients) return;
      const edgeThreshold = 48.0;
      const scrollStep = 60.0;
      final current = _scrollController.offset;
      final max = _scrollController.position.maxScrollExtent;

      if (_pointerX < edgeThreshold && current > 0) {
        _scrollController.animateTo(
          (current - scrollStep).clamp(0.0, max),
          duration: const Duration(milliseconds: 80),
          curve: Curves.linear,
        );
      } else if (_pointerX > _scrollAreaWidth - edgeThreshold &&
          current < max) {
        _scrollController.animateTo(
          (current + scrollStep).clamp(0.0, max),
          duration: const Duration(milliseconds: 80),
          curve: Curves.linear,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Drop handling
  // ---------------------------------------------------------------------------

  Future<void> _onDrop(
    MealSlot dragged,
    MealSlot? targetSlot,
    String targetDay,
    String targetMealType,
  ) async {
    final notifier =
        ref.read(mealPlanNotifierProvider(widget.weekStart).notifier);

    // Same cell — ignore.
    if (dragged.dayOfWeek == targetDay && dragged.mealType == targetMealType) {
      return;
    }

    if (targetSlot != null && targetSlot.recipeId != null) {
      // Target is filled — swap the two slots.
      await notifier.swapSlots(dragged.id, targetSlot.id);
    } else if (targetSlot != null) {
      // Target slot row exists but is empty — swap (effectively moves).
      await notifier.swapSlots(dragged.id, targetSlot.id);
    } else {
      // No row for target yet — assign recipe to target, clear source.
      await notifier.assignRecipe(
        dayOfWeek: targetDay,
        mealType: targetMealType,
        recipeId: int.parse(dragged.recipeId!),
      );
      await notifier.clearSlot(dragged.id);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(mealPlanNotifierProvider(widget.weekStart));

    return slotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading meal plan: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (slots) => _buildGrid(context, slots),
    );
  }

  Widget _buildGrid(BuildContext context, List<MealSlot> slots) {
    const labelColumnWidth = 32.0;
    const cellHeight = 110.0;
    const headerHeight = 48.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Fixed left label column (meal type initials) ---
        SizedBox(
          width: labelColumnWidth,
          child: Column(
            children: [
              // Header row spacer (matches the day header height)
              const SizedBox(height: headerHeight),
              // Meal label cells
              ..._mealLabels.map(
                (label) => SizedBox(
                  height: cellHeight,
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Horizontally scrollable day columns ---
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _scrollAreaWidth = constraints.maxWidth;
              // Fixed column width — works on both mobile and desktop.
              // On mobile (~370px available) shows ~2.8 columns; on desktop
              // shows more columns with the same card size.
              const columnWidth = 130.0;
              return Listener(
                // Track pointer position for edge-scroll detection.
                onPointerMove: _isDragging
                    ? (event) {
                        _pointerX = event.localPosition.dx;
                      }
                    : null,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  // Disable scroll while a drag is active to prevent gesture
                  // conflict between horizontal scroll and drag recogniser.
                  physics: _isDragging
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _orderedDays.map((day) {
                      final dayDate = _dayDate(day);
                      return SizedBox(
                        width: columnWidth,
                        child: Column(
                          children: [
                            // Day header
                            SizedBox(
                              height: headerHeight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _dayAbbreviations[day] ?? day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${dayDate.day}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Slot cells for this day
                            ..._mealTypes.map((mealType) {
                              final slot = _findSlot(slots, day, mealType);
                              return SizedBox(
                                height: cellHeight,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: _SlotCell(
                                    slot: slot,
                                    dayOfWeek: day,
                                    mealType: mealType,
                                    weekStart: widget.weekStart,
                                    onDrop: _onDrop,
                                    onDragStarted: _onDragStarted,
                                    onDragEnd: _onDragEnd,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Finds the [MealSlot] for the given day and meal type, or null if absent.
  MealSlot? _findSlot(
    List<MealSlot> slots,
    String dayOfWeek,
    String mealType,
  ) {
    try {
      return slots.firstWhere(
        (s) => s.dayOfWeek == dayOfWeek && s.mealType == mealType,
      );
    } catch (_) {
      return null;
    }
  }

  /// Computes the calendar date for the given day of the week offset from [weekStart].
  DateTime _dayDate(String day) {
    final offset = _orderedDays.indexOf(day);
    return widget.weekStart.add(Duration(days: offset));
  }
}

// =============================================================================
// _SlotCell — DragTarget wrapper for a single grid cell
// =============================================================================

/// A single cell in the planner grid, wrapping either [MealSlotCard] or
/// [EmptySlotCard] in a [DragTarget] that accepts [MealSlot] drags.
class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.slot,
    required this.dayOfWeek,
    required this.mealType,
    required this.weekStart,
    required this.onDrop,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  final MealSlot? slot;
  final String dayOfWeek;
  final String mealType;
  final DateTime weekStart;
  final Future<void> Function(
    MealSlot dragged,
    MealSlot? targetSlot,
    String targetDay,
    String targetMealType,
  ) onDrop;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return DragTarget<MealSlot>(
      onWillAcceptWithDetails: (details) {
        final dragged = details.data;
        // Reject drops onto the same cell.
        return !(dragged.dayOfWeek == dayOfWeek &&
            dragged.mealType == mealType);
      },
      onAcceptWithDetails: (details) {
        onDrop(details.data, slot, dayOfWeek, mealType);
      },
      builder: (context, candidateItems, rejectedItems) {
        final isHovered = candidateItems.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isHovered
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor, width: 2),
                  color: primaryColor.withValues(alpha: 0.06),
                )
              : null,
          child: slot != null && slot!.recipeId != null
              ? MealSlotCard(
                  slot: slot!,
                  weekStart: weekStart,
                  onDragStarted: onDragStarted,
                  onDragEnd: onDragEnd,
                )
              : EmptySlotCard(
                  dayOfWeek: dayOfWeek,
                  mealType: mealType,
                  weekStart: weekStart,
                  isHovered: isHovered,
                ),
        );
      },
    );
  }
}
