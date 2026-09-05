# Feature: design-system

**Goal:** One source of truth for how MunServ looks, checked by machines: design tokens that generate both platforms' theme constants, a component registry agents read before building, catalogues that render the real components, and (5b) visual gates that prove a build matches its approved design.
**Platforms:** web, mobile, design (cross-cutting)
**Status:** 🟡 In Progress
**Decisions:** memory `design-system-decisions`; factory design record section "Visual design"

## Stories

| ID | Title | Handoff | Status |
|---|---|---|---|
| DS0 | Design tokens (DTCG) and Style Dictionary generator, registry, CI drift check | done in PR 5a directly | 🟢 Done |
| DS1 | Storybook catalogue for web | [storybook-web.md](storybook-web.md) | 🔴 Pending |
| DS2 | Widgetbook catalogue for mobile, theme showcase removed | [widgetbook-mobile.md](widgetbook-mobile.md) | 🔴 Pending |
| DS3 | GitHub Pages workflow publishing both catalogues | `.github/workflows/pages.yml`, `site/index.html` | 🟡 In Progress (first deploy after DS1 and DS2 merge) |
| DS4 | Playwright screenshot tests and Flutter golden tests with committed baselines | PR 5b | 🔴 Pending |
| DS5 | `designer` and `design-reviewer` agents; Design stage in `/factory` | PR 5b | 🔴 Pending |

## Notes
- Web and mobile dark schemes differ on 13 M3 roles; tokens carry the web palette, mobile keeps its own until #69 is decided.
- Storybook's Vitest addon does not support Vitest 5; visual tests use Playwright directly (DS4).
- GitHub Pages is enabled for the repository with `build_type: workflow`; the site is https://ossewawiel.github.io/munserv/.
