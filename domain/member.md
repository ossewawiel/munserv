# Member

## Definition
A community resident, registered on the web portal and approved by a sector administrator, who reports and views issues through the mobile app.

## Why it exists
High-trust communities. A member is vouched for by an administrator before they can report, which keeps spam and bad actors out without needing SMS verification.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.auth.domain.Member`, `MemberStatus` (sealed), `MemberId` |
| Database | `members`, enum `member_status` |
| TypeScript | `Member`, `MemberStatus`, `MemberProfile`, `MemberListItem` |
| Dart | `Member`, `MemberStatus` |

## States and transitions
`member_status`: `pending_approval` → `active` ↔ `suspended`; any state → `deleted` (terminal).

| From | To | Who |
|---|---|---|
| pending_approval | active | Sector admin approves (welcome email with temporary password) |
| pending_approval | deleted | Sector admin rejects |
| active | suspended | Sector admin, for policy violation |
| suspended | active | Sector admin reinstates |
| any | deleted | Sector admin; audit trail kept |

Known drift: web and mobile still carry the old `pending` value and lack `deleted` (#61).

## Invariants
- Email is the username; phone and address are contact and residency data, visible to admins only.
- First login after approval forces a password change, then PIN setup; biometric login is optional after that.
- A member belongs to exactly one sector and can only report inside it.
- Other members never see who reported an issue.

## Relationships
- Belongs to a [sector](sector.md).
- Reports [issues](issue.md).
- May become a [ground admin](ground-admin.md).

## Say / do not say
- Say **member**. Do not say "user", "citizen" or "resident" in product text.

## Decided by
Domain model v0.3 §2.5 to §2.7 and §10.1 (email + password, web registration, admin approval).
