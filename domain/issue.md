# Issue

## Definition
A reported infrastructure problem at a GPS location inside a sector, with photos, a type, a lifecycle state and a heat score.

## Why it exists
It is the thing the whole system tracks: from a member's photo to a municipal fix, with a visible history.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.issues.domain.Issue`, `IssueStateHistoryEntry`, `IssueId` |
| Database | `issues`, `issue_state_history` |
| TypeScript | `Issue`, `IssueSummary`, `StateHistoryEntry`, `IssueFilterParams` |
| Dart | `Issue`, `IssueFilter`, `StateHistory` |

## Fields that carry meaning
| Field | Meaning |
|---|---|
| `sectorId` | Derived from `location`; a member can only report inside their sector |
| `reporterId` | The first member who reported it; hidden from other members |
| `reportCount` | How many members have reported this same problem; feeds [heat](heat.md) |
| `location`, `address` | GPS point plus an optional reverse-geocoded address |
| `state` | See [issue-state](issue-state.md) |
| `type` | See [issue-type](issue-type.md) |

## Invariants
- An issue is created in state `reported` with heat 10.
- A state change writes an `issue_state_history` row with the actor and an optional note.
- Duplicate reports are linked to the existing issue rather than creating a new one; they raise `reportCount` (manual linking for now).
- Reporter identity is visible to admins only.

## Relationships
- Belongs to a [sector](sector.md) and a reporting [member](member.md).
- Has many [photos](photo.md) and [verifications](verification.md).

## Say / do not say
- Say **issue** for the tracked problem and **report** for one member's submission. Several reports can belong to one issue.
- Do not say "ticket" or "case".

## Decided by
Domain model v0.3 §4; ADR 004 (result pattern for transitions).
