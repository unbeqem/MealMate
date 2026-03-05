import 'package:drift/drift.dart';

/// Drift table for caching Spoonacular recipe data locally.
/// Uses Spoonacular's integer recipe ID as primary key (not UUID).
class CachedRecipes extends Table {
  /// Spoonacular recipe ID — integer PK, not UUID (external key)
  IntColumn get id => integer()();

  TextColumn get title => text()();
  TextColumn get image => text().nullable()();

  /// Full JSON from getRecipeInformation (or summary JSON from complexSearch)
  TextColumn get jsonData => text()();

  /// True when cached from complexSearch (no ingredients/instructions)
  BoolColumn get isSummaryOnly =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
