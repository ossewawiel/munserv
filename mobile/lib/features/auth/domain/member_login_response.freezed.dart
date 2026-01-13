// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_login_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberLoginResponse {

 String get memberId; String get accessToken; String get refreshToken; int get expiresIn; bool get mustChangePassword;
/// Create a copy of MemberLoginResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberLoginResponseCopyWith<MemberLoginResponse> get copyWith => _$MemberLoginResponseCopyWithImpl<MemberLoginResponse>(this as MemberLoginResponse, _$identity);

  /// Serializes this MemberLoginResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberLoginResponse&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.mustChangePassword, mustChangePassword) || other.mustChangePassword == mustChangePassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,accessToken,refreshToken,expiresIn,mustChangePassword);

@override
String toString() {
  return 'MemberLoginResponse(memberId: $memberId, accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, mustChangePassword: $mustChangePassword)';
}


}

/// @nodoc
abstract mixin class $MemberLoginResponseCopyWith<$Res>  {
  factory $MemberLoginResponseCopyWith(MemberLoginResponse value, $Res Function(MemberLoginResponse) _then) = _$MemberLoginResponseCopyWithImpl;
@useResult
$Res call({
 String memberId, String accessToken, String refreshToken, int expiresIn, bool mustChangePassword
});




}
/// @nodoc
class _$MemberLoginResponseCopyWithImpl<$Res>
    implements $MemberLoginResponseCopyWith<$Res> {
  _$MemberLoginResponseCopyWithImpl(this._self, this._then);

  final MemberLoginResponse _self;
  final $Res Function(MemberLoginResponse) _then;

/// Create a copy of MemberLoginResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberId = null,Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? mustChangePassword = null,}) {
  return _then(_self.copyWith(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,mustChangePassword: null == mustChangePassword ? _self.mustChangePassword : mustChangePassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberLoginResponse].
extension MemberLoginResponsePatterns on MemberLoginResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberLoginResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberLoginResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberLoginResponse value)  $default,){
final _that = this;
switch (_that) {
case _MemberLoginResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberLoginResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MemberLoginResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String memberId,  String accessToken,  String refreshToken,  int expiresIn,  bool mustChangePassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberLoginResponse() when $default != null:
return $default(_that.memberId,_that.accessToken,_that.refreshToken,_that.expiresIn,_that.mustChangePassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String memberId,  String accessToken,  String refreshToken,  int expiresIn,  bool mustChangePassword)  $default,) {final _that = this;
switch (_that) {
case _MemberLoginResponse():
return $default(_that.memberId,_that.accessToken,_that.refreshToken,_that.expiresIn,_that.mustChangePassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String memberId,  String accessToken,  String refreshToken,  int expiresIn,  bool mustChangePassword)?  $default,) {final _that = this;
switch (_that) {
case _MemberLoginResponse() when $default != null:
return $default(_that.memberId,_that.accessToken,_that.refreshToken,_that.expiresIn,_that.mustChangePassword);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberLoginResponse implements MemberLoginResponse {
  const _MemberLoginResponse({required this.memberId, required this.accessToken, required this.refreshToken, required this.expiresIn, required this.mustChangePassword});
  factory _MemberLoginResponse.fromJson(Map<String, dynamic> json) => _$MemberLoginResponseFromJson(json);

@override final  String memberId;
@override final  String accessToken;
@override final  String refreshToken;
@override final  int expiresIn;
@override final  bool mustChangePassword;

/// Create a copy of MemberLoginResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberLoginResponseCopyWith<_MemberLoginResponse> get copyWith => __$MemberLoginResponseCopyWithImpl<_MemberLoginResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberLoginResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberLoginResponse&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.mustChangePassword, mustChangePassword) || other.mustChangePassword == mustChangePassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,accessToken,refreshToken,expiresIn,mustChangePassword);

@override
String toString() {
  return 'MemberLoginResponse(memberId: $memberId, accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, mustChangePassword: $mustChangePassword)';
}


}

/// @nodoc
abstract mixin class _$MemberLoginResponseCopyWith<$Res> implements $MemberLoginResponseCopyWith<$Res> {
  factory _$MemberLoginResponseCopyWith(_MemberLoginResponse value, $Res Function(_MemberLoginResponse) _then) = __$MemberLoginResponseCopyWithImpl;
@override @useResult
$Res call({
 String memberId, String accessToken, String refreshToken, int expiresIn, bool mustChangePassword
});




}
/// @nodoc
class __$MemberLoginResponseCopyWithImpl<$Res>
    implements _$MemberLoginResponseCopyWith<$Res> {
  __$MemberLoginResponseCopyWithImpl(this._self, this._then);

  final _MemberLoginResponse _self;
  final $Res Function(_MemberLoginResponse) _then;

/// Create a copy of MemberLoginResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? mustChangePassword = null,}) {
  return _then(_MemberLoginResponse(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,mustChangePassword: null == mustChangePassword ? _self.mustChangePassword : mustChangePassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
