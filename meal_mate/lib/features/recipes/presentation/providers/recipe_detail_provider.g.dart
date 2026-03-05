// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a full [Recipe] by Spoonacular ID using cache-first logic.
///
/// Uses [RecipeRepository.getRecipeDetail] which checks the Drift cache (24h TTL)
/// before hitting the Spoonacular API via the Edge Function proxy.

@ProviderFor(recipeDetail)
final recipeDetailProvider = RecipeDetailFamily._();

/// Fetches a full [Recipe] by Spoonacular ID using cache-first logic.
///
/// Uses [RecipeRepository.getRecipeDetail] which checks the Drift cache (24h TTL)
/// before hitting the Spoonacular API via the Edge Function proxy.

final class RecipeDetailProvider
    extends $FunctionalProvider<AsyncValue<Recipe>, Recipe, FutureOr<Recipe>>
    with $FutureModifier<Recipe>, $FutureProvider<Recipe> {
  /// Fetches a full [Recipe] by Spoonacular ID using cache-first logic.
  ///
  /// Uses [RecipeRepository.getRecipeDetail] which checks the Drift cache (24h TTL)
  /// before hitting the Spoonacular API via the Edge Function proxy.
  RecipeDetailProvider._({
    required RecipeDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recipeDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeDetailHash();

  @override
  String toString() {
    return r'recipeDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Recipe> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Recipe> create(Ref ref) {
    final argument = this.argument as int;
    return recipeDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeDetailHash() => r'9dc5d9fe452798088639305c6b8eab5e98d1ef9d';

/// Fetches a full [Recipe] by Spoonacular ID using cache-first logic.
///
/// Uses [RecipeRepository.getRecipeDetail] which checks the Drift cache (24h TTL)
/// before hitting the Spoonacular API via the Edge Function proxy.

final class RecipeDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Recipe>, int> {
  RecipeDetailFamily._()
    : super(
        retry: null,
        name: r'recipeDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a full [Recipe] by Spoonacular ID using cache-first logic.
  ///
  /// Uses [RecipeRepository.getRecipeDetail] which checks the Drift cache (24h TTL)
  /// before hitting the Spoonacular API via the Edge Function proxy.

  RecipeDetailProvider call(int id) =>
      RecipeDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'recipeDetailProvider';
}

/// Holds the current serving size for a recipe detail view.
///
/// Initialised to [originalServings] (the recipe's canonical serving count).
/// Increment/decrement/setTo mutations are ephemeral UI state — original
/// ingredient amounts are never modified in Drift.

@ProviderFor(ServingSizeNotifier)
final servingSizeProvider = ServingSizeNotifierFamily._();

/// Holds the current serving size for a recipe detail view.
///
/// Initialised to [originalServings] (the recipe's canonical serving count).
/// Increment/decrement/setTo mutations are ephemeral UI state — original
/// ingredient amounts are never modified in Drift.
final class ServingSizeNotifierProvider
    extends $NotifierProvider<ServingSizeNotifier, int> {
  /// Holds the current serving size for a recipe detail view.
  ///
  /// Initialised to [originalServings] (the recipe's canonical serving count).
  /// Increment/decrement/setTo mutations are ephemeral UI state — original
  /// ingredient amounts are never modified in Drift.
  ServingSizeNotifierProvider._({
    required ServingSizeNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'servingSizeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$servingSizeNotifierHash();

  @override
  String toString() {
    return r'servingSizeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ServingSizeNotifier create() => ServingSizeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ServingSizeNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$servingSizeNotifierHash() =>
    r'a9f40261ff80800a8bf79a47b80a29784d33de17';

/// Holds the current serving size for a recipe detail view.
///
/// Initialised to [originalServings] (the recipe's canonical serving count).
/// Increment/decrement/setTo mutations are ephemeral UI state — original
/// ingredient amounts are never modified in Drift.

final class ServingSizeNotifierFamily extends $Family
    with $ClassFamilyOverride<ServingSizeNotifier, int, int, int, int> {
  ServingSizeNotifierFamily._()
    : super(
        retry: null,
        name: r'servingSizeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the current serving size for a recipe detail view.
  ///
  /// Initialised to [originalServings] (the recipe's canonical serving count).
  /// Increment/decrement/setTo mutations are ephemeral UI state — original
  /// ingredient amounts are never modified in Drift.

  ServingSizeNotifierProvider call(int originalServings) =>
      ServingSizeNotifierProvider._(argument: originalServings, from: this);

  @override
  String toString() => r'servingSizeProvider';
}

/// Holds the current serving size for a recipe detail view.
///
/// Initialised to [originalServings] (the recipe's canonical serving count).
/// Increment/decrement/setTo mutations are ephemeral UI state — original
/// ingredient amounts are never modified in Drift.

abstract class _$ServingSizeNotifier extends $Notifier<int> {
  late final _$args = ref.$arg as int;
  int get originalServings => _$args;

  int build(int originalServings);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
