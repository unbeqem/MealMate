import 'package:freezed_annotation/freezed_annotation.dart';

part 'extended_ingredient.freezed.dart';
part 'extended_ingredient.g.dart';

@freezed
sealed class ExtendedIngredient with _$ExtendedIngredient {
  const factory ExtendedIngredient({
    required int id,
    required String name,
    required double amount,
    required String unit,
    String? original,
  }) = _ExtendedIngredient;

  factory ExtendedIngredient.fromJson(Map<String, dynamic> json) =>
      _$ExtendedIngredientFromJson(json);
}
