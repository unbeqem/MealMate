import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';
import 'tables/ingredients_table.dart';
import 'tables/recipes_table.dart';
import 'tables/meal_plan_slots_table.dart';
import 'tables/shopping_list_items_table.dart';
import 'tables/selected_today_table.dart';
import 'tables/cached_recipes_table.dart';
import 'tables/meal_plan_templates_table.dart';
import 'tables/meal_plan_template_slots_table.dart';
import '../../features/recipes/data/recipe_cache_dao.dart';

part 'app_database.g.dart';

// Shared UUID generator — accessible to the generated app_database.g.dart part file
// (table-level _uuid constants are not visible across non-part imports)
// ignore: unused_element
const _uuid = Uuid();

@DriftDatabase(
  tables: [
    Ingredients,
    Recipes,
    MealPlanSlots,
    ShoppingListItems,
    SelectedTodayIngredients,
    CachedRecipes,
    MealPlanTemplates,
    MealPlanTemplateSlots,
  ],
  daos: [RecipeCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mealmate');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Add new columns to ingredients table
        await m.addColumn(ingredients, ingredients.isFavorite);
        await m.addColumn(ingredients, ingredients.dietaryFlags);
        await m.addColumn(ingredients, ingredients.cachedAt);
        // Create selected_today_ingredients table
        await m.createTable(selectedTodayIngredients);
      }
      if (from < 3) {
        // Phase 4: Add Spoonacular recipe cache table
        await m.createTable(cachedRecipes);
      }
      if (from < 4) {
        // Phase 5: Add meal plan template tables
        await m.createTable(mealPlanTemplates);
        await m.createTable(mealPlanTemplateSlots);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
