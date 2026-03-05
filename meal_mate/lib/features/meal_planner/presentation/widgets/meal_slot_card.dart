import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';

/// A compact card displaying an assigned recipe in a meal plan slot.
///
/// Shows the recipe thumbnail and title, with inline replace and remove
/// icon buttons positioned at the top-right. Tapping the card body navigates
/// to the recipe detail screen.
///
/// Wrapped in [LongPressDraggable] so users can long-press and drag the card
/// to another slot in [PlannerGrid] to swap or move meals.
class MealSlotCard extends ConsumerWidget {
  const MealSlotCard({
    super.key,
    required this.slot,
    required this.weekStart,
    this.onDragStarted,
    this.onDragEnd,
  });

  final MealSlot slot;
  final DateTime weekStart;

  /// Called when a drag begins — used by PlannerGrid to disable scroll.
  final VoidCallback? onDragStarted;

  /// Called when a drag ends (dropped or cancelled) — re-enables scroll.
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = _buildCard(context, ref);

    return LongPressDraggable<MealSlot>(
      data: slot,
      delay: const Duration(milliseconds: 200),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        onDragStarted?.call();
      },
      onDragEnd: (_) => onDragEnd?.call(),
      onDraggableCanceled: (_, __) => onDragEnd?.call(),
      // Feedback widget: elevated copy of the card at ~80% opacity.
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 110,
            height: 90,
            child: _CompactFeedbackCard(slot: slot),
          ),
        ),
      ),
      // Ghost placeholder while dragging: reduced opacity dashed container.
      childWhenDragging: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Icon(Icons.drag_indicator, color: Colors.grey, size: 24),
        ),
      ),
      child: card,
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref) {
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
        await ref.read(mealPlanProvider(weekStart).notifier).assignRecipe(
              dayOfWeek: slot.dayOfWeek,
              mealType: slot.mealType,
              recipeId: recipeId,
              recipeTitle: result['recipeTitle'] as String?,
              recipeImage: result['recipeImage'] as String?,
            );
      }
    }
  }

  Future<void> _onRemove(WidgetRef ref) async {
    await ref
        .read(mealPlanProvider(weekStart).notifier)
        .clearSlot(slot.id);
  }
}

/// Compact card used as LongPressDraggable feedback widget.
///
/// Shows thumbnail and title without interactive elements.
class _CompactFeedbackCard extends StatelessWidget {
  const _CompactFeedbackCard({required this.slot});

  final MealSlot slot;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // Thumbnail
          Positioned.fill(
            child: _buildThumbnail(),
          ),
          // Title bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: Colors.black54,
              child: Text(
                slot.recipeTitle ?? 'Recipe',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final imageUrl = slot.recipeImage;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.restaurant, color: Colors.grey, size: 24),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.restaurant, color: Colors.grey, size: 24),
        ),
      ),
    );
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
