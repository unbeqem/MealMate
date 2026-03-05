// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeSearchResult {

 int get offset; int get number; int get totalResults; List<RecipeSummary> get results;
/// Create a copy of RecipeSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeSearchResultCopyWith<RecipeSearchResult> get copyWith => _$RecipeSearchResultCopyWithImpl<RecipeSearchResult>(this as RecipeSearchResult, _$identity);

  /// Serializes this RecipeSearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeSearchResult&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.number, number) || other.number == number)&&(identical(other.totalResults, totalResults) || other.totalResults == totalResults)&&const DeepCollectionEquality().equals(other.results, results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,offset,number,totalResults,const DeepCollectionEquality().hash(results));

@override
String toString() {
  return 'RecipeSearchResult(offset: $offset, number: $number, totalResults: $totalResults, results: $results)';
}


}

/// @nodoc
abstract mixin class $RecipeSearchResultCopyWith<$Res>  {
  factory $RecipeSearchResultCopyWith(RecipeSearchResult value, $Res Function(RecipeSearchResult) _then) = _$RecipeSearchResultCopyWithImpl;
@useResult
$Res call({
 int offset, int number, int totalResults, List<RecipeSummary> results
});




}
/// @nodoc
class _$RecipeSearchResultCopyWithImpl<$Res>
    implements $RecipeSearchResultCopyWith<$Res> {
  _$RecipeSearchResultCopyWithImpl(this._self, this._then);

  final RecipeSearchResult _self;
  final $Res Function(RecipeSearchResult) _then;

/// Create a copy of RecipeSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? offset = null,Object? number = null,Object? totalResults = null,Object? results = null,}) {
  return _then(_self.copyWith(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,totalResults: null == totalResults ? _self.totalResults : totalResults // ignore: cast_nullable_to_non_nullable
as int,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<RecipeSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeSearchResult].
extension RecipeSearchResultPatterns on RecipeSearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeSearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeSearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeSearchResult value)  $default,){
final _that = this;
switch (_that) {
case _RecipeSearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeSearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeSearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int offset,  int number,  int totalResults,  List<RecipeSummary> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeSearchResult() when $default != null:
return $default(_that.offset,_that.number,_that.totalResults,_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int offset,  int number,  int totalResults,  List<RecipeSummary> results)  $default,) {final _that = this;
switch (_that) {
case _RecipeSearchResult():
return $default(_that.offset,_that.number,_that.totalResults,_that.results);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int offset,  int number,  int totalResults,  List<RecipeSummary> results)?  $default,) {final _that = this;
switch (_that) {
case _RecipeSearchResult() when $default != null:
return $default(_that.offset,_that.number,_that.totalResults,_that.results);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeSearchResult implements RecipeSearchResult {
  const _RecipeSearchResult({required this.offset, required this.number, required this.totalResults, final  List<RecipeSummary> results = const []}): _results = results;
  factory _RecipeSearchResult.fromJson(Map<String, dynamic> json) => _$RecipeSearchResultFromJson(json);

@override final  int offset;
@override final  int number;
@override final  int totalResults;
 final  List<RecipeSummary> _results;
@override@JsonKey() List<RecipeSummary> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of RecipeSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeSearchResultCopyWith<_RecipeSearchResult> get copyWith => __$RecipeSearchResultCopyWithImpl<_RecipeSearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeSearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeSearchResult&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.number, number) || other.number == number)&&(identical(other.totalResults, totalResults) || other.totalResults == totalResults)&&const DeepCollectionEquality().equals(other._results, _results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,offset,number,totalResults,const DeepCollectionEquality().hash(_results));

@override
String toString() {
  return 'RecipeSearchResult(offset: $offset, number: $number, totalResults: $totalResults, results: $results)';
}


}

/// @nodoc
abstract mixin class _$RecipeSearchResultCopyWith<$Res> implements $RecipeSearchResultCopyWith<$Res> {
  factory _$RecipeSearchResultCopyWith(_RecipeSearchResult value, $Res Function(_RecipeSearchResult) _then) = __$RecipeSearchResultCopyWithImpl;
@override @useResult
$Res call({
 int offset, int number, int totalResults, List<RecipeSummary> results
});




}
/// @nodoc
class __$RecipeSearchResultCopyWithImpl<$Res>
    implements _$RecipeSearchResultCopyWith<$Res> {
  __$RecipeSearchResultCopyWithImpl(this._self, this._then);

  final _RecipeSearchResult _self;
  final $Res Function(_RecipeSearchResult) _then;

/// Create a copy of RecipeSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? offset = null,Object? number = null,Object? totalResults = null,Object? results = null,}) {
  return _then(_RecipeSearchResult(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,totalResults: null == totalResults ? _self.totalResults : totalResults // ignore: cast_nullable_to_non_nullable
as int,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<RecipeSummary>,
  ));
}


}


/// @nodoc
mixin _$RecipeSummary {

 int get id; String get title; String? get image; String? get imageType;
/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeSummaryCopyWith<RecipeSummary> get copyWith => _$RecipeSummaryCopyWithImpl<RecipeSummary>(this as RecipeSummary, _$identity);

  /// Serializes this RecipeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image)&&(identical(other.imageType, imageType) || other.imageType == imageType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image,imageType);

@override
String toString() {
  return 'RecipeSummary(id: $id, title: $title, image: $image, imageType: $imageType)';
}


}

/// @nodoc
abstract mixin class $RecipeSummaryCopyWith<$Res>  {
  factory $RecipeSummaryCopyWith(RecipeSummary value, $Res Function(RecipeSummary) _then) = _$RecipeSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String title, String? image, String? imageType
});




}
/// @nodoc
class _$RecipeSummaryCopyWithImpl<$Res>
    implements $RecipeSummaryCopyWith<$Res> {
  _$RecipeSummaryCopyWithImpl(this._self, this._then);

  final RecipeSummary _self;
  final $Res Function(RecipeSummary) _then;

/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? image = freezed,Object? imageType = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,imageType: freezed == imageType ? _self.imageType : imageType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeSummary].
extension RecipeSummaryPatterns on RecipeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeSummary value)  $default,){
final _that = this;
switch (_that) {
case _RecipeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String? image,  String? imageType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
return $default(_that.id,_that.title,_that.image,_that.imageType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String? image,  String? imageType)  $default,) {final _that = this;
switch (_that) {
case _RecipeSummary():
return $default(_that.id,_that.title,_that.image,_that.imageType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String? image,  String? imageType)?  $default,) {final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
return $default(_that.id,_that.title,_that.image,_that.imageType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeSummary implements RecipeSummary {
  const _RecipeSummary({required this.id, required this.title, this.image, this.imageType});
  factory _RecipeSummary.fromJson(Map<String, dynamic> json) => _$RecipeSummaryFromJson(json);

@override final  int id;
@override final  String title;
@override final  String? image;
@override final  String? imageType;

/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeSummaryCopyWith<_RecipeSummary> get copyWith => __$RecipeSummaryCopyWithImpl<_RecipeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image)&&(identical(other.imageType, imageType) || other.imageType == imageType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image,imageType);

@override
String toString() {
  return 'RecipeSummary(id: $id, title: $title, image: $image, imageType: $imageType)';
}


}

/// @nodoc
abstract mixin class _$RecipeSummaryCopyWith<$Res> implements $RecipeSummaryCopyWith<$Res> {
  factory _$RecipeSummaryCopyWith(_RecipeSummary value, $Res Function(_RecipeSummary) _then) = __$RecipeSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String? image, String? imageType
});




}
/// @nodoc
class __$RecipeSummaryCopyWithImpl<$Res>
    implements _$RecipeSummaryCopyWith<$Res> {
  __$RecipeSummaryCopyWithImpl(this._self, this._then);

  final _RecipeSummary _self;
  final $Res Function(_RecipeSummary) _then;

/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? image = freezed,Object? imageType = freezed,}) {
  return _then(_RecipeSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,imageType: freezed == imageType ? _self.imageType : imageType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
