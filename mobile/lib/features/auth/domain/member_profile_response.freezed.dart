// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_profile_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberProfileResponse {

 String get id; String get firstName; String get surname; String get phoneNumber; String get address; GeoPoint get registrationLocation; String get sectorId; String get status; String get createdAt;
/// Create a copy of MemberProfileResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberProfileResponseCopyWith<MemberProfileResponse> get copyWith => _$MemberProfileResponseCopyWithImpl<MemberProfileResponse>(this as MemberProfileResponse, _$identity);

  /// Serializes this MemberProfileResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberProfileResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberProfileResponse&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.firstName, _this.firstName) || other.firstName == _this.firstName)&&(identical(other.surname, _this.surname) || other.surname == _this.surname)&&(identical(other.phoneNumber, _this.phoneNumber) || other.phoneNumber == _this.phoneNumber)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.registrationLocation, _this.registrationLocation) || other.registrationLocation == _this.registrationLocation)&&(identical(other.sectorId, _this.sectorId) || other.sectorId == _this.sectorId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberProfileResponse;
  return Object.hash(runtimeType,_this.id,_this.firstName,_this.surname,_this.phoneNumber,_this.address,_this.registrationLocation,_this.sectorId,_this.status,_this.createdAt);
}

@override
String toString() {
  final _this = this as MemberProfileResponse;
  return 'MemberProfileResponse(id: ${_this.id}, firstName: ${_this.firstName}, surname: ${_this.surname}, phoneNumber: ${_this.phoneNumber}, address: ${_this.address}, registrationLocation: ${_this.registrationLocation}, sectorId: ${_this.sectorId}, status: ${_this.status}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MemberProfileResponseCopyWith<$Res>  {
  factory $MemberProfileResponseCopyWith(MemberProfileResponse value, $Res Function(MemberProfileResponse) _then) = _$MemberProfileResponseCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String surname, String phoneNumber, String address, GeoPoint registrationLocation, String sectorId, String status, String createdAt
});


$GeoPointCopyWith<$Res> get registrationLocation;

}
/// @nodoc
class _$MemberProfileResponseCopyWithImpl<$Res>
    implements $MemberProfileResponseCopyWith<$Res> {
  _$MemberProfileResponseCopyWithImpl(this._self, this._then);

  final MemberProfileResponse _self;
  final $Res Function(MemberProfileResponse) _then;

/// Create a copy of MemberProfileResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? surname = null,Object? phoneNumber = null,Object? address = null,Object? registrationLocation = null,Object? sectorId = null,Object? status = null,Object? createdAt = null,}) {
  return _then(MemberProfileResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,surname: null == surname ? _self.surname : surname // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,registrationLocation: null == registrationLocation ? _self.registrationLocation : registrationLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of MemberProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get registrationLocation {
  
  return $GeoPointCopyWith<$Res>(_self.registrationLocation, (value) {
    return _then(_self.copyWith(registrationLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [MemberProfileResponse].
extension MemberProfileResponsePatterns on MemberProfileResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberProfileResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberProfileResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberProfileResponse value)  $default,){
final _that = this;
switch (_that) {
case _MemberProfileResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberProfileResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MemberProfileResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String surname,  String phoneNumber,  String address,  GeoPoint registrationLocation,  String sectorId,  String status,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberProfileResponse() when $default != null:
return $default(_that.id,_that.firstName,_that.surname,_that.phoneNumber,_that.address,_that.registrationLocation,_that.sectorId,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String surname,  String phoneNumber,  String address,  GeoPoint registrationLocation,  String sectorId,  String status,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _MemberProfileResponse():
return $default(_that.id,_that.firstName,_that.surname,_that.phoneNumber,_that.address,_that.registrationLocation,_that.sectorId,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String surname,  String phoneNumber,  String address,  GeoPoint registrationLocation,  String sectorId,  String status,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MemberProfileResponse() when $default != null:
return $default(_that.id,_that.firstName,_that.surname,_that.phoneNumber,_that.address,_that.registrationLocation,_that.sectorId,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberProfileResponse extends MemberProfileResponse {
  const _MemberProfileResponse({required this.id, required this.firstName, required this.surname, required this.phoneNumber, required this.address, required this.registrationLocation, required this.sectorId, required this.status, required this.createdAt}): super._();
  factory _MemberProfileResponse.fromJson(Map<String, dynamic> json) => _$MemberProfileResponseFromJson(json);

@override final  String id;
@override final  String firstName;
@override final  String surname;
@override final  String phoneNumber;
@override final  String address;
@override final  GeoPoint registrationLocation;
@override final  String sectorId;
@override final  String status;
@override final  String createdAt;

/// Create a copy of MemberProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberProfileResponseCopyWith<_MemberProfileResponse> get copyWith => __$MemberProfileResponseCopyWithImpl<_MemberProfileResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberProfileResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberProfileResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.surname, surname) || other.surname == surname)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.address, address) || other.address == address)&&(identical(other.registrationLocation, registrationLocation) || other.registrationLocation == registrationLocation)&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,firstName,surname,phoneNumber,address,registrationLocation,sectorId,status,createdAt);
}

@override
String toString() {
    return 'MemberProfileResponse(id: $id, firstName: $firstName, surname: $surname, phoneNumber: $phoneNumber, address: $address, registrationLocation: $registrationLocation, sectorId: $sectorId, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MemberProfileResponseCopyWith<$Res> implements $MemberProfileResponseCopyWith<$Res> {
  factory _$MemberProfileResponseCopyWith(_MemberProfileResponse value, $Res Function(_MemberProfileResponse) _then) = __$MemberProfileResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String surname, String phoneNumber, String address, GeoPoint registrationLocation, String sectorId, String status, String createdAt
});


@override $GeoPointCopyWith<$Res> get registrationLocation;

}
/// @nodoc
class __$MemberProfileResponseCopyWithImpl<$Res>
    implements _$MemberProfileResponseCopyWith<$Res> {
  __$MemberProfileResponseCopyWithImpl(this._self, this._then);

  final _MemberProfileResponse _self;
  final $Res Function(_MemberProfileResponse) _then;

/// Create a copy of MemberProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? surname = null,Object? phoneNumber = null,Object? address = null,Object? registrationLocation = null,Object? sectorId = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_MemberProfileResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,surname: null == surname ? _self.surname : surname // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,registrationLocation: null == registrationLocation ? _self.registrationLocation : registrationLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of MemberProfileResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get registrationLocation {
  
  return $GeoPointCopyWith<$Res>(_self.registrationLocation, (value) {
    return _then(_self.copyWith(registrationLocation: value));
  });
}
}

// dart format on
