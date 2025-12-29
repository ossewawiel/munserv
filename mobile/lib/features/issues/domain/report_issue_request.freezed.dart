// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_issue_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReportIssueRequest {

 IssueType get type; GeoPoint get location; String? get description;
/// Create a copy of ReportIssueRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportIssueRequestCopyWith<ReportIssueRequest> get copyWith => _$ReportIssueRequestCopyWithImpl<ReportIssueRequest>(this as ReportIssueRequest, _$identity);

  /// Serializes this ReportIssueRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportIssueRequest&&(identical(other.type, type) || other.type == type)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,location,description);

@override
String toString() {
  return 'ReportIssueRequest(type: $type, location: $location, description: $description)';
}


}

/// @nodoc
abstract mixin class $ReportIssueRequestCopyWith<$Res>  {
  factory $ReportIssueRequestCopyWith(ReportIssueRequest value, $Res Function(ReportIssueRequest) _then) = _$ReportIssueRequestCopyWithImpl;
@useResult
$Res call({
 IssueType type, GeoPoint location, String? description
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$ReportIssueRequestCopyWithImpl<$Res>
    implements $ReportIssueRequestCopyWith<$Res> {
  _$ReportIssueRequestCopyWithImpl(this._self, this._then);

  final ReportIssueRequest _self;
  final $Res Function(ReportIssueRequest) _then;

/// Create a copy of ReportIssueRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? location = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ReportIssueRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReportIssueRequest].
extension ReportIssueRequestPatterns on ReportIssueRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportIssueRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportIssueRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportIssueRequest value)  $default,){
final _that = this;
switch (_that) {
case _ReportIssueRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportIssueRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ReportIssueRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IssueType type,  GeoPoint location,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportIssueRequest() when $default != null:
return $default(_that.type,_that.location,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IssueType type,  GeoPoint location,  String? description)  $default,) {final _that = this;
switch (_that) {
case _ReportIssueRequest():
return $default(_that.type,_that.location,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IssueType type,  GeoPoint location,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _ReportIssueRequest() when $default != null:
return $default(_that.type,_that.location,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportIssueRequest implements ReportIssueRequest {
  const _ReportIssueRequest({required this.type, required this.location, this.description});
  factory _ReportIssueRequest.fromJson(Map<String, dynamic> json) => _$ReportIssueRequestFromJson(json);

@override final  IssueType type;
@override final  GeoPoint location;
@override final  String? description;

/// Create a copy of ReportIssueRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportIssueRequestCopyWith<_ReportIssueRequest> get copyWith => __$ReportIssueRequestCopyWithImpl<_ReportIssueRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportIssueRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportIssueRequest&&(identical(other.type, type) || other.type == type)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,location,description);

@override
String toString() {
  return 'ReportIssueRequest(type: $type, location: $location, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ReportIssueRequestCopyWith<$Res> implements $ReportIssueRequestCopyWith<$Res> {
  factory _$ReportIssueRequestCopyWith(_ReportIssueRequest value, $Res Function(_ReportIssueRequest) _then) = __$ReportIssueRequestCopyWithImpl;
@override @useResult
$Res call({
 IssueType type, GeoPoint location, String? description
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$ReportIssueRequestCopyWithImpl<$Res>
    implements _$ReportIssueRequestCopyWith<$Res> {
  __$ReportIssueRequestCopyWithImpl(this._self, this._then);

  final _ReportIssueRequest _self;
  final $Res Function(_ReportIssueRequest) _then;

/// Create a copy of ReportIssueRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? location = null,Object? description = freezed,}) {
  return _then(_ReportIssueRequest(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ReportIssueRequest
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
mixin _$ReportIssueResponse {

 String get id; IssueType get type; String get state; GeoPoint get location; int get heat; List<String> get photoUrls; DateTime get createdAt;
/// Create a copy of ReportIssueResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportIssueResponseCopyWith<ReportIssueResponse> get copyWith => _$ReportIssueResponseCopyWithImpl<ReportIssueResponse>(this as ReportIssueResponse, _$identity);

  /// Serializes this ReportIssueResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportIssueResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.state, state) || other.state == state)&&(identical(other.location, location) || other.location == location)&&(identical(other.heat, heat) || other.heat == heat)&&const DeepCollectionEquality().equals(other.photoUrls, photoUrls)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,state,location,heat,const DeepCollectionEquality().hash(photoUrls),createdAt);

@override
String toString() {
  return 'ReportIssueResponse(id: $id, type: $type, state: $state, location: $location, heat: $heat, photoUrls: $photoUrls, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ReportIssueResponseCopyWith<$Res>  {
  factory $ReportIssueResponseCopyWith(ReportIssueResponse value, $Res Function(ReportIssueResponse) _then) = _$ReportIssueResponseCopyWithImpl;
@useResult
$Res call({
 String id, IssueType type, String state, GeoPoint location, int heat, List<String> photoUrls, DateTime createdAt
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$ReportIssueResponseCopyWithImpl<$Res>
    implements $ReportIssueResponseCopyWith<$Res> {
  _$ReportIssueResponseCopyWithImpl(this._self, this._then);

  final ReportIssueResponse _self;
  final $Res Function(ReportIssueResponse) _then;

/// Create a copy of ReportIssueResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? heat = null,Object? photoUrls = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,photoUrls: null == photoUrls ? _self.photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ReportIssueResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReportIssueResponse].
extension ReportIssueResponsePatterns on ReportIssueResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportIssueResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportIssueResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportIssueResponse value)  $default,){
final _that = this;
switch (_that) {
case _ReportIssueResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportIssueResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ReportIssueResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  IssueType type,  String state,  GeoPoint location,  int heat,  List<String> photoUrls,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportIssueResponse() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.heat,_that.photoUrls,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  IssueType type,  String state,  GeoPoint location,  int heat,  List<String> photoUrls,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ReportIssueResponse():
return $default(_that.id,_that.type,_that.state,_that.location,_that.heat,_that.photoUrls,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  IssueType type,  String state,  GeoPoint location,  int heat,  List<String> photoUrls,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ReportIssueResponse() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.heat,_that.photoUrls,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportIssueResponse implements ReportIssueResponse {
  const _ReportIssueResponse({required this.id, required this.type, required this.state, required this.location, required this.heat, required final  List<String> photoUrls, required this.createdAt}): _photoUrls = photoUrls;
  factory _ReportIssueResponse.fromJson(Map<String, dynamic> json) => _$ReportIssueResponseFromJson(json);

@override final  String id;
@override final  IssueType type;
@override final  String state;
@override final  GeoPoint location;
@override final  int heat;
 final  List<String> _photoUrls;
@override List<String> get photoUrls {
  if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoUrls);
}

@override final  DateTime createdAt;

/// Create a copy of ReportIssueResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportIssueResponseCopyWith<_ReportIssueResponse> get copyWith => __$ReportIssueResponseCopyWithImpl<_ReportIssueResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportIssueResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportIssueResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.state, state) || other.state == state)&&(identical(other.location, location) || other.location == location)&&(identical(other.heat, heat) || other.heat == heat)&&const DeepCollectionEquality().equals(other._photoUrls, _photoUrls)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,state,location,heat,const DeepCollectionEquality().hash(_photoUrls),createdAt);

@override
String toString() {
  return 'ReportIssueResponse(id: $id, type: $type, state: $state, location: $location, heat: $heat, photoUrls: $photoUrls, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ReportIssueResponseCopyWith<$Res> implements $ReportIssueResponseCopyWith<$Res> {
  factory _$ReportIssueResponseCopyWith(_ReportIssueResponse value, $Res Function(_ReportIssueResponse) _then) = __$ReportIssueResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, IssueType type, String state, GeoPoint location, int heat, List<String> photoUrls, DateTime createdAt
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$ReportIssueResponseCopyWithImpl<$Res>
    implements _$ReportIssueResponseCopyWith<$Res> {
  __$ReportIssueResponseCopyWithImpl(this._self, this._then);

  final _ReportIssueResponse _self;
  final $Res Function(_ReportIssueResponse) _then;

/// Create a copy of ReportIssueResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? heat = null,Object? photoUrls = null,Object? createdAt = null,}) {
  return _then(_ReportIssueResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as IssueType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,photoUrls: null == photoUrls ? _self._photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ReportIssueResponse
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
