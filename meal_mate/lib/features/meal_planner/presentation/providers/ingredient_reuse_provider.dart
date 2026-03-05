import 'dart:convert';

import 'package:meal_mate/features/ingredients/data/ingredient_repository_provider.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ingredient_reuse_provider.g.dart';

/// Returns the set of all ingredient names (lowercased) used in the current
/// week's meal plan by loading each assigned recipe from [CachedRecipes].
///
/// - Watches [mealPlanNotifierProvider] reactively — updates whenever slots change.
/// - Parses `extendedIngredients[].name` from each recipe's cached JSON.
/// - Skips any recipe whose cache entry is missing (cache expired).
@riverpod
FutureOr<Set<String>> weekIngredientNames(
  Ref ref,
  DateTime weekStart,
) async {
  final slots = ref.watch(mealPlanNotifierProvider(weekStart));
  final db = ref.watch(appDatabaseProvider);

  // Wait for the meal plan stream to have data.
  final slotList = switch (slots) {
    AsyncData(:final value) => value,
    _ => <dynamic>[],
  };

  final ingredientNames = <String>{};

  for (final slot in slotList) {
    final recipeIdStr = slot.recipeId;
    if (recipeIdStr == null) continue;

    final recipeId = int.tryParse(recipeIdStr);
    if (recipeId == null) continue;

    // Query the cached recipe from Drift.
    final rows = await (db.select(db.cachedRecipes)
          ..where((r) => r.id.equals(recipeId)))
        .get();

    if (rows.isEmpty) continue;

    final row = rows.first;
    // Only full-detail entries have extendedIngredients.
    if (row.isSummaryOnly) continue;

    try {
      final json = jsonDecode(row.jsonData) as Map<String, dynamic>;
      final extendedIngredients = json['extendedIngredients'];
      if (extendedIngredients is List) {
        for (final ingredient in extendedIngredients) {
          if (ingredient is Map<String, dynamic>) {
            final name = ingredient['name'];
            if (name is String && name.isNotEmpty) {
              ingredientNames.add(name.toLowerCase());
            }
          }
        }
      }
    } catch (_) {
      // Malformed JSON — skip silently.
    }
  }

  return ingredientNames;
}

/// Returns lowercased ingredient names for a single recipe from CachedRecipes.
/// Returns empty list if the recipe is not cached or is summary-only (no extendedIngredients).
/// This enables the overlap badge to show real counts for recipes the user has previously viewed in detail.
@riverpod
FutureOr<List<String>> cachedRecipeIngredientNames(
  Ref ref,
  int recipeId,
) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await (db.select(db.cachedRecipes)
        ..where((r) => r.id.equals(recipeId)))
      .get();

  if (rows.isEmpty || rows.first.isSummaryOnly) return [];

  try {
    final json = jsonDecode(rows.first.jsonData) as Map<String, dynamic>;
    final extendedIngredients = json['extendedIngredients'];
    if (extendedIngredients is! List) return [];

    return extendedIngredients
        .whereType<Map<String, dynamic>>()
        .map((ing) => ing['name'])
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .map((n) => n.toLowerCase())
        .toList();
  } catch (_) {
    return [];
  }
}

/// Returns the count of ingredients that the given [candidateIngredientNames]
/// share with the current week's planned recipes.
///
/// - Watches [weekIngredientNamesProvider] — updates reactively.
/// - Returns 0 while the week ingredient set is still loading.
@riverpod
int ingredientOverlapCount(
  Ref ref, {
  required DateTime weekStart,
  required List<String> candidateIngredientNames,
}) {
  final weekNamesAsync = ref.watch(weekIngredientNamesProvider(weekStart));

  return weekNamesAsync.when(
    data: (weekNames) {
      if (weekNames.isEmpty || candidateIngredientNames.isEmpty) return 0;
      final candidateSet =
          candidateIngredientNames.map((n) => n.toLowerCase()).toSet();
      return weekNames.intersection(candidateSet).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
}
