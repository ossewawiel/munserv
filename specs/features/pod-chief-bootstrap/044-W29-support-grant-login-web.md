---
issue: 44
story: W29
title: "Super user uses temporary access for debugging"
platform: web
status: pending
depends_on: [68]        # B9 grant login + GET /support-access/grants/current, merged in PR #73
touches:
  - web/src/features/auth
  - web/src/shared/hooks
  - web/src/components/organisms
  - web/src/components/templates
  - web/src/test/mocks
  - web/src/locales
ui: true
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# W29 · Super user uses temporary access for debugging (Web)

Read `domain/README.md` and `domain/support-grant.md` for every term used below. This handoff is
complete on its own; do not read the feature spec or other stories' handoffs.

## Outcome
The super user logs in to a live pod while a support grant is active, works under the granted role
only, sees the remaining grant time in the header, and lands back on the login page when the grant
ends.

## Acceptance criteria
- [ ] Login works when temporary grant is active
- [ ] Role-limited access based on granted role
- [ ] Session shows expiry timer in header
- [ ] Auto-logout when grant expires
- [ ] All actions audit logged
- [ ] Activity extends session (up to max 1 hour from last activity)

AC5 is backend behaviour shipped in B9 (`SUPPORT_ACCESS_LOGIN`, revoke and expiry audit entries):
the web writes no audit call. AC2 also falls out of B9 — the login response already carries the
**granted** role as `profile.admin.role` — but you must prove it with a test.

## Visual (ui stories only)
Match artboard: to be produced by the designer under `design/canvases/support-access/`. Expect one
artboard for the header banner with time remaining and one for the last-minutes (warning) state;
the designer fills the exact file names into `design_artboards` before this story is dispatched.

## Contract
Shipped by B9. No contract changes; do not edit `specs/contracts/`.

`POST /auth/admin/login` (`specs/contracts/api.md`) — when the credentials are the super user's and
the pod has an active grant, `profile.admin.role` is the **granted** role (never `super_user`) and
`profile.supportGrant` carries the grant:
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
`supportGrant` is `null` for every other login. `admin.role` is the uppercase wire role;
`supportGrant.grantedRole` is the snake_case `AdminRole`. `tokens.expiresAt` is the access token
expiry, `supportGrant.expiresAt` is the grant's own, server-owned, sliding expiry.
`SupportGrantInfo` (`types.md`): `grantId`, `grantedRole`, `expiresAt`.

`GET /support-access/grants/current` — grant-scoped tokens only; returns the caller's own grant so
the client can refresh a slid `expiresAt`. **Response** `200 SupportGrant` (this story consumes
only `expiresAt`). **Errors:** `401` not authenticated | `403` not a support grant token
(`{ code: "not_support_grant", message }`), **or the grant is revoked or expired, with an empty
body**. There is no 404 and no 409.

`POST /auth/logout` → `204`, and revokes the grant when the token is grant-scoped. The existing
`authApi.logout()` already calls it; no change needed.

## Steps

1. `web/src/features/auth/types.ts`: add `export interface SupportGrantInfo { grantId: string; grantedRole: AdminRole; expiresAt: string }`
   (import `AdminRole` from `@/shared/types/admin`), add `supportGrant?: SupportGrantInfo | null` to
   `AdminProfile`, and add `export interface CurrentSupportGrantResponse { expiresAt: string }` with
   a comment that the endpoint returns the full grant and only `expiresAt` is consumed here. No test;
   steps 2-6 exercise it.
2. `web/src/features/auth/api.ts`: add
   `getCurrentSupportGrant: () => apiClient.get<CurrentSupportGrantResponse>('/support-access/grants/current').then((r) => r.data)`.
   Test: `web/src/features/auth/api.test.ts` — `should return the slid expiry from the current grant endpoint`.
3. `web/src/features/auth/hooks.ts`: in `useLogin.onSuccess` store `response.profile.supportGrant`
   under a new `SUPPORT_GRANT_KEY = 'supportGrant'` when it is non-null and `removeItem` otherwise;
   `removeItem` it in `useLogout.onSuccess` too. Add
   `useCurrentSupportGrant(options: { pathname: string; expired: boolean; enabled: boolean })`:
   `useQuery` with key `['auth', 'support-grant', 'current', options.pathname, options.expired]`,
   `queryFn: authApi.getCurrentSupportGrant`, `enabled: options.enabled`, `retry: false`,
   `refetchOnWindowFocus: false`, `gcTime: 0`. Test: `web/src/features/auth/hooks.test.tsx` —
   `should store the support grant when the login response carries one`,
   `should clear the stored support grant on logout`,
   `should not request the current grant when there is no support grant`.
4. `web/src/features/auth/LoginPage.test.tsx`: add
   `should redirect to the dashboard when the super user logs in under a support grant` — an MSW
   login response with `profile.admin.role: 'POD_ADMIN'` and a `supportGrant` must land on `/`, not
   on `/bootstrap/create-pod-chief`. No source change: `getRedirectPath` already keys off
   `admin.role`.
5. `web/src/shared/hooks/useAuth.ts`: read `supportGrant` from localStorage in a `useCallback`
   mirroring `getStoredAdmin` (JSON.parse in try/catch, `null` on failure), expose it as
   `supportGrant: SupportGrantInfo | null`, and `removeItem` it inside `logout()`. Leave
   `hasPermission` exactly as it is — under a grant `admin.role` is already the granted role, so the
   hierarchy branch does the limiting. Test: new `web/src/shared/hooks/useAuth.test.ts` —
   `should expose the stored support grant`,
   `should limit permissions to the granted role under a support grant` (stored role `POD_ADMIN`:
   `hasPermission('pod_chief')` false, `hasPermission('ward_admin')` true),
   `should clear the support grant on logout`.
6. `web/src/components/organisms/SupportGrantBanner.tsx` (new): returns `null` when
   `useAuth().supportGrant` is null. One `useEffect` holding a 1s `setInterval` that stores
   `Date.now()` in state; `expiresAt = data?.expiresAt ?? supportGrant.expiresAt`;
   `remainingMs = Math.max(0, Date.parse(expiresAt) - now)`. Call
   `useCurrentSupportGrant({ pathname: useLocation().pathname, expired: remainingMs === 0, enabled: true })`
   so the expiry refreshes on every route change (real activity) and exactly once when the countdown
   reaches zero. Render an MUI `Chip` (or `Alert`) with `t('supportGrant.banner', { role: t(\`roles.${supportGrant.grantedRole}\`), remaining })`
   where `remaining` is `mm:ss` under an hour, `color="warning"` under 5 minutes, and
   `t('supportGrant.expired')` at zero. Styling through `sx` and theme tokens only. Test:
   `web/src/components/organisms/SupportGrantBanner.test.tsx` with `vi.useFakeTimers()` —
   `should render nothing when there is no support grant`,
   `should count down to the server expiry`,
   `should show the slid expiry after a route change`.
7. `web/src/components/templates/DashboardLayout.tsx`: render `<SupportGrantBanner />` in the header
   `Toolbar` immediately before `<NotificationDropdown />`. Test: `DashboardLayout.test.tsx` —
   `should show the support grant banner when a grant is stored` (and the existing cases stay green).
8. `web/src/test/mocks/handlers.ts`: add `mockCurrentSupportGrant` (a full `SupportGrant` body with
   `expiresAt` one hour ahead) and `http.get('*/support-access/grants/current', …)` returning it, in
   the style of the neighbouring handlers.
9. `web/src/locales/{en,af,zu}/translation.json`: add a `supportGrant` block — `banner`
   (`"Support access as {{role}} · {{remaining}} left"`), `remainingLabel`, `expired`. Real
   Afrikaans and isiZulu translations, not English copies; reuse the existing `roles.*` keys for the
   role name.

## Do not
- Do not poll `GET /support-access/grants/current` on a timer or with `refetchInterval`. The backend
  `SupportGrantActivityFilter` counts **every** authenticated request as activity, so a poll would
  slide `expires_at` forever and the one-idle-hour invariant in `domain/support-grant.md` would
  never fire. Refresh only on route change and once at zero.
- Do not call the endpoint when no `supportGrant` is stored. For a normal admin it answers `403`,
  and `web/src/lib/api-client.ts` turns any 403 into `authEvents.emit('session-expired')`, which
  would log a legitimate admin out.
- Do not write your own auto-logout redirect. A revoked or expired grant answers `403` with an empty
  body, and the existing interceptor plus `SessionExpiredHandler` already clear storage and route to
  `/login`; that is AC4.
- Do not invent a client-side one-hour countdown from login time, and do not treat
  `tokens.expiresAt` as the grant expiry.
- Do not relax or special-case `hasPermission`, and do not set the `isSuperUser` flag for a grant
  login — the bootstrap pages must stay closed.
- Do not touch or import from `web/src/features/support-access/` or `web/src/features/pod-settings/`:
  W28 (#43) and W30 (#45) own them.
- Do not say "session", "impersonation" or "elevation" in code, keys or copy: the terms are
  **support grant** (the record) and **support access** (the capability).
- Do not touch backend, mobile or `specs/contracts/`; do not add an audit call from the web.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
