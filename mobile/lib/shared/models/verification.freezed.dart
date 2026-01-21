// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingVerification {

 String get verificationId; String get issueId; String get issueType; String get verificationType; GeoPoint get location; DateTime get requestedAt; double? get distance;
/// Create a copy of PendingVerification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingVerificationCopyWith<PendingVerification> get copyWith => _$PendingVerificationCopyWithImpl<PendingVerification>(this as PendingVerification, _$identity);

  /// Serializes this PendingVerification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingVerification&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.issueType, issueType) || other.issueType == issueType)&&(identical(other.verificationType, verificationType) || other.verificationType == verificationType)&&(identical(other.location, location) || other.location == location)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.distance, distance) || other.distance == distance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationId,issueId,issueType,verificationType,location,requestedAt,distance);

@override
String toString() {
  return 'PendingVerification(verificationId: $verificationId, issueId: $issueId, issueType: $issueType, verificationType: $verificationType, location: $location, requestedAt: $requestedAt, distance: $distance)';
}


}

/// @nodoc
abstract mixin class $PendingVerificationCopyWith<$Res>  {
  factory $PendingVerificationCopyWith(PendingVerification value, $Res Function(PendingVerification) _then) = _$PendingVerificationCopyWithImpl;
@useResult
$Res call({
 String verificationId, String issueId, String issueType, String verificationType, GeoPoint location, DateTime requestedAt, double? distance
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$PendingVerificationCopyWithImpl<$Res>
    implements $PendingVerificationCopyWith<$Res> {
  _$PendingVerificationCopyWithImpl(this._self, this._then);

  final PendingVerification _self;
  final $Res Function(PendingVerification) _then;

/// Create a copy of PendingVerification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verificationId = null,Object? issueId = null,Object? issueType = null,Object? verificationType = null,Object? location = null,Object? requestedAt = null,Object? distance = freezed,}) {
  return _then(_self.copyWith(
verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as String,issueType: null == issueType ? _self.issueType : issueType // ignore: cast_nullable_to_non_nullable
as String,verificationType: null == verificationType ? _self.verificationType : verificationType // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of PendingVerification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [PendingVerification].
extension PendingVerificationPatterns on PendingVerification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingVerification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingVerification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingVerification value)  $default,){
final _that = this;
switch (_that) {
case _PendingVerification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingVerification value)?  $default,){
final _that = this;
switch (_that) {
case _PendingVerification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String verificationId,  String issueId,  String issueType,  String verificationType,  GeoPoint location,  DateTime requestedAt,  double? distance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingVerification() when $default != null:
return $default(_that.verificationId,_that.issueId,_that.issueType,_that.verificationType,_that.location,_that.requestedAt,_that.distance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String verificationId,  String issueId,  String issueType,  String verificationType,  GeoPoint location,  DateTime requestedAt,  double? distance)  $default,) {final _that = this;
switch (_that) {
case _PendingVerification():
return $default(_that.verificationId,_that.issueId,_that.issueType,_that.verificationType,_that.location,_that.requestedAt,_that.distance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String verificationId,  String issueId,  String issueType,  String verificationType,  GeoPoint location,  DateTime requestedAt,  double? distance)?  $default,) {final _that = this;
switch (_that) {
case _PendingVerification() when $default != null:
return $default(_that.verificationId,_that.issueId,_that.issueType,_that.verificationType,_that.location,_that.requestedAt,_that.distance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingVerification extends PendingVerification {
  const _PendingVerification({required this.verificationId, required this.issueId, required this.issueType, required this.verificationType, required this.location, required this.requestedAt, this.distance}): super._();
  factory _PendingVerification.fromJson(Map<String, dynamic> json) => _$PendingVerificationFromJson(json);

@override final  String verificationId;
@override final  String issueId;
@override final  String issueType;
@override final  String verificationType;
@override final  GeoPoint location;
@override final  DateTime requestedAt;
@override final  double? distance;

/// Create a copy of PendingVerification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingVerificationCopyWith<_PendingVerification> get copyWith => __$PendingVerificationCopyWithImpl<_PendingVerification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingVerificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingVerification&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.issueType, issueType) || other.issueType == issueType)&&(identical(other.verificationType, verificationType) || other.verificationType == verificationType)&&(identical(other.location, location) || other.location == location)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.distance, distance) || other.distance == distance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationId,issueId,issueType,verificationType,location,requestedAt,distance);

@override
String toString() {
  return 'PendingVerification(verificationId: $verificationId, issueId: $issueId, issueType: $issueType, verificationType: $verificationType, location: $location, requestedAt: $requestedAt, distance: $distance)';
}


}

/// @nodoc
abstract mixin class _$PendingVerificationCopyWith<$Res> implements $PendingVerificationCopyWith<$Res> {
  factory _$PendingVerificationCopyWith(_PendingVerification value, $Res Function(_PendingVerification) _then) = __$PendingVerificationCopyWithImpl;
@override @useResult
$Res call({
 String verificationId, String issueId, String issueType, String verificationType, GeoPoint location, DateTime requestedAt, double? distance
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$PendingVerificationCopyWithImpl<$Res>
    implements _$PendingVerificationCopyWith<$Res> {
  __$PendingVerificationCopyWithImpl(this._self, this._then);

  final _PendingVerification _self;
  final $Res Function(_PendingVerification) _then;

/// Create a copy of PendingVerification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verificationId = null,Object? issueId = null,Object? issueType = null,Object? verificationType = null,Object? location = null,Object? requestedAt = null,Object? distance = freezed,}) {
  return _then(_PendingVerification(
verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as String,issueType: null == issueType ? _self.issueType : issueType // ignore: cast_nullable_to_non_nullable
as String,verificationType: null == verificationType ? _self.verificationType : verificationType // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of PendingVerification
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
mixin _$VerificationSubmitRequest {

 String get verificationId; String get result; String? get reason; String? get note; String? get photoId;
/// Create a copy of VerificationSubmitRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationSubmitRequestCopyWith<VerificationSubmitRequest> get copyWith => _$VerificationSubmitRequestCopyWithImpl<VerificationSubmitRequest>(this as VerificationSubmitRequest, _$identity);

  /// Serializes this VerificationSubmitRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationSubmitRequest&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.result, result) || other.result == result)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.note, note) || other.note == note)&&(identical(other.photoId, photoId) || other.photoId == photoId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationId,result,reason,note,photoId);

@override
String toString() {
  return 'VerificationSubmitRequest(verificationId: $verificationId, result: $result, reason: $reason, note: $note, photoId: $photoId)';
}


}

/// @nodoc
abstract mixin class $VerificationSubmitRequestCopyWith<$Res>  {
  factory $VerificationSubmitRequestCopyWith(VerificationSubmitRequest value, $Res Function(VerificationSubmitRequest) _then) = _$VerificationSubmitRequestCopyWithImpl;
@useResult
$Res call({
 String verificationId, String result, String? reason, String? note, String? photoId
});




}
/// @nodoc
class _$VerificationSubmitRequestCopyWithImpl<$Res>
    implements $VerificationSubmitRequestCopyWith<$Res> {
  _$VerificationSubmitRequestCopyWithImpl(this._self, this._then);

  final VerificationSubmitRequest _self;
  final $Res Function(VerificationSubmitRequest) _then;

/// Create a copy of VerificationSubmitRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verificationId = null,Object? result = null,Object? reason = freezed,Object? note = freezed,Object? photoId = freezed,}) {
  return _then(_self.copyWith(
verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationSubmitRequest].
extension VerificationSubmitRequestPatterns on VerificationSubmitRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationSubmitRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationSubmitRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationSubmitRequest value)  $default,){
final _that = this;
switch (_that) {
case _VerificationSubmitRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationSubmitRequest value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationSubmitRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String verificationId,  String result,  String? reason,  String? note,  String? photoId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationSubmitRequest() when $default != null:
return $default(_that.verificationId,_that.result,_that.reason,_that.note,_that.photoId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String verificationId,  String result,  String? reason,  String? note,  String? photoId)  $default,) {final _that = this;
switch (_that) {
case _VerificationSubmitRequest():
return $default(_that.verificationId,_that.result,_that.reason,_that.note,_that.photoId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String verificationId,  String result,  String? reason,  String? note,  String? photoId)?  $default,) {final _that = this;
switch (_that) {
case _VerificationSubmitRequest() when $default != null:
return $default(_that.verificationId,_that.result,_that.reason,_that.note,_that.photoId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationSubmitRequest implements VerificationSubmitRequest {
  const _VerificationSubmitRequest({required this.verificationId, required this.result, this.reason, this.note, this.photoId});
  factory _VerificationSubmitRequest.fromJson(Map<String, dynamic> json) => _$VerificationSubmitRequestFromJson(json);

@override final  String verificationId;
@override final  String result;
@override final  String? reason;
@override final  String? note;
@override final  String? photoId;

/// Create a copy of VerificationSubmitRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationSubmitRequestCopyWith<_VerificationSubmitRequest> get copyWith => __$VerificationSubmitRequestCopyWithImpl<_VerificationSubmitRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationSubmitRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationSubmitRequest&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.result, result) || other.result == result)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.note, note) || other.note == note)&&(identical(other.photoId, photoId) || other.photoId == photoId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationId,result,reason,note,photoId);

@override
String toString() {
  return 'VerificationSubmitRequest(verificationId: $verificationId, result: $result, reason: $reason, note: $note, photoId: $photoId)';
}


}

/// @nodoc
abstract mixin class _$VerificationSubmitRequestCopyWith<$Res> implements $VerificationSubmitRequestCopyWith<$Res> {
  factory _$VerificationSubmitRequestCopyWith(_VerificationSubmitRequest value, $Res Function(_VerificationSubmitRequest) _then) = __$VerificationSubmitRequestCopyWithImpl;
@override @useResult
$Res call({
 String verificationId, String result, String? reason, String? note, String? photoId
});




}
/// @nodoc
class __$VerificationSubmitRequestCopyWithImpl<$Res>
    implements _$VerificationSubmitRequestCopyWith<$Res> {
  __$VerificationSubmitRequestCopyWithImpl(this._self, this._then);

  final _VerificationSubmitRequest _self;
  final $Res Function(_VerificationSubmitRequest) _then;

/// Create a copy of VerificationSubmitRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verificationId = null,Object? result = null,Object? reason = freezed,Object? note = freezed,Object? photoId = freezed,}) {
  return _then(_VerificationSubmitRequest(
verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$IssueVerification {

 String get id; String get issueId; String get verificationType; String? get assignedTo; String? get verifiedBy; String? get result; String? get reason; String? get note; String? get photoId; DateTime get requestedAt; DateTime? get respondedAt; String get status;
/// Create a copy of IssueVerification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueVerificationCopyWith<IssueVerification> get copyWith => _$IssueVerificationCopyWithImpl<IssueVerification>(this as IssueVerification, _$identity);

  /// Serializes this IssueVerification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueVerification&&(identical(other.id, id) || other.id == id)&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.verificationType, verificationType) || other.verificationType == verificationType)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.verifiedBy, verifiedBy) || other.verifiedBy == verifiedBy)&&(identical(other.result, result) || other.result == result)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.note, note) || other.note == note)&&(identical(other.photoId, photoId) || other.photoId == photoId)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,issueId,verificationType,assignedTo,verifiedBy,result,reason,note,photoId,requestedAt,respondedAt,status);

@override
String toString() {
  return 'IssueVerification(id: $id, issueId: $issueId, verificationType: $verificationType, assignedTo: $assignedTo, verifiedBy: $verifiedBy, result: $result, reason: $reason, note: $note, photoId: $photoId, requestedAt: $requestedAt, respondedAt: $respondedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $IssueVerificationCopyWith<$Res>  {
  factory $IssueVerificationCopyWith(IssueVerification value, $Res Function(IssueVerification) _then) = _$IssueVerificationCopyWithImpl;
@useResult
$Res call({
 String id, String issueId, String verificationType, String? assignedTo, String? verifiedBy, String? result, String? reason, String? note, String? photoId, DateTime requestedAt, DateTime? respondedAt, String status
});




}
/// @nodoc
class _$IssueVerificationCopyWithImpl<$Res>
    implements $IssueVerificationCopyWith<$Res> {
  _$IssueVerificationCopyWithImpl(this._self, this._then);

  final IssueVerification _self;
  final $Res Function(IssueVerification) _then;

/// Create a copy of IssueVerification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? issueId = null,Object? verificationType = null,Object? assignedTo = freezed,Object? verifiedBy = freezed,Object? result = freezed,Object? reason = freezed,Object? note = freezed,Object? photoId = freezed,Object? requestedAt = null,Object? respondedAt = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as String,verificationType: null == verificationType ? _self.verificationType : verificationType // ignore: cast_nullable_to_non_nullable
as String,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,verifiedBy: freezed == verifiedBy ? _self.verifiedBy : verifiedBy // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueVerification].
extension IssueVerificationPatterns on IssueVerification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueVerification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueVerification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueVerification value)  $default,){
final _that = this;
switch (_that) {
case _IssueVerification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueVerification value)?  $default,){
final _that = this;
switch (_that) {
case _IssueVerification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String issueId,  String verificationType,  String? assignedTo,  String? verifiedBy,  String? result,  String? reason,  String? note,  String? photoId,  DateTime requestedAt,  DateTime? respondedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueVerification() when $default != null:
return $default(_that.id,_that.issueId,_that.verificationType,_that.assignedTo,_that.verifiedBy,_that.result,_that.reason,_that.note,_that.photoId,_that.requestedAt,_that.respondedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String issueId,  String verificationType,  String? assignedTo,  String? verifiedBy,  String? result,  String? reason,  String? note,  String? photoId,  DateTime requestedAt,  DateTime? respondedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _IssueVerification():
return $default(_that.id,_that.issueId,_that.verificationType,_that.assignedTo,_that.verifiedBy,_that.result,_that.reason,_that.note,_that.photoId,_that.requestedAt,_that.respondedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String issueId,  String verificationType,  String? assignedTo,  String? verifiedBy,  String? result,  String? reason,  String? note,  String? photoId,  DateTime requestedAt,  DateTime? respondedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _IssueVerification() when $default != null:
return $default(_that.id,_that.issueId,_that.verificationType,_that.assignedTo,_that.verifiedBy,_that.result,_that.reason,_that.note,_that.photoId,_that.requestedAt,_that.respondedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueVerification implements IssueVerification {
  const _IssueVerification({required this.id, required this.issueId, required this.verificationType, this.assignedTo, this.verifiedBy, this.result, this.reason, this.note, this.photoId, required this.requestedAt, this.respondedAt, required this.status});
  factory _IssueVerification.fromJson(Map<String, dynamic> json) => _$IssueVerificationFromJson(json);

@override final  String id;
@override final  String issueId;
@override final  String verificationType;
@override final  String? assignedTo;
@override final  String? verifiedBy;
@override final  String? result;
@override final  String? reason;
@override final  String? note;
@override final  String? photoId;
@override final  DateTime requestedAt;
@override final  DateTime? respondedAt;
@override final  String status;

/// Create a copy of IssueVerification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueVerificationCopyWith<_IssueVerification> get copyWith => __$IssueVerificationCopyWithImpl<_IssueVerification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueVerificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueVerification&&(identical(other.id, id) || other.id == id)&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.verificationType, verificationType) || other.verificationType == verificationType)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.verifiedBy, verifiedBy) || other.verifiedBy == verifiedBy)&&(identical(other.result, result) || other.result == result)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.note, note) || other.note == note)&&(identical(other.photoId, photoId) || other.photoId == photoId)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,issueId,verificationType,assignedTo,verifiedBy,result,reason,note,photoId,requestedAt,respondedAt,status);

@override
String toString() {
  return 'IssueVerification(id: $id, issueId: $issueId, verificationType: $verificationType, assignedTo: $assignedTo, verifiedBy: $verifiedBy, result: $result, reason: $reason, note: $note, photoId: $photoId, requestedAt: $requestedAt, respondedAt: $respondedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$IssueVerificationCopyWith<$Res> implements $IssueVerificationCopyWith<$Res> {
  factory _$IssueVerificationCopyWith(_IssueVerification value, $Res Function(_IssueVerification) _then) = __$IssueVerificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String issueId, String verificationType, String? assignedTo, String? verifiedBy, String? result, String? reason, String? note, String? photoId, DateTime requestedAt, DateTime? respondedAt, String status
});




}
/// @nodoc
class __$IssueVerificationCopyWithImpl<$Res>
    implements _$IssueVerificationCopyWith<$Res> {
  __$IssueVerificationCopyWithImpl(this._self, this._then);

  final _IssueVerification _self;
  final $Res Function(_IssueVerification) _then;

/// Create a copy of IssueVerification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? issueId = null,Object? verificationType = null,Object? assignedTo = freezed,Object? verifiedBy = freezed,Object? result = freezed,Object? reason = freezed,Object? note = freezed,Object? photoId = freezed,Object? requestedAt = null,Object? respondedAt = freezed,Object? status = null,}) {
  return _then(_IssueVerification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as String,verificationType: null == verificationType ? _self.verificationType : verificationType // ignore: cast_nullable_to_non_nullable
as String,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,verifiedBy: freezed == verifiedBy ? _self.verifiedBy : verifiedBy // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PendingVerificationsResponse {

 List<PendingVerification> get items;
/// Create a copy of PendingVerificationsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingVerificationsResponseCopyWith<PendingVerificationsResponse> get copyWith => _$PendingVerificationsResponseCopyWithImpl<PendingVerificationsResponse>(this as PendingVerificationsResponse, _$identity);

  /// Serializes this PendingVerificationsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingVerificationsResponse&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'PendingVerificationsResponse(items: $items)';
}


}

/// @nodoc
abstract mixin class $PendingVerificationsResponseCopyWith<$Res>  {
  factory $PendingVerificationsResponseCopyWith(PendingVerificationsResponse value, $Res Function(PendingVerificationsResponse) _then) = _$PendingVerificationsResponseCopyWithImpl;
@useResult
$Res call({
 List<PendingVerification> items
});




}
/// @nodoc
class _$PendingVerificationsResponseCopyWithImpl<$Res>
    implements $PendingVerificationsResponseCopyWith<$Res> {
  _$PendingVerificationsResponseCopyWithImpl(this._self, this._then);

  final PendingVerificationsResponse _self;
  final $Res Function(PendingVerificationsResponse) _then;

/// Create a copy of PendingVerificationsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PendingVerification>,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingVerificationsResponse].
extension PendingVerificationsResponsePatterns on PendingVerificationsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingVerificationsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingVerificationsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingVerificationsResponse value)  $default,){
final _that = this;
switch (_that) {
case _PendingVerificationsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingVerificationsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PendingVerificationsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PendingVerification> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingVerificationsResponse() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PendingVerification> items)  $default,) {final _that = this;
switch (_that) {
case _PendingVerificationsResponse():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PendingVerification> items)?  $default,) {final _that = this;
switch (_that) {
case _PendingVerificationsResponse() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingVerificationsResponse implements PendingVerificationsResponse {
  const _PendingVerificationsResponse({required final  List<PendingVerification> items}): _items = items;
  factory _PendingVerificationsResponse.fromJson(Map<String, dynamic> json) => _$PendingVerificationsResponseFromJson(json);

 final  List<PendingVerification> _items;
@override List<PendingVerification> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PendingVerificationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingVerificationsResponseCopyWith<_PendingVerificationsResponse> get copyWith => __$PendingVerificationsResponseCopyWithImpl<_PendingVerificationsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingVerificationsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingVerificationsResponse&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'PendingVerificationsResponse(items: $items)';
}


}

/// @nodoc
abstract mixin class _$PendingVerificationsResponseCopyWith<$Res> implements $PendingVerificationsResponseCopyWith<$Res> {
  factory _$PendingVerificationsResponseCopyWith(_PendingVerificationsResponse value, $Res Function(_PendingVerificationsResponse) _then) = __$PendingVerificationsResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PendingVerification> items
});




}
/// @nodoc
class __$PendingVerificationsResponseCopyWithImpl<$Res>
    implements _$PendingVerificationsResponseCopyWith<$Res> {
  __$PendingVerificationsResponseCopyWithImpl(this._self, this._then);

  final _PendingVerificationsResponse _self;
  final $Res Function(_PendingVerificationsResponse) _then;

/// Create a copy of PendingVerificationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_PendingVerificationsResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PendingVerification>,
  ));
}


}

// dart format on
