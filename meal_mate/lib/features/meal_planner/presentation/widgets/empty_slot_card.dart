import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';

/// An empty meal plan slot — shows a dashed-style border with a + icon.
///
/// Tapping opens the recipe picker in "select for slot" mode. When the user
/// picks a recipe and pops back with recipe data, [MealPlanNotifier.assignRecipe]
/// is called to persist the assignment.
///
/// When [isHovered] is true (a drag is hovering over this slot), the border
/// changes to the primary colour with a "Drop here" hint.
class EmptySlotCard extends ConsumerWidget {
  const EmptySlotCard({
    super.key,
    required this.dayOfWeek,
    required this.mealType,
    required this.weekStart,
    this.isHovered = false,
  });

  final String dayOfWeek;
  final String mealType;
  final DateTime weekStart;

  /// True when a DragTarget reports a candidate is hovering over this slot.
  final bool isHovered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: isHovered ? primaryColor : Colors.grey.shade300,
          width: isHovered ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isHovered
            ? primaryColor.withValues(alpha: 0.08)
            : Colors.grey.shade50,
      ),
      child: GestureDetector(
        onTap: () => _onTap(context, ref),
        child: Center(
          child: isHovered
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward, color: primaryColor, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      'Drop here',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : const Icon(Icons.add, color: Colors.grey),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final uri =
        '/recipes?selectForSlot=true&day=$dayOfWeek&meal=$mealType&week=${weekStart.millisecondsSinceEpoch}';
    final result = await context.push<Map<String, dynamic>>(uri);
    if (result != null) {
      final recipeId = result['recipeId'] as int?;
      if (recipeId != null) {
        await ref
            .read(mealPlanNotifierProvider(weekStart).notifier)
            .assignRecipe(
              dayOfWeek: dayOfWeek,
              mealType: mealType,
              recipeId: recipeId,
            );
      }
    }
  }
}
