import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class MealPlanSlots extends Table {
  // UUID v4 PK — generated client-side so offline inserts never collide
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  TextColumn get userId => text()();

  // Spoonacular recipe ID stored as text (e.g. "716429"), nullable when empty
  TextColumn get recipeId => text().nullable()();

  // 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday'
  TextColumn get dayOfWeek => text()();

  // 'breakfast' | 'lunch' | 'dinner'
  TextColumn get mealType => text()();

  // The Monday of the planned week
  DateTimeColumn get weekStart => dateTime()();

  // Sync metadata — required on every table that syncs to Supabase
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
