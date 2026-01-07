// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_phone_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckPhoneResponse {

 bool get isRegistered;
/// Create a copy of CheckPhoneResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckPhoneResponseCopyWith<CheckPhoneResponse> get copyWith => _$CheckPhoneResponseCopyWithImpl<CheckPhoneResponse>(this as CheckPhoneResponse, _$identity);

  /// Serializes this CheckPhoneResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckPhoneResponse&&(identical(other.isRegistered, isRegistered) || other.isRegistered == isRegistered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isRegistered);

@override
String toString() {
  return 'CheckPhoneResponse(isRegistered: $isRegistered)';
}


}

/// @nodoc
abstract mixin class $CheckPhoneResponseCopyWith<$Res>  {
  factory $CheckPhoneResponseCopyWith(CheckPhoneResponse value, $Res Function(CheckPhoneResponse) _then) = _$CheckPhoneResponseCopyWithImpl;
@useResult
$Res call({
 bool isRegistered
});




}
/// @nodoc
class _$CheckPhoneResponseCopyWithImpl<$Res>
    implements $CheckPhoneResponseCopyWith<$Res> {
  _$CheckPhoneResponseCopyWithImpl(this._self, this._then);

  final CheckPhoneResponse _self;
  final $Res Function(CheckPhoneResponse) _then;

/// Create a copy of CheckPhoneResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRegistered = null,}) {
  return _then(_self.copyWith(
isRegistered: null == isRegistered ? _self.isRegistered : isRegistered // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckPhoneResponse].
extension CheckPhoneResponsePatterns on CheckPhoneResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckPhoneResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckPhoneResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckPhoneResponse value)  $default,){
final _that = this;
switch (_that) {
case _CheckPhoneResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckPhoneResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CheckPhoneResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRegistered)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckPhoneResponse() when $default != null:
return $default(_that.isRegistered);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRegistered)  $default,) {final _that = this;
switch (_that) {
case _CheckPhoneResponse():
return $default(_that.isRegistered);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRegistered)?  $default,) {final _that = this;
switch (_that) {
case _CheckPhoneResponse() when $default != null:
return $default(_that.isRegistered);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckPhoneResponse implements CheckPhoneResponse {
  const _CheckPhoneResponse({required this.isRegistered});
  factory _CheckPhoneResponse.fromJson(Map<String, dynamic> json) => _$CheckPhoneResponseFromJson(json);

@override final  bool isRegistered;

/// Create a copy of CheckPhoneResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckPhoneResponseCopyWith<_CheckPhoneResponse> get copyWith => __$CheckPhoneResponseCopyWithImpl<_CheckPhoneResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckPhoneResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckPhoneResponse&&(identical(other.isRegistered, isRegistered) || other.isRegistered == isRegistered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isRegistered);

@override
String toString() {
  return 'CheckPhoneResponse(isRegistered: $isRegistered)';
}


}

/// @nodoc
abstract mixin class _$CheckPhoneResponseCopyWith<$Res> implements $CheckPhoneResponseCopyWith<$Res> {
  factory _$CheckPhoneResponseCopyWith(_CheckPhoneResponse value, $Res Function(_CheckPhoneResponse) _then) = __$CheckPhoneResponseCopyWithImpl;
@override @useResult
$Res call({
 bool isRegistered
});




}
/// @nodoc
class __$CheckPhoneResponseCopyWithImpl<$Res>
    implements _$CheckPhoneResponseCopyWith<$Res> {
  __$CheckPhoneResponseCopyWithImpl(this._self, this._then);

  final _CheckPhoneResponse _self;
  final $Res Function(_CheckPhoneResponse) _then;

/// Create a copy of CheckPhoneResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRegistered = null,}) {
  return _then(_CheckPhoneResponse(
isRegistered: null == isRegistered ? _self.isRegistered : isRegistered // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
