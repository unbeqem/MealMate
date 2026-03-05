import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/selected_today_provider.dart';
import 'package:meal_mate/features/recipes/data/spoonacular_client.dart';
import 'package:meal_mate/features/recipes/domain/recipe_search_result.dart';
import 'package:meal_mate/features/recipes/presentation/providers/recipe_search_provider.dart';
import 'package:meal_mate/features/recipes/presentation/recipe_card.dart';
import 'package:meal_mate/features/recipes/presentation/widgets/filter_chips_row.dart';

/// The primary recipe discovery screen.
///
/// - Search mode (default): paginated recipe list from Spoonacular.
/// - Ingredient mode: list of recipes matching the user's selected ingredients.
class RecipeBrowseScreen extends ConsumerStatefulWidget {
  const RecipeBrowseScreen({super.key});

  @override
  ConsumerState<RecipeBrowseScreen> createState() =>
      _RecipeBrowseScreenState();
}

class _RecipeBrowseScreenState extends ConsumerState<RecipeBrowseScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(recipeFilterStateProvider.notifier)
          .setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(recipeFilterStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search recipes...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          onSubmitted: (value) {
            _debounce?.cancel();
            ref
                .read(recipeFilterStateProvider.notifier)
                .setQuery(value);
          },
        ),
      ),
      body: Column(
        children: [
          // --- Filter chips ---
          const FilterChipsRow(),
          const Divider(height: 1),

          // --- Results ---
          Expanded(
            child: filterState.isIngredientMode
                ? const _IngredientModeBody()
                : _SearchModeBody(filterState: filterState),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search mode body
// ---------------------------------------------------------------------------

class _SearchModeBody extends ConsumerStatefulWidget {
  const _SearchModeBody({required this.filterState});

  final RecipeFilterState filterState;

  @override
  ConsumerState<_SearchModeBody> createState() => _SearchModeBodyState();
}

class _SearchModeBodyState extends ConsumerState<_SearchModeBody> {
  // Tracks how many pages the user has loaded.
  int _loadedPages = 1;

  // Total results from the first page (updated when page 0 loads).
  int? _totalResults;

  @override
  void didUpdateWidget(covariant _SearchModeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination when filters change.
    if (oldWidget.filterState.query != widget.filterState.query ||
        oldWidget.filterState.cuisine != widget.filterState.cuisine ||
        oldWidget.filterState.maxReadyTime !=
            widget.filterState.maxReadyTime) {
      setState(() {
        _loadedPages = 1;
        _totalResults = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filterState;

    // Watch page 0 to get totalResults for pagination decisions.
    final firstPageAsync = ref.watch(
      recipeSearchPageProvider(
        query: filter.query,
        cuisine: filter.cuisine,
        maxReadyTime: filter.maxReadyTime,
        page: 0,
      ),
    );

    return firstPageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(error),
      data: (firstPage) {
        // Keep totalResults in sync.
        if (_totalResults != firstPage.totalResults) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _totalResults = firstPage.totalResults);
            }
          });
        }

        if (firstPage.totalResults == 0) {
          return const _EmptySearchState();
        }

        final totalResults = firstPage.totalResults;
        const pageSize = 20;
        final totalItems = totalResults < _loadedPages * pageSize
            ? totalResults
            : _loadedPages * pageSize + 1;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            final page = index ~/ pageSize;
            final indexInPage = index % pageSize;

            // Load more trigger: last visible item loads next page.
            if (index == _loadedPages * pageSize - 1 &&
                _loadedPages * pageSize < totalResults) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _loadedPages++);
              });
            }

            // Loading indicator at end of list.
            if (page >= _loadedPages) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final pageAsync = page == 0
                ? firstPageAsync
                : ref.watch(
                    recipeSearchPageProvider(
                      query: filter.query,
                      cuisine: filter.cuisine,
                      maxReadyTime: filter.maxReadyTime,
                      page: page,
                    ),
                  );

            return pageAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => const SizedBox.shrink(),
              data: (pageResult) {
                final results = pageResult.results;
                if (indexInPage >= results.length) {
                  return const SizedBox.shrink();
                }
                return RecipeCard(recipe: results[indexInPage]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildError(Object error) {
    if (error is QuotaExhaustedException) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Daily recipe limit reached',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You have reached the daily recipe quota. Please try again tomorrow.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Something went wrong loading recipes.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(recipeSearchPageProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ingredient mode body
// ---------------------------------------------------------------------------

class _IngredientModeBody extends ConsumerWidget {
  const _IngredientModeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsync = ref.watch(selectedTodayProvider);

    return selectedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading ingredients')),
      data: (selectedMap) {
        if (selectedMap.isEmpty) {
          return const _EmptyIngredientsState();
        }

        final ingredientNames = selectedMap.values.toList();
        final recipesAsync =
            ref.watch(ingredientBasedRecipesProvider(ingredientNames));

        return recipesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            if (error is QuotaExhaustedException) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 48, color: Colors.orange),
                      SizedBox(height: 16),
                      Text(
                        'Daily recipe limit reached',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You have reached the daily recipe quota. Please try again tomorrow.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(
              child: Text('Error loading ingredient-based recipes.'),
            );
          },
          data: (recipes) {
            if (recipes.isEmpty) {
              return const _EmptySearchState();
            }
            final summaries = recipes
                .map((r) => RecipeSummary(
                      id: r.id,
                      title: r.title,
                      image: r.image,
                    ))
                .toList();
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: summaries.length,
              itemBuilder: (_, i) => RecipeCard(recipe: summaries[i]),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No recipes found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Try a different search term or adjust your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _EmptyIngredientsState extends StatelessWidget {
  const _EmptyIngredientsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kitchen_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No ingredients selected',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Select ingredients from the Ingredients screen first,\nthen come back to find matching recipes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
