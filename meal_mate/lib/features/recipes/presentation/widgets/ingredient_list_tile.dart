import 'package:flutter/material.dart';
import 'package:meal_mate/features/recipes/domain/extended_ingredient.dart';
import 'package:meal_mate/features/recipes/utils/format_amount.dart';

/// Displays a single ingredient row with a proportionally scaled amount.
///
/// Scaling formula: `(ingredient.amount / originalServings) * selectedServings`
///
/// Falls back to [ExtendedIngredient.original] string if the structured data
/// is missing (amount == 0 or unit is empty) — some Spoonacular responses
/// omit structured data for certain ingredients.
class IngredientListTile extends StatelessWidget {
  final ExtendedIngredient ingredient;
  final int originalServings;
  final int selectedServings;

  const IngredientListTile({
    super.key,
    required this.ingredient,
    required this.originalServings,
    required this.selectedServings,
  });

  @override
  Widget build(BuildContext context) {
    final useOriginalString =
        ingredient.amount == 0 || ingredient.unit.isEmpty;

    final String displayText;
    if (useOriginalString && ingredient.original != null) {
      displayText = ingredient.original!;
    } else {
      final scaledAmount = originalServings > 0
          ? (ingredient.amount / originalServings) * selectedServings
          : ingredient.amount;
      displayText =
          '${formatAmount(scaledAmount)} ${ingredient.unit} ${ingredient.name}'
              .trim();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fiber_manual_record, size: 8, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
