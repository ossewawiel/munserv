# Design

The design system's source of truth, in three parts:

| Part | Where | Consumed by |
|---|---|---|
| Tokens | `tokens/*.tokens.json` (W3C DTCG) | `sd.config.mjs` generates `web/src/theme/generated/tokens.ts` and `mobile/lib/shared/theme/generated/tokens.dart`; CI fails on drift |
| Registry | `registry/web.md`, `registry/mobile.md` | Agents, before creating or styling any component |
| Catalog | Storybook (`web/`) and Widgetbook (`mobile/widgetbook/`) | Humans and the design reviewer; published by `.github/workflows/pages.yml` to https://ossewawiel.github.io/munserv/ (`storybook/`, `widgetbook/`) |

## Changing a colour or size
1. Edit the token in `tokens/`.
2. `pnpm --dir design build` (installs nothing; Style Dictionary is a dev dependency of this folder).
3. Commit the token and both generated files together. `pnpm --dir design check` is what CI runs.

## Adding a component
Registry row, story or use-case, then the component. The reviewer blocks a PR that adds a component without the first two.

## Sign-off
Every feature with UI gets a design canvas built from these tokens and this registry before planning; the approved canvas URL goes into the feature spec. Screenshot and golden tests keep the build honest against it (PR 5b).

Web: `pnpm --dir web test:visual` screenshots every Storybook story (light and dark) against the baselines committed under `web/e2e/visual/__screenshots__/` and fails on more than a 0.2% pixel difference; `pnpm --dir web test:visual:update` refreshes them after an intentional visual change. CI blocks a PR that changes those baselines unless it carries the `design-approved` label.
- `cd mobile && flutter test test/goldens` — run the mobile golden suite.
- `cd mobile && flutter test test/goldens --update-goldens` — refresh the mobile golden PNGs after an approved visual change.
