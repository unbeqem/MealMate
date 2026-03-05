import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'meal_plan_templates_table.dart';

const _uuid = Uuid();

class MealPlanTemplateSlots extends Table {
  // UUID v4 PK
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  // FK → MealPlanTemplates.id
  TextColumn get templateId =>
      text().references(MealPlanTemplates, #id)();

  // 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday'
  TextColumn get dayOfWeek => text()();

  // 'breakfast' | 'lunch' | 'dinner'
  TextColumn get mealType => text()();

  // Spoonacular integer ID stored as string (e.g. "716429") — same pattern as MealPlanSlots
  TextColumn get recipeId => text().nullable()();

  // Snapshot of recipe title at save time (avoids stale joins when cache is evicted)
  TextColumn get recipeTitle => text().nullable()();

  // Snapshot of recipe image URL at save time
  TextColumn get recipeImage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
