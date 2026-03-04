// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Debounced autocomplete search provider with local-first matching.
///
/// Fires a search request 300ms after the last [search] call, with a minimum
/// query length of 2 characters. Uses auto-dispose to cancel inflight timers
/// when the screen is dismissed.
///
/// Search strategy:
/// 1. Check [commonIngredients] first (instant, no API call).
/// 2. If >= 5 local matches found, return them immediately (fast path).
/// 3. Otherwise, fall back to the OpenFoodFacts API and combine results.

@ProviderFor(IngredientSearch)
final ingredientSearchProvider = IngredientSearchProvider._();

/// Debounced autocomplete search provider with local-first matching.
///
/// Fires a search request 300ms after the last [search] call, with a minimum
/// query length of 2 characters. Uses auto-dispose to cancel inflight timers
/// when the screen is dismissed.
///
/// Search strategy:
/// 1. Check [commonIngredients] first (instant, no API call).
/// 2. If >= 5 local matches found, return them immediately (fast path).
/// 3. Otherwise, fall back to the OpenFoodFacts API and combine results.
final class IngredientSearchProvider
    extends $AsyncNotifierProvider<IngredientSearch, List<String>> {
  /// Debounced autocomplete search provider with local-first matching.
  ///
  /// Fires a search request 300ms after the last [search] call, with a minimum
  /// query length of 2 characters. Uses auto-dispose to cancel inflight timers
  /// when the screen is dismissed.
  ///
  /// Search strategy:
  /// 1. Check [commonIngredients] first (instant, no API call).
  /// 2. If >= 5 local matches found, return them immediately (fast path).
  /// 3. Otherwise, fall back to the OpenFoodFacts API and combine results.
  IngredientSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientSearchHash();

  @$internal
  @override
  IngredientSearch create() => IngredientSearch();
}

String _$ingredientSearchHash() => r'6b287e3929282efd228b9edb340a38e04568e01b';

/// Debounced autocomplete search provider with local-first matching.
///
/// Fires a search request 300ms after the last [search] call, with a minimum
/// query length of 2 characters. Uses auto-dispose to cancel inflight timers
/// when the screen is dismissed.
///
/// Search strategy:
/// 1. Check [commonIngredients] first (instant, no API call).
/// 2. If >= 5 local matches found, return them immediately (fast path).
/// 3. Otherwise, fall back to the OpenFoodFacts API and combine results.

abstract class _$IngredientSearch extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
