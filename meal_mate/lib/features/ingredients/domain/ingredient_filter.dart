import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient_filter.freezed.dart';

enum DietaryRestriction { vegetarian, vegan, glutenFree, dairyFree }

@freezed
abstract class IngredientFilter with _$IngredientFilter {
  const factory IngredientFilter({
    String? query,
    String? category,
    @Default({}) Set<DietaryRestriction> dietaryRestrictions,
  }) = _IngredientFilter;
}
