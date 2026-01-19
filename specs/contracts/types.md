# Shared Types

> **Full code**: See [MVP_Development_Guide.md §3](../MVP_Development_Guide.md) for TypeScript interfaces and Dart/Freezed classes.

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

---

## Enums

### IssueState

| Value | Description |
|-------|-------------|
| REPORTED | Initial state |
| CONFIRMED | Verified by admin |
| IN_PROGRESS | Being addressed |
| FIXED | Resolved |
| REJECTED | Not valid |

### MemberRole

| Value | Description |
|-------|-------------|
| MEMBER | Regular user |
| ADMIN | Administrator |

### VerificationMode

| Value | Description |
|-------|-------------|
| ALL_NOTIFIED | All Ground Admins notified simultaneously |
| ADMIN_ASSIGNS | Sector Admin manually assigns verification |
| NEAREST_AUTO | Nearest Ground Admin auto-assigned |
| FIRST_COME | First Ground Admin to accept |

---

## ID Types

All IDs are UUID v4 wrapped in type-safe wrappers:

- `MemberId` - Member identifier
- `IssueId` - Issue identifier
- `SectorId` - Sector identifier
- `SectorSettingsId` - Sector settings identifier
- `IssueTypeId` - Issue type identifier
- `PhotoId` - Photo identifier
