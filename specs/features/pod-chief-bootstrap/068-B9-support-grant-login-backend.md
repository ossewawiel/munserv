---
issue: 68
story: B9
title: "Super user login with a support grant"
platform: backend
status: completed
depends_on: [49]
touches: [pod-chief-bootstrap]
created_by: feature-planner
created_at: "2026-09-05"
files_changed:
  - backend/src/main/kotlin/com/munserv/auth/service/JwtService.kt
  - backend/src/main/kotlin/com/munserv/auth/service/AuthResult.kt
  - backend/src/main/kotlin/com/munserv/auth/service/AuthService.kt
  - backend/src/main/kotlin/com/munserv/auth/api/AuthResponse.kt
  - backend/src/main/kotlin/com/munserv/auth/api/AuthController.kt
  - backend/src/main/kotlin/com/munserv/shared/config/SecurityConfig.kt
  - backend/src/main/kotlin/com/munserv/shared/security/JwtAuthenticationFilter.kt
  - backend/src/main/kotlin/com/munserv/shared/security/RoleAuthorizationAspect.kt
  - backend/src/main/kotlin/com/munserv/support/api/SupportGrantActivityFilter.kt
  - backend/src/main/kotlin/com/munserv/support/api/SupportGrantSelfController.kt
  - backend/src/main/kotlin/com/munserv/support/service/SupportAccessService.kt
  - backend/src/test/kotlin/com/munserv/auth/service/JwtServiceTest.kt
  - backend/src/test/kotlin/com/munserv/auth/service/AuthServiceTest.kt
  - backend/src/test/kotlin/com/munserv/auth/api/AuthControllerTest.kt
  - backend/src/test/kotlin/com/munserv/support/service/SupportAccessServiceTest.kt
  - backend/src/test/kotlin/com/munserv/support/api/SupportGrantActivityFilterTest.kt
  - backend/src/test/kotlin/com/munserv/support/api/SupportAccessRoleAuthorizationTest.kt
  - backend/src/test/kotlin/com/munserv/support/api/SupportGrantSelfControllerTest.kt
  - backend/src/test/kotlin/com/munserv/shared/security/JwtAuthenticationFilterTest.kt
  - specs/contracts/api.md
  - specs/contracts/types.md
  - specs/features/pod-chief-bootstrap/implementation-plan.md
  - specs/requirements/backend.md
  - domain/support-grant.md
  - domain/bootstrap.md
  - domain/language.yaml
tests_added:
  - "JwtServiceTest: should round-trip the support grant scope claim when generating a scoped access token"
  - "JwtServiceTest: should not carry a scope claim for an ordinary access token"
  - "SupportAccessServiceTest.LoginUnderGrant: should return Granted and audit the login when an active grant exists"
  - "SupportAccessServiceTest.LoginUnderGrant: should return NotFound when the pod has no active grant"
  - "SupportAccessServiceTest.LoginUnderGrant: should return GrantNotActive when the grant is revoked"
  - "SupportAccessServiceTest.CurrentGrant: should return Granted when the grant is active"
  - "SupportAccessServiceTest.CurrentGrant: should return GrantNotActive when the grant is revoked"
  - "SupportAccessServiceTest.CurrentGrant: should return NotFound when the grant does not exist"
  - "AuthServiceTest: should return SupportGrantLoginSuccess when the pod is not eligible and an active grant exists"
  - "AuthServiceTest: should return InvalidCredentials when the pod is not eligible and no grant exists"
  - "AuthServiceTest: should mint a token whose subject is the grant id and whose role is the granted role"
  - "AuthServiceTest: should revoke the grant when a grant-scoped token logs out"
  - "AuthServiceTest: should not revoke anything when a plain admin token logs out"
  - "AuthControllerTest: POST api-v1-auth-logout should return 204 for an authenticated admin token"
  - "JwtAuthenticationFilterTest: should add ROLE_SUPPORT_GRANT when the token carries the support grant scope"
  - "JwtAuthenticationFilterTest: should not add ROLE_SUPPORT_GRANT for an ordinary admin token"
  - "SupportGrantActivityFilterTest: updated to ROLE_SUPPORT_GRANT authority"
  - "SupportAccessRoleAuthorizationTest: should return 403 on the pod chief grant endpoints for a grant-scoped token"
  - "SupportGrantSelfControllerTest: should return the caller's own grant for a grant-scoped token"
  - "SupportGrantSelfControllerTest: should return 403 for a pod chief token"
---

# B9 · Super user login with a support grant (Backend)

Read `domain/support-grant.md`, `domain/admin-role.md`, `domain/bootstrap.md` and `domain/audit.md`
for every term used below. This handoff is complete on its own; do not read other stories' handoffs.

## Outcome
The super user can log in to a bootstrapped pod while the pod chief has an active support grant, and
gets a token that carries the granted role only, the grant id as subject, and a server-owned expiry.

## Acceptance criteria
- [x] Super user login on a pod that is not bootstrap-eligible succeeds when an active support grant exists for that pod, and is still refused when there is none
- [x] The minted JWT has the grant id as subject and carries the granted role only, never `super_user`; the granted role is enforced server-side on `@RequireRole` endpoints
- [x] The admin login response for that path carries `grantId`, `grantedRole` and the grant's `expiresAt`; `AuthResult` gains the matching case and `AuthController` maps it
- [x] `GET /api/v1/support-access/grants/current` returns the caller's own grant so the client can refresh a slid expiry (grant-scoped callers only)
- [x] `POST /api/v1/auth/logout` revokes a grant-scoped login through `SupportAccessService.revokeOnLogout`, and is a no-op `204` for any other token
- [x] A `SUPPORT_ACCESS_LOGIN` audit entry is written on a grant login
- [x] `specs/contracts/api.md` and `types.md` document the new endpoints and response shape; the stale `POST /api/v1/support-access/login` line is removed from the feature implementation plan; `domain/support-grant.md` and `domain/bootstrap.md` match the shipped login path

## Contract
You are writing the contract in step 12; these are the exact shapes to implement and to document.

`POST /api/v1/auth/admin/login` (existing, public) — response when the credentials are the super
user's and the pod has an active grant. Same `AdminLoginResponse` envelope as an admin login, with
`profile.admin.role` set to the **granted** role and a new `profile.supportGrant` block:
```json
{
  "tokens": { "accessToken": "…", "refreshToken": "…", "expiresAt": "2026-09-05T10:15:00Z" },
  "profile": {
    "admin": { "id": "<grantId>", "email": "<super user email>", "displayName": "Support User",
               "role": "POD_ADMIN", "level": "pod", "podId": "<uuid>", "wardId": null,
               "sectorId": null, "onboardingStatus": null },
    "sector": null,
    "bootstrapStatus": null,
    "supportGrant": { "grantId": "<uuid>", "grantedRole": "pod_admin", "expiresAt": "2026-09-05T11:00:00Z" }
  }
}
```
`tokens.expiresAt` is the access token expiry (unchanged); `supportGrant.expiresAt` is the grant's
server-owned expiry, which slides with activity. `supportGrant` is `null` for every other login.
Errors unchanged: `401 { "error": "invalid_credentials", … }` when no active grant exists.

`GET /api/v1/support-access/grants/current` — grant-scoped tokens only. `200` is the existing
`SupportGrantResponse` (`specs/contracts/types.md` § SupportGrant). Errors: `401` not authenticated |
`403 { "code": "not_support_grant", … }` for any non-grant token | `404` not found |
`409 { "code": "grant_not_active", … }` when revoked, expired or past `expiresAt`.

`POST /api/v1/auth/logout` — any authenticated token. No request body. `204` always.

## Steps
1. `backend/src/main/kotlin/com/munserv/auth/service/JwtService.kt`: add `CLAIM_SCOPE = "scope"` and
   `const val SCOPE_SUPPORT_GRANT = "support_grant"` (public, in the companion), an optional
   `scope: String? = null` parameter on `generateAccessToken` and `generateTokenPair` that is written
   as a claim only when non-null, and `scope: String?` on `TokenValidationResult`, read back in
   `validateToken`. Test: `src/test/kotlin/com/munserv/auth/service/JwtServiceTest.kt`
   `should round-trip the support grant scope claim when generating a scoped access token`.
2. `com/munserv/support/service/SupportAccessService.kt`: add
   `fun loginUnderGrant(podId: PodId, superUserEmail: String): SupportAccessResult` — `@Transactional`,
   finds `supportGrantRepository.findActiveByPodId(podId)`, returns `NotFound` when absent or when
   `!grant.isActiveAt(Instant.now(clock))`, otherwise writes `auditService.logSupportAccessLogin(...)`
   and returns `Granted(SupportGrantView(grant, grantedByName))` (resolve the name the same way
   `list` does). Add `fun currentGrant(id: SupportGrantId): SupportAccessResult` returning
   `Granted` when `isActiveAt(now)`, `GrantNotActive` when the row exists but is not, `NotFound`
   otherwise. Tests: `SupportAccessServiceTest` `should return Granted and audit the login when an
   active grant exists`, `should return NotFound when the pod has no active grant`,
   `should return GrantNotActive when the grant is revoked`.
3. `com/munserv/auth/service/AuthResult.kt`: add
   `data class SupportGrantLoginSuccess(val tokens: TokenPair, val podId: String, val grantId: String, val grantedRole: String, val grantedLevel: String, val superUserEmail: String, val grantExpiresAt: String) : AuthResult`
   and `data object LoggedOut : AuthResult`.
4. `com/munserv/auth/service/AuthService.kt`: inject `supportAccessService: SupportAccessService`.
   In `handleSuperUserLogin`, replace the `BootstrapStatus.NotEligible` branch: call
   `supportAccessService.loginUnderGrant(podId, superUserEmail)`; on `Granted` mint
   `jwtService.generateTokenPair(MemberId(grant.id.value), grant.grantedRole.toDbValue(), JwtService.SCOPE_SUPPORT_GRANT)`
   and return `SupportGrantLoginSuccess`; on anything else keep the existing
   `logSuperUserLoginAttempt(success = false)` + `InvalidCredentials`. Change `adminLogin` from
   `@Transactional(readOnly = true)` to `@Transactional`, since this path writes an audit row. Add
   `fun logout(subject: String, isGrantScoped: Boolean): AuthResult` — when `isGrantScoped` and
   `subject` parses as a UUID, call `supportAccessService.revokeOnLogout(SupportGrantId(uuid))`;
   always return `AuthResult.LoggedOut`. Tests: `AuthServiceTest` (add the new mock to `setup()`)
   `should return SupportGrantLoginSuccess when the pod is not eligible and an active grant exists`,
   `should return InvalidCredentials when the pod is not eligible and no grant exists`,
   `should mint a token whose subject is the grant id and whose role is the granted role`,
   `should revoke the grant when a grant-scoped token logs out`,
   `should not revoke anything when a plain admin token logs out`.
5. `com/munserv/auth/api/AuthResponse.kt`: add
   `data class SupportGrantInfo(val grantId: String, val grantedRole: String, val expiresAt: String)`
   and `val supportGrant: SupportGrantInfo? = null` on `AdminProfile` (last, defaulted, so existing
   construction sites compile unchanged).
6. `com/munserv/auth/api/AuthController.kt`: map `AuthResult.SupportGrantLoginSuccess` in
   `adminLogin` to the Contract shape above (`admin.role` = `grantedRole.uppercase()`,
   `admin.level` = `grantedLevel`, `admin.id` = `grantId`, `bootstrapStatus = null`). Add
   `@PostMapping("/logout")` returning `204`, reading the principal and authorities from
   `SecurityContextHolder` and delegating to `authService.logout(...)`; annotate it with
   `@Operation`/`@ApiResponses`/`@SecurityRequirement` like the other endpoints. Add
   `is AuthResult.SupportGrantLoginSuccess,` and `is AuthResult.LoggedOut,` to **all nine**
   exhaustive `when` branch lists that end in `throw IllegalStateException("Unexpected result type…")`
   — the build fails otherwise. Test: `src/test/kotlin/com/munserv/auth/api/AuthControllerTest.kt`
   `POST api-v1-auth-logout should return 204 for an authenticated admin token`.
7. `com/munserv/shared/config/SecurityConfig.kt`: add `.requestMatchers("/api/v1/auth/logout").authenticated()`
   next to the existing `change-password` matcher (before the `permitAll` default).
8. `com/munserv/shared/security/JwtAuthenticationFilter.kt`: when `validation.scope ==
   JwtService.SCOPE_SUPPORT_GRANT`, grant two authorities — `ROLE_<role.uppercase()>` and
   `ROLE_SUPPORT_GRANT` (add the literal as a companion constant). Test (new file)
   `src/test/kotlin/com/munserv/shared/security/JwtAuthenticationFilterTest.kt`
   `should add ROLE_SUPPORT_GRANT when the token carries the support grant scope` and
   `should not add ROLE_SUPPORT_GRANT for an ordinary admin token`.
9. `com/munserv/support/api/SupportGrantActivityFilter.kt`: change `SUPER_USER_AUTHORITY` to the
   `ROLE_SUPPORT_GRANT` authority (rename the constant) and rewrite the KDoc — the filter is no
   longer a no-op. Update `SupportGrantActivityFilterTest` to use the new authority.
10. `com/munserv/shared/security/RoleAuthorizationAspect.kt`: in `getCurrentAdminRole()`, when the
    authentication carries `ROLE_SUPPORT_GRANT`, resolve the role from
    `supportAccessService.currentGrant(SupportGrantId(uuid))` (`Granted` → `view.grant.grantedRole`,
    anything else → `null`, which denies) instead of the admin lookup. Inject the service with
    `@Lazy`, matching how `SecurityConfig` breaks the same cycle. Test:
    `src/test/kotlin/com/munserv/support/api/SupportAccessRoleAuthorizationTest.kt`
    `should return 403 on the pod chief grant endpoints for a grant-scoped token`.
11. `com/munserv/support/api/SupportGrantSelfController.kt` (new, no class-level `@RequireRole`):
    `@GetMapping("/api/v1/support-access/grants/current")` — reject callers without
    `ROLE_SUPPORT_GRANT` with `403 not_support_grant`, otherwise map `currentGrant(...)` through the
    existing `SupportGrantView.toResponse()`. Reuse `SupportAccessErrorResponse`. Test (new file)
    `src/test/kotlin/com/munserv/support/api/SupportGrantSelfControllerTest.kt`
    `should return the caller's own grant for a grant-scoped token` and
    `should return 403 for a pod chief token`.
12. Docs, one commit-worthy pass: `specs/contracts/api.md` — add `### POST /auth/admin/login` and
    `### POST /auth/logout` under `## Auth`, and `### GET /support-access/grants/current` under
    `## Support Access`, using the Contract section above verbatim; `specs/contracts/types.md` — add
    a `### SupportGrantLogin` subsection under `## SupportGrant` (`grantId`, `grantedRole`,
    `expiresAt`); `specs/features/pod-chief-bootstrap/implementation-plan.md` — delete the stale
    `| POST | /api/v1/support-access/login | Public | Super user login with grant |` row;
    `domain/support-grant.md` — state that the grant login mints a token scoped to `grantedRole`
    with the grant id as subject, and add the new code names (`SupportGrantSelfController`);
    `domain/bootstrap.md` — point 5 now names the shipped login path;
    `specs/requirements/backend.md` — set B9 to 🟢 Done.

## Do not
- Do not put `super_user` in the grant token's role claim, and do not add a second role claim. The
  token must not carry more than `grantedRole`; the web limit is a mirror of this, not the check.
- Do not add `POST /api/v1/support-access/login`. The grant login goes through the existing
  `/api/v1/auth/admin/login`, as `spec.md` says.
- Do not put the `current` endpoint on `SupportAccessController`: its class-level
  `@RequireRole(AdminRole.POD_CHIEF)` is enforced by `@within` and would deny the grant holder.
- Do not compute `supportGrant.expiresAt` from the token TTL. It is the grant's own `expiresAt`,
  server-owned and slid by `SupportGrantActivityFilter` (`domain/support-grant.md` invariants).
- Do not say "session": the domain term is **support grant**, and grant status is `status`, never `state`.
- Do not touch `web/` or `mobile/`; W29 (#44) consumes this and is a separate story.
- Do not add a new `AuditAction`; `SUPPORT_ACCESS_LOGIN` and `logSupportAccessLogin` already exist.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
