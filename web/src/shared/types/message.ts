/**
 * Message types for the platform messaging system
 */
export type MessageType =
  | 'ground_admin_invitation'
  | 'ground_admin_application'
  | 'ground_admin_approved'
  | 'ground_admin_declined'
  | 'ground_admin_invitation_declined'
  | 'ground_admin_invitation_accepted'
  | 'ground_admin_revocation'
  | 'ground_admin_stepdown_request'
  | 'verify_new_issue'
  | 'verify_fix'
  | 'member_registration'
  | 'monthly_report';

/**
 * Status of a message in the system
 */
export type MessageStatus = 'unread' | 'read' | 'actioned' | 'dismissed';

/**
 * Recipient type for messages
 */
export type RecipientType = 'member' | 'admin';

/**
 * Sender type for messages
 */
export type SenderType = 'member' | 'admin' | 'system';

/**
 * Message entity representing platform communications
 */
export interface Message {
  id: string;
  type: MessageType;
  title: string;
  body: string;
  recipientId: string;
  recipientType: RecipientType;
  senderId?: string;
  senderType?: SenderType;
  status: MessageStatus;
  actionType?: string;
  relatedEntityId?: string;
  relatedEntityType?: string;
  actionResult?: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
  readAt?: string;
  actionedAt?: string;
  expiresAt?: string;
}

/**
 * Response from messages list endpoint
 */
export interface MessageListResponse {
  items: Message[];
  total: number;
  page: number;
  unreadCount: number;
}

/**
 * Request to perform an action on a message
 */
export interface MessageActionRequest {
  action: string;
  note?: string;
}

/**
 * Parameters for filtering messages
 */
export interface MessageFilterParams {
  status?: MessageStatus;
  type?: MessageType;
  page?: number;
  size?: number;
}

/**
 * Action types that messages can have
 */
export const MESSAGE_ACTION_TYPES = {
  ACCEPT_DECLINE: 'accept_decline',
  APPROVE_REJECT: 'approve_reject',
  CONFIRM_VERIFY: 'confirm_verify',
  ACKNOWLEDGE: 'acknowledge',
  VIEW: 'view',
} as const;

/**
 * Map message types to their i18n label keys
 */
export const MESSAGE_TYPE_LABELS: Record<MessageType, string> = {
  ground_admin_invitation: 'messages.types.groundAdminInvitation',
  ground_admin_application: 'messages.types.groundAdminApplication',
  ground_admin_approved: 'messages.types.groundAdminApproved',
  ground_admin_declined: 'messages.types.groundAdminDeclined',
  ground_admin_invitation_declined: 'messages.types.groundAdminInvitationDeclined',
  ground_admin_invitation_accepted: 'messages.types.groundAdminInvitationAccepted',
  ground_admin_revocation: 'messages.types.groundAdminRevocation',
  ground_admin_stepdown_request: 'messages.types.groundAdminStepdownRequest',
  verify_new_issue: 'messages.types.verifyNewIssue',
  verify_fix: 'messages.types.verifyFix',
  member_registration: 'messages.types.memberRegistration',
  monthly_report: 'messages.types.monthlyReport',
};
