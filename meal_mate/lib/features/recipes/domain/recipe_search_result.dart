import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_search_result.freezed.dart';
part 'recipe_search_result.g.dart';

@freezed
sealed class RecipeSearchResult with _$RecipeSearchResult {
  const factory RecipeSearchResult({
    required int offset,
    required int number,
    required int totalResults,
    @Default([]) List<RecipeSummary> results,
  }) = _RecipeSearchResult;

  factory RecipeSearchResult.fromJson(Map<String, dynamic> json) =>
      _$RecipeSearchResultFromJson(json);
}

@freezed
sealed class RecipeSummary with _$RecipeSummary {
  const factory RecipeSummary({
    required int id,
    required String title,
    String? image,
    String? imageType,
  }) = _RecipeSummary;

  factory RecipeSummary.fromJson(Map<String, dynamic> json) =>
      _$RecipeSummaryFromJson(json);
}
