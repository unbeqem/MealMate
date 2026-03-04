import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/selected_today_provider.dart';

/// Expandable bottom pill bar showing selected-today ingredients.
///
/// Hidden when no ingredients are selected. When visible:
/// - Collapsed: shows count + first 2-3 ingredient name chips + "Find Recipes" CTA
/// - Expanded: full chip list with delete icons, "Clear all" + "Find Recipes" CTA
///
/// Uses [AnimatedContainer] for smooth expand/collapse transition.
/// Placed in [IngredientMainScreen] body Column (shared across both tabs) and
/// in [IngredientCategoryScreen] (standalone Scaffold).
///
/// Phase 4 reads the selection directly from [selectedTodayProvider].
class SelectedTodayBar extends ConsumerStatefulWidget {
  const SelectedTodayBar({super.key});

  @override
  ConsumerState<SelectedTodayBar> createState() => _SelectedTodayBarState();
}

class _SelectedTodayBarState extends ConsumerState<SelectedTodayBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final selectedAsync = ref.watch(selectedTodayProvider);
    final selectedMap = selectedAsync.value ?? <String, String>{};

    if (selectedMap.isEmpty) return const SizedBox.shrink();

    final names = selectedMap.values.toList();
    final count = selectedMap.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: tap to expand/collapse — shows count + first 2-3 name chips
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '$count ingredient${count == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 8),
                    // Show first 2-3 name chips in collapsed state
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...names.take(3).map(
                                  (name) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Chip(
                                      label: Text(
                                        name,
                                        style:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                    ),
                                  ),
                                ),
                            if (count > 3)
                              Text(
                                '+${count - 3} more',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_more : Icons.expand_less,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded section: full chip list + Clear all + Find Recipes
            if (_expanded) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: selectedMap.entries
                      .map(
                        (entry) => Chip(
                          label: Text(entry.value),
                          onDeleted: () {
                            ref
                                .read(selectedTodayProvider.notifier)
                                .toggle(entry.key, name: entry.value);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ref
                            .read(selectedTodayProvider.notifier)
                            .clearAll();
                        setState(() => _expanded = false);
                      },
                      child: const Text('Clear all'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/recipes'),
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Find Recipes'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Collapsed: just the "Find Recipes" CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/recipes'),
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Find Recipes'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
