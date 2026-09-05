---
issue: 45
story: W30
title: "Pod Chief views and revokes support grants"
platform: web
status: pending
depends_on: [43]        # W28 creates features/support-access (types, api, hooks, section)
touches:
  - web/src/features/support-access
  - web/src/locales
ui: true
design_canvas: "https://claude.ai/code/artifact/e74d590c-6be1-40e5-8864-88e5e85d52c9"
design_artboards: [Main.dc.html, SupportAccessActive.dc.html, SupportGrantsHistory.dc.html, GrantDialog.dc.html, GrantDialogError.dc.html, RevokeConfirm.dc.html]
design_approved: false
created_by: feature-planner
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# W30 · Pod Chief views and revokes support grants (Web)

Read `domain/README.md` and `domain/support-grant.md` for every term used below. This handoff is
complete on its own; do not read the feature spec or other stories' handoffs.

## Outcome
In Pod Settings > Support Access a pod chief sees the active support grant with its role, grant
time and last activity, sees the history of past grants, and can revoke the active one after
confirming.

## Acceptance criteria
- [ ] Located in Pod Settings > Support Access section
- [ ] Shows active sessions: role, granted time, last activity
- [ ] Manual revoke button per session
- [ ] Session history log (past grants)
- [ ] Confirmation dialog before revoke

The issue says "session". The domain term is **support grant**; use it in code, i18n keys and
user-visible copy. See `domain/support-grant.md` "Say / do not say".

## Contract
Already in `specs/contracts/api.md` (Support Access) and `specs/contracts/types.md` (SupportGrant).
Verified against `backend/src/main/kotlin/com/munserv/support/api/SupportAccessDto.kt`. No contract
changes needed.

`DELETE /support-access/grants/{id}` → `204` No Content.
Errors: `401` | `403` not pod chief or another pod's grant | `404` not found |
`409 { code: "grant_not_active", message: string }`.

`GET /support-access/grants` returns every grant for the pod, newest first, each carrying
`status` (`active` | `expired` | `revoked`), `grantedRole`, `purpose`, `grantedByName`,
`grantedAt`, `expiresAt`, `lastActivity`, `revokedAt`, `expiredAt`. Filter locally by `status`;
do not issue two requests.

W28 has already added `web/src/features/support-access/{types,api,hooks}.ts` and
`SupportAccessSection.tsx`. Extend those files, do not recreate them.

## Steps

1. `web/src/features/support-access/api.ts`: add
   `revoke: (id: string) => apiClient.delete(\`/support-access/grants/${id}\`).then(r => r.data)`
   next to the existing `list` and `grant`.
2. `web/src/features/support-access/hooks.ts`: add `useRevokeSupportGrant()` — `useMutation` calling
   `supportAccessApi.revoke`, invalidating `['support-grants']` in `onSuccess`. Test: extend
   `web/src/features/support-access/hooks.test.tsx` — `should invalidate the grants list after a revoke`
   and `should surface grant_not_active when the revoke conflicts`.
3. `web/src/test/mocks/handlers.ts`: add a `DELETE */support-access/grants/:id` handler returning
   `new HttpResponse(null, { status: 204 })`, next to the handlers W28 added.
4. `web/src/features/support-access/components/RevokeGrantDialog.tsx`: wrap
   `@/components/molecules/ConfirmDialog` with `variant="warning"`, props
   `{ open, grant: SupportGrant | null, onClose, onConfirm, isLoading }`. Body names the granted
   role (`t(\`roles.${grant.grantedRole}\`)`), the purpose and that revocation is immediate and
   final. Test: `RevokeGrantDialog.test.tsx` — `should name the granted role in the confirmation`,
   `should call onConfirm when the pod chief confirms`.
5. `web/src/features/support-access/components/SupportGrantsTable.tsx`: one component driven by a
   `variant: 'active' | 'history'` prop, rendering `@/components/organisms/DataTableCard` with
   `Column<SupportGrant>[]`. Active columns: role, purpose, granted by, granted at, last activity
   (`t('supportAccess.table.never')` when `lastActivity` is null), expires at, actions (an
   `ActionIconButton` that calls `onRevoke(grant)`). History columns: role, purpose, granted by,
   granted at, status badge, ended at (`revokedAt ?? expiredAt ?? '-'`), and no actions column.
   Format timestamps with `toLocaleString()`; use `@/components/molecules/EmptyState` copy through
   `DataTableCard`'s empty message. Test: `SupportGrantsTable.test.tsx` —
   `should render the last activity placeholder when the grant has no activity yet`,
   `should not render a revoke action in the history variant`,
   `should call onRevoke with the grant when the revoke action is pressed`.
6. `web/src/features/support-access/SupportAccessSection.tsx`: keep the existing grant button and
   active-grant callout from W28; below them add `DataTableCard` tabs
   (`active` badge = count of active grants, `history` badge = count of the rest) rendering
   `SupportGrantsTable` for each, wire `RevokeGrantDialog` state (`grantToRevoke`), and call
   `useRevokeSupportGrant()` on confirm, closing the dialog in `onSuccess` and showing
   `t('supportAccess.errors.grantNotActive')` in an `Alert` when the mutation returns
   `code === 'grant_not_active'`. Test: extend `SupportAccessSection.test.tsx` —
   `should open the confirmation dialog before revoking`,
   `should show the past grants in the history tab`.
7. `web/src/locales/{en,af,zu}/translation.json`: extend the `supportAccess` block from W28 with
   `tabs.active`, `tabs.history`, `table.role`, `table.purpose`, `table.grantedBy`,
   `table.grantedAt`, `table.lastActivity`, `table.expiresAt`, `table.status`, `table.endedAt`,
   `table.actions`, `table.never`, `table.emptyActive`, `table.emptyHistory`, `revoke`,
   `revokeDialog.title`, `revokeDialog.body`, `revokeDialog.warning`, `revokeDialog.confirm`,
   `status.active`, `status.expired`, `status.revoked`, `errors.grantNotActive`,
   `errors.revokeFailed`. All three locales get real translations, not English copies. Test:
   `web/src/lib/i18n.test.ts` already asserts key parity across locales — keep it green.

## Do not
- Do not re-create `types.ts`, `api.ts`, `hooks.ts` or `SupportAccessSection.tsx`: W28 owns their
  first version and this story only extends them. If they are missing, W28 has not merged — stop.
- Do not say "session", "impersonation" or "revoke access token": the term is **support grant**.
- Do not poll the list on a timer or add websockets; invalidate on mutation and let the pod chief
  reload. "Real-time status updates" in the issue's notes is not an acceptance criterion.
- Do not add optimistic removal of the revoked row without an `onError` rollback; simplest correct
  option is to invalidate and refetch.
- Do not touch backend, mobile, `App.tsx` or `useAuth`.
- Do not hand-roll a table, use `useEffect` for fetching, or write literal colours.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
