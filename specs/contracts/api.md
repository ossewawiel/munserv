# API Contract

Base URL: `/api/v1`

> **Full examples**: See [archive/MVP_Development_Guide.md §4](../archive/MVP_Development_Guide.md) for complete JSON request/response examples.

## Auth

### POST /auth/register
Start registration with phone.

**Request:** `{ phone: string }`
**Response:** `{ otpSent: boolean, expiresIn: number }`
**Errors:** 409 Already registered | 429 Rate limited

### POST /auth/verify
Verify OTP and complete registration.

**Request:** `{ phone: string, otp: string, pin: string, name: string }`
**Response:** `{ accessToken: string, refreshToken: string, member: Member }`
**Errors:** 400 Invalid OTP | 410 OTP expired

### POST /auth/login
Login with PIN.

**Request:** `{ phone: string, pin: string }`
**Response:** `{ accessToken: string, refreshToken: string, member: Member }`
**Errors:** 401 Invalid credentials | 423 Account locked

### POST /auth/refresh
Refresh access token.

**Request:** `{ refreshToken: string }`
**Response:** `{ accessToken: string, refreshToken: string }`
**Errors:** 401 Invalid token

### POST /auth/admin/login
Public. Administrator login, including the super user during [bootstrap](../../domain/bootstrap.md)
and the super user logging in under a pod chief's active [support grant](../../domain/support-grant.md).

**Request:** `{ email: string, password: string }`

**Response:** `200` `AdminLoginResponse`. When the credentials are the super user's and the pod has
an active grant, `profile.admin.role` is the **granted** role (never `super_user`) and
`profile.supportGrant` carries the grant:
```json
{
  "tokens": { "accessToken": "…", "refreshToken": "…", "expiresAt": "2026-09-05T10:15:00Z" },
  "profile": {
    "admin": { "id": "<grantId>", "email": "<super user email>", "displayName": "Support User",
               "role": "POD_ADMIN", "level": "pod", "podId": "<uuid>", "wardId": null,
               "sectorId": null, "onboardingStatus": null },
    "sector": null,
    "bootstrapStatus": null,
    "supportGrant": { "grantId": "<uuid>", "grantedRole": "pod_admin", "expiresAt": "2026-09-05T11:00:00Z" }
  }
}
```
`tokens.expiresAt` is the access token expiry; `supportGrant.expiresAt` is the grant's own,
server-owned, sliding expiry. `supportGrant` is `null` for every other login.
**Errors:** 401 Invalid credentials (also when the pod is not bootstrap-eligible and no active
grant exists)

### POST /auth/logout
Log out the current caller. Revokes the underlying support grant when the token is grant-scoped
(minted by `/auth/admin/login` under a support grant); a no-op for any other authenticated token.

**Request:** none
**Response:** `204` No Content, always
**Errors:** 401 Not authenticated

---

## Issues

### GET /issues
List issues with filters.

**Query:** `?sector={id}&state={state}&page={n}&size={n}`
**Response:** `{ items: Issue[], total: number, page: number }`
**Errors:** 400 Invalid query

### GET /issues/{id}
Get issue details including state history.

**Response:** `IssueDetail` (includes `stateHistory: StateHistoryEntry[]`)
**Errors:** 404 Not found

### POST /issues
Create new issue.

**Request:** `{ title: string, description?: string, typeId: string, location: GeoPoint, photos: string[] }`
**Response:** `Issue`
**Errors:** 400 Validation failed | 401 Unauthorized

### PATCH /issues/{id}/state
Update issue state (admin only).

**Request:** `{ state: IssueState, note?: string }`
**Response:** `Issue`
**Errors:** 403 Forbidden | 404 Not found

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
**Errors:** 400 Invalid state | 401 Unauthorized | 403 Forbidden | 404 Not found

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
**Errors:** 400 Invalid result | 401 Unauthorized | 403 Not assigned | 404 Not found | 409 Already verified

### GET /issues/{id}/verifications
Get verification history for issue.

**Response:** `{ items: IssueVerification[] }`
**Errors:** 401 Unauthorized | 404 Not found

---

## Members

### GET /members/me
Get current member profile.

**Response:** `Member`
**Errors:** 401 Unauthorized

### GET /members/{id}/issues
Get issues reported by member.

**Response:** `{ items: Issue[], total: number }`
**Errors:** 404 Member not found

### GET /members/me/ground-admin
Get current member's Ground Admin info (if applicable).

**Response:** `GroundAdminInfo | null`
**Errors:** 401 Unauthorized

### POST /members/me/ground-admin/apply
Apply to become a Ground Admin.

**Request:** `{ }` (empty - uses current member's sector)
**Response:** `{ applicationId: string, status: 'pending' }`
**Errors:** 401 Unauthorized | 409 Already applied | 409 Already Ground Admin

### POST /members/me/ground-admin/accept
Accept Ground Admin invitation.

**Request:** `{ applicationId: string }`
**Response:** `{ status: 'accepted', member: Member }`
**Errors:** 400 Invalid application | 401 Unauthorized | 404 Not found | 409 Not an invitation

### POST /members/me/ground-admin/decline
Decline Ground Admin invitation.

**Request:** `{ applicationId: string, reason?: string }`
**Response:** `{ status: 'declined' }`
**Errors:** 400 Invalid application | 401 Unauthorized | 404 Not found

### POST /members/me/ground-admin/stepdown
Request to step down from Ground Admin role.

**Request:** `{ reason?: string }`
**Response:** `{ status: 'pending_approval' }`
**Errors:** 401 Unauthorized | 409 Not a Ground Admin

### GET /members/me/pending-verifications
Get pending verifications for current Ground Admin.

**Response:** `{ items: PendingVerification[] }`
**Errors:** 401 Unauthorized

### GET /members/me/notification-settings
Get notification preferences.

**Response:** `{ pushEnabled: boolean, verificationAlerts: boolean, monthlyReports: boolean }`
**Errors:** 401 Unauthorized

### PATCH /members/me/notification-settings
Update notification preferences.

**Request:** `{ pushEnabled?: boolean, verificationAlerts?: boolean, monthlyReports?: boolean }`
**Response:** `NotificationSettings`
**Errors:** 401 Unauthorized

---

## Ground Admin (Admin Actions)

### POST /members/{id}/ground-admin/invite
Invite member to become Ground Admin (admin only).

**Request:** `{ message?: string }`
**Response:** `{ applicationId: string, status: 'pending' }`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Member not found | 409 Already Ground Admin | 409 Already invited

### POST /members/{id}/ground-admin/approve
Approve Ground Admin application (admin only).

**Request:** `{ applicationId: string }`
**Response:** `{ status: 'approved', member: Member }`
**Errors:** 400 Invalid application | 401 Unauthorized | 403 Forbidden | 404 Not found

### POST /members/{id}/ground-admin/decline
Decline Ground Admin application (admin only).

**Request:** `{ applicationId: string, reason: string }`
**Response:** `{ status: 'declined' }`
**Errors:** 400 Invalid application | 401 Unauthorized | 403 Forbidden | 404 Not found

### POST /members/{id}/ground-admin/revoke
Revoke Ground Admin status (admin only).

**Request:** `{ reason: string }`
**Response:** `{ status: 'revoked', member: Member }`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Member not found | 409 Not a Ground Admin

### PATCH /members/{id}/ground-admin/status
Update Ground Admin status (admin only).

**Request:** `{ status: 'active' | 'on_hold' }`
**Response:** `Member`
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Member not found | 409 Not a Ground Admin

---

## Admin

### GET /admin/dashboard
Get dashboard statistics.

**Response:** `{ totalIssues: number, openIssues: number, resolvedThisMonth: number, activeMembers: number }`
**Errors:** 403 Forbidden

### GET /admin/members
List members (admin only).

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
**Errors:** 403 Forbidden

---

## Sectors

### GET /sectors
List all sectors.

**Response:** `Sector[]`

### GET /sectors/{id}
Get sector details.

**Response:** `Sector`
**Errors:** 404 Not found

### GET /sectors/{id}/ground-admins
List Ground Admins in sector.

**Query:** `?status={status}` (optional filter: active, on_hold, inactive)
**Response:**
```json
{
  "items": [
    {
      "id": "...",
      "memberId": "...",
      "name": "...",
      "status": "active",
      "since": "2025-01-15T00:00:00Z",
      "responseRate": 0.85,
      "pendingVerifications": 2
    }
  ],
  "total": 5
}
```
**Errors:** 401 Unauthorized | 403 Forbidden | 404 Sector not found

---

## Sector Settings

### GET /sectors/{sectorId}/settings
Get sector settings. Creates default settings if none exist.

**Response:** `SectorSettings`
**Errors:** 404 Sector not found

### PATCH /sectors/{sectorId}/settings
Partially update sector settings. Only provided fields are updated.

**Request:**
```json
{
  "newIssueVerificationMode": "ADMIN_ASSIGNS",  // optional
  "fixVerificationMode": "NEAREST_AUTO",         // optional
  "daysFixedBeforeClosed": 14,                   // optional, 1-365
  "minimumGroundAdmins": 3                       // optional, 0-100
}
```
**Response:** `SectorSettings`
**Errors:** 400 Validation failed | 404 Sector not found

---

## Pod

Pod configuration and setup status. See [`domain/pod.md`](../../domain/pod.md).
Every endpoint in this section requires an authenticated admin with role `pod_chief`
(`@RequireRole(AdminRole.POD_CHIEF)` on `PodController`).

### GET /pod/status
Setup completion status of the caller's pod.

**Response:** `200` `PodSetupStatusResponse`
```json
{
  "isComplete": false,
  "missingSteps": ["pod_boundaries", "first_admin"]
}
```
`missingSteps` values are the snake_case `SetupStep` wire values:
`pod_name`, `pod_boundaries`, `wards_sectors`, `first_admin`. The list is empty when `isComplete` is true.
The response does **not** carry wards or sectors (tracked in #59).

**Errors:** 401 Unauthorized (`{ code, message }`) | 403 Not pod chief | 404 Pod not found

### GET /pod/settings
Name and logo of the caller's pod.

**Response:** `200` `PodSettingsResponse`
```json
{
  "name": "Ward42",
  "displayName": "Munserv Pod Ward42",
  "logoUrl": "https://example.com/logo.png"
}
```
`displayName` is server-derived as `"Munserv Pod {name}"`; clients render it, never build it.
`logoUrl` is `null` when no logo is set.

**Errors:** 401 Unauthorized (`{ code, message }`) | 403 Not pod chief | 404 Pod not found

### PATCH /pod/settings
Partially update pod settings. Only provided fields are updated.

**Request:**
```json
{
  "name": "Ward42",                              // optional, 2-100 chars
  "logoUrl": "https://example.com/logo.png"      // optional, max 500 chars
}
```
**Response:** `200` `PodSettingsResponse` (as above, with `displayName` recomputed)
**Errors:** 400 Validation error (`{ code: "validation_error", message: string }`) | 401 Unauthorized | 403 Not pod chief | 404 Pod not found

There is **no** logo file-upload endpoint. `logoUrl` is a URL the caller supplies;
multipart upload is not implemented.

---

## Messages

`admin_welcome` messages are created by `POST /pod/administrators` and carry `metadata.tasks`, a list of strings.

### GET /messages
List messages for authenticated user with optional filtering.

**Query:** `?status={status}&type={type}&page={n}&size={n}`
**Response:** `MessageListResponse`
```json
{
  "items": Message[],
  "total": number,
  "page": number,
  "unreadCount": number
}
```
**Errors:** 401 Unauthorized

### GET /messages/{id}
Get single message details.

**Response:** `Message`
**Errors:** 401 Unauthorized | 404 Not found

### PATCH /messages/{id}/read
Mark message as read.

**Response:** `Message`
**Errors:** 401 Unauthorized | 404 Not found

### POST /messages/{id}/action
Perform action on message (accept, decline, approve, reject, confirm, etc.).

**Request:** `{ action: string, note?: string }`
**Response:** `Message`
**Errors:** 400 Invalid action | 401 Unauthorized | 404 Not found | 409 Already actioned

---

## Support Access

Temporary super user access to a live pod. See [`domain/support-grant.md`](../../domain/support-grant.md).
All three endpoints require an authenticated admin with role `pod_chief`.

### GET /support-access/grants
List support grants for the caller's pod, newest first.

**Query:** `?status={active|expired|revoked}` (optional; omit for all)
**Response:** `SupportGrantListResponse`
```json
{
  "items": SupportGrant[],
  "total": number
}
```
**Errors:** 401 Unauthorized | 403 Not pod chief

### POST /support-access/grants
Grant the super user temporary access.

**Request:**
```json
{
  "grantedRole": "pod_admin",
  "purpose": "Investigate duplicate issue reports in sector 3"
}
```
`grantedRole` is an `AdminRole` wire value strictly below `pod_chief`. `purpose` is required, 10-500 chars.

**Response:** `201` `SupportGrant`
```json
{
  "id": "uuid",
  "grantedRole": "pod_admin",
  "purpose": "Investigate duplicate issue reports in sector 3",
  "status": "active",
  "grantedBy": "uuid",
  "grantedByName": "Thandi Mokoena",
  "grantedAt": "2026-09-05T10:00:00Z",
  "expiresAt": "2026-09-05T11:00:00Z",
  "lastActivity": null,
  "revokedAt": null,
  "expiredAt": null
}
```
**Errors:** 400 Validation failed (`{ messages: string[] }`) | 401 Unauthorized | 403 Not pod chief | 409 Active grant already exists (`{ code: "active_grant_exists", message: string }`)

### DELETE /support-access/grants/{id}
Revoke an active grant immediately.

**Response:** `204` No Content
**Errors:** 401 Unauthorized | 403 Not pod chief or grant belongs to another pod | 404 Not found | 409 Grant is not active (`{ code: "grant_not_active", message: string }`)

### GET /support-access/grants/current
Grant-scoped tokens only (minted by `/auth/admin/login` under a support grant). Returns the
caller's own grant, so the client can refresh a slid `expiresAt`.

**Response:** `200` `SupportGrant` (same shape as above)
**Errors:** 401 Not authenticated | 403 Not a support grant token (`{ code: "not_support_grant", message: string }`), or the grant is revoked or expired (empty body: the activity filter clears the token's authentication before the controller runs)
