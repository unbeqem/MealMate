import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/ingredient_repository_provider.dart';
import '../../domain/ingredient.dart';

part 'ingredient_favorites_provider.g.dart';

/// Manages the list of favorited ingredients.
///
/// Supports optimistic toggle: the UI updates immediately while the
/// Drift write happens in the background.
@riverpod
class IngredientFavorites extends _$IngredientFavorites {
  @override
  FutureOr<List<Ingredient>> build() async {
    final repo = ref.watch(ingredientRepositoryProvider);
    return repo.getFavorites();
  }

  Future<void> toggleFavorite(String ingredientId, {String name = ''}) async {
    final repo = ref.read(ingredientRepositoryProvider);
    final currentList = state.value ?? [];
    final existingIndex = currentList.indexWhere((i) => i.id == ingredientId);

    if (existingIndex >= 0) {
      // Already in list — toggle its isFavorite flag (optimistic)
      final updated = List<Ingredient>.from(currentList);
      updated[existingIndex] = updated[existingIndex].copyWith(
        isFavorite: !updated[existingIndex].isFavorite,
      );
      // Remove from favorites list if unfavoriting
      if (!updated[existingIndex].isFavorite) {
        updated.removeAt(existingIndex);
      }
      state = AsyncData(updated);
    } else {
      // New favorite — append to list optimistically
      final newIngredient = Ingredient(
        id: ingredientId,
        name: name.isNotEmpty ? name : ingredientId,
        isFavorite: true,
        cachedAt: DateTime.now(),
      );
      state = AsyncData([...currentList, newIngredient]);
    }

    // Persist to Drift (syncStatus set to pending for future Supabase sync)
    await repo.toggleFavorite(ingredientId, name: name);

    // Refresh from source of truth
    if (!ref.mounted) return;
    state = AsyncData(await repo.getFavorites());
  }
}
