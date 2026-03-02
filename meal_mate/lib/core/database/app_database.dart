import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/ingredients_table.dart';
import 'tables/recipes_table.dart';
import 'tables/meal_plan_slots_table.dart';
import 'tables/shopping_list_items_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Ingredients, Recipes, MealPlanSlots, ShoppingListItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mealmate');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Phase 1 is schemaVersion 1 — no upgrades yet
      // Future migrations: if (from < 2) { await m.addColumn(...); }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
