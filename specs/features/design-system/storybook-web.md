---
issue: 0
story: DS1
title: "Storybook catalogue for the web design system"
platform: web
status: completed
depends_on: []
touches: [design-system, web-components]
created_by: orchestrator
created_at: "2026-09-05"
files_changed:
  - web/package.json
  - web/pnpm-lock.yaml
  - web/eslint.config.js
  - web/.gitignore
  - web/.storybook/main.ts
  - web/.storybook/preview.tsx
  - web/src/components/atoms/Button.stories.tsx
  - web/src/components/atoms/ActionButton.stories.tsx
  - web/src/components/atoms/ActionIconButton.stories.tsx
  - web/src/components/atoms/IconAvatar.stories.tsx
  - web/src/components/atoms/Badge.stories.tsx
  - web/src/components/atoms/Input.stories.tsx
  - web/src/components/atoms/Select.stories.tsx
  - web/src/components/atoms/Modal.stories.tsx
  - web/src/components/atoms/MainCard.stories.tsx
  - web/src/components/atoms/Spinner.stories.tsx
  - web/src/components/atoms/ThemeToggle.stories.tsx
  - web/src/components/atoms/IssueTypeFilterButton.stories.tsx
  - web/src/components/molecules/PageHeader.stories.tsx
  - web/src/components/molecules/Breadcrumbs.stories.tsx
  - web/src/components/molecules/StatCard.stories.tsx
  - web/src/components/molecules/IssueStateBadge.stories.tsx
  - web/src/components/molecules/IssueTypeBadge.stories.tsx
  - web/src/components/molecules/MemberStatusBadge.stories.tsx
  - web/src/components/molecules/HeatIndicator.stories.tsx
  - web/src/components/molecules/EmptyState.stories.tsx
  - web/src/components/molecules/ErrorState.stories.tsx
  - web/src/components/molecules/LoadingSkeleton.stories.tsx
  - web/src/components/molecules/ConfirmDialog.stories.tsx
  - web/src/components/molecules/Pagination.stories.tsx
  - web/src/components/molecules/PhotoGallery.stories.tsx
  - web/src/components/molecules/IssueTypeFilterBar.stories.tsx
  - web/src/components/molecules/LoginForm.stories.tsx
  - web/src/components/molecules/RegisterForm.stories.tsx
  - web/src/components/organisms/DataTableCard.stories.tsx
  - web/src/theme/generated/tokens.stories.tsx
tests_added: []
---

# DS1 · Storybook catalogue (Web)

Read `design/README.md` and `design/registry/web.md`. This handoff is complete on its own.

## Outcome
`pnpm --dir web storybook` opens a catalogue of every atom, molecule and organism in the registry, rendered with the real MUI theme in light and dark mode, and `pnpm --dir web build-storybook` produces a static site under `web/storybook-static/`.

## Acceptance criteria
- [ ] Storybook 10.6 (`@storybook/react-vite`) installed as dev dependencies; `storybook`, `build-storybook` scripts in `web/package.json`
- [ ] A global decorator wraps every story in the app's `ThemeProvider` (from `src/theme`) with a toolbar toggle for light / dark / system, plus `MemoryRouter`, `QueryClientProvider` and `I18nextProvider` (English)
- [ ] One `*.stories.tsx` co-located with every component listed in `design/registry/web.md` under Atoms and Molecules, and for `DataTableCard`; each story shows the component's meaningful states (for example `Button`: primary, secondary, danger, ghost, loading, disabled)
- [ ] A `Design/Tokens` story that renders the generated colour scheme swatches and size scale from `src/theme/generated/tokens.ts`
- [ ] `pnpm build-storybook` succeeds and its output is gitignored
- [ ] `pnpm lint`, `pnpm typecheck`, `pnpm test:run` still pass; stories are excluded from Vitest if they interfere

## Contract
None. No component behaviour changes; stories only.

## Steps
1. `web/package.json`: add dev deps `storybook@10.6.0`, `@storybook/react-vite@10.6.0` (do not add `@storybook/addon-vitest`; it does not support Vitest 5). Add scripts `"storybook": "storybook dev -p 6006"`, `"build-storybook": "storybook build"`. Run `pnpm install`.
2. `web/.storybook/main.ts`: framework `@storybook/react-vite`, `stories: ['../src/**/*.stories.tsx']`, reuse the Vite config aliases (`@/`).
3. `web/.storybook/preview.tsx`: global decorator providing theme (light/dark from a `globalTypes.theme` toolbar), router, query client, i18n. Test: `pnpm storybook --smoke-test` exits 0.
4. Stories for atoms: `Button`, `ActionButton`, `ActionIconButton`, `IconAvatar`, `Badge`, `Input`, `Select`, `Modal`, `MainCard`, `Spinner`, `ThemeToggle`, `IssueTypeFilterButton`. Use `satisfies Meta<typeof X>` and typed `StoryObj`; props from the component's real types.
5. Stories for molecules: `PageHeader`, `Breadcrumbs`, `StatCard`, `IssueStateBadge` (one story per wire value), `IssueTypeBadge`, `MemberStatusBadge`, `HeatIndicator` (0, 25, 50, 75, 100), `EmptyState`, `ErrorState`, `LoadingSkeleton`, `ConfirmDialog`, `Pagination`, `PhotoGallery`, `IssueTypeFilterBar`, `LoginForm`, `RegisterForm`. `LocationPickerDialog` may be skipped if Leaflet cannot render in Storybook; say so in the summary.
6. `DataTableCard.stories.tsx`: basic, with tabs and badges, empty, loading.
7. `src/theme/generated/tokens.stories.tsx` under title `Design/Tokens`: swatches for `schemeLight` and `schemeDark`, the semantic sets, and the size scales.
8. `.gitignore`: `web/storybook-static/`. `vite.config.ts` test exclude: add `'**/*.stories.tsx'` only if Vitest tries to collect them.
9. `design/README.md`: no change needed unless a command differs from what it says.

## Do not
- Do not restyle or refactor components to make stories easier; if a component cannot be rendered in isolation, note it and move on.
- Do not add Chromatic, addon-vitest, or any paid or cloud service.
- Do not touch `mobile/`, `backend/`, `design/tokens/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
cd web && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build-storybook
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with the story count and any component skipped and why. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.
