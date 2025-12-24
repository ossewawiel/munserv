// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_verify_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OtpVerifyRequest {

 String get phoneNumber; String get otp;
/// Create a copy of OtpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpVerifyRequestCopyWith<OtpVerifyRequest> get copyWith => _$OtpVerifyRequestCopyWithImpl<OtpVerifyRequest>(this as OtpVerifyRequest, _$identity);

  /// Serializes this OtpVerifyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpVerifyRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.otp, otp) || other.otp == otp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber,otp);

@override
String toString() {
  return 'OtpVerifyRequest(phoneNumber: $phoneNumber, otp: $otp)';
}


}

/// @nodoc
abstract mixin class $OtpVerifyRequestCopyWith<$Res>  {
  factory $OtpVerifyRequestCopyWith(OtpVerifyRequest value, $Res Function(OtpVerifyRequest) _then) = _$OtpVerifyRequestCopyWithImpl;
@useResult
$Res call({
 String phoneNumber, String otp
});




}
/// @nodoc
class _$OtpVerifyRequestCopyWithImpl<$Res>
    implements $OtpVerifyRequestCopyWith<$Res> {
  _$OtpVerifyRequestCopyWithImpl(this._self, this._then);

  final OtpVerifyRequest _self;
  final $Res Function(OtpVerifyRequest) _then;

/// Create a copy of OtpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phoneNumber = null,Object? otp = null,}) {
  return _then(_self.copyWith(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,otp: null == otp ? _self.otp : otp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpVerifyRequest].
extension OtpVerifyRequestPatterns on OtpVerifyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpVerifyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpVerifyRequest value)  $default,){
final _that = this;
switch (_that) {
case _OtpVerifyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpVerifyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _OtpVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phoneNumber,  String otp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpVerifyRequest() when $default != null:
return $default(_that.phoneNumber,_that.otp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phoneNumber,  String otp)  $default,) {final _that = this;
switch (_that) {
case _OtpVerifyRequest():
return $default(_that.phoneNumber,_that.otp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phoneNumber,  String otp)?  $default,) {final _that = this;
switch (_that) {
case _OtpVerifyRequest() when $default != null:
return $default(_that.phoneNumber,_that.otp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OtpVerifyRequest implements OtpVerifyRequest {
  const _OtpVerifyRequest({required this.phoneNumber, required this.otp});
  factory _OtpVerifyRequest.fromJson(Map<String, dynamic> json) => _$OtpVerifyRequestFromJson(json);

@override final  String phoneNumber;
@override final  String otp;

/// Create a copy of OtpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpVerifyRequestCopyWith<_OtpVerifyRequest> get copyWith => __$OtpVerifyRequestCopyWithImpl<_OtpVerifyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpVerifyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpVerifyRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.otp, otp) || other.otp == otp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber,otp);

@override
String toString() {
  return 'OtpVerifyRequest(phoneNumber: $phoneNumber, otp: $otp)';
}


}

/// @nodoc
abstract mixin class _$OtpVerifyRequestCopyWith<$Res> implements $OtpVerifyRequestCopyWith<$Res> {
  factory _$OtpVerifyRequestCopyWith(_OtpVerifyRequest value, $Res Function(_OtpVerifyRequest) _then) = __$OtpVerifyRequestCopyWithImpl;
@override @useResult
$Res call({
 String phoneNumber, String otp
});




}
/// @nodoc
class __$OtpVerifyRequestCopyWithImpl<$Res>
    implements _$OtpVerifyRequestCopyWith<$Res> {
  __$OtpVerifyRequestCopyWithImpl(this._self, this._then);

  final _OtpVerifyRequest _self;
  final $Res Function(_OtpVerifyRequest) _then;

/// Create a copy of OtpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phoneNumber = null,Object? otp = null,}) {
  return _then(_OtpVerifyRequest(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,otp: null == otp ? _self.otp : otp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

OtpVerifyResult _$OtpVerifyResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['status']) {
                  case 'new_user':
          return OtpVerifyResultNewUser.fromJson(
            json
          );
                case 'existing_user':
          return OtpVerifyResultExistingUser.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'status',
  'OtpVerifyResult',
  'Invalid union type "${json['status']}"!'
);
        }
      
}

/// @nodoc
mixin _$OtpVerifyResult {



  /// Serializes this OtpVerifyResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpVerifyResult);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpVerifyResult()';
}


}

/// @nodoc
class $OtpVerifyResultCopyWith<$Res>  {
$OtpVerifyResultCopyWith(OtpVerifyResult _, $Res Function(OtpVerifyResult) __);
}


/// Adds pattern-matching-related methods to [OtpVerifyResult].
extension OtpVerifyResultPatterns on OtpVerifyResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OtpVerifyResultNewUser value)?  newUser,TResult Function( OtpVerifyResultExistingUser value)?  existingUser,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OtpVerifyResultNewUser() when newUser != null:
return newUser(_that);case OtpVerifyResultExistingUser() when existingUser != null:
return existingUser(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OtpVerifyResultNewUser value)  newUser,required TResult Function( OtpVerifyResultExistingUser value)  existingUser,}){
final _that = this;
switch (_that) {
case OtpVerifyResultNewUser():
return newUser(_that);case OtpVerifyResultExistingUser():
return existingUser(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OtpVerifyResultNewUser value)?  newUser,TResult? Function( OtpVerifyResultExistingUser value)?  existingUser,}){
final _that = this;
switch (_that) {
case OtpVerifyResultNewUser() when newUser != null:
return newUser(_that);case OtpVerifyResultExistingUser() when existingUser != null:
return existingUser(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String tempToken)?  newUser,TResult Function( AuthTokens tokens,  AuthProfile profile)?  existingUser,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OtpVerifyResultNewUser() when newUser != null:
return newUser(_that.tempToken);case OtpVerifyResultExistingUser() when existingUser != null:
return existingUser(_that.tokens,_that.profile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String tempToken)  newUser,required TResult Function( AuthTokens tokens,  AuthProfile profile)  existingUser,}) {final _that = this;
switch (_that) {
case OtpVerifyResultNewUser():
return newUser(_that.tempToken);case OtpVerifyResultExistingUser():
return existingUser(_that.tokens,_that.profile);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String tempToken)?  newUser,TResult? Function( AuthTokens tokens,  AuthProfile profile)?  existingUser,}) {final _that = this;
switch (_that) {
case OtpVerifyResultNewUser() when newUser != null:
return newUser(_that.tempToken);case OtpVerifyResultExistingUser() when existingUser != null:
return existingUser(_that.tokens,_that.profile);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class OtpVerifyResultNewUser extends OtpVerifyResult {
  const OtpVerifyResultNewUser({required this.tempToken, final  String? $type}): $type = $type ?? 'new_user',super._();
  factory OtpVerifyResultNewUser.fromJson(Map<String, dynamic> json) => _$OtpVerifyResultNewUserFromJson(json);

 final  String tempToken;

@JsonKey(name: 'status')
final String $type;


/// Create a copy of OtpVerifyResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpVerifyResultNewUserCopyWith<OtpVerifyResultNewUser> get copyWith => _$OtpVerifyResultNewUserCopyWithImpl<OtpVerifyResultNewUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpVerifyResultNewUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpVerifyResultNewUser&&(identical(other.tempToken, tempToken) || other.tempToken == tempToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tempToken);

@override
String toString() {
  return 'OtpVerifyResult.newUser(tempToken: $tempToken)';
}


}

/// @nodoc
abstract mixin class $OtpVerifyResultNewUserCopyWith<$Res> implements $OtpVerifyResultCopyWith<$Res> {
  factory $OtpVerifyResultNewUserCopyWith(OtpVerifyResultNewUser value, $Res Function(OtpVerifyResultNewUser) _then) = _$OtpVerifyResultNewUserCopyWithImpl;
@useResult
$Res call({
 String tempToken
});




}
/// @nodoc
class _$OtpVerifyResultNewUserCopyWithImpl<$Res>
    implements $OtpVerifyResultNewUserCopyWith<$Res> {
  _$OtpVerifyResultNewUserCopyWithImpl(this._self, this._then);

  final OtpVerifyResultNewUser _self;
  final $Res Function(OtpVerifyResultNewUser) _then;

/// Create a copy of OtpVerifyResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tempToken = null,}) {
  return _then(OtpVerifyResultNewUser(
tempToken: null == tempToken ? _self.tempToken : tempToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class OtpVerifyResultExistingUser extends OtpVerifyResult {
  const OtpVerifyResultExistingUser({required this.tokens, required this.profile, final  String? $type}): $type = $type ?? 'existing_user',super._();
  factory OtpVerifyResultExistingUser.fromJson(Map<String, dynamic> json) => _$OtpVerifyResultExistingUserFromJson(json);

 final  AuthTokens tokens;
 final  AuthProfile profile;

@JsonKey(name: 'status')
final String $type;


/// Create a copy of OtpVerifyResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpVerifyResultExistingUserCopyWith<OtpVerifyResultExistingUser> get copyWith => _$OtpVerifyResultExistingUserCopyWithImpl<OtpVerifyResultExistingUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpVerifyResultExistingUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpVerifyResultExistingUser&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.profile, profile) || other.profile == profile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tokens,profile);

@override
String toString() {
  return 'OtpVerifyResult.existingUser(tokens: $tokens, profile: $profile)';
}


}

/// @nodoc
abstract mixin class $OtpVerifyResultExistingUserCopyWith<$Res> implements $OtpVerifyResultCopyWith<$Res> {
  factory $OtpVerifyResultExistingUserCopyWith(OtpVerifyResultExistingUser value, $Res Function(OtpVerifyResultExistingUser) _then) = _$OtpVerifyResultExistingUserCopyWithImpl;
@useResult
$Res call({
 AuthTokens tokens, AuthProfile profile
});


$AuthTokensCopyWith<$Res> get tokens;$AuthProfileCopyWith<$Res> get profile;

}
/// @nodoc
class _$OtpVerifyResultExistingUserCopyWithImpl<$Res>
    implements $OtpVerifyResultExistingUserCopyWith<$Res> {
  _$OtpVerifyResultExistingUserCopyWithImpl(this._self, this._then);

  final OtpVerifyResultExistingUser _self;
  final $Res Function(OtpVerifyResultExistingUser) _then;

/// Create a copy of OtpVerifyResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tokens = null,Object? profile = null,}) {
  return _then(OtpVerifyResultExistingUser(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AuthProfile,
  ));
}

/// Create a copy of OtpVerifyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}/// Create a copy of OtpVerifyResult
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
