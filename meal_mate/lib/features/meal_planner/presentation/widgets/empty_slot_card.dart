import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';

/// An empty meal plan slot — shows a dashed-style border with a + icon.
///
/// Tapping opens the recipe picker in "select for slot" mode. When the user
/// picks a recipe and pops back with recipe data, [MealPlanNotifier.assignRecipe]
/// is called to persist the assignment.
class EmptySlotCard extends ConsumerWidget {
  const EmptySlotCard({
    super.key,
    required this.dayOfWeek,
    required this.mealType,
    required this.weekStart,
  });

  final String dayOfWeek;
  final String mealType;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _onTap(context, ref),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.grey),
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
