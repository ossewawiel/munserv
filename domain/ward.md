# Ward

## Definition
An optional grouping tier inside a pod that holds several sectors, used by large pods to reduce span of control.

## Why it exists
A metro pod can have dozens of sectors. Wards give pod-level administrators a middle tier to delegate to, with their own chief and administrators.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `WardId`; ward-level roles in `AdminRole` (`WARD_ADMIN`, `WARD_CHIEF`) |
| Database | `wards` (V027), `admins.ward_id`, `sectors.ward_id` |
| TypeScript | `WardDashboardStats`; ward entries in `PodSetupStatus.wards` |
| Dart | none (members never see wards) |

## Invariants
- A ward belongs to exactly one pod.
- A sector may belong to at most one ward; sectors without a ward report straight to the pod.
- Ward administrators may act only on sectors inside their ward (enforcement gap tracked in #56).
- Whether a pod calls this tier "ward" or shows sectors directly is pod configuration; the portal labels adapt.

## Relationships
- Belongs to a [pod](pod.md).
- Has many [sectors](sector.md).
- Has [admins](admin-role.md) at ward level.

## Say / do not say
- Say **ward**. Do not say "sector group" (the unimplemented term from the early spec) or "region".

## Decided by
Roles expansion, issue #20 (six-level hierarchy with ward roles).
