# Pod

## Definition
One independent deployment of MunServ, with its own database and infrastructure, serving one or more communities.

## Why it exists
Communities pay only for hosting. Isolating each deployment keeps data, cost and configuration local to the community that owns it, and lets a metro, a town and a rural area run very different structures on the same software.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.pod.domain.Pod`, `PodSettings`, `PodSetupStatus`, `SetupStep`, `PodId` |
| Database | `pods`, `pod_setup_steps` |
| TypeScript | `PodDashboardStats`, `PodSetupStatus` (in `usePodSetup`) |
| Dart | `PodConfig` (theme and branding only) |

## States and transitions
A pod is either being set up or set up. Setup is complete when every `SetupStep` is done:

`pod_name` → `pod_boundaries` → `wards_sectors` → `first_admin`

`setupCompletedAt` is set once; there is no "un-setup".

## Invariants
- A deployment currently holds exactly one pod. Code that reads "the current pod" relies on this (tracked in #58 for an explicit decision).
- A pod's display name appears in the portal header as "Munserv Pod {name}".
- Pod settings (name, logo) are editable only by the pod chief.

## Relationships
- Has many [wards](ward.md) (optional) and [sectors](sector.md).
- Has many [admins](admin-role.md) at pod level.
- Is created by [bootstrap](bootstrap.md).

## Say / do not say
- Say **pod**. Do not say "instance", "tenant" or "deployment" in product text; those describe infrastructure, not the community's unit.

## Decided by
ADR 006 (PostGIS), specs/features/pod-chief-mvp, specs/features/pod-chief-bootstrap.
