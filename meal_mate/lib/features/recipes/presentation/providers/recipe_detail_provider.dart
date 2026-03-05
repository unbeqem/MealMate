import 'package:meal_mate/features/recipes/data/recipe_repository.dart';
import 'package:meal_mate/features/recipes/domain/recipe.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_detail_provider.g.dart';

// ---------------------------------------------------------------------------
// Recipe detail fetch provider
// ---------------------------------------------------------------------------

/// Fetches a full [Recipe] by Spoonacular ID using cache-first logic.
///
/// Uses [RecipeRepository.getRecipeDetail] which checks the Drift cache (24h TTL)
/// before hitting the Spoonacular API via the Edge Function proxy.
@riverpod
Future<Recipe> recipeDetail(Ref ref, int id) async {
  return ref.watch(recipeRepositoryProvider).getRecipeDetail(id);
}

// ---------------------------------------------------------------------------
// Serving size state provider
// ---------------------------------------------------------------------------

/// Holds the current serving size for a recipe detail view.
///
/// Initialised to [originalServings] (the recipe's canonical serving count).
/// Increment/decrement/setTo mutations are ephemeral UI state — original
/// ingredient amounts are never modified in Drift.
@riverpod
class ServingSizeNotifier extends _$ServingSizeNotifier {
  @override
  int build(int originalServings) => originalServings;

  /// Increases the serving count by 1.
  void increment() => state = state + 1;

  /// Decreases the serving count by 1. Never goes below 1.
  void decrement() {
    if (state > 1) state = state - 1;
  }

  /// Sets the serving count to [value]. Ignored if [value] < 1.
  void setTo(int value) {
    if (value >= 1) state = value;
  }
}
