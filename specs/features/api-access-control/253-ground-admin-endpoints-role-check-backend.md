---
issue: 253
story: FIX253
title: "Only admins and support grants may manage ground admins, and revoke works"
platform: backend
status: pending
depends_on: []
touches: [api-access-control]
ui: false
user_facing: true
eyeball_exempt: []
design_canvas: ""
design_artboards: []
design_approved: false
created_by: investigator
created_at: "2026-11-04"
files_changed: []
tests_added: []
---

# #253 · Ground admin management checks the role, and revoke works (Backend)

Read `domain/README.md`, `domain/ground-admin.md`, `domain/admin-role.md` and `domain/support-grant.md` first. This handoff is complete on its own. The evidence and the decisions are in `253-ground-admin-endpoints-role-check-investigation.md`; read it only if a step surprises you. `completed/169-admin-issue-endpoints-role-check-backend.md` is the model.

## Outcome
A member gets `403` from the seven ground admin management endpoints, an admin or support grant succeeds, and revoke ends the role with status `inactive`.

## Acceptance criteria
- [ ] AC1 A member token, also one of an active ground admin, gets `403` `FORBIDDEN` from invite, revoke invitation, approve, decline, revoke, `PATCH status` and `GET /sectors/{id}/ground-admins`. The member row, the applications and the message count stay unchanged, and no phone number is sent. This holds for a member approving their own application.
- [ ] AC2 Each of the six admin roles gets `200` from the six endpoints other than invite. Where a call writes them, `processed_by` and message `sender_id` hold the admin, and `sender_type` is `admin`. On invite, `sector_admin` and `sector_chief` get `200` with `invited_by` set; the other four keep today's `403` `Member not in your sector` (#254). The list response has no `phone` field.
- [ ] AC3 A support grant with role `sector_admin` gets `200` from all seven. `invited_by` and `processed_by` are null, and message `sender_id` is null with `sender_type` `system`.
- [ ] AC4 No token gets `401` `UNAUTHENTICATED` from all seven, and nothing changes.
- [ ] AC5 Revoke answers `200`. The row keeps `is_ground_admin = true` and `ground_admin_since`, has status `inactive`, and the member gets a `ground_admin_revocation` message. The list shows the row as `inactive`. `GET /members/me/ground-admin` is empty, `pending-verifications` is empty, stepdown, a second revoke and `PATCH status` answer `409`, and `GET /admin/members` shows `isGroundAdmin: false`. A new apply plus approve, or a new invitation, answers `200`, and approve makes the status `active`. `python3 scripts/dev-seed.py` exits `0`.
- [ ] AC6 `PATCH status` with `inactive` answers `400` `VALIDATION_ERROR`, and nothing changes.
- [ ] AC7 A member token still succeeds on `POST /members/me/ground-admin/apply`, `accept`, `decline`, `stepdown` and `GET /members/me/ground-admin`.

## Contract
`specs/contracts/api.md` already says "admin only" and `403` on the admin actions, and its list response has no `phone`. Step 7 adds the rest. No wire value changes. The domain is unchanged except for the invariant in step 7.

## Steps
1. Write this step first, and see the red cases fail as stated before you change a `main` file. `backend/src/test/kotlin/com/munserv/groundadmin/api/GroundAdminEndpointsAccessTest.kt` (new). Use `@SpringBootTest`, `@AutoConfigureMockMvc`, `@ActiveProfiles("test")` and `@Import(TestContainersConfig::class)`. Do not use `@Transactional`: the service transaction must commit, so PostgreSQL runs the foreign keys and `ck_members_ground_admin_status`.
   - Set-up: create each target with `memberRepository.save` in sector `…0001`, a random id and email. Set each target up for real, or the answer is a meaningless `409` or `404`: a pending application through `POST /members/me/ground-admin/apply` for approve and decline, an invitation through the sector admin `…0020` for revoke invitation, and `is_ground_admin = true`, status `active`, `ground_admin_since` by JDBC for revoke, status and list. The plain member is `…0010`. Mint admin tokens as `IssueAdminEndpointsAccessTest` does for `…0020`, `…0021`, `…0034`, `…0033`, `…0032`, `…0031`, and copy its grant set-up. `@AfterEach`: delete messages created since the test began, delete the targets, revoke the grant. Compare a snapshot before and after each refusal: the member's four ground admin columns and `updated_at`, the application rows, and the message count.
   - Red, over the seven calls: `` `should answer 403 and change nothing when a plain member calls` `` and the same for `an active ground admin` (today invite `404`; revoke invitation, approve, decline, revoke `500`; status and list `200`); `` `should answer 200 and record no admin when a support grant calls` `` (today invite `404`; four `500`); AC2 for each role (revoke `500`, approve and decline `sender_type` `member`). Red, single: approving one's own application; AC5 as one lifecycle test plus a pending-verifications test; AC6; `` `should not send a phone number in the list` ``. Green guards: no token over the seven calls (AC4), and AC7. Assert the list with no `status` parameter: the filter is broken today (see Do not).
2. `backend/src/main/kotlin/com/munserv/auth/domain/Member.kt`. Add `val isCurrentGroundAdmin: Boolean get() = isGroundAdmin && groundAdminStatus != GroundAdminStatus.INACTIVE`. In `demoteFromGroundAdmin`, delete `isGroundAdmin = false` and correct the KDoc. `groundadmin/domain/GroundAdminApplication.kt`: make the actor parameter `MemberId?` in `approve`, `decline`, `revokeByAdmin` and `createInvitation`.
3. `backend/src/main/kotlin/com/munserv/groundadmin/service/GroundAdminService.kt`. Make `adminId` `MemberId?` in the six admin actions. Replace `isGroundAdmin` with `isCurrentGroundAdmin` at lines 57, 185, 219, 260, 428 and 466. In `invite`, load the admin only when `adminId` is not null, skip the sector check when it is null, and use `val inviterName = admin?.fullName ?: SUPPORT_SENDER_NAME` (`"MunServ support"`). At lines 283-284, 364-365, 406-407 and 444-445 write `senderId = adminId?.value` and `senderType = senderTypeOf(adminId)`, a private helper returning `"system"` for null and `"admin"` otherwise. In `updateStatus`, return `GroundAdminResult.ValidationError` for `INACTIVE` before the lookup, with a message naming revoke, and replace the `when` with `if (status == GroundAdminStatus.ACTIVE) member.reactivateGroundAdmin() else member.setGroundAdminOnHold()`. Delete `phone = member.phone` at line 502, and delete `phone` from `GroundAdminResponse` in `groundadmin/api/GroundAdminDto.kt`.
4. `backend/src/main/kotlin/com/munserv/groundadmin/api/GroundAdminController.kt`. Add `@RequireRole(AdminRole.SECTOR_ADMIN)` and `ApiResponse(responseCode = "403", description = "Requires an admin role")` to `invite`, `revokeInvitation`, `approve`, `decline`, `revoke`, `updateStatus` and `listGroundAdmins`. In the first six, replace `@AuthenticationPrincipal adminId` with `@Parameter(hidden = true) authentication: Authentication?` and use `authentication.toAdminActor()`. Remove the principal from `listGroundAdmins`. Add a private extension at the end of the file, modelled on `toHistoryActor` in `IssueController.kt`: null for a null authentication, for `JwtAuthenticationFilter.SUPPORT_GRANT_AUTHORITY` and for a subject that is not a UUID, otherwise `MemberId`.
5. Two more readers of the flag. `verification/service/VerificationService.kt:231`: use `isCurrentGroundAdmin`, or a revoked ground admin still sees the sector's pending verifications. `admin/api/AdminController.kt`: add `.filter { it.isCurrentGroundAdmin }` at line 202, and at lines 300-301 send `isGroundAdmin = isCurrentGroundAdmin` and `groundAdminStatus = groundAdminStatus.takeIf { isCurrentGroundAdmin }`, so the portal offers invite again without a web change.
6. Existing tests. `GroundAdminControllerTest`: the nested classes `Invite`, `Approve`, `Revoke`, `UpdateStatus` and `ListGroundAdmins` use a member token and will answer `403`; use a token and service-mock id for admin `…0020`, delete `phone` at line 375, and leave the member classes alone. `MemberGroundAdminTest:127-141`: assert `isGroundAdmin` true, status `INACTIVE`, `isCurrentGroundAdmin` false. `GroundAdminServiceTest:484`: match on status `INACTIVE` and not `isCurrentGroundAdmin`. `GroundAdminServiceTest:529-539`: expect `ValidationError` and no save.
7. Documents. `domain/ground-admin.md`: add `isCurrentGroundAdmin` to the Kotlin names, and an invariant: an ended role keeps `is_ground_admin = true` with status `inactive`, and the member returns only through a new application or invitation. `specs/contracts/api.md`: on `PATCH status` add `400` for `inactive`; on `GET /sectors/{id}/ground-admins` say admin only; add `DELETE /members/{id}/ground-admin/invite/{applicationId}` (admin only), response `{ applicationId, status: "revoked" }`, errors `400 | 401 | 403 | 404 | 409`.

## Do not
- Put `@RequireRole` on the class: it serves the member routes too. Do not use `hasRole` in `SecurityConfig`. Do not add a migration, change `ck_members_ground_admin_status` or a foreign key, change web, mobile or `scripts/dev-seed.py`, or change the type of `adminId` to `AdminId`.
- Add sector scope checks (#254). Do not fix the `?status=` filter or the message recipients from `findAdminsBySectorId`: the investigation record lists them for separate issues.
- Treat an `IssueStateTest` null failure as yours: it is the order-dependent #261. Rerun the suite once and say so in your summary.

## Done when
```bash
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: A member cannot manage ground admins but keeps their own routes
  as: member
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Ground%20Admins/approve
  probe: [{method: POST, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/invite, body: {}, expect_status: 403, expect_body: FORBIDDEN}, {method: DELETE, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/invite/00000000-0000-0000-0000-000000000000, expect_status: 403, expect_body: FORBIDDEN}, {method: POST, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/approve, body: {applicationId: 00000000-0000-0000-0000-000000000000}, expect_status: 403, expect_body: FORBIDDEN}, {method: POST, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/decline, body: {applicationId: 00000000-0000-0000-0000-000000000000, reason: check}, expect_status: 403, expect_body: FORBIDDEN}, {method: POST, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/revoke, body: {reason: check}, expect_status: 403, expect_body: FORBIDDEN}, {method: PATCH, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/status, body: {status: on_hold}, expect_status: 403, expect_body: FORBIDDEN}, {method: GET, path: /api/v1/sectors/550e8400-e29b-41d4-a716-446655440001/ground-admins, expect_status: 403, expect_body: FORBIDDEN}, {method: GET, path: /api/v1/members/me/ground-admin, expect_status: 200}, {method: POST, path: /api/v1/members/me/ground-admin/accept, body: {applicationId: 00000000-0000-0000-0000-000000000000}, expect_status: 404}, {method: POST, path: /api/v1/members/me/ground-admin/decline, body: {applicationId: 00000000-0000-0000-0000-000000000000}, expect_status: 404}, {method: POST, path: /api/v1/members/me/ground-admin/stepdown, body: {reason: check}, expect_status: 409}]
  steps: [Read the eleven answers in the automatic evidence.]
  expect: The seven management calls answer 403, and the member's own four routes answer 200, 404, 404 and 409 instead of 403.
  covers: [AC1, AC7]
- id: E2
  title: A caller without a login is refused
  as: none
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Ground%20Admins/listGroundAdmins
  probe: [{method: PATCH, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/status, body: {status: on_hold}, expect_status: 401, expect_body: UNAUTHENTICATED}, {method: GET, path: /api/v1/sectors/550e8400-e29b-41d4-a716-446655440001/ground-admins, expect_status: 401, expect_body: UNAUTHENTICATED}]
  steps: [Read the two answers in the automatic evidence.]
  expect: Both answers are 401 with the code UNAUTHENTICATED.
  covers: [AC4]
- id: E3
  title: The status call refuses inactive
  as: sector_admin
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Ground%20Admins/updateStatus
  probe: {method: PATCH, path: /api/v1/members/00000000-0000-0000-0000-000000000000/ground-admin/status, body: {status: inactive}, expect_status: 400, expect_body: VALIDATION_ERROR}
  steps: [Read the answer in the automatic evidence.]
  expect: The answer is 400 with the code VALIDATION_ERROR.
  covers: [AC6]
- id: E4
  title: A sector admin revokes a ground admin, who can return
  as: sector_admin
  services: [db, backend, web]
  url: http://localhost:3000/ground-admins
  steps:
    - "`python3 scripts/dev-seed.py`"
    - "`T=$(curl -s -X POST http://localhost:8080/api/v1/auth/admin/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@ward42.example.com\",\"password\":\"admin123\"}' | python3 -c 'import json,sys;print(json.load(sys.stdin)[\"tokens\"][\"accessToken\"])'); curl -s -H \"Authorization: Bearer $T\" http://localhost:8080/api/v1/sectors/550e8400-e29b-41d4-a716-446655440001/ground-admins`"
    - Log in as the sector admin and open Ground Admins.
    - Open the actions menu on the ground admin, choose Revoke, give a reason and confirm.
    - "`python3 scripts/dev-seed.py`"
    - Reload the page.
  expect: The list shows no phone number, the person shows Inactive with actions disabled after the revoke, and Active again after the script.
  covers: [AC2, AC5]
- id: E5
  title: Support staff revoke a ground admin under a support grant
  as: super_user
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Log in as the pod chief and open Support Access.
    - Grant access with the sector admin role and a reason, then log out.
    - "`T=$(curl -s -X POST http://localhost:8080/api/v1/auth/admin/login -H 'Content-Type: application/json' -d '{\"email\":\"superuser@munserv.local\",\"password\":\"super123\"}' | python3 -c 'import json,sys;print(json.load(sys.stdin)[\"tokens\"][\"accessToken\"])'); M=$(curl -s -H \"Authorization: Bearer $T\" http://localhost:8080/api/v1/sectors/550e8400-e29b-41d4-a716-446655440001/ground-admins | python3 -c 'import json,sys;print(json.load(sys.stdin)[\"items\"][0][\"memberId\"])'); curl -s -X POST -H \"Authorization: Bearer $T\" -H 'Content-Type: application/json' -d '{\"reason\":\"support check\"}' http://localhost:8080/api/v1/members/$M/ground-admin/revoke`"
    - "`python3 scripts/dev-seed.py`"
  expect: The revoke command prints the status revoked, and the script ends without an error.
  covers: [AC3]
```
