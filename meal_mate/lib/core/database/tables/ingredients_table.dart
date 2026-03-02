import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Ingredients extends Table {
  // UUID v4 PK — generated client-side so offline inserts never collide
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();

  // Sync metadata — required on every table that syncs to Supabase
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
