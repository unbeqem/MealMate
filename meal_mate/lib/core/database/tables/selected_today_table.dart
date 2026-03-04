import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class SelectedTodayIngredients extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get ingredientId => text()();
  DateTimeColumn get selectedDate => dateTime()();
  TextColumn get userId => text()();

  @override
  Set<Column> get primaryKey => {id};
}
