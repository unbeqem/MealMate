import 'package:meal_mate/features/auth/presentation/auth_notifier.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_repository_provider.dart';
import 'package:meal_mate/features/meal_planner/data/meal_plan_repository.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:meal_mate/features/recipes/data/recipe_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_plan_notifier.g.dart';

/// Returns the current user's ID, throwing if not signed in.
@riverpod
String currentUserId(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Not authenticated');
  return user.id;
}

/// Stream-based Riverpod notifier for the weekly meal plan grid.
///
/// Watches Drift reactively — any insert/update/delete on mealPlanSlots
/// for the given [weekStart] automatically emits a new state.
@riverpod
class MealPlanNotifier extends _$MealPlanNotifier {
  late MealPlanRepository _repository;

  @override
  Stream<List<MealSlot>> build(DateTime weekStart) {
    final db = ref.watch(appDatabaseProvider);
    final userId = ref.watch(currentUserIdProvider);
    _repository = MealPlanRepository(db);
    return _repository.watchWeek(userId, weekStart);
  }

  /// Assigns a Spoonacular recipe to the slot identified by its grid position.
  ///
  /// After persisting the slot, triggers a background fetch of the full recipe
  /// detail so that [weekIngredientNamesProvider] can populate the ingredient
  /// summary panel. Recipes assigned from search are cached as summary-only
  /// (no extendedIngredients); this backfill ensures the panel shows chips.
  Future<void> assignRecipe({
    required String dayOfWeek,
    required String mealType,
    required int recipeId,
    String? recipeTitle,
    String? recipeImage,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    await _repository.assignRecipe(
      userId: userId,
      dayOfWeek: dayOfWeek,
      mealType: mealType,
      weekStart: ref.$arg as DateTime,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      recipeImage: recipeImage,
    );

    // Fire-and-forget: fetch full recipe detail to backfill extendedIngredients
    // in the local cache. This enables weekIngredientNamesProvider to populate
    // the ingredient summary panel for newly-assigned recipes.
    // Errors are swallowed — the slot is already assigned; ingredient panel
    // will remain empty for this recipe if the network is unavailable.
    ref.read(recipeRepositoryProvider).getRecipeDetail(recipeId).ignore();
  }

  /// Clears the recipe from a slot (sets recipeId to null).
  Future<void> clearSlot(String slotId) async {
    await _repository.clearSlot(slotId);
  }

  /// Swaps the recipe assignments of two slots.
  Future<void> swapSlots(String slotIdA, String slotIdB) async {
    await _repository.swapSlots(slotIdA, slotIdB);
  }
}
