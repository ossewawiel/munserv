# Support grant

## Definition
A time-boxed permission, issued by the pod chief, that lets the super user log in to a live pod
under a named role for a stated purpose, and that ends on logout, on revocation, or after an hour
without activity.

## Why it exists
[Bootstrap](bootstrap.md) access dies once the pod chief is onboarded, but Central Authority staff
still have to help with real problems on a running pod. The community stays in control: the pod
chief decides when support may look, under which role, and for how long, and every grant is in the
[audit](audit.md) log.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.support.domain.SupportGrant`, `SupportGrantId`, `SupportGrantStatus`, `com.munserv.support.service.SupportAccessService`, `SupportAccessResult`, `SupportGrantExpiryJob`, `com.munserv.support.repository.SupportGrantRepository`, `com.munserv.support.api.SupportAccessController`, `SupportGrantActivityFilter` |
| Database | `support_grants` |
| TypeScript | `SupportGrant`, `SupportGrantStatus`, `GrantSupportAccessRequest` (stories W28 to W30) |
| Dart | none (support access is web-only) |

## Statuses and transitions
`support_grant_status`: `active`, `expired`, `revoked`.

| From | To | When |
|---|---|---|
| `active` | `revoked` | The pod chief revokes the grant, or the super user logs out |
| `active` | `expired` | The expiry job finds `expires_at` in the past |

`expired` and `revoked` are terminal. A grant is never reopened; the pod chief issues a new one.

## Invariants
- A pod has at most one `active` grant at a time.
- The granted role is strictly below `pod_chief` in the [admin role](admin-role.md) hierarchy.
- Purpose is required and recorded; a grant without a stated reason is not created.
- `expires_at` is always one hour after the later of `granted_at` and `last_activity`; activity by
  the super user slides the window forward, it never extends beyond one idle hour.
- Grant, revocation and expiry each write an [audit](audit.md) entry.

## Relationships
- Belongs to a [pod](pod.md); granted by the pod chief of that pod ([admin-role](admin-role.md)).
- Grants the `super_user` JWT role, the same role [bootstrap](bootstrap.md) issues.
- Produces `SUPPORT_ACCESS_GRANTED`, `SUPPORT_ACCESS_REVOKED`, `SUPPORT_ACCESS_EXPIRED`,
  `SUPPORT_ACCESS_LOGIN` [audit](audit.md) entries.

## Say / do not say
- Say **support grant** for the record and **support access** for the capability it confers.
- Do not say "session" (a grant outlives any one login), "impersonation", "backdoor",
  "elevation" or "super user account" (the super user has no account, only environment credentials).
- Say **status** for a grant, never "state"; state belongs to issues.

## Decided by
Story B8, issue #49; specs/features/pod-chief-bootstrap; migration V035.
