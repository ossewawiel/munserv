# Sector

## Definition
The operational unit where issues are reported and managed: a ward, community or defined geographic area with a boundary, a member base and its own administrators.

## Why it exists
Issues are local. Routing every report to the people responsible for that ground, and letting them approve members who live there, is what keeps the system trustworthy.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.sectors.domain.Sector`, `SectorSettings`, `SectorId` |
| Database | `sectors` (`center` and `boundary` as PostGIS geography), `sector_settings` |
| TypeScript | `Sector`, `SectorSettings`, `SectorDashboardStats` |
| Dart | `Sector` |

## Invariants
- A sector belongs to exactly one pod and at most one ward.
- A sector has a `center` point; its `boundary` polygon is optional until boundary editing ships.
- Every member and every issue belongs to exactly one sector. An issue's sector is determined from its GPS location.
- `SectorSettings` holds the sector's [verification](verification.md) mode and the minimum number of [ground admins](ground-admin.md).

## Relationships
- Belongs to a [pod](pod.md), optionally to a [ward](ward.md).
- Has many [members](member.md), [issues](issue.md), sector-level [admins](admin-role.md).

## Say / do not say
- Say **sector**. Do not say "community" for the unit of management (a community is what a sector serves), and do not say "area".

## Decided by
Domain model v0.3; ADR 006 (PostGIS for boundaries).
