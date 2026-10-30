// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'demo_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DemoAccount {

 DemoAccountGroup get group; String get name; String get email; String get password;
/// Create a copy of DemoAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DemoAccountCopyWith<DemoAccount> get copyWith => _$DemoAccountCopyWithImpl<DemoAccount>(this as DemoAccount, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DemoAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DemoAccount&&(identical(other.group, _this.group) || other.group == _this.group)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.password, _this.password) || other.password == _this.password));
}


@override
int get hashCode {
  final _this = this as DemoAccount;
  return Object.hash(runtimeType,_this.group,_this.name,_this.email,_this.password);
}

@override
String toString() {
  final _this = this as DemoAccount;
  return 'DemoAccount(group: ${_this.group}, name: ${_this.name}, email: ${_this.email}, password: ${_this.password})';
}


}

/// @nodoc
abstract mixin class $DemoAccountCopyWith<$Res>  {
  factory $DemoAccountCopyWith(DemoAccount value, $Res Function(DemoAccount) _then) = _$DemoAccountCopyWithImpl;
@useResult
$Res call({
 DemoAccountGroup group, String name, String email, String password
});




}
/// @nodoc
class _$DemoAccountCopyWithImpl<$Res>
    implements $DemoAccountCopyWith<$Res> {
  _$DemoAccountCopyWithImpl(this._self, this._then);

  final DemoAccount _self;
  final $Res Function(DemoAccount) _then;

/// Create a copy of DemoAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = null,Object? name = null,Object? email = null,Object? password = null,}) {
  return _then(DemoAccount(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as DemoAccountGroup,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DemoAccount].
extension DemoAccountPatterns on DemoAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DemoAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DemoAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DemoAccount value)  $default,){
final _that = this;
switch (_that) {
case _DemoAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DemoAccount value)?  $default,){
final _that = this;
switch (_that) {
case _DemoAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DemoAccountGroup group,  String name,  String email,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DemoAccount() when $default != null:
return $default(_that.group,_that.name,_that.email,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DemoAccountGroup group,  String name,  String email,  String password)  $default,) {final _that = this;
switch (_that) {
case _DemoAccount():
return $default(_that.group,_that.name,_that.email,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DemoAccountGroup group,  String name,  String email,  String password)?  $default,) {final _that = this;
switch (_that) {
case _DemoAccount() when $default != null:
return $default(_that.group,_that.name,_that.email,_that.password);case _:
  return null;

}
}

}

/// @nodoc


class _DemoAccount extends DemoAccount {
  const _DemoAccount({required this.group, required this.name, required this.email, required this.password}): super._();
  

@override final  DemoAccountGroup group;
@override final  String name;
@override final  String email;
@override final  String password;

/// Create a copy of DemoAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DemoAccountCopyWith<_DemoAccount> get copyWith => __$DemoAccountCopyWithImpl<_DemoAccount>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DemoAccount&&(identical(other.group, group) || other.group == group)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode {
    return Object.hash(runtimeType,group,name,email,password);
}

@override
String toString() {
    return 'DemoAccount(group: $group, name: $name, email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class _$DemoAccountCopyWith<$Res> implements $DemoAccountCopyWith<$Res> {
  factory _$DemoAccountCopyWith(_DemoAccount value, $Res Function(_DemoAccount) _then) = __$DemoAccountCopyWithImpl;
@override @useResult
$Res call({
 DemoAccountGroup group, String name, String email, String password
});




}
/// @nodoc
class __$DemoAccountCopyWithImpl<$Res>
    implements _$DemoAccountCopyWith<$Res> {
  __$DemoAccountCopyWithImpl(this._self, this._then);

  final _DemoAccount _self;
  final $Res Function(_DemoAccount) _then;

/// Create a copy of DemoAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = null,Object? name = null,Object? email = null,Object? password = null,}) {
  return _then(_DemoAccount(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as DemoAccountGroup,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
