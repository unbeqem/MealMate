import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_mate/core/database/app_database.dart';
import 'package:meal_mate/core/database/tables/ingredients_table.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('AppDatabase opens and creates tables successfully', () async {
    // Verify DB is accessible by running a simple select
    final results = await db.select(db.ingredients).get();
    expect(results, isEmpty);
  });

  test('insert ingredient and query back with UUID PK', () async {
    // Insert a row using the Drift companion
    await db.into(db.ingredients).insert(
      IngredientsCompanion.insert(
        userId: 'user-123',
        name: 'Tomato',
      ),
    );

    // Query it back
    final results = await db.select(db.ingredients).get();
    expect(results.length, equals(1));

    final ingredient = results.first;
    expect(ingredient.name, equals('Tomato'));
    expect(ingredient.userId, equals('user-123'));

    // UUID PK was auto-generated (not empty, not an integer string)
    expect(ingredient.id, isNotEmpty);
    // UUID v4 format: 8-4-4-4-12 hex chars with dashes
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    expect(ingredient.id, matches(uuidPattern));
  });

  test('syncStatus defaults to pending and updatedAt is set', () async {
    await db.into(db.ingredients).insert(
      IngredientsCompanion.insert(
        userId: 'user-456',
        name: 'Onion',
      ),
    );

    final results = await db.select(db.ingredients).get();
    final ingredient = results.first;

    expect(ingredient.syncStatus, equals('pending'));
    expect(ingredient.updatedAt, isNotNull);
  });

  test('watch() stream emits update when a row is inserted', () async {
    // Set up a watch stream before inserting
    final stream = db.select(db.ingredients).watch();

    // The stream should initially emit an empty list
    final initialResult = await stream.first;
    expect(initialResult, isEmpty);

    // Insert a row
    await db.into(db.ingredients).insert(
      IngredientsCompanion.insert(
        userId: 'user-789',
        name: 'Garlic',
      ),
    );

    // Wait for the stream to emit with the new row
    final updatedResult = await stream.first;
    expect(updatedResult.length, equals(1));
    expect(updatedResult.first.name, equals('Garlic'));
  });
}
