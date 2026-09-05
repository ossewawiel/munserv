// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pod_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PodConfig {

 String get podId; String get podName; String get primaryColor; String get secondaryColor; String? get tertiaryColor; String? get logoUrl; String? get fontFamily; List<String> get supportedLocales; String get defaultLocale;
/// Create a copy of PodConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodConfigCopyWith<PodConfig> get copyWith => _$PodConfigCopyWithImpl<PodConfig>(this as PodConfig, _$identity);

  /// Serializes this PodConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PodConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PodConfig&&(identical(other.podId, _this.podId) || other.podId == _this.podId)&&(identical(other.podName, _this.podName) || other.podName == _this.podName)&&(identical(other.primaryColor, _this.primaryColor) || other.primaryColor == _this.primaryColor)&&(identical(other.secondaryColor, _this.secondaryColor) || other.secondaryColor == _this.secondaryColor)&&(identical(other.tertiaryColor, _this.tertiaryColor) || other.tertiaryColor == _this.tertiaryColor)&&(identical(other.logoUrl, _this.logoUrl) || other.logoUrl == _this.logoUrl)&&(identical(other.fontFamily, _this.fontFamily) || other.fontFamily == _this.fontFamily)&&const DeepCollectionEquality().equals(other.supportedLocales, _this.supportedLocales)&&(identical(other.defaultLocale, _this.defaultLocale) || other.defaultLocale == _this.defaultLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PodConfig;
  return Object.hash(runtimeType,_this.podId,_this.podName,_this.primaryColor,_this.secondaryColor,_this.tertiaryColor,_this.logoUrl,_this.fontFamily,const DeepCollectionEquality().hash(_this.supportedLocales),_this.defaultLocale);
}

@override
String toString() {
  final _this = this as PodConfig;
  return 'PodConfig(podId: ${_this.podId}, podName: ${_this.podName}, primaryColor: ${_this.primaryColor}, secondaryColor: ${_this.secondaryColor}, tertiaryColor: ${_this.tertiaryColor}, logoUrl: ${_this.logoUrl}, fontFamily: ${_this.fontFamily}, supportedLocales: ${_this.supportedLocales}, defaultLocale: ${_this.defaultLocale})';
}


}

/// @nodoc
abstract mixin class $PodConfigCopyWith<$Res>  {
  factory $PodConfigCopyWith(PodConfig value, $Res Function(PodConfig) _then) = _$PodConfigCopyWithImpl;
@useResult
$Res call({
 String podId, String podName, String primaryColor, String secondaryColor, String? tertiaryColor, String? logoUrl, String? fontFamily, List<String> supportedLocales, String defaultLocale
});




}
/// @nodoc
class _$PodConfigCopyWithImpl<$Res>
    implements $PodConfigCopyWith<$Res> {
  _$PodConfigCopyWithImpl(this._self, this._then);

  final PodConfig _self;
  final $Res Function(PodConfig) _then;

/// Create a copy of PodConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? podId = null,Object? podName = null,Object? primaryColor = null,Object? secondaryColor = null,Object? tertiaryColor = freezed,Object? logoUrl = freezed,Object? fontFamily = freezed,Object? supportedLocales = null,Object? defaultLocale = null,}) {
  return _then(PodConfig(
podId: null == podId ? _self.podId : podId // ignore: cast_nullable_to_non_nullable
as String,podName: null == podName ? _self.podName : podName // ignore: cast_nullable_to_non_nullable
as String,primaryColor: null == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String,secondaryColor: null == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String,tertiaryColor: freezed == tertiaryColor ? _self.tertiaryColor : tertiaryColor // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,supportedLocales: null == supportedLocales ? _self.supportedLocales : supportedLocales // ignore: cast_nullable_to_non_nullable
as List<String>,defaultLocale: null == defaultLocale ? _self.defaultLocale : defaultLocale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PodConfig].
extension PodConfigPatterns on PodConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PodConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PodConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PodConfig value)  $default,){
final _that = this;
switch (_that) {
case _PodConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PodConfig value)?  $default,){
final _that = this;
switch (_that) {
case _PodConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String podId,  String podName,  String primaryColor,  String secondaryColor,  String? tertiaryColor,  String? logoUrl,  String? fontFamily,  List<String> supportedLocales,  String defaultLocale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PodConfig() when $default != null:
return $default(_that.podId,_that.podName,_that.primaryColor,_that.secondaryColor,_that.tertiaryColor,_that.logoUrl,_that.fontFamily,_that.supportedLocales,_that.defaultLocale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String podId,  String podName,  String primaryColor,  String secondaryColor,  String? tertiaryColor,  String? logoUrl,  String? fontFamily,  List<String> supportedLocales,  String defaultLocale)  $default,) {final _that = this;
switch (_that) {
case _PodConfig():
return $default(_that.podId,_that.podName,_that.primaryColor,_that.secondaryColor,_that.tertiaryColor,_that.logoUrl,_that.fontFamily,_that.supportedLocales,_that.defaultLocale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String podId,  String podName,  String primaryColor,  String secondaryColor,  String? tertiaryColor,  String? logoUrl,  String? fontFamily,  List<String> supportedLocales,  String defaultLocale)?  $default,) {final _that = this;
switch (_that) {
case _PodConfig() when $default != null:
return $default(_that.podId,_that.podName,_that.primaryColor,_that.secondaryColor,_that.tertiaryColor,_that.logoUrl,_that.fontFamily,_that.supportedLocales,_that.defaultLocale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PodConfig extends PodConfig {
  const _PodConfig({required this.podId, required this.podName, required this.primaryColor, required this.secondaryColor, this.tertiaryColor, this.logoUrl, this.fontFamily,  List<String> supportedLocales = const ['en'], this.defaultLocale = 'en'}): _supportedLocales = supportedLocales,super._();
  factory _PodConfig.fromJson(Map<String, dynamic> json) => _$PodConfigFromJson(json);

@override final  String podId;
@override final  String podName;
@override final  String primaryColor;
@override final  String secondaryColor;
@override final  String? tertiaryColor;
@override final  String? logoUrl;
@override final  String? fontFamily;
 final  List<String> _supportedLocales;
@override@JsonKey() List<String> get supportedLocales {
  if (_supportedLocales is EqualUnmodifiableListView) return _supportedLocales;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedLocales);
}

@override@JsonKey() final  String defaultLocale;

/// Create a copy of PodConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PodConfigCopyWith<_PodConfig> get copyWith => __$PodConfigCopyWithImpl<_PodConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PodConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PodConfig&&(identical(other.podId, podId) || other.podId == podId)&&(identical(other.podName, podName) || other.podName == podName)&&(identical(other.primaryColor, primaryColor) || other.primaryColor == primaryColor)&&(identical(other.secondaryColor, secondaryColor) || other.secondaryColor == secondaryColor)&&(identical(other.tertiaryColor, tertiaryColor) || other.tertiaryColor == tertiaryColor)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&const DeepCollectionEquality().equals(other.supportedLocales, _supportedLocales)&&(identical(other.defaultLocale, defaultLocale) || other.defaultLocale == defaultLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,podId,podName,primaryColor,secondaryColor,tertiaryColor,logoUrl,fontFamily,const DeepCollectionEquality().hash(_supportedLocales),defaultLocale);
}

@override
String toString() {
    return 'PodConfig(podId: $podId, podName: $podName, primaryColor: $primaryColor, secondaryColor: $secondaryColor, tertiaryColor: $tertiaryColor, logoUrl: $logoUrl, fontFamily: $fontFamily, supportedLocales: $supportedLocales, defaultLocale: $defaultLocale)';
}


}

/// @nodoc
abstract mixin class _$PodConfigCopyWith<$Res> implements $PodConfigCopyWith<$Res> {
  factory _$PodConfigCopyWith(_PodConfig value, $Res Function(_PodConfig) _then) = __$PodConfigCopyWithImpl;
@override @useResult
$Res call({
 String podId, String podName, String primaryColor, String secondaryColor, String? tertiaryColor, String? logoUrl, String? fontFamily, List<String> supportedLocales, String defaultLocale
});




}
/// @nodoc
class __$PodConfigCopyWithImpl<$Res>
    implements _$PodConfigCopyWith<$Res> {
  __$PodConfigCopyWithImpl(this._self, this._then);

  final _PodConfig _self;
  final $Res Function(_PodConfig) _then;

/// Create a copy of PodConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? podId = null,Object? podName = null,Object? primaryColor = null,Object? secondaryColor = null,Object? tertiaryColor = freezed,Object? logoUrl = freezed,Object? fontFamily = freezed,Object? supportedLocales = null,Object? defaultLocale = null,}) {
  return _then(_PodConfig(
podId: null == podId ? _self.podId : podId // ignore: cast_nullable_to_non_nullable
as String,podName: null == podName ? _self.podName : podName // ignore: cast_nullable_to_non_nullable
as String,primaryColor: null == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String,secondaryColor: null == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String,tertiaryColor: freezed == tertiaryColor ? _self.tertiaryColor : tertiaryColor // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,supportedLocales: null == supportedLocales ? _self._supportedLocales : supportedLocales // ignore: cast_nullable_to_non_nullable
as List<String>,defaultLocale: null == defaultLocale ? _self.defaultLocale : defaultLocale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
