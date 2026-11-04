# Investigation: a member token reaches three admin issue endpoints

Issue: #169 · Investigated 2026-11-04 · Platform: backend · Fix handoff: `169-admin-issue-endpoints-role-check-backend.md`

## Problem
A member token passes the only gate on three admin endpoints, because `SecurityConfig` asks for a login and no code asks for a role. `specs/contracts/api.md` promises `403` for two of them. The third, `override-state`, is not in the contract and not in `domain/`.

A member opens the app, copies their token and posts `{"state":"fixed"}` to `override-state` on a pothole report. The issue leaves `reported` for `fixed`, and the pending verification expires. The ground admin's task disappears, and the history still says `reported`.

The issue had no comments on 2026-11-04. Its "To check" list asks for this reproduction.

## Evidence
"Live" means the dev backend on port 8080, reproduced by the requester before this investigation. "Test" means a throwaway copy of `cbae360`, under the scratchpad, on a Testcontainers database. The copy changed no file in this checkout, and no test touched the dev database.

| Caller | `PATCH …/state` | `POST …/request-verification` | `POST …/override-state` | Source |
|---|---|---|---|---|
| Member | `500`, state unchanged | `200` | `200`, `reported` to `fixed` | Live and test |
| No token | `401` | `401` | `401` | Live (PATCH) and test (all) |
| Each of the six admin roles | `200`, `changed_by` is the admin | `200` | `200` | Test |
| Active support grant | `500` | `200` | `200` | Test |

The backend log holds the PATCH failure at 11:46:06 (`~/Work/munserv-console/.console/logs/backend.log`, lines 381840 to 382042):

```
ERROR: insert or update on table "issue_state_history" violates foreign key constraint "issue_state_history_changed_by_fkey"
Detail: Key (changed_by)=(90990aa1-62b9-4699-b66c-23e7ce6d260a) is not present in table "admins".
  at com.munserv.issues.api.IssueController.updateIssueState(IssueController.kt:367)
```

The dev database shows that `90990aa1…` is `thandi.nkosi@example.com` in `members`, with no row in `admins`. The running backend's checkout is at `53c4c6b`. The issue, verification, security and config packages have no diff against `cbae360`.

## Steps taken
1. Read `domain/admin-role.md`, `issue-state.md`, `verification.md`, `ground-admin.md`, `support-grant.md`, `audit.md` and the wire contract.
2. Followed each request through `SecurityConfig`, `JwtAuthenticationFilter`, the two controllers, the two services and migration V010.
3. Read the constraint from `pg_constraint`. It matches V010: `changed_by` references `admins(id)`.
4. Searched `web/src`, `web/e2e`, `mobile/lib`, `mobile/test`, `scripts/` and `backend/src/test` for each endpoint.
5. Ran the proposed test on the unmodified copy. Four cases failed: member PATCH (`500`), member request-verification (`200`), member override (`200`), grant PATCH (`500`). The ground admin case ran only with the fix. Its `200` before the fix is inferred, because a ground admin holds a member token.
6. Applied the proposed fix to the copy. The full backend suite passed: `1264` tests, `0` failed. `ktlintCheck` reported nothing on the changed `main` files.

## Root cause
All three endpoints share one gap. `SecurityConfig.kt:82-83` sets `/api/v1/issues/**` to `authenticated()`, because members use the same path for their own routes. The role check belongs on each admin method, and none of the three has one. Every `@RequireRole` in production code sits on a class, and these two controllers cannot use that form, because they also serve members.

### `POST /issues/{issueId}/request-verification`
`VerificationController.kt:63-73` parses the subject into `MemberId` and calls the service. `VerificationService.kt:51-55` receives `requestedBy` and never reads it. `issue_verifications` has no requester column. The service therefore creates the row and messages every active ground admin in the sector. A member can send those messages at will, one per `pending` slot.

### `POST /issues/{issueId}/override-state`
`VerificationController.kt:93-104` follows the same path. `VerificationService.kt:266-287` receives `adminId` and never reads it. It expires pending verifications and saves `issue.withState(newState)`. `Issue.withState` (`Issue.kt:47`) copies the state with no check, so `canTransitionTo` never runs.

### `PATCH /issues/{id}/state`
The `500` is the same gap, and the requester's suspicion is correct.
1. `IssueController.kt:365` wraps the JWT subject in `AdminId`. It does not check that the subject is an admin.
2. `IssueService.kt:136-139` writes that value to `issue_state_history.changed_by`.
3. V010 line 11 declares `changed_by UUID REFERENCES admins(id)`, so PostgreSQL rejects a member id.
4. The exception falls to `GlobalExceptionHandler.kt:112-118`, which answers `500`.
5. The transaction rolls back, so the state stays unchanged.

The foreign key is correct and acts as an accidental gate. It is not the bug.

### The same foreign key breaks support grants
The JWT subject of a support grant is the grant id (`AuthService.kt:263-267`), and grant ids are not in `admins`. `domain/support-grant.md` says `@RequireRole` endpoints enforce the granted role. A role check alone therefore leaves grant tokens on `500`. The fix passes null for a grant, and `changed_by` is nullable.

### Why no test caught it
`IssuesApiContractTest` and `AdminWorkflowScenarioTest` call `PATCH` with admin tokens only. Step 9 of the scenario test tries a member token on `/api/v1/admin/*`, not on these routes. `VerificationFlowIntegrationTest` uses an admin token. `VerificationServiceTest` calls the service, which has no role logic to test.

## Which roles may call each endpoint
`RoleAuthorizationAspect.kt:79-114` looks up the subject in `admins` and ignores the JWT role claim. It skips soft-deleted admins (`JpaAdminRepository.kt:84`). For a grant it uses the granted role. `AdminRole.hasPermission` (`Admin.kt:113`) compares ordinals, so `@RequireRole(AdminRole.SECTOR_ADMIN)` admits all six roles. A denial answers `403` through `GlobalExceptionHandler.kt:104-110`.

| Endpoint | Floor | Basis |
|---|---|---|
| `PATCH …/state` | `SECTOR_ADMIN` | `admin-role.md`: a sector admin can "change issue states". `issue-state.md` names the sector admin on every admin transition. |
| `request-verification` | `SECTOR_ADMIN` | Contract: "admin only". `verification.md`: administrators send ground admins to the site. `backend-phase-5.md:646` names `SECTOR_ADMIN` and `SECTOR_CHIEF`. |
| `override-state` | `SECTOR_ADMIN`, see decision 1 | `domain/` is silent. `backend-phase-5.md:710` names `SECTOR_ADMIN` and `SECTOR_CHIEF`. `ground-admin-messaging/spec.md:190` says an admin "can always override". |

A ground admin stays refused on all three. `ground-admin.md` defines a ground admin as a member with no web access, and their route is `POST /issues/{id}/verify`. The test run confirms `403` on request-verification for an active ground admin.

## Findings outside the fix
| Finding | Status | Where it goes |
|---|---|---|
| **An admin from another sector passes.** The sector admin of `…0001` got `200` from all three on an issue in `…0002`. | Verified by test, with the fix applied | Own issue |
| **`override-state` writes no history and no audit entry.** `VerificationService` has no history or audit dependency (`VerificationService.kt:40-46`). The dev issue `4a42fcd1…` shows `rejected`, while its last history row says `reported`. A test confirms one history row after an admin override. | Verified | Own issue |
| **`override-state` breaks two domain rules.** `issue-state.md` says the backend refuses illegal moves and records every transition. The endpoint does neither. | Verified | Decision 1 |
| **Verification outcomes write no history.** `VerificationService.updateIssueState` (`VerificationService.kt:366-387`) saves the state with no history row. `issue-state.md` expects one for every transition. | Read in code, not run | Own issue |
| **Support grant actions leave no audit entry.** `SUPPORT_ACCESS_ACTIVITY` is defined at `AuditAction.kt:17` and written nowhere. `recordActivity` updates only `last_activity`. `audit.md` promises that communities can see these actions. | Read in code, not run | Own issue, see decision 2 |
| **Ground admin management has the same missing gate.** `GroundAdminController` `approve` and `revoke` take the principal with no role check, and the service does not read the actor's role (`GroundAdminService.kt:330`, `:419`). A member token reached the demote write in a test. That call then answered `500` on `ck_members_ground_admin_status`, so the outcome for a real ground admin is not established. | Partly verified | Own issue, with its own reproduction |
| **A member can report into another sector.** Member `…0010` of sector `…0001` got `201` creating an issue in `…0002`. | Verified by test; `domain/` was not checked for intent | Check against the mobile flow first |
| **`request-verification` ignores `message`, and does not validate `assignTo` against the sector.** `VerificationService.kt:313-326`. | Read in code, not run | Own issue |

Sector scope is not the same small change. It needs the actor's admin row, a sector-to-ward-to-pod lookup, a grant scope rule, a sector rule for sectors with no ward, and a new refusal result in `IssueService`. Issue #56 covers only admin management, although `admin-role.md` cites it for scope in general. The issue list and report routes need the same decision.

## Affected components
### Backend (fix)
- `issues/api/IssueController.kt`: role annotation at line 349, and a history actor that handles grants at line 365.
- `verification/api/VerificationController.kt`: role annotation at lines 63 and 93.
- `specs/contracts/api.md`: `401` on PATCH, and a new `override-state` entry.

### Web (no change)
The portal logs in only through `/auth/admin/login` (`web/src/features/auth/api.ts:13`), so it holds an admin token or a grant token. It calls `PATCH` from `IssueDetailPage.tsx:44`, and all six roles pass. `useRequestVerification` has no component caller. Nothing calls `override-state`. A bootstrap super user with no grant moves from `500` to `403`, and the interceptor at `web/src/lib/api-client.ts` keeps that session open.

### Mobile (no change)
`mobile/lib` calls none of the three. A ground admin uses `POST /issues/{id}/verify` and `GET /members/me/pending-verifications`, which keep their current behaviour.

### Scripts and tests (no change)
`scripts/dev-seed.py:169` logs in through `/auth/admin/login` as `admin@ward42.example.com`, the `sector_admin` row `…0020`. `VerificationFlowIntegrationTest` uses the same id. `IssuesApiContractTest` and `AdminWorkflowScenarioTest` also use `…0020`. All pass with the fix. The script itself was not run, because it writes to the dev database. The mock API is separate and keeps its behaviour.

### Database (no change)
The foreign key stays. No migration is needed.

## Fix approach
1. Write `IssueAdminEndpointsAccessTest` and watch the five red cases fail.
2. Add `@RequireRole(AdminRole.SECTOR_ADMIN)` to the three methods.
3. Pass a null history actor for a grant token in `updateIssueState`.
4. Update the contract.

`RoleAuthorizationAspect` already has a method-level pointcut at line 39, but no production method used it before. The test run proves it on both controllers. `IssueController` is already a CGLIB proxy, a generated subclass that Spring uses for aspects, as the log stack shows, and `@AuthenticationPrincipal` works through it.

## Decisions for the user
1. **The fate of `override-state`.** The handoff gates it at `SECTOR_ADMIN`, the floor that the only spec names. After that, any sector admin can still skip the legal transitions and leave no history. Raising the floor to `SECTOR_CHIEF` is a one-word change, and matches "final authority in the sector". Removing the endpoint is possible, because no client calls it. Keeping it needs a `domain/` entry and a history write.
2. **A support grant's history row has a null `changed_by`.** The state change succeeds, and the timeline names no actor. Naming the grant needs a migration and a change to the history type. Audit entries for grant actions are a separate gap, listed above.

## Risk
- **Low: an unlisted caller with a member token.** The search covered web, mobile, scripts and tests. Any caller it missed gets `403` instead of `200`.
- **Low: a data residue from the reproduction.** Dev issue `4a42fcd1…` has state `rejected`, a last history row of `reported` and an `expired` verification. This investigation left it as it is.
- **Open after this fix:** an admin from another sector still passes. The fix narrows the gate from any login to any admin or support grant in the pod.
