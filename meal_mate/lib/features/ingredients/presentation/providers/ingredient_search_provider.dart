import 'dart:async';

import 'package:meal_mate/core/assets/common_ingredients.dart';
import 'package:meal_mate/features/ingredients/data/ingredient_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ingredient_search_provider.g.dart';

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
@riverpod
class IngredientSearch extends _$IngredientSearch {
  Timer? _debounce;

  @override
  FutureOr<List<String>> build() => [];

  Future<void> search(String query) async {
    _debounce?.cancel();
    if (query.length < 2) {
      state = const AsyncData([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      state = const AsyncLoading();

      // LOCAL-FIRST: match against curated list (instant, no API call)
      final localResults = commonIngredients
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .take(10)
          .toList();

      if (localResults.length >= 5) {
        // Fast path — enough local matches, skip API call entirely
        state = AsyncData(localResults);
        return;
      }

      // FALLBACK: OFf API for less common items
      state = await AsyncValue.guard(() async {
        final apiResults = await ref
            .read(ingredientRepositoryProvider)
            .searchSuggestions(query);
        // Deduplicate: combine local + API, prefer local matches first
        final combined = <String>{...localResults, ...apiResults};
        return combined.take(20).toList();
      });
    });
    ref.onDispose(() => _debounce?.cancel());
  }
}
