// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecipeFilterStateNotifier)
final recipeFilterStateProvider = RecipeFilterStateNotifierProvider._();

final class RecipeFilterStateNotifierProvider
    extends $NotifierProvider<RecipeFilterStateNotifier, RecipeFilterState> {
  RecipeFilterStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeFilterStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeFilterStateNotifierHash();

  @$internal
  @override
  RecipeFilterStateNotifier create() => RecipeFilterStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeFilterState>(value),
    );
  }
}

String _$recipeFilterStateNotifierHash() =>
    r'20f4f568e16b54758391aa52aa25e151267f633f';

abstract class _$RecipeFilterStateNotifier
    extends $Notifier<RecipeFilterState> {
  RecipeFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RecipeFilterState, RecipeFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecipeFilterState, RecipeFilterState>,
              RecipeFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetches a single page of recipe search results.
///
/// Parameters: [query], [cuisine], [maxReadyTime], [includeIngredients], [page].
/// Page size is [_kPageSize] (20). Offset is computed as `page * _kPageSize`.
///
/// Each page is cached independently by Riverpod. Call `ref.invalidate` on
/// the family to clear all pages when filters change.

@ProviderFor(recipeSearchPage)
final recipeSearchPageProvider = RecipeSearchPageFamily._();

/// Fetches a single page of recipe search results.
///
/// Parameters: [query], [cuisine], [maxReadyTime], [includeIngredients], [page].
/// Page size is [_kPageSize] (20). Offset is computed as `page * _kPageSize`.
///
/// Each page is cached independently by Riverpod. Call `ref.invalidate` on
/// the family to clear all pages when filters change.

final class RecipeSearchPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecipeSearchResult>,
          RecipeSearchResult,
          FutureOr<RecipeSearchResult>
        >
    with
        $FutureModifier<RecipeSearchResult>,
        $FutureProvider<RecipeSearchResult> {
  /// Fetches a single page of recipe search results.
  ///
  /// Parameters: [query], [cuisine], [maxReadyTime], [includeIngredients], [page].
  /// Page size is [_kPageSize] (20). Offset is computed as `page * _kPageSize`.
  ///
  /// Each page is cached independently by Riverpod. Call `ref.invalidate` on
  /// the family to clear all pages when filters change.
  RecipeSearchPageProvider._({
    required RecipeSearchPageFamily super.from,
    required ({
      String query,
      String? cuisine,
      int? maxReadyTime,
      String? includeIngredients,
      int page,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'recipeSearchPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeSearchPageHash();

  @override
  String toString() {
    return r'recipeSearchPageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<RecipeSearchResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecipeSearchResult> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String query,
              String? cuisine,
              int? maxReadyTime,
              String? includeIngredients,
              int page,
            });
    return recipeSearchPage(
      ref,
      query: argument.query,
      cuisine: argument.cuisine,
      maxReadyTime: argument.maxReadyTime,
      includeIngredients: argument.includeIngredients,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeSearchPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeSearchPageHash() => r'e952788d45bf41755e3ec06581e51dee1aa14008';

/// Fetches a single page of recipe search results.
///
/// Parameters: [query], [cuisine], [maxReadyTime], [includeIngredients], [page].
/// Page size is [_kPageSize] (20). Offset is computed as `page * _kPageSize`.
///
/// Each page is cached independently by Riverpod. Call `ref.invalidate` on
/// the family to clear all pages when filters change.

final class RecipeSearchPageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<RecipeSearchResult>,
          ({
            String query,
            String? cuisine,
            int? maxReadyTime,
            String? includeIngredients,
            int page,
          })
        > {
  RecipeSearchPageFamily._()
    : super(
        retry: null,
        name: r'recipeSearchPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single page of recipe search results.
  ///
  /// Parameters: [query], [cuisine], [maxReadyTime], [includeIngredients], [page].
  /// Page size is [_kPageSize] (20). Offset is computed as `page * _kPageSize`.
  ///
  /// Each page is cached independently by Riverpod. Call `ref.invalidate` on
  /// the family to clear all pages when filters change.

  RecipeSearchPageProvider call({
    String query = '',
    String? cuisine,
    int? maxReadyTime,
    String? includeIngredients,
    required int page,
  }) => RecipeSearchPageProvider._(
    argument: (
      query: query,
      cuisine: cuisine,
      maxReadyTime: maxReadyTime,
      includeIngredients: includeIngredients,
      page: page,
    ),
    from: this,
  );

  @override
  String toString() => r'recipeSearchPageProvider';
}

/// Finds recipes matching the given list of ingredient names.
///
/// Uses the Spoonacular `findByIngredients` endpoint via [RecipeRepository].
/// Results are cached as summary-only entries in Drift.

@ProviderFor(ingredientBasedRecipes)
final ingredientBasedRecipesProvider = IngredientBasedRecipesFamily._();

/// Finds recipes matching the given list of ingredient names.
///
/// Uses the Spoonacular `findByIngredients` endpoint via [RecipeRepository].
/// Results are cached as summary-only entries in Drift.

final class IngredientBasedRecipesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecipeSummary>>,
          List<RecipeSummary>,
          FutureOr<List<RecipeSummary>>
        >
    with
        $FutureModifier<List<RecipeSummary>>,
        $FutureProvider<List<RecipeSummary>> {
  /// Finds recipes matching the given list of ingredient names.
  ///
  /// Uses the Spoonacular `findByIngredients` endpoint via [RecipeRepository].
  /// Results are cached as summary-only entries in Drift.
  IngredientBasedRecipesProvider._({
    required IngredientBasedRecipesFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'ingredientBasedRecipesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ingredientBasedRecipesHash();

  @override
  String toString() {
    return r'ingredientBasedRecipesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RecipeSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecipeSummary>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return ingredientBasedRecipes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IngredientBasedRecipesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ingredientBasedRecipesHash() =>
    r'082ef484a05fbbeb4bc4faaa48e675b36669ab4e';

/// Finds recipes matching the given list of ingredient names.
///
/// Uses the Spoonacular `findByIngredients` endpoint via [RecipeRepository].
/// Results are cached as summary-only entries in Drift.

final class IngredientBasedRecipesFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<RecipeSummary>>, List<String>> {
  IngredientBasedRecipesFamily._()
    : super(
        retry: null,
        name: r'ingredientBasedRecipesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Finds recipes matching the given list of ingredient names.
  ///
  /// Uses the Spoonacular `findByIngredients` endpoint via [RecipeRepository].
  /// Results are cached as summary-only entries in Drift.

  IngredientBasedRecipesProvider call(List<String> ingredientNames) =>
      IngredientBasedRecipesProvider._(argument: ingredientNames, from: this);

  @override
  String toString() => r'ingredientBasedRecipesProvider';
}
