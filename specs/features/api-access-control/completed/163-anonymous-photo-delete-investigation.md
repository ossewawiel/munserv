# Investigation: anonymous callers can delete issue photos

**Issue:** #163 (Operation V1 plan, step S03, finding F01)
**Date:** 2026-10-28
**Platforms:** Backend (fix). Web and mobile checked as callers; neither needs a change.
**Handoff:** `163-anonymous-photo-delete-backend.md`

## Problem

`DELETE /api/v1/photos/{photoId}` runs with no `Authorization` header. Any caller who knows a photo id can delete the file and its `issue_photos` row. A signed-in member can also delete or add photos on another member's issue. A photo is evidence on an [issue](../../../domain/issue.md). The fix lets the reporter and admins add and delete photos, and lets the ground admin verifying the issue add one.

## Reproduction

Against the running dev backend (2026-10-28):

| Request (no token) | Answer | Meaning |
|---|---|---|
| `DELETE /api/v1/photos/00000000-0000-0000-0000-000000000000` | `404 {"error":{"code":"NOT_FOUND","message":"Photo not found"}}` | The request reached the handler. A protected route answers 401 before the handler runs. |
| `DELETE /api/v1/photos/not-a-uuid` | `400` | Same: the handler parsed the id. |
| `GET /api/v1/messages` | `401 {"error":{"code":"UNAUTHORIZED",...}}` | Public at the chain. The controller rejects the request itself. |

No real photo was deleted. The 404 on a random id proves the path is open.

## Steps taken

1. Read the issue, `domain/README.md`, `domain/photo.md`, `issue.md`, `member.md`, `admin-role.md`, `verification.md` and `backend/CLAUDE.md`.
2. Read the security chain, the JWT filter, the entry point, the photo controller, the service, the result type and the domain class.
3. Listed every `@*Mapping` in `backend/src/main/kotlin`. Matched each route against the chain to find routes that only the fallthrough rule covers.
4. Listed every backend path that `web/src` and `mobile/lib` call, and which of them run before login.
5. Listed the tests that touch the changed routes and types.
6. Checked the schema with the `postgres` MCP. `issue_photos.issue_id` and `issues.reporter_id` are both `NOT NULL`, so every photo resolves to one reporter.
7. After the user's decision, read the `verification` package (`IssueVerification`, `VerificationService`, `IssueVerificationRepository`, `JpaIssueVerificationRepository`) and the mobile verify flow. The goal was to find where ground-admin assignment is stored.

## Evidence check (from the issue)

| Claim | Status |
|---|---|
| `SecurityConfig.kt:72-86` ends in `anyRequest().permitAll()` | Drifted. The fallthrough is at `SecurityConfig.kt:99-101`. Lines 72-86 hold the Swagger, issues, members, admin and bootstrap matchers. |
| `PhotoController.kt:171-176` takes no principal | Correct. `deletePhoto` runs from 171 to 186. `uploadPhoto` (95-128) takes no principal either. |
| `JwtAuthenticationFilter.kt:34,59` passes tokenless requests on | Correct, but this is not a defect. A stateless JWT filter must pass anonymous requests on. Authorization rules decide what they reach. Do not change the filter. |

## Root cause

Two gaps combine.

1. **Chain.** `SecurityConfig.kt:99-101` ends in `.anyRequest().permitAll()` with the comment "Default: allow all for now". No matcher names `/api/v1/photos/**`, so the delete route is public. Upload is `POST /api/v1/issues/{id}/photos`, and `/api/v1/issues/**` (79-80) already requires a token. That is why only delete is anonymous.
2. **Ownership.** `IssuePhotoService.uploadPhoto` (`IssuePhotoService.kt:34-76`) and `deletePhoto` (99-111) take no actor. `PhotoController` passes none (95-100, 171-177). Any token, from any member, can add photos to any issue or delete any photo. `PhotoResult` (`PhotoResult.kt:10-26`) has no `Forbidden` variant, so the service cannot express "not allowed".

## What else the fallthrough covers today

Routes with no explicit matcher, so `anyRequest().permitAll()` makes them public:

| Route | Who uses it | After the fix |
|---|---|---|
| `DELETE /api/v1/photos/{id}` | No client calls it today | Authenticated (the bug) |
| `/api/v1/messages/**` (4 routes) | Web `features/messages/api.ts`, mobile `features/messages/data/messages_api.dart`, both after login with a token | Authenticated. The anonymous 401 body changes from `UNAUTHORIZED` (controller) to `UNAUTHENTICATED` (entry point). No client reads the code. |
| `/actuator/health/liveness` (and the other `/actuator/health/*` groups) | Factory console health check, `scripts/console/services.yaml:43` | **Must stay public.** The current matcher is the exact `/actuator/health`, which does not match sub-paths. |
| `/error` | Spring Boot error dispatch for unhandled exceptions, e.g. `IllegalArgumentException` from `UUID.fromString` in controllers (no handler in `GlobalExceptionHandler`) | **Must stay public.** The JWT filter does not run on the ERROR dispatch, so a protected `/error` turns every 400/500 into a 401. |
| Unmapped paths, e.g. `/api/v1/pods/{podId}/theme` | Web `theme/ThemeContext.tsx:70`, before login, only off localhost. No backend handler exists. | 401 instead of 404. The web falls back to the default theme on any non-OK answer. No change. |

## Public routes, enumerated from code and clients

The fix names each of these explicitly. Everything else requires a token.

| Route | Why public | Callers found |
|---|---|---|
| `/actuator/health`, `/actuator/health/**` | Liveness and readiness probes | `scripts/console/services.yaml:43` (`/actuator/health/liveness`) |
| `/actuator/info` | Already public. Not exposed by default. | none |
| `POST /api/v1/auth/admin/login` | Web login | `web/src/features/auth/api.ts:13` |
| `POST /api/v1/auth/member/login` | Mobile login | `mobile/lib/features/auth/data/auth_api.dart:87` |
| `POST /api/v1/auth/refresh` | Token refresh with an expired access token | `mobile/lib/features/auth/data/auth_api.dart:47`; scenario tests |
| `POST /api/v1/auth/register/web` | Web member registration | `web/src/features/auth/api.ts:24` |
| `POST /api/v1/auth/login`, `/register`, `/verify-otp`, `/complete-registration`, `GET /check-phone` | Legacy phone and OTP flow; already public; scenario tests use `/login` and `/register` | No current web or mobile caller. Kept to avoid scope creep. |
| `GET /api/v1/sectors`, `GET /api/v1/sectors/{id}` | Sector picker on the registration page; sector lookup at login | `web/src/features/auth/api.ts:18`, `mobile/lib/features/auth/data/auth_api.dart:29,57` |
| `/uploads/**` | Photo and pod-logo files. `<img>` and `Image.network` send no token. | URLs built by `LocalPhotoStorageService.kt:92-101`, served by `StorageConfig.kt:79` |
| `/swagger-ui.html`, `/swagger-ui/**`, `/v3/api-docs/**`, `/v3/api-docs.yaml`, `/swagger-resources/**`, `/webjars/**` | API docs and eyeball Swagger links | `scripts/console/project.yaml:24,35` |
| `/error` | Error dispatch (see above) | Spring Boot |

`/api/v1/sectors/**` is public today, which also opens `GET /api/v1/sectors/{id}/ground-admins` at the chain. That handler rejects anonymous callers itself (`GroundAdminController.kt:422-424`). The fix narrows the rule to the two GET routes above, so the chain rejects anonymous callers first. Its test (`GroundAdminControllerTest.kt:415`) asserts only the status, so it still passes.

CORS preflight is not a public route. `.cors { }` puts Spring's `CorsFilter` ahead of authorization, and it answers `OPTIONS` from the `WebConfig` mapping. Do not add an `OPTIONS /**` permit.

## Affected components

### Backend (fix)
- `shared/config/SecurityConfig.kt`: replace the fallthrough, add `/error` and `/actuator/health/**`, narrow sectors to GET.
- `photos/service/PhotoResult.kt`: add `Forbidden` and `IssueNotFound`.
- `photos/service/PhotoActor.kt` (new): who is acting, `Member(MemberId)` or `Admin`. A ground admin holds a member token, so no third variant is needed.
- `verification/service/VerificationService.kt`: new `mayVerify(issueId, memberId): Boolean` (see Decision).
- `photos/service/IssuePhotoService.kt`: take an actor and load the issue through `IssueService.findById`. Upload allows the reporter, an admin, or `VerificationService.mayVerify`. Delete allows the reporter or an admin. Both check before storing or deleting.
- `photos/api/PhotoController.kt`: build the actor from the `Authentication`, map `Forbidden` to 403 and `IssueNotFound` to 404, return 204 from a `PhotoResult` on delete.
- No migration. No DTO change. No change to `IssueService`. Neither `IssueService` nor `VerificationService` depends on photos, so there is no cycle. The `VerificationService` chain runs through `MessageService` and `GroundAdminService`, and none of them uses `IssuePhotoService`.

### Web
No change. Every web call after login goes through `apiClient`, which attaches the token (`web/src/lib/api-client.ts:53-59`). Pre-login calls hit routes that stay public. The web never calls the photo upload or delete routes.

### Mobile
No code change. Dio attaches the token to every non-auth request (`mobile/lib/shared/providers/dio_provider.dart:58-69`). Issue creation uploads photos as the reporter (`features/issues/data/issue_api.dart:90`), which the new rule allows. The ground-admin verify flow uploads its photo through the same route, and the widened upload rule keeps it working (see Decision).

## Decision: ground-admin verification photos (user, 2026-10-28)

`mobile/lib/features/verification/data/verification_api.dart:38-41,58-77`: a ground admin who submits a verification with an optional photo first uploads it through `POST /api/v1/issues/{issueId}/photos`. A ground admin is a member, and usually not the reporter. A strict reporter-or-admin rule answers 403, and mobile then abandons `submitVerification`.

The user chose to widen the upload rule in this fix. Upload is allowed for the reporter, an admin, or the ground admin assigned to the issue's pending verification. Delete stays reporter-or-admin.

### How assignment is stored
- `issue_verifications.assigned_to` (`IssueVerification.assignedTo: MemberId?`) is nullable.
- It is set only when an admin calls `POST /issues/{id}/request-verification` with `assignTo` (`VerificationService.kt:79-85`).
- Every auto-triggered verification is saved with `assigned_to` null, in all four sector modes (`VerificationService.kt:112-117`). The request is then offered to every active ground admin in the sector through messages.
- `submitVerification` accepts any active ground admin when `assigned_to` is null, and only the named member otherwise (`VerificationService.kt:169-175`). It does not check the sector.
- `IssueVerificationRepository.findPendingForGroundAdmin(sectorId, memberId)` (`JpaIssueVerificationRepository.kt:25-37`) returns pending verifications on issues in the member's sector where `assigned_to = member OR assigned_to IS NULL`. That is the stored meaning of "assigned to me". It feeds `GET /members/me/pending-verifications`, the list the mobile verify screen starts from.

The dev database holds no `issue_verifications` rows, so this was read from code, not data.

### The check
New `VerificationService.mayVerify(issueId, memberId): Boolean`:
- `memberRepository.findById(memberId)` must return a member with `isGroundAdmin` and `groundAdminStatus == ACTIVE`;
- and `verificationRepository.findPendingForGroundAdmin(member.sectorId, memberId).any { it.issueId == issueId }` must be true.

`IssuePhotoService` calls it on upload only, after the reporter and admin checks. The photos package never reads the verification or member repositories.

### What "assigned" therefore means
For an assigned verification, only the named ground admin may upload. For an unassigned one, every active ground admin of the issue's sector may upload while it is pending, because every one of them may answer it. A literal `assigned_to = member` rule would leave the verify flow broken for every auto-triggered verification, the common case.

## Fix approach

1. Write the tests first (see the handoff for the exact list): chain tests in `SecurityConfigTest`, service tests in a new `IssuePhotoServiceTest`, MockMvc cases in `PhotoControllerTest`.
2. Change the chain so it ends in `anyRequest().authenticated()`, with the public routes above named explicitly.
3. Give the photo service an actor and a `Forbidden` result. The service decides; the controller only translates the `Authentication` into an actor and the result into HTTP.
4. Add `VerificationService.mayVerify` and use it on upload only.
5. Check ownership before `validationService.validate` and `storageService.store`, so a forbidden upload writes nothing to disk.

## Tests that relied on the current behaviour

| Test | Why it breaks | Change |
|---|---|---|
| `photos/api/PhotoControllerTest.kt:82,110,134` | Stubs `uploadPhoto(any(), any())`; the signature gains an actor | Stub three arguments |
| `photos/api/PhotoControllerTest.kt:229-254` | Stubs `deletePhoto(id)` returning `Boolean` | Stub `deletePhoto(id, any())` returning `PhotoResult` |
| `photos/service/PhotoResultTest.kt:101-125` | Exhaustive `when` expressions stop compiling when variants are added | Add the two new branches |

No test reaches a newly protected route without a token. The integration scenarios (`integration/scenarios/*`) hit only routes that already have explicit rules. Every other test of a protected route already sends a token or uses `@WithMockUser`. `SupportAccessControllerTest` runs with `addFilters = false` and does not see the chain.

## Risk

- **Medium: an unlisted public caller.** Any client call this record missed, made without a token, turns into 401. The search covered `web/src` and `mobile/lib` and the console scripts. The mock API (`infrastructure/mock-api`) is not the backend and is unaffected.
- **Low: unassigned verifications.** While an unassigned verification is pending, any active ground admin of the sector can add photos to that issue. They can also answer the verification itself, so this adds no new reach. They cannot delete photos.
- **Low: query cost.** The extra check runs only for members who are neither the reporter nor an admin. It costs one member lookup and one query.
- **Low: admin scope.** "Admin" means any `ROLE_ADMIN` token, or an active support grant. Admins are not yet limited to their own sector (#56 tracks scope). This is no wider than today's `PATCH /issues/{id}/state`.
- **Low: existence oracle.** Delete checks `NotFound` before `Forbidden`, so a signed-in member can tell whether a photo id exists. Photo ids are random UUIDs.
- **Low: body change.** Anonymous `/api/v1/messages` now returns `UNAUTHENTICATED` instead of `UNAUTHORIZED`. No client reads the code.
