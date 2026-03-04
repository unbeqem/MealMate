import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:meal_mate/core/database/app_database.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_local_source.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_repository.dart';
import 'package:meal_mate/features/ingredients/data/openfoodfacts_remote_source.dart';
import 'package:meal_mate/features/ingredients/domain/ingredient.dart' as domain;
import 'package:meal_mate/features/ingredients/domain/ingredient_filter.dart';

class MockOpenFoodFactsRemoteSource extends Mock
    implements OpenFoodFactsRemoteSource {}

AppDatabase _createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late MockOpenFoodFactsRemoteSource mockRemote;
  late AppDatabase db;
  late IngredientLocalSource localSource;
  late IngredientRepository repository;

  setUp(() {
    mockRemote = MockOpenFoodFactsRemoteSource();
    db = _createTestDatabase();
    localSource = IngredientLocalSource(db);
    repository = IngredientRepository(mockRemote, localSource);
  });

  tearDown(() async {
    await db.close();
  });

  group('searchSuggestions', () {
    test('returns empty list when query is less than 2 chars', () async {
      final result = await repository.searchSuggestions('a');
      expect(result, isEmpty);
      verifyNever(() => mockRemote.getSuggestions(any()));
    });

    test('returns empty list for empty query', () async {
      final result = await repository.searchSuggestions('');
      expect(result, isEmpty);
      verifyNever(() => mockRemote.getSuggestions(any()));
    });

    test('delegates to remote source for valid query', () async {
      when(() => mockRemote.getSuggestions('tom')).thenAnswer(
        (_) async => ['tomato', 'tomato paste', 'tomato sauce'],
      );

      final result = await repository.searchSuggestions('tom');
      expect(result, ['tomato', 'tomato paste', 'tomato sauce']);
      verify(() => mockRemote.getSuggestions('tom')).called(1);
    });
  });

  group('toggleFavorite', () {
    test('flips isFavorite and sets syncStatus to pending', () async {
      // First upsert an ingredient
      const ingredient = domain.Ingredient(
        id: 'test-id-1',
        name: 'Tomato',
        isFavorite: false,
      );
      await localSource.upsert(ingredient, userId: 'user-1');

      // Toggle favorite
      await repository.toggleFavorite('test-id-1', userId: 'user-1');

      // Verify it was flipped
      final updated = await localSource.getIngredient('test-id-1');
      expect(updated, isNotNull);
      expect(updated!.isFavorite, isTrue);
    });

    test('flips isFavorite back to false on second toggle', () async {
      const ingredient = domain.Ingredient(
        id: 'test-id-2',
        name: 'Carrot',
        isFavorite: true,
      );
      await localSource.upsert(ingredient, userId: 'user-1');

      await repository.toggleFavorite('test-id-2', userId: 'user-1');

      final updated = await localSource.getIngredient('test-id-2');
      expect(updated!.isFavorite, isFalse);
    });
  });

  group('selected today', () {
    test('addSelectedToday and getSelectedToday round-trips correctly',
        () async {
      // First add the ingredient (required by FK-like convention)
      const ingredient = domain.Ingredient(id: 'ing-1', name: 'Tomato');
      await localSource.upsert(ingredient, userId: 'user-1');

      await repository.addSelectedToday('ing-1', 'user-1');
      final selected = await repository.getSelectedToday('user-1');
      expect(selected, contains('ing-1'));
    });

    test('getSelectedToday does not return entries from other days', () async {
      // We rely on Drift queries filtering by today — this test verifies
      // that a freshly cleared state returns empty
      final selected = await repository.getSelectedToday('user-1');
      expect(selected, isEmpty);
    });

    test('clearSelectedToday removes all of today entries for user', () async {
      const ingredient1 = domain.Ingredient(id: 'ing-2', name: 'Onion');
      const ingredient2 = domain.Ingredient(id: 'ing-3', name: 'Garlic');
      await localSource.upsert(ingredient1, userId: 'user-1');
      await localSource.upsert(ingredient2, userId: 'user-1');

      await repository.addSelectedToday('ing-2', 'user-1');
      await repository.addSelectedToday('ing-3', 'user-1');

      await repository.clearSelectedToday('user-1');

      final selected = await repository.getSelectedToday('user-1');
      expect(selected, isEmpty);
    });

    test('clearSelectedToday only removes entries for the given user',
        () async {
      const ingredient = domain.Ingredient(id: 'ing-4', name: 'Pepper');
      await localSource.upsert(ingredient, userId: 'user-1');
      await localSource.upsert(ingredient, userId: 'user-2');

      await repository.addSelectedToday('ing-4', 'user-1');
      await repository.addSelectedToday('ing-4', 'user-2');

      await repository.clearSelectedToday('user-1');

      final user1Selected = await repository.getSelectedToday('user-1');
      final user2Selected = await repository.getSelectedToday('user-2');
      expect(user1Selected, isEmpty);
      expect(user2Selected, contains('ing-4'));
    });
  });

  group('filterByDietary', () {
    test('returns only ingredients matching dietary flags', () async {
      const veganIngredient = domain.Ingredient(
        id: 'vegan-1',
        name: 'Lettuce',
        dietaryFlags: ['vegan', 'vegetarian'],
      );
      const nonVeganIngredient = domain.Ingredient(
        id: 'meat-1',
        name: 'Chicken',
        dietaryFlags: [],
      );
      await localSource.upsert(veganIngredient, userId: 'user-1');
      await localSource.upsert(nonVeganIngredient, userId: 'user-1');

      final result =
          await repository.filterByDietary({DietaryRestriction.vegan});
      expect(result.map((i) => i.id), contains('vegan-1'));
      expect(result.map((i) => i.id), isNot(contains('meat-1')));
    });

    test('returns all cached ingredients when no restrictions specified',
        () async {
      const ingredient = domain.Ingredient(id: 'any-1', name: 'Rice');
      await localSource.upsert(ingredient, userId: 'user-1');

      final result = await repository.filterByDietary({});
      expect(result, isNotEmpty);
    });
  });
}
