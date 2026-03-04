import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/ingredients/data/openfoodfacts_remote_source.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/ingredient_favorites_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/ingredient_search_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/selected_today_provider.dart';
import 'package:meal_mate/features/ingredients/presentation/widgets/dietary_filter_chips.dart';
import 'package:meal_mate/features/ingredients/presentation/widgets/ingredient_tile.dart';
import 'package:shimmer/shimmer.dart';

/// Ingredient discovery screen: autocomplete search and category browsing.
///
/// Designed as a tab child inside [IngredientMainScreen] — no standalone
/// [Scaffold] wrapper; callers must provide one.
///
/// Users can:
/// - Quick-add favorites via chips at the top (one tap to add to today's selection)
/// - Search for ingredients by name (300ms debounced, min 2 chars)
/// - Browse by category — 12 colored cards (navigates to [IngredientCategoryScreen])
/// - Favorite ingredients (via heart icon)
/// - Select "I have this today" (via check icon)
class IngredientSearchScreen extends ConsumerStatefulWidget {
  const IngredientSearchScreen({super.key});

  @override
  ConsumerState<IngredientSearchScreen> createState() =>
      _IngredientSearchScreenState();
}

class _IngredientSearchScreenState
    extends ConsumerState<IngredientSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(ingredientSearchProvider);
    final selectedAsync = ref.watch(selectedTodayProvider);
    final selectedMap = selectedAsync.value ?? {};

    // Quick-add favorites state
    final favoritesAsync = ref.watch(ingredientFavoritesProvider);
    final unselectedFavorites = favoritesAsync.value
            ?.where((fav) => !selectedMap.containsKey(fav.id))
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick-add favorites chips — per locked decision
        if (unselectedFavorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              'Quick add from favorites',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: unselectedFavorites.map((fav) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(fav.name),
                      onPressed: () => ref
                          .read(selectedTodayProvider.notifier)
                          .toggle(fav.id, name: fav.name),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],

        // Dietary filter chips
        const DietaryFilterChips(),

        // Search text field
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Search ingredients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) =>
                ref.read(ingredientSearchProvider.notifier).search(text),
          ),
        ),

        // Search results or category grid
        Expanded(
          child: searchResults.when(
            loading: () => _buildShimmerList(),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Text('Error: $e'),
                  TextButton(
                    onPressed: () => ref
                        .read(ingredientSearchProvider.notifier)
                        .search(_controller.text),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return _buildEmptyOrBrowseState(context);
              }
              return ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (_, i) {
                  final name = suggestions[i];
                  // Search results are name strings, not Ingredient domain objects
                  // Use name as both id and display name for selection
                  final isSelected = selectedMap.containsKey(name);
                  return IngredientTile(
                    name: name,
                    isSelected: isSelected,
                    onFavoriteTap: () => ref
                        .read(ingredientFavoritesProvider.notifier)
                        .toggleFavorite(name),
                    onSelectTap: () => ref
                        .read(selectedTodayProvider.notifier)
                        .toggle(name, name: name),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Shows category grid when there are no search results.
  Widget _buildEmptyOrBrowseState(BuildContext context) {
    final query = _controller.text;
    if (query.length >= 2) {
      return const Center(child: Text('No results found'));
    }
    if (query.isEmpty) {
      return _buildCategoryGrid(context);
    }
    return const Center(
      child: Text('Type at least 2 characters to search'),
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

  /// Browse by Category grid — 12 colored cards.
  Widget _buildCategoryGrid(BuildContext context) {
    const categoryMeta = {
      'Produce': (color: Color(0xFF81C784), icon: Icons.eco),
      'Dairy': (color: Color(0xFF64B5F6), icon: Icons.water_drop),
      'Meat': (color: Color(0xFFE57373), icon: Icons.set_meal),
      'Seafood': (color: Color(0xFF4DD0E1), icon: Icons.water),
      'Grains': (color: Color(0xFFFFD54F), icon: Icons.grass),
      'Legumes': (color: Color(0xFFA5D6A7), icon: Icons.spa),
      'Spices': (color: Color(0xFFFF8A65), icon: Icons.local_fire_department),
      'Condiments': (color: Color(0xFFCE93D8), icon: Icons.kitchen),
      'Oils': (color: Color(0xFFFFF176), icon: Icons.opacity),
      'Beverages': (color: Color(0xFF80DEEA), icon: Icons.local_cafe),
      'Baking': (color: Color(0xFFBCAAA4), icon: Icons.cake),
      'Nuts & Seeds': (color: Color(0xFFFFCC80), icon: Icons.grain),
    };

    final categories = ingredientCategories.keys.toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              'Browse by Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final name = categories[i];
                final meta = categoryMeta[name];
                final color = meta?.color ?? Colors.grey[300]!;
                final icon = meta?.icon ?? Icons.category;

                return Card(
                  color: color,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () =>
                        context.push('/ingredients/category/$name'),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 28, color: Colors.black87),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
          ),
        ),
      ],
    );
  }
}
