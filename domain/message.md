# Message

## Definition
A system-generated notification to a member or administrator that may require an action, such as accepting an invitation or verifying an issue.

## Why it exists
The system has to ask people to do things and record whether they did. Messages are that record, independent of how they are delivered.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `MessageType`, `MessageStatus` (in `com.munserv.shared.enums`), `MessageService`, `MessageFactory` |
| Database | `messages`, enums `message_type`, `message_status` |
| TypeScript | `Message`, `MessageType`, `MessageStatus`, `MESSAGE_ACTION_TYPES` |
| Dart | `MessageType`, `MessageStatus`, messages pages |

## Values
Status: `unread` → `read` → `actioned` or `dismissed`.

Types: `ground_admin_invitation`, `ground_admin_application`, `ground_admin_approved`, `ground_admin_declined`, `ground_admin_invitation_declined`, `ground_admin_invitation_accepted`, `ground_admin_revocation`, `ground_admin_stepdown_request`, `verify_new_issue`, `verify_fix`, `member_registration`, `monthly_report`.

## Invariants
- Actionable types carry an action payload; acting on a message performs the domain operation (for example accepting a ground admin invitation) and marks it `actioned`.
- A message is addressed to one recipient: a member or an admin.

## Relationships
- Produced by [ground admin](ground-admin.md) and [verification](verification.md) flows and by member registration.

## Say / do not say
- Say **message** for the record. Say **notification** only for a delivery channel (push, email), which is a future feature.

## Decided by
Ground admin messaging feature spec; V015, V016, V020, V024.
