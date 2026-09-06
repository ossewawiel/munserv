---
issue: 97
story: W18b
title: "Upload a pod logo"
platform: web
status: pending
depends_on: [96, 29]
touches:
  - web/src/features/pod-settings
  - web/src/test/mocks
  - web/src/locales
ui: true
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-09-06"
files_changed: []
tests_added: []
---

# W18b · Upload a pod logo (Web)

Read `domain/README.md` and `domain/pod.md` for every term used below. This handoff is complete on
its own; do not read the feature spec or other stories' handoffs.

## Outcome
A pod chief picks an image file in Pod Settings and the pod's logo is uploaded, saved and shown in
the identity card and the portal header, without ever typing a URL.

## Acceptance criteria
- [ ] Pod Settings offers a file picker for the pod logo
- [ ] Choosing an image uploads it and stores the returned `logoUrl` in the pod settings
- [ ] The new logo appears in the identity card and in the portal header without a page reload
- [ ] A file that is not a JPEG, PNG or WebP, or is larger than 5MB, is rejected inline with a message and is not uploaded
- [ ] The control is disabled while an upload is in flight and a server error is shown without losing the current logo

## Visual (ui stories only)
One screen changes: Pod Settings, the identity card built by W18 (#29). Match artboard: to be
produced by the designer under `design/canvases/pod-chief-mvp/pod-settings/` (states: no logo, logo
set, uploading, rejected file, server error). Until the canvas exists this story is not dispatchable.
The artboards outrank this handoff on copy, layout and order. `PodLogoUpload` is a feature component
under `features/pod-settings/components/`, not a registry component, so it needs no
`design/registry/web.md` row.

## Contract
`specs/contracts/api.md` § Pod. Both endpoints require role `pod_chief`.

`POST /pod/logo` — `multipart/form-data`, one part named `file` (JPEG, PNG or WebP, max 5MB) → `200`
```json
{ "logoUrl": "http://localhost:8080/uploads/8f14e45f-ea1e-4d0e-9c6b-2a1c6f1b7d10.png" }
```
Uploading stores the file only. Persist it with `PATCH /pod/settings` → `200`
```json
{ "name": "Ward42", "displayName": "Munserv Pod Ward42", "logoUrl": "http://localhost:8080/uploads/8f14e45f-....png" }
```
**Errors:** `400 { "code": "validation_error", "message": string }` | `401` | `403` | `500 { "code": "internal_error", "message": string }`.

W18 (#29) already built `features/pod-settings/{types,api,hooks}.ts`, `PodIdentitySection.tsx` and
the header binding; this story extends them. Do not start before both #96 and #29 are merged.

## Steps

1. `web/src/features/pod-settings/types.ts`: add
   `export interface PodLogoUploadResponse { logoUrl: string }`. No test.
2. `web/src/features/pod-settings/api.ts`: add
   `uploadLogo: (file: File): Promise<PodLogoUploadResponse> => { const form = new FormData(); form.append('file', file); return apiClient.post<PodLogoUploadResponse>('/pod/logo', form, { headers: { 'Content-Type': 'multipart/form-data' } }).then((r) => r.data); }`.
   Test: `api.test.ts` — `should post the chosen file as multipart form data`.
3. `web/src/features/pod-settings/hooks.ts`: add `useUploadPodLogo()` — a `useMutation` whose
   `mutationFn` uploads the file and then calls `podSettingsApi.updateSettings({ logoUrl })` with the
   returned URL, resolving to the updated `PodSettings`; `onSuccess` writes it to
   `queryClient.setQueryData(podSettingsKeys.all, settings)` so the identity card and the header
   update without a refetch. Test: `hooks.test.tsx` — `should save the uploaded logo url to the pod
   settings`, `should leave the cached settings unchanged when the upload fails`.
4. `web/src/features/pod-settings/components/PodLogoUpload.tsx` (new): the current logo as a
   `Box component="img"` (or an empty-state placeholder when `logoUrl` is null), a `Button` atom that
   opens a visually hidden `<input type="file" accept="image/jpeg,image/png,image/webp">` through a
   ref, and helper text for errors. Module constants
   `const ACCEPTED_LOGO_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const;` and
   `const MAX_LOGO_BYTES = 5 * 1024 * 1024;` — no magic numbers inline. Reject a bad type or an
   oversize file client-side with `t('podSettings.logo.invalidType')` /
   `t('podSettings.logo.tooLarge')` and never call the mutation. While `isPending`, disable the
   button and show `CircularProgress size={16}` as its `startIcon` (do not use the `Button` atom's
   `isLoading`, which replaces the label with hardcoded English). On error read
   `error.response.data.message` behind an `AxiosError` guard (`unknown` plus a guard, never `any`)
   and fall back to `t('podSettings.logo.uploadFailed')`. Clear the input's value after each pick so
   the same file can be retried. Test: `PodLogoUpload.test.tsx` —
   `should upload the chosen file and show the new logo` (`userEvent.upload` with
   `new File(['x'], 'logo.png', { type: 'image/png' })`),
   `should reject a file that is not an image`,
   `should reject a file larger than five megabytes`,
   `should disable the button while the upload is in flight`,
   `should show the server message when the upload fails`.
5. `web/src/features/pod-settings/components/PodIdentitySection.tsx`: replace the manual `logoUrl`
   `Input` and its inline `<img>` with `<PodLogoUpload />`; the name field, the `displayName` preview
   and the save button stay exactly as W18 built them. Update the W18 tests in
   `PodIdentitySection.test.tsx` that referenced the URL field, and add
   `should render the logo uploader in place of the logo url field`.
6. `web/src/test/mocks/handlers.ts`: add `http.post('*/pod/logo', …)` returning
   `{ logoUrl: 'http://localhost:8080/uploads/mock-logo.png' }`, in the style of the neighbouring
   handlers; the existing `PATCH /pod/settings` handler must echo the new `logoUrl`.
7. `web/src/locales/{en,af,zu}/translation.json`: extend the `podSettings` block with a `logo` group
   (`title`, `choose`, `replace`, `none`, `uploading`, `invalidType`, `tooLarge`, `uploadFailed`,
   `alt`). Real Afrikaans and isiZulu, not English copies. The canvas note `copy` has the final
   English strings once the artboards exist.

## Do not
- Do not send the file as base64, as a JSON field, or with `Content-Type: application/json`; the
  endpoint is multipart and takes exactly one part named `file`.
- Do not call `PATCH /pod/settings` before the upload resolves, and do not clear the existing
  `logoUrl` when an upload fails.
- Do not build a drag-and-drop zone, a cropper, a progress bar or client-side resizing; the artboards
  show a button and a preview.
- Do not read `GET /pod/settings` for an admin below `pod_chief` (W18's `enabled` guard stays): a
  `403` makes `web/src/lib/api-client.ts` emit `session-expired` and logs the admin out.
- Do not touch `DashboardLayout`, `SupportAccessSection` or the header lockup: they already re-render
  from the same query key.
- Do not touch backend, mobile or `specs/contracts/` — B11 (#96) owns the endpoint and its docs.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
