import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:meal_mate/features/auth/presentation/auth_notifier.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_repository.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_repository_provider.dart';
import 'package:meal_mate/features/ingredients/domain/ingredient.dart';
import 'package:meal_mate/features/ingredients/presentation/providers/selected_today_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockIngredientRepository extends Mock implements IngredientRepository {}

class MockUser extends Mock implements User {
  @override
  final String id;
  MockUser(this.id);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer makeContainer({
  required IngredientRepository mockRepo,
  User? user,
}) {
  return ProviderContainer(
    overrides: [
      ingredientRepositoryProvider.overrideWithValue(mockRepo),
      currentUserProvider.overrideWithValue(user),
    ],
  );
}

Ingredient makeIngredient(String id, String name) => Ingredient(
      id: id,
      name: name,
      category: 'Produce',
      isFavorite: false,
      dietaryFlags: [],
    );

void main() {
  late MockIngredientRepository mockRepo;
  late MockUser testUser;

  setUp(() {
    mockRepo = MockIngredientRepository();
    testUser = MockUser('user-123');

    // Default stubs
    when(() => mockRepo.getSelectedToday(any())).thenAnswer((_) async => []);
    when(() => mockRepo.addSelectedToday(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockRepo.removeSelectedToday(any()))
        .thenAnswer((_) async {});
    when(() => mockRepo.clearSelectedToday(any())).thenAnswer((_) async {});
  });

  group('SelectedTodayNotifier — Map<String, String> state', () {
    test('build() loads today\'s selections and returns ids (names default to id)', () async {
      when(() => mockRepo.getSelectedToday('user-123'))
          .thenAnswer((_) async => ['ing-1', 'ing-2']);

      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      final state = await container.read(selectedTodayProvider.future);

      // State is Map<String, String> — keys are present
      expect(state, isA<Map<String, String>>());
      expect(state.keys, containsAll(['ing-1', 'ing-2']));
    });

    test('toggle() adds ingredient to map with name when not present', () async {
      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      final notifier = container.read(selectedTodayProvider.notifier);
      await container.read(selectedTodayProvider.future);

      await notifier.toggle('ing-1', name: 'Tomato');

      verify(() => mockRepo.addSelectedToday('ing-1', 'user-123')).called(1);
      final state = container.read(selectedTodayProvider).value;
      expect(state, isNotNull);
      expect(state!.containsKey('ing-1'), isTrue);
      expect(state['ing-1'], equals('Tomato'));
    });

    test('toggle() removes ingredient that is already present', () async {
      when(() => mockRepo.getSelectedToday('user-123'))
          .thenAnswer((_) async => ['ing-1']);

      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      await container.read(selectedTodayProvider.future);

      final notifier = container.read(selectedTodayProvider.notifier);
      await notifier.toggle('ing-1', name: 'Tomato');

      verify(() => mockRepo.removeSelectedToday('ing-1')).called(1);
      final state = container.read(selectedTodayProvider).value;
      expect(state, isNotNull);
      expect(state!.containsKey('ing-1'), isFalse);
    });

    test('addAll() batch-adds multiple ingredients in a single state update', () async {
      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      final notifier = container.read(selectedTodayProvider.notifier);
      await container.read(selectedTodayProvider.future);

      final ingredients = [
        makeIngredient('ing-1', 'Tomato'),
        makeIngredient('ing-2', 'Garlic'),
      ];

      await notifier.addAll(ingredients);

      verify(() => mockRepo.addSelectedToday('ing-1', 'user-123')).called(1);
      verify(() => mockRepo.addSelectedToday('ing-2', 'user-123')).called(1);

      final state = container.read(selectedTodayProvider).value;
      expect(state, isNotNull);
      expect(state!['ing-1'], equals('Tomato'));
      expect(state['ing-2'], equals('Garlic'));
    });

    test('addAll() skips already-selected ingredients', () async {
      // Start with ing-1 already selected
      when(() => mockRepo.getSelectedToday('user-123'))
          .thenAnswer((_) async => ['ing-1']);

      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      await container.read(selectedTodayProvider.future);

      final notifier = container.read(selectedTodayProvider.notifier);
      final ingredients = [
        makeIngredient('ing-1', 'Tomato'),
        makeIngredient('ing-2', 'Garlic'),
      ];

      await notifier.addAll(ingredients);

      // Only ing-2 should be added (ing-1 already present)
      verifyNever(() => mockRepo.addSelectedToday('ing-1', any()));
      verify(() => mockRepo.addSelectedToday('ing-2', 'user-123')).called(1);
    });

    test('clearAll() empties state and calls repository (no date filter)', () async {
      when(() => mockRepo.getSelectedToday('user-123'))
          .thenAnswer((_) async => ['ing-1', 'ing-2']);

      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      await container.read(selectedTodayProvider.future);

      final notifier = container.read(selectedTodayProvider.notifier);
      await notifier.clearAll();

      verify(() => mockRepo.clearSelectedToday('user-123')).called(1);
      final state = container.read(selectedTodayProvider).value;
      expect(state, isEmpty);
    });

    test('count returns correct number of selected ingredients', () async {
      when(() => mockRepo.getSelectedToday('user-123'))
          .thenAnswer((_) async => ['ing-1', 'ing-2', 'ing-3']);

      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      await container.read(selectedTodayProvider.future);

      final notifier = container.read(selectedTodayProvider.notifier);
      expect(notifier.count, 3);
    });

    test('selectedIds returns correct Set<String>', () async {
      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      await container.read(selectedTodayProvider.future);

      final notifier = container.read(selectedTodayProvider.notifier);

      await notifier.toggle('ing-1', name: 'Tomato');
      await notifier.toggle('ing-2', name: 'Garlic');
      await notifier.toggle('ing-1', name: 'Tomato'); // remove it again

      final ids = notifier.selectedIds;
      expect(ids, isA<Set<String>>());
      expect(ids, contains('ing-2'));
      expect(ids, isNot(contains('ing-1')));
    });

    test('selectedNames returns correct Map<String, String>', () async {
      final container = makeContainer(mockRepo: mockRepo, user: testUser);
      addTearDown(container.dispose);

      await container.read(selectedTodayProvider.future);

      final notifier = container.read(selectedTodayProvider.notifier);

      await notifier.toggle('ing-1', name: 'Tomato');
      await notifier.toggle('ing-2', name: 'Garlic');

      final names = notifier.selectedNames;
      expect(names, isA<Map<String, String>>());
      expect(names['ing-1'], equals('Tomato'));
      expect(names['ing-2'], equals('Garlic'));
    });

    test('build() returns empty map when user is null', () async {
      final container = makeContainer(mockRepo: mockRepo, user: null);
      addTearDown(container.dispose);

      final state = await container.read(selectedTodayProvider.future);
      expect(state, isEmpty);
      verifyNever(() => mockRepo.getSelectedToday(any()));
    });
  });
}
