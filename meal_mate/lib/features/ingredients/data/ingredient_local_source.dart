import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:meal_mate/core/database/app_database.dart' as db_lib;
import 'package:meal_mate/core/database/app_database.dart'
    show AppDatabase, IngredientsCompanion, SelectedTodayIngredientsCompanion;
import 'package:meal_mate/features/ingredients/domain/ingredient.dart'
    as domain;
import 'package:meal_mate/features/ingredients/domain/ingredient_filter.dart';

typedef _DbIngredient = db_lib.Ingredient;

class IngredientLocalSource {
  final AppDatabase _db;

  IngredientLocalSource(this._db);

  Future<List<domain.Ingredient>> getIngredientsByCategory(
      String category) async {
    final rows = await (_db.select(_db.ingredients)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_rowToIngredient).toList();
  }

  Future<domain.Ingredient?> getIngredient(String id) async {
    final row = await (_db.select(_db.ingredients)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToIngredient(row);
  }

  Future<void> upsert(domain.Ingredient ingredient, {String userId = ''}) async {
    await _db.into(_db.ingredients).insertOnConflictUpdate(
          _ingredientToCompanion(ingredient, userId: userId),
        );
  }

  Future<void> upsertAll(List<domain.Ingredient> ingredients,
      {String userId = ''}) async {
    await _db.batch((batch) {
      for (final ingredient in ingredients) {
        batch.insert(
          _db.ingredients,
          _ingredientToCompanion(ingredient, userId: userId),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<domain.Ingredient>> filterByDietary(
      Set<DietaryRestriction> restrictions) async {
    final rows = await (_db.select(_db.ingredients)
          ..where((t) {
            Expression<bool>? condition;
            for (final restriction in restrictions) {
              final flag = _restrictionToFlag(restriction);
              final like = t.dietaryFlags.like('%$flag%');
              condition = condition == null ? like : condition & like;
            }
            return condition ?? const Constant(true);
          }))
        .get();
    return rows.map(_rowToIngredient).toList();
  }

  Future<List<domain.Ingredient>> getFavorites() async {
    final rows = await (_db.select(_db.ingredients)
          ..where((t) => t.isFavorite.equals(true)))
        .get();
    return rows.map(_rowToIngredient).toList();
  }

  Future<void> addSelectedToday(String ingredientId, String userId) async {
    // selectedDate stored for audit only — NOT used as a filter
    await _db.into(_db.selectedTodayIngredients).insertOnConflictUpdate(
          SelectedTodayIngredientsCompanion.insert(
            ingredientId: ingredientId,
            selectedDate: DateTime.now(),
            userId: userId,
          ),
        );
  }

  Future<void> removeSelectedToday(String ingredientId) async {
    // No date filter — remove any selection of this ingredient
    await (_db.delete(_db.selectedTodayIngredients)
          ..where((t) => t.ingredientId.equals(ingredientId)))
        .go();
  }

  /// Returns ALL selected ingredient IDs for the user.
  /// Per locked decision: NO date filter — selections persist until manual clear.
  Future<List<String>> getSelectedToday(String userId) async {
    final rows = await (_db.select(_db.selectedTodayIngredients)
          ..where((t) => t.userId.equals(userId)))
        .get();
    return rows.map((r) => r.ingredientId).toList();
  }

  /// Removes ALL selected ingredient entries for the user.
  /// Per locked decision: NO date filter — clears entire selection history.
  Future<void> clearSelectedToday(String userId) async {
    await (_db.delete(_db.selectedTodayIngredients)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  domain.Ingredient _rowToIngredient(_DbIngredient row) {
    final flags = row.dietaryFlags != null
        ? List<String>.from(jsonDecode(row.dietaryFlags!) as List)
        : <String>[];
    return domain.Ingredient(
      id: row.id,
      name: row.name,
      category: row.category,
      isFavorite: row.isFavorite,
      dietaryFlags: flags,
      cachedAt: row.cachedAt,
    );
  }

  IngredientsCompanion _ingredientToCompanion(
    domain.Ingredient ingredient, {
    String userId = '',
  }) {
    return IngredientsCompanion(
      id: Value(ingredient.id),
      name: Value(ingredient.name),
      category: Value(ingredient.category),
      isFavorite: Value(ingredient.isFavorite),
      dietaryFlags: Value(
        ingredient.dietaryFlags.isNotEmpty
            ? jsonEncode(ingredient.dietaryFlags)
            : null,
      ),
      cachedAt: Value(ingredient.cachedAt),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
      userId: Value(userId),
    );
  }

  String _restrictionToFlag(DietaryRestriction restriction) {
    switch (restriction) {
      case DietaryRestriction.vegetarian:
        return 'vegetarian';
      case DietaryRestriction.vegan:
        return 'vegan';
      case DietaryRestriction.glutenFree:
        return 'gluten-free';
      case DietaryRestriction.dairyFree:
        return 'dairy-free';
    }
  }
}
