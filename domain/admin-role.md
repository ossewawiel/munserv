# Admin role

## Definition
The six-level administrator hierarchy that manages a pod, its wards and its sectors from the web portal, plus the out-of-band super user used only for bootstrap and support.

## Why it exists
Responsibility follows geography. Each tier of the pod has a chief who sets it up and creates administrators, and administrators who do the daily work.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.admin.domain.Admin`, `AdminRole`, `AdminLevel`, `OnboardingStatus`, `AdminId` |
| Database | `admins`, enums `admin_role`, `onboarding_status` |
| TypeScript | `AdminRole`, `AdminLevel`, `UserRole`, `ADMIN_ROLES`, `ROLE_HIERARCHY`, `SUPER_USER_ROLE` |
| Dart | none (admins use the web portal only) |

## Roles, lowest to highest
| Role | Level | Chief? | Can do |
|---|---|---|---|
| `sector_admin` | sector | no | Approve members, change issue states, manage ground admins, sector reports |
| `sector_chief` | sector | yes | Set up the sector, create sector admins, final authority in the sector |
| `ward_admin` | ward | no | Manage the sectors in the ward, ward reports |
| `ward_chief` | ward | yes | Set up the ward, create ward admins |
| `pod_admin` | pod | no | Cross-sector reports, escalations, scoped sector access |
| `pod_chief` | pod | yes | Full pod setup, create pod admins, pod settings, support access |

`super_user` is not an `AdminRole`. It is a JWT role granted from environment configuration during [bootstrap](bootstrap.md) and, later, through a temporary support grant.

## Onboarding
`onboarding_status`: `pending` → `password_changed` → `profile_complete` → `active`. A new admin receives a temporary password by email and cannot reach the dashboard until the password is changed; profile completion is optional and can be skipped.

## Invariants
- A role can manage only roles below it, and only inside its own pod, ward or sector (ward and sector scope checks tracked in #56).
- An admin has at most one of `podId`, `wardId`, `sectorId` set, matching its level.
- One person may hold roles in several sectors, but each `Admin` row is one role in one place.

## Relationships
- Belongs to a [pod](pod.md), [ward](ward.md) or [sector](sector.md) by level.
- Created by a chief one level up, or by [bootstrap](bootstrap.md) for the first pod chief.

## Say / do not say
- Say the role name. Do not say "community administrator" (that was the spec's name for [ground admin](ground-admin.md)), "manager" or "supervisor".
- Say **chief** for the setup-and-final-authority role at each level.

## Decided by
Issue #18 (sector chief), issue #20 (six-level hierarchy), specs/features/pod-chief-bootstrap.
