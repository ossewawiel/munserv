// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sector.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Sector {

 String get id; String get name; GeoPoint get center;
/// Create a copy of Sector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectorCopyWith<Sector> get copyWith => _$SectorCopyWithImpl<Sector>(this as Sector, _$identity);

  /// Serializes this Sector to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Sector;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sector&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.center, _this.center) || other.center == _this.center));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Sector;
  return Object.hash(runtimeType,_this.id,_this.name,_this.center);
}

@override
String toString() {
  final _this = this as Sector;
  return 'Sector(id: ${_this.id}, name: ${_this.name}, center: ${_this.center})';
}


}

/// @nodoc
abstract mixin class $SectorCopyWith<$Res>  {
  factory $SectorCopyWith(Sector value, $Res Function(Sector) _then) = _$SectorCopyWithImpl;
@useResult
$Res call({
 String id, String name, GeoPoint center
});


$GeoPointCopyWith<$Res> get center;

}
/// @nodoc
class _$SectorCopyWithImpl<$Res>
    implements $SectorCopyWith<$Res> {
  _$SectorCopyWithImpl(this._self, this._then);

  final Sector _self;
  final $Res Function(Sector) _then;

/// Create a copy of Sector
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? center = null,}) {
  return _then(Sector(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,
  ));
}
/// Create a copy of Sector
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get center {
  
  return $GeoPointCopyWith<$Res>(_self.center, (value) {
    return _then(_self.copyWith(center: value));
  });
}
}


/// Adds pattern-matching-related methods to [Sector].
extension SectorPatterns on Sector {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sector value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sector() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sector value)  $default,){
final _that = this;
switch (_that) {
case _Sector():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sector value)?  $default,){
final _that = this;
switch (_that) {
case _Sector() when $default != null:
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
case _Sector() when $default != null:
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
case _Sector():
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
case _Sector() when $default != null:
return $default(_that.id,_that.name,_that.center);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sector implements Sector {
  const _Sector({required this.id, required this.name, required this.center});
  factory _Sector.fromJson(Map<String, dynamic> json) => _$SectorFromJson(json);

@override final  String id;
@override final  String name;
@override final  GeoPoint center;

/// Create a copy of Sector
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SectorCopyWith<_Sector> get copyWith => __$SectorCopyWithImpl<_Sector>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SectorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sector&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.center, center) || other.center == center));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,center);
}

@override
String toString() {
    return 'Sector(id: $id, name: $name, center: $center)';
}


}

/// @nodoc
abstract mixin class _$SectorCopyWith<$Res> implements $SectorCopyWith<$Res> {
  factory _$SectorCopyWith(_Sector value, $Res Function(_Sector) _then) = __$SectorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, GeoPoint center
});


@override $GeoPointCopyWith<$Res> get center;

}
/// @nodoc
class __$SectorCopyWithImpl<$Res>
    implements _$SectorCopyWith<$Res> {
  __$SectorCopyWithImpl(this._self, this._then);

  final _Sector _self;
  final $Res Function(_Sector) _then;

/// Create a copy of Sector
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? center = null,}) {
  return _then(_Sector(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,
  ));
}

/// Create a copy of Sector
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get center {
  
  return $GeoPointCopyWith<$Res>(_self.center, (value) {
    return _then(_self.copyWith(center: value));
  });
}
}

// dart format on
