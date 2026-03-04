import 'package:meal_mate/core/database/app_database.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_local_source.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_repository.dart';
import 'package:meal_mate/features/ingredients/data/openfoodfacts_remote_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ingredient_repository_provider.g.dart';

/// Shared keepAlive AppDatabase provider for the ingredients feature.
///
/// Must survive navigation — using keepAlive: true.
/// Both Wave 2 plans (03-02 and 03-03) import this provider.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => AppDatabase();

/// Provides the IngredientRepository as the single source of truth
/// for all ingredient operations throughout Phase 3.
@riverpod
IngredientRepository ingredientRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return IngredientRepository(
    OpenFoodFactsRemoteSource(),
    IngredientLocalSource(db),
  );
}
