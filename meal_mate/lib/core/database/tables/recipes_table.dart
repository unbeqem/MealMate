import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Recipes extends Table {
  // UUID v4 PK — generated client-side so offline inserts never collide
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  TextColumn get userId => text()();
  TextColumn get title => text()();

  // 'api' | 'ai_generated'
  TextColumn get source =>
      text().withDefault(const Constant('api'))();

  TextColumn get description => text().nullable()();
  TextColumn get instructions => text().nullable()();
  IntColumn get cookTimeMinutes => integer().nullable()();
  IntColumn get servings => integer().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();

  // Spoonacular recipe ID for dedup
  TextColumn get externalId => text().nullable()();

  // Sync metadata — required on every table that syncs to Supabase
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
