---
issue: 0
story: DS4a
title: "Playwright visual regression for the web catalogue"
platform: web
status: pending
depends_on: []
touches: [design-system, web-e2e]
created_by: orchestrator
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# DS4a · Visual regression (Web)

Read `design/README.md`. This handoff is complete on its own.

## Outcome
`pnpm --dir web test:visual` screenshots every Storybook story against committed baselines and fails on a pixel difference above a small threshold, locally and in CI. `pnpm --dir web test:visual:update` refreshes baselines, and the CI job refuses a PR that changes baselines unless it carries the `design-approved` label.

## Acceptance criteria
- [ ] `web/e2e/visual/stories.spec.ts` reads the built Storybook's `index.json`, opens each story in `iframe.html?id=<id>&viewMode=story`, waits for fonts and idle, and calls `expect(page).toHaveScreenshot()` with `maxDiffPixelRatio: 0.002` and animations disabled
- [ ] Baselines committed under `web/e2e/visual/__screenshots__/` (Linux, chromium, 1280×800, deviceScaleFactor 1) for all stories except any the file explicitly skips with a reason
- [ ] Both light and dark: run each story twice with the theme global (`&globals=theme:light` / `theme:dark`) as the Storybook preview defines it
- [ ] `web/playwright.visual.config.ts`: separate config that serves `storybook-static` (`npx http-server` or Playwright's `webServer` with `pnpm exec http-server storybook-static -p 6007 -s`), chromium only, `snapshotPathTemplate` fixed so paths do not include the platform suffix twice
- [ ] Scripts `test:visual` and `test:visual:update` in `web/package.json`
- [ ] `.github/workflows/ci.yml`: new job `visual-web` (needs `changes.web`): install, `pnpm build-storybook`, `pnpm exec playwright install --with-deps chromium`, `pnpm test:visual`, upload the Playwright report on failure; plus a step that fails when `git diff --name-only origin/master...HEAD` contains `web/e2e/visual/__screenshots__/` and the PR has no `design-approved` label (use `gh pr view ${{ github.event.pull_request.number }} --json labels`)
- [ ] `CI status` aggregate includes `visual-web`
- [ ] Existing `e2e/registration.spec.ts` untouched; `pnpm test:run` still excludes `e2e/`

## Contract
None.

## Steps
1. `web/package.json`: add `http-server` dev dependency; scripts `test:visual` = `playwright test -c playwright.visual.config.ts`, `test:visual:update` = the same with `--update-snapshots`.
2. `web/playwright.visual.config.ts`: `testDir: 'e2e/visual'`, `webServer` serving `storybook-static` on 6007, `use: { viewport: {width:1280,height:800}, deviceScaleFactor: 1 }`, `expect.toHaveScreenshot: { maxDiffPixelRatio: 0.002, animations: 'disabled' }`, one chromium project.
3. `web/e2e/visual/stories.spec.ts`: fetch `index.json` at test-collection time via `fs.readFileSync('storybook-static/index.json')`; generate one `test()` per story and theme; skip list as a constant with reasons (for example stories that open portals with random ids).
4. Run `pnpm build-storybook && pnpm exec playwright install chromium && pnpm test:visual:update`; commit the baselines. Then `pnpm test:visual` must pass with 0 diffs.
5. `.github/workflows/ci.yml`: the `visual-web` job and the baseline-guard step; add it to `ci-status.needs` and its result loop.
6. `design/README.md`: under "Sign-off", document the two commands and the `design-approved` label rule. `web/CLAUDE.md`: one line under Tests.

## Do not
- Do not screenshot the running app against the backend; the catalogue is the surface.
- Do not raise the diff threshold to make a flaky story pass; skip it with a reason instead.
- Do not touch `mobile/`, `backend/`, `design/tokens/`, or any component.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
cd web && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build-storybook && pnpm test:visual
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with the number of baselines and any skipped stories. If you cannot finish, set `status: blocked` and end with `BLOCKED: <reason>`.
