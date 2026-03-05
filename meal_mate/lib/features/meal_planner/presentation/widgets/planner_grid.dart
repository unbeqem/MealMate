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
class PlannerGrid extends ConsumerWidget {
  const PlannerGrid({super.key, required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(mealPlanNotifierProvider(weekStart));

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
    // Calculate day column width — ~2.8 days visible in portrait.
    final columnWidth = MediaQuery.of(context).size.width * 0.35;
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                            child: slot != null && slot.recipeId != null
                                ? MealSlotCard(
                                    slot: slot,
                                    weekStart: weekStart,
                                  )
                                : EmptySlotCard(
                                    dayOfWeek: day,
                                    mealType: mealType,
                                    weekStart: weekStart,
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
    return weekStart.add(Duration(days: offset));
  }
}
