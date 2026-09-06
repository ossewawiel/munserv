---
issue: 132
story: W18c
title: "Snackbar feedback and a Reset action on the pod identity form"
platform: web
status: pending
depends_on: [29]
touches:
  - web/src/components/organisms
  - web/src/components/templates
  - web/src/features/pod-settings
  - web/src/locales
ui: true
design_canvas: "https://claude.ai/code/artifact/1f658255-0e88-48ac-ab86-1be239115d50"
design_artboards:
  - design/canvases/pod-chief-mvp/pod-settings/Main.dc.html
  - design/canvases/pod-chief-mvp/pod-settings/IdentityDirty.dc.html
  - design/canvases/pod-chief-mvp/pod-settings/IdentitySaving.dc.html
  - design/canvases/pod-chief-mvp/pod-settings/IdentityInvalidName.dc.html
  - design/canvases/pod-chief-mvp/pod-settings/IdentitySaved.dc.html
  - design/canvases/pod-chief-mvp/pod-settings/IdentityServerError.dc.html
design_approved: false
created_by: designer
created_at: "2026-09-06"
files_changed: []
tests_added: []
---

# W18c · Snackbar feedback and a Reset action on the pod identity form (Web)

Read `domain/README.md` and `domain/pod.md` for every term used below. This handoff is complete on
its own; do not read the feature spec or other stories' handoffs.

Both issues came out of the eyeball run on W18 (#101). They change one card, but the first one also
sets a portal-wide convention that is now written into `design/registry/web.md` under **Feedback**.

## Outcome
A pod chief who saves the pod identity sees the confirmation as a snackbar over the page instead of
an alert wedged into the card, and can discard an unsaved edit with a Reset button beside Save.

## Acceptance criteria
From #128:
- [ ] A successful save of the pod identity is confirmed by a `Snackbar` over the page, not by an inline alert inside the card
- [ ] The snackbar carries a filled `Alert` of the matching severity, auto-hides after 4 seconds, and only one is on screen at a time
- [ ] Validation errors and a server rejection of the save stay inline next to the form and do not auto-dismiss
- [ ] The snackbar is shared portal code, not a `Snackbar` hand-rolled inside `PodIdentitySection`

From #129:
- [ ] A Reset action sits beside Save in the pod identity card
- [ ] Reset is enabled only while the form is dirty, and disabled while a save is in flight
- [ ] Reset restores the last saved pod name and logo URL and clears any field error
- [ ] Nothing is sent to the server when Reset is pressed

## Visual (ui stories only)
Canvas: **Pod Settings**, `design/canvases/pod-chief-mvp/pod-settings/`. The artboards and their
annotations (`feedback` especially) outrank this handoff on visual detail.

| Screen / state | Artboard |
|---|---|
| Resting form, saved values, Reset disabled | `Main.dc.html` |
| Unsaved edit, Save and Reset both enabled | `IdentityDirty.dc.html` |
| Save in flight, both buttons disabled | `IdentitySaving.dc.html` |
| Name too short: field error, Save disabled, Reset enabled | `IdentityInvalidName.dc.html` |
| Saved: bottom-centre snackbar, no inline alert, Reset disabled | `IdentitySaved.dc.html` |
| Server rejected the change: inline alert stays, unchanged | `IdentityServerError.dc.html` |

`FeedbackSnackbar` is a registry organism (see below), so it needs a Storybook story covering at
least the success and error severities, and `IdentityDirty` and `IdentitySaved` each need a
`PodIdentitySection` story so the visual gate can render them.

## Registry
`design/registry/web.md` now carries a `FeedbackSnackbar` row and a **Feedback** section. Build the
component to that row; do not introduce any other new shared component. `Button`, `Input`,
`MainCard` and the MUI `Alert` already in use cover everything else on these artboards.

## Contract
None. No request or response shape changes; Reset is client-side only.

## Steps
1. `web/src/components/organisms/FeedbackSnackbar.tsx` (new): a `Snackbar` with
   `anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}` and `autoHideDuration={4000}`,
   holding `<Alert variant="filled" severity={severity} elevation={6}>{message}</Alert>`. It renders
   `null` with no message and shows one message at a time — a new message replaces the one on
   screen. Props: `{ feedback: { message: string; severity: AlertColor } | null; onClose: () => void }`.
   No colour literals; severity picks the palette. Test: `FeedbackSnackbar.test.tsx` —
   `should render the message with the given severity`, `should call onClose when it auto-hides`,
   `should render nothing without a message`.
2. `web/src/components/organisms/FeedbackSnackbar.stories.tsx` (new): stories for `Success` and
   `Error`, message text supplied by the story, not translated in the story file.
3. `web/src/hooks/useFeedback.ts` (new, or the project's existing hooks folder): a context provider
   plus `useFeedback()` returning `showFeedback({ message, severity })`. The provider owns the single
   message state and renders `FeedbackSnackbar`. Test: `useFeedback.test.tsx` —
   `should expose the last message shown`, `should replace an earlier message`.
4. `web/src/components/templates/DashboardLayout.tsx`: mount the feedback provider around the layout
   content, once, beside `SessionExpiredHandler`. Leave `SessionExpiredHandler` exactly as it is —
   it is the one deliberate exception in the registry's Feedback section. Test:
   `DashboardLayout.test.tsx` — the existing cases stay green.
5. `web/src/features/pod-settings/components/PodIdentitySection.tsx`: delete the inline success
   `Alert` and its spacing, and call `showFeedback({ message: t('podSettings.identity.saved', { displayName }), severity: 'success' })`
   from the mutation's `onSuccess`. The inline error `Alert` for a rejected save and the field-level
   validation stay exactly as W18 built them. Test: `PodIdentitySection.test.tsx` —
   `should show the saved confirmation in a snackbar`, `should not render an inline success alert
   after a save`, `should keep the server error inline when the save is rejected`.
6. `web/src/features/pod-settings/components/PodIdentitySection.tsx`: add a `Reset` `Button`
   (`variant="secondary"`) to the left of Save in the actions row, 12px apart, `disabled` unless
   `formState.isDirty` and while `isPending`. `onClick` calls `reset()` with the values from
   `usePodSettings`, which also clears field errors. It issues no request. Test:
   `PodIdentitySection.test.tsx` — `should disable reset while the form is pristine`,
   `should restore the saved name when reset is pressed`, `should disable both buttons while saving`,
   `should not call the mutation when reset is pressed`.
7. `web/src/features/pod-settings/components/PodIdentitySection.stories.tsx`: add `Dirty` and
   `Saved` stories matching `IdentityDirty.dc.html` and `IdentitySaved.dc.html`.
8. `web/src/locales/{en,af,zu}/translation.json`: add `podSettings.identity.reset` — English
   `Reset`. Real Afrikaans and isiZulu, not English copies. `podSettings.identity.saved` is
   unchanged; it is now the snackbar's message.

## Do not
- Do not put the failed-save message in the snackbar. A 400 the pod chief has to act on stays inline
  (`IdentityServerError.dc.html` is deliberately untouched by this story).
- Do not stack snackbars, add a queue, or pull in `notistack`. One message at a time, as the registry
  row says.
- Do not fold `SessionExpiredHandler` into `FeedbackSnackbar`, and do not move its top-centre bar.
- Do not render a `Snackbar` inside `PodIdentitySection` or any other feature component.
- Do not make Reset re-fetch, reload the page, or reset to empty values — it restores the last saved
  values already in the query cache.
- Do not change the header preview binding: it still shows the saved `displayName`, never the draft.
- Do not touch the boundary placeholder cards, `SupportAccessSection`, backend, mobile or
  `specs/contracts/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: Saving the pod name confirms in a snackbar
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Open Pod Settings and change the pod name in the Pod identity card.
    - Press Save changes and watch the bottom of the page.
  expect: A green bar slides in at the bottom centre reading 'Saved. The header now reads "Munserv Pod ...".', it disappears on its own after about four seconds, and no success message appears inside the card.
- id: E2
  title: A rejected save stays inline
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Clear the pod name down to a single character and try to save; then set a name the server refuses.
  expect: The field error and the card's error alert stay on screen until the problem is fixed; neither appears as a disappearing bar at the bottom.
- id: E3
  title: Reset is offered only for an unsaved edit
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Look at the buttons on the untouched Pod identity card, then type a change into the pod name.
  expect: Reset sits to the left of Save changes, greyed out on the untouched form and active as soon as the name differs from the saved one.
- id: E4
  title: Reset restores the saved values
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Type a wrong pod name (and a different logo URL) without saving, then press Reset.
  expect: Both fields go back to the last saved values, any field error clears, Reset greys out again, and the header and preview never changed.
```
