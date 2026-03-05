import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/ingredient_reuse_provider.dart';

/// An expandable panel on the planner screen showing all unique ingredient
/// names from recipes planned for the current week.
///
/// - Watches [weekIngredientNamesProvider] reactively — updates as slots change.
/// - Hidden (SizedBox.shrink) when no slots are filled.
/// - Expanded: sorted alphabetical chips, one per ingredient.
/// - Serves as a bridge/preview for Phase 6 shopping list.
class WeekIngredientSummary extends ConsumerWidget {
  const WeekIngredientSummary({super.key, required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final namesAsync = ref.watch(weekIngredientNamesProvider(weekStart));

    return namesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (names) {
        if (names.isEmpty) return const SizedBox.shrink();

        final sortedNames = names.toList()..sort();

        return ExpansionTile(
          leading: const Icon(Icons.shopping_basket_outlined),
          title: Text('Week ingredients (${names.length})'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sortedNames
                  .map(
                    (name) => Chip(
                      label: Text(
                        _capitalize(name),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
}
