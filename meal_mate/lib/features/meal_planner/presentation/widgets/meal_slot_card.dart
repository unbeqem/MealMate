import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';

/// A compact card displaying an assigned recipe in a meal plan slot.
///
/// Shows the recipe thumbnail and title, with inline replace and remove
/// icon buttons positioned at the top-right. Tapping the card body navigates
/// to the recipe detail screen.
class MealSlotCard extends ConsumerWidget {
  const MealSlotCard({
    super.key,
    required this.slot,
    required this.weekStart,
  });

  final MealSlot slot;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => context.push('/recipes/${slot.recipeId}'),
        child: Stack(
          children: [
            // --- Recipe thumbnail filling the card ---
            Positioned.fill(
              child: _buildThumbnail(slot.recipeImage),
            ),

            // --- Semi-transparent title bar at bottom ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.black54,
                child: Text(
                  slot.recipeTitle ?? 'Recipe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // --- Action icons at top-right ---
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replace icon
                  _ActionIcon(
                    icon: Icons.swap_horiz,
                    tooltip: 'Replace recipe',
                    onTap: () => _onReplace(context, ref),
                  ),
                  // Remove icon
                  _ActionIcon(
                    icon: Icons.close,
                    tooltip: 'Remove recipe',
                    onTap: () => _onRemove(ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.restaurant, color: Colors.grey, size: 28),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.restaurant, color: Colors.grey, size: 28),
        ),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onReplace(BuildContext context, WidgetRef ref) async {
    final uri =
        '/recipes?selectForSlot=true&day=${slot.dayOfWeek}&meal=${slot.mealType}&week=${weekStart.millisecondsSinceEpoch}';
    final result =
        await context.push<Map<String, dynamic>>(uri);
    if (result != null) {
      final recipeId = result['recipeId'] as int?;
      if (recipeId != null) {
        await ref.read(mealPlanNotifierProvider(weekStart).notifier).assignRecipe(
              dayOfWeek: slot.dayOfWeek,
              mealType: slot.mealType,
              recipeId: recipeId,
            );
      }
    }
  }

  Future<void> _onRemove(WidgetRef ref) async {
    await ref
        .read(mealPlanNotifierProvider(weekStart).notifier)
        .clearSlot(slot.id);
  }
}

/// A small semi-transparent icon button used for slot actions.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: Colors.black45,
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
