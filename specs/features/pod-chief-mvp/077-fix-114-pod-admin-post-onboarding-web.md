---
issue: 114
story: FIX114
title: "A pod admin is logged out right after onboarding because the dashboard call returns 403"
platform: web
status: completed
depends_on: []
touches:
  - web/src/lib/api-client.ts
  - web/src/features/dashboard
  - web/src/features/pod-chief/hooks.ts
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: orchestrator
created_at: "2026-09-06"
files_changed:
  - web/src/lib/api-client.ts
  - web/src/lib/api-client.test.ts
  - web/src/features/pod-chief/hooks.ts
  - web/src/features/dashboard/DashboardPage.tsx
  - web/src/features/dashboard/DashboardPage.test.tsx
  - web/src/features/pod-chief/WardDashboardPage.tsx
  - web/src/features/pod-chief/SectorDashboardPage.tsx
  - web/src/components/organisms/SessionExpiredHandler.test.tsx
  - web/src/locales/en/translation.json
  - web/src/locales/af/translation.json
  - web/src/locales/zu/translation.json
tests_added:
  - "web/src/lib/api-client.test.ts: should not end the session on a 403 without a support grant"
  - "web/src/lib/api-client.test.ts: should end the session on a 403 under a support grant"
  - "web/src/lib/api-client.test.ts: should end the session on a 401"
  - "web/src/features/dashboard/DashboardPage.test.tsx: should not request the pod dashboard for a pod admin"
  - "web/src/components/organisms/SessionExpiredHandler.test.tsx: should not display session expired message without a support grant (#114)"
  - "web/src/components/organisms/SessionExpiredHandler.test.tsx: should display session expired message and redirect under a support grant"
---

# FIX114 · Pod admin is logged out right after onboarding (Web)

Read `domain/README.md` and `domain/admin-role.md` for the role hierarchy. Found by eyeball testing of #100; the backend is correct.

## Outcome
A pod admin who finishes onboarding lands on a page they may see and stays signed in; a single 403 no longer ends a session unless the user is under a support grant.

## Acceptance criteria
- [x] After "Skip for Now" (or completing the profile) a pod admin lands on `/` and stays logged in; no `session-expired` event fires.
- [x] `GET /pod/dashboard` is only requested for users with `pod_chief` permission (`hasPermission('pod_chief')`).
- [x] A 403 on any request logs the user out only when a support grant is stored in localStorage (W29 auto-logout keeps working); otherwise the promise rejects and the caller shows its own error.
- [x] A 401 still logs the user out as today.
- [ ] `/messages` opens for the new pod admin and shows the welcome message (B10, #100) — not verified against the real backend in this session (unit tests pass; step 4 manual/console check was skipped per instructions).

## Visual
None.

## Contract
`GET /pod/dashboard` is `@RequireRole(POD_CHIEF)` (`PodDashboardController.kt:39`) and answers 403 for every other role. `GET /support-access/grants/current` answers 403 with an empty body when a grant is revoked or expired (`specs/contracts/api.md`). No contract change.

## Steps
1. `web/src/lib/api-client.ts`: in the response interceptor, keep the 401 branch unchanged. For 403, emit `session-expired` (and clear storage) only when `localStorage.getItem('supportGrant')` is set; otherwise just reject. Test: `web/src/lib/api-client.test.ts` `should not end the session on a 403 without a support grant` and `should end the session on a 403 under a support grant`.
2. `web/src/features/pod-chief/hooks.ts` `usePodDashboard`: accept `{ enabled }` and pass it to `useQuery`. `web/src/features/dashboard/DashboardPage.tsx`: call it with `enabled: hasPermission('pod_chief') && podSetup.isPodLevel && podSetup.isSetupComplete` (use `useAuth`). Test: `DashboardPage.test.tsx` `should not request the pod dashboard for a pod admin` (assert with an MSW request counter).
3. Check the other pod-level dashboards (`WardDashboardPage`, `SectorDashboardPage`) do not issue pod-chief-only requests for lower roles; guard the same way if they do.
4. Run the flow from the issue against the real backend (`./dashboard.sh`, PR checkout of your branch): create a pod admin as the pod chief, log in, set a password, Skip for Now, open `/messages`. Note the result in the PR body.

## Do not
- Do not change `SupportGrantBanner`, `useAuth.hasPermission` or the role hierarchy.
- Do not add a role-specific landing route; `/` is correct once the pod-chief-only request is gated.
- Do not touch backend or mobile.

## Done when
```bash
cd web && pnpm lint && pnpm typecheck && pnpm exec vitest run --maxWorkers=2
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: New pod admin lands on the dashboard and can open Messages
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - Click "Add administrator", create a Pod Admin, copy the temporary password.
    - Log out, log in as the new admin, set a new password, press "Skip for Now".
    - Open http://localhost:3000/messages.
  expect: The admin stays signed in on the dashboard and the Messages page shows the welcome message.
- id: E2
  title: A revoked support grant still logs the support user out
  as: super_user
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - As the pod chief grant support access, log in as the super user under the grant, then revoke the grant as the pod chief in another browser.
    - Navigate to any page as the support user.
  expect: The support user is returned to the login page with the session-expired message.
```
