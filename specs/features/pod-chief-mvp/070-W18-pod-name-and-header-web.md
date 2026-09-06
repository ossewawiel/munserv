---
issue: 29
story: W18
title: "Pod name and logo configuration"
platform: web
status: pending
depends_on: []
touches:
  - web/src/features/pod-settings
  - web/src/components/templates
  - web/src/test/mocks
  - web/src/locales
ui: true
design_canvas: "https://claude.ai/code/artifact/1f658255-0e88-48ac-ab86-1be239115d50"
design_artboards:
  - Main.dc.html
  - IdentityNoLogo.dc.html
  - IdentitySaving.dc.html
  - IdentityInvalidName.dc.html
  - IdentityServerError.dc.html
  - IdentitySaved.dc.html
  - HeaderStates.dc.html
design_approved: true
created_by: feature-planner
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# W18 · Pod name and header branding (Web)

Read `domain/README.md` and `domain/pod.md` for every term used below. This handoff is complete on
its own; do not read the feature spec or other stories' handoffs.

## Outcome
A pod chief renames the pod from Pod Settings and the portal header immediately reads
"Munserv Pod {name}" beside the Munserv mark, with the pod's logo when one is configured.

## Acceptance criteria
- [ ] Set pod name
- [ ] Name appears in header as "Munserv Pod [name]"
- [ ] Upload logo
- [ ] Munserv icon shows in orange on background

**AC3 is out of scope for this story.** There is no logo file-upload endpoint (see Contract), so
this story renders the logo from `logoUrl` and lets the pod chief clear or set that URL. File upload
needs a backend story and a separate web story; #29 should be split. Do not build a multipart
uploader, a base64 field or a client-side file picker that posts anywhere.

## Visual (ui stories only)
Two screens change. **Match the approved artboards**, working files under
`design/canvases/pod-chief-mvp/pod-settings/`: `Main` (identity card, logo set), `IdentityNoLogo`,
`IdentitySaving`, `IdentityInvalidName`, `IdentityServerError`, `IdentitySaved` and `HeaderStates`
(the three header branches). **The artboards outrank the words here**, including where they depart
from this handoff — read the canvas notes `header-lockup`, `form-controls` and `assets` before
building. Three things they settle:

- The Munserv mark is an image, not a tinted icon: cut the left 93x93 square of
  `web/public/assets/app-logo.png` and commit it as `web/public/assets/app-mark.png`. Its orange is
  the artwork's own `#D9613F`, already the `brand.secondary` token, so no colour is hardcoded and
  none is invented. Do not recolour it with `secondary.main`.
- The `displayName` preview inside the card is bound to `usePodSettings`, so it shows the SAVED
  value and only changes after a successful save. That is what keeps the client from composing
  `"Munserv Pod " + name`.
- Do not use `Button` `isLoading` for the save: the atom swallows the label into a hardcoded English
  `'Loading...'`. Use `disabled` plus `startIcon={<CircularProgress size={16} />}` and keep the
  label, as `IdentitySaving` draws it.

`PodIdentitySection` is a **new feature component**, not a registry component: it lives under
`features/pod-settings/components/` and needs no `design/registry/web.md` row.

The canvas was revised after this story was written (W18c, #128 and #129): `IdentitySaved` now draws
the confirmation as a bottom-centre snackbar and every identity artboard carries a Reset button
beside Save. **Both belong to W18c, not to this story.** Build the inline success `Alert` and the
single Save button exactly as this handoff describes; W18c replaces the alert and adds Reset. Ignore
the canvas' `feedback` note and its `IdentityDirty` artboard here.

## Contract
`specs/contracts/api.md` § Pod. Both endpoints require role `pod_chief`.

`GET /pod/settings` → `200`
```json
{ "name": "Ward42", "displayName": "Munserv Pod Ward42", "logoUrl": "https://example.com/logo.png" }
```
`displayName` is server-derived as `"Munserv Pod {name}"`; render it, never build the string in the
client. `logoUrl` is `null` when unset.

`PATCH /pod/settings` request `{ "name"?: string, "logoUrl"?: string }` — `name` 2-100 chars,
`logoUrl` max 500 chars — response `200` with the same body and `displayName` recomputed.
**Errors:** `400` `{ "code": "validation_error", "message": string }` | `401` | `403` | `404`.

There is no logo upload endpoint. Proposed backend story to open for AC3 — **B11, "Pod logo
upload"**: `POST /pod/logo`, `multipart/form-data`, returns `{ "logoUrl": string }`.

## Steps

1. `web/src/features/pod-settings/types.ts` (new): `export interface PodSettings { name: string;
   displayName: string; logoUrl: string | null }` and
   `export interface UpdatePodSettingsRequest { name?: string; logoUrl?: string }`. No test.
2. `web/src/features/pod-settings/api.ts` (new): `podSettingsApi` with
   `getSettings: () => apiClient.get<PodSettings>('/pod/settings').then((r) => r.data)` and
   `updateSettings: (request: UpdatePodSettingsRequest) => apiClient.patch<PodSettings>('/pod/settings', request).then((r) => r.data)`.
   Test: `web/src/features/pod-settings/api.test.ts` — `should return the pod settings`,
   `should send only the changed fields when updating`.
3. `web/src/features/pod-settings/hooks.ts` (new): `podSettingsKeys = { all: ['pod','settings'] as const }`;
   `usePodSettings(options?: { enabled?: boolean })` → `useQuery` with that key, `retry: false`,
   `enabled: options?.enabled ?? true`; `useUpdatePodSettings()` → `useMutation` that on success
   calls `queryClient.setQueryData(podSettingsKeys.all, response)`. Test:
   `web/src/features/pod-settings/hooks.test.tsx` — `should load the pod settings`,
   `should not fetch when disabled`, `should replace the cached settings after an update`.
4. `web/src/features/pod-settings/components/PodIdentitySection.tsx` (new): a `MainCard` titled
   `t('podSettings.identity.title')` holding the `Input` atom for the pod name (prefilled from
   `usePodSettings`), a read-only preview of `displayName`, an `Input` for `logoUrl`, the logo
   rendered as a `Box component="img"` when `logoUrl` is set, and the `Button` atom to save. Block
   the save and show `helperText` when the trimmed name is shorter than 2 or longer than 100
   characters; surface a server `400` through `ErrorState`-style copy from `error.response.data.message`
   (guard with `AxiosError`, no `any`). Use `Spinner` while loading. Test:
   `PodIdentitySection.test.tsx` — `should prefill the form with the current pod name`,
   `should reject a name shorter than two characters`,
   `should send the new name when saved`, `should show the server validation message on 400`.
5. `web/src/features/pod-settings/PodSettingsPage.tsx`: render `<PodIdentitySection />` above the
   existing `<SupportAccessSection />` inside the same `Box sx={{ mt: 3 }}`, separated by a
   `Stack spacing={3}`. Test: `PodSettingsPage.test.tsx` (new) —
   `should show the pod identity section above support access`.
6. `web/src/components/templates/DashboardLayout.tsx`: call
   `usePodSettings({ enabled: hasPermission('pod_chief') })` from `useAuth()` and, when it returns
   data, replace the `app-logo.png` `<img>` with the Munserv mark plus a `Typography` showing
   `data.displayName`; when `logoUrl` is set render it beside the mark. Keep the current
   `app-logo.png` branch as the fallback for every other role and while loading. Test:
   `DashboardLayout.test.tsx` — `should show the pod display name in the header for a pod chief`,
   `should keep the app logo for a sector admin`, and the existing cases stay green.
7. `web/src/test/mocks/handlers.ts`: add `mockPodSettings` and handlers for
   `http.get('*/pod/settings', …)` and `http.patch('*/pod/settings', …)`, the patch echoing the body
   with `displayName` recomputed, in the style of the neighbouring handlers.
8. `web/src/locales/{en,af,zu}/translation.json`: extend the existing `podSettings` block with an
   `identity` group (`title`, `nameLabel`, `nameHelper`, `displayNamePreview`, `previewHint`,
   `logoUrlLabel`, `logoUrlHelper`, `save`, `saved`, `nameTooShort`, `nameTooLong`). `saved`
   interpolates `{{displayName}}`. The canvas note `copy` has every string verbatim. Real Afrikaans
   and isiZulu.

## Do not
- Do not call `GET /pod/settings` for an admin below `pod_chief`. The endpoint answers `403` and
  `web/src/lib/api-client.ts` turns any 403 into `authEvents.emit('session-expired')`, which would
  log a legitimate sector admin out of the portal. The `enabled` guard in step 6 is the whole point.
- Do not compose `"Munserv Pod " + name` anywhere in the client. `displayName` is server-owned; the
  invariant in `domain/pod.md` belongs to the backend.
- Do not build a file uploader (see AC3 above), and do not add a `logo` field to any request body.
- Do not touch `SupportAccessSection`, `Sidebar` or the boundary sections: W28/W30 own the first and
  W19 (#30) owns the last.
- Do not hardcode a colour for the Munserv mark; use `secondary.main` or whatever the approved
  artboard names, through `sx`.
- Do not touch backend, mobile or `specs/contracts/` (the Pod section is already written).

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
