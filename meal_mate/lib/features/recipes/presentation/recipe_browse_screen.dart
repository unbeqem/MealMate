import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/selected_today_provider.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/ingredient_reuse_provider.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';
import 'package:meal_mate/features/meal_planner/presentation/widgets/ingredient_overlap_badge.dart';
import 'package:meal_mate/features/recipes/domain/recipe_search_result.dart';
import 'package:meal_mate/features/recipes/presentation/providers/recipe_search_provider.dart';
import 'package:meal_mate/features/recipes/presentation/recipe_card.dart';
import 'package:meal_mate/features/recipes/presentation/widgets/filter_chips_row.dart';

/// The primary recipe discovery screen.
///
/// - Search mode (default): paginated recipe list from Spoonacular.
/// - Ingredient mode: list of recipes matching the user's selected ingredients.
/// - Select-for-slot mode: triggered via `?selectForSlot=true` query param.
///   In this mode the AppBar title changes to "Pick a Recipe" and tapping a
///   recipe card pops back with `{'recipeId': int, 'recipeTitle': String?,
///   'recipeImage': String?}` instead of navigating to the detail screen.
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

    // Detect select-for-slot mode from GoRouter query parameters.
    final queryParams = GoRouterState.of(context).uri.queryParameters;
    final isSelectMode = queryParams['selectForSlot'] == 'true';

    // Parse weekStart from millisecondsSinceEpoch query param (only in select mode).
    DateTime? weekStart;
    if (isSelectMode) {
      final weekMs = int.tryParse(queryParams['week'] ?? '');
      if (weekMs != null) {
        weekStart = DateTime.fromMillisecondsSinceEpoch(weekMs, isUtc: true);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: isSelectMode
            ? const Text('Pick a Recipe')
            : TextField(
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
          // --- Filter chips (hidden in select mode to keep UI focused) ---
          if (!isSelectMode) ...[
            const FilterChipsRow(),
            const Divider(height: 1),
          ],

          // --- Results ---
          Expanded(
            child: filterState.isIngredientMode
                ? _IngredientModeBody(
                    isSelectMode: isSelectMode,
                    weekStart: weekStart,
                  )
                : _SearchModeBody(
                    filterState: filterState,
                    isSelectMode: isSelectMode,
                    weekStart: weekStart,
                  ),
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
  const _SearchModeBody({
    required this.filterState,
    this.isSelectMode = false,
    this.weekStart,
  });

  final RecipeFilterState filterState;
  final bool isSelectMode;
  final DateTime? weekStart;

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
                final recipe = results[indexInPage];
                if (widget.isSelectMode) {
                  return _SelectableRecipeCard(
                    recipe: recipe,
                    weekStart: widget.weekStart,
                  );
                }
                return RecipeCard(recipe: recipe);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildError(Object error) {
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
  const _IngredientModeBody({this.isSelectMode = false, this.weekStart});

  final bool isSelectMode;
  final DateTime? weekStart;

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
          error: (_, __) => const Center(
            child: Text('Error loading ingredient-based recipes.'),
          ),
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
              itemBuilder: (_, i) => isSelectMode
                  ? _SelectableRecipeCard(
                      recipe: summaries[i],
                      weekStart: weekStart,
                    )
                  : RecipeCard(recipe: summaries[i]),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Selectable recipe card (select-for-slot mode)
// ---------------------------------------------------------------------------

/// A recipe card that pops with recipe data when tapped, used in
/// select-for-slot mode so the planner can assign the chosen recipe.
///
/// When [weekStart] is provided, shows:
/// - "Planned" chip if the recipe is already assigned to any slot this week.
/// - [IngredientOverlapBadge] if the recipe shares ingredients with week plan
///   (best-effort: only when ingredient names are available from the cache).
class _SelectableRecipeCard extends ConsumerWidget {
  const _SelectableRecipeCard({
    required this.recipe,
    this.weekStart,
  });

  final RecipeSummary recipe;
  final DateTime? weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine if this recipe is already planned this week.
    bool isPlanned = false;
    int overlapCount = 0;

    if (weekStart != null) {
      final slotsAsync = ref.watch(mealPlanProvider(weekStart!));
      final slotList = switch (slotsAsync) {
        AsyncData(:final value) => value,
        _ => <MealSlot>[],
      };
      isPlanned = slotList.any((s) => s.recipeId == recipe.id.toString());

      // Overlap badge: look up cached ingredient names for this recipe.
      // Returns empty list for summary-only cache entries — badge stays hidden (0).
      final candidateAsync =
          ref.watch(cachedRecipeIngredientNamesProvider(recipe.id));
      final candidateNames = switch (candidateAsync) {
        AsyncData(:final value) => value,
        _ => <String>[],
      };
      overlapCount = ref.watch(
        ingredientOverlapCountProvider(
          weekStart: weekStart!,
          candidateIngredientNames: candidateNames,
        ),
      );
    }

    return Stack(
      children: [
        RecipeCard(
          recipe: recipe,
          onTap: () {
            context.pop<Map<String, dynamic>>({
              'recipeId': recipe.id,
              'recipeTitle': recipe.title,
              'recipeImage': recipe.image,
            });
          },
        ),
          if (weekStart != null && (isPlanned || overlapCount > 0))
            Positioned(
              bottom: 8,
              left: 136, // Offset past the 120px thumbnail + some padding
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPlanned)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Planned',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IngredientOverlapBadge(overlapCount: overlapCount),
                ],
              ),
            ),
      ],
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
