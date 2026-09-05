// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StateHistoryEntry {

 IssueState get state; DateTime get changedAt; String? get changedBy; String? get note;
/// Create a copy of StateHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StateHistoryEntryCopyWith<StateHistoryEntry> get copyWith => _$StateHistoryEntryCopyWithImpl<StateHistoryEntry>(this as StateHistoryEntry, _$identity);

  /// Serializes this StateHistoryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StateHistoryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StateHistoryEntry&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.changedAt, _this.changedAt) || other.changedAt == _this.changedAt)&&(identical(other.changedBy, _this.changedBy) || other.changedBy == _this.changedBy)&&(identical(other.note, _this.note) || other.note == _this.note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StateHistoryEntry;
  return Object.hash(runtimeType,_this.state,_this.changedAt,_this.changedBy,_this.note);
}

@override
String toString() {
  final _this = this as StateHistoryEntry;
  return 'StateHistoryEntry(state: ${_this.state}, changedAt: ${_this.changedAt}, changedBy: ${_this.changedBy}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $StateHistoryEntryCopyWith<$Res>  {
  factory $StateHistoryEntryCopyWith(StateHistoryEntry value, $Res Function(StateHistoryEntry) _then) = _$StateHistoryEntryCopyWithImpl;
@useResult
$Res call({
 IssueState state, DateTime changedAt, String? changedBy, String? note
});




}
/// @nodoc
class _$StateHistoryEntryCopyWithImpl<$Res>
    implements $StateHistoryEntryCopyWith<$Res> {
  _$StateHistoryEntryCopyWithImpl(this._self, this._then);

  final StateHistoryEntry _self;
  final $Res Function(StateHistoryEntry) _then;

/// Create a copy of StateHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? changedAt = null,Object? changedBy = freezed,Object? note = freezed,}) {
  return _then(StateHistoryEntry(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,changedBy: freezed == changedBy ? _self.changedBy : changedBy // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StateHistoryEntry].
extension StateHistoryEntryPatterns on StateHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StateHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StateHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StateHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _StateHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StateHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _StateHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IssueState state,  DateTime changedAt,  String? changedBy,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StateHistoryEntry() when $default != null:
return $default(_that.state,_that.changedAt,_that.changedBy,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IssueState state,  DateTime changedAt,  String? changedBy,  String? note)  $default,) {final _that = this;
switch (_that) {
case _StateHistoryEntry():
return $default(_that.state,_that.changedAt,_that.changedBy,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IssueState state,  DateTime changedAt,  String? changedBy,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _StateHistoryEntry() when $default != null:
return $default(_that.state,_that.changedAt,_that.changedBy,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StateHistoryEntry implements StateHistoryEntry {
  const _StateHistoryEntry({required this.state, required this.changedAt, this.changedBy, this.note});
  factory _StateHistoryEntry.fromJson(Map<String, dynamic> json) => _$StateHistoryEntryFromJson(json);

@override final  IssueState state;
@override final  DateTime changedAt;
@override final  String? changedBy;
@override final  String? note;

/// Create a copy of StateHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateHistoryEntryCopyWith<_StateHistoryEntry> get copyWith => __$StateHistoryEntryCopyWithImpl<_StateHistoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StateHistoryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateHistoryEntry&&(identical(other.state, state) || other.state == state)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt)&&(identical(other.changedBy, changedBy) || other.changedBy == changedBy)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,state,changedAt,changedBy,note);
}

@override
String toString() {
    return 'StateHistoryEntry(state: $state, changedAt: $changedAt, changedBy: $changedBy, note: $note)';
}


}

/// @nodoc
abstract mixin class _$StateHistoryEntryCopyWith<$Res> implements $StateHistoryEntryCopyWith<$Res> {
  factory _$StateHistoryEntryCopyWith(_StateHistoryEntry value, $Res Function(_StateHistoryEntry) _then) = __$StateHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 IssueState state, DateTime changedAt, String? changedBy, String? note
});




}
/// @nodoc
class __$StateHistoryEntryCopyWithImpl<$Res>
    implements _$StateHistoryEntryCopyWith<$Res> {
  __$StateHistoryEntryCopyWithImpl(this._self, this._then);

  final _StateHistoryEntry _self;
  final $Res Function(_StateHistoryEntry) _then;

/// Create a copy of StateHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? changedAt = null,Object? changedBy = freezed,Object? note = freezed,}) {
  return _then(_StateHistoryEntry(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as IssueState,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,changedBy: freezed == changedBy ? _self.changedBy : changedBy // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$IssueDetail {

 String get id; String get type; String get state; GeoPoint get location; String? get address; String? get description; int get heat; List<String> get photoUrls; String get sectorId; String get reporterId; int get reportCount; DateTime get createdAt; DateTime get updatedAt; List<StateHistoryEntry> get stateHistory;
/// Create a copy of IssueDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueDetailCopyWith<IssueDetail> get copyWith => _$IssueDetailCopyWithImpl<IssueDetail>(this as IssueDetail, _$identity);

  /// Serializes this IssueDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.heat, _this.heat) || other.heat == _this.heat)&&const DeepCollectionEquality().equals(other.photoUrls, _this.photoUrls)&&(identical(other.sectorId, _this.sectorId) || other.sectorId == _this.sectorId)&&(identical(other.reporterId, _this.reporterId) || other.reporterId == _this.reporterId)&&(identical(other.reportCount, _this.reportCount) || other.reportCount == _this.reportCount)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&const DeepCollectionEquality().equals(other.stateHistory, _this.stateHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueDetail;
  return Object.hash(runtimeType,_this.id,_this.type,_this.state,_this.location,_this.address,_this.description,_this.heat,const DeepCollectionEquality().hash(_this.photoUrls),_this.sectorId,_this.reporterId,_this.reportCount,_this.createdAt,_this.updatedAt,const DeepCollectionEquality().hash(_this.stateHistory));
}

@override
String toString() {
  final _this = this as IssueDetail;
  return 'IssueDetail(id: ${_this.id}, type: ${_this.type}, state: ${_this.state}, location: ${_this.location}, address: ${_this.address}, description: ${_this.description}, heat: ${_this.heat}, photoUrls: ${_this.photoUrls}, sectorId: ${_this.sectorId}, reporterId: ${_this.reporterId}, reportCount: ${_this.reportCount}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, stateHistory: ${_this.stateHistory})';
}


}

/// @nodoc
abstract mixin class $IssueDetailCopyWith<$Res>  {
  factory $IssueDetailCopyWith(IssueDetail value, $Res Function(IssueDetail) _then) = _$IssueDetailCopyWithImpl;
@useResult
$Res call({
 String id, String type, String state, GeoPoint location, String? address, String? description, int heat, List<String> photoUrls, String sectorId, String reporterId, int reportCount, DateTime createdAt, DateTime updatedAt, List<StateHistoryEntry> stateHistory
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$IssueDetailCopyWithImpl<$Res>
    implements $IssueDetailCopyWith<$Res> {
  _$IssueDetailCopyWithImpl(this._self, this._then);

  final IssueDetail _self;
  final $Res Function(IssueDetail) _then;

/// Create a copy of IssueDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? address = freezed,Object? description = freezed,Object? heat = null,Object? photoUrls = null,Object? sectorId = null,Object? reporterId = null,Object? reportCount = null,Object? createdAt = null,Object? updatedAt = null,Object? stateHistory = null,}) {
  return _then(IssueDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,photoUrls: null == photoUrls ? _self.photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,stateHistory: null == stateHistory ? _self.stateHistory : stateHistory // ignore: cast_nullable_to_non_nullable
as List<StateHistoryEntry>,
  ));
}
/// Create a copy of IssueDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssueDetail].
extension IssueDetailPatterns on IssueDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueDetail value)  $default,){
final _that = this;
switch (_that) {
case _IssueDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueDetail value)?  $default,){
final _that = this;
switch (_that) {
case _IssueDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String state,  GeoPoint location,  String? address,  String? description,  int heat,  List<String> photoUrls,  String sectorId,  String reporterId,  int reportCount,  DateTime createdAt,  DateTime updatedAt,  List<StateHistoryEntry> stateHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueDetail() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.address,_that.description,_that.heat,_that.photoUrls,_that.sectorId,_that.reporterId,_that.reportCount,_that.createdAt,_that.updatedAt,_that.stateHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String state,  GeoPoint location,  String? address,  String? description,  int heat,  List<String> photoUrls,  String sectorId,  String reporterId,  int reportCount,  DateTime createdAt,  DateTime updatedAt,  List<StateHistoryEntry> stateHistory)  $default,) {final _that = this;
switch (_that) {
case _IssueDetail():
return $default(_that.id,_that.type,_that.state,_that.location,_that.address,_that.description,_that.heat,_that.photoUrls,_that.sectorId,_that.reporterId,_that.reportCount,_that.createdAt,_that.updatedAt,_that.stateHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String state,  GeoPoint location,  String? address,  String? description,  int heat,  List<String> photoUrls,  String sectorId,  String reporterId,  int reportCount,  DateTime createdAt,  DateTime updatedAt,  List<StateHistoryEntry> stateHistory)?  $default,) {final _that = this;
switch (_that) {
case _IssueDetail() when $default != null:
return $default(_that.id,_that.type,_that.state,_that.location,_that.address,_that.description,_that.heat,_that.photoUrls,_that.sectorId,_that.reporterId,_that.reportCount,_that.createdAt,_that.updatedAt,_that.stateHistory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueDetail extends IssueDetail {
  const _IssueDetail({required this.id, required this.type, required this.state, required this.location, this.address, this.description, required this.heat, required  List<String> photoUrls, required this.sectorId, required this.reporterId, required this.reportCount, required this.createdAt, required this.updatedAt,  List<StateHistoryEntry> stateHistory = const []}): _photoUrls = photoUrls,_stateHistory = stateHistory,super._();
  factory _IssueDetail.fromJson(Map<String, dynamic> json) => _$IssueDetailFromJson(json);

@override final  String id;
@override final  String type;
@override final  String state;
@override final  GeoPoint location;
@override final  String? address;
@override final  String? description;
@override final  int heat;
 final  List<String> _photoUrls;
@override List<String> get photoUrls {
  if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoUrls);
}

@override final  String sectorId;
@override final  String reporterId;
@override final  int reportCount;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
 final  List<StateHistoryEntry> _stateHistory;
@override@JsonKey() List<StateHistoryEntry> get stateHistory {
  if (_stateHistory is EqualUnmodifiableListView) return _stateHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stateHistory);
}


/// Create a copy of IssueDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueDetailCopyWith<_IssueDetail> get copyWith => __$IssueDetailCopyWithImpl<_IssueDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.state, state) || other.state == state)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.heat, heat) || other.heat == heat)&&const DeepCollectionEquality().equals(other.photoUrls, _photoUrls)&&(identical(other.sectorId, sectorId) || other.sectorId == sectorId)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.stateHistory, _stateHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,state,location,address,description,heat,const DeepCollectionEquality().hash(_photoUrls),sectorId,reporterId,reportCount,createdAt,updatedAt,const DeepCollectionEquality().hash(_stateHistory));
}

@override
String toString() {
    return 'IssueDetail(id: $id, type: $type, state: $state, location: $location, address: $address, description: $description, heat: $heat, photoUrls: $photoUrls, sectorId: $sectorId, reporterId: $reporterId, reportCount: $reportCount, createdAt: $createdAt, updatedAt: $updatedAt, stateHistory: $stateHistory)';
}


}

/// @nodoc
abstract mixin class _$IssueDetailCopyWith<$Res> implements $IssueDetailCopyWith<$Res> {
  factory _$IssueDetailCopyWith(_IssueDetail value, $Res Function(_IssueDetail) _then) = __$IssueDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String state, GeoPoint location, String? address, String? description, int heat, List<String> photoUrls, String sectorId, String reporterId, int reportCount, DateTime createdAt, DateTime updatedAt, List<StateHistoryEntry> stateHistory
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$IssueDetailCopyWithImpl<$Res>
    implements _$IssueDetailCopyWith<$Res> {
  __$IssueDetailCopyWithImpl(this._self, this._then);

  final _IssueDetail _self;
  final $Res Function(_IssueDetail) _then;

/// Create a copy of IssueDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? state = null,Object? location = null,Object? address = freezed,Object? description = freezed,Object? heat = null,Object? photoUrls = null,Object? sectorId = null,Object? reporterId = null,Object? reportCount = null,Object? createdAt = null,Object? updatedAt = null,Object? stateHistory = null,}) {
  return _then(_IssueDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,heat: null == heat ? _self.heat : heat // ignore: cast_nullable_to_non_nullable
as int,photoUrls: null == photoUrls ? _self._photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sectorId: null == sectorId ? _self.sectorId : sectorId // ignore: cast_nullable_to_non_nullable
as String,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,stateHistory: null == stateHistory ? _self._stateHistory : stateHistory // ignore: cast_nullable_to_non_nullable
as List<StateHistoryEntry>,
  ));
}

/// Create a copy of IssueDetail
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
