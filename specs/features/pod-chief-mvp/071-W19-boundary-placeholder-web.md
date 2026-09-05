---
issue: 30
story: W19
title: "Boundary configuration placeholder"
platform: web
status: pending
depends_on: []
touches:
  - web/src/features/pod-settings
  - web/src/locales
ui: true
design_canvas: "https://claude.ai/code/artifact/1f658255-0e88-48ac-ab86-1be239115d50"
design_artboards:
  - Main.dc.html
  - BoundariesSector.dc.html
design_approved: false
created_by: feature-planner
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# W19 · Boundary configuration placeholder (Web)

Read `domain/README.md`, `domain/pod.md`, `domain/ward.md` and `domain/sector.md` for every term
used below. This handoff is complete on its own; do not read the feature spec or other stories'
handoffs.

## Outcome
A pod chief opening Pod Settings sees that pod boundaries and ward/sector boundaries are part of the
product, marked "coming soon" and not yet operable, instead of wondering where they are.

## Acceptance criteria
- [ ] Pod boundaries section visible but disabled
- [ ] Ward/sector boundaries section visible but disabled
- [ ] "Coming soon" indicator

## Visual (ui stories only)
**Match the approved artboards**, working files under `design/canvases/pod-chief-mvp/pod-settings/`:
`Main` (both cards in their ward wording, in page context) and `BoundariesSector` (the sector
wording, with the tooltip open). **The artboards outrank the words here**, and they depart from step
1 below in three ways — read the canvas note `boundary-cards` before building:

- The two cards sit **side by side** in a flex row (`gap: 3`, each `flex: 1`, `align-items:
  stretch`), not stacked in the page's vertical `Stack`. Two full-width inert cards would push
  Support access below the fold.
- **No `opacity: 0.6`.** The acceptance criteria say the sections must be visible; dimming takes the
  title, chip and description with it. The card carries `bgcolor: 'action.hover'` instead, which
  reads as recessed while every word stays at full contrast. Keep `aria-disabled="true"`.
- The Chip is **`variant="outlined"`**. A filled default chip resolves to `rgba(0,0,0,.08)`, which
  over the tinted card is invisible.

`BoundaryPlaceholderCard` is a **new feature component** under `features/pod-settings/components/`,
not a registry component, so it needs no `design/registry/web.md` row and no Storybook story.

## Contract
None. This story calls no API and adds no type to `specs/contracts/`. Boundary geometry is
post-MVP; `GET /pod/status` reports `pod_boundaries` as a `SetupStep` but this story does not read
it.

## Steps

1. `web/src/features/pod-settings/components/BoundaryPlaceholderCard.tsx` (new): a presentational
   component taking `readonly title: string`, `readonly description: string` and rendering a
   `MainCard` whose `secondary` is an MUI `Chip` with `label={t('common.comingSoon')}`,
   `size="small"`, `color="default"`. The body is the description plus one disabled `Button` atom
   labelled `t('podSettings.boundaries.configure')` wrapped in an MUI `Tooltip` carrying the
   coming-soon copy. Dim the card with `sx={{ opacity: 0.6 }}` and set `aria-disabled="true"` on the
   card root so the state is announced, not only drawn. No data fetching: this is a molecule-level
   component and molecules never fetch. Test:
   `web/src/features/pod-settings/components/BoundaryPlaceholderCard.test.tsx` —
   `should render the coming soon chip`,
   `should render the configure button in a disabled state`.
2. `web/src/features/pod-settings/PodSettingsPage.tsx`: render two `BoundaryPlaceholderCard`s inside
   the page's `Stack`, below the pod identity card and above `<SupportAccessSection />` — one with
   `t('podSettings.boundaries.pod.title')` / `.description`, one with
   `t('podSettings.boundaries.area.title')` / `.description`. Pick the area wording from
   `usePodSetup()` (`web/src/shared/hooks/usePodSetup.ts`): use the ward keys when
   `status.wards.length > 0`, the sector keys otherwise. Test:
   `web/src/features/pod-settings/PodSettingsPage.test.tsx` (new unless W18 created it) —
   `should show a pod boundaries placeholder`,
   `should label the area placeholder Ward Boundaries when the pod has wards`,
   `should label the area placeholder Sector Boundaries when the pod has no wards`.
3. `web/src/locales/{en,af,zu}/translation.json`: add `common.comingSoon` if it is absent, and a
   `podSettings.boundaries` block with `configure`, `comingSoonHint`, `pod.title`,
   `pod.description`, `ward.title`, `ward.description`, `sector.title`, `sector.description`.
   `comingSoonHint` is the tooltip copy and is drawn on the `BoundariesSector` artboard; the canvas
   note `copy` has every string verbatim. Real Afrikaans and isiZulu translations, not English
   copies.

## Do not
- Do not add a map, Leaflet import, geometry type or draw control. This is a placeholder; the whole
  point is that no boundary code exists yet.
- Do not add an API call, a hook or a `features/pod-settings/api.ts` entry for boundaries.
- Do not hide the cards behind a feature flag or a setup-status check: the acceptance criteria say
  visible but disabled, for every pod chief, always.
- Do not write the words "Ward" or "Sector" as literals in the component; both come from i18n keys
  chosen by the `usePodSetup` branch, because the terminology adapts per pod.
- Do not touch `PodIdentitySection` or `SupportAccessSection`; W18 (#29) and W28/W30 own them. If
  W18 has not merged yet, place the two cards above `<SupportAccessSection />` and leave the rest of
  the page as you find it.
- Do not touch backend, mobile or `specs/contracts/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.
