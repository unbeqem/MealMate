import 'dart:convert';
// Hide the Drift-generated Recipe class (from the sync Recipes table) to avoid
// ambiguity with the Freezed domain Recipe model.
import 'package:meal_mate/core/database/app_database.dart' hide Recipe;
import 'package:meal_mate/features/ingredients/data/ingredient_repository_provider.dart'
    show appDatabaseProvider;
import 'package:meal_mate/features/recipes/data/recipe_cache_dao.dart';
import 'package:meal_mate/features/recipes/data/spoonacular_client.dart';
import 'package:meal_mate/features/recipes/domain/recipe.dart';
import 'package:meal_mate/features/recipes/domain/recipe_search_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'recipe_repository.g.dart';

/// Coordinates cache-first recipe reads between [SpoonacularClient] (API layer)
/// and [RecipeCacheDao] (Drift local cache with 24-hour TTL).
class RecipeRepository {
  final SpoonacularClient _client;
  final RecipeCacheDao _cacheDao;

  RecipeRepository(this._client, this._cacheDao);

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Searches recipes via the Spoonacular proxy, caches each result as a
  /// summary-only entry in Drift, and returns the parsed [RecipeSearchResult].
  Future<RecipeSearchResult> searchRecipes({
    String? query,
    String? cuisine,
    int? maxReadyTime,
    String? includeIngredients,
    int offset = 0,
    int number = 20,
  }) async {
    final raw = await _client.complexSearch(
      query: query,
      cuisine: cuisine,
      maxReadyTime: maxReadyTime,
      includeIngredients: includeIngredients,
      offset: offset,
      number: number,
    );
    final result = RecipeSearchResult.fromJson(raw);

    // Cache each summary to Drift (isSummaryOnly = true)
    for (final summary in result.results) {
      await _cacheDao.upsert(
        CachedRecipe(
          id: summary.id,
          title: summary.title,
          image: summary.image,
          jsonData: jsonEncode(summary.toJson()),
          isSummaryOnly: true,
          cachedAt: DateTime.now(),
        ),
      );
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Detail
  // ---------------------------------------------------------------------------

  /// Returns a full [Recipe] using cache-first logic:
  /// - If a fresh (< 24h) full entry exists in Drift, returns it.
  /// - Otherwise fetches from the Spoonacular proxy, caches, and returns.
  Future<Recipe> getRecipeDetail(int id) async {
    final cached = await _cacheDao.getById(id);
    if (cached != null && _cacheDao.isFresh(cached) && !cached.isSummaryOnly) {
      return Recipe.fromJson(
        jsonDecode(cached.jsonData) as Map<String, dynamic>,
      );
    }

    // Cache miss, stale, or summary-only — fetch full detail from API
    final raw = await _client.getRecipeInformation(id);
    final recipe = Recipe.fromJson(raw);

    await _cacheDao.upsert(
      CachedRecipe(
        id: recipe.id,
        title: recipe.title,
        image: recipe.image,
        jsonData: jsonEncode(raw),
        isSummaryOnly: false,
        cachedAt: DateTime.now(),
      ),
    );

    return recipe;
  }

  // ---------------------------------------------------------------------------
  // findByIngredients
  // ---------------------------------------------------------------------------

  /// Returns a list of [RecipeSummary] matching the provided ingredient names.
  /// Results are cached as summary-only entries in Drift.
  Future<List<RecipeSummary>> findByIngredients(
      List<String> ingredientNames) async {
    final rawList = await _client.findByIngredients(ingredientNames);

    final summaries = rawList
        .map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    for (final summary in summaries) {
      await _cacheDao.upsert(
        CachedRecipe(
          id: summary.id,
          title: summary.title,
          image: summary.image,
          jsonData: jsonEncode(summary.toJson()),
          isSummaryOnly: true,
          cachedAt: DateTime.now(),
        ),
      );
    }

    return summaries;
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Provides a [SpoonacularClient] backed by the Supabase singleton.
@riverpod
SpoonacularClient spoonacularClient(Ref ref) {
  return SpoonacularClient(Supabase.instance.client);
}

/// Provides the [RecipeRepository] wired to the Spoonacular client and Drift cache.
@riverpod
RecipeRepository recipeRepository(Ref ref) {
  final client = ref.watch(spoonacularClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return RecipeRepository(client, RecipeCacheDao(db));
}
