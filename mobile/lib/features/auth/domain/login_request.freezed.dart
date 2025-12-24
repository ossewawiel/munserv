// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoginRequest {

 String get phoneNumber; String get pin;
/// Create a copy of LoginRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginRequestCopyWith<LoginRequest> get copyWith => _$LoginRequestCopyWithImpl<LoginRequest>(this as LoginRequest, _$identity);

  /// Serializes this LoginRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.pin, pin) || other.pin == pin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber,pin);

@override
String toString() {
  return 'LoginRequest(phoneNumber: $phoneNumber, pin: $pin)';
}


}

/// @nodoc
abstract mixin class $LoginRequestCopyWith<$Res>  {
  factory $LoginRequestCopyWith(LoginRequest value, $Res Function(LoginRequest) _then) = _$LoginRequestCopyWithImpl;
@useResult
$Res call({
 String phoneNumber, String pin
});




}
/// @nodoc
class _$LoginRequestCopyWithImpl<$Res>
    implements $LoginRequestCopyWith<$Res> {
  _$LoginRequestCopyWithImpl(this._self, this._then);

  final LoginRequest _self;
  final $Res Function(LoginRequest) _then;

/// Create a copy of LoginRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phoneNumber = null,Object? pin = null,}) {
  return _then(_self.copyWith(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginRequest].
extension LoginRequestPatterns on LoginRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginRequest value)  $default,){
final _that = this;
switch (_that) {
case _LoginRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginRequest value)?  $default,){
final _that = this;
switch (_that) {
case _LoginRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phoneNumber,  String pin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginRequest() when $default != null:
return $default(_that.phoneNumber,_that.pin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phoneNumber,  String pin)  $default,) {final _that = this;
switch (_that) {
case _LoginRequest():
return $default(_that.phoneNumber,_that.pin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phoneNumber,  String pin)?  $default,) {final _that = this;
switch (_that) {
case _LoginRequest() when $default != null:
return $default(_that.phoneNumber,_that.pin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoginRequest implements LoginRequest {
  const _LoginRequest({required this.phoneNumber, required this.pin});
  factory _LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);

@override final  String phoneNumber;
@override final  String pin;

/// Create a copy of LoginRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginRequestCopyWith<_LoginRequest> get copyWith => __$LoginRequestCopyWithImpl<_LoginRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoginRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.pin, pin) || other.pin == pin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber,pin);

@override
String toString() {
  return 'LoginRequest(phoneNumber: $phoneNumber, pin: $pin)';
}


}

/// @nodoc
abstract mixin class _$LoginRequestCopyWith<$Res> implements $LoginRequestCopyWith<$Res> {
  factory _$LoginRequestCopyWith(_LoginRequest value, $Res Function(_LoginRequest) _then) = __$LoginRequestCopyWithImpl;
@override @useResult
$Res call({
 String phoneNumber, String pin
});




}
/// @nodoc
class __$LoginRequestCopyWithImpl<$Res>
    implements _$LoginRequestCopyWith<$Res> {
  __$LoginRequestCopyWithImpl(this._self, this._then);

  final _LoginRequest _self;
  final $Res Function(_LoginRequest) _then;

/// Create a copy of LoginRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phoneNumber = null,Object? pin = null,}) {
  return _then(_LoginRequest(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AuthTokens {

 String get accessToken; String get refreshToken; String? get expiresAt;
/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<AuthTokens> get copyWith => _$AuthTokensCopyWithImpl<AuthTokens>(this as AuthTokens, _$identity);

  /// Serializes this AuthTokens to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthTokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresAt);

@override
String toString() {
  return 'AuthTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $AuthTokensCopyWith<$Res>  {
  factory $AuthTokensCopyWith(AuthTokens value, $Res Function(AuthTokens) _then) = _$AuthTokensCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, String? expiresAt
});




}
/// @nodoc
class _$AuthTokensCopyWithImpl<$Res>
    implements $AuthTokensCopyWith<$Res> {
  _$AuthTokensCopyWithImpl(this._self, this._then);

  final AuthTokens _self;
  final $Res Function(AuthTokens) _then;

/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthTokens].
extension AuthTokensPatterns on AuthTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthTokens value)  $default,){
final _that = this;
switch (_that) {
case _AuthTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthTokens value)?  $default,){
final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  String? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _AuthTokens():
return $default(_that.accessToken,_that.refreshToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  String? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthTokens implements AuthTokens {
  const _AuthTokens({required this.accessToken, required this.refreshToken, this.expiresAt});
  factory _AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  String? expiresAt;

/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthTokensCopyWith<_AuthTokens> get copyWith => __$AuthTokensCopyWithImpl<_AuthTokens>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthTokensToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthTokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresAt);

@override
String toString() {
  return 'AuthTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$AuthTokensCopyWith<$Res> implements $AuthTokensCopyWith<$Res> {
  factory _$AuthTokensCopyWith(_AuthTokens value, $Res Function(_AuthTokens) _then) = __$AuthTokensCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, String? expiresAt
});




}
/// @nodoc
class __$AuthTokensCopyWithImpl<$Res>
    implements _$AuthTokensCopyWith<$Res> {
  __$AuthTokensCopyWithImpl(this._self, this._then);

  final _AuthTokens _self;
  final $Res Function(_AuthTokens) _then;

/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresAt = freezed,}) {
  return _then(_AuthTokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MemberProfile {

 String get id; String get firstName; String get surname; String get phoneNumber; String get address; GeoPoint get registrationLocation; String get sectorId; String get status; String get createdAt;
/// Create a copy of MemberProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberProfileCopyWith<MemberProfile> get copyWith => _$MemberProfileCopyWithImpl<MemberProfile>(this as MemberProfile, _$identity);

  /// Serializes this MemberProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.surname, surname) || other.surname == surname)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.address, address) || other.address == address)&&(identical(other.registrationLocation, registrationLocation) || other.registrationLocation == registrationLocation)&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstName,surname,phoneNumber,address,registrationLocation,sectorId,status,createdAt);

@override
String toString() {
  return 'MemberProfile(id: $id, firstName: $firstName, surname: $surname, phoneNumber: $phoneNumber, address: $address, registrationLocation: $registrationLocation, sectorId: $sectorId, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MemberProfileCopyWith<$Res>  {
  factory $MemberProfileCopyWith(MemberProfile value, $Res Function(MemberProfile) _then) = _$MemberProfileCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String surname, String phoneNumber, String address, GeoPoint registrationLocation, String sectorId, String status, String createdAt
});


$GeoPointCopyWith<$Res> get registrationLocation;

}
/// @nodoc
class _$MemberProfileCopyWithImpl<$Res>
    implements $MemberProfileCopyWith<$Res> {
  _$MemberProfileCopyWithImpl(this._self, this._then);

  final MemberProfile _self;
  final $Res Function(MemberProfile) _then;

/// Create a copy of MemberProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? surname = null,Object? phoneNumber = null,Object? address = null,Object? registrationLocation = null,Object? sectorId = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
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
/// Create a copy of MemberProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get registrationLocation {
  
  return $GeoPointCopyWith<$Res>(_self.registrationLocation, (value) {
    return _then(_self.copyWith(registrationLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [MemberProfile].
extension MemberProfilePatterns on MemberProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberProfile value)  $default,){
final _that = this;
switch (_that) {
case _MemberProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberProfile value)?  $default,){
final _that = this;
switch (_that) {
case _MemberProfile() when $default != null:
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
case _MemberProfile() when $default != null:
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
case _MemberProfile():
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
case _MemberProfile() when $default != null:
return $default(_that.id,_that.firstName,_that.surname,_that.phoneNumber,_that.address,_that.registrationLocation,_that.sectorId,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberProfile extends MemberProfile {
  const _MemberProfile({required this.id, required this.firstName, required this.surname, required this.phoneNumber, required this.address, required this.registrationLocation, required this.sectorId, required this.status, required this.createdAt}): super._();
  factory _MemberProfile.fromJson(Map<String, dynamic> json) => _$MemberProfileFromJson(json);

@override final  String id;
@override final  String firstName;
@override final  String surname;
@override final  String phoneNumber;
@override final  String address;
@override final  GeoPoint registrationLocation;
@override final  String sectorId;
@override final  String status;
@override final  String createdAt;

/// Create a copy of MemberProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberProfileCopyWith<_MemberProfile> get copyWith => __$MemberProfileCopyWithImpl<_MemberProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.surname, surname) || other.surname == surname)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.address, address) || other.address == address)&&(identical(other.registrationLocation, registrationLocation) || other.registrationLocation == registrationLocation)&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstName,surname,phoneNumber,address,registrationLocation,sectorId,status,createdAt);

@override
String toString() {
  return 'MemberProfile(id: $id, firstName: $firstName, surname: $surname, phoneNumber: $phoneNumber, address: $address, registrationLocation: $registrationLocation, sectorId: $sectorId, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MemberProfileCopyWith<$Res> implements $MemberProfileCopyWith<$Res> {
  factory _$MemberProfileCopyWith(_MemberProfile value, $Res Function(_MemberProfile) _then) = __$MemberProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String surname, String phoneNumber, String address, GeoPoint registrationLocation, String sectorId, String status, String createdAt
});


@override $GeoPointCopyWith<$Res> get registrationLocation;

}
/// @nodoc
class __$MemberProfileCopyWithImpl<$Res>
    implements _$MemberProfileCopyWith<$Res> {
  __$MemberProfileCopyWithImpl(this._self, this._then);

  final _MemberProfile _self;
  final $Res Function(_MemberProfile) _then;

/// Create a copy of MemberProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? surname = null,Object? phoneNumber = null,Object? address = null,Object? registrationLocation = null,Object? sectorId = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_MemberProfile(
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

/// Create a copy of MemberProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get registrationLocation {
  
  return $GeoPointCopyWith<$Res>(_self.registrationLocation, (value) {
    return _then(_self.copyWith(registrationLocation: value));
  });
}
}


/// @nodoc
mixin _$SectorInfo {

 String get id; String get name; GeoPoint get center;
/// Create a copy of SectorInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectorInfoCopyWith<SectorInfo> get copyWith => _$SectorInfoCopyWithImpl<SectorInfo>(this as SectorInfo, _$identity);

  /// Serializes this SectorInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectorInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.center, center) || other.center == center));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,center);

@override
String toString() {
  return 'SectorInfo(id: $id, name: $name, center: $center)';
}


}

/// @nodoc
abstract mixin class $SectorInfoCopyWith<$Res>  {
  factory $SectorInfoCopyWith(SectorInfo value, $Res Function(SectorInfo) _then) = _$SectorInfoCopyWithImpl;
@useResult
$Res call({
 String id, String name, GeoPoint center
});


$GeoPointCopyWith<$Res> get center;

}
/// @nodoc
class _$SectorInfoCopyWithImpl<$Res>
    implements $SectorInfoCopyWith<$Res> {
  _$SectorInfoCopyWithImpl(this._self, this._then);

  final SectorInfo _self;
  final $Res Function(SectorInfo) _then;

/// Create a copy of SectorInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? center = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,
  ));
}
/// Create a copy of SectorInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get center {
  
  return $GeoPointCopyWith<$Res>(_self.center, (value) {
    return _then(_self.copyWith(center: value));
  });
}
}


/// Adds pattern-matching-related methods to [SectorInfo].
extension SectorInfoPatterns on SectorInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SectorInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SectorInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SectorInfo value)  $default,){
final _that = this;
switch (_that) {
case _SectorInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SectorInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SectorInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  GeoPoint center)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SectorInfo() when $default != null:
return $default(_that.id,_that.name,_that.center);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  GeoPoint center)  $default,) {final _that = this;
switch (_that) {
case _SectorInfo():
return $default(_that.id,_that.name,_that.center);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  GeoPoint center)?  $default,) {final _that = this;
switch (_that) {
case _SectorInfo() when $default != null:
return $default(_that.id,_that.name,_that.center);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SectorInfo implements SectorInfo {
  const _SectorInfo({required this.id, required this.name, required this.center});
  factory _SectorInfo.fromJson(Map<String, dynamic> json) => _$SectorInfoFromJson(json);

@override final  String id;
@override final  String name;
@override final  GeoPoint center;

/// Create a copy of SectorInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SectorInfoCopyWith<_SectorInfo> get copyWith => __$SectorInfoCopyWithImpl<_SectorInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SectorInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SectorInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.center, center) || other.center == center));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,center);

@override
String toString() {
  return 'SectorInfo(id: $id, name: $name, center: $center)';
}


}

/// @nodoc
abstract mixin class _$SectorInfoCopyWith<$Res> implements $SectorInfoCopyWith<$Res> {
  factory _$SectorInfoCopyWith(_SectorInfo value, $Res Function(_SectorInfo) _then) = __$SectorInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, GeoPoint center
});


@override $GeoPointCopyWith<$Res> get center;

}
/// @nodoc
class __$SectorInfoCopyWithImpl<$Res>
    implements _$SectorInfoCopyWith<$Res> {
  __$SectorInfoCopyWithImpl(this._self, this._then);

  final _SectorInfo _self;
  final $Res Function(_SectorInfo) _then;

/// Create a copy of SectorInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? center = null,}) {
  return _then(_SectorInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,
  ));
}

/// Create a copy of SectorInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get center {
  
  return $GeoPointCopyWith<$Res>(_self.center, (value) {
    return _then(_self.copyWith(center: value));
  });
}
}


/// @nodoc
mixin _$AuthProfile {

 MemberProfile get member; SectorInfo get sector;
/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthProfileCopyWith<AuthProfile> get copyWith => _$AuthProfileCopyWithImpl<AuthProfile>(this as AuthProfile, _$identity);

  /// Serializes this AuthProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthProfile&&(identical(other.member, member) || other.member == member)&&(identical(other.sector, sector) || other.sector == sector));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,member,sector);

@override
String toString() {
  return 'AuthProfile(member: $member, sector: $sector)';
}


}

/// @nodoc
abstract mixin class $AuthProfileCopyWith<$Res>  {
  factory $AuthProfileCopyWith(AuthProfile value, $Res Function(AuthProfile) _then) = _$AuthProfileCopyWithImpl;
@useResult
$Res call({
 MemberProfile member, SectorInfo sector
});


$MemberProfileCopyWith<$Res> get member;$SectorInfoCopyWith<$Res> get sector;

}
/// @nodoc
class _$AuthProfileCopyWithImpl<$Res>
    implements $AuthProfileCopyWith<$Res> {
  _$AuthProfileCopyWithImpl(this._self, this._then);

  final AuthProfile _self;
  final $Res Function(AuthProfile) _then;

/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? member = null,Object? sector = null,}) {
  return _then(_self.copyWith(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as MemberProfile,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as SectorInfo,
  ));
}
/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberProfileCopyWith<$Res> get member {
  
  return $MemberProfileCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SectorInfoCopyWith<$Res> get sector {
  
  return $SectorInfoCopyWith<$Res>(_self.sector, (value) {
    return _then(_self.copyWith(sector: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthProfile].
extension AuthProfilePatterns on AuthProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthProfile value)  $default,){
final _that = this;
switch (_that) {
case _AuthProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthProfile value)?  $default,){
final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MemberProfile member,  SectorInfo sector)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
return $default(_that.member,_that.sector);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MemberProfile member,  SectorInfo sector)  $default,) {final _that = this;
switch (_that) {
case _AuthProfile():
return $default(_that.member,_that.sector);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MemberProfile member,  SectorInfo sector)?  $default,) {final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
return $default(_that.member,_that.sector);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthProfile implements AuthProfile {
  const _AuthProfile({required this.member, required this.sector});
  factory _AuthProfile.fromJson(Map<String, dynamic> json) => _$AuthProfileFromJson(json);

@override final  MemberProfile member;
@override final  SectorInfo sector;

/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthProfileCopyWith<_AuthProfile> get copyWith => __$AuthProfileCopyWithImpl<_AuthProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthProfile&&(identical(other.member, member) || other.member == member)&&(identical(other.sector, sector) || other.sector == sector));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,member,sector);

@override
String toString() {
  return 'AuthProfile(member: $member, sector: $sector)';
}


}

/// @nodoc
abstract mixin class _$AuthProfileCopyWith<$Res> implements $AuthProfileCopyWith<$Res> {
  factory _$AuthProfileCopyWith(_AuthProfile value, $Res Function(_AuthProfile) _then) = __$AuthProfileCopyWithImpl;
@override @useResult
$Res call({
 MemberProfile member, SectorInfo sector
});


@override $MemberProfileCopyWith<$Res> get member;@override $SectorInfoCopyWith<$Res> get sector;

}
/// @nodoc
class __$AuthProfileCopyWithImpl<$Res>
    implements _$AuthProfileCopyWith<$Res> {
  __$AuthProfileCopyWithImpl(this._self, this._then);

  final _AuthProfile _self;
  final $Res Function(_AuthProfile) _then;

/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? member = null,Object? sector = null,}) {
  return _then(_AuthProfile(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as MemberProfile,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as SectorInfo,
  ));
}

/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberProfileCopyWith<$Res> get member {
  
  return $MemberProfileCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SectorInfoCopyWith<$Res> get sector {
  
  return $SectorInfoCopyWith<$Res>(_self.sector, (value) {
    return _then(_self.copyWith(sector: value));
  });
}
}


/// @nodoc
mixin _$AuthResponse {

 AuthTokens get tokens; AuthProfile get profile;
/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthResponseCopyWith<AuthResponse> get copyWith => _$AuthResponseCopyWithImpl<AuthResponse>(this as AuthResponse, _$identity);

  /// Serializes this AuthResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthResponse&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.profile, profile) || other.profile == profile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tokens,profile);

@override
String toString() {
  return 'AuthResponse(tokens: $tokens, profile: $profile)';
}


}

/// @nodoc
abstract mixin class $AuthResponseCopyWith<$Res>  {
  factory $AuthResponseCopyWith(AuthResponse value, $Res Function(AuthResponse) _then) = _$AuthResponseCopyWithImpl;
@useResult
$Res call({
 AuthTokens tokens, AuthProfile profile
});


$AuthTokensCopyWith<$Res> get tokens;$AuthProfileCopyWith<$Res> get profile;

}
/// @nodoc
class _$AuthResponseCopyWithImpl<$Res>
    implements $AuthResponseCopyWith<$Res> {
  _$AuthResponseCopyWithImpl(this._self, this._then);

  final AuthResponse _self;
  final $Res Function(AuthResponse) _then;

/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tokens = null,Object? profile = null,}) {
  return _then(_self.copyWith(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AuthProfile,
  ));
}
/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthProfileCopyWith<$Res> get profile {
  
  return $AuthProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthResponse].
extension AuthResponsePatterns on AuthResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthResponse value)  $default,){
final _that = this;
switch (_that) {
case _AuthResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AuthResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthTokens tokens,  AuthProfile profile)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthResponse() when $default != null:
return $default(_that.tokens,_that.profile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthTokens tokens,  AuthProfile profile)  $default,) {final _that = this;
switch (_that) {
case _AuthResponse():
return $default(_that.tokens,_that.profile);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthTokens tokens,  AuthProfile profile)?  $default,) {final _that = this;
switch (_that) {
case _AuthResponse() when $default != null:
return $default(_that.tokens,_that.profile);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthResponse extends AuthResponse {
  const _AuthResponse({required this.tokens, required this.profile}): super._();
  factory _AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);

@override final  AuthTokens tokens;
@override final  AuthProfile profile;

/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthResponseCopyWith<_AuthResponse> get copyWith => __$AuthResponseCopyWithImpl<_AuthResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthResponse&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.profile, profile) || other.profile == profile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tokens,profile);

@override
String toString() {
  return 'AuthResponse(tokens: $tokens, profile: $profile)';
}


}

/// @nodoc
abstract mixin class _$AuthResponseCopyWith<$Res> implements $AuthResponseCopyWith<$Res> {
  factory _$AuthResponseCopyWith(_AuthResponse value, $Res Function(_AuthResponse) _then) = __$AuthResponseCopyWithImpl;
@override @useResult
$Res call({
 AuthTokens tokens, AuthProfile profile
});


@override $AuthTokensCopyWith<$Res> get tokens;@override $AuthProfileCopyWith<$Res> get profile;

}
/// @nodoc
class __$AuthResponseCopyWithImpl<$Res>
    implements _$AuthResponseCopyWith<$Res> {
  __$AuthResponseCopyWithImpl(this._self, this._then);

  final _AuthResponse _self;
  final $Res Function(_AuthResponse) _then;

/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tokens = null,Object? profile = null,}) {
  return _then(_AuthResponse(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AuthProfile,
  ));
}

/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}/// Create a copy of AuthResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthProfileCopyWith<$Res> get profile {
  
  return $AuthProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
