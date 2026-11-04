---
issue: 169
story: FIX169
title: "Only admins and support grants may change issue state or request a verification"
platform: backend
status: completed
depends_on: []
touches: [api-access-control]
ui: false
user_facing: true
eyeball_exempt: [AC6]
design_canvas: ""
design_artboards: []
design_approved: false
created_by: investigator
created_at: "2026-11-04"
files_changed:
  - backend/src/main/kotlin/com/munserv/issues/api/IssueController.kt
  - backend/src/main/kotlin/com/munserv/verification/api/VerificationController.kt
  - backend/src/test/kotlin/com/munserv/issues/api/IssueAdminEndpointsAccessTest.kt
  - specs/contracts/api.md
tests_added:
  - backend/src/test/kotlin/com/munserv/issues/api/IssueAdminEndpointsAccessTest.kt
---

# #169 · Admin issue endpoints check the role (Backend)

Read `domain/README.md`, `domain/admin-role.md` and `domain/support-grant.md` first. This handoff is complete on its own. The evidence is in `169-admin-issue-endpoints-role-check-investigation.md`; read it only if a step surprises you.

## Outcome
A member gets `403` from the three admin issue endpoints, and every admin role and active support grant still succeeds.

## Acceptance criteria
- [ ] AC1 A member token, also one of an active ground admin, gets `403` `FORBIDDEN` from `PATCH /issues/{id}/state`, `POST /issues/{issueId}/request-verification` and `POST /issues/{issueId}/override-state`. The issue, its history and its verifications stay unchanged.
- [ ] AC2 Each of the six admin roles gets `200` from all three. After `PATCH`, the new `issue_state_history` row has `changed_by` set to the admin's id.
- [ ] AC3 An active support grant gets `200` from all three. After `PATCH`, the new history row has `changed_by` null.
- [ ] AC4 No token gets `401` `UNAUTHENTICATED` from all three.
- [ ] AC5 `VerificationFlowIntegrationTest` passes unchanged, and `python3 scripts/dev-seed.py` exits `0`.
- [ ] AC6 `specs/contracts/api.md` lists `401` and `403` on all three endpoints and documents `override-state`.

## Contract
`specs/contracts/api.md` already says "admin only" and promises `403` for `PATCH /issues/{id}/state` and `POST /issues/{id}/request-verification`. Step 4 adds `POST /issues/{id}/override-state`, which the contract omits today. No wire value changes.

## Steps
Write step 1 first. Run it and see the red cases fail as stated before you change a `main` file.
1. `backend/src/test/kotlin/com/munserv/issues/api/IssueAdminEndpointsAccessTest.kt` (new). Use `@SpringBootTest`, `@AutoConfigureMockMvc`, `@ActiveProfiles("test")` and `@Import(TestContainersConfig::class)`. Do not use `@Transactional`: the service transaction must commit, so PostgreSQL runs the foreign key check.
   - Set-up: copy `createFreshIssue` from `IssuesApiContractTest.UpdateIssueState`, and leave seeded issue `…0103` alone, because `VerificationFlowIntegrationTest` needs it `reported`. Mint admin tokens with `jwtService.generateAccessToken(MemberId(id), "admin")` for `…0020` sector_admin, `…0021` sector_chief, `…0034` ward_admin, `…0033` ward_chief, `…0032` pod_admin and `…0031` pod_chief. The member is `…0010`. Copy the grant set-up and `@AfterEach` revoke from `SupportAccessRoleAuthorizationTest`, with `grantedRole = AdminRole.SECTOR_ADMIN`.
   - Red: `` `should answer 403 and change nothing when a member calls PATCH state` `` (today `500`), the same for `request-verification` and `override-state` (today `200`).
   - Red: `` `should answer 403 when an active ground admin calls request-verification` `` (today `200`). Set and restore the flags as `VerificationFlowIntegrationTest` does.
   - Red: `` `should answer 200 with no changed_by when a support grant calls PATCH state` `` (today `500`).
   - Green guards: `` `should answer 200 on all three when the token is an admin` `` (`@ParameterizedTest` over the six ids; asserts `changed_by` after `PATCH`), `` `should answer 200 when a support grant calls request-verification or override-state` ``, and `` `should answer 401 on all three when no token is sent` `` (asserts `UNAUTHENTICATED` and state `reported`).
2. `backend/src/main/kotlin/com/munserv/issues/api/IssueController.kt`, `updateIssueState` (line 349). Add `@RequireRole(AdminRole.SECTOR_ADMIN)`. Replace the `@AuthenticationPrincipal adminIdStr` parameter with `@Parameter(hidden = true) authentication: Authentication?`. Replace line 365 with `val adminId = authentication.toHistoryActor()`. Add a private extension at the end of the file, modelled on `toPhotoActor` in `PhotoController.kt`: it returns null for a null authentication, for `JwtAuthenticationFilter.SUPPORT_GRANT_AUTHORITY` and for a subject that is not a UUID, otherwise `AdminId`.
3. `backend/src/main/kotlin/com/munserv/verification/api/VerificationController.kt`. Add `@RequireRole(AdminRole.SECTOR_ADMIN)` to `requestVerification` (line 63) and `overrideState` (line 93). Add `ApiResponse(responseCode = "403", description = "Requires an admin role")` to both.
4. `specs/contracts/api.md`. Add `401` to `PATCH /issues/{id}/state`. After `request-verification`, add `POST /issues/{id}/override-state` (admin only). Request `{ state: IssueState }`, response `{ status: "updated" }`, errors `400 | 401 | 403 | 404`. State that it skips the legal transition check.

## Do not
- Put `@RequireRole` on either class. Both serve member routes: `POST /issues`, `GET /issues`, `POST /issues/{id}/verify`.
- Use `hasRole` in `SecurityConfig`. Grant tokens carry the granted role, and path rules cannot see soft-deleted admins.
- Change the foreign key on `changed_by`, add a migration, or change web, mobile or `scripts/dev-seed.py`.
- Add sector scope checks, history writes to `adminOverrideState`, or remove `override-state`. The investigation record lists these for separate issues.

## Done when
```bash
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: A member cannot use the admin issue actions
  as: member
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Verifications/overrideState
  probe:
    - {method: PATCH, path: /api/v1/issues/00000000-0000-0000-0000-000000000000/state, body: {state: confirmed}, expect_status: 403, expect_body: FORBIDDEN}
    - {method: POST, path: /api/v1/issues/00000000-0000-0000-0000-000000000000/request-verification, body: {type: existence}, expect_status: 403, expect_body: FORBIDDEN}
    - {method: POST, path: /api/v1/issues/00000000-0000-0000-0000-000000000000/override-state, body: {state: fixed}, expect_status: 403, expect_body: FORBIDDEN}
  steps:
    - Read the three answers in the automatic evidence.
  expect: All three answers are 403 with the code FORBIDDEN, and no data changes because the issue does not exist.
  covers: [AC1]
- id: E2
  title: A caller without a login is refused
  as: none
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Verifications/overrideState
  probe:
    - {method: PATCH, path: /api/v1/issues/00000000-0000-0000-0000-000000000000/state, body: {state: confirmed}, expect_status: 401, expect_body: UNAUTHENTICATED}
    - {method: POST, path: /api/v1/issues/00000000-0000-0000-0000-000000000000/request-verification, body: {type: existence}, expect_status: 401, expect_body: UNAUTHENTICATED}
    - {method: POST, path: /api/v1/issues/00000000-0000-0000-0000-000000000000/override-state, body: {state: fixed}, expect_status: 401, expect_body: UNAUTHENTICATED}
  steps:
    - Read the three answers in the automatic evidence.
  expect: All three answers are 401 with the code UNAUTHENTICATED.
  covers: [AC4]
- id: E3
  title: The seed script runs and a sector admin changes an issue
  as: sector_admin
  services: [db, backend, web]
  url: http://localhost:3000/issues
  steps:
    - "`python3 scripts/dev-seed.py`"
    - Log in as the sector admin.
    - Open an issue in the reported state.
    - Click Change State, choose Confirmed and save.
  expect: The script ends without an error, and the issue shows Confirmed with a new timeline entry.
  covers: [AC2, AC5]
- id: E4
  title: Support staff change an issue under a support grant
  as: super_user
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Log in as the pod chief and open Support Access.
    - Grant access with the sector admin role and a reason, then log out.
    - Log in as the super user.
    - Open an issue in the reported state.
    - Click Change State, choose Confirmed and save.
  expect: The issue shows Confirmed and no error message appears.
  covers: [AC3]
```
