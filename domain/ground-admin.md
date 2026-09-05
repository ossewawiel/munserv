# Ground admin

## Definition
A trusted member who verifies issues and fixes on the ground for their sector. This is the implemented name for what the early spec called a community administrator.

## Why it exists
Sector administrators need eyes on the street. Ground admins are members with extra trust and no web access.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.groundadmin.domain.GroundAdminApplication`, `ApplicationStatus`, `ApplicationType`, `GroundAdminStatus`, flags on `Member` (`isGroundAdmin`, `groundAdminStatus`, `groundAdminSince`, `groundAdminResponseRate`) |
| Database | `ground_admin_applications`, enum `ground_admin_status`, columns on `members` |
| TypeScript | `GroundAdmin`, `GroundAdminStatus`, `GroundAdminApplication` |
| Dart | `GroundAdminStatus`, ground admin pages |

## Becoming one
Two paths, both recorded as a `GroundAdminApplication`:
- `application`: the member applies; a sector admin approves or declines.
- `invitation`: a sector admin invites; the member accepts or declines.

Application status: `pending` → `approved` | `declined` (application path) or `accepted` | `rejected` (invitation path); `withdrawn` when the member pulls out.

## Status once active
`ground_admin_status`: `active` (receives requests), `on_hold` (paused for low response rate), `inactive` (stepped down or revoked).

## Invariants
- A ground admin is always also a [member](member.md) of the same sector.
- A sector's minimum number of ground admins is a sector setting; the portal warns below it.
- Revocation and step-down produce [messages](message.md).

## Relationships
- Is a [member](member.md); belongs to a [sector](sector.md); handles [verifications](verification.md).

## Say / do not say
- Say **ground admin**. Do not say "community administrator", "community admin" or "verifier".

## Decided by
Ground admin lifecycle and messaging feature (January 2026), V013, V018, V022.
