// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'registration_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegistrationRequest {

 String get firstName; String get surname; String get pin; GeoPoint get location; String get address;
/// Create a copy of RegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegistrationRequestCopyWith<RegistrationRequest> get copyWith => _$RegistrationRequestCopyWithImpl<RegistrationRequest>(this as RegistrationRequest, _$identity);

  /// Serializes this RegistrationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegistrationRequest&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.surname, surname) || other.surname == surname)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,firstName,surname,pin,location,address);

@override
String toString() {
  return 'RegistrationRequest(firstName: $firstName, surname: $surname, pin: $pin, location: $location, address: $address)';
}


}

/// @nodoc
abstract mixin class $RegistrationRequestCopyWith<$Res>  {
  factory $RegistrationRequestCopyWith(RegistrationRequest value, $Res Function(RegistrationRequest) _then) = _$RegistrationRequestCopyWithImpl;
@useResult
$Res call({
 String firstName, String surname, String pin, GeoPoint location, String address
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$RegistrationRequestCopyWithImpl<$Res>
    implements $RegistrationRequestCopyWith<$Res> {
  _$RegistrationRequestCopyWithImpl(this._self, this._then);

  final RegistrationRequest _self;
  final $Res Function(RegistrationRequest) _then;

/// Create a copy of RegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? firstName = null,Object? surname = null,Object? pin = null,Object? location = null,Object? address = null,}) {
  return _then(_self.copyWith(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,surname: null == surname ? _self.surname : surname // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of RegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [RegistrationRequest].
extension RegistrationRequestPatterns on RegistrationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegistrationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegistrationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegistrationRequest value)  $default,){
final _that = this;
switch (_that) {
case _RegistrationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegistrationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RegistrationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String firstName,  String surname,  String pin,  GeoPoint location,  String address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegistrationRequest() when $default != null:
return $default(_that.firstName,_that.surname,_that.pin,_that.location,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String firstName,  String surname,  String pin,  GeoPoint location,  String address)  $default,) {final _that = this;
switch (_that) {
case _RegistrationRequest():
return $default(_that.firstName,_that.surname,_that.pin,_that.location,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String firstName,  String surname,  String pin,  GeoPoint location,  String address)?  $default,) {final _that = this;
switch (_that) {
case _RegistrationRequest() when $default != null:
return $default(_that.firstName,_that.surname,_that.pin,_that.location,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegistrationRequest implements RegistrationRequest {
  const _RegistrationRequest({required this.firstName, required this.surname, required this.pin, required this.location, required this.address});
  factory _RegistrationRequest.fromJson(Map<String, dynamic> json) => _$RegistrationRequestFromJson(json);

@override final  String firstName;
@override final  String surname;
@override final  String pin;
@override final  GeoPoint location;
@override final  String address;

/// Create a copy of RegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegistrationRequestCopyWith<_RegistrationRequest> get copyWith => __$RegistrationRequestCopyWithImpl<_RegistrationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegistrationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegistrationRequest&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.surname, surname) || other.surname == surname)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,firstName,surname,pin,location,address);

@override
String toString() {
  return 'RegistrationRequest(firstName: $firstName, surname: $surname, pin: $pin, location: $location, address: $address)';
}


}

/// @nodoc
abstract mixin class _$RegistrationRequestCopyWith<$Res> implements $RegistrationRequestCopyWith<$Res> {
  factory _$RegistrationRequestCopyWith(_RegistrationRequest value, $Res Function(_RegistrationRequest) _then) = __$RegistrationRequestCopyWithImpl;
@override @useResult
$Res call({
 String firstName, String surname, String pin, GeoPoint location, String address
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$RegistrationRequestCopyWithImpl<$Res>
    implements _$RegistrationRequestCopyWith<$Res> {
  __$RegistrationRequestCopyWithImpl(this._self, this._then);

  final _RegistrationRequest _self;
  final $Res Function(_RegistrationRequest) _then;

/// Create a copy of RegistrationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? firstName = null,Object? surname = null,Object? pin = null,Object? location = null,Object? address = null,}) {
  return _then(_RegistrationRequest(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,surname: null == surname ? _self.surname : surname // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of RegistrationRequest
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
