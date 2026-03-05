// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recipe {

 int get id; String get title; String? get image; int get servings; int get readyInMinutes; List<ExtendedIngredient> get extendedIngredients; List<AnalyzedInstruction> get analyzedInstructions; bool get isSummaryOnly;
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeCopyWith<Recipe> get copyWith => _$RecipeCopyWithImpl<Recipe>(this as Recipe, _$identity);

  /// Serializes this Recipe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.readyInMinutes, readyInMinutes) || other.readyInMinutes == readyInMinutes)&&const DeepCollectionEquality().equals(other.extendedIngredients, extendedIngredients)&&const DeepCollectionEquality().equals(other.analyzedInstructions, analyzedInstructions)&&(identical(other.isSummaryOnly, isSummaryOnly) || other.isSummaryOnly == isSummaryOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image,servings,readyInMinutes,const DeepCollectionEquality().hash(extendedIngredients),const DeepCollectionEquality().hash(analyzedInstructions),isSummaryOnly);

@override
String toString() {
  return 'Recipe(id: $id, title: $title, image: $image, servings: $servings, readyInMinutes: $readyInMinutes, extendedIngredients: $extendedIngredients, analyzedInstructions: $analyzedInstructions, isSummaryOnly: $isSummaryOnly)';
}


}

/// @nodoc
abstract mixin class $RecipeCopyWith<$Res>  {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) _then) = _$RecipeCopyWithImpl;
@useResult
$Res call({
 int id, String title, String? image, int servings, int readyInMinutes, List<ExtendedIngredient> extendedIngredients, List<AnalyzedInstruction> analyzedInstructions, bool isSummaryOnly
});




}
/// @nodoc
class _$RecipeCopyWithImpl<$Res>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._self, this._then);

  final Recipe _self;
  final $Res Function(Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? image = freezed,Object? servings = null,Object? readyInMinutes = null,Object? extendedIngredients = null,Object? analyzedInstructions = null,Object? isSummaryOnly = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,readyInMinutes: null == readyInMinutes ? _self.readyInMinutes : readyInMinutes // ignore: cast_nullable_to_non_nullable
as int,extendedIngredients: null == extendedIngredients ? _self.extendedIngredients : extendedIngredients // ignore: cast_nullable_to_non_nullable
as List<ExtendedIngredient>,analyzedInstructions: null == analyzedInstructions ? _self.analyzedInstructions : analyzedInstructions // ignore: cast_nullable_to_non_nullable
as List<AnalyzedInstruction>,isSummaryOnly: null == isSummaryOnly ? _self.isSummaryOnly : isSummaryOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Recipe].
extension RecipePatterns on Recipe {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recipe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recipe value)  $default,){
final _that = this;
switch (_that) {
case _Recipe():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recipe value)?  $default,){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String? image,  int servings,  int readyInMinutes,  List<ExtendedIngredient> extendedIngredients,  List<AnalyzedInstruction> analyzedInstructions,  bool isSummaryOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.title,_that.image,_that.servings,_that.readyInMinutes,_that.extendedIngredients,_that.analyzedInstructions,_that.isSummaryOnly);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String? image,  int servings,  int readyInMinutes,  List<ExtendedIngredient> extendedIngredients,  List<AnalyzedInstruction> analyzedInstructions,  bool isSummaryOnly)  $default,) {final _that = this;
switch (_that) {
case _Recipe():
return $default(_that.id,_that.title,_that.image,_that.servings,_that.readyInMinutes,_that.extendedIngredients,_that.analyzedInstructions,_that.isSummaryOnly);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String? image,  int servings,  int readyInMinutes,  List<ExtendedIngredient> extendedIngredients,  List<AnalyzedInstruction> analyzedInstructions,  bool isSummaryOnly)?  $default,) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.title,_that.image,_that.servings,_that.readyInMinutes,_that.extendedIngredients,_that.analyzedInstructions,_that.isSummaryOnly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recipe implements Recipe {
  const _Recipe({required this.id, required this.title, this.image, required this.servings, required this.readyInMinutes, final  List<ExtendedIngredient> extendedIngredients = const [], final  List<AnalyzedInstruction> analyzedInstructions = const [], this.isSummaryOnly = false}): _extendedIngredients = extendedIngredients,_analyzedInstructions = analyzedInstructions;
  factory _Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

@override final  int id;
@override final  String title;
@override final  String? image;
@override final  int servings;
@override final  int readyInMinutes;
 final  List<ExtendedIngredient> _extendedIngredients;
@override@JsonKey() List<ExtendedIngredient> get extendedIngredients {
  if (_extendedIngredients is EqualUnmodifiableListView) return _extendedIngredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extendedIngredients);
}

 final  List<AnalyzedInstruction> _analyzedInstructions;
@override@JsonKey() List<AnalyzedInstruction> get analyzedInstructions {
  if (_analyzedInstructions is EqualUnmodifiableListView) return _analyzedInstructions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_analyzedInstructions);
}

@override@JsonKey() final  bool isSummaryOnly;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeCopyWith<_Recipe> get copyWith => __$RecipeCopyWithImpl<_Recipe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.readyInMinutes, readyInMinutes) || other.readyInMinutes == readyInMinutes)&&const DeepCollectionEquality().equals(other._extendedIngredients, _extendedIngredients)&&const DeepCollectionEquality().equals(other._analyzedInstructions, _analyzedInstructions)&&(identical(other.isSummaryOnly, isSummaryOnly) || other.isSummaryOnly == isSummaryOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image,servings,readyInMinutes,const DeepCollectionEquality().hash(_extendedIngredients),const DeepCollectionEquality().hash(_analyzedInstructions),isSummaryOnly);

@override
String toString() {
  return 'Recipe(id: $id, title: $title, image: $image, servings: $servings, readyInMinutes: $readyInMinutes, extendedIngredients: $extendedIngredients, analyzedInstructions: $analyzedInstructions, isSummaryOnly: $isSummaryOnly)';
}


}

/// @nodoc
abstract mixin class _$RecipeCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$RecipeCopyWith(_Recipe value, $Res Function(_Recipe) _then) = __$RecipeCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String? image, int servings, int readyInMinutes, List<ExtendedIngredient> extendedIngredients, List<AnalyzedInstruction> analyzedInstructions, bool isSummaryOnly
});




}
/// @nodoc
class __$RecipeCopyWithImpl<$Res>
    implements _$RecipeCopyWith<$Res> {
  __$RecipeCopyWithImpl(this._self, this._then);

  final _Recipe _self;
  final $Res Function(_Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? image = freezed,Object? servings = null,Object? readyInMinutes = null,Object? extendedIngredients = null,Object? analyzedInstructions = null,Object? isSummaryOnly = null,}) {
  return _then(_Recipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,readyInMinutes: null == readyInMinutes ? _self.readyInMinutes : readyInMinutes // ignore: cast_nullable_to_non_nullable
as int,extendedIngredients: null == extendedIngredients ? _self._extendedIngredients : extendedIngredients // ignore: cast_nullable_to_non_nullable
as List<ExtendedIngredient>,analyzedInstructions: null == analyzedInstructions ? _self._analyzedInstructions : analyzedInstructions // ignore: cast_nullable_to_non_nullable
as List<AnalyzedInstruction>,isSummaryOnly: null == isSummaryOnly ? _self.isSummaryOnly : isSummaryOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
