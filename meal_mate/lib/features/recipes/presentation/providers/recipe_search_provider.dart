import 'package:meal_mate/features/recipes/data/recipe_repository.dart';
import 'package:meal_mate/features/recipes/domain/recipe_search_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_search_provider.g.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int _kPageSize = 20;

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

/// Holds the current filter selections for the recipe browse screen.
///
/// When [isIngredientMode] is true, the browse screen shows ingredient-based
/// results instead of the normal search/filter results.
class RecipeFilterState {
  const RecipeFilterState({
    this.query = '',
    this.cuisine,
    this.maxReadyTime,
    this.isIngredientMode = false,
  });

  final String query;
  final String? cuisine;
  final int? maxReadyTime;
  final bool isIngredientMode;

  RecipeFilterState copyWith({
    String? query,
    Object? cuisine = _sentinel,
    Object? maxReadyTime = _sentinel,
    bool? isIngredientMode,
  }) {
    return RecipeFilterState(
      query: query ?? this.query,
      cuisine: cuisine == _sentinel ? this.cuisine : cuisine as String?,
      maxReadyTime: maxReadyTime == _sentinel
          ? this.maxReadyTime
          : maxReadyTime as int?,
      isIngredientMode: isIngredientMode ?? this.isIngredientMode,
    );
  }
}

// Sentinel for optional nullable fields in copyWith.
const Object _sentinel = Object();

// ---------------------------------------------------------------------------
// recipeFilterStateProvider
// ---------------------------------------------------------------------------

@riverpod
class RecipeFilterStateNotifier extends _$RecipeFilterStateNotifier {
  @override
  RecipeFilterState build() => const RecipeFilterState();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCuisine(String? cuisine) {
    state = state.copyWith(cuisine: cuisine);
  }

  void setMaxReadyTime(int? maxReadyTime) {
    state = state.copyWith(maxReadyTime: maxReadyTime);
  }

  void toggleIngredientMode() {
    state = state.copyWith(isIngredientMode: !state.isIngredientMode);
  }

  void clearFilters() {
    state = const RecipeFilterState();
  }
}

// ---------------------------------------------------------------------------
// recipeSearchPageProvider
// ---------------------------------------------------------------------------

/// Fetches a single page of recipe search results.
///
/// Parameters: [query], [cuisine], [maxReadyTime], [includeIngredients], [page].
/// Page size is [_kPageSize] (20). Offset is computed as `page * _kPageSize`.
///
/// Each page is cached independently by Riverpod. Call `ref.invalidate` on
/// the family to clear all pages when filters change.
@riverpod
Future<RecipeSearchResult> recipeSearchPage(
  Ref ref, {
  String query = '',
  String? cuisine,
  int? maxReadyTime,
  String? includeIngredients,
  required int page,
}) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.searchRecipes(
    query: query.isEmpty ? null : query,
    cuisine: cuisine,
    maxReadyTime: maxReadyTime,
    includeIngredients: includeIngredients,
    offset: page * _kPageSize,
    // number defaults to 20 in searchRecipes — matches _kPageSize
  );
}

// ---------------------------------------------------------------------------
// ingredientBasedRecipesProvider
// ---------------------------------------------------------------------------

/// Finds recipes matching the given list of ingredient names.
///
/// Uses the Spoonacular `findByIngredients` endpoint via [RecipeRepository].
/// Results are cached as summary-only entries in Drift.
@riverpod
Future<List<RecipeSummary>> ingredientBasedRecipes(
  Ref ref,
  List<String> ingredientNames,
) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.findByIngredients(ingredientNames);
}
