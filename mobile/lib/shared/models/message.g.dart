// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
  title: json['title'] as String,
  body: json['body'] as String,
  recipientId: json['recipientId'] as String,
  recipientType: json['recipientType'] as String,
  senderId: json['senderId'] as String?,
  senderType: json['senderType'] as String?,
  status: $enumDecode(_$MessageStatusEnumMap, json['status']),
  actionType: json['actionType'] as String?,
  relatedEntityId: json['relatedEntityId'] as String?,
  relatedEntityType: json['relatedEntityType'] as String?,
  actionResult: json['actionResult'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  readAt: json['readAt'] == null
      ? null
      : DateTime.parse(json['readAt'] as String),
  actionedAt: json['actionedAt'] == null
      ? null
      : DateTime.parse(json['actionedAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$MessageTypeEnumMap[instance.type]!,
  'title': instance.title,
  'body': instance.body,
  'recipientId': instance.recipientId,
  'recipientType': instance.recipientType,
  'senderId': instance.senderId,
  'senderType': instance.senderType,
  'status': _$MessageStatusEnumMap[instance.status]!,
  'actionType': instance.actionType,
  'relatedEntityId': instance.relatedEntityId,
  'relatedEntityType': instance.relatedEntityType,
  'actionResult': instance.actionResult,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt.toIso8601String(),
  'readAt': instance.readAt?.toIso8601String(),
  'actionedAt': instance.actionedAt?.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
};

const _$MessageTypeEnumMap = {
  MessageType.groundAdminInvitation: 'ground_admin_invitation',
  MessageType.groundAdminApplication: 'ground_admin_application',
  MessageType.groundAdminApproved: 'ground_admin_approved',
  MessageType.groundAdminDeclined: 'ground_admin_declined',
  MessageType.groundAdminInvitationDeclined: 'ground_admin_invitation_declined',
  MessageType.groundAdminRevocation: 'ground_admin_revocation',
  MessageType.groundAdminStepdownRequest: 'ground_admin_stepdown_request',
  MessageType.verifyNewIssue: 'verify_new_issue',
  MessageType.verifyFix: 'verify_fix',
  MessageType.memberRegistration: 'member_registration',
  MessageType.monthlyReport: 'monthly_report',
};

const _$MessageStatusEnumMap = {
  MessageStatus.unread: 'unread',
  MessageStatus.read: 'read',
  MessageStatus.actioned: 'actioned',
  MessageStatus.dismissed: 'dismissed',
};

_MessageListResponse _$MessageListResponseFromJson(Map<String, dynamic> json) =>
    _MessageListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      unreadCount: (json['unreadCount'] as num).toInt(),
    );

Map<String, dynamic> _$MessageListResponseToJson(
  _MessageListResponse instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'page': instance.page,
  'unreadCount': instance.unreadCount,
};

_MessageActionRequest _$MessageActionRequestFromJson(
  Map<String, dynamic> json,
) => _MessageActionRequest(
  action: json['action'] as String,
  note: json['note'] as String?,
);

Map<String, dynamic> _$MessageActionRequestToJson(
  _MessageActionRequest instance,
) => <String, dynamic>{'action': instance.action, 'note': instance.note};
