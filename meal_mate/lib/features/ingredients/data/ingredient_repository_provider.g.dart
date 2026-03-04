// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared keepAlive AppDatabase provider for the ingredients feature.
///
/// Must survive navigation — using keepAlive: true.
/// Both Wave 2 plans (03-02 and 03-03) import this provider.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Shared keepAlive AppDatabase provider for the ingredients feature.
///
/// Must survive navigation — using keepAlive: true.
/// Both Wave 2 plans (03-02 and 03-03) import this provider.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Shared keepAlive AppDatabase provider for the ingredients feature.
  ///
  /// Must survive navigation — using keepAlive: true.
  /// Both Wave 2 plans (03-02 and 03-03) import this provider.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'98a09c6cfd43966155dfbdb0787fa18c85438e13';

/// Provides the IngredientRepository as the single source of truth
/// for all ingredient operations throughout Phase 3.

@ProviderFor(ingredientRepository)
final ingredientRepositoryProvider = IngredientRepositoryProvider._();

/// Provides the IngredientRepository as the single source of truth
/// for all ingredient operations throughout Phase 3.

final class IngredientRepositoryProvider
    extends
        $FunctionalProvider<
          IngredientRepository,
          IngredientRepository,
          IngredientRepository
        >
    with $Provider<IngredientRepository> {
  /// Provides the IngredientRepository as the single source of truth
  /// for all ingredient operations throughout Phase 3.
  IngredientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientRepositoryHash();

  @$internal
  @override
  $ProviderElement<IngredientRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IngredientRepository create(Ref ref) {
    return ingredientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IngredientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IngredientRepository>(value),
    );
  }
}

String _$ingredientRepositoryHash() =>
    r'1f7679582974c259483744d59f011802140d385c';
