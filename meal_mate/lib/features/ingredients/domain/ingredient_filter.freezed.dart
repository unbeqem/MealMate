// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingredient_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IngredientFilter {

 String? get query; String? get category; Set<DietaryRestriction> get dietaryRestrictions;
/// Create a copy of IngredientFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngredientFilterCopyWith<IngredientFilter> get copyWith => _$IngredientFilterCopyWithImpl<IngredientFilter>(this as IngredientFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngredientFilter&&(identical(other.query, query) || other.query == query)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.dietaryRestrictions, dietaryRestrictions));
}


@override
int get hashCode => Object.hash(runtimeType,query,category,const DeepCollectionEquality().hash(dietaryRestrictions));

@override
String toString() {
  return 'IngredientFilter(query: $query, category: $category, dietaryRestrictions: $dietaryRestrictions)';
}


}

/// @nodoc
abstract mixin class $IngredientFilterCopyWith<$Res>  {
  factory $IngredientFilterCopyWith(IngredientFilter value, $Res Function(IngredientFilter) _then) = _$IngredientFilterCopyWithImpl;
@useResult
$Res call({
 String? query, String? category, Set<DietaryRestriction> dietaryRestrictions
});




}
/// @nodoc
class _$IngredientFilterCopyWithImpl<$Res>
    implements $IngredientFilterCopyWith<$Res> {
  _$IngredientFilterCopyWithImpl(this._self, this._then);

  final IngredientFilter _self;
  final $Res Function(IngredientFilter) _then;

/// Create a copy of IngredientFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = freezed,Object? category = freezed,Object? dietaryRestrictions = null,}) {
  return _then(_self.copyWith(
query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,dietaryRestrictions: null == dietaryRestrictions ? _self.dietaryRestrictions : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
as Set<DietaryRestriction>,
  ));
}

}


/// Adds pattern-matching-related methods to [IngredientFilter].
extension IngredientFilterPatterns on IngredientFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IngredientFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IngredientFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IngredientFilter value)  $default,){
final _that = this;
switch (_that) {
case _IngredientFilter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IngredientFilter value)?  $default,){
final _that = this;
switch (_that) {
case _IngredientFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? query,  String? category,  Set<DietaryRestriction> dietaryRestrictions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IngredientFilter() when $default != null:
return $default(_that.query,_that.category,_that.dietaryRestrictions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? query,  String? category,  Set<DietaryRestriction> dietaryRestrictions)  $default,) {final _that = this;
switch (_that) {
case _IngredientFilter():
return $default(_that.query,_that.category,_that.dietaryRestrictions);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? query,  String? category,  Set<DietaryRestriction> dietaryRestrictions)?  $default,) {final _that = this;
switch (_that) {
case _IngredientFilter() when $default != null:
return $default(_that.query,_that.category,_that.dietaryRestrictions);case _:
  return null;

}
}

}

/// @nodoc


class _IngredientFilter implements IngredientFilter {
  const _IngredientFilter({this.query, this.category, final  Set<DietaryRestriction> dietaryRestrictions = const {}}): _dietaryRestrictions = dietaryRestrictions;
  

@override final  String? query;
@override final  String? category;
 final  Set<DietaryRestriction> _dietaryRestrictions;
@override@JsonKey() Set<DietaryRestriction> get dietaryRestrictions {
  if (_dietaryRestrictions is EqualUnmodifiableSetView) return _dietaryRestrictions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_dietaryRestrictions);
}


/// Create a copy of IngredientFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngredientFilterCopyWith<_IngredientFilter> get copyWith => __$IngredientFilterCopyWithImpl<_IngredientFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IngredientFilter&&(identical(other.query, query) || other.query == query)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._dietaryRestrictions, _dietaryRestrictions));
}


@override
int get hashCode => Object.hash(runtimeType,query,category,const DeepCollectionEquality().hash(_dietaryRestrictions));

@override
String toString() {
  return 'IngredientFilter(query: $query, category: $category, dietaryRestrictions: $dietaryRestrictions)';
}


}

/// @nodoc
abstract mixin class _$IngredientFilterCopyWith<$Res> implements $IngredientFilterCopyWith<$Res> {
  factory _$IngredientFilterCopyWith(_IngredientFilter value, $Res Function(_IngredientFilter) _then) = __$IngredientFilterCopyWithImpl;
@override @useResult
$Res call({
 String? query, String? category, Set<DietaryRestriction> dietaryRestrictions
});




}
/// @nodoc
class __$IngredientFilterCopyWithImpl<$Res>
    implements _$IngredientFilterCopyWith<$Res> {
  __$IngredientFilterCopyWithImpl(this._self, this._then);

  final _IngredientFilter _self;
  final $Res Function(_IngredientFilter) _then;

/// Create a copy of IngredientFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = freezed,Object? category = freezed,Object? dietaryRestrictions = null,}) {
  return _then(_IngredientFilter(
query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,dietaryRestrictions: null == dietaryRestrictions ? _self._dietaryRestrictions : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
as Set<DietaryRestriction>,
  ));
}


}

// dart format on
