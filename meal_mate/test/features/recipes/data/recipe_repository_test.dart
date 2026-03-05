import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:meal_mate/core/database/app_database.dart' hide Recipe;
import 'package:meal_mate/features/recipes/data/recipe_cache_dao.dart';
import 'package:meal_mate/features/recipes/data/recipe_repository.dart';
import 'package:meal_mate/features/recipes/data/spoonacular_client.dart';
import 'package:meal_mate/features/recipes/domain/recipe.dart';
import 'package:meal_mate/features/recipes/domain/recipe_search_result.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSpoonacularClient extends Mock implements SpoonacularClient {}

class MockRecipeCacheDao extends Mock implements RecipeCacheDao {}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

AppDatabase _createTestDatabase() => AppDatabase(NativeDatabase.memory());

/// Builds a CachedRecipe data row for use in tests.
CachedRecipe _buildCachedRecipe({
  int id = 1,
  String title = 'Test Recipe',
  String? image,
  String? jsonData,
  bool isSummaryOnly = false,
  DateTime? cachedAt,
}) {
  return CachedRecipe(
    id: id,
    title: title,
    image: image,
    jsonData: jsonData ??
        jsonEncode({
          'id': id,
          'title': title,
          'servings': 4,
          'readyInMinutes': 30,
          'extendedIngredients': [],
          'analyzedInstructions': [],
          'isSummaryOnly': isSummaryOnly,
        }),
    isSummaryOnly: isSummaryOnly,
    cachedAt: cachedAt ?? DateTime.now(),
  );
}

/// Builds a fresh API response map for a recipe.
Map<String, dynamic> _buildRecipeApiResponse({
  int id = 1,
  String title = 'API Recipe',
}) {
  return {
    'id': id,
    'title': title,
    'servings': 4,
    'readyInMinutes': 30,
    'extendedIngredients': [],
    'analyzedInstructions': [],
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // Mocktail requires fallback values for custom types used with any()
    registerFallbackValue(
      _buildCachedRecipe(id: 0, title: 'fallback'),
    );
  });

  late MockSpoonacularClient mockClient;
  late MockRecipeCacheDao mockCacheDao;
  late RecipeRepository repository;

  setUp(() {
    mockClient = MockSpoonacularClient();
    mockCacheDao = MockRecipeCacheDao();
    repository = RecipeRepository(mockClient, mockCacheDao);
  });

  // -------------------------------------------------------------------------
  // getRecipeDetail — cache hit
  // -------------------------------------------------------------------------

  group('getRecipeDetail — cache hit', () {
    test('returns cached recipe when cache is fresh and not summary-only',
        () async {
      final cachedRow = _buildCachedRecipe(
        id: 42,
        isSummaryOnly: false,
        cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      when(() => mockCacheDao.getById(42))
          .thenAnswer((_) async => cachedRow);
      when(() => mockCacheDao.isFresh(cachedRow)).thenReturn(true);

      final result = await repository.getRecipeDetail(42);

      expect(result.id, 42);
      verifyNever(() => mockClient.getRecipeInformation(any()));
    });
  });

  // -------------------------------------------------------------------------
  // getRecipeDetail — stale cache
  // -------------------------------------------------------------------------

  group('getRecipeDetail — stale cache', () {
    test('fetches from API when cached entry is stale', () async {
      final staleRow = _buildCachedRecipe(
        id: 7,
        isSummaryOnly: false,
        cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      final apiResponse = _buildRecipeApiResponse(id: 7, title: 'Updated');

      when(() => mockCacheDao.getById(7)).thenAnswer((_) async => staleRow);
      when(() => mockCacheDao.isFresh(staleRow)).thenReturn(false);
      when(() => mockClient.getRecipeInformation(7))
          .thenAnswer((_) async => apiResponse);
      when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

      final result = await repository.getRecipeDetail(7);

      expect(result.title, 'Updated');
      verify(() => mockClient.getRecipeInformation(7)).called(1);
      verify(() => mockCacheDao.upsert(any())).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // getRecipeDetail — cache miss
  // -------------------------------------------------------------------------

  group('getRecipeDetail — cache miss', () {
    test('fetches from API when cache returns null', () async {
      final apiResponse = _buildRecipeApiResponse(id: 99);

      when(() => mockCacheDao.getById(99)).thenAnswer((_) async => null);
      when(() => mockClient.getRecipeInformation(99))
          .thenAnswer((_) async => apiResponse);
      when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

      final result = await repository.getRecipeDetail(99);

      expect(result.id, 99);
      verify(() => mockClient.getRecipeInformation(99)).called(1);
      verify(() => mockCacheDao.upsert(any())).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // getRecipeDetail — summary-only forces refresh
  // -------------------------------------------------------------------------

  group('getRecipeDetail — summary-only in cache', () {
    test('fetches from API when cached entry is summary-only', () async {
      final summaryRow = _buildCachedRecipe(
        id: 5,
        isSummaryOnly: true,
        cachedAt: DateTime.now(),
      );
      final apiResponse = _buildRecipeApiResponse(id: 5);

      when(() => mockCacheDao.getById(5)).thenAnswer((_) async => summaryRow);
      when(() => mockCacheDao.isFresh(summaryRow)).thenReturn(true);
      when(() => mockClient.getRecipeInformation(5))
          .thenAnswer((_) async => apiResponse);
      when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

      final result = await repository.getRecipeDetail(5);

      expect(result.id, 5);
      // Summary-only triggers an API fetch even when fresh
      verify(() => mockClient.getRecipeInformation(5)).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // searchRecipes — caches summaries to Drift
  // -------------------------------------------------------------------------

  group('searchRecipes', () {
    test('caches each result summary to Drift', () async {
      final apiResponse = {
        'offset': 0,
        'number': 2,
        'totalResults': 2,
        'results': [
          {'id': 10, 'title': 'Pasta', 'image': null, 'imageType': null},
          {'id': 11, 'title': 'Salad', 'image': null, 'imageType': null},
        ],
      };

      when(() => mockClient.complexSearch(
            query: any(named: 'query'),
            cuisine: any(named: 'cuisine'),
            maxReadyTime: any(named: 'maxReadyTime'),
            includeIngredients: any(named: 'includeIngredients'),
            offset: any(named: 'offset'),
            number: any(named: 'number'),
          )).thenAnswer((_) async => apiResponse);
      when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

      final result = await repository.searchRecipes(query: 'pasta');

      expect(result.results.length, 2);
      // One upsert call per result
      verify(() => mockCacheDao.upsert(any())).called(2);
    });
  });

  // -------------------------------------------------------------------------
  // findByIngredients — joins ingredient names with commas
  // -------------------------------------------------------------------------

  group('findByIngredients', () {
    test('passes ingredient names as comma-joined string to client', () async {
      final ingredients = ['chicken', 'rice', 'onion'];
      final apiResponse = <dynamic>[
        {'id': 20, 'title': 'Chicken Rice', 'image': null, 'imageType': null},
      ];

      when(() => mockClient.findByIngredients(ingredients))
          .thenAnswer((_) async => apiResponse);
      when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

      final result = await repository.findByIngredients(ingredients);

      expect(result.length, 1);
      expect(result.first.title, 'Chicken Rice');
      verify(() => mockClient.findByIngredients(ingredients)).called(1);
      verify(() => mockCacheDao.upsert(any())).called(1);
    });

    test('caches each summary result to Drift', () async {
      final ingredients = ['tomato'];
      final apiResponse = <dynamic>[
        {'id': 30, 'title': 'Tomato Soup', 'image': null, 'imageType': null},
        {'id': 31, 'title': 'Tomato Pasta', 'image': null, 'imageType': null},
      ];

      when(() => mockClient.findByIngredients(ingredients))
          .thenAnswer((_) async => apiResponse);
      when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

      await repository.findByIngredients(ingredients);

      verify(() => mockCacheDao.upsert(any())).called(2);
    });
  });

  // -------------------------------------------------------------------------
  // Integration test using in-memory Drift DB
  // -------------------------------------------------------------------------

  group('getRecipeDetail — integration with real RecipeCacheDao', () {
    late AppDatabase db;
    late RecipeCacheDao realDao;
    late RecipeRepository integrationRepo;

    setUp(() {
      db = _createTestDatabase();
      realDao = RecipeCacheDao(db);
      integrationRepo = RecipeRepository(mockClient, realDao);
    });

    tearDown(() async {
      await db.close();
    });

    test('cache miss triggers API and stores result in Drift', () async {
      final apiResponse = _buildRecipeApiResponse(id: 200, title: 'Lasagne');

      when(() => mockClient.getRecipeInformation(200))
          .thenAnswer((_) async => apiResponse);

      final result = await integrationRepo.getRecipeDetail(200);

      expect(result.id, 200);
      expect(result.title, 'Lasagne');
      verify(() => mockClient.getRecipeInformation(200)).called(1);

      // Subsequent call should hit the cache and NOT call the client again
      final cached = await integrationRepo.getRecipeDetail(200);
      expect(cached.id, 200);
      verifyNever(() => mockClient.getRecipeInformation(200));
    });
  });
}
