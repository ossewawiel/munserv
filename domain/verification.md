# Verification

## Definition
A request for a ground admin to confirm on site that a reported issue exists, or that a fix is real, with an outcome and an optional reason.

## Why it exists
Administrators cannot visit every report. Trusted members on the ground turn a `reported` issue into a `confirmed` one and catch fixes that did not happen.

## Code names
| Platform | Identifier |
|---|---|
| Kotlin | `com.munserv.verification.domain.IssueVerification`, `VerificationType`, `VerificationStatus`, `VerificationOutcome`, `VerificationReason`, `VerificationMode`, `IssueVerificationId` |
| Database | `issue_verifications`, enums `verification_mode`, `verification_reason` |
| TypeScript | `IssueVerification`, `VerificationType`, `VerificationStatus`, `VerificationResult`, `VerificationReason`, `VerificationMode` |
| Dart | `VerificationType`, `VerificationResult`, `VerificationReason` |

## Values
| Set | Values |
|---|---|
| type | `existence` (is the issue real), `fix` (is it fixed) |
| status | `pending` → `completed` or `expired` |
| outcome | `confirmed`, `not_found`, `not_fixed`, `cannot_verify` |
| reason (when declining) | `busy`, `away`, `cannot_find`, `wrong_location`, `not_an_issue` |

## Verification mode (per sector)
How a request reaches ground admins is a [sector](sector.md) setting: `all_notified`, `admin_assigns`, `nearest_auto`, `first_come`.

## Invariants
- A `confirmed` existence outcome moves the issue to `confirmed`; a `not_fixed` fix outcome moves it to `reopened`.
- A ground admin's response rate is derived from verifications answered versus requested.

## Relationships
- Belongs to an [issue](issue.md) and is assigned to a [ground admin](ground-admin.md).
- Creates [messages](message.md) of type `verify_new_issue` and `verify_fix`.

## Say / do not say
- Say **verification**. Do not say "inspection" or "review". "Audit" is the security log.

## Decided by
Ground admin messaging feature spec; V021.
