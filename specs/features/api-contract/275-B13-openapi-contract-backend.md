---
issue: 275
story: B13
title: "Export the API contract from the code"
platform: backend
status: completed
depends_on: []
touches: [backend/src/main/kotlin/com/munserv/admin, backend/src/main/kotlin/com/munserv/auth, backend/src/main/kotlin/com/munserv/bootstrap, backend/src/main/kotlin/com/munserv/groundadmin, backend/src/main/kotlin/com/munserv/issues, backend/src/main/kotlin/com/munserv/members, backend/src/main/kotlin/com/munserv/messages, backend/src/main/kotlin/com/munserv/photos, backend/src/main/kotlin/com/munserv/pod, backend/src/main/kotlin/com/munserv/sectors, backend/src/main/kotlin/com/munserv/shared, backend/src/main/kotlin/com/munserv/support, backend/src/main/kotlin/com/munserv/verification, specs/contracts, specs/features/_template]
ui: false
user_facing: false
eyeball_exempt: []
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-11-05"
files_changed: [.github/workflows/ci.yml, CLAUDE.md, CONTRIBUTING.md, backend/CLAUDE.md, backend/README.md, backend/build.gradle.kts, backend/src/main/kotlin/com/munserv/admin/api/AdminController.kt, backend/src/main/kotlin/com/munserv/admin/api/AdminManagementController.kt, backend/src/main/kotlin/com/munserv/admin/api/AdminResponse.kt, backend/src/main/kotlin/com/munserv/admin/api/OnboardingController.kt, backend/src/main/kotlin/com/munserv/auth/api/AuthController.kt, backend/src/main/kotlin/com/munserv/auth/api/AuthResponse.kt, backend/src/main/kotlin/com/munserv/bootstrap/api/BootstrapController.kt, backend/src/main/kotlin/com/munserv/groundadmin/api/GroundAdminController.kt, backend/src/main/kotlin/com/munserv/groundadmin/api/GroundAdminDto.kt, backend/src/main/kotlin/com/munserv/issues/api/IssueController.kt, backend/src/main/kotlin/com/munserv/members/api/MemberController.kt, backend/src/main/kotlin/com/munserv/messages/api/MessageController.kt, backend/src/main/kotlin/com/munserv/photos/api/PhotoController.kt, backend/src/main/kotlin/com/munserv/pod/api/PodAdministratorController.kt, backend/src/main/kotlin/com/munserv/pod/api/PodController.kt, backend/src/main/kotlin/com/munserv/pod/api/PodDashboardController.kt, backend/src/main/kotlin/com/munserv/pod/api/PodDto.kt, backend/src/main/kotlin/com/munserv/sectors/api/SectorController.kt, backend/src/main/kotlin/com/munserv/sectors/api/SectorSettingsController.kt, backend/src/main/kotlin/com/munserv/shared/config/OpenApiConfig.kt, backend/src/main/kotlin/com/munserv/support/api/SupportAccessController.kt, backend/src/main/kotlin/com/munserv/support/api/SupportGrantSelfController.kt, backend/src/main/kotlin/com/munserv/verification/api/VerificationController.kt, backend/src/main/kotlin/com/munserv/verification/api/VerificationDto.kt, backend/src/test/kotlin/com/munserv/shared/config/OpenApiCanonical.kt, backend/src/test/kotlin/com/munserv/shared/config/OpenApiCanonicalTest.kt, backend/src/test/kotlin/com/munserv/shared/config/OpenApiContractTest.kt, specs/README.md, specs/contracts/api.md, specs/contracts/openapi.json, specs/features/_template/story-handoff.md, specs/features/pod-chief-mvp/076-W18b-pod-logo-upload-web.md]
tests_added: [OpenApiContractTest (5 tests), OpenApiCanonicalTest (6 tests)]
---

# B13 · Export the API contract from the code (Backend)

Read `domain/README.md` for every term used below. This handoff is complete on its own. No route, status code or JSON body changes: only annotations, one test, one generated file, docs.

## Outcome
Anyone can read the wire contract from `specs/contracts/openapi.json`, and CI refuses a backend change that leaves that file stale.

## Acceptance criteria
- [ ] `OpenApiContractTest` boots the app, fetches `/v3/api-docs` and writes `specs/contracts/openapi.json` with sorted keys and no `servers` block; the file is byte-identical across two consecutive runs and across a clean and an incremental Gradle build
- [ ] The JSON lists every controller route; the test checks this against `RequestMappingHandlerMapping` for `com.munserv` handlers, not a hardcoded count (76 method-and-path pairs on this PR)
- [ ] Every route has an explicit, unique `@Operation(operationId = ...)` that follows the naming rule, and at least one tag
- [ ] Every success response with a body names a schema, and the schema names match the wire, so a DTO change reaches the JSON
- [ ] Changing a DTO field without regenerating fails CI, and so does a hand edit of `openapi.json` alone
- [ ] `specs/contracts/api.md` is a short guide that links the JSON and the Swagger UI and keeps the cross-cutting conventions; every route-specific fact from the old file that is true in the code now sits in the controller annotations
- [ ] `specs/features/_template/story-handoff.md` and the living docs no longer name `api.md` as the place new endpoints are added
- [ ] ktlint and tests pass

## Contract
None changes on the wire. Mechanism, proven on master: `@SpringBootTest` + `@Import(TestContainersConfig::class)` + `@AutoConfigureMockMvc` + `@ActiveProfiles("test")` gets 200 from `/v3/api-docs` with no token, 76 operations, 76 `com.munserv` handlers and identical route sets. The test's working directory is `backend/` in the shared checkout and in a worktree, so the file is `Path.of("..", "specs", "contracts", "openapi.json")`.

**Drift rule.** The test compares and fails; it never rewrites and passes. A stale or missing file: write the new content, then fail with "openapi.json was stale and has been rewritten. Review it, commit it, run the test again." A matching file: do not touch it. So CI fails on staleness, and the Stop hook blocks until the regenerated file exists.

## Steps
1. `backend/src/test/kotlin/com/munserv/shared/config/OpenApiCanonical.kt` (new): `fun canonicalize(raw: JsonNode): JsonNode` using `tools.jackson.databind.json.JsonMapper.builder().enable(SerializationFeature.INDENT_OUTPUT).build()`, `createObjectNode()`, `createArrayNode()`, `node.properties()`. Rules: drop the root `servers`; sort object keys at every depth by plain `String` order (`ORDER_MAP_ENTRIES_BY_KEYS` does not reach `JsonNode`); sort string arrays under `required`, `type` and `tags`; sort the root `tags` objects by `name`; keep `enum` and `parameters` order. Test: `OpenApiCanonicalTest.kt` (plain unit test) `should sort keys at every depth`, `should drop servers`, `should sort tags by name`, `should keep enum order`.
2. `backend/src/test/kotlin/com/munserv/shared/config/OpenApiContractTest.kt` (new), annotations as in Contract. Read the body with `response.contentAsByteArray`, not `contentAsString`, so non-ASCII text survives. Write `mapper.writeValueAsString(canonicalize(tree)) + "\n"` in UTF-8. Assert first that `../specs/contracts` is a directory. Tests:
   - `should match the committed contract file`: the drift rule. Use `org.junit.jupiter.api.fail`.
   - `should list every controller route`: inject `@Qualifier("requestMappingHandlerMapping") RequestMappingHandlerMapping` (a second bean of that type exists), keep `handlerMethods` whose `beanType.packageName` starts with `com.munserv`, expand `methodsCondition.methods` x `pathPatternsCondition.patternValues`, assert no handler has an empty method set, assert the set equals the JSON's method-and-path set.
   - `should give every route an explicit unique operationId and a tag`: read `getMethodAnnotation(Operation::class.java).operationId` from each handler. It must match `^[a-z][a-zA-Z0-9]*$`, be unique and equal the JSON's value. JSON `tags` is non-empty and root tag names are unique. Check the annotation, not only the JSON: springdoc invents an id from the function name, so a JSON-only check passes with no annotation.
   - `should name a schema on every success response with a body`: each 2xx except 204 has `content`, and its schema is not a bare `{ "type": "object" }`.
   - `should keep is-prefixed names as on the wire`: the schemas hold `isComplete`, `isOnboarded`, `isGroundAdmin`, `isRegistered`, and not `complete`, `onboarded`, `groundAdmin`, `registered`.
3. `backend/build.gradle.kts`, inside `tasks.withType<Test>`: add `inputs.files("../specs/contracts/openapi.json").withPropertyName("openApiContract").withPathSensitivity(PathSensitivity.NONE)` and `testLogging.exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL`. The input is required: `org.gradle.caching=true` is on, and CI restores the cache, so without it a hand edit leaves `:test` `UP-TO-DATE` or `FROM-CACHE` and the check never runs. `FULL` puts the failure message in the CI log.
4. `.github/workflows/ci.yml`, in the `changes` job under `backend:`, add `- 'specs/contracts/openapi.json'` after `- 'backend/**'`. Add no other step.
5. Operation ids, in every controller. Rule: lowerCamelCase `<verb><Noun>`, no underscores, `list` for a collection, `get` for one, and the noun names the resource. Set `operationId` to the Kotlin function name, except these (`function -> id`). Do not rename the Kotlin functions or any tag.
   - `AdminController`: getDashboard -> getAdminDashboard, getMembers -> listMembers. `OnboardingController`: changePassword -> changeOnboardingPassword, completeProfile -> completeOnboardingProfile, getStatus -> getOnboardingStatus.
   - `GroundAdminController`: apply -> applyForGroundAdmin, acceptInvitation -> acceptGroundAdminInvitation, declineInvitation -> declineGroundAdminInvitation, stepDown -> stepDownAsGroundAdmin, invite -> inviteGroundAdmin, revokeInvitation -> revokeGroundAdminInvitation, approve -> approveGroundAdminApplication, decline -> declineGroundAdminApplication, revoke -> revokeGroundAdmin, updateStatus -> updateGroundAdminStatus.
   - `MessageController`: getMessages -> listMessages, markAsRead -> markMessageRead, performAction -> performMessageAction. `PhotoController`: getPhotosForIssue -> listIssuePhotos.
   - `PodController`: getSetupStatus -> getPodSetupStatus, getSettings -> getPodSettings, updateSettings -> updatePodSettings, uploadLogo -> uploadPodLogo. `SectorSettingsController`: getSettings -> getSectorSettings, updateSettings -> updateSectorSettings. `SectorController`: getAllSectors -> listSectors, getSectorById -> getSector.
   - `SupportAccessController`: listGrants -> listSupportGrants, createGrant -> createSupportGrant, revokeGrant -> revokeSupportGrant. `SupportGrantSelfController`: getCurrentGrant -> getCurrentSupportGrant. `VerificationController`: overrideState -> overrideIssueState, getVerificationHistory -> listIssueVerifications, getPendingVerifications -> listMyPendingVerifications.
6. `SupportGrantSelfController.kt` and `SupportAccessController.kt`: give both `@Tag(name = "Support Access")` the same description: "Pod chiefs grant, list and revoke support access; a support grant holder reads their own grant." Two descriptions make two root tags.
7. Response schemas, 28 handlers that return `ResponseEntity<*>`: add `content = [Content(schema = Schema(implementation = X::class))]` to the 2xx `ApiResponse`. Do not change the handlers.
   - `AuthController`: register, verifyOtp -> OtpResponse; completeRegistration -> RegistrationResponse; login -> LoginResponse; adminLogin -> AdminLoginResponse; refreshToken -> TokenResponse; checkPhone -> CheckPhoneResponse; registerWeb -> WebRegisterResponse; memberLogin -> MemberLoginResponse; changePassword -> auth MessageResponse. `MemberController`: getCurrentMember -> MemberProfileResponse.
   - `GroundAdminController`: apply, acceptInvitation, declineInvitation, invite, revokeInvitation, approve, decline -> GroundAdminApplicationResponse; getMyGroundAdminInfo -> GroundAdminInfoResponse; listGroundAdmins -> GroundAdminListResponse; stepDown, revoke, updateStatus -> new `GroundAdminStatusChangeResponse(val status: String)` in `GroundAdminDto.kt` (the service keeps returning its map).
   - `VerificationController`: requestVerification, submitVerification -> IssueVerificationResponse; getPendingVerifications -> PendingVerificationsResponse; getVerificationHistory -> VerificationHistoryResponse; overrideState -> new `OverrideStateResponse(val status: String)` in `VerificationDto.kt`.
8. Schema names that today lie about the wire. springdoc keys schemas by simple class name, so same-named classes overwrite each other: `/admin/onboarding/change-password` shows the auth request's `currentPassword` today. Add `name` to the class `@Schema`: onboarding `ChangePasswordRequest` -> `OnboardingChangePasswordRequest` (the class already has `@Schema`, so edit it); auth `MessageResponse` -> `AuthMessageResponse`; auth `GeoPointResponse` -> `AuthGeoPointResponse`. springdoc also strips `is` from Kotlin booleans, so add `@get:JsonProperty("<name>")` on `PodSetupStatusResponse.isComplete`, `OnboardingStatusResponse.isOnboarded`, admin `MemberResponse.isGroundAdmin` and `CheckPhoneResponse.isRegistered`. Tests: `PodControllerTest` and `AuthControllerAdditionalTest` stay green; they assert the wire names.
9. Move facts from `api.md` to annotations, checking each against the code first. Text goes in `@Operation(description)` unless marked. The old `api.md` keys routes by path; ids below are the new ones.
   | Operation | Fact |
   |---|---|
   | adminLogin | Under an active grant `profile.admin.role` is the granted role, never `super_user`, and `profile.supportGrant` carries the grant (null otherwise). `tokens.expiresAt` is the token's expiry, `supportGrant.expiresAt` the grant's sliding expiry. 401 also when the pod is not bootstrap-eligible and has no active grant. |
   | logout | Always 204; a no-op for a token without a grant. |
   | updateGroundAdminStatus, revokeGroundAdminInvitation | Add `ApiResponse` 400: "`inactive` is refused: use revoke"; "Not an invitation". |
   | getPodSetupStatus | `missingSteps` holds `pod_name`, `pod_boundaries`, `wards_sectors`, `first_admin`; empty when complete. No wards or sectors (#59). |
   | getPodSettings | `displayName` is `"Munserv Pod {name}"`, server-derived; clients render it, never build it. `logoUrl` is null with no logo. |
   | uploadPodLogo | One multipart part `file`: JPEG, PNG or WebP, max 5MB. |
   | listAdministrators | A pod's administrators are admins with its `podId` plus ward- and sector-level admins of its wards and sectors. Unpaginated; `total` equals `items.length`. Filters combine with AND. Default `createdAt:asc`. `role` sorts by hierarchy, `email` and `displayName` ignore case. 400 codes `invalid_sort`, `invalid_role`, `invalid_ward_id`. |
   | createAdministrator | Sends an `admin_welcome` message; `temporaryPassword` is shown once. 409 code `email_exists`. |
   | getAdministrator, deleteAdministrator | 403 codes: `cross_pod`, `out_of_scope`; `cannot_delete_self`, `insufficient_permissions`, `cross_pod`. |
   | overrideIssueState | Skips the legal transition check and expires pending verifications. |
   | updateSectorSettings | `daysFixedBeforeClosed` 1-365, `minimumGroundAdmins` 0-100. |
   | getMessage | `admin_welcome` carries `metadata.tasks`, a list of strings. |
   | createSupportGrant, revokeSupportGrant, getCurrentSupportGrant | 400 body `{ messages: string[] }`; 409 code `active_grant_exists`; 409 code `grant_not_active`; 403 code `not_support_grant`. |
10. `backend/src/main/kotlin/com/munserv/shared/config/OpenApiConfig.kt`: replace "All errors follow this structure" with "The target error structure is below; older endpoints differ until #246 closes".
11. Generate: run the contract test twice (Done when). The file appears after the first, red, run. Commit it.
12. `specs/contracts/api.md`: replace the whole file, under 60 lines, with these sections. Do not keep the `archive/MVP_Development_Guide.md` link.
   - **Contract**: base URL `/api/v1`; `openapi.json` is generated, the source of truth, never hand-edited; Swagger UI `http://localhost:8080/swagger-ui.html`; deep link `http://localhost:8080/swagger-ui/index.html#/<Tag>/<operationId>`, a space in a tag written `%20`.
   - **Changing the contract**: annotate the controller, run `cd backend && ./gradlew test --tests '*OpenApiContractTest*'`, review, commit, rerun. On a merge conflict in the file, take either side and regenerate.
   - **Naming**: the rule from step 5.
   - **Error conventions**: keep the 401 and 403 line. The bodies, tracked in #246, are `{ error: { code, message, details? } }`, flat `{ code, message }` (Pod Settings, Pod Administrators, Support Access), `{ error, message }` (Authentication), `{ messages: string[] }` (Support Access validation). A revoked or expired grant token gets 401 `UNAUTHENTICATED`; a token with no grant gets 403 `not_support_grant`.
   - **Known gaps**: documented before but never built: `POST /auth/verify`, `GET /members/{id}/issues`, `GET` and `PATCH /members/me/notification-settings` (mobile calls the last two).
   - **History**: `git show bd32a4b:specs/contracts/api.md`.
13. Pointers, one edit each:
   - `specs/features/_template/story-handoff.md:39`: "API or type changes this story depends on, quoted from `specs/contracts/openapi.json` (generated from the controllers) / `types.md`; a shape not built yet is written here and the backend story makes it true. "None" if none."
   - `specs/README.md`: line 10 becomes one row for `contracts/openapi.json` (generated source of truth) and one for `contracts/api.md` (guide). Line 24 becomes "New endpoint: annotate the controller and regenerate `contracts/openapi.json`. New shared type: edit `contracts/types.md`."
   - `backend/README.md:239` and `:244`: link the JSON and call `api.md` the guide.
   - `specs/features/pod-chief-mvp/076-W18b-pod-logo-upload-web.md:55`: replace the `api.md` pointer with `specs/contracts/openapi.json`, operations `uploadPodLogo` and `updatePodSettings`.
   - `CONTRIBUTING.md:72` and root `CLAUDE.md:8`: name `openapi.json` first. `CLAUDE.md` has 79 lines and a limit of 80, so edit that line and add none.
   - `backend/CLAUDE.md`, Commands: add that every `@Operation` needs an `operationId` and that a route or DTO change regenerates the file, with the step 12 command.
14. Prove drift, and put the output in your final message. Add `val contractProbe: String? = null` to `CheckPhoneResponse`; the contract test must fail; `git checkout -- <that file> ../specs/contracts/openapi.json`. Then change `"1.0.0"` in `openapi.json` by hand; the same command must run and fail, not report `UP-TO-DATE`; the file is restored by the test. Print the count: `python3 -c "import json;d=json.load(open('../specs/contracts/openapi.json'));print(sum(m in ('get','post','put','patch','delete') for p in d['paths'].values() for m in p))"`. It prints 76, or more if master gained a route; state the number in the PR body.

If the harness refuses an edit to `.github/workflows/ci.yml`, `CLAUDE.md` or `CONTRIBUTING.md` (outside the allow list), do not use the shell instead: finish the rest and name the file and the edit in your final message, so the orchestrator can put it to the user.

## Do not
- Do not edit `.claude/agents/feature-planner.md`; the main session changes it after merge. Do not touch `web/`: `SupportGrantBanner.stories.tsx:32` keeps pointing at `api.md`, which keeps the grant-token rule.
- Do not edit done rows B11 and B12 in `specs/requirements/backend.md`, handoffs under `completed/`, `081-W21b` (status completed) or `specs/architecture/overview.md:41` (its link stays true).
- Do not hardcode 76 in a test, add `springdoc.*` properties, or add a `git diff` step to CI: a cached `:test` would rewrite nothing and that diff would pass.
- Do not port the 4 routes in Known gaps, or copy old `api.md` response shapes without checking the code: several are out of date (ground admin answers are `{ applicationId, status }`, not `{ status, member }`).
- Do not fix the three error bodies (#246), and do not rename `LocationResponse`: its two classes have one shape.

## Done when
```bash
cd backend && ./gradlew ktlintFormat && ./gradlew ktlintCheck test
./gradlew test --tests '*OpenApiContractTest*' --rerun --no-build-cache   # a new JVM agrees with the file
./gradlew clean test --tests '*OpenApiContractTest*' --no-build-cache     # a clean build agrees with the file
git diff --exit-code ../specs/contracts/openapi.json                      # after your commit: nothing rewrote it
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.
