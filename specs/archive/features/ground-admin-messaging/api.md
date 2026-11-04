# Ground Admin & Messaging - API Contract

Base URL: `/api/v1`

## Messages

### GET /messages
List messages for current user.

**Query:** `?status={status}&type={type}&page={n}&size={n}`
**Response:** `{ items: Message[], total: number, page: number, unreadCount: number }`
**Errors:** 401 Unauthorized

### GET /messages/{id}
Get message detail.

**Response:** `Message`
**Errors:** 401 Unauthorized | 404 Not Found

### PATCH /messages/{id}/read
Mark message as read.

**Response:** `Message`
**Errors:** 401 Unauthorized | 404 Not Found

### POST /messages/{id}/action
Perform action on message (accept, decline, approve, etc.).

**Request:** `{ action: string, note?: string }`
**Response:** `Message`
**Errors:** 400 Invalid Action | 401 Unauthorized | 404 Not Found | 409 Already Actioned

---

## Ground Admin - Member Actions

### POST /members/me/ground-admin/apply
Apply to become a Ground Admin.

**Request:** `{ }` (empty - uses current member's sector)
**Response:** `{ applicationId: string, status: 'pending' }`
**Errors:** 401 Unauthorized | 409 Already Applied | 409 Already Ground Admin

### POST /members/me/ground-admin/accept
Accept Ground Admin invitation.

**Request:** `{ applicationId: string }`
**Response:** `{ status: 'accepted', member: Member }`
**Errors:** 400 Invalid Application | 401 Unauthorized | 404 Application Not Found | 409 Not An Invitation

### POST /members/me/ground-admin/decline
Decline Ground Admin invitation.

**Request:** `{ applicationId: string, reason?: string }`
**Response:** `{ status: 'declined' }`
**Errors:** 400 Invalid Application | 401 Unauthorized | 404 Application Not Found

### POST /members/me/ground-admin/stepdown
Request to step down from Ground Admin role.

**Request:** `{ reason?: string }`
**Response:** `{ status: 'pending_approval' }`
**Errors:** 401 Unauthorized | 409 Not A Ground Admin

---

## Ground Admin - Admin Actions

### POST /members/{id}/ground-admin/invite
Invite member to become Ground Admin (admin only).

**Request:** `{ message?: string }`
**Response:** `{ applicationId: string, status: 'pending' }`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Member Not Found | 409 Already Ground Admin | 409 Already Invited

### POST /members/{id}/ground-admin/approve
Approve Ground Admin application (admin only).

**Request:** `{ applicationId: string }`
**Response:** `{ status: 'approved', member: Member }`
**Errors:** 400 Invalid Application | 401 Unauthorized | 403 Forbidden | 404 Not Found

### POST /members/{id}/ground-admin/decline
Decline Ground Admin application (admin only).

**Request:** `{ applicationId: string, reason: string }`
**Response:** `{ status: 'declined' }`
**Errors:** 400 Invalid Application | 401 Unauthorized | 403 Forbidden | 404 Not Found

### POST /members/{id}/ground-admin/revoke
Revoke Ground Admin status (admin only).

**Request:** `{ reason: string }`
**Response:** `{ status: 'revoked', member: Member }`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Member Not Found | 409 Not A Ground Admin

### PATCH /members/{id}/ground-admin/status
Update Ground Admin status (admin only).

**Request:** `{ status: 'active' | 'on_hold' }`
**Response:** `Member`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Member Not Found | 409 Not A Ground Admin

---

## Ground Admin - Queries

### GET /sectors/{id}/ground-admins
List Ground Admins in sector.

**Query:** `?status={status}` (optional filter)
**Response:** `{ items: GroundAdmin[], total: number }`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Sector Not Found

**GroundAdmin type:**
```typescript
{
  id: string;
  memberId: string;
  name: string;
  status: GroundAdminStatus;
  since: string;
  responseRate: number;
  pendingVerifications: number;
}
```

### GET /members/me/ground-admin
Get current member's Ground Admin info (if applicable).

**Response:** `GroundAdminInfo | null`
**Errors:** 401 Unauthorized

**GroundAdminInfo type:**
```typescript
{
  status: GroundAdminStatus;
  since: string;
  responseRate: number;
  pendingVerifications: number;
  totalVerifications: number;
}
```

---

## Sector Settings

### GET /sectors/{id}/settings
Get sector settings (chief only).

**Response:** `SectorSettings`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Not Found

### PATCH /sectors/{id}/settings
Update sector settings (chief only).

**Request:**
```json
{
  "newIssueVerificationMode": "all_notified",
  "fixVerificationMode": "admin_assigns",
  "daysFixedBeforeClosed": 7,
  "minimumGroundAdmins": 2
}
```
**Response:** `SectorSettings`
**Errors:** 400 Validation Failed | 401 Unauthorized | 403 Forbidden | 404 Not Found

---

## Issue Verification

### POST /issues/{id}/request-verification
Request Ground Admin verification (admin only).

**Request:**
```json
{
  "type": "existence" | "fix",
  "assignTo": "member-id" | null,
  "message": "Please verify this issue"
}
```
**Response:** `IssueVerification`
**Errors:** 400 Invalid State | 401 Unauthorized | 403 Forbidden | 404 Issue Not Found

### POST /issues/{id}/verify
Submit verification result (Ground Admin only).

**Request:**
```json
{
  "verificationId": "uuid",
  "result": "confirmed" | "not_found" | "not_fixed",
  "reason": "cannot_find" | "wrong_location" | "not_an_issue" | "busy" | "away",
  "note": "Optional explanation",
  "photoId": "uuid"
}
```
**Response:** `IssueVerification`
**Errors:** 400 Invalid Result | 401 Unauthorized | 403 Not Assigned | 404 Not Found | 409 Already Verified

### GET /issues/{id}/verifications
Get verification history for issue.

**Response:** `{ items: IssueVerification[] }`
**Errors:** 401 Unauthorized | 404 Issue Not Found

### GET /members/me/pending-verifications
Get pending verifications for current Ground Admin.

**Response:** `{ items: PendingVerification[] }`
**Errors:** 401 Unauthorized

**PendingVerification type:**
```typescript
{
  verificationId: string;
  issueId: string;
  issueType: IssueType;
  verificationType: 'existence' | 'fix';
  location: GeoPoint;
  requestedAt: string;
  distance?: number;  // if location available
}
```

---

## Notifications

### GET /members/me/notification-settings
Get notification preferences.

**Response:**
```json
{
  "pushEnabled": true,
  "verificationAlerts": true,
  "monthlyReports": true
}
```
**Errors:** 401 Unauthorized

### PATCH /members/me/notification-settings
Update notification preferences.

**Request:**
```json
{
  "pushEnabled": false,
  "verificationAlerts": true,
  "monthlyReports": false
}
```
**Response:** `NotificationSettings`
**Errors:** 401 Unauthorized

---

## Admin Endpoints Update

### GET /admin/members
List members (updated response).

**Query:** `?search={term}&page={n}&size={n}&groundAdmin={true|false}`
**Response:**
```json
{
  "items": [
    {
      "id": "...",
      "name": "...",
      "phone": "...",
      "status": "active",
      "isGroundAdmin": true,
      "groundAdminStatus": "active",
      "hasPendingApplication": false
    }
  ],
  "total": 100,
  "page": 1
}
```

---

## Types Summary

### Message
```typescript
interface Message {
  id: string;
  type: MessageType;
  title: string;
  body: string;
  recipientId: string;
  recipientType: 'member' | 'admin';
  senderId?: string;
  senderType?: 'member' | 'admin' | 'system';
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
```

### SectorSettings
```typescript
interface SectorSettings {
  id: string;
  sectorId: string;
  newIssueVerificationMode: VerificationMode;
  fixVerificationMode: VerificationMode;
  daysFixedBeforeClosed: number;
  minimumGroundAdmins: number;
  createdAt: string;
  updatedAt: string;
}
```

### IssueVerification
```typescript
interface IssueVerification {
  id: string;
  issueId: string;
  verificationType: 'existence' | 'fix';
  assignedTo?: string;
  verifiedBy?: string;
  result?: 'confirmed' | 'not_found' | 'not_fixed' | 'cannot_verify';
  reason?: VerificationReason;
  note?: string;
  photoId?: string;
  requestedAt: string;
  respondedAt?: string;
  status: 'pending' | 'completed' | 'expired';
}
```

### Enums
```typescript
type MessageType =
  | 'ground_admin_invitation'
  | 'ground_admin_application'
  | 'ground_admin_approved'
  | 'ground_admin_declined'
  | 'ground_admin_invitation_declined'
  | 'ground_admin_revocation'
  | 'ground_admin_stepdown_request'
  | 'verify_new_issue'
  | 'verify_fix'
  | 'member_registration'
  | 'monthly_report';

type MessageStatus = 'unread' | 'read' | 'actioned' | 'dismissed';

type VerificationMode = 'all_notified' | 'admin_assigns' | 'nearest_auto' | 'first_come';

type VerificationReason = 'busy' | 'away' | 'cannot_find' | 'wrong_location' | 'not_an_issue';

type GroundAdminStatus = 'active' | 'on_hold' | 'inactive';
```

---

## Error Response Format

All errors follow standard format:
```json
{
  "error": {
    "code": "INVALID_STATE",
    "message": "Issue must be in REPORTED state to request existence verification",
    "details": {
      "currentState": "confirmed"
    }
  }
}
```

## Common Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| UNAUTHORIZED | 401 | Not authenticated |
| FORBIDDEN | 403 | Not authorized for this action |
| NOT_FOUND | 404 | Resource not found |
| INVALID_STATE | 400 | Resource in wrong state for operation |
| ALREADY_EXISTS | 409 | Resource already exists |
| VALIDATION_FAILED | 400 | Request validation failed |
