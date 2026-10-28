---
issue: 163
story: ""               # bug fix, no story id; Operation V1 plan step S03, finding F01
title: "Photos require a token; only the reporter, an admin or the verifying ground admin may add them, and only the reporter or an admin may delete them"
platform: backend
status: completed
depends_on: []
touches: [api-access-control]
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: investigator
created_at: "2026-10-28"
files_changed:
  - backend/src/main/kotlin/com/munserv/shared/config/SecurityConfig.kt
  - backend/src/main/kotlin/com/munserv/photos/service/PhotoResult.kt
  - backend/src/main/kotlin/com/munserv/photos/service/PhotoActor.kt
  - backend/src/main/kotlin/com/munserv/photos/service/IssuePhotoService.kt
  - backend/src/main/kotlin/com/munserv/photos/api/PhotoController.kt
  - backend/src/main/kotlin/com/munserv/verification/service/VerificationService.kt
  - specs/contracts/api.md
tests_added:
  - backend/src/test/kotlin/com/munserv/shared/config/SecurityConfigTest.kt
  - backend/src/test/kotlin/com/munserv/photos/service/PhotoActorTest.kt
  - backend/src/test/kotlin/com/munserv/photos/service/IssuePhotoServiceTest.kt
  - backend/src/test/kotlin/com/munserv/photos/service/PhotoResultTest.kt
  - backend/src/test/kotlin/com/munserv/photos/api/PhotoControllerTest.kt
  - backend/src/test/kotlin/com/munserv/photos/api/PhotoAuthorizationTest.kt
  - backend/src/test/kotlin/com/munserv/verification/service/VerificationServiceTest.kt
---

# #163 · Photos require a token, and only the right people may add or delete them (Backend)

Read `domain/README.md` for every term used below. This handoff is complete on its own. The root cause is in `163-anonymous-photo-delete-investigation.md` next to this file. You do not need to read it unless a step fails in a way this handoff does not explain.

## Outcome
An anonymous caller can no longer delete a photo. A member can add photos only to an issue they reported, or to an issue whose pending verification they may answer as a ground admin. Only the reporter or an admin can delete a photo.

## Acceptance criteria
AC1 and AC3 to AC5 are verbatim from #163. AC2 was widened by the user's decision on 2026-10-28, so the mobile verify-with-photo flow keeps working.
- [ ] AC1: The security chain ends in `anyRequest().authenticated()`, and every public route is named explicitly.
- [ ] AC2: Photo upload succeeds only for the member who reported the issue, for an admin, or for the ground admin assigned to that issue's pending verification. Photo delete succeeds only for the reporter or an admin. Anyone else gets `PhotoResult.Forbidden`.
- [ ] AC3: Anonymous `DELETE /api/v1/photos/{id}` → 401.
- [ ] AC4: Authenticated member who did not report the issue → 403.
- [ ] AC5: The reporter → 204.
- [ ] AC6: MockMvc tests cover all three, the matching upload cases, and the ground-admin cases: assigned ground admin uploads → 201; a ground admin not assigned to that issue uploads → 403; assigned ground admin deletes → 403.

## Visual (ui stories only)
None.

## Contract
`specs/contracts/api.md` does not document the photo routes today. Step 12 adds them. The wire shapes do not change. Only the status codes are new:

| Route | Codes after this story |
|---|---|
| `POST /api/v1/issues/{issueId}/photos` | 201, 400, 401, **403** (not reporter, admin or verifying ground admin), 404 (issue not found), 500 |
| `DELETE /api/v1/photos/{photoId}` | 204, **401**, **403** (not reporter or admin), 404 (photo not found) |

A 403 uses the existing `forbiddenError(message)` body (`ErrorCodes.FORBIDDEN`). A 401 from the chain uses the `UnauthenticatedEntryPoint` body (`UNAUTHENTICATED`).

## Rules this story implements
- **Reporter**: the request's subject equals `Issue.reporterId` of the issue.
- **Admin**: the `Authentication` holds `ROLE_ADMIN` (every admin login, `AuthService.kt:229`) or `ROLE_SUPPORT_GRANT` (`JwtAuthenticationFilter.SUPPORT_GRANT_AUTHORITY`). `SupportGrantActivityFilter` clears the context when the grant is no longer active. Sector scope for admins is out of scope (#56).
- **Assigned ground admin** (upload only). The subject is a member with all three of:
  - `isGroundAdmin == true`;
  - `groundAdminStatus == GroundAdminStatus.ACTIVE`;
  - at least one verification for this issue in `IssueVerificationRepository.findPendingForGroundAdmin(member.sectorId, memberId)`.

  That query (`JpaIssueVerificationRepository.kt:25-37`) returns pending verifications on issues in the member's sector where `assigned_to = member` or `assigned_to IS NULL`. It is the stored definition of "assigned to me". It feeds `GET /members/me/pending-verifications`, the list the mobile verify screen opens from. A null `assigned_to` is normal: every auto-triggered verification is saved unassigned (`VerificationService.kt:112-117`) and offered to every active ground admin in the sector. A verification assigned to another member, or on an issue in another sector, does not count. These are the same conditions `VerificationService.submitVerification` enforces at lines 169-175, plus the sector match.
- **Order on upload**: issue exists → actor allowed → validate file → store. A forbidden upload must never write a file.
- **Order on delete**: photo exists → reporter or admin → delete from storage → delete row. A ground admin gets `Forbidden` on delete, even for the issue they are verifying.

## Public routes (the only `permitAll` entries after this story)
Callers were found by searching `web/src`, `mobile/lib` and `scripts/console`.

| Matcher | Found callers |
|---|---|
| `/actuator/health`, `/actuator/health/**`, `/actuator/info` | Factory console health check `GET /actuator/health/liveness` (`scripts/console/services.yaml:43`). Public today only through the fallthrough, because the current matcher is the exact `/actuator/health`. |
| `/api/v1/auth/admin/login` | web `features/auth/api.ts:13` |
| `/api/v1/auth/member/login` | mobile `features/auth/data/auth_api.dart:87` |
| `/api/v1/auth/refresh` | mobile `features/auth/data/auth_api.dart:47`; scenario tests |
| `/api/v1/auth/register/web` | web `features/auth/api.ts:24` |
| `/api/v1/auth/register`, `/api/v1/auth/verify-otp`, `/api/v1/auth/complete-registration`, `/api/v1/auth/login`, `/api/v1/auth/check-phone` | Legacy phone flow, public today; scenario tests use `/login` and `/register`. Keep them unchanged. |
| `GET /api/v1/sectors`, `GET /api/v1/sectors/*` | web registration `features/auth/api.ts:18`; mobile `features/auth/data/auth_api.dart:29,57` |
| `/uploads/**` | Photo and pod-logo files loaded by `<img>` and `Image.network` without a token (`LocalPhotoStorageService.kt:92-101`, `StorageConfig.kt:79`) |
| `/swagger-ui.html`, `/swagger-ui/**`, `/v3/api-docs/**`, `/v3/api-docs.yaml`, `/swagger-resources/**`, `/webjars/**` | Swagger UI and eyeball deep links (`scripts/console/project.yaml:24,35`) |
| `/error` | Spring Boot error dispatch. The JWT filter does not run on the ERROR dispatch, so a protected `/error` turns every unhandled 400/500 into a 401. |

Routes that become protected because they only had the fallthrough: `/api/v1/photos/**`, `/api/v1/messages/**`, any unmapped path, and `GET /api/v1/sectors/{id}/ground-admins` (narrowed from `/api/v1/sectors/**`). Every web and mobile caller of these already sends a token.

## Steps

Write each test before the change it proves, and watch it fail first.

1. `backend/src/test/kotlin/com/munserv/shared/config/SecurityConfigTest.kt`: add these tests first.
   - `` `should answer 401 for DELETE photo when no token is sent` `` → `DELETE /api/v1/photos/{random uuid}` → 401, `$.error.code` = `UNAUTHENTICATED`. (Fails today with 404.)
   - `` `should answer 401 for GET messages when no token is sent` `` → `$.error.code` = `UNAUTHENTICATED`. (Fails today: the code is `UNAUTHORIZED`, written by the controller.)
   - `` `should answer 401 for an unmapped path when no token is sent` `` → `GET /api/v1/does-not-exist` → 401.
   - `` `should keep public routes reachable without a token` ``: `GET /actuator/health/liveness`, `GET /v3/api-docs`, `GET /api/v1/sectors` and `POST /api/v1/auth/member/login` with a wrong password each answer something other than 401 and 403. Use one test per route if a parameterised test reads badly.
   - `` `should answer 401 for GET sector ground admins when no token is sent` ``. This passes today and must keep passing.
2. `backend/src/main/kotlin/com/munserv/shared/config/SecurityConfig.kt`:
   - Add `.requestMatchers("/error").permitAll()`.
   - Change line 36 to `.requestMatchers("/actuator/health", "/actuator/health/**", "/actuator/info")`.
   - Replace `.requestMatchers("/api/v1/sectors", "/api/v1/sectors/**").permitAll()` (lines 67-68) with `.requestMatchers(HttpMethod.GET, "/api/v1/sectors", "/api/v1/sectors/*").permitAll()`. Keep the sector-settings matcher above it.
   - Replace lines 99-101 (`// Default: allow all for now` and `.anyRequest().permitAll()`) with `.anyRequest().authenticated()`. Leave every other matcher as it is.
   - Test: step 1 is green.
3. `backend/src/main/kotlin/com/munserv/photos/service/PhotoResult.kt`: add `data class Forbidden(val message: String) : PhotoResult` and `data class IssueNotFound(val id: IssueId) : PhotoResult`. In the same commit, add the two branches to the exhaustive `when` expressions in `backend/src/test/kotlin/com/munserv/photos/service/PhotoResultTest.kt:101-125`, and add `` `Forbidden should contain message` `` and `` `IssueNotFound should contain issue id` ``.
4. `backend/src/main/kotlin/com/munserv/photos/service/PhotoActor.kt` (new): `sealed interface PhotoActor { data class Member(val id: MemberId) : PhotoActor; data object Admin : PhotoActor }`, plus `fun PhotoActor.isReporterOrAdminOf(issue: Issue): Boolean`. It returns true for `Admin`, and for `Member` when `id == issue.reporterId`. A ground admin authenticates with a member token, so no ground-admin variant is needed: the service asks `VerificationService` (step 6). Test: `backend/src/test/kotlin/com/munserv/photos/service/PhotoActorTest.kt`: `` `should allow the reporter` ``, `` `should allow an admin` ``, `` `should refuse another member` ``.
5. `backend/src/test/kotlin/com/munserv/verification/service/VerificationServiceTest.kt`: add a `@Nested inner class MayVerify` with these tests before step 6. Stub `memberRepository.findById` and `verificationRepository.findPendingForGroundAdmin(member.sectorId, memberId)`.
   - `` `should return true when the pending verification is assigned to the member` ``
   - `` `should return true when the pending verification is unassigned and the issue is in the member's sector` ``: the query returns a row with `assignedTo = null`.
   - `` `should return false when the pending verifications do not include this issue` ``: covers "assigned to another ground admin" and "issue in another sector", because the query filters both out.
   - `` `should return false when the member is not a ground admin` ``: verify `findPendingForGroundAdmin` is never called.
   - `` `should return false when the ground admin status is not active` ``
   - `` `should return false when the member does not exist` ``
6. `backend/src/main/kotlin/com/munserv/verification/service/VerificationService.kt`: add `fun mayVerify(issueId: IssueId, memberId: MemberId): Boolean`. The body:
   - `val member = memberRepository.findById(memberId) ?: return false`.
   - Return false unless `member.isGroundAdmin && member.groundAdminStatus == GroundAdminStatus.ACTIVE`.
   - Otherwise return `verificationRepository.findPendingForGroundAdmin(member.sectorId, memberId).any { it.issueId == issueId }`.

   This is the only call the photo check uses. Do not change `submitVerification` or `getPendingVerifications`. Test: step 5 is green.
7. `backend/src/test/kotlin/com/munserv/photos/service/IssuePhotoServiceTest.kt` (new, MockK unit test; there is none today). Mock `IssueService` and `VerificationService`. Write these before step 8:
   - Upload: `` `should return Success when the reporter uploads` `` (verify `verificationService.mayVerify` is never called); `` `should return Success when an admin uploads` ``; `` `should return Success when the assigned ground admin uploads` `` (`mayVerify(issueId, gaId)` returns true); `` `should return Forbidden when a ground admin not assigned to the issue uploads` `` (`mayVerify` returns false; verify `validationService.validate`, `storageService.store` and `repository.save` are never called); `` `should return Forbidden when another member uploads` `` (same verifications); `` `should return IssueNotFound when the issue does not exist` ``.
   - Delete: `` `should return Success when the reporter deletes` `` (verify storage and repository delete were called); `` `should return Success when an admin deletes` ``; `` `should return Forbidden when the assigned ground admin deletes` `` (verify `verificationService.mayVerify` is never called, and `storageService.delete` and `repository.deleteById` are never called); `` `should return Forbidden when another member deletes` ``; `` `should return NotFound when the photo does not exist` ``.
8. `backend/src/main/kotlin/com/munserv/photos/service/IssuePhotoService.kt`:
   - Inject `IssueService` and `VerificationService`, both cross-module through the service, never a repository. Neither depends on `IssuePhotoService`, so there is no cycle.
   - `uploadPhoto(issueId, file, actor: PhotoActor): PhotoResult`:
     - Resolve the issue with `issueService.findById`. Return `IssueNotFound` for anything but `IssueResult.Success`.
     - The actor is allowed when `actor.isReporterOrAdminOf(issue)`, or when `actor is PhotoActor.Member && verificationService.mayVerify(issue.id, actor.id)`. Check in that order, so the reporter and admins never hit the verification query.
     - Otherwise return `Forbidden("Only the reporter, an admin or the verifying ground admin can add photos to this issue")`.
     - Only then run the existing validate → store → save.
   - `deletePhoto(photoId, actor: PhotoActor): PhotoResult`:
     - `repository.findById`, or return `NotFound(photoId)`.
     - Resolve the issue from `photo.issueId`. If it is missing, return `NotFound(photoId)`.
     - Return `Forbidden("Only the reporter or an admin can delete this photo")` when `!actor.isReporterOrAdminOf(issue)`. Do not consult `VerificationService` here.
     - Delete from storage and the repository, and return `Success(photo)`.
   - Test: step 7 is green.
9. `backend/src/test/kotlin/com/munserv/photos/api/PhotoControllerTest.kt`: update first. The service stays a `@MockkBean`.
   - Change the existing upload stubs (lines 82, 110, 134) to three arguments. Change the delete stubs (230, 244) to `deletePhoto(testPhotoId, any())` returning `PhotoResult.Success(testPhoto)` / `PhotoResult.NotFound(testPhotoId)`.
   - Add to `DeletePhoto`: `` `DELETE photos-photoId should return 401 without token` `` (and `verify(exactly = 0) { photoService.deletePhoto(any(), any()) }`); `` `DELETE photos-photoId should return 403 when the service answers Forbidden` `` (`$.error.code` = `FORBIDDEN`); `` `DELETE photos-photoId should pass the member as actor` `` (verify `PhotoActor.Member(testMemberId)`); `` `DELETE photos-photoId should pass Admin as actor for an admin token` ``.
   - Add to `UploadPhoto`: `` `POST issues-issueId-photos should return 403 when the service answers Forbidden` ``; `` `POST issues-issueId-photos should return 404 when the issue does not exist` ``; `` `POST issues-issueId-photos should pass Admin as actor for an admin token` ``.
10. `backend/src/test/kotlin/com/munserv/photos/api/PhotoAuthorizationTest.kt` (new; the end-to-end AC proof).
    - Annotations: `@SpringBootTest`, `@Import(TestContainersConfig::class)`, `@AutoConfigureMockMvc`, `@ActiveProfiles("test")`.
    - Keep the real `IssuePhotoService`. Add `@MockkBean` for `IssueService`, `VerificationService`, `IssuePhotoRepository`, `PhotoStorageService` and `PhotoValidationService` (returns `ValidationResult.Valid`).
    - Stub one issue whose `reporterId` is the reporter, and one photo on that issue.
    - Stub `verificationService.mayVerify(issueId, assignedGaId)` → true, and `mayVerify(issueId, otherGaId)` → false.
    - Mint tokens with `JwtService.generateAccessToken(id, "member")`, or `"admin"` for the admin.

    Tests:
    - `` `anonymous DELETE should return 401` ``
    - `` `another member DELETE should return 403` ``
    - `` `the reporter DELETE should return 204` ``
    - `` `an admin DELETE should return 204` ``
    - `` `the assigned ground admin DELETE should return 403` ``
    - `` `anonymous upload should return 401` ``
    - `` `another member upload should return 403 and store nothing` `` (verify `storageService.store` never called)
    - `` `the reporter upload should return 201` ``
    - `` `an admin upload should return 201` ``
    - `` `the assigned ground admin upload should return 201` ``
    - `` `a ground admin not assigned to the issue upload should return 403 and store nothing` ``
11. `backend/src/main/kotlin/com/munserv/photos/api/PhotoController.kt`:
    - Both handlers take `authentication: Authentication?` (Spring injects it). Add a private `Authentication?.toPhotoActor(): PhotoActor?`. It returns `Admin` when the authorities hold `ROLE_ADMIN` or `JwtAuthenticationFilter.SUPPORT_GRANT_AUTHORITY`. Otherwise it returns `Member(MemberId.fromString(principal))`. It returns null when the authentication or the principal is missing, or the UUID is invalid. Null → 401 `unauthorizedError()`. Deciding who may act stays in the service.
    - Upload: map `Forbidden` → 403 `forbiddenError(result.message)` and `IssueNotFound` → 404 `"Issue not found"`. Keep the other branches.
    - Delete: `when` over the `PhotoResult`: `Success` → 204, `NotFound` and `IssueNotFound` → 404 `"Photo not found"`, `Forbidden` → 403, `ValidationError` → 400, `StorageError` → 500. Do not throw.
    - Add `ApiResponse(responseCode = "403", ...)` to both operations. Upload already documents 404 "Issue not found".
    - Test: steps 9 and 10 are green.
12. `specs/contracts/api.md`: under the issues section, add `### POST /issues/{id}/photos` ("reporter, admin, or a ground admin with a pending verification on the issue") and `### DELETE /photos/{id}` ("reporter or admin only"). Copy the codes from the Contract table above.

## Do not
- Do not change `JwtAuthenticationFilter`. Passing a tokenless request on is correct; the chain decides.
- Do not add an `OPTIONS /**` permit. `.cors { }` answers preflight before authorization.
- Do not permit `/api/v1/pods/**` for the web theme fetch (`web/src/theme/ThemeContext.tsx:70`). No backend handler exists. The web falls back to the default theme on any non-OK answer.
- Do not let a ground admin delete photos. The ground-admin path applies to upload only.
- Do not read `IssueVerificationRepository` or `MemberRepository` from the photos package. Go through `VerificationService.mayVerify`.
- Do not change `submitVerification`, `getPendingVerifications` or the `findPendingForGroundAdmin` query.
- Do not add sector scoping for admins (#56).
- Do not touch web or mobile code, `IssueController`, `IssueService` or migrations.
- Do not tidy the other matchers in `SecurityConfig` beyond the four edits in step 2.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball
The dev database has one member (`john.doe@example.com`). He reported every seeded issue and has no verifications, so two cases are proven only by `PhotoAuthorizationTest`: "another member → 403", and the ground admin who is not the reporter. A manual check of the second needs a second member to be registered, approved, made a ground admin and sent a verification request. That setup takes more steps than an eyeball check should carry. E5 checks that the verify flow still submits with a photo when the reporter is the ground admin.

```yaml
- id: E1
  title: Anonymous photo delete is refused
  as: none
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Photos/deletePhoto
  steps:
    - Do not press Authorize. If a token is set, press Authorize, then Logout.
    - Open the deletePhoto operation, press Try it out, enter photoId 00000000-0000-0000-0000-000000000000 and press Execute.
  expect: The response is 401 with body {"error":{"code":"UNAUTHENTICATED","message":"Authentication required"}}. Before the fix the same call answered 404.
- id: E2
  title: The reporter deletes their own photo
  as: member
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Authentication/memberLogin
  steps:
    - In memberLogin press Try it out, send {"email":"john.doe@example.com","password":"member123"} and copy accessToken from the response.
    - Press Authorize at the top of the page, paste the token into bearerAuth and close the dialog.
    - Open http://localhost:8080/swagger-ui/index.html#/Issues/listMyIssues, execute it, and copy the id of an issue with a thumbnailUrl.
    - Open http://localhost:8080/swagger-ui/index.html#/Photos/getPhotosForIssue, execute it with that issueId, and copy one photo id.
    - Open http://localhost:8080/swagger-ui/index.html#/Photos/deletePhoto and execute it with that photoId.
  expect: The delete answers 204. Running getPhotosForIssue again no longer lists that photo.
- id: E3
  title: Public routes still work without a token
  as: none
  services: [db, backend, web]
  url: http://localhost:3000/register
  steps:
    - Open the registration page in a private window, signed out.
    - Open the sector dropdown.
    - Open http://localhost:8080/actuator/health/liveness and http://localhost:8080/swagger-ui.html in the same window.
  expect: The dropdown lists sectors. The liveness page shows {"status":"UP"}. Swagger UI loads with its operations listed.
- id: E4
  title: Signed-in web portal is unaffected
  as: sector_admin
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - Log in as admin@ward42.example.com / admin123.
    - Open Issues, open an issue that has photos, then open Messages.
  expect: The issue's photos render. The messages list loads. No page bounces back to the login screen.
- id: E5
  title: Verify-with-photo still submits
  as: member
  services: [db, backend, mobile]
  url: http://localhost:8080/swagger-ui/index.html#/Ground%20Admins/apply
  steps:
    - Get a member token from http://localhost:8080/swagger-ui/index.html#/Authentication/memberLogin with {"email":"john.doe@example.com","password":"member123"}, press Authorize and paste it into bearerAuth.
    - Execute apply (no body). Copy the application id from the response.
    - Get an admin token from http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin with {"email":"admin@ward42.example.com","password":"admin123"}, press Authorize, Logout, and paste the admin token into bearerAuth.
    - Open http://localhost:8080/swagger-ui/index.html#/Ground%20Admins/approve and execute it with memberId 550e8400-e29b-41d4-a716-446655440010 and body {"applicationId":"<the id you copied>"}.
    - Open http://localhost:8080/swagger-ui/index.html#/Issues/listIssues with state reported and copy an issue id. Open http://localhost:8080/swagger-ui/index.html#/Verifications/requestVerification and execute it with that issueId and body {"type":"existence"}. Leave assignTo out, so the verification is unassigned like an auto-triggered one.
    - In the mobile app, log in as john.doe@example.com, open the verification request in Messages, press Verify now, take a photo, choose Confirmed and submit.
  expect: The submit succeeds and the issue moves to confirmed. getPhotosForIssue for that issue lists the new photo. John is also the reporter, so this guards the flow end to end. PhotoAuthorizationTest covers the case where the ground admin is not the reporter.
```
