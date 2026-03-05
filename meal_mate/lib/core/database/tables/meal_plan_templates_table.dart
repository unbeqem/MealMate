import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class MealPlanTemplates extends Table {
  // UUID v4 PK — generated client-side so offline inserts never collide
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  TextColumn get userId => text()();

  // User-defined template name (e.g. "Healthy Week", "Family Favourites")
  TextColumn get name => text()();

  // Audit timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Sync metadata — required on every table that syncs to Supabase
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
