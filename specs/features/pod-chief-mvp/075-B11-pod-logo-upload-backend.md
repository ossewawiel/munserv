---
issue: 96
story: B11
title: "Pod logo upload"
platform: backend
status: completed
depends_on: []
touches:
  - backend/src/main/kotlin/com/munserv/pod
  - specs/contracts
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-09-06"
files_changed:
  - backend/src/main/kotlin/com/munserv/pod/service/PodLogoResult.kt
  - backend/src/main/kotlin/com/munserv/pod/service/PodLogoService.kt
  - backend/src/main/kotlin/com/munserv/pod/api/PodDto.kt
  - backend/src/main/kotlin/com/munserv/pod/api/PodController.kt
  - backend/src/test/kotlin/com/munserv/pod/service/PodLogoServiceTest.kt
  - backend/src/test/kotlin/com/munserv/pod/api/PodControllerTest.kt
  - specs/contracts/api.md
tests_added:
  - com.munserv.pod.service.PodLogoServiceTest
  - com.munserv.pod.api.PodControllerTest.UploadLogo
---

# B11 · Pod logo upload (Backend)

Read `domain/README.md` and `domain/pod.md` for every term used below. This handoff is complete on
its own; do not read the feature spec or other stories' handoffs.

## Outcome
A pod chief posts an image file to `POST /pod/logo` and gets back the public URL of the stored file,
which they then persist with `PATCH /pod/settings`.

## Acceptance criteria
- [ ] `POST /pod/logo` accepts `multipart/form-data` with a `file` part and requires role `pod_chief`
- [ ] The file is stored through the existing photo storage mechanism (`PhotoStorageService`) and served from `/uploads`
- [ ] Success returns `200 { "logoUrl": string }`
- [ ] An empty file, a non-image content type or a file over 5MB returns `400 { code, message }`; a storage failure returns `500`
- [ ] `PATCH /pod/settings` keeps accepting `logoUrl`, so the returned URL can be persisted
- [ ] `specs/contracts/api.md` documents the endpoint and `./gradlew ktlintCheck test` passes

## Visual (ui stories only)
None.

## Contract
New endpoint, in `specs/contracts/api.md` § Pod, directly after `PATCH /pod/settings`. Write exactly
this and **delete** the paragraph that currently ends the Pod section ("There is **no** logo
file-upload endpoint. ..."):

```
### POST /pod/logo
Upload a pod logo image. `multipart/form-data`, one part named `file`
(JPEG, PNG or WebP, max 5MB).

**Response:** `200`
{ "logoUrl": "http://localhost:8080/uploads/8f14e45f-ea1e-4d0e-9c6b-2a1c6f1b7d10.png" }

Uploading stores the file only; it does not change the pod. Persist the returned URL with
`PATCH /pod/settings { "logoUrl": ... }`.

**Errors:** 400 Validation error ({ code: "validation_error", message: string }) |
401 Unauthorized | 403 Not pod chief | 500 Storage error ({ code: "internal_error", message: string })
```
(Render the JSON blocks as fenced ```json blocks in api.md, matching the neighbouring entries.)
No change to `specs/contracts/types.md`.

## Steps

Reuse the mechanism member photos already use: the `photoStorageService` bean from
`com.munserv.photos.config.StorageConfig` (a `LocalPhotoStorageService` writing to
`storage.local.upload-dir` and serving `/uploads/**`) and `PhotoValidationService` (5MB,
`image/jpeg`, `image/png`, `image/webp`). Do not add a bucket, a new config property, a new table or
a second storage class.

1. `backend/src/main/kotlin/com/munserv/pod/service/PodLogoResult.kt` (new):
   `sealed interface PodLogoResult { data class Success(val logoUrl: String); data class ValidationError(val errors: List<String>); data class StorageError(val message: String) }`.
   Do **not** add variants to `PodResult`: it is `when`-ed exhaustively in `PodController` and every
   branch would have to change. No test.
2. `backend/src/main/kotlin/com/munserv/pod/service/PodLogoService.kt` (new): `@Service` taking
   `PhotoStorageService` and `PhotoValidationService`, with
   `fun uploadLogo(file: MultipartFile): PodLogoResult`:
   validate first (`ValidationResult.Invalid` → `PodLogoResult.ValidationError(errors)`), then
   `photoStorageService.store(file, PhotoId.generate())` and map `UploadResult.Success` →
   `PodLogoResult.Success(result.url)` and `UploadResult.StorageError` →
   `PodLogoResult.StorageError(message)`. The generated `PhotoId` is only the storage key; nothing is
   written to `issue_photos`. Test:
   `backend/src/test/kotlin/com/munserv/pod/service/PodLogoServiceTest.kt` (new, MockK, no Spring
   context, `MockMultipartFile` as in `PhotoValidationServiceTest`) —
   `should return the stored url when the file is valid`,
   `should return a validation error when the file is not an image` (storage never called:
   `verify(exactly = 0) { storage.store(any(), any()) }`),
   `should return a storage error when the file cannot be written`.
3. `backend/src/main/kotlin/com/munserv/pod/api/PodDto.kt`: add
   `data class PodLogoResponse(val logoUrl: String)`. No test.
4. `backend/src/main/kotlin/com/munserv/pod/api/PodController.kt`: inject `PodLogoService` and add
   ```kotlin
   @PostMapping("/logo", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
   fun uploadLogo(@RequestParam("file") file: MultipartFile): ResponseEntity<*>
   ```
   `when`-ing over `PodLogoResult`: `Success` → `200 PodLogoResponse`, `ValidationError` →
   `400 ErrorResponse("validation_error", errors.joinToString("; "))`, `StorageError` →
   `500 ErrorResponse("internal_error", message)`. Use the same `ErrorResponse` the file already
   uses. The class-level `@RequireRole(AdminRole.POD_CHIEF)` already restricts the endpoint — do not
   add a second check. Document it with `@Operation` / `@ApiResponses` like its neighbours. Test:
   `backend/src/test/kotlin/com/munserv/pod/api/PodControllerTest.kt`, new
   `@Nested inner class UploadLogo` using `@MockkBean PodLogoService`, `MockMultipartFile("file",
   "logo.png", MediaType.IMAGE_PNG_VALUE, ...)` and `mockMvc.multipart("/api/v1/pod/logo") { file(...); header("Authorization", "Bearer $podChiefToken") }`
   (see `PhotoControllerTest` for the multipart helper) —
   `should return 200 with the logo url on a successful upload`,
   `should return 400 when the file fails validation`,
   `should return 500 when storage fails`,
   `should return 403 when the caller is not a pod chief` (stub `adminRepository.findById` with a
   `POD_ADMIN`, in the style of the existing 403 tests in this file).
5. `specs/contracts/api.md`: apply the Contract section above (add the endpoint, delete the
   "no logo file-upload endpoint" paragraph). `PATCH /pod/settings` stays exactly as documented.

## Do not
- Do not persist the URL on the pod inside the upload endpoint, and do not mark any `SetupStep`
  complete: `PATCH /pod/settings` is the only writer of `logoUrl`, and W18/W18b call it.
- Do not create an `issue_photos` row, a `pod_logos` table or a migration; this story has no schema
  change.
- Do not add a delete-logo endpoint, image resizing, a thumbnail or a CDN path. Clearing the logo is
  `PATCH /pod/settings` with a blank `logoUrl`, which `PodService.updateSettings` already maps to null.
- Do not change `PhotoStorageService`, `LocalPhotoStorageService`, `PhotoValidationService` or
  `StorageConfig`; reuse them as they are, including the 5MB / three-content-type limits and the
  existing `spring.servlet.multipart` settings.
- Do not touch web or mobile: W18b (#97) is the web story.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
