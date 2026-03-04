import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/ingredients/domain/ingredient_filter.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/ingredient_category_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/ingredient_favorites_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/ingredient_filter_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/selected_today_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/widgets/dietary_filter_chips.dart';
import 'package:meal_mate/features/ingredients/presentation/widgets/ingredient_tile.dart';
import 'package:meal_mate/features/ingredients/presentation/widgets/selected_today_bar.dart';
import 'package:shimmer/shimmer.dart';

/// Displays ingredients for a specific category.
///
/// Uses the pull-through cache pattern: shows Drift-cached data immediately
/// then updates when fresh data arrives from OpenFoodFacts.
/// Dietary filter chips allow client-side filtering of displayed results.
///
/// [SelectedTodayBar] is embedded at the bottom of the body Column so users
/// can see their current selection and navigate to recipe discovery from here.
///
/// Route: /ingredients/category/:name
class IngredientCategoryScreen extends ConsumerWidget {
  final String categoryName;

  const IngredientCategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pass display name directly — repository owns the display-name-to-OFf-tag lookup
    final ingredientsAsync =
        ref.watch(ingredientsByCategoryProvider(categoryName));
    final activeFilters = ref.watch(ingredientFilterProvider);
    final selectedAsync = ref.watch(selectedTodayProvider);
    final selectedMap = selectedAsync.value ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: Column(
        children: [
          const DietaryFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ingredientsByCategoryProvider(categoryName));
                await ref
                    .read(ingredientsByCategoryProvider(categoryName).future);
              },
              child: ingredientsAsync.when(
                loading: () => _buildShimmerList(),
                error: (e, _) => ListView(
                  // ListView required so RefreshIndicator detects the pull gesture
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 80),
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 8),
                          Text('Failed to load ingredients: $e'),
                          TextButton(
                            onPressed: () => ref
                                .invalidate(ingredientsByCategoryProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (ingredients) {
                  // Client-side filter by active dietary restrictions
                  final filtered = activeFilters.isEmpty
                      ? ingredients
                      : ingredients.where((i) {
                          return activeFilters.every((restriction) {
                            final flag = _restrictionToFlag(restriction);
                            return i.dietaryFlags.contains(flag);
                          });
                        }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      // ListView required so RefreshIndicator detects the pull gesture
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Text('No ingredients found for this category'),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final ingredient = filtered[i];
                      final isSelected = selectedMap.containsKey(ingredient.id);
                      return IngredientTile(
                        name: ingredient.name,
                        category: ingredient.category,
                        dietaryFlags: ingredient.dietaryFlags,
                        isFavorite: ingredient.isFavorite,
                        isSelected: isSelected,
                        onFavoriteTap: () => ref
                            .read(ingredientFavoritesProvider.notifier)
                            .toggleFavorite(ingredient.id, name: ingredient.name),
                        onSelectTap: () => ref
                            .read(selectedTodayProvider.notifier)
                            .toggle(ingredient.id, name: ingredient.name),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // SelectedTodayBar at the bottom — shows selection across navigation
          const SelectedTodayBar(),
        ],
      ),
    );
  }

  /// Shimmer loading skeleton — 4 tiles, no CircularProgressIndicator.
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 4,
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

  String _restrictionToFlag(DietaryRestriction restriction) {
    switch (restriction) {
      case DietaryRestriction.vegetarian:
        return 'vegetarian';
      case DietaryRestriction.vegan:
        return 'vegan';
      case DietaryRestriction.glutenFree:
        return 'gluten-free';
      case DietaryRestriction.dairyFree:
        return 'dairy-free';
    }
  }
}
