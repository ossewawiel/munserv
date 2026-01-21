// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ground_admin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroundAdminInfo {

 GroundAdminStatus get status; DateTime get since; double get responseRate; int get pendingVerifications; int get totalVerifications;
/// Create a copy of GroundAdminInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroundAdminInfoCopyWith<GroundAdminInfo> get copyWith => _$GroundAdminInfoCopyWithImpl<GroundAdminInfo>(this as GroundAdminInfo, _$identity);

  /// Serializes this GroundAdminInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroundAdminInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.since, since) || other.since == since)&&(identical(other.responseRate, responseRate) || other.responseRate == responseRate)&&(identical(other.pendingVerifications, pendingVerifications) || other.pendingVerifications == pendingVerifications)&&(identical(other.totalVerifications, totalVerifications) || other.totalVerifications == totalVerifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,since,responseRate,pendingVerifications,totalVerifications);

@override
String toString() {
  return 'GroundAdminInfo(status: $status, since: $since, responseRate: $responseRate, pendingVerifications: $pendingVerifications, totalVerifications: $totalVerifications)';
}


}

/// @nodoc
abstract mixin class $GroundAdminInfoCopyWith<$Res>  {
  factory $GroundAdminInfoCopyWith(GroundAdminInfo value, $Res Function(GroundAdminInfo) _then) = _$GroundAdminInfoCopyWithImpl;
@useResult
$Res call({
 GroundAdminStatus status, DateTime since, double responseRate, int pendingVerifications, int totalVerifications
});




}
/// @nodoc
class _$GroundAdminInfoCopyWithImpl<$Res>
    implements $GroundAdminInfoCopyWith<$Res> {
  _$GroundAdminInfoCopyWithImpl(this._self, this._then);

  final GroundAdminInfo _self;
  final $Res Function(GroundAdminInfo) _then;

/// Create a copy of GroundAdminInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? since = null,Object? responseRate = null,Object? pendingVerifications = null,Object? totalVerifications = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroundAdminStatus,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime,responseRate: null == responseRate ? _self.responseRate : responseRate // ignore: cast_nullable_to_non_nullable
as double,pendingVerifications: null == pendingVerifications ? _self.pendingVerifications : pendingVerifications // ignore: cast_nullable_to_non_nullable
as int,totalVerifications: null == totalVerifications ? _self.totalVerifications : totalVerifications // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GroundAdminInfo].
extension GroundAdminInfoPatterns on GroundAdminInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroundAdminInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroundAdminInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroundAdminInfo value)  $default,){
final _that = this;
switch (_that) {
case _GroundAdminInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroundAdminInfo value)?  $default,){
final _that = this;
switch (_that) {
case _GroundAdminInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroundAdminStatus status,  DateTime since,  double responseRate,  int pendingVerifications,  int totalVerifications)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroundAdminInfo() when $default != null:
return $default(_that.status,_that.since,_that.responseRate,_that.pendingVerifications,_that.totalVerifications);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroundAdminStatus status,  DateTime since,  double responseRate,  int pendingVerifications,  int totalVerifications)  $default,) {final _that = this;
switch (_that) {
case _GroundAdminInfo():
return $default(_that.status,_that.since,_that.responseRate,_that.pendingVerifications,_that.totalVerifications);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroundAdminStatus status,  DateTime since,  double responseRate,  int pendingVerifications,  int totalVerifications)?  $default,) {final _that = this;
switch (_that) {
case _GroundAdminInfo() when $default != null:
return $default(_that.status,_that.since,_that.responseRate,_that.pendingVerifications,_that.totalVerifications);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroundAdminInfo extends GroundAdminInfo {
  const _GroundAdminInfo({required this.status, required this.since, required this.responseRate, required this.pendingVerifications, required this.totalVerifications}): super._();
  factory _GroundAdminInfo.fromJson(Map<String, dynamic> json) => _$GroundAdminInfoFromJson(json);

@override final  GroundAdminStatus status;
@override final  DateTime since;
@override final  double responseRate;
@override final  int pendingVerifications;
@override final  int totalVerifications;

/// Create a copy of GroundAdminInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroundAdminInfoCopyWith<_GroundAdminInfo> get copyWith => __$GroundAdminInfoCopyWithImpl<_GroundAdminInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroundAdminInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroundAdminInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.since, since) || other.since == since)&&(identical(other.responseRate, responseRate) || other.responseRate == responseRate)&&(identical(other.pendingVerifications, pendingVerifications) || other.pendingVerifications == pendingVerifications)&&(identical(other.totalVerifications, totalVerifications) || other.totalVerifications == totalVerifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,since,responseRate,pendingVerifications,totalVerifications);

@override
String toString() {
  return 'GroundAdminInfo(status: $status, since: $since, responseRate: $responseRate, pendingVerifications: $pendingVerifications, totalVerifications: $totalVerifications)';
}


}

/// @nodoc
abstract mixin class _$GroundAdminInfoCopyWith<$Res> implements $GroundAdminInfoCopyWith<$Res> {
  factory _$GroundAdminInfoCopyWith(_GroundAdminInfo value, $Res Function(_GroundAdminInfo) _then) = __$GroundAdminInfoCopyWithImpl;
@override @useResult
$Res call({
 GroundAdminStatus status, DateTime since, double responseRate, int pendingVerifications, int totalVerifications
});




}
/// @nodoc
class __$GroundAdminInfoCopyWithImpl<$Res>
    implements _$GroundAdminInfoCopyWith<$Res> {
  __$GroundAdminInfoCopyWithImpl(this._self, this._then);

  final _GroundAdminInfo _self;
  final $Res Function(_GroundAdminInfo) _then;

/// Create a copy of GroundAdminInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? since = null,Object? responseRate = null,Object? pendingVerifications = null,Object? totalVerifications = null,}) {
  return _then(_GroundAdminInfo(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroundAdminStatus,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime,responseRate: null == responseRate ? _self.responseRate : responseRate // ignore: cast_nullable_to_non_nullable
as double,pendingVerifications: null == pendingVerifications ? _self.pendingVerifications : pendingVerifications // ignore: cast_nullable_to_non_nullable
as int,totalVerifications: null == totalVerifications ? _self.totalVerifications : totalVerifications // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GroundAdminApplication {

 String get id; String get status;
/// Create a copy of GroundAdminApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroundAdminApplicationCopyWith<GroundAdminApplication> get copyWith => _$GroundAdminApplicationCopyWithImpl<GroundAdminApplication>(this as GroundAdminApplication, _$identity);

  /// Serializes this GroundAdminApplication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroundAdminApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status);

@override
String toString() {
  return 'GroundAdminApplication(id: $id, status: $status)';
}


}

/// @nodoc
abstract mixin class $GroundAdminApplicationCopyWith<$Res>  {
  factory $GroundAdminApplicationCopyWith(GroundAdminApplication value, $Res Function(GroundAdminApplication) _then) = _$GroundAdminApplicationCopyWithImpl;
@useResult
$Res call({
 String id, String status
});




}
/// @nodoc
class _$GroundAdminApplicationCopyWithImpl<$Res>
    implements $GroundAdminApplicationCopyWith<$Res> {
  _$GroundAdminApplicationCopyWithImpl(this._self, this._then);

  final GroundAdminApplication _self;
  final $Res Function(GroundAdminApplication) _then;

/// Create a copy of GroundAdminApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroundAdminApplication].
extension GroundAdminApplicationPatterns on GroundAdminApplication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroundAdminApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroundAdminApplication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroundAdminApplication value)  $default,){
final _that = this;
switch (_that) {
case _GroundAdminApplication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroundAdminApplication value)?  $default,){
final _that = this;
switch (_that) {
case _GroundAdminApplication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroundAdminApplication() when $default != null:
return $default(_that.id,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status)  $default,) {final _that = this;
switch (_that) {
case _GroundAdminApplication():
return $default(_that.id,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status)?  $default,) {final _that = this;
switch (_that) {
case _GroundAdminApplication() when $default != null:
return $default(_that.id,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroundAdminApplication implements GroundAdminApplication {
  const _GroundAdminApplication({required this.id, required this.status});
  factory _GroundAdminApplication.fromJson(Map<String, dynamic> json) => _$GroundAdminApplicationFromJson(json);

@override final  String id;
@override final  String status;

/// Create a copy of GroundAdminApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroundAdminApplicationCopyWith<_GroundAdminApplication> get copyWith => __$GroundAdminApplicationCopyWithImpl<_GroundAdminApplication>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroundAdminApplicationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroundAdminApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status);

@override
String toString() {
  return 'GroundAdminApplication(id: $id, status: $status)';
}


}

/// @nodoc
abstract mixin class _$GroundAdminApplicationCopyWith<$Res> implements $GroundAdminApplicationCopyWith<$Res> {
  factory _$GroundAdminApplicationCopyWith(_GroundAdminApplication value, $Res Function(_GroundAdminApplication) _then) = __$GroundAdminApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String status
});




}
/// @nodoc
class __$GroundAdminApplicationCopyWithImpl<$Res>
    implements _$GroundAdminApplicationCopyWith<$Res> {
  __$GroundAdminApplicationCopyWithImpl(this._self, this._then);

  final _GroundAdminApplication _self;
  final $Res Function(_GroundAdminApplication) _then;

/// Create a copy of GroundAdminApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,}) {
  return _then(_GroundAdminApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GroundAdminActionResponse {

 String get status; Map<String, dynamic>? get member;
/// Create a copy of GroundAdminActionResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroundAdminActionResponseCopyWith<GroundAdminActionResponse> get copyWith => _$GroundAdminActionResponseCopyWithImpl<GroundAdminActionResponse>(this as GroundAdminActionResponse, _$identity);

  /// Serializes this GroundAdminActionResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroundAdminActionResponse&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.member, member));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(member));

@override
String toString() {
  return 'GroundAdminActionResponse(status: $status, member: $member)';
}


}

/// @nodoc
abstract mixin class $GroundAdminActionResponseCopyWith<$Res>  {
  factory $GroundAdminActionResponseCopyWith(GroundAdminActionResponse value, $Res Function(GroundAdminActionResponse) _then) = _$GroundAdminActionResponseCopyWithImpl;
@useResult
$Res call({
 String status, Map<String, dynamic>? member
});




}
/// @nodoc
class _$GroundAdminActionResponseCopyWithImpl<$Res>
    implements $GroundAdminActionResponseCopyWith<$Res> {
  _$GroundAdminActionResponseCopyWithImpl(this._self, this._then);

  final GroundAdminActionResponse _self;
  final $Res Function(GroundAdminActionResponse) _then;

/// Create a copy of GroundAdminActionResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? member = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,member: freezed == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroundAdminActionResponse].
extension GroundAdminActionResponsePatterns on GroundAdminActionResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroundAdminActionResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroundAdminActionResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroundAdminActionResponse value)  $default,){
final _that = this;
switch (_that) {
case _GroundAdminActionResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroundAdminActionResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GroundAdminActionResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  Map<String, dynamic>? member)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroundAdminActionResponse() when $default != null:
return $default(_that.status,_that.member);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  Map<String, dynamic>? member)  $default,) {final _that = this;
switch (_that) {
case _GroundAdminActionResponse():
return $default(_that.status,_that.member);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  Map<String, dynamic>? member)?  $default,) {final _that = this;
switch (_that) {
case _GroundAdminActionResponse() when $default != null:
return $default(_that.status,_that.member);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroundAdminActionResponse implements GroundAdminActionResponse {
  const _GroundAdminActionResponse({required this.status, final  Map<String, dynamic>? member}): _member = member;
  factory _GroundAdminActionResponse.fromJson(Map<String, dynamic> json) => _$GroundAdminActionResponseFromJson(json);

@override final  String status;
 final  Map<String, dynamic>? _member;
@override Map<String, dynamic>? get member {
  final value = _member;
  if (value == null) return null;
  if (_member is EqualUnmodifiableMapView) return _member;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of GroundAdminActionResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroundAdminActionResponseCopyWith<_GroundAdminActionResponse> get copyWith => __$GroundAdminActionResponseCopyWithImpl<_GroundAdminActionResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroundAdminActionResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroundAdminActionResponse&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._member, _member));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_member));

@override
String toString() {
  return 'GroundAdminActionResponse(status: $status, member: $member)';
}


}

/// @nodoc
abstract mixin class _$GroundAdminActionResponseCopyWith<$Res> implements $GroundAdminActionResponseCopyWith<$Res> {
  factory _$GroundAdminActionResponseCopyWith(_GroundAdminActionResponse value, $Res Function(_GroundAdminActionResponse) _then) = __$GroundAdminActionResponseCopyWithImpl;
@override @useResult
$Res call({
 String status, Map<String, dynamic>? member
});




}
/// @nodoc
class __$GroundAdminActionResponseCopyWithImpl<$Res>
    implements _$GroundAdminActionResponseCopyWith<$Res> {
  __$GroundAdminActionResponseCopyWithImpl(this._self, this._then);

  final _GroundAdminActionResponse _self;
  final $Res Function(_GroundAdminActionResponse) _then;

/// Create a copy of GroundAdminActionResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? member = freezed,}) {
  return _then(_GroundAdminActionResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,member: freezed == member ? _self._member : member // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
