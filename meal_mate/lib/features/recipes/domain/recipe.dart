import 'package:freezed_annotation/freezed_annotation.dart';
import 'extended_ingredient.dart';
import 'analyzed_instruction.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
sealed class Recipe with _$Recipe {
  const factory Recipe({
    required int id,
    required String title,
    String? image,
    required int servings,
    required int readyInMinutes,
    @Default([]) List<ExtendedIngredient> extendedIngredients,
    @Default([]) List<AnalyzedInstruction> analyzedInstructions,
    @Default(false) bool isSummaryOnly,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}
