// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$RecipeCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedRecipesTable get cachedRecipes => attachedDatabase.cachedRecipes;
  RecipeCacheDaoManager get managers => RecipeCacheDaoManager(this);
}

class RecipeCacheDaoManager {
  final _$RecipeCacheDaoMixin _db;
  RecipeCacheDaoManager(this._db);
  $$CachedRecipesTableTableManager get cachedRecipes =>
      $$CachedRecipesTableTableManager(_db.attachedDatabase, _db.cachedRecipes);
}
