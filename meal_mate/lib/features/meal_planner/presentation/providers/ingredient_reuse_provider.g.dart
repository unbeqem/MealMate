// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_reuse_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

/// Returns the set of all ingredient names (lowercased) used in the current
/// week's meal plan by loading each assigned recipe from [CachedRecipes].

@ProviderFor(weekIngredientNames)
final weekIngredientNamesProvider = WeekIngredientNamesFamily._();

/// Returns the set of all ingredient names (lowercased) used in the current
/// week's meal plan by loading each assigned recipe from [CachedRecipes].

final class WeekIngredientNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with
        $FutureModifier<Set<String>>,
        $FutureProvider<Set<String>> {
  /// Returns the set of all ingredient names (lowercased) used in the current
  /// week's meal plan by loading each assigned recipe from [CachedRecipes].
  WeekIngredientNamesProvider._({
    required WeekIngredientNamesFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'weekIngredientNamesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weekIngredientNamesHash();

  @override
  String toString() {
    return r'weekIngredientNamesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return weekIngredientNames(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WeekIngredientNamesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weekIngredientNamesHash() => r'c1d2e3f4a5b6c1d2e3f4a5b6c1d2e3f4a5b6c1d2';

/// Returns the set of all ingredient names (lowercased) used in the current
/// week's meal plan by loading each assigned recipe from [CachedRecipes].

final class WeekIngredientNamesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Set<String>>, DateTime> {
  WeekIngredientNamesFamily._()
    : super(
        retry: null,
        name: r'weekIngredientNamesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the set of all ingredient names (lowercased) used in the current
  /// week's meal plan by loading each assigned recipe from [CachedRecipes].

  WeekIngredientNamesProvider call(DateTime weekStart) =>
      WeekIngredientNamesProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'weekIngredientNamesProvider';
}

// ---------------------------------------------------------------------------
// ingredientOverlapCount — named-param family FutureProvider returning int
// ---------------------------------------------------------------------------

/// Returns the count of ingredients that the given [candidateIngredientNames]
/// share with the current week's planned recipes.

@ProviderFor(ingredientOverlapCount)
final ingredientOverlapCountProvider = IngredientOverlapCountFamily._();

/// Returns the count of ingredients that the given [candidateIngredientNames]
/// share with the current week's planned recipes.

final class IngredientOverlapCountProvider
    extends
        $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Returns the count of ingredients that the given [candidateIngredientNames]
  /// share with the current week's planned recipes.
  IngredientOverlapCountProvider._({
    required IngredientOverlapCountFamily super.from,
    required ({DateTime weekStart, List<String> candidateIngredientNames})
    super.argument,
  }) : super(
         retry: null,
         name: r'ingredientOverlapCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ingredientOverlapCountHash();

  @override
  String toString() {
    return r'ingredientOverlapCountProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument =
        this.argument
            as ({
              DateTime weekStart,
              List<String> candidateIngredientNames,
            });
    return ingredientOverlapCount(
      ref,
      weekStart: argument.weekStart,
      candidateIngredientNames: argument.candidateIngredientNames,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IngredientOverlapCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$ingredientOverlapCountHash() =>
    r'd2e3f4a5b6c1d2e3f4a5b6c1d2e3f4a5b6c1d2e3';

// ---------------------------------------------------------------------------
// cachedRecipeIngredientNames — positional-param family FutureProvider returning List<String>
// ---------------------------------------------------------------------------

/// Returns lowercased ingredient names for a single recipe from CachedRecipes.

@ProviderFor(cachedRecipeIngredientNames)
final cachedRecipeIngredientNamesProvider =
    CachedRecipeIngredientNamesFamily._();

/// Returns lowercased ingredient names for a single recipe from CachedRecipes.

final class CachedRecipeIngredientNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with
        $FutureModifier<List<String>>,
        $FutureProvider<List<String>> {
  /// Returns lowercased ingredient names for a single recipe from CachedRecipes.
  CachedRecipeIngredientNamesProvider._({
    required CachedRecipeIngredientNamesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'cachedRecipeIngredientNamesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cachedRecipeIngredientNamesHash();

  @override
  String toString() {
    return r'cachedRecipeIngredientNamesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as int;
    return cachedRecipeIngredientNames(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedRecipeIngredientNamesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cachedRecipeIngredientNamesHash() =>
    r'e3f4a5b6c1d2e3f4a5b6c1d2e3f4a5b6c1d2e3f4';

/// Returns lowercased ingredient names for a single recipe from CachedRecipes.

final class CachedRecipeIngredientNamesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, int> {
  CachedRecipeIngredientNamesFamily._()
    : super(
        retry: null,
        name: r'cachedRecipeIngredientNamesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns lowercased ingredient names for a single recipe from CachedRecipes.

  CachedRecipeIngredientNamesProvider call(int recipeId) =>
      CachedRecipeIngredientNamesProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'cachedRecipeIngredientNamesProvider';
}

/// Returns the count of ingredients that the given [candidateIngredientNames]
/// share with the current week's planned recipes.

final class IngredientOverlapCountFamily extends $Family
    with
        $FunctionalFamilyOverride<
          int,
          ({DateTime weekStart, List<String> candidateIngredientNames})
        > {
  IngredientOverlapCountFamily._()
    : super(
        retry: null,
        name: r'ingredientOverlapCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the count of ingredients that the given [candidateIngredientNames]
  /// share with the current week's planned recipes.

  IngredientOverlapCountProvider call({
    required DateTime weekStart,
    required List<String> candidateIngredientNames,
  }) => IngredientOverlapCountProvider._(
    argument: (
      weekStart: weekStart,
      candidateIngredientNames: candidateIngredientNames,
    ),
    from: this,
  );

  @override
  String toString() => r'ingredientOverlapCountProvider';
}
