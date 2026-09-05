// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthStateInitial value)?  initial,TResult Function( AuthStateLoading value)?  loading,TResult Function( AuthStateUnauthenticated value)?  unauthenticated,TResult Function( AuthStateMustChangePassword value)?  mustChangePassword,TResult Function( AuthStatePendingPinSetup value)?  pendingPinSetup,TResult Function( AuthStateAuthenticated value)?  authenticated,TResult Function( AuthStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthStateInitial() when initial != null:
return initial(_that);case AuthStateLoading() when loading != null:
return loading(_that);case AuthStateUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthStateMustChangePassword() when mustChangePassword != null:
return mustChangePassword(_that);case AuthStatePendingPinSetup() when pendingPinSetup != null:
return pendingPinSetup(_that);case AuthStateAuthenticated() when authenticated != null:
return authenticated(_that);case AuthStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthStateInitial value)  initial,required TResult Function( AuthStateLoading value)  loading,required TResult Function( AuthStateUnauthenticated value)  unauthenticated,required TResult Function( AuthStateMustChangePassword value)  mustChangePassword,required TResult Function( AuthStatePendingPinSetup value)  pendingPinSetup,required TResult Function( AuthStateAuthenticated value)  authenticated,required TResult Function( AuthStateError value)  error,}){
final _that = this;
switch (_that) {
case AuthStateInitial():
return initial(_that);case AuthStateLoading():
return loading(_that);case AuthStateUnauthenticated():
return unauthenticated(_that);case AuthStateMustChangePassword():
return mustChangePassword(_that);case AuthStatePendingPinSetup():
return pendingPinSetup(_that);case AuthStateAuthenticated():
return authenticated(_that);case AuthStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthStateInitial value)?  initial,TResult? Function( AuthStateLoading value)?  loading,TResult? Function( AuthStateUnauthenticated value)?  unauthenticated,TResult? Function( AuthStateMustChangePassword value)?  mustChangePassword,TResult? Function( AuthStatePendingPinSetup value)?  pendingPinSetup,TResult? Function( AuthStateAuthenticated value)?  authenticated,TResult? Function( AuthStateError value)?  error,}){
final _that = this;
switch (_that) {
case AuthStateInitial() when initial != null:
return initial(_that);case AuthStateLoading() when loading != null:
return loading(_that);case AuthStateUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthStateMustChangePassword() when mustChangePassword != null:
return mustChangePassword(_that);case AuthStatePendingPinSetup() when pendingPinSetup != null:
return pendingPinSetup(_that);case AuthStateAuthenticated() when authenticated != null:
return authenticated(_that);case AuthStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  unauthenticated,TResult Function( AuthTokens tokens,  String memberId)?  mustChangePassword,TResult Function( AuthTokens tokens,  String memberId)?  pendingPinSetup,TResult Function( AuthTokens tokens,  MemberProfile profile,  SectorInfo sector)?  authenticated,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthStateInitial() when initial != null:
return initial();case AuthStateLoading() when loading != null:
return loading();case AuthStateUnauthenticated() when unauthenticated != null:
return unauthenticated();case AuthStateMustChangePassword() when mustChangePassword != null:
return mustChangePassword(_that.tokens,_that.memberId);case AuthStatePendingPinSetup() when pendingPinSetup != null:
return pendingPinSetup(_that.tokens,_that.memberId);case AuthStateAuthenticated() when authenticated != null:
return authenticated(_that.tokens,_that.profile,_that.sector);case AuthStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  unauthenticated,required TResult Function( AuthTokens tokens,  String memberId)  mustChangePassword,required TResult Function( AuthTokens tokens,  String memberId)  pendingPinSetup,required TResult Function( AuthTokens tokens,  MemberProfile profile,  SectorInfo sector)  authenticated,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case AuthStateInitial():
return initial();case AuthStateLoading():
return loading();case AuthStateUnauthenticated():
return unauthenticated();case AuthStateMustChangePassword():
return mustChangePassword(_that.tokens,_that.memberId);case AuthStatePendingPinSetup():
return pendingPinSetup(_that.tokens,_that.memberId);case AuthStateAuthenticated():
return authenticated(_that.tokens,_that.profile,_that.sector);case AuthStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  unauthenticated,TResult? Function( AuthTokens tokens,  String memberId)?  mustChangePassword,TResult? Function( AuthTokens tokens,  String memberId)?  pendingPinSetup,TResult? Function( AuthTokens tokens,  MemberProfile profile,  SectorInfo sector)?  authenticated,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case AuthStateInitial() when initial != null:
return initial();case AuthStateLoading() when loading != null:
return loading();case AuthStateUnauthenticated() when unauthenticated != null:
return unauthenticated();case AuthStateMustChangePassword() when mustChangePassword != null:
return mustChangePassword(_that.tokens,_that.memberId);case AuthStatePendingPinSetup() when pendingPinSetup != null:
return pendingPinSetup(_that.tokens,_that.memberId);case AuthStateAuthenticated() when authenticated != null:
return authenticated(_that.tokens,_that.profile,_that.sector);case AuthStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class AuthStateInitial implements AuthState {
  const AuthStateInitial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthState.initial()';
}


}




/// @nodoc


class AuthStateLoading implements AuthState {
  const AuthStateLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthState.loading()';
}


}




/// @nodoc


class AuthStateUnauthenticated implements AuthState {
  const AuthStateUnauthenticated();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStateUnauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthState.unauthenticated()';
}


}




/// @nodoc


class AuthStateMustChangePassword implements AuthState {
  const AuthStateMustChangePassword({required this.tokens, required this.memberId});
  

 final  AuthTokens tokens;
 final  String memberId;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateMustChangePasswordCopyWith<AuthStateMustChangePassword> get copyWith => _$AuthStateMustChangePasswordCopyWithImpl<AuthStateMustChangePassword>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStateMustChangePassword&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.memberId, memberId) || other.memberId == memberId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tokens,memberId);
}

@override
String toString() {
    return 'AuthState.mustChangePassword(tokens: $tokens, memberId: $memberId)';
}


}

/// @nodoc
abstract mixin class $AuthStateMustChangePasswordCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthStateMustChangePasswordCopyWith(AuthStateMustChangePassword value, $Res Function(AuthStateMustChangePassword) _then) = _$AuthStateMustChangePasswordCopyWithImpl;
@useResult
$Res call({
 AuthTokens tokens, String memberId
});


$AuthTokensCopyWith<$Res> get tokens;

}
/// @nodoc
class _$AuthStateMustChangePasswordCopyWithImpl<$Res>
    implements $AuthStateMustChangePasswordCopyWith<$Res> {
  _$AuthStateMustChangePasswordCopyWithImpl(this._self, this._then);

  final AuthStateMustChangePassword _self;
  final $Res Function(AuthStateMustChangePassword) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tokens = null,Object? memberId = null,}) {
  return _then(AuthStateMustChangePassword(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}
}

/// @nodoc


class AuthStatePendingPinSetup implements AuthState {
  const AuthStatePendingPinSetup({required this.tokens, required this.memberId});
  

 final  AuthTokens tokens;
 final  String memberId;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStatePendingPinSetupCopyWith<AuthStatePendingPinSetup> get copyWith => _$AuthStatePendingPinSetupCopyWithImpl<AuthStatePendingPinSetup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStatePendingPinSetup&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.memberId, memberId) || other.memberId == memberId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tokens,memberId);
}

@override
String toString() {
    return 'AuthState.pendingPinSetup(tokens: $tokens, memberId: $memberId)';
}


}

/// @nodoc
abstract mixin class $AuthStatePendingPinSetupCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthStatePendingPinSetupCopyWith(AuthStatePendingPinSetup value, $Res Function(AuthStatePendingPinSetup) _then) = _$AuthStatePendingPinSetupCopyWithImpl;
@useResult
$Res call({
 AuthTokens tokens, String memberId
});


$AuthTokensCopyWith<$Res> get tokens;

}
/// @nodoc
class _$AuthStatePendingPinSetupCopyWithImpl<$Res>
    implements $AuthStatePendingPinSetupCopyWith<$Res> {
  _$AuthStatePendingPinSetupCopyWithImpl(this._self, this._then);

  final AuthStatePendingPinSetup _self;
  final $Res Function(AuthStatePendingPinSetup) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tokens = null,Object? memberId = null,}) {
  return _then(AuthStatePendingPinSetup(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}
}

/// @nodoc


class AuthStateAuthenticated implements AuthState {
  const AuthStateAuthenticated({required this.tokens, required this.profile, required this.sector});
  

 final  AuthTokens tokens;
 final  MemberProfile profile;
 final  SectorInfo sector;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateAuthenticatedCopyWith<AuthStateAuthenticated> get copyWith => _$AuthStateAuthenticatedCopyWithImpl<AuthStateAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStateAuthenticated&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.sector, sector) || other.sector == sector));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tokens,profile,sector);
}

@override
String toString() {
    return 'AuthState.authenticated(tokens: $tokens, profile: $profile, sector: $sector)';
}


}

/// @nodoc
abstract mixin class $AuthStateAuthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthStateAuthenticatedCopyWith(AuthStateAuthenticated value, $Res Function(AuthStateAuthenticated) _then) = _$AuthStateAuthenticatedCopyWithImpl;
@useResult
$Res call({
 AuthTokens tokens, MemberProfile profile, SectorInfo sector
});


$AuthTokensCopyWith<$Res> get tokens;$MemberProfileCopyWith<$Res> get profile;$SectorInfoCopyWith<$Res> get sector;

}
/// @nodoc
class _$AuthStateAuthenticatedCopyWithImpl<$Res>
    implements $AuthStateAuthenticatedCopyWith<$Res> {
  _$AuthStateAuthenticatedCopyWithImpl(this._self, this._then);

  final AuthStateAuthenticated _self;
  final $Res Function(AuthStateAuthenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tokens = null,Object? profile = null,Object? sector = null,}) {
  return _then(AuthStateAuthenticated(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as MemberProfile,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as SectorInfo,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberProfileCopyWith<$Res> get profile {
  
  return $MemberProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}/// Create a copy of AuthState
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


class AuthStateError implements AuthState {
  const AuthStateError(this.message);
  

 final  String message;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateErrorCopyWith<AuthStateError> get copyWith => _$AuthStateErrorCopyWithImpl<AuthStateError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'AuthState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $AuthStateErrorCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthStateErrorCopyWith(AuthStateError value, $Res Function(AuthStateError) _then) = _$AuthStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AuthStateErrorCopyWithImpl<$Res>
    implements $AuthStateErrorCopyWith<$Res> {
  _$AuthStateErrorCopyWithImpl(this._self, this._then);

  final AuthStateError _self;
  final $Res Function(AuthStateError) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AuthStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
