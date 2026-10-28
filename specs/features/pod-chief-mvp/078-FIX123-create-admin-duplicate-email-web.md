---
issue: 123
story: FIX123
title: "Add Administrator dialog shows no error when the email already exists"
platform: web
status: completed
depends_on: []
touches:
  - web/src/features/pod-chief/components/CreatePodAdminDialog.tsx
  - web/src/features/pod-chief/hooks.ts
  - web/src/locales
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: orchestrator
created_at: "2026-09-06"
files_changed:
  - web/src/features/pod-chief/components/CreatePodAdminDialog.tsx
  - web/src/features/pod-chief/PodAdministratorsPage.tsx
  - web/src/features/pod-chief/hooks.test.tsx
  - web/src/features/pod-chief/components/CreatePodAdminDialog.test.tsx
  - web/src/locales/en/translation.json
  - web/src/locales/af/translation.json
  - web/src/locales/zu/translation.json
tests_added:
  - "pod-chief hooks > useCreatePodAdministrator > should surface a 409 conflict to the caller"
  - "CreatePodAdminDialog > should show the duplicate email error and keep the dialog open with the entered values"
  - "CreatePodAdminDialog > should show a form-level alert with the server message for a non-conflict 4xx error"
  - "CreatePodAdminDialog > should clear the form-level alert when any field is edited"
  - "CreatePodAdminDialog > should show the generic failure alert for a network error with no response"
  - "CreatePodAdminDialog > should allow resubmitting after correcting the email"
---

# FIX123 · Add Administrator dialog shows no error on a duplicate email (Web)

Found by eyeball testing of #100 (B10, check E2). The backend already refuses the duplicate; the dialog swallows the answer.

## Outcome
When a pod chief submits the Add Administrator dialog with an email that already exists, the dialog stays open and shows the server's message on the email field; the same pattern covers any other 4xx from that endpoint.

## Acceptance criteria
- [ ] A 409 from `POST /pod/administrators` (`{ "code": ..., "message": "Email already exists" }`, the flat `ErrorResponse` unqualified-resolved from `PodController.kt:198-203` in `PodAdministratorController.kt:181,218`) is shown as the email field's error text and the dialog remains open with the entered values.
- [ ] Any other 4xx with a message shows a form-level `Alert severity="error"` inside the dialog; 5xx shows the generic error.
- [ ] Submitting again after correcting the email works.
- [ ] Copy is an i18n key in en/af/zu (`podAdministrators.errors.emailExists`).

## Visual
None (existing dialog; use the same error styling as `GrantAccessDialog` for the form-level alert).

## Contract
`POST /pod/administrators` → `409 Conflict` with the flat `{ code, message }` error body when the email exists (`PodAdministratorController`). No change.

## Steps
1. `web/src/features/pod-chief/hooks.ts` `useCreatePodAdmin`: expose the failing response (`AxiosError`) to the caller; do not swallow it. Test: `hooks.test.tsx` `should surface a 409 conflict to the caller`.
2. `web/src/features/pod-chief/components/CreatePodAdminDialog.tsx`: read `mutation.error`; on status 409 set the email field error to `t('podAdministrators.errors.emailExists')`; on other 4xx show an `Alert` with the server message; clear on edit. Test: `CreatePodAdminDialog.test.tsx` `should show the duplicate email error and keep the dialog open`, `should allow resubmitting after correcting the email`.
3. `web/src/locales/{en,af,zu}/translation.json`: add `podAdministrators.errors.emailExists`.

## Do not
- Do not change the backend or the contract.
- Do not touch `PodAdministratorsPage.tsx` beyond what the dialog needs.

## Done when
```bash
cd web && pnpm lint && pnpm typecheck && pnpm exec vitest run --maxWorkers=2
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes.

## Eyeball
```yaml
- id: E1
  title: Duplicate email is refused with a visible message
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - Click "Add administrator", enter the email of an existing administrator (for example podadmin@munserv.local), a name and a role, submit.
  expect: The dialog stays open and the email field shows "An administrator with this email already exists"; correcting the email and submitting creates the administrator.
- id: E2
  title: A non-conflict 4xx shows the server's message in a form-level alert
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - Click "Add administrator", enter a new (unused) email, a display name longer than 100 characters, and a role, submit. The client does not limit the display name's length, so this reaches the backend's validation.
  expect: The dialog stays open and shows a form-level error alert with the backend's message ("Display name must be 100 characters or less"), not the email field; shortening the name and submitting again creates the administrator.
```
