// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ingredient _$IngredientFromJson(Map<String, dynamic> json) => _Ingredient(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String?,
  isFavorite: json['isFavorite'] as bool? ?? false,
  dietaryFlags:
      (json['dietaryFlags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  cachedAt: json['cachedAt'] == null
      ? null
      : DateTime.parse(json['cachedAt'] as String),
);

Map<String, dynamic> _$IngredientToJson(_Ingredient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'isFavorite': instance.isFavorite,
      'dietaryFlags': instance.dietaryFlags,
      'cachedAt': instance.cachedAt?.toIso8601String(),
    };
