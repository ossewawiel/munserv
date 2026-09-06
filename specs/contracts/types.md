# Shared Types

> **Full code**: See [archive/MVP_Development_Guide.md §3](../archive/MVP_Development_Guide.md) for TypeScript interfaces and Dart/Freezed classes.

## Member

| Field | Type | Notes |
|-------|------|-------|
| id | MemberId | UUID |
| phone | string | E.164 format |
| name | string | Display name |
| role | MemberRole | enum |
| sectorId | SectorId | Assigned sector |
| createdAt | DateTime | ISO 8601 |

## Issue

| Field | Type | Notes |
|-------|------|-------|
| id | IssueId | UUID |
| title | string | max 100 chars |
| description | string? | optional, max 1000 |
| state | IssueState | enum |
| typeId | IssueTypeId | Category |
| location | GeoPoint | lat/lng |
| photos | Photo[] | max 5 |
| reporterId | MemberId | Who reported |
| sectorId | SectorId | Where located |
| heat | number | Priority score |
| createdAt | DateTime | ISO 8601 |
| updatedAt | DateTime | ISO 8601 |
| stateHistory | StateHistoryEntry[] | State change audit trail (detail view only) |

## StateHistoryEntry

| Field | Type | Notes |
|-------|------|-------|
| state | IssueState | State after transition |
| changedAt | DateTime | ISO 8601 timestamp |
| changedBy | string? | Admin name (null for system) |
| note | string? | Optional note explaining change |

## Sector

| Field | Type | Notes |
|-------|------|-------|
| id | SectorId | UUID |
| name | string | Display name |
| boundary | GeoPolygon | Geographic area |

## GeoPoint

| Field | Type | Notes |
|-------|------|-------|
| lat | number | -90 to 90 |
| lng | number | -180 to 180 |

## SectorSettings

| Field | Type | Notes |
|-------|------|-------|
| id | SectorSettingsId | UUID |
| sectorId | SectorId | Parent sector |
| newIssueVerificationMode | VerificationMode | enum |
| fixVerificationMode | VerificationMode | enum |
| daysFixedBeforeClosed | number | 1-365 days |
| minimumGroundAdmins | number | 0-100 |
| createdAt | DateTime | ISO 8601 |
| updatedAt | DateTime | ISO 8601 |

## Photo

| Field | Type | Notes |
|-------|------|-------|
| id | PhotoId | UUID |
| url | string | Storage URL |
| thumbnail | string | Thumbnail URL |

## Message

| Field | Type | Notes |
|-------|------|-------|
| id | MessageId | UUID |
| type | MessageType | enum |
| title | string | max 200 chars |
| body | string | Message content |
| recipientId | UUID | Member or Admin ID |
| recipientType | string | "member" or "admin" |
| senderId | UUID? | Optional sender |
| senderType | string? | "member", "admin", "system" |
| status | MessageStatus | enum |
| actionType | string? | Action type for actionable messages |
| relatedEntityId | UUID? | Related entity (issue, application) |
| relatedEntityType | string? | Type of related entity |
| actionResult | string? | Result after action performed |
| metadata | object? | Additional JSON data |
| createdAt | DateTime | ISO 8601 |
| readAt | DateTime? | When marked as read |
| actionedAt | DateTime? | When action performed |
| expiresAt | DateTime? | Optional expiration |

## SupportGrant

Temporary super user access to a pod. See [`domain/support-grant.md`](../../domain/support-grant.md).

| Field | Type | Notes |
|-------|------|-------|
| id | SupportGrantId | UUID |
| grantedRole | AdminRole | Strictly below pod_chief |
| purpose | string | 10-500 chars, required |
| status | SupportGrantStatus | enum |
| grantedBy | AdminId | Pod chief who issued it |
| grantedByName | string | Display name of the pod chief |
| grantedAt | DateTime | ISO 8601 |
| expiresAt | DateTime | grantedAt or lastActivity + 1 hour |
| lastActivity | DateTime? | Null until the super user acts |
| revokedAt | DateTime? | Set when status is revoked |
| expiredAt | DateTime? | Set when status is expired |

### SupportGrantStatus
@enum @serialization(snake_case)

| Value | Description |
|-------|-------------|
| active | Super user may log in |
| expired | Idle for an hour; terminal |
| revoked | Ended by the pod chief or by logout; terminal |

### SupportGrantInfo

Carried as `profile.supportGrant` on the `AdminLoginResponse` returned by `POST /auth/admin/login`
when the super user logs in under an active grant instead of via bootstrap. See
[`domain/support-grant.md`](../../domain/support-grant.md).

| Field | Type | Notes |
|-------|------|-------|
| grantId | SupportGrantId | UUID; also the JWT subject for this login |
| grantedRole | AdminRole | The role carried by the minted token, never super_user |
| expiresAt | DateTime | The grant's own, server-owned, sliding expiry |

---

## Enums

> **Type Generation:** Enums with `@generate` annotations can be auto-generated using `/generate-types` or `./scripts/generate-types.sh`.
> All enum values use **snake_case** for JSON serialization.

### IssueState
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| reported | Initial state |
| confirmed | Verified by admin |
| in_progress | Being addressed |
| fixed | Resolved |
| rejected | Not valid |

### MemberRole
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| member | Regular user |
| admin | Administrator |

### VerificationMode
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| all_notified | All Ground Admins notified simultaneously |
| admin_assigns | Sector Admin manually assigns verification |
| nearest_auto | Nearest Ground Admin auto-assigned |
| first_come | First Ground Admin to accept |

### MessageType
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| ground_admin_invitation | Invitation to become Ground Admin |
| ground_admin_application | Application to become Ground Admin |
| ground_admin_approved | Application/invitation approved |
| ground_admin_declined | Application/invitation declined |
| ground_admin_invitation_declined | Member declined invitation |
| ground_admin_revocation | Ground Admin status revoked |
| ground_admin_stepdown_request | Request to step down |
| verify_new_issue | Request to verify new issue |
| verify_fix | Request to verify fix |
| member_registration | New member registration notification |
| monthly_report | Monthly activity report |
| admin_welcome | Welcome message with initial tasks for a new administrator |

### MessageStatus
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| unread | Not yet read |
| read | Marked as read |
| actioned | Action performed |
| dismissed | Dismissed by recipient |

### GroundAdminStatus
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| pending | Awaiting approval |
| approved | Active ground admin |
| rejected | Application denied |
| revoked | Access removed |

### VerificationReason
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| new_issue | Verify new issue report |
| fix_verification | Verify issue has been fixed |

---

## ID Types

All IDs are UUID v4 wrapped in type-safe wrappers:

- `MemberId` - Member identifier
- `IssueId` - Issue identifier
- `SectorId` - Sector identifier
- `SectorSettingsId` - Sector settings identifier
- `IssueTypeId` - Issue type identifier
- `PhotoId` - Photo identifier
- `MessageId` - Message identifier
- `SupportGrantId` - Support grant identifier
