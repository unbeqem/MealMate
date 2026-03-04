import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/auth/presentation/auth_notifier.dart';
import '../../data/ingredient_repository_provider.dart';
import '../../domain/ingredient.dart';

part 'selected_today_provider.g.dart';

/// Manages the map of ingredient IDs -> names selected as "I have these today".
///
/// CRITICAL: Uses keepAlive: true so this state survives navigation.
/// Phase 4 recipe discovery reads from this provider directly — do NOT
/// store selected-today in route args or widget state.
///
/// State is Map<String, String> (id -> name) so the expandable pill bar
/// can show ingredient name chips without additional async lookups.
///
/// Entries persist until user manually clears — NO date filter per locked decision.
@Riverpod(keepAlive: true)
class SelectedTodayNotifier extends _$SelectedTodayNotifier {
  @override
  FutureOr<Map<String, String>> build() async {
    final repo = ref.watch(ingredientRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    // getSelectedToday returns ALL IDs for userId — no date filter
    final ids = await repo.getSelectedToday(user.id);
    // Build map with id as both key and fallback value
    // Names are populated when toggle() is called with the name parameter
    final map = <String, String>{};
    for (final id in ids) {
      map[id] = id; // Fallback: use ID until name is known
    }
    return map;
  }

  /// Toggles the given ingredient in/out of today's selection.
  ///
  /// Adds if absent (with name for pill bar display), removes if present.
  /// Persists to Drift immediately. No date filter — persists until manual clear.
  Future<void> toggle(String ingredientId, {required String name}) async {
    final repo = ref.read(ingredientRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final current = Map<String, String>.from(state.value ?? {});

    if (current.containsKey(ingredientId)) {
      current.remove(ingredientId);
      await repo.removeSelectedToday(ingredientId);
    } else {
      current[ingredientId] = name;
      await repo.addSelectedToday(ingredientId, user.id);
    }

    if (!ref.mounted) return;
    state = AsyncData(current);
  }

  /// Batch-adds multiple ingredients at once — single state update, avoids N rebuilds.
  /// Per locked decision: "Add all favorites" bulk action.
  /// Skips already-selected ingredients.
  Future<void> addAll(List<Ingredient> ingredients) async {
    final repo = ref.read(ingredientRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final current = Map<String, String>.from(state.value ?? {});

    for (final ingredient in ingredients) {
      if (!current.containsKey(ingredient.id)) {
        current[ingredient.id] = ingredient.name;
        await repo.addSelectedToday(ingredient.id, user.id);
      }
    }

    if (!ref.mounted) return;
    state = AsyncData(current);
  }

  /// Clears ALL of the user's ingredient selections (no date filter).
  Future<void> clearAll() async {
    final repo = ref.read(ingredientRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    // clearSelectedToday removes ALL entries for userId — no date filter
    await repo.clearSelectedToday(user.id);
    if (!ref.mounted) return;
    state = const AsyncData({});
  }

  /// Returns the current set of selected ingredient IDs.
  Set<String> get selectedIds => state.value?.keys.toSet() ?? {};

  /// Returns the current map of id -> name for pill bar chip display.
  Map<String, String> get selectedNames => state.value ?? {};

  /// Returns the number of selected ingredients.
  int get count => selectedIds.length;
}
