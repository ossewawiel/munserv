import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Message types for the messaging system
enum MessageType {
  @JsonValue('ground_admin_invitation')
  groundAdminInvitation,
  @JsonValue('ground_admin_application')
  groundAdminApplication,
  @JsonValue('ground_admin_approved')
  groundAdminApproved,
  @JsonValue('ground_admin_declined')
  groundAdminDeclined,
  @JsonValue('ground_admin_invitation_declined')
  groundAdminInvitationDeclined,
  @JsonValue('ground_admin_revocation')
  groundAdminRevocation,
  @JsonValue('ground_admin_stepdown_request')
  groundAdminStepdownRequest,
  @JsonValue('verify_new_issue')
  verifyNewIssue,
  @JsonValue('verify_fix')
  verifyFix,
  @JsonValue('member_registration')
  memberRegistration,
  @JsonValue('monthly_report')
  monthlyReport;

  String get displayName => switch (this) {
        groundAdminInvitation => 'Ground Admin Invitation',
        groundAdminApplication => 'Ground Admin Application',
        groundAdminApproved => 'Application Approved',
        groundAdminDeclined => 'Application Declined',
        groundAdminInvitationDeclined => 'Invitation Declined',
        groundAdminRevocation => 'Status Revoked',
        groundAdminStepdownRequest => 'Step Down Request',
        verifyNewIssue => 'Verify Issue',
        verifyFix => 'Verify Fix',
        memberRegistration => 'Member Registration',
        monthlyReport => 'Monthly Report',
      };
}

/// Message status
enum MessageStatus {
  unread,
  read,
  actioned,
  dismissed;

  String get displayName => switch (this) {
        unread => 'Unread',
        read => 'Read',
        actioned => 'Actioned',
        dismissed => 'Dismissed',
      };
}

/// A message in the user's inbox
@freezed
abstract class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required MessageType type,
    required String title,
    required String body,
    required String recipientId,
    required String recipientType,
    String? senderId,
    String? senderType,
    required MessageStatus status,
    String? actionType,
    String? relatedEntityId,
    String? relatedEntityType,
    String? actionResult,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    DateTime? readAt,
    DateTime? actionedAt,
    DateTime? expiresAt,
  }) = _Message;

  /// Whether this message has pending actions
  bool get hasActions => actionType != null && status != MessageStatus.actioned;

  /// Whether this message is unread
  bool get isUnread => status == MessageStatus.unread;

  /// Whether this message is related to verification
  bool get isVerificationMessage =>
      type == MessageType.verifyNewIssue || type == MessageType.verifyFix;

  /// Whether this message is related to ground admin flow
  bool get isGroundAdminMessage =>
      type == MessageType.groundAdminInvitation ||
      type == MessageType.groundAdminApplication ||
      type == MessageType.groundAdminApproved ||
      type == MessageType.groundAdminDeclined ||
      type == MessageType.groundAdminInvitationDeclined ||
      type == MessageType.groundAdminRevocation ||
      type == MessageType.groundAdminStepdownRequest;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}

/// Paginated response for messages
@freezed
abstract class MessageListResponse with _$MessageListResponse {
  const factory MessageListResponse({
    required List<Message> items,
    required int total,
    required int page,
    required int unreadCount,
  }) = _MessageListResponse;

  factory MessageListResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageListResponseFromJson(json);
}

/// Request to perform an action on a message
@freezed
abstract class MessageActionRequest with _$MessageActionRequest {
  const factory MessageActionRequest({
    required String action,
    String? note,
  }) = _MessageActionRequest;

  factory MessageActionRequest.fromJson(Map<String, dynamic> json) =>
      _$MessageActionRequestFromJson(json);
}
