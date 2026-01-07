// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backend_registration_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackendRegistrationRequest {

 String get phone; String get firstName; String get surname; String get pin; String get address; String get sectorId; double get latitude; double get longitude;
/// Create a copy of BackendRegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackendRegistrationRequestCopyWith<BackendRegistrationRequest> get copyWith => _$BackendRegistrationRequestCopyWithImpl<BackendRegistrationRequest>(this as BackendRegistrationRequest, _$identity);

  /// Serializes this BackendRegistrationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackendRegistrationRequest&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.surname, surname) || other.surname == surname)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.address, address) || other.address == address)&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phone,firstName,surname,pin,address,sectorId,latitude,longitude);

@override
String toString() {
  return 'BackendRegistrationRequest(phone: $phone, firstName: $firstName, surname: $surname, pin: $pin, address: $address, sectorId: $sectorId, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $BackendRegistrationRequestCopyWith<$Res>  {
  factory $BackendRegistrationRequestCopyWith(BackendRegistrationRequest value, $Res Function(BackendRegistrationRequest) _then) = _$BackendRegistrationRequestCopyWithImpl;
@useResult
$Res call({
 String phone, String firstName, String surname, String pin, String address, String sectorId, double latitude, double longitude
});




}
/// @nodoc
class _$BackendRegistrationRequestCopyWithImpl<$Res>
    implements $BackendRegistrationRequestCopyWith<$Res> {
  _$BackendRegistrationRequestCopyWithImpl(this._self, this._then);

  final BackendRegistrationRequest _self;
  final $Res Function(BackendRegistrationRequest) _then;

/// Create a copy of BackendRegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,Object? firstName = null,Object? surname = null,Object? pin = null,Object? address = null,Object? sectorId = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,surname: null == surname ? _self.surname : surname // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BackendRegistrationRequest].
extension BackendRegistrationRequestPatterns on BackendRegistrationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackendRegistrationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackendRegistrationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackendRegistrationRequest value)  $default,){
final _that = this;
switch (_that) {
case _BackendRegistrationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackendRegistrationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _BackendRegistrationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone,  String firstName,  String surname,  String pin,  String address,  String sectorId,  double latitude,  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackendRegistrationRequest() when $default != null:
return $default(_that.phone,_that.firstName,_that.surname,_that.pin,_that.address,_that.sectorId,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone,  String firstName,  String surname,  String pin,  String address,  String sectorId,  double latitude,  double longitude)  $default,) {final _that = this;
switch (_that) {
case _BackendRegistrationRequest():
return $default(_that.phone,_that.firstName,_that.surname,_that.pin,_that.address,_that.sectorId,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone,  String firstName,  String surname,  String pin,  String address,  String sectorId,  double latitude,  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _BackendRegistrationRequest() when $default != null:
return $default(_that.phone,_that.firstName,_that.surname,_that.pin,_that.address,_that.sectorId,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BackendRegistrationRequest implements BackendRegistrationRequest {
  const _BackendRegistrationRequest({required this.phone, required this.firstName, required this.surname, required this.pin, required this.address, required this.sectorId, required this.latitude, required this.longitude});
  factory _BackendRegistrationRequest.fromJson(Map<String, dynamic> json) => _$BackendRegistrationRequestFromJson(json);

@override final  String phone;
@override final  String firstName;
@override final  String surname;
@override final  String pin;
@override final  String address;
@override final  String sectorId;
@override final  double latitude;
@override final  double longitude;

/// Create a copy of BackendRegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackendRegistrationRequestCopyWith<_BackendRegistrationRequest> get copyWith => __$BackendRegistrationRequestCopyWithImpl<_BackendRegistrationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BackendRegistrationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackendRegistrationRequest&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.surname, surname) || other.surname == surname)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.address, address) || other.address == address)&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phone,firstName,surname,pin,address,sectorId,latitude,longitude);

@override
String toString() {
  return 'BackendRegistrationRequest(phone: $phone, firstName: $firstName, surname: $surname, pin: $pin, address: $address, sectorId: $sectorId, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$BackendRegistrationRequestCopyWith<$Res> implements $BackendRegistrationRequestCopyWith<$Res> {
  factory _$BackendRegistrationRequestCopyWith(_BackendRegistrationRequest value, $Res Function(_BackendRegistrationRequest) _then) = __$BackendRegistrationRequestCopyWithImpl;
@override @useResult
$Res call({
 String phone, String firstName, String surname, String pin, String address, String sectorId, double latitude, double longitude
});




}
/// @nodoc
class __$BackendRegistrationRequestCopyWithImpl<$Res>
    implements _$BackendRegistrationRequestCopyWith<$Res> {
  __$BackendRegistrationRequestCopyWithImpl(this._self, this._then);

  final _BackendRegistrationRequest _self;
  final $Res Function(_BackendRegistrationRequest) _then;

/// Create a copy of BackendRegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? firstName = null,Object? surname = null,Object? pin = null,Object? address = null,Object? sectorId = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_BackendRegistrationRequest(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,surname: null == surname ? _self.surname : surname // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
