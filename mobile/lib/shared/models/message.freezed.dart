// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Message {

 String get id; MessageType get type; String get title; String get body; String get recipientId; String get recipientType; String? get senderId; String? get senderType; MessageStatus get status; String? get actionType; String? get relatedEntityId; String? get relatedEntityType; String? get actionResult; Map<String, dynamic>? get metadata; DateTime get createdAt; DateTime? get readAt; DateTime? get actionedAt; DateTime? get expiresAt;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.recipientType, recipientType) || other.recipientType == recipientType)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderType, senderType) || other.senderType == senderType)&&(identical(other.status, status) || other.status == status)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.relatedEntityId, relatedEntityId) || other.relatedEntityId == relatedEntityId)&&(identical(other.relatedEntityType, relatedEntityType) || other.relatedEntityType == relatedEntityType)&&(identical(other.actionResult, actionResult) || other.actionResult == actionResult)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.actionedAt, actionedAt) || other.actionedAt == actionedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,body,recipientId,recipientType,senderId,senderType,status,actionType,relatedEntityId,relatedEntityType,actionResult,const DeepCollectionEquality().hash(metadata),createdAt,readAt,actionedAt,expiresAt);

@override
String toString() {
  return 'Message(id: $id, type: $type, title: $title, body: $body, recipientId: $recipientId, recipientType: $recipientType, senderId: $senderId, senderType: $senderType, status: $status, actionType: $actionType, relatedEntityId: $relatedEntityId, relatedEntityType: $relatedEntityType, actionResult: $actionResult, metadata: $metadata, createdAt: $createdAt, readAt: $readAt, actionedAt: $actionedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, MessageType type, String title, String body, String recipientId, String recipientType, String? senderId, String? senderType, MessageStatus status, String? actionType, String? relatedEntityId, String? relatedEntityType, String? actionResult, Map<String, dynamic>? metadata, DateTime createdAt, DateTime? readAt, DateTime? actionedAt, DateTime? expiresAt
});




}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? recipientId = null,Object? recipientType = null,Object? senderId = freezed,Object? senderType = freezed,Object? status = null,Object? actionType = freezed,Object? relatedEntityId = freezed,Object? relatedEntityType = freezed,Object? actionResult = freezed,Object? metadata = freezed,Object? createdAt = null,Object? readAt = freezed,Object? actionedAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,recipientType: null == recipientType ? _self.recipientType : recipientType // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,senderType: freezed == senderType ? _self.senderType : senderType // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,actionType: freezed == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String?,relatedEntityId: freezed == relatedEntityId ? _self.relatedEntityId : relatedEntityId // ignore: cast_nullable_to_non_nullable
as String?,relatedEntityType: freezed == relatedEntityType ? _self.relatedEntityType : relatedEntityType // ignore: cast_nullable_to_non_nullable
as String?,actionResult: freezed == actionResult ? _self.actionResult : actionResult // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,actionedAt: freezed == actionedAt ? _self.actionedAt : actionedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MessageType type,  String title,  String body,  String recipientId,  String recipientType,  String? senderId,  String? senderType,  MessageStatus status,  String? actionType,  String? relatedEntityId,  String? relatedEntityType,  String? actionResult,  Map<String, dynamic>? metadata,  DateTime createdAt,  DateTime? readAt,  DateTime? actionedAt,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.recipientId,_that.recipientType,_that.senderId,_that.senderType,_that.status,_that.actionType,_that.relatedEntityId,_that.relatedEntityType,_that.actionResult,_that.metadata,_that.createdAt,_that.readAt,_that.actionedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MessageType type,  String title,  String body,  String recipientId,  String recipientType,  String? senderId,  String? senderType,  MessageStatus status,  String? actionType,  String? relatedEntityId,  String? relatedEntityType,  String? actionResult,  Map<String, dynamic>? metadata,  DateTime createdAt,  DateTime? readAt,  DateTime? actionedAt,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.type,_that.title,_that.body,_that.recipientId,_that.recipientType,_that.senderId,_that.senderType,_that.status,_that.actionType,_that.relatedEntityId,_that.relatedEntityType,_that.actionResult,_that.metadata,_that.createdAt,_that.readAt,_that.actionedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MessageType type,  String title,  String body,  String recipientId,  String recipientType,  String? senderId,  String? senderType,  MessageStatus status,  String? actionType,  String? relatedEntityId,  String? relatedEntityType,  String? actionResult,  Map<String, dynamic>? metadata,  DateTime createdAt,  DateTime? readAt,  DateTime? actionedAt,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.recipientId,_that.recipientType,_that.senderId,_that.senderType,_that.status,_that.actionType,_that.relatedEntityId,_that.relatedEntityType,_that.actionResult,_that.metadata,_that.createdAt,_that.readAt,_that.actionedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message extends Message {
  const _Message({required this.id, required this.type, required this.title, required this.body, required this.recipientId, required this.recipientType, this.senderId, this.senderType, required this.status, this.actionType, this.relatedEntityId, this.relatedEntityType, this.actionResult, final  Map<String, dynamic>? metadata, required this.createdAt, this.readAt, this.actionedAt, this.expiresAt}): _metadata = metadata,super._();
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String id;
@override final  MessageType type;
@override final  String title;
@override final  String body;
@override final  String recipientId;
@override final  String recipientType;
@override final  String? senderId;
@override final  String? senderType;
@override final  MessageStatus status;
@override final  String? actionType;
@override final  String? relatedEntityId;
@override final  String? relatedEntityType;
@override final  String? actionResult;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime createdAt;
@override final  DateTime? readAt;
@override final  DateTime? actionedAt;
@override final  DateTime? expiresAt;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.recipientType, recipientType) || other.recipientType == recipientType)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderType, senderType) || other.senderType == senderType)&&(identical(other.status, status) || other.status == status)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.relatedEntityId, relatedEntityId) || other.relatedEntityId == relatedEntityId)&&(identical(other.relatedEntityType, relatedEntityType) || other.relatedEntityType == relatedEntityType)&&(identical(other.actionResult, actionResult) || other.actionResult == actionResult)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.actionedAt, actionedAt) || other.actionedAt == actionedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,body,recipientId,recipientType,senderId,senderType,status,actionType,relatedEntityId,relatedEntityType,actionResult,const DeepCollectionEquality().hash(_metadata),createdAt,readAt,actionedAt,expiresAt);

@override
String toString() {
  return 'Message(id: $id, type: $type, title: $title, body: $body, recipientId: $recipientId, recipientType: $recipientType, senderId: $senderId, senderType: $senderType, status: $status, actionType: $actionType, relatedEntityId: $relatedEntityId, relatedEntityType: $relatedEntityType, actionResult: $actionResult, metadata: $metadata, createdAt: $createdAt, readAt: $readAt, actionedAt: $actionedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, MessageType type, String title, String body, String recipientId, String recipientType, String? senderId, String? senderType, MessageStatus status, String? actionType, String? relatedEntityId, String? relatedEntityType, String? actionResult, Map<String, dynamic>? metadata, DateTime createdAt, DateTime? readAt, DateTime? actionedAt, DateTime? expiresAt
});




}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? recipientId = null,Object? recipientType = null,Object? senderId = freezed,Object? senderType = freezed,Object? status = null,Object? actionType = freezed,Object? relatedEntityId = freezed,Object? relatedEntityType = freezed,Object? actionResult = freezed,Object? metadata = freezed,Object? createdAt = null,Object? readAt = freezed,Object? actionedAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,recipientType: null == recipientType ? _self.recipientType : recipientType // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,senderType: freezed == senderType ? _self.senderType : senderType // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageStatus,actionType: freezed == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String?,relatedEntityId: freezed == relatedEntityId ? _self.relatedEntityId : relatedEntityId // ignore: cast_nullable_to_non_nullable
as String?,relatedEntityType: freezed == relatedEntityType ? _self.relatedEntityType : relatedEntityType // ignore: cast_nullable_to_non_nullable
as String?,actionResult: freezed == actionResult ? _self.actionResult : actionResult // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,actionedAt: freezed == actionedAt ? _self.actionedAt : actionedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$MessageListResponse {

 List<Message> get items; int get total; int get page; int get unreadCount;
/// Create a copy of MessageListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageListResponseCopyWith<MessageListResponse> get copyWith => _$MessageListResponseCopyWithImpl<MessageListResponse>(this as MessageListResponse, _$identity);

  /// Serializes this MessageListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageListResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.total, total) || other.total == total)&&(identical(other.page, page) || other.page == page)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),total,page,unreadCount);

@override
String toString() {
  return 'MessageListResponse(items: $items, total: $total, page: $page, unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class $MessageListResponseCopyWith<$Res>  {
  factory $MessageListResponseCopyWith(MessageListResponse value, $Res Function(MessageListResponse) _then) = _$MessageListResponseCopyWithImpl;
@useResult
$Res call({
 List<Message> items, int total, int page, int unreadCount
});




}
/// @nodoc
class _$MessageListResponseCopyWithImpl<$Res>
    implements $MessageListResponseCopyWith<$Res> {
  _$MessageListResponseCopyWithImpl(this._self, this._then);

  final MessageListResponse _self;
  final $Res Function(MessageListResponse) _then;

/// Create a copy of MessageListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,Object? page = null,Object? unreadCount = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Message>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageListResponse].
extension MessageListResponsePatterns on MessageListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageListResponse value)  $default,){
final _that = this;
switch (_that) {
case _MessageListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MessageListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Message> items,  int total,  int page,  int unreadCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageListResponse() when $default != null:
return $default(_that.items,_that.total,_that.page,_that.unreadCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Message> items,  int total,  int page,  int unreadCount)  $default,) {final _that = this;
switch (_that) {
case _MessageListResponse():
return $default(_that.items,_that.total,_that.page,_that.unreadCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Message> items,  int total,  int page,  int unreadCount)?  $default,) {final _that = this;
switch (_that) {
case _MessageListResponse() when $default != null:
return $default(_that.items,_that.total,_that.page,_that.unreadCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageListResponse implements MessageListResponse {
  const _MessageListResponse({required final  List<Message> items, required this.total, required this.page, required this.unreadCount}): _items = items;
  factory _MessageListResponse.fromJson(Map<String, dynamic> json) => _$MessageListResponseFromJson(json);

 final  List<Message> _items;
@override List<Message> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int total;
@override final  int page;
@override final  int unreadCount;

/// Create a copy of MessageListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageListResponseCopyWith<_MessageListResponse> get copyWith => __$MessageListResponseCopyWithImpl<_MessageListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageListResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.total, total) || other.total == total)&&(identical(other.page, page) || other.page == page)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total,page,unreadCount);

@override
String toString() {
  return 'MessageListResponse(items: $items, total: $total, page: $page, unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class _$MessageListResponseCopyWith<$Res> implements $MessageListResponseCopyWith<$Res> {
  factory _$MessageListResponseCopyWith(_MessageListResponse value, $Res Function(_MessageListResponse) _then) = __$MessageListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<Message> items, int total, int page, int unreadCount
});




}
/// @nodoc
class __$MessageListResponseCopyWithImpl<$Res>
    implements _$MessageListResponseCopyWith<$Res> {
  __$MessageListResponseCopyWithImpl(this._self, this._then);

  final _MessageListResponse _self;
  final $Res Function(_MessageListResponse) _then;

/// Create a copy of MessageListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,Object? page = null,Object? unreadCount = null,}) {
  return _then(_MessageListResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Message>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MessageActionRequest {

 String get action; String? get note;
/// Create a copy of MessageActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageActionRequestCopyWith<MessageActionRequest> get copyWith => _$MessageActionRequestCopyWithImpl<MessageActionRequest>(this as MessageActionRequest, _$identity);

  /// Serializes this MessageActionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageActionRequest&&(identical(other.action, action) || other.action == action)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,note);

@override
String toString() {
  return 'MessageActionRequest(action: $action, note: $note)';
}


}

/// @nodoc
abstract mixin class $MessageActionRequestCopyWith<$Res>  {
  factory $MessageActionRequestCopyWith(MessageActionRequest value, $Res Function(MessageActionRequest) _then) = _$MessageActionRequestCopyWithImpl;
@useResult
$Res call({
 String action, String? note
});




}
/// @nodoc
class _$MessageActionRequestCopyWithImpl<$Res>
    implements $MessageActionRequestCopyWith<$Res> {
  _$MessageActionRequestCopyWithImpl(this._self, this._then);

  final MessageActionRequest _self;
  final $Res Function(MessageActionRequest) _then;

/// Create a copy of MessageActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageActionRequest].
extension MessageActionRequestPatterns on MessageActionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageActionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageActionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageActionRequest value)  $default,){
final _that = this;
switch (_that) {
case _MessageActionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageActionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MessageActionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageActionRequest() when $default != null:
return $default(_that.action,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  String? note)  $default,) {final _that = this;
switch (_that) {
case _MessageActionRequest():
return $default(_that.action,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _MessageActionRequest() when $default != null:
return $default(_that.action,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageActionRequest implements MessageActionRequest {
  const _MessageActionRequest({required this.action, this.note});
  factory _MessageActionRequest.fromJson(Map<String, dynamic> json) => _$MessageActionRequestFromJson(json);

@override final  String action;
@override final  String? note;

/// Create a copy of MessageActionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageActionRequestCopyWith<_MessageActionRequest> get copyWith => __$MessageActionRequestCopyWithImpl<_MessageActionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageActionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageActionRequest&&(identical(other.action, action) || other.action == action)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,note);

@override
String toString() {
  return 'MessageActionRequest(action: $action, note: $note)';
}


}

/// @nodoc
abstract mixin class _$MessageActionRequestCopyWith<$Res> implements $MessageActionRequestCopyWith<$Res> {
  factory _$MessageActionRequestCopyWith(_MessageActionRequest value, $Res Function(_MessageActionRequest) _then) = __$MessageActionRequestCopyWithImpl;
@override @useResult
$Res call({
 String action, String? note
});




}
/// @nodoc
class __$MessageActionRequestCopyWithImpl<$Res>
    implements _$MessageActionRequestCopyWith<$Res> {
  __$MessageActionRequestCopyWithImpl(this._self, this._then);

  final _MessageActionRequest _self;
  final $Res Function(_MessageActionRequest) _then;

/// Create a copy of MessageActionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? note = freezed,}) {
  return _then(_MessageActionRequest(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
