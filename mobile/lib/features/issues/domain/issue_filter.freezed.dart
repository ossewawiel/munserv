// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueFilter {

 String get sectorId; IssueState? get state; IssueType? get type; int get page; int get limit; IssueSortBy get sortBy;
/// Create a copy of IssueFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueFilterCopyWith<IssueFilter> get copyWith => _$IssueFilterCopyWithImpl<IssueFilter>(this as IssueFilter, _$identity);

  /// Serializes this IssueFilter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueFilter&&(identical(other.sectorId, _this.sectorId) || other.sectorId == _this.sectorId)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.sortBy, _this.sortBy) || other.sortBy == _this.sortBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueFilter;
  return Object.hash(runtimeType,_this.sectorId,_this.state,_this.type,_this.page,_this.limit,_this.sortBy);
}

@override
String toString() {
  final _this = this as IssueFilter;
  return 'IssueFilter(sectorId: ${_this.sectorId}, state: ${_this.state}, type: ${_this.type}, page: ${_this.page}, limit: ${_this.limit}, sortBy: ${_this.sortBy})';
}


}

/// @nodoc
abstract mixin class $IssueFilterCopyWith<$Res>  {
  factory $IssueFilterCopyWith(IssueFilter value, $Res Function(IssueFilter) _then) = _$IssueFilterCopyWithImpl;
@useResult
$Res call({
 String sectorId, IssueState? state, IssueType? type, int page, int limit, IssueSortBy sortBy
});




}
/// @nodoc
class _$IssueFilterCopyWithImpl<$Res>
    implements $IssueFilterCopyWith<$Res> {
  _$IssueFilterCopyWithImpl(this._self, this._then);

  final IssueFilter _self;
  final $Res Function(IssueFilter) _then;

/// Create a copy of IssueFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sectorId = null,Object? state = freezed,Object? type = freezed,Object? page = null,Object? limit = null,Object? sortBy = null,}) {
  return _then(IssueFilter(
sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType?,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as IssueSortBy,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueFilter].
extension IssueFilterPatterns on IssueFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueFilter value)  $default,){
final _that = this;
switch (_that) {
case _IssueFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueFilter value)?  $default,){
final _that = this;
switch (_that) {
case _IssueFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sectorId,  IssueState? state,  IssueType? type,  int page,  int limit,  IssueSortBy sortBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueFilter() when $default != null:
return $default(_that.sectorId,_that.state,_that.type,_that.page,_that.limit,_that.sortBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sectorId,  IssueState? state,  IssueType? type,  int page,  int limit,  IssueSortBy sortBy)  $default,) {final _that = this;
switch (_that) {
case _IssueFilter():
return $default(_that.sectorId,_that.state,_that.type,_that.page,_that.limit,_that.sortBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sectorId,  IssueState? state,  IssueType? type,  int page,  int limit,  IssueSortBy sortBy)?  $default,) {final _that = this;
switch (_that) {
case _IssueFilter() when $default != null:
return $default(_that.sectorId,_that.state,_that.type,_that.page,_that.limit,_that.sortBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueFilter extends IssueFilter {
  const _IssueFilter({required this.sectorId, this.state, this.type, this.page = 1, this.limit = 20, this.sortBy = IssueSortBy.heat}): super._();
  factory _IssueFilter.fromJson(Map<String, dynamic> json) => _$IssueFilterFromJson(json);

@override final  String sectorId;
@override final  IssueState? state;
@override final  IssueType? type;
@override@JsonKey() final  int page;
@override@JsonKey() final  int limit;
@override@JsonKey() final  IssueSortBy sortBy;

/// Create a copy of IssueFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueFilterCopyWith<_IssueFilter> get copyWith => __$IssueFilterCopyWithImpl<_IssueFilter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueFilterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueFilter&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.state, state) || other.state == state)&&(identical(other.type, type) || other.type == type)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sectorId,state,type,page,limit,sortBy);
}

@override
String toString() {
    return 'IssueFilter(sectorId: $sectorId, state: $state, type: $type, page: $page, limit: $limit, sortBy: $sortBy)';
}


}

/// @nodoc
abstract mixin class _$IssueFilterCopyWith<$Res> implements $IssueFilterCopyWith<$Res> {
  factory _$IssueFilterCopyWith(_IssueFilter value, $Res Function(_IssueFilter) _then) = __$IssueFilterCopyWithImpl;
@override @useResult
$Res call({
 String sectorId, IssueState? state, IssueType? type, int page, int limit, IssueSortBy sortBy
});




}
/// @nodoc
class __$IssueFilterCopyWithImpl<$Res>
    implements _$IssueFilterCopyWith<$Res> {
  __$IssueFilterCopyWithImpl(this._self, this._then);

  final _IssueFilter _self;
  final $Res Function(_IssueFilter) _then;

/// Create a copy of IssueFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sectorId = null,Object? state = freezed,Object? type = freezed,Object? page = null,Object? limit = null,Object? sortBy = null,}) {
  return _then(_IssueFilter(
sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType?,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as IssueSortBy,
  ));
}


}

// dart format on
