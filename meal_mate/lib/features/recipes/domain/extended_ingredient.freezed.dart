// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'extended_ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExtendedIngredient {

 int get id; String get name; double get amount; String get unit; String? get original;
/// Create a copy of ExtendedIngredient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtendedIngredientCopyWith<ExtendedIngredient> get copyWith => _$ExtendedIngredientCopyWithImpl<ExtendedIngredient>(this as ExtendedIngredient, _$identity);

  /// Serializes this ExtendedIngredient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtendedIngredient&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.original, original) || other.original == original));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,amount,unit,original);

@override
String toString() {
  return 'ExtendedIngredient(id: $id, name: $name, amount: $amount, unit: $unit, original: $original)';
}


}

/// @nodoc
abstract mixin class $ExtendedIngredientCopyWith<$Res>  {
  factory $ExtendedIngredientCopyWith(ExtendedIngredient value, $Res Function(ExtendedIngredient) _then) = _$ExtendedIngredientCopyWithImpl;
@useResult
$Res call({
 int id, String name, double amount, String unit, String? original
});




}
/// @nodoc
class _$ExtendedIngredientCopyWithImpl<$Res>
    implements $ExtendedIngredientCopyWith<$Res> {
  _$ExtendedIngredientCopyWithImpl(this._self, this._then);

  final ExtendedIngredient _self;
  final $Res Function(ExtendedIngredient) _then;

/// Create a copy of ExtendedIngredient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? amount = null,Object? unit = null,Object? original = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExtendedIngredient].
extension ExtendedIngredientPatterns on ExtendedIngredient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExtendedIngredient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExtendedIngredient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExtendedIngredient value)  $default,){
final _that = this;
switch (_that) {
case _ExtendedIngredient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExtendedIngredient value)?  $default,){
final _that = this;
switch (_that) {
case _ExtendedIngredient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  double amount,  String unit,  String? original)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExtendedIngredient() when $default != null:
return $default(_that.id,_that.name,_that.amount,_that.unit,_that.original);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  double amount,  String unit,  String? original)  $default,) {final _that = this;
switch (_that) {
case _ExtendedIngredient():
return $default(_that.id,_that.name,_that.amount,_that.unit,_that.original);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  double amount,  String unit,  String? original)?  $default,) {final _that = this;
switch (_that) {
case _ExtendedIngredient() when $default != null:
return $default(_that.id,_that.name,_that.amount,_that.unit,_that.original);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExtendedIngredient implements ExtendedIngredient {
  const _ExtendedIngredient({required this.id, required this.name, required this.amount, required this.unit, this.original});
  factory _ExtendedIngredient.fromJson(Map<String, dynamic> json) => _$ExtendedIngredientFromJson(json);

@override final  int id;
@override final  String name;
@override final  double amount;
@override final  String unit;
@override final  String? original;

/// Create a copy of ExtendedIngredient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExtendedIngredientCopyWith<_ExtendedIngredient> get copyWith => __$ExtendedIngredientCopyWithImpl<_ExtendedIngredient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExtendedIngredientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExtendedIngredient&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.original, original) || other.original == original));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,amount,unit,original);

@override
String toString() {
  return 'ExtendedIngredient(id: $id, name: $name, amount: $amount, unit: $unit, original: $original)';
}


}

/// @nodoc
abstract mixin class _$ExtendedIngredientCopyWith<$Res> implements $ExtendedIngredientCopyWith<$Res> {
  factory _$ExtendedIngredientCopyWith(_ExtendedIngredient value, $Res Function(_ExtendedIngredient) _then) = __$ExtendedIngredientCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, double amount, String unit, String? original
});




}
/// @nodoc
class __$ExtendedIngredientCopyWithImpl<$Res>
    implements _$ExtendedIngredientCopyWith<$Res> {
  __$ExtendedIngredientCopyWithImpl(this._self, this._then);

  final _ExtendedIngredient _self;
  final $Res Function(_ExtendedIngredient) _then;

/// Create a copy of ExtendedIngredient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? amount = null,Object? unit = null,Object? original = freezed,}) {
  return _then(_ExtendedIngredient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
