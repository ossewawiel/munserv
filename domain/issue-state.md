# Issue state

## Definition
Where an issue is in its lifecycle. Only the transitions listed here are legal, and the backend refuses any other.

## Why it exists
Members and administrators need one honest answer to "what is happening with this". A closed set of states with enforced transitions is that answer.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.issues.domain.IssueState` (sealed class; `Reported`, `Confirmed`, `InProgress`, `Fixed`, `Rejected`, `Reopened`, `Closed`) |
| Database | enum `issue_state` |
| TypeScript | `IssueState` union |
| Dart | `IssueState` enum |

## States and transitions
Wire values: `reported`, `confirmed`, `in_progress`, `fixed`, `rejected`, `reopened`, `closed`.

| From | To | Who |
|---|---|---|
| reported | confirmed | Ground admin verifies existence, or sector admin approves |
| reported | rejected | Sector admin: invalid, spam, wrong location |
| confirmed | in_progress | Sector admin: work has started |
| confirmed | rejected | Sector admin |
| in_progress | fixed | Sector admin |
| in_progress | rejected | Sector admin (found invalid during work) |
| fixed | reopened | Ground admin verifies the fix and finds it inadequate |
| fixed | closed | Sector admin after a fix verification succeeds |
| reopened | confirmed | Automatic: back into the queue |

Open states: `reported`, `confirmed`, `in_progress`, `reopened`. Closed states: `fixed`, `rejected`, `closed`.

Known drift: web and mobile lack `reopened` and `closed` (#61).

## Invariants
- `IssueState.canTransitionTo` is the only authority; services return `IssueResult.InvalidTransition` rather than throwing.
- Every transition is recorded in `issue_state_history`.

## Say / do not say
- Say **state** for issues. Say **status** for members, admins, messages, verifications and ground admins.

## Decided by
Domain model v0.3 §4.1 and §4.2; V012 added `closed`.
