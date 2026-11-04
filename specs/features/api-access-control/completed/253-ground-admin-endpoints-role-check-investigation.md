# Investigation: ground admin management has no role check, and revoke breaks a database constraint

Issue: #253 · Investigated 2026-11-04 · Platform: backend · Fix handoff: `253-ground-admin-endpoints-role-check-backend.md`

## Problem
A member token passes the only gate on seven admin endpoints, because `SecurityConfig` asks for a login and no code asks for a role. Two endpoints fully work for a member today. Four others stop only by accident, on a lookup or a foreign key. Revoke fails for everyone, admins included.

A member opens the app, copies their token and calls `GET /sectors/{id}/ground-admins`. The answer holds the name and phone number of each ground admin in the sector. The same member sends `PATCH …/status` with `on_hold`, and a ground admin stops receiving verification requests. A ground admin that an admin put on hold can set themselves back to `active`.

## Evidence
"Test" means a throwaway copy of `b030f1a` under the scratchpad, on a Testcontainers database, running `GroundAdminEndpointsAccessTest` before any fix. The copy changed no file in this checkout, and no test touched the dev database or a running stack. Each case set up a real target: a pending application for approve and decline, an invitation for revoke invitation, and an active ground admin for revoke, status and list. Each refusal compared the member row, the application rows and the message count before and after.

| Endpoint | Plain member | Active ground admin | No token | Six admin roles | Support grant |
|---|---|---|---|---|---|
| `POST …/invite` | `404` `Admin not found` | `404` | `401` | `sector_admin`, `sector_chief` `200`; other four `403` | `404` |
| `DELETE …/invite/{id}` | `500` | `500` | `401` | `200` | `500` |
| `POST …/approve` | `500` | `500` | `401` | `200` | `500` |
| `POST …/decline` | `500` | `500` | `401` | `200` | `500` |
| `POST …/revoke` | `500` | `500` | `401` | `500` | `500` |
| `PATCH …/status`, `on_hold` | **`200`, changed** | **`200`, changed** | `401` | `200` | `200` |
| `PATCH …/status`, `inactive` | not run | not run | not run | `500` (`sector_admin`) | not run |
| `GET /sectors/{id}/ground-admins` | **`200`, with phones** | **`200`, with phones** | `401` | `200` | `200` |

Two further cases ran on the same copy. A member approving their own application got `500` and nothing changed. A ground admin on hold who sent `active` for themselves got `200`, and the status changed.

The `500` cases carry two database errors in the test log: `ground_admin_applications_processed_by_fkey` and `ck_members_ground_admin_status`.

## Steps taken
1. Read the issue and its reproduction, `domain/ground-admin.md`, `admin-role.md`, `support-grant.md`, the wire contract, and the #169 record and handoff.
2. Followed each request through `SecurityConfig`, `RoleAuthorizationAspect`, `GroundAdminController`, `GroundAdminService`, `Member`, and migrations V018, V020, V022 and V023.
3. Read the constraints from `pg_constraint` with a read-only query. They match the migrations.
4. Searched `mobile/lib`, `mobile/test`, `web/src`, `web/e2e`, `scripts/`, `infrastructure/mock-api` and `backend/src/test` for each route.
5. Ran the test on the unmodified copy: 79 cases, 44 failed as listed above.
6. Applied the fix in the handoff to the copy and ran the test, the existing tests and `ktlintMainSourceSetCheck`. The results are under "What was verified".

## Root cause
All seven endpoints share one gap. `SecurityConfig.kt:84-85` sets `/api/v1/members/**` to `authenticated()`, because members use the same path for `/members/me/...`. The list route falls to `anyRequest().authenticated()` at line 102. `GroundAdminController` has no `@RequireRole`, and `GroundAdminService` never reads a role. Revoke has a second, separate cause.

### `POST /members/{id}/ground-admin/invite`
`GroundAdminController.kt:211-228` parses the subject into `MemberId` and calls the service. `GroundAdminService.kt:249` looks the subject up in `admins`. A member id is not there, so the answer is `404`. The lookup blocks the member by accident, and it blocks a support grant the same way.

### `DELETE /members/{id}/ground-admin/invite/{applicationId}`
`GroundAdminController.kt:242-268` calls the service, and `GroundAdminService.kt:320` writes the subject to `processed_by`. V023 lines 23-25 point `processed_by` at `admins(id)`, so PostgreSQL refuses a member id or a grant id. The exception becomes `500`, and the transaction rolls back.

### `POST /members/{id}/ground-admin/approve` and `/decline`
`GroundAdminController.kt:282-300` and `:314-340` follow the same path. `GroundAdminService.kt:348` and `:395` write `processed_by`. The foreign key is the only thing that stops a member promoting themselves. The foreign key is correct. It is not the bug.

### `POST /members/{id}/ground-admin/revoke`
`GroundAdminController.kt:354-371` has the same missing gate. The call then fails for every caller, with a cause of its own.
1. `Member.kt:86-91` sets `isGroundAdmin = false` and `groundAdminStatus = INACTIVE`.
2. V018 lines 14-20 allow `FALSE` only with a null status, and `TRUE` only with a status.
3. `GroundAdminService.kt:434` saves the row, and PostgreSQL refuses it.

`backend-phase-4.md:207-211` planned the method this way, and no test runs it against the database. Revoke has therefore never worked.

### `PATCH /members/{id}/ground-admin/status`
`GroundAdminController.kt:385-402` has the missing gate. `GroundAdminService.kt:457` receives `adminId` and never reads it. `active` and `on_hold` write the row at once, so a member token succeeds. `inactive` calls the same `demoteFromGroundAdmin` at line 474, and it fails as revoke does.

### `GET /sectors/{id}/ground-admins`
`GroundAdminController.kt:414-429` checks only that the subject parses as a UUID. `GroundAdminService.kt:502` copies `member.phone` into the response. `specs/contracts/api.md:319-340` shows no phone in this response, and promises `403`.

### Why no test caught it
`GroundAdminControllerTest` mocks the service and sends a member token to the admin routes, so it asserts the gap as correct behaviour. `GroundAdminServiceTest` mocks the repositories, so no foreign key or check constraint runs. Lines 484 and 538 assert `!it.isGroundAdmin`, and `MemberGroundAdminTest:138-139` asserts both values the constraint refuses.

## Settled from the code

### 1. Which roles may call each endpoint
The floor is `SECTOR_ADMIN` on all seven. `AdminRole.hasPermission` (`Admin.kt:113`) compares ordinals, so this admits all six roles.

| Endpoint | Floor | Basis |
|---|---|---|
| invite, approve, decline, revoke, `PATCH status` | `SECTOR_ADMIN` | `admin-role.md:20`: a sector admin can "manage ground admins". Contract: "admin only". `ground-admin-messaging/spec.md` GA2, GA4, GA8. `backend-phase-4.md:848-917` planned these roles, and the annotations never landed. |
| revoke invitation | `SECTOR_ADMIN` | Not in the contract. It undoes an invite, so it takes the floor of invite. The handoff adds it to the contract. |
| list | `SECTOR_ADMIN` | Contract: `403`. `backend-phase-4.md:934`. Personal data. |

A ground admin stays refused. `ground-admin.md` defines a ground admin as a member with no web access.

**The invite sector rule stays.** `GroundAdminService.kt:256` compares the member's sector with `admin.sectorId`, which is null for ward and pod roles. Those four roles pass the new gate and still get `403` `Member not in your sector`. This is today's behaviour. `admin-role.md` says a ward admin manages the sectors in the ward, so the rule is too narrow for them. That change belongs to #254.

**Support grants.** The JWT subject of a grant is the grant id (`AuthService.kt:263-267`), and `support-grant.md` says `@RequireRole` endpoints enforce the granted role. A role gate alone leaves grants on `404` and `500`. The fix follows #169:
- The controller passes a null actor for a grant, as `toHistoryActor` does in `IssueController.kt:412`.
- `invited_by` and `processed_by` are nullable, so they stay null.
- Messages write a null `sender_id` with `sender_type` `system`. V020 allows both.
- `invite` skips the sector check for a grant, because a grant has a pod and no sector. Grant scope belongs to #254.
- The invitation message names "MunServ support" as the sender.

Afterwards, an application row processed under a grant names no admin. Audit entries for grant actions are the gap the #169 record already lists.

### 2. The phone numbers
No member-side client calls the list. `mobile/lib` calls only `/members/me/...` routes (`ground_admin_api.dart:16-57`). The only callers are `web/src/features/ground-admins/hooks.ts:15`, from `GroundAdminsPage.tsx:53` and `SectorSettingsPage.tsx:49`. Both hold an admin session, so the handoff gates the route. Mobile needs no member-safe shape, and there is no decision to make about it.

The gate leaves one question, in decision 3 below: no client reads the `phone` field. `web/src/shared/types/groundAdmin.ts:9-17` has no `phone`, and neither does the contract. The portal reads phone numbers from `/admin/members` instead.

### 3. The revoke fix
The constraint can store `inactive` only with `is_ground_admin = TRUE`. So there are two ways to pass it.

| | A: flag stays true, status `inactive` | B: flag false, status null |
|---|---|---|
| Code | `demoteFromGroundAdmin` drops one line. Every reader that means "holds the role now" uses a new `isCurrentGroundAdmin`: six in `GroundAdminService`, `VerificationService.kt:231`, two in `AdminController` | `demoteFromGroundAdmin` writes null. One line, and every reader stays correct |
| `domain/ground-admin.md:25` | Holds: `inactive` means "stepped down or revoked" | Breaks: nothing can ever store `inactive`, so the domain needs editing |
| `?status=inactive`, contract line 322, the query at `JpaMemberRepository.kt:41-49` | Can match rows | Can never match |
| Web Inactive tab, `GroundAdminsPage.tsx:69`, and the disabled row at line 234 | Have rows to show | Dead code in web |
| Enum value `inactive` | In use | Unreachable. Removing it needs a migration and a change on three platforms |
| Reader left unchanged | A revoked member sees pending verifications. The test proves this reader needs the change | No risk |
| Migration | None | None |

**The handoff follows A.** Five sources agree that `inactive` is a state a row can hold: the domain, the contract, the backend query, the web page and the mobile enum. `demoteFromGroundAdmin` is the one outlier. B is smaller today, but it changes the domain to fit the bug and leaves a value that nothing can reach. A costs about ten changed lines and needs a test on each reader.

Afterwards a tester sees this: the revoked person stays on the Ground Admins page as Inactive with the actions disabled. On the Members page they show the invite action again, because `/admin/members` sends `isGroundAdmin: false`. They can apply again, and `promoteToGroundAdmin` resets `since` and the response rate.

**`PATCH status` with `inactive` answers `400`.** Contract line 266 allows only `active | on_hold`, `web/src/features/ground-admins/api.ts:68` sends only those, and the Swagger text says the same. `ground-admin.md:30` says revocation produces a message, and this route has no reason to put in one. Revoke stays the single way to end the role.

**Existing tests.**

| Test | Today | After |
|---|---|---|
| `MemberGroundAdminTest:127-141` | Asserts flag false and `INACTIVE`, the pair the constraint refuses | Asserts flag true, `INACTIVE`, `isCurrentGroundAdmin` false. Renamed |
| `MemberGroundAdminTest:218-228` | Asserts `INACTIVE` | Passes unchanged |
| `MemberGroundAdminTest:144-157` | Asserts `since` is kept | Passes unchanged |
| `GroundAdminServiceTest:484` | `!it.isGroundAdmin` | Status `INACTIVE` and not `isCurrentGroundAdmin` |
| `GroundAdminServiceTest:529-539` | `should demote when status set to INACTIVE` | `ValidationError`, no save |
| `GroundAdminControllerTest`: `Invite`, `Approve`, `Revoke`, `UpdateStatus`, `ListGroundAdmins` | Member token, `200` | Admin token `…0020`; would otherwise answer `403` |

**The message write on revoke is a bug.** `GroundAdminService.kt:444-445` writes `senderId` as the admin and `senderType` as `"member"`. Approve (`:364-365`) and decline (`:406-407`) do the same. Invite (`:283-284`) and `MessageFactory.kt:42-43` write `"admin"`, and V020 line 45 allows `admin`. The test confirms `member` on approve and decline for all six roles. The effect is small today: `sender_id` has no foreign key, so nothing fails, and neither web nor mobile reads `senderType` beyond its type. A later screen would label the admin as a member. The handoff fixes it, because the grant path rewrites these same lines. See decision 4.

### 4. Member routes stay open
`apply`, `accept`, `decline`, `stepdown` and `GET /members/me/ground-admin` keep no role gate. Literal `/members/me/...` paths win over `/members/{memberId}/...` in Spring, so `POST /members/me/ground-admin/decline` still reaches the member method. The test proves all five with member tokens, before and after the fix. `MessageService.kt:190-197` calls the service directly for accept and decline, and the gate sits on the controller, so it stays unaffected.

### 5. Web and mobile keep working
- **Web:** the portal logs in only through `/auth/admin/login` (`web/src/features/auth/api.ts:13`), so it holds an admin or grant token. No web caller uses a member token on the gated routes. `hooks.ts` reads nothing from these responses beyond invalidating queries, so the removed `phone` and the unchanged `{status: "revoked"}` are safe. A grant session has a null `sectorId`, so `useGroundAdmins` does not call the list, today or after.
- **Web filter tabs stay broken:** see the first finding below. The fix neither causes nor cures this.
- **Mobile:** `mobile/lib` calls none of the seven. `isGroundAdminProvider` reads `/members/me/ground-admin`, and a revoked member now gets the same empty answer as any other member.
- **Scripts:** `scripts/dev-seed.py:147` approves with the sector admin token and uses `/members/me/...` with the member token. Its calls pass in the test matrix. The script itself was not run, because it writes to the dev database.
- **Mock API:** it has no ground admin route.

## Findings outside the fix
| Finding | Status | Where it goes |
|---|---|---|
| **The status filter refuses every wire value.** `?status=active`, `on_hold` and `inactive` answer `400`; only `ACTIVE`, `ON_HOLD`, `INACTIVE` work. `EnumConverters.kt` has no converter for `GroundAdminStatus`. So the Active, On Hold and Inactive tabs and the sector settings count all get `400` today. `SectorSettingsPage.tsx:72` then shows `0`. | `400` verified by test on clean master; web result read in code | Own issue. Small: one converter |
| **Application and step-down messages go to members, not admins.** `findAdminsBySectorId` (`JpaMemberRepository.kt:59-67`) selects active `members` with a password. In the test, an application and a step-down each messaged every such member, with none in `admins`. The applicant's name reaches their neighbours, and no admin is told. | Verified by test | Own issue, high priority |
| **A step-down never takes effect.** `requestStepDown` only sends messages. The row stays `active`, as the test shows. `MessageService.kt:182` handles only invitation actions, so approving the message changes nothing. `inactive` is reachable only through revoke. | Row verified by test; message path read in code | Own issue |
| **An admin from another sector passes.** With the fix applied, the sector admin of `…0001` got `200` on approve, status, revoke and list for sector `…0002`. Invite answered `403`. | Verified by test | #254 |
| **The portal has no approve path.** `useApproveGroundAdmin` and `ApproveDialog` have no caller, and a message action on an application does not reach `approveApplication`. Only `dev-seed.py` calls it. | Read in code, not run | Own issue |
| **`declineInvitation` addresses the inviting admin as a member.** `GroundAdminService.kt:162` writes `recipientType = "member"`. | Read in code, not run | Own issue |
| **The contract has drifted.** Revoke and approve promise a `member` in the response and do not send one. An unknown sector answers `200` with an empty list, not `404`. `types.md:210-219` lists `pending`, `approved`, `rejected`, `revoked` for `GroundAdminStatus`, against `active`, `on_hold`, `inactive` in the domain. | `200` on unknown sector verified; the rest read | Own issue |
| **Verifications assigned to a revoked ground admin stay pending.** Nothing reassigns them, and the pending list of every other ground admin leaves them out, because `assigned_to` names someone else. | Read in code, not run | Own issue, with the assignment rules |
| **`IssueStateTest` hit its null failure in one full run.** See "What was verified". | Verified | #261 |

## What was verified
All of this ran on the throwaway copies, on Testcontainers.
- Before the fix: the table under "Evidence", and `1264` tests with `0` failed on clean master.
- After the fix, `GroundAdminEndpointsAccessTest` passes in full:
  - Seven calls for a plain member and an active ground admin: `403`, snapshot unchanged, no `+27` in the body.
  - Seven calls with no token: `401` `UNAUTHENTICATED`, unchanged.
  - Six roles over seven calls: `200`, with `processed_by` or `invited_by` and message sender as the admin, and `sender_type` `admin`. Ward and pod roles on invite: `403`, unchanged.
  - Support grant over seven calls: `200`, null actors, null sender, `sender_type` `system`.
  - Revoke lifecycle, pending verifications, new invitation after revoke, `inactive` refused with `400`, no `phone`, member routes.
- The full backend suite ran twice on the fixed copy. The final run passed: `1344` tests, `0` failed. An earlier run had `1343` tests and one failure, `IssueStateTest` `isClosed should be inverse of isOpen`, with the null from #261. That class passes alone, and the failure did not repeat, so it depends on order and not on this fix.
- The requests in the Eyeball probes ran through MockMvc on the fixed copy and gave the expected answers: member `403` on seven, then `200`, `404`, `404`, `409` on the member routes; no token `401`; sector admin `400` on `inactive`.
- `ktlintMainSourceSetCheck` reports nothing on the changed `main` files.
- `ktlintTestSourceSetCheck` was not clean on the scratch test, which is not delivered. The implementer writes that test and `ktlintCheck` gates it.

## What is inferred
- The web page behaviour after a revoke, and the tab errors. They come from reading the components, not from running a browser.
- `scripts/dev-seed.py` passes. The calls it makes pass in the test. The script was not run.
- A grant with a role other than `sector_admin` behaves the same. The aspect compares role ordinals, and `SupportAccessRoleAuthorizationTest` covers the aspect. Only `sector_admin` ran here.

## Affected components
### Backend (fix)
- `groundadmin/api/GroundAdminController.kt`: seven gates, the actor extension.
- `groundadmin/service/GroundAdminService.kt`: nullable actor, the invite grant path, `isCurrentGroundAdmin`, sender type, `inactive` refusal, no phone.
- `groundadmin/domain/GroundAdminApplication.kt`, `groundadmin/api/GroundAdminDto.kt`, `auth/domain/Member.kt`.
- `verification/service/VerificationService.kt:231`, `admin/api/AdminController.kt:202` and `:300-301`.
- Three existing test classes and one new one. `domain/ground-admin.md`, `specs/contracts/api.md`.

### Web, mobile, scripts, database (no change)
No caller changes. The constraint and the foreign keys stay. No migration.

## Fix approach
1. Write `GroundAdminEndpointsAccessTest`, with real targets and before-and-after snapshots, and watch it fail.
2. Keep the row on revoke with status `inactive`, and add `isCurrentGroundAdmin` for each reader.
3. Add `@RequireRole(AdminRole.SECTOR_ADMIN)` to the seven methods, and pass a null actor for a grant.
4. Remove the phone field, refuse `inactive` on `PATCH status`, and correct the sender type.
5. Update the existing tests, the contract and the domain file.

## Decisions for the user
The handoff is written to the recommended option in each case.
1. **What a revoke stores.** Recommended: option A above, flag true with status `inactive`. Option B is one line, but it needs a domain edit, leaves web dead code and leaves an enum value nothing can reach.
2. **`PATCH status` with `inactive`.** Recommended: `400`, because the contract excludes it and it cannot carry a reason. The alternative is to treat it as a revoke with a stock message.
3. **The `phone` field.** Recommended: remove it, since no client reads it and the contract never had it. It also stops support staff and admins of other sectors reading phones from this route until #254. They can still read them from `/admin/members`. The alternative is to keep it for admins and add it to the contract.
4. **`sender_type` on approve, decline and revoke.** Recommended: fix it now, because the grant path rewrites those lines. The issue did not name it. To leave it out, keep `"member"` when `adminId` is not null and drop the sender type assertions from AC2.

## Risk
- **Medium: a reader of `isGroundAdmin` that the search missed.** It would treat a revoked member as a ground admin. The search covered `backend/src/main` and all client code. `VerificationService.kt:169` and `:217` already check for `ACTIVE`, and the dashboard counts in `PodDashboardRepository` already filter on `active`.
- **Low: an unlisted caller with a member token.** It gets `403` instead of its old answer. The search found none.
- **Low: a new test can shift test order and expose #261.** The implementer reruns once and reports it.
- **Open after this fix:** an admin from another sector still passes on six of the seven endpoints (#254), and the filter and message recipient findings above remain.
