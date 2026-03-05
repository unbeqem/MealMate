// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analyzed_instruction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalyzedInstruction {

 String get name; List<InstructionStep> get steps;
/// Create a copy of AnalyzedInstruction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyzedInstructionCopyWith<AnalyzedInstruction> get copyWith => _$AnalyzedInstructionCopyWithImpl<AnalyzedInstruction>(this as AnalyzedInstruction, _$identity);

  /// Serializes this AnalyzedInstruction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyzedInstruction&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.steps, steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(steps));

@override
String toString() {
  return 'AnalyzedInstruction(name: $name, steps: $steps)';
}


}

/// @nodoc
abstract mixin class $AnalyzedInstructionCopyWith<$Res>  {
  factory $AnalyzedInstructionCopyWith(AnalyzedInstruction value, $Res Function(AnalyzedInstruction) _then) = _$AnalyzedInstructionCopyWithImpl;
@useResult
$Res call({
 String name, List<InstructionStep> steps
});




}
/// @nodoc
class _$AnalyzedInstructionCopyWithImpl<$Res>
    implements $AnalyzedInstructionCopyWith<$Res> {
  _$AnalyzedInstructionCopyWithImpl(this._self, this._then);

  final AnalyzedInstruction _self;
  final $Res Function(AnalyzedInstruction) _then;

/// Create a copy of AnalyzedInstruction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? steps = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<InstructionStep>,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyzedInstruction].
extension AnalyzedInstructionPatterns on AnalyzedInstruction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyzedInstruction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyzedInstruction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyzedInstruction value)  $default,){
final _that = this;
switch (_that) {
case _AnalyzedInstruction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyzedInstruction value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyzedInstruction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<InstructionStep> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyzedInstruction() when $default != null:
return $default(_that.name,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<InstructionStep> steps)  $default,) {final _that = this;
switch (_that) {
case _AnalyzedInstruction():
return $default(_that.name,_that.steps);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<InstructionStep> steps)?  $default,) {final _that = this;
switch (_that) {
case _AnalyzedInstruction() when $default != null:
return $default(_that.name,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyzedInstruction implements AnalyzedInstruction {
  const _AnalyzedInstruction({this.name = '', final  List<InstructionStep> steps = const []}): _steps = steps;
  factory _AnalyzedInstruction.fromJson(Map<String, dynamic> json) => _$AnalyzedInstructionFromJson(json);

@override@JsonKey() final  String name;
 final  List<InstructionStep> _steps;
@override@JsonKey() List<InstructionStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of AnalyzedInstruction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyzedInstructionCopyWith<_AnalyzedInstruction> get copyWith => __$AnalyzedInstructionCopyWithImpl<_AnalyzedInstruction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyzedInstructionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyzedInstruction&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'AnalyzedInstruction(name: $name, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$AnalyzedInstructionCopyWith<$Res> implements $AnalyzedInstructionCopyWith<$Res> {
  factory _$AnalyzedInstructionCopyWith(_AnalyzedInstruction value, $Res Function(_AnalyzedInstruction) _then) = __$AnalyzedInstructionCopyWithImpl;
@override @useResult
$Res call({
 String name, List<InstructionStep> steps
});




}
/// @nodoc
class __$AnalyzedInstructionCopyWithImpl<$Res>
    implements _$AnalyzedInstructionCopyWith<$Res> {
  __$AnalyzedInstructionCopyWithImpl(this._self, this._then);

  final _AnalyzedInstruction _self;
  final $Res Function(_AnalyzedInstruction) _then;

/// Create a copy of AnalyzedInstruction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? steps = null,}) {
  return _then(_AnalyzedInstruction(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<InstructionStep>,
  ));
}


}


/// @nodoc
mixin _$InstructionStep {

 int get number; String get step;
/// Create a copy of InstructionStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructionStepCopyWith<InstructionStep> get copyWith => _$InstructionStepCopyWithImpl<InstructionStep>(this as InstructionStep, _$identity);

  /// Serializes this InstructionStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructionStep&&(identical(other.number, number) || other.number == number)&&(identical(other.step, step) || other.step == step));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,step);

@override
String toString() {
  return 'InstructionStep(number: $number, step: $step)';
}


}

/// @nodoc
abstract mixin class $InstructionStepCopyWith<$Res>  {
  factory $InstructionStepCopyWith(InstructionStep value, $Res Function(InstructionStep) _then) = _$InstructionStepCopyWithImpl;
@useResult
$Res call({
 int number, String step
});




}
/// @nodoc
class _$InstructionStepCopyWithImpl<$Res>
    implements $InstructionStepCopyWith<$Res> {
  _$InstructionStepCopyWithImpl(this._self, this._then);

  final InstructionStep _self;
  final $Res Function(InstructionStep) _then;

/// Create a copy of InstructionStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? step = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructionStep].
extension InstructionStepPatterns on InstructionStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructionStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructionStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructionStep value)  $default,){
final _that = this;
switch (_that) {
case _InstructionStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructionStep value)?  $default,){
final _that = this;
switch (_that) {
case _InstructionStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  String step)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructionStep() when $default != null:
return $default(_that.number,_that.step);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  String step)  $default,) {final _that = this;
switch (_that) {
case _InstructionStep():
return $default(_that.number,_that.step);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  String step)?  $default,) {final _that = this;
switch (_that) {
case _InstructionStep() when $default != null:
return $default(_that.number,_that.step);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructionStep implements InstructionStep {
  const _InstructionStep({required this.number, required this.step});
  factory _InstructionStep.fromJson(Map<String, dynamic> json) => _$InstructionStepFromJson(json);

@override final  int number;
@override final  String step;

/// Create a copy of InstructionStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructionStepCopyWith<_InstructionStep> get copyWith => __$InstructionStepCopyWithImpl<_InstructionStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructionStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructionStep&&(identical(other.number, number) || other.number == number)&&(identical(other.step, step) || other.step == step));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,step);

@override
String toString() {
  return 'InstructionStep(number: $number, step: $step)';
}


}

/// @nodoc
abstract mixin class _$InstructionStepCopyWith<$Res> implements $InstructionStepCopyWith<$Res> {
  factory _$InstructionStepCopyWith(_InstructionStep value, $Res Function(_InstructionStep) _then) = __$InstructionStepCopyWithImpl;
@override @useResult
$Res call({
 int number, String step
});




}
/// @nodoc
class __$InstructionStepCopyWithImpl<$Res>
    implements _$InstructionStepCopyWith<$Res> {
  __$InstructionStepCopyWithImpl(this._self, this._then);

  final _InstructionStep _self;
  final $Res Function(_InstructionStep) _then;

/// Create a copy of InstructionStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? step = null,}) {
  return _then(_InstructionStep(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
