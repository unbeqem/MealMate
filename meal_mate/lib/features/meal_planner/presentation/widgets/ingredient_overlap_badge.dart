import 'package:flutter/material.dart';

/// A compact badge displayed on recipe cards in the slot picker.
///
/// Shows the number of ingredients the candidate recipe shares with recipes
/// already planned for the current week. Helps users minimise food waste by
/// choosing recipes that reuse ingredients.
///
/// Returns a [SizedBox.shrink] when [overlapCount] is zero, so callers never
/// need to guard against rendering an empty widget.
class IngredientOverlapBadge extends StatelessWidget {
  const IngredientOverlapBadge({super.key, required this.overlapCount});

  /// The number of shared ingredients between the candidate recipe and the
  /// current week's plan. If 0, the widget renders nothing.
  final int overlapCount;

  @override
  Widget build(BuildContext context) {
    if (overlapCount == 0) return const SizedBox.shrink();

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 14, color: primaryColor),
          const SizedBox(width: 3),
          Text(
            '$overlapCount shared',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
