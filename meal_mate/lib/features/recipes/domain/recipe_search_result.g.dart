// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeSearchResult _$RecipeSearchResultFromJson(Map<String, dynamic> json) =>
    _RecipeSearchResult(
      offset: (json['offset'] as num).toInt(),
      number: (json['number'] as num).toInt(),
      totalResults: (json['totalResults'] as num).toInt(),
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RecipeSearchResultToJson(_RecipeSearchResult instance) =>
    <String, dynamic>{
      'offset': instance.offset,
      'number': instance.number,
      'totalResults': instance.totalResults,
      'results': instance.results,
    };

_RecipeSummary _$RecipeSummaryFromJson(Map<String, dynamic> json) =>
    _RecipeSummary(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      image: json['image'] as String?,
      imageType: json['imageType'] as String?,
    );

Map<String, dynamic> _$RecipeSummaryToJson(_RecipeSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image': instance.image,
      'imageType': instance.imageType,
    };
