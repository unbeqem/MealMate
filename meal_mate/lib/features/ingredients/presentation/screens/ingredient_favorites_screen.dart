import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/ingredient_favorites_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/selected_today_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/widgets/ingredient_tile.dart';
import 'package:shimmer/shimmer.dart';

/// Displays all favorited ingredients as a tab child inside [IngredientMainScreen].
///
/// No standalone [Scaffold] — callers must provide one. Embedded as Tab 1
/// in the 2-tab shell at /ingredients.
///
/// Features:
/// - "Add all to today" bulk action button at top (per locked decision)
/// - Unfavorite action via heart icon (removes from this list optimistically)
/// - "I have this today" toggle via select icon
/// - Shimmer loading skeleton (no CircularProgressIndicator)
/// - Empty state with icon + instructions
class IngredientFavoritesScreen extends ConsumerWidget {
  const IngredientFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(ingredientFavoritesProvider);
    final selectedAsync = ref.watch(selectedTodayProvider);
    final selectedMap = selectedAsync.value ?? {};

    return Column(
      children: [
        Expanded(
          child: favoritesAsync.when(
            loading: () => _buildShimmerList(),
            error: (e, _) => Center(
              child: Text('Failed to load favorites: $e'),
            ),
            data: (favorites) {
              // Filter to only show currently-favorited items
              final active = favorites.where((i) => i.isFavorite).toList();

              if (active.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on any ingredient to save it here',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // "Add all to today" bulk action — per locked decision
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add all to today'),
                        onPressed: () => ref
                            .read(selectedTodayProvider.notifier)
                            .addAll(active),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: active.length,
                      itemBuilder: (_, i) {
                        final ingredient = active[i];
                        final isSelected =
                            selectedMap.containsKey(ingredient.id);
                        return IngredientTile(
                          name: ingredient.name,
                          category: ingredient.category,
                          dietaryFlags: ingredient.dietaryFlags,
                          isFavorite: true,
                          isSelected: isSelected,
                          onFavoriteTap: () => ref
                              .read(ingredientFavoritesProvider.notifier)
                              .toggleFavorite(ingredient.id),
                          onSelectTap: () => ref
                              .read(selectedTodayProvider.notifier)
                              .toggle(ingredient.id, name: ingredient.name),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Shimmer loading skeleton — 3 tiles, no CircularProgressIndicator.
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Container(
            height: 14,
            color: Colors.white,
            margin: const EdgeInsets.only(right: 80),
          ),
          subtitle: Container(
            height: 10,
            color: Colors.white,
            margin: const EdgeInsets.only(right: 140, top: 4),
          ),
        ),
      ),
    );
  }
}
