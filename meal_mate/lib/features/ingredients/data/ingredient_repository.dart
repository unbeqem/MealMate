import 'package:meal_mate/features/ingredients/data/ingredient_local_source.dart';
import 'package:meal_mate/features/ingredients/data/openfoodfacts_remote_source.dart';
import 'package:meal_mate/features/ingredients/domain/ingredient.dart';
import 'package:meal_mate/features/ingredients/domain/ingredient_filter.dart';

/// Single source of truth for all ingredient operations.
///
/// Presentation layer never calls OpenFoodFacts or Drift directly — all
/// calls go through this repository.
class IngredientRepository {
  final OpenFoodFactsRemoteSource _remote;
  final IngredientLocalSource _local;

  IngredientRepository(this._remote, this._local);

  /// Returns autocomplete suggestions for the given query.
  /// Returns empty list if query is shorter than 2 characters.
  Future<List<String>> searchSuggestions(String query) async {
    if (query.length < 2) return [];
    return _remote.getSuggestions(query);
  }

  /// Returns a stream of ingredients for the given category.
  ///
  /// Implements pull-through cache: emits cached data immediately,
  /// then fetches from remote, upserts to local, and emits again.
  Stream<List<Ingredient>> watchIngredientsByCategory(String category) async* {
    // Emit cached data first (may be empty on first load)
    final cached = await _local.getIngredientsByCategory(category);
    yield cached;

    // Fetch fresh data from OFf API
    try {
      final categoryTag = _getCategoryTag(category);
      if (categoryTag != null) {
        final fresh = await _remote.searchByCategory(categoryTag);
        if (fresh.isNotEmpty) {
          // Tag each ingredient with the display category name
          final tagged = fresh
              .map((i) => i.copyWith(category: category))
              .toList();
          await _local.upsertAll(tagged);
          yield tagged;
        }
      }
    } catch (_) {
      // Network failure — cached data already emitted, silently ignore
    }
  }

  /// Toggles the favorite status of an ingredient.
  ///
  /// Optimistic write: flips isFavorite locally and marks syncStatus as pending.
  Future<void> toggleFavorite(String ingredientId, {String userId = ''}) async {
    final ingredient = await _local.getIngredient(ingredientId);
    if (ingredient == null) return;
    final updated = ingredient.copyWith(
      isFavorite: !ingredient.isFavorite,
    );
    await _local.upsert(updated, userId: userId);
  }

  Future<List<Ingredient>> getFavorites() => _local.getFavorites();

  Future<List<Ingredient>> filterByDietary(
          Set<DietaryRestriction> restrictions) =>
      _local.filterByDietary(restrictions);

  Future<void> addSelectedToday(String ingredientId, String userId) =>
      _local.addSelectedToday(ingredientId, userId);

  Future<void> removeSelectedToday(String ingredientId) =>
      _local.removeSelectedToday(ingredientId);

  Future<List<String>> getSelectedToday(String userId) =>
      _local.getSelectedToday(userId);

  Future<void> clearSelectedToday(String userId) =>
      _local.clearSelectedToday(userId);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? _getCategoryTag(String displayName) {
    // Look up the OFf category tag from the display name.
    // Import ingredientCategories from remote source.
    return ingredientCategories[displayName];
  }
}
