---
issue: 44
story: W29
title: "Super user uses temporary access for debugging"
platform: web
status: blocked
depends_on: [43]        # W28 creates features/support-access; plus an unwritten backend story (see Contract)
touches:
  - web/src/features/support-access
  - web/src/features/auth
  - web/src/shared/hooks
  - web/src/locales
created_by: feature-planner
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# W29 · Super user uses temporary access for debugging (Web)

**BLOCKED on backend. Do not start implementation.** The backend cannot log the super user in
under a support grant, and returns nothing the web can build an expiry timer or a role limit from.
Read the Contract section, then hand this back to the feature planner to raise the backend story.

## Outcome
The super user logs in to a bootstrapped pod while a support grant is active, works under the
granted role only, sees the remaining time in the header, and is logged out when the grant ends.

## Acceptance criteria
- [ ] Login works when temporary grant is active
- [ ] Role-limited access based on granted role
- [ ] Session shows expiry timer in header
- [ ] Auto-logout when grant expires
- [ ] All actions audit logged
- [ ] Activity extends session (up to max 1 hour from last activity)

## Contract
`specs/contracts/api.md` covers only the three pod-chief grant endpoints. There is **no contract
and no implementation** for a grant login. Verified on master:

1. **Grant login does not exist.** `backend/src/main/kotlin/com/munserv/auth/service/AuthService.kt`
   `handleSuperUserLogin(podId)` consults only `bootstrapService.getStatus(podId)` and returns
   `AuthResult.InvalidCredentials` for `BootstrapStatus.NotEligible`. No `SupportGrant` lookup
   exists anywhere in `com.munserv.auth`, so on a bootstrapped pod the super user is refused even
   with an `active` grant. AC1 is unimplementable.
2. **The token is not grant-scoped.** `AuthService` mints
   `jwtService.generateTokenPair(MemberId(UUID.randomUUID()), SUPER_USER_ROLE)` — a random subject.
   `support/api/SupportGrantActivityFilter.kt` reads the JWT subject as a `SupportGrantId`, and its
   own KDoc says: "Until then this filter is effectively a no-op, since no such token is ever
   minted." AC6 (activity slides the window) therefore never fires.
3. **The login response carries no grant data.** `AuthResult.SuperUserLoginSuccess(tokens, podId,
   bootstrapStatus)` and the `AdminLoginResponse` built in `auth/api/AuthController.kt` hardcode
   `id = "super-user"`, `role = "SUPER_USER"`, `level = "system"`, and expose no `grantId`,
   `grantedRole` or grant `expiresAt`. The header timer (AC3) and auto-logout (AC4) have no
   timestamp to count to; inventing a client-side one-hour clock would contradict
   `domain/support-grant.md`, where `expires_at` is server-owned and slides with activity.
4. **No granted role reaches the client.** The JWT role is `super_user`, and
   `web/src/shared/hooks/useAuth.ts` `hasPermission` returns `true` for every role when
   `admin.role === SUPER_USER_ROLE`. Without `grantedRole` in the response the UI cannot be limited
   to what the pod chief granted. AC2 is unimplementable.
5. **Logout does not end the grant.** `SupportAccessService.revokeOnLogout(id)` exists
   (`support/service/SupportAccessService.kt:148`) but has no caller and there is no logout endpoint
   in the backend at all. The `active` → `revoked` on logout transition in
   `domain/support-grant.md` has no trigger.
6. **No self-read endpoint.** The three grant endpoints are `@RequireRole(AdminRole.POD_CHIEF)`
   (`support/api/SupportAccessController.kt`), so a super user cannot re-read its own grant to
   refresh the expiry after activity slid the window.

### Backend story this needs
A new backend story (suggest **B9**, milestone `pod-chief-bootstrap`) that:
- extends `handleSuperUserLogin` to fall back to `SupportGrantRepository.findActiveByPod(podId)`
  when the pod is `NotEligible`, and writes the `SUPPORT_ACCESS_LOGIN` audit entry already named in
  `domain/support-grant.md`;
- mints the token with the `SupportGrantId` as subject so `SupportGrantActivityFilter` starts
  recording activity;
- adds `grantId`, `grantedRole` and `expiresAt` to `AuthResult.SuperUserLoginSuccess` and to the
  admin login response, and documents them in `specs/contracts/api.md`;
- adds `GET /api/v1/support-access/grants/current` for the super user to re-read its own grant
  (role `super_user`, returns the caller's `SupportGrant`);
- adds a logout route that calls `revokeOnLogout(grantId)`;
- decides how the granted role is enforced server-side, so the web limit is a mirror of the API
  rather than the only check.

Once that story is merged, rewrite this handoff's Contract from the shipped shapes and set
`status: pending`.

## Steps
None. The story is blocked; no web file may be written against an invented contract.

For the planner's sizing only, the web work after B9 is roughly: extend `AdminUser`/`useAuth` with
`grantId`, `grantedRole` and `grantExpiresAt`; a `SupportGrantBanner` in `DashboardLayout` showing
the remaining time from the server `expiresAt`; refresh from `GET /support-access/grants/current`
after mutations; logout and redirect when the grant ends; make `hasPermission` use `grantedRole`
instead of returning `true` for `super_user`; i18n keys in `en`, `af` and `zu`. That is more than
one story's worth and should be split when it is unblocked.

## Do not
- Do not implement a client-side one-hour countdown from login time. `expires_at` is server-owned
  and slides with activity (`domain/support-grant.md` invariants).
- Do not relax `useAuth.hasPermission` guesswork by mapping `super_user` to a hardcoded role.
- Do not add a `/api/v1/support-access/login` endpoint from the web side, and ignore the stale line
  proposing one in `specs/features/pod-chief-bootstrap/implementation-plan.md` Phase 4.
- Do not say "session": the domain term is **support grant**. The header element is a support grant
  banner, not a session timer.
- Do not start W29 before W28 (#43) has merged; both own `web/src/features/support-access`.

## Done when
Blocked. There is nothing to run. Leave `status: blocked` and end your message with
`BLOCKED: backend cannot log the super user in under a support grant (no grant lookup in AuthService, no grant-scoped token, no grantedRole/expiresAt in the login response, no logout revoke); needs backend story B9.`
