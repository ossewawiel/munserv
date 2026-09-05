---
issue: 43
story: W28
title: "Pod Chief grants super user temporary access"
platform: web
status: pending
depends_on: [49]        # B8 backend support grants, merged (PR #65)
touches:
  - web/src/features/support-access
  - web/src/features/pod-settings
  - web/src/locales
  - web/src/App.tsx
ui: true
design_canvas: "https://claude.ai/code/artifact/e74d590c-6be1-40e5-8864-88e5e85d52c9"
design_artboards: [Main.dc.html, SupportAccessActive.dc.html, SupportGrantsHistory.dc.html, GrantDialog.dc.html, GrantDialogError.dc.html, RevokeConfirm.dc.html]
design_approved: false
created_by: feature-planner
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# W28 · Pod Chief grants super user temporary access (Web)

Read `domain/README.md` and `domain/support-grant.md` for every term used below. This handoff is
complete on its own; do not read the feature spec or other stories' handoffs.

## Outcome
A pod chief opens Pod Settings, presses **Grant support access**, picks a role below `pod_chief`
and states a purpose, and the super user gets a one-hour support grant on the live pod.

## Acceptance criteria
- [ ] Located in Pod Settings > Support Access section
- [ ] Grant button opens dialog
- [ ] Select role to grant (from manageable roles)
- [ ] Set purpose/reason (required)
- [ ] Super user notified (optional)
- [ ] Access auto-revokes after logout OR 1 hour inactivity
- [ ] Action audit logged

AC 5 is explicitly optional and is **not** in scope: no notification endpoint exists. AC 6 and AC 7
are backend behaviour already shipped in B8; this story only has to display the expiry the backend
returns. Do not build a client-side revoke timer or an audit call.

## Contract
Already in `specs/contracts/api.md` (Support Access) and `specs/contracts/types.md` (SupportGrant).
Verified against `backend/src/main/kotlin/com/munserv/support/api/SupportAccessDto.kt`. No contract
changes needed.

`GET /support-access/grants` → `200 { "items": SupportGrant[], "total": number }`, optional
`?status=active|expired|revoked`.

`POST /support-access/grants` request:
```json
{ "grantedRole": "pod_admin", "purpose": "Investigate duplicate issue reports in sector 3" }
```
→ `201 SupportGrant`: `{ id, grantedRole, purpose, status, grantedBy, grantedByName, grantedAt,
expiresAt, lastActivity, revokedAt, expiredAt }` — the last three are `string | null`, timestamps
are ISO 8601, `status` is `active | expired | revoked`. Full field table in `types.md`.
Errors: `400 { messages: string[] }` | `403` not pod chief | `409 { code: "active_grant_exists", message }`.
`purpose` is 10-500 chars; `grantedRole` is an `AdminRole` wire value strictly below `pod_chief`.

## Steps

1. `web/src/features/support-access/types.ts`: add `SUPPORT_GRANT_STATUSES = ['active','expired','revoked'] as const`,
   `type SupportGrantStatus`, `interface SupportGrant` (fields exactly as the contract above, optional
   fields typed `string | null`), `interface SupportGrantListResponse { items: SupportGrant[]; total: number }`,
   `interface GrantSupportAccessRequest { grantedRole: AdminRole; purpose: string }`. Import `AdminRole`
   from `@/shared/types/admin`. No test file; the types are exercised by steps 3-5.
2. `web/src/features/support-access/api.ts`: `export const supportAccessApi` with
   `list: (status?: SupportGrantStatus) => apiClient.get<SupportGrantListResponse>('/support-access/grants', { params: status ? { status } : undefined }).then(r => r.data)`
   and `grant: (request: GrantSupportAccessRequest) => apiClient.post<SupportGrant>('/support-access/grants', request).then(r => r.data)`.
   Follow `web/src/features/admin-management/api.ts` exactly. Do not add `revoke` — that is W30.
3. `web/src/features/support-access/hooks.ts`: `useSupportGrants(status?)` with query key
   `['support-grants', status ?? 'all']`, and `useGrantSupportAccess()` mutation invalidating
   `['support-grants']` in `onSuccess`. Test: `web/src/features/support-access/hooks.test.tsx`
   (MSW, wrapper pattern from `web/src/features/admin-management/hooks.test.tsx`) —
   `should return grants when the list endpoint resolves`, `should expose the conflict body when granting returns 409`.
4. `web/src/test/mocks/handlers.ts`: add `mockSupportGrants` plus `GET` and `POST` handlers for
   `*/support-access/grants`, in the style of the existing admin handlers. Export the mock array.
5. `web/src/features/support-access/components/GrantAccessDialog.tsx`: controlled dialog
   (`open`, `onClose`, `onSubmit`, `isLoading`, `errorCode?`). MUI `Select` of roles from
   `getManageableRoles('pod_chief')` labelled with `t(\`roles.${role}\`)`, multiline `purpose`
   `TextField` with a character counter, inline validation (`purposeRequired` when empty,
   `purposeTooShort` under 10, `purposeTooLong` over 500), an `Alert` explaining the one-hour idle
   expiry, and an `Alert severity="warning"` when `errorCode === 'active_grant_exists'`. Test:
   `GrantAccessDialog.test.tsx` — `should block submit when purpose is shorter than 10 characters`,
   `should submit the selected role and purpose when the form is valid`,
   `should show the conflict warning when an active grant already exists`.
6. `web/src/features/support-access/SupportAccessSection.tsx`: a `MainCard` titled
   `t('supportAccess.title')` that calls `useSupportGrants()`, shows a `Spinner` while loading, an
   `ErrorState` on failure, a callout naming the active grant's role, purpose and `expiresAt`
   (formatted with `toLocaleString`) when one exists, an `EmptyState` when none does, and a
   **Grant support access** `Button` that opens `GrantAccessDialog` and is disabled while an active
   grant exists. Pass the mutation's 409 `code` down as `errorCode`. Test:
   `SupportAccessSection.test.tsx` — `should disable the grant button when an active grant exists`,
   `should render the expiry of the active grant`.
7. `web/src/features/pod-settings/PodSettingsPage.tsx`: new page using `DashboardLayout`,
   `Breadcrumbs` and `PageHeader` (copy the shape of `web/src/features/sector-settings/SectorSettingsPage.tsx`),
   rendering `<SupportAccessSection />`. Titles from `t('podSettings.title')` / `t('podSettings.subtitle')`.
8. `web/src/App.tsx`: replace `<PlaceholderPage title="Pod Settings" />` on route `/settings/pod`
   with `<PodSettingsPage />`, keeping the existing `ProtectedRoute` + `RoleGuard requiredRole="pod_chief"`
   wrappers and adding the import alongside the other feature imports.
9. `web/src/locales/{en,af,zu}/translation.json`: add a `supportAccess` block (`title`, `subtitle`,
   `grantButton`, `activeGrant`, `noActiveGrant`, `expiresAt`, `grantedBy`, `purpose`, `role`,
   `dialog.title`, `dialog.roleLabel`, `dialog.purposeLabel`, `dialog.purposeHelp`,
   `dialog.expiryNotice`, `dialog.submit`, `errors.purposeRequired`, `errors.purposeTooShort`,
   `errors.purposeTooLong`, `errors.activeGrantExists`, `errors.loadFailed`) and a `podSettings`
   block (`title`, `subtitle`). All three locales get real translations, not English copies; reuse
   the existing `roles.*` keys for role names. Test: `web/src/lib/i18n.test.ts` already asserts key
   parity across locales — keep it green.

## Do not
- Do not add a revoke button, an active/history table or a revoke dialog: that is W30 in the same
  folder, and the two stories must not collide.
- Do not touch backend, mobile, `AuthService`, `useAuth` or `App.tsx` routes other than `/settings/pod`.
- Do not say "session", "impersonation" or "elevation" in code, keys or copy: the term is
  **support grant** (record) or **support access** (capability). See `domain/support-grant.md`.
- Do not hardcode the one-hour window as a client-side countdown; render the server's `expiresAt`.
- Do not send a notification to the super user; no endpoint exists.
- Do not build a hand-rolled table, use `useEffect` for fetching, or write literal colours.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
