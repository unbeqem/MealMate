// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Recipe _$RecipeFromJson(Map<String, dynamic> json) => _Recipe(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  image: json['image'] as String?,
  servings: (json['servings'] as num).toInt(),
  readyInMinutes: (json['readyInMinutes'] as num).toInt(),
  extendedIngredients:
      (json['extendedIngredients'] as List<dynamic>?)
          ?.map((e) => ExtendedIngredient.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  analyzedInstructions:
      (json['analyzedInstructions'] as List<dynamic>?)
          ?.map((e) => AnalyzedInstruction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isSummaryOnly: json['isSummaryOnly'] as bool? ?? false,
);

Map<String, dynamic> _$RecipeToJson(_Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'image': instance.image,
  'servings': instance.servings,
  'readyInMinutes': instance.readyInMinutes,
  'extendedIngredients': instance.extendedIngredients,
  'analyzedInstructions': instance.analyzedInstructions,
  'isSummaryOnly': instance.isSummaryOnly,
};
