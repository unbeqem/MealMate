// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [SpoonacularClient] backed by the Supabase singleton.

@ProviderFor(spoonacularClient)
final spoonacularClientProvider = SpoonacularClientProvider._();

/// Provides a [SpoonacularClient] backed by the Supabase singleton.

final class SpoonacularClientProvider
    extends
        $FunctionalProvider<
          SpoonacularClient,
          SpoonacularClient,
          SpoonacularClient
        >
    with $Provider<SpoonacularClient> {
  /// Provides a [SpoonacularClient] backed by the Supabase singleton.
  SpoonacularClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spoonacularClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spoonacularClientHash();

  @$internal
  @override
  $ProviderElement<SpoonacularClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SpoonacularClient create(Ref ref) {
    return spoonacularClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpoonacularClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpoonacularClient>(value),
    );
  }
}

String _$spoonacularClientHash() => r'1227c1532a4c7b59fd780e84b649cf7aebdb3ada';

/// Provides the [RecipeRepository] wired to the Spoonacular client and Drift cache.

@ProviderFor(recipeRepository)
final recipeRepositoryProvider = RecipeRepositoryProvider._();

/// Provides the [RecipeRepository] wired to the Spoonacular client and Drift cache.

final class RecipeRepositoryProvider
    extends
        $FunctionalProvider<
          RecipeRepository,
          RecipeRepository,
          RecipeRepository
        >
    with $Provider<RecipeRepository> {
  /// Provides the [RecipeRepository] wired to the Spoonacular client and Drift cache.
  RecipeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecipeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeRepository create(Ref ref) {
    return recipeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeRepository>(value),
    );
  }
}

String _$recipeRepositoryHash() => r'87f9cfcb63510a3058846ee317680e4247367e0f';
