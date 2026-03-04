import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient.freezed.dart';
part 'ingredient.g.dart';

@freezed
abstract class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String id,
    required String name,
    String? category,
    @Default(false) bool isFavorite,
    @Default([]) List<String> dietaryFlags, // ["vegan", "vegetarian", "gluten-free", "dairy-free"]
    DateTime? cachedAt,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}
