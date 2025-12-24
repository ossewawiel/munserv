// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OtpRequest {

 String get phoneNumber;
/// Create a copy of OtpRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpRequestCopyWith<OtpRequest> get copyWith => _$OtpRequestCopyWithImpl<OtpRequest>(this as OtpRequest, _$identity);

  /// Serializes this OtpRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber);

@override
String toString() {
  return 'OtpRequest(phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class $OtpRequestCopyWith<$Res>  {
  factory $OtpRequestCopyWith(OtpRequest value, $Res Function(OtpRequest) _then) = _$OtpRequestCopyWithImpl;
@useResult
$Res call({
 String phoneNumber
});




}
/// @nodoc
class _$OtpRequestCopyWithImpl<$Res>
    implements $OtpRequestCopyWith<$Res> {
  _$OtpRequestCopyWithImpl(this._self, this._then);

  final OtpRequest _self;
  final $Res Function(OtpRequest) _then;

/// Create a copy of OtpRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phoneNumber = null,}) {
  return _then(_self.copyWith(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpRequest].
extension OtpRequestPatterns on OtpRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpRequest value)  $default,){
final _that = this;
switch (_that) {
case _OtpRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpRequest value)?  $default,){
final _that = this;
switch (_that) {
case _OtpRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phoneNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpRequest() when $default != null:
return $default(_that.phoneNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phoneNumber)  $default,) {final _that = this;
switch (_that) {
case _OtpRequest():
return $default(_that.phoneNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phoneNumber)?  $default,) {final _that = this;
switch (_that) {
case _OtpRequest() when $default != null:
return $default(_that.phoneNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OtpRequest implements OtpRequest {
  const _OtpRequest({required this.phoneNumber});
  factory _OtpRequest.fromJson(Map<String, dynamic> json) => _$OtpRequestFromJson(json);

@override final  String phoneNumber;

/// Create a copy of OtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpRequestCopyWith<_OtpRequest> get copyWith => __$OtpRequestCopyWithImpl<_OtpRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber);

@override
String toString() {
  return 'OtpRequest(phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class _$OtpRequestCopyWith<$Res> implements $OtpRequestCopyWith<$Res> {
  factory _$OtpRequestCopyWith(_OtpRequest value, $Res Function(_OtpRequest) _then) = __$OtpRequestCopyWithImpl;
@override @useResult
$Res call({
 String phoneNumber
});




}
/// @nodoc
class __$OtpRequestCopyWithImpl<$Res>
    implements _$OtpRequestCopyWith<$Res> {
  __$OtpRequestCopyWithImpl(this._self, this._then);

  final _OtpRequest _self;
  final $Res Function(_OtpRequest) _then;

/// Create a copy of OtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phoneNumber = null,}) {
  return _then(_OtpRequest(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OtpRequestResponse {

 String get message; int get expiresInSeconds;
/// Create a copy of OtpRequestResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpRequestResponseCopyWith<OtpRequestResponse> get copyWith => _$OtpRequestResponseCopyWithImpl<OtpRequestResponse>(this as OtpRequestResponse, _$identity);

  /// Serializes this OtpRequestResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpRequestResponse&&(identical(other.message, message) || other.message == message)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,expiresInSeconds);

@override
String toString() {
  return 'OtpRequestResponse(message: $message, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class $OtpRequestResponseCopyWith<$Res>  {
  factory $OtpRequestResponseCopyWith(OtpRequestResponse value, $Res Function(OtpRequestResponse) _then) = _$OtpRequestResponseCopyWithImpl;
@useResult
$Res call({
 String message, int expiresInSeconds
});




}
/// @nodoc
class _$OtpRequestResponseCopyWithImpl<$Res>
    implements $OtpRequestResponseCopyWith<$Res> {
  _$OtpRequestResponseCopyWithImpl(this._self, this._then);

  final OtpRequestResponse _self;
  final $Res Function(OtpRequestResponse) _then;

/// Create a copy of OtpRequestResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? expiresInSeconds = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpRequestResponse].
extension OtpRequestResponsePatterns on OtpRequestResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpRequestResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpRequestResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpRequestResponse value)  $default,){
final _that = this;
switch (_that) {
case _OtpRequestResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpRequestResponse value)?  $default,){
final _that = this;
switch (_that) {
case _OtpRequestResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  int expiresInSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpRequestResponse() when $default != null:
return $default(_that.message,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  int expiresInSeconds)  $default,) {final _that = this;
switch (_that) {
case _OtpRequestResponse():
return $default(_that.message,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  int expiresInSeconds)?  $default,) {final _that = this;
switch (_that) {
case _OtpRequestResponse() when $default != null:
return $default(_that.message,_that.expiresInSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OtpRequestResponse implements OtpRequestResponse {
  const _OtpRequestResponse({required this.message, required this.expiresInSeconds});
  factory _OtpRequestResponse.fromJson(Map<String, dynamic> json) => _$OtpRequestResponseFromJson(json);

@override final  String message;
@override final  int expiresInSeconds;

/// Create a copy of OtpRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpRequestResponseCopyWith<_OtpRequestResponse> get copyWith => __$OtpRequestResponseCopyWithImpl<_OtpRequestResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpRequestResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpRequestResponse&&(identical(other.message, message) || other.message == message)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,expiresInSeconds);

@override
String toString() {
  return 'OtpRequestResponse(message: $message, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class _$OtpRequestResponseCopyWith<$Res> implements $OtpRequestResponseCopyWith<$Res> {
  factory _$OtpRequestResponseCopyWith(_OtpRequestResponse value, $Res Function(_OtpRequestResponse) _then) = __$OtpRequestResponseCopyWithImpl;
@override @useResult
$Res call({
 String message, int expiresInSeconds
});




}
/// @nodoc
class __$OtpRequestResponseCopyWithImpl<$Res>
    implements _$OtpRequestResponseCopyWith<$Res> {
  __$OtpRequestResponseCopyWithImpl(this._self, this._then);

  final _OtpRequestResponse _self;
  final $Res Function(_OtpRequestResponse) _then;

/// Create a copy of OtpRequestResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? expiresInSeconds = null,}) {
  return _then(_OtpRequestResponse(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
