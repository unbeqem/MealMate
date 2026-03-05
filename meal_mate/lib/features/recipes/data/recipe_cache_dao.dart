import 'package:drift/drift.dart';
import 'package:meal_mate/core/database/app_database.dart';
import 'package:meal_mate/core/database/tables/cached_recipes_table.dart';

part 'recipe_cache_dao.g.dart';

@DriftAccessor(tables: [CachedRecipes])
class RecipeCacheDao extends DatabaseAccessor<AppDatabase>
    with _$RecipeCacheDaoMixin {
  RecipeCacheDao(super.db);

  static const Duration _ttl = Duration(hours: 24);

  /// Returns cached recipe by Spoonacular ID, or null if not cached.
  Future<CachedRecipe?> getById(int id) =>
      (select(cachedRecipes)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Returns true if the cached entry is within the 24-hour TTL.
  bool isFresh(CachedRecipe row) =>
      DateTime.now().difference(row.cachedAt) < _ttl;

  /// Inserts or updates a cached recipe row (upsert by primary key).
  Future<void> upsert(CachedRecipe row) =>
      into(cachedRecipes).insertOnConflictUpdate(row);

  /// Returns a page of summary-only cached recipes.
  Future<List<CachedRecipe>> getSummaryPage(int offset, int limit) =>
      (select(cachedRecipes)
            ..where((r) => r.isSummaryOnly.equals(true))
            ..limit(limit, offset: offset))
          .get();
}
