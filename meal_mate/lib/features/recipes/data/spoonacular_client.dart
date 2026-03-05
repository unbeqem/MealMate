import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when Spoonacular returns HTTP 402 (daily quota exhausted).
class QuotaExhaustedException implements Exception {
  const QuotaExhaustedException();

  @override
  String toString() =>
      'QuotaExhaustedException: Daily Spoonacular recipe limit reached. Try again tomorrow.';
}

/// Client that routes all Spoonacular API calls through the `spoonacular-proxy`
/// Supabase Edge Function. The API key is never present in the Flutter bundle.
class SpoonacularClient {
  final SupabaseClient _supabase;

  SpoonacularClient(this._supabase);

  // ---------------------------------------------------------------------------
  // Internal helper
  // ---------------------------------------------------------------------------

  Future<dynamic> _invoke(String path, Map<String, dynamic> params) async {
    final response = await _supabase.functions.invoke(
      'spoonacular-proxy',
      body: {'path': path, 'params': params},
    );

    // FunctionException is thrown by the Supabase client on non-2xx status.
    // We check the status code ourselves to handle 402 specifically.
    // The raw status is available on FunctionException.status.
    if (response.status == 402) {
      throw const QuotaExhaustedException();
    }

    return response.data;
  }

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------

  /// Searches recipes by various filter criteria.
  /// Does NOT request `addRecipeInformation=true` — fetch detail lazily to
  /// preserve Spoonacular API point quota.
  Future<Map<String, dynamic>> complexSearch({
    String? query,
    String? cuisine,
    int? maxReadyTime,
    String? includeIngredients,
    int offset = 0,
    int number = 20,
  }) async {
    final params = <String, dynamic>{
      'offset': offset,
      'number': number,
      if (query != null) 'query': query,
      if (cuisine != null) 'cuisine': cuisine,
      if (maxReadyTime != null) 'maxReadyTime': maxReadyTime,
      if (includeIngredients != null) 'includeIngredients': includeIngredients,
    };
    return (await _invoke('/recipes/complexSearch', params))
        as Map<String, dynamic>;
  }

  /// Fetches full recipe details (ingredients, instructions, servings) for a
  /// single Spoonacular recipe ID.
  Future<Map<String, dynamic>> getRecipeInformation(int recipeId) async {
    return (await _invoke(
      '/recipes/$recipeId/information',
      {'includeNutrition': false},
    )) as Map<String, dynamic>;
  }

  /// Finds recipes that can be made from the given list of ingredient names.
  /// Maximises used ingredients (`ranking=1`) and ignores pantry staples.
  Future<List<dynamic>> findByIngredients(List<String> ingredients) async {
    return (await _invoke(
      '/recipes/findByIngredients',
      {
        'ingredients': ingredients.join(','),
        'number': 20,
        'ranking': 1,
        'ignorePantry': true,
      },
    )) as List<dynamic>;
  }
}
