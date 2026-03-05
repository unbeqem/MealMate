// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extended_ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExtendedIngredient _$ExtendedIngredientFromJson(Map<String, dynamic> json) =>
    _ExtendedIngredient(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      original: json['original'] as String?,
    );

Map<String, dynamic> _$ExtendedIngredientToJson(_ExtendedIngredient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'unit': instance.unit,
      'original': instance.original,
    };
