// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Issue {

 String get id; IssueType get type; IssueState get state; GeoPoint get location; String? get address; String? get description; int get heat; List<String> get photoUrls; String get sectorId; String get reporterId; int get reportCount; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueCopyWith<Issue> get copyWith => _$IssueCopyWithImpl<Issue>(this as Issue, _$identity);

  /// Serializes this Issue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Issue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Issue&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.heat, _this.heat) || other.heat == _this.heat)&&const DeepCollectionEquality().equals(other.photoUrls, _this.photoUrls)&&(identical(other.sectorId, _this.sectorId) || other.sectorId == _this.sectorId)&&(identical(other.reporterId, _this.reporterId) || other.reporterId == _this.reporterId)&&(identical(other.reportCount, _this.reportCount) || other.reportCount == _this.reportCount)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Issue;
  return Object.hash(runtimeType,_this.id,_this.type,_this.state,_this.location,_this.address,_this.description,_this.heat,const DeepCollectionEquality().hash(_this.photoUrls),_this.sectorId,_this.reporterId,_this.reportCount,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Issue;
  return 'Issue(id: ${_this.id}, type: ${_this.type}, state: ${_this.state}, location: ${_this.location}, address: ${_this.address}, description: ${_this.description}, heat: ${_this.heat}, photoUrls: ${_this.photoUrls}, sectorId: ${_this.sectorId}, reporterId: ${_this.reporterId}, reportCount: ${_this.reportCount}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $IssueCopyWith<$Res>  {
  factory $IssueCopyWith(Issue value, $Res Function(Issue) _then) = _$IssueCopyWithImpl;
@useResult
$Res call({
 String id, IssueType type, IssueState state, GeoPoint location, String? address, String? description, int heat, List<String> photoUrls, String sectorId, String reporterId, int reportCount, DateTime createdAt, DateTime updatedAt
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$IssueCopyWithImpl<$Res>
    implements $IssueCopyWith<$Res> {
  _$IssueCopyWithImpl(this._self, this._then);

  final Issue _self;
  final $Res Function(Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? address = freezed,Object? description = freezed,Object? heat = null,Object? photoUrls = null,Object? sectorId = null,Object? reporterId = null,Object? reportCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Issue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,photoUrls: null == photoUrls ? _self.photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [Issue].
extension IssuePatterns on Issue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Issue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Issue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Issue value)  $default,){
final _that = this;
switch (_that) {
case _Issue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Issue value)?  $default,){
final _that = this;
switch (_that) {
case _Issue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  IssueType type,  IssueState state,  GeoPoint location,  String? address,  String? description,  int heat,  List<String> photoUrls,  String sectorId,  String reporterId,  int reportCount,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.address,_that.description,_that.heat,_that.photoUrls,_that.sectorId,_that.reporterId,_that.reportCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  IssueType type,  IssueState state,  GeoPoint location,  String? address,  String? description,  int heat,  List<String> photoUrls,  String sectorId,  String reporterId,  int reportCount,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Issue():
return $default(_that.id,_that.type,_that.state,_that.location,_that.address,_that.description,_that.heat,_that.photoUrls,_that.sectorId,_that.reporterId,_that.reportCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  IssueType type,  IssueState state,  GeoPoint location,  String? address,  String? description,  int heat,  List<String> photoUrls,  String sectorId,  String reporterId,  int reportCount,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.address,_that.description,_that.heat,_that.photoUrls,_that.sectorId,_that.reporterId,_that.reportCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Issue extends Issue {
  const _Issue({required this.id, required this.type, required this.state, required this.location, this.address, this.description, required this.heat, required  List<String> photoUrls, required this.sectorId, required this.reporterId, required this.reportCount, required this.createdAt, required this.updatedAt}): _photoUrls = photoUrls,super._();
  factory _Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

@override final  String id;
@override final  IssueType type;
@override final  IssueState state;
@override final  GeoPoint location;
@override final  String? address;
@override final  String? description;
@override final  int heat;
 final  List<String> _photoUrls;
@override List<String> get photoUrls {
  if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoUrls);
}

@override final  String sectorId;
@override final  String reporterId;
@override final  int reportCount;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueCopyWith<_Issue> get copyWith => __$IssueCopyWithImpl<_Issue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Issue&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.state, state) || other.state == state)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.heat, heat) || other.heat == heat)&&const DeepCollectionEquality().equals(other.photoUrls, _photoUrls)&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,state,location,address,description,heat,const DeepCollectionEquality().hash(_photoUrls),sectorId,reporterId,reportCount,createdAt,updatedAt);
}

@override
String toString() {
    return 'Issue(id: $id, type: $type, state: $state, location: $location, address: $address, description: $description, heat: $heat, photoUrls: $photoUrls, sectorId: $sectorId, reporterId: $reporterId, reportCount: $reportCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$IssueCopyWith<$Res> implements $IssueCopyWith<$Res> {
  factory _$IssueCopyWith(_Issue value, $Res Function(_Issue) _then) = __$IssueCopyWithImpl;
@override @useResult
$Res call({
 String id, IssueType type, IssueState state, GeoPoint location, String? address, String? description, int heat, List<String> photoUrls, String sectorId, String reporterId, int reportCount, DateTime createdAt, DateTime updatedAt
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$IssueCopyWithImpl<$Res>
    implements _$IssueCopyWith<$Res> {
  __$IssueCopyWithImpl(this._self, this._then);

  final _Issue _self;
  final $Res Function(_Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? address = freezed,Object? description = freezed,Object? heat = null,Object? photoUrls = null,Object? sectorId = null,Object? reporterId = null,Object? reportCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Issue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,photoUrls: null == photoUrls ? _self._photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$IssueSummary {

 String get id; IssueType get type; IssueState get state; GeoPoint get location; int get heat; String? get thumbnailUrl; DateTime get createdAt;
/// Create a copy of IssueSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueSummaryCopyWith<IssueSummary> get copyWith => _$IssueSummaryCopyWithImpl<IssueSummary>(this as IssueSummary, _$identity);

  /// Serializes this IssueSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.heat, _this.heat) || other.heat == _this.heat)&&(identical(other.thumbnailUrl, _this.thumbnailUrl) || other.thumbnailUrl == _this.thumbnailUrl)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueSummary;
  return Object.hash(runtimeType,_this.id,_this.type,_this.state,_this.location,_this.heat,_this.thumbnailUrl,_this.createdAt);
}

@override
String toString() {
  final _this = this as IssueSummary;
  return 'IssueSummary(id: ${_this.id}, type: ${_this.type}, state: ${_this.state}, location: ${_this.location}, heat: ${_this.heat}, thumbnailUrl: ${_this.thumbnailUrl}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $IssueSummaryCopyWith<$Res>  {
  factory $IssueSummaryCopyWith(IssueSummary value, $Res Function(IssueSummary) _then) = _$IssueSummaryCopyWithImpl;
@useResult
$Res call({
 String id, IssueType type, IssueState state, GeoPoint location, int heat, String? thumbnailUrl, DateTime createdAt
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$IssueSummaryCopyWithImpl<$Res>
    implements $IssueSummaryCopyWith<$Res> {
  _$IssueSummaryCopyWithImpl(this._self, this._then);

  final IssueSummary _self;
  final $Res Function(IssueSummary) _then;

/// Create a copy of IssueSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? heat = null,Object? thumbnailUrl = freezed,Object? createdAt = null,}) {
  return _then(IssueSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of IssueSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssueSummary].
extension IssueSummaryPatterns on IssueSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueSummary value)  $default,){
final _that = this;
switch (_that) {
case _IssueSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueSummary value)?  $default,){
final _that = this;
switch (_that) {
case _IssueSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  IssueType type,  IssueState state,  GeoPoint location,  int heat,  String? thumbnailUrl,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueSummary() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.heat,_that.thumbnailUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  IssueType type,  IssueState state,  GeoPoint location,  int heat,  String? thumbnailUrl,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _IssueSummary():
return $default(_that.id,_that.type,_that.state,_that.location,_that.heat,_that.thumbnailUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  IssueType type,  IssueState state,  GeoPoint location,  int heat,  String? thumbnailUrl,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _IssueSummary() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.heat,_that.thumbnailUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueSummary implements IssueSummary {
  const _IssueSummary({required this.id, required this.type, required this.state, required this.location, required this.heat, this.thumbnailUrl, required this.createdAt});
  factory _IssueSummary.fromJson(Map<String, dynamic> json) => _$IssueSummaryFromJson(json);

@override final  String id;
@override final  IssueType type;
@override final  IssueState state;
@override final  GeoPoint location;
@override final  int heat;
@override final  String? thumbnailUrl;
@override final  DateTime createdAt;

/// Create a copy of IssueSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueSummaryCopyWith<_IssueSummary> get copyWith => __$IssueSummaryCopyWithImpl<_IssueSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.state, state) || other.state == state)&&(identical(other.location, location) || other.location == location)&&(identical(other.heat, heat) || other.heat == heat)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,state,location,heat,thumbnailUrl,createdAt);
}

@override
String toString() {
    return 'IssueSummary(id: $id, type: $type, state: $state, location: $location, heat: $heat, thumbnailUrl: $thumbnailUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$IssueSummaryCopyWith<$Res> implements $IssueSummaryCopyWith<$Res> {
  factory _$IssueSummaryCopyWith(_IssueSummary value, $Res Function(_IssueSummary) _then) = __$IssueSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, IssueType type, IssueState state, GeoPoint location, int heat, String? thumbnailUrl, DateTime createdAt
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$IssueSummaryCopyWithImpl<$Res>
    implements _$IssueSummaryCopyWith<$Res> {
  __$IssueSummaryCopyWithImpl(this._self, this._then);

  final _IssueSummary _self;
  final $Res Function(_IssueSummary) _then;

/// Create a copy of IssueSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? heat = null,Object? thumbnailUrl = freezed,Object? createdAt = null,}) {
  return _then(_IssueSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of IssueSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

// dart format on
