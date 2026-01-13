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

---

## ID Types

All IDs are UUID v4 wrapped in type-safe wrappers:

- `MemberId` - Member identifier
- `IssueId` - Issue identifier
- `SectorId` - Sector identifier
- `IssueTypeId` - Issue type identifier
- `PhotoId` - Photo identifier
