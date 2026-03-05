// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MealSlot {

 String get id; String get dayOfWeek; String get mealType; DateTime get weekStart; String? get recipeId;// Spoonacular ID as string (e.g. "716429")
 String? get recipeTitle; String? get recipeImage;
/// Create a copy of MealSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealSlotCopyWith<MealSlot> get copyWith => _$MealSlotCopyWithImpl<MealSlot>(this as MealSlot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.recipeTitle, recipeTitle) || other.recipeTitle == recipeTitle)&&(identical(other.recipeImage, recipeImage) || other.recipeImage == recipeImage));
}


@override
int get hashCode => Object.hash(runtimeType,id,dayOfWeek,mealType,weekStart,recipeId,recipeTitle,recipeImage);

@override
String toString() {
  return 'MealSlot(id: $id, dayOfWeek: $dayOfWeek, mealType: $mealType, weekStart: $weekStart, recipeId: $recipeId, recipeTitle: $recipeTitle, recipeImage: $recipeImage)';
}


}

/// @nodoc
abstract mixin class $MealSlotCopyWith<$Res>  {
  factory $MealSlotCopyWith(MealSlot value, $Res Function(MealSlot) _then) = _$MealSlotCopyWithImpl;
@useResult
$Res call({
 String id, String dayOfWeek, String mealType, DateTime weekStart, String? recipeId, String? recipeTitle, String? recipeImage
});




}
/// @nodoc
class _$MealSlotCopyWithImpl<$Res>
    implements $MealSlotCopyWith<$Res> {
  _$MealSlotCopyWithImpl(this._self, this._then);

  final MealSlot _self;
  final $Res Function(MealSlot) _then;

/// Create a copy of MealSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dayOfWeek = null,Object? mealType = null,Object? weekStart = null,Object? recipeId = freezed,Object? recipeTitle = freezed,Object? recipeImage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,recipeTitle: freezed == recipeTitle ? _self.recipeTitle : recipeTitle // ignore: cast_nullable_to_non_nullable
as String?,recipeImage: freezed == recipeImage ? _self.recipeImage : recipeImage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealSlot].
extension MealSlotPatterns on MealSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealSlot value)  $default,){
final _that = this;
switch (_that) {
case _MealSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealSlot value)?  $default,){
final _that = this;
switch (_that) {
case _MealSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String dayOfWeek,  String mealType,  DateTime weekStart,  String? recipeId,  String? recipeTitle,  String? recipeImage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealSlot() when $default != null:
return $default(_that.id,_that.dayOfWeek,_that.mealType,_that.weekStart,_that.recipeId,_that.recipeTitle,_that.recipeImage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String dayOfWeek,  String mealType,  DateTime weekStart,  String? recipeId,  String? recipeTitle,  String? recipeImage)  $default,) {final _that = this;
switch (_that) {
case _MealSlot():
return $default(_that.id,_that.dayOfWeek,_that.mealType,_that.weekStart,_that.recipeId,_that.recipeTitle,_that.recipeImage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String dayOfWeek,  String mealType,  DateTime weekStart,  String? recipeId,  String? recipeTitle,  String? recipeImage)?  $default,) {final _that = this;
switch (_that) {
case _MealSlot() when $default != null:
return $default(_that.id,_that.dayOfWeek,_that.mealType,_that.weekStart,_that.recipeId,_that.recipeTitle,_that.recipeImage);case _:
  return null;

}
}

}

/// @nodoc


class _MealSlot implements MealSlot {
  const _MealSlot({required this.id, required this.dayOfWeek, required this.mealType, required this.weekStart, this.recipeId, this.recipeTitle, this.recipeImage});
  

@override final  String id;
@override final  String dayOfWeek;
@override final  String mealType;
@override final  DateTime weekStart;
@override final  String? recipeId;
// Spoonacular ID as string (e.g. "716429")
@override final  String? recipeTitle;
@override final  String? recipeImage;

/// Create a copy of MealSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealSlotCopyWith<_MealSlot> get copyWith => __$MealSlotCopyWithImpl<_MealSlot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.recipeTitle, recipeTitle) || other.recipeTitle == recipeTitle)&&(identical(other.recipeImage, recipeImage) || other.recipeImage == recipeImage));
}


@override
int get hashCode => Object.hash(runtimeType,id,dayOfWeek,mealType,weekStart,recipeId,recipeTitle,recipeImage);

@override
String toString() {
  return 'MealSlot(id: $id, dayOfWeek: $dayOfWeek, mealType: $mealType, weekStart: $weekStart, recipeId: $recipeId, recipeTitle: $recipeTitle, recipeImage: $recipeImage)';
}


}

/// @nodoc
abstract mixin class _$MealSlotCopyWith<$Res> implements $MealSlotCopyWith<$Res> {
  factory _$MealSlotCopyWith(_MealSlot value, $Res Function(_MealSlot) _then) = __$MealSlotCopyWithImpl;
@override @useResult
$Res call({
 String id, String dayOfWeek, String mealType, DateTime weekStart, String? recipeId, String? recipeTitle, String? recipeImage
});




}
/// @nodoc
class __$MealSlotCopyWithImpl<$Res>
    implements _$MealSlotCopyWith<$Res> {
  __$MealSlotCopyWithImpl(this._self, this._then);

  final _MealSlot _self;
  final $Res Function(_MealSlot) _then;

/// Create a copy of MealSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dayOfWeek = null,Object? mealType = null,Object? weekStart = null,Object? recipeId = freezed,Object? recipeTitle = freezed,Object? recipeImage = freezed,}) {
  return _then(_MealSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as String,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,recipeTitle: freezed == recipeTitle ? _self.recipeTitle : recipeTitle // ignore: cast_nullable_to_non_nullable
as String?,recipeImage: freezed == recipeImage ? _self.recipeImage : recipeImage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
