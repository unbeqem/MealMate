import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/recipes/presentation/providers/recipe_detail_provider.dart';

/// Row widget that shows a serving count with increment/decrement controls.
///
/// Reads [servingSizeProvider] keyed by [originalServings].
/// Calls the notifier on button taps — the state is ephemeral UI only.
class ServingScalerWidget extends ConsumerWidget {
  /// The recipe's original serving count (provider key).
  final int originalServings;

  const ServingScalerWidget({super.key, required this.originalServings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentServings =
        ref.watch(servingSizeProvider(originalServings));
    final notifier =
        ref.read(servingSizeProvider(originalServings).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Servings',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: notifier.decrement,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
            Text(
              '$currentServings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: notifier.increment,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ],
    );
  }
}
