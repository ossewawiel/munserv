# Audit

## Definition
The append-only security log of super user and support-access actions.

## Why it exists
Central Authority staff can reach into any pod for support. Communities own their data, so every such action must be visible to them afterwards.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.audit.domain.AuditLog`, `AuditAction`, `AuditActorType`, `AuditService` |
| Database | `audit_logs`, enum `audit_action_type` |
| TypeScript | none yet (session history view is story W30) |
| Dart | none |

## Values
`SUPER_USER_LOGIN_SUCCESS`, `SUPER_USER_LOGIN_FAILURE`, `POD_CHIEF_CREATED`, `SUPPORT_ACCESS_GRANTED`, `SUPPORT_ACCESS_REVOKED`, `SUPPORT_ACCESS_EXPIRED`, `SUPPORT_ACCESS_LOGIN`, `SUPPORT_ACCESS_ACTIVITY`.

These are the only wire values written in `UPPER_CASE`; they predate the snake_case rule and are kept for compatibility.

## Invariants
- Rows are never updated or deleted.
- Every entry records actor type, actor, action, timestamp and a detail payload.

## Say / do not say
- Say **audit log**. Application logs are not the audit log, and issue state history is a different record.

## Decided by
Story B7, issue #48; V034.
