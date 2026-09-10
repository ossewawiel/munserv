---
issue: 117
story: FIX117
title: "Unauthenticated requests answer 401 instead of 403"
platform: backend
status: completed
depends_on: []
touches:
  - backend/src/main/kotlin/com/munserv/shared/config
  - backend/src/main/kotlin/com/munserv/shared/api
  - backend/src/test/kotlin/com/munserv/auth/api
  - specs/contracts/api.md
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: orchestrator
created_at: "2026-09-10"
files_changed:
  - backend/src/main/kotlin/com/munserv/shared/config/UnauthenticatedEntryPoint.kt
  - backend/src/main/kotlin/com/munserv/shared/config/SecurityConfig.kt
  - backend/src/main/kotlin/com/munserv/shared/api/ErrorResponse.kt
  - backend/src/test/kotlin/com/munserv/shared/config/SecurityConfigTest.kt
  - backend/src/test/kotlin/com/munserv/auth/api/AuthControllerAdditionalTest.kt
  - backend/src/test/kotlin/com/munserv/auth/api/WebRegistrationApiContractTest.kt
  - backend/src/test/kotlin/com/munserv/admin/api/AdminControllerTest.kt
  - backend/src/test/kotlin/com/munserv/members/api/MemberControllerTest.kt
  - backend/src/test/kotlin/com/munserv/photos/api/PhotoControllerTest.kt
  - backend/src/test/kotlin/com/munserv/groundadmin/api/GroundAdminControllerTest.kt
  - backend/src/test/kotlin/com/munserv/support/api/SupportGrantAccessRevocationTest.kt
  - specs/contracts/api.md
tests_added:
  - SecurityConfigTest.should answer 401 with the standard body when no token is sent
  - SecurityConfigTest.should answer 401 when the token is expired
  - SecurityConfigTest.should answer 403 when the role is not allowed
  - SecurityConfigTest.expired token result should not be valid
---

# FIX117 · Unauthenticated requests answer 401, forbidden ones 403 (Backend)

Read `domain/README.md`. Found by the reviewer of #116: `SecurityConfig` registers no `AuthenticationEntryPoint`, so a request with a missing or expired token is refused by the authorisation layer with 403, indistinguishable from "signed in but not allowed". The web client had to guess from the stored token's expiry.

## Outcome
A client can tell "not signed in" (401) from "not allowed" (403) on every endpoint.

## Acceptance criteria
- [x] A request to any protected endpoint with no `Authorization` header answers `401` with the standard error body (`ErrorResponse` from `com.munserv.shared.api`, code `UNAUTHENTICATED`, message "Authentication required").
- [x] A request with an expired or malformed JWT answers `401` with the same body.
- [x] An authenticated request to an endpoint the role may not call still answers `403` (unchanged, e.g. a ward admin calling `GET /pod/dashboard`).
- [x] `POST /auth/admin/login` with wrong credentials keeps answering `401` as today.
- [x] `specs/contracts/api.md` documents the rule once in its error conventions section.

## Visual
None.

## Contract
No endpoint shape changes. Error body: `ErrorResponse` (`backend/src/main/kotlin/com/munserv/shared/api/ErrorResponse.kt`). Add to `specs/contracts/api.md` near the top (error conventions): "401 `UNAUTHENTICATED`: no, expired or invalid token; 403: authenticated but not allowed."

## Steps
1. `backend/src/main/kotlin/com/munserv/shared/config/SecurityConfig.kt`: add `.exceptionHandling { it.authenticationEntryPoint(unauthenticatedEntryPoint) }` where `unauthenticatedEntryPoint` writes status 401, `application/json`, and the serialised `ErrorResponse` (use the existing Jackson `ObjectMapper` bean via `tools.jackson`), for unauthenticated requests only; keep the access-denied path (403) as is. Test: `SecurityConfigTest` (`@SpringBootTest` + MockMvc) `should answer 401 with the standard body when no token is sent`, `should answer 401 when the token is expired`, `should answer 403 when the role is not allowed`.
2. `backend/src/main/kotlin/com/munserv/auth/security/JwtAuthenticationFilter.kt` (or wherever the token is parsed): make sure an invalid or expired token results in no authentication being set (so the entry point fires) rather than a 403 written by the filter; no other behaviour change.
3. `backend/src/test/kotlin/com/munserv/auth/api/AuthControllerAdditionalTest.kt` line ~289: rename `should return 401 without token` to match its assertion and switch it to `isUnauthorized()`; grep every other test asserting `isForbidden()` for a missing token and update them.
4. `specs/contracts/api.md`: the one-paragraph rule in the error conventions.
5. `web/src/lib/api-client.ts` is NOT in scope; leave the web client (it already handles 401). Note in the PR body that the expiry heuristic there can be removed in a later web story.

## Do not
- Do not change any controller or the role aspect.
- Do not touch web or mobile.
- Do not change the support-grant filter (`SupportGrantActivityFilter`); a revoked grant still clears the context and results in 401 from the entry point, which the web client already treats as session-expired.

## Done when
```bash
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes.

## Eyeball
```yaml
- id: E1
  title: Missing token answers 401 with the standard body
  as: none
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Pod%20Settings/getSettings_1
  steps:
    - 'Without pressing Authorize, open http://localhost:8080/swagger-ui/index.html#/Pod%20Settings/getSettings_1, press "Try it out", Execute.'
  expect: 'Response code 401 and a JSON body with code "UNAUTHENTICATED" and message "Authentication required".'
- id: E2
  title: Wrong role still answers 403
  as: ward_admin
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin
  steps:
    - 'Log in at http://localhost:8080/swagger-ui/index.html#/Authentication/adminLogin with {"email": "wardadmin@munserv.local", "password": "wardadmin123"}, copy tokens.accessToken, press Authorize and paste it.'
    - 'Open http://localhost:8080/swagger-ui/index.html#/Pod%20Settings/getSettings_1, press "Try it out", Execute.'
  expect: Response code 403.
- id: E3
  title: Web session still ends when the token is gone
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/
  steps:
    - Log in on http://localhost:3000/login, then in the browser devtools Application tab delete the accessToken entry from Local Storage and reload the page.
  expect: The app returns to http://localhost:3000/login with the session-expired message.
```
