---
issue: 222
story: W32
title: "Quick login baselines from CI's render, W31 Eyeball gaps"
platform: web
status: pending
depends_on: []
touches:
  - web/src/components/molecules
  - web/e2e/visual/__screenshots__
  - specs/features/quick-login/208-W31-quick-login-web.md
ui: true
design_canvas: "https://claude.ai/artifact/Fi653crxT7uArKg4apB9vR"
design_artboards:
  - "web/Main.dc.html — Closed and LoginForm WithQuickLogin baselines"
  - "web/QuickLoginOpen.dc.html, web/QuickLoginOpenNamed.dc.html — Open baselines (unchanged unless step 1 reverses the premise)"
design_approved: true
created_by: feature-planner
created_at: "2026-10-30"
files_changed: []
tests_added: []
---

# W32 · Quick login baselines from CI's render, W31 Eyeball gaps (Web)

Read `domain/README.md` and `domain/demo-account.md`. This handoff is complete on its own. Put `Plan step: S46` in the PR body.

## Outcome
Every quick login baseline is CI's own render, the PR explains the font and tolerance facts behind it, and the W31 Eyeball block covers all seven W31 criteria.

## Acceptance criteria
- [ ] The PR body reports, with evidence, whether the portal and Storybook load Source Sans 3 as a web font, and whether loading the face before the Open click can change CI's render
- [ ] Every QuickLoginSelect and LoginForm WithQuickLogin baseline is CI's own render; none is generated on the laptop
- [ ] The Open story's play function holds only code that affects the render
- [ ] The PR body reports `maxDiffPixelRatio` and `threshold` from `web/playwright.visual.config.ts`, the Playwright defaults that apply, and why c3707d0 passed against the striped baseline; the config does not change
- [ ] The W31 handoff's Eyeball block adds checks for the af and zu strings, the Storybook Closed, Open and WithQuickLogin stories (Open against QuickLoginOpenNamed), and the real /login page against Main and QuickLoginOpen, font included
- [ ] lint, typecheck, tests, build and the visual gate pass; the design reviewer approves the retaken baselines

## Visual
Closed and WithQuickLogin match `design/canvases/quick-login/web/Main.dc.html`; Open matches `QuickLoginOpen` / `QuickLoginOpenNamed`. Baselines judge geometry and colour only: CI has no Source Sans 3. The typeface is judged on the real page (Eyeball E3).

## Contract
None.

## Why the reviewer's fix is not enough (planner finding; step 1 verifies it)
The W31 review asked to call `document.fonts.load('400 16px "Source Sans 3"')` and `'500 14px ...'` before the Open click. The planner found three facts against it:
1. Nothing loads Source Sans 3 as a web font. `web/index.html`, `web/src`, `web/.storybook` and `web/public` hold no `@font-face`, Google Fonts link or `@fontsource` import. `web/src/theme/defaultTheme.ts:10` only names the family, so the browser takes it from the operating system.
2. The laptop has the font installed (`~/.local/share/fonts/huisstyl/sourcesans3-*.ttf`). The CI runner (`ubuntu-latest`) does not, so CI renders an Arial-like fallback. `document.fonts.load` only resolves faces declared by `@font-face` or `FontFace`; with none, it resolves to an empty list at once, in CI and here. It cannot change CI's render.
3. The odd baselines are Closed and WithQuickLogin, not Open. `molecules-quickloginselect--closed--{light,dark}.png` and `molecules-loginform--with-quick-login--{light,dark}.png` came from 3721ccc, rendered on the laptop in Source Sans 3. Open light (75dba5d) and Open dark (283374f) are CI renders. The local four pass CI only because the glyph difference fits inside the tolerance.

The smallest honest fix: retake the four laptop baselines from CI, so all six share CI's font. Remove the font wait in Open that does nothing. Shipping Source Sans 3 as a web font is a separate story, because it rebaselines the whole catalogue.

## Steps
1. Verify the font facts; write a `## Font` section in the PR body. Run `grep -rn -i "@font-face\|fonts.googleapis\|fontsource\|woff" web/index.html web/src web/.storybook web/public` (expect no output). Run `git log --format='%h %s' -- web/e2e/visual/__screenshots__/stories.spec/molecules-quickloginselect--*.png web/e2e/visual/__screenshots__/stories.spec/molecules-loginform--with-quick-login--*.png`. Quote both outputs. **If grep finds a loaded face**, the premise is wrong; say so and skip steps 2 and 4. Instead, load both faces before the click and await `document.fonts.ready` in the Open `play`. Then retake only the two Open baselines, as in step 4.
2. `web/src/components/molecules/QuickLoginSelect.stories.tsx`, story `Open`: delete `await document.fonts.ready;` and the two comment lines above it. Keep the click. `e2e/visual/stories.spec.ts` already awaits `document.fonts.ready` before each screenshot. Test: `pnpm test:run` stays green; the Open baselines must not change in CI (step 4).
3. Tolerance, report only: write a `## Tolerance` section in the PR body. Read `expect.toHaveScreenshot` in `web/playwright.visual.config.ts` and `pnpm exec playwright --version`. The planner read `maxDiffPixelRatio: 0.002`, which allows 2048 of 1,024,000 pixels at 1280x800. `threshold` is not set, so Playwright's default 0.2 applies. A pixel counts only when its YIQ colour distance exceeds 35215 x 0.2² ≈ 1409. The old dark stripes, #1F2926 against #39423F, differ by about 25 in luma: 0.5053 x 25² ≈ 323. That is under 1409, so no stripe pixel counted, and c3707d0 passed against the striped baseline. Confirm or correct each figure. Do not change the config.
4. Retake the four laptop baselines from CI's render. (a) `git rm` the four PNGs named in finding 3, commit `test(web): drop laptop-rendered quick login baselines so CI renders them (#222)`, push. (b) The visual job fails with "A snapshot doesn't exist at ... writing actual" for those four tests. This is expected; 5ba1f59 and 283374f used the same route. (c) Run `gh run download <run-id> -n visual-web-report -D <scratchpad>/report`. `report/index.html` embeds a base64 zip of per-test JSON. Each attachment has a `name` ending in `-actual.png` and a `path` under `data/`. Copy each actual to its baseline path. (d) Commit `test(web): quick login baselines from the CI render (#222)`, push. Name the run id in the PR body. The comparison step must then pass. The "Baseline change requires design-approved label" step stays red until the orchestrator adds the label after a design-reviewer APPROVE.
5. `specs/features/quick-login/208-W31-quick-login-web.md`, the Eyeball section: append this story's checks E2, E3 and E4 to the end of the W31 YAML list, renamed E5, E6 and E7, otherwise verbatim. Add one line above the W31 YAML fence: "E6's typeface part passes only on a computer with Source Sans 3 installed: the portal ships no web font (W32). If the letters differ, fail E6 and name the font you see." Leave E1 to E4 and the rest of W31 unchanged.

## Do not
- Do not run `pnpm test:visual:update` or commit any PNG rendered on this laptop. Local `pnpm test:visual` reports diffs on CI-rendered baselines; that is expected, and CI is the judge.
- Do not retake the Open baselines (already CI renders) unless step 1 reverses the premise.
- Do not add `document.fonts.load` calls that cannot change CI's render.
- Do not change `playwright.visual.config.ts`, `stories.spec.ts`, the theme, or add a web font.
- Do not touch `QuickLoginSelect.tsx`, `LoginForm.tsx` or any other baseline. Do not add the `design-approved` label yourself.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
cd web && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build && cd ..
python3 -c "from pathlib import Path; from scripts.console.eyeball import frontmatter_and_body, eyeball_block; ids=[c['id'] for c in eyeball_block(frontmatter_and_body(Path('specs/features/quick-login/208-W31-quick-login-web.md').read_text())[1])]; print(ids); assert ids==['E1','E2','E3','E4','E5','E6','E7']"
```
Then CI's "Visual regression" step must be green on the last push (`scripts/watch-ci.sh <pr>`). Update this frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: The pull request explains the font and the tolerance
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/222
  steps:
    - Open the pull request linked from this issue.
    - Read the Font and Tolerance sections of its description.
  expect: Font says whether a web font loads and names the CI run the four baselines came from; Tolerance gives 0.002, 0.2 and why c3707d0 passed.
- id: E2
  title: Afrikaans and isiZulu read correctly in Quick login
  as: sector_admin
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - Pick Sector Admin in the Quick login list.
    - Open the profile menu, choose Language, then Afrikaans.
    - Log out, then read the Quick login box.
    - Pick Sector Admin again, switch the language to isiZulu, and log out.
    - Read the Quick login box.
    - Log in, switch the language back to English, and log out.
  expect: Afrikaans shows "Vinnige aanmelding" over "Kies 'n rekening", and isiZulu shows "Ukungena ngokushesha" over "Khetha i-akhawunti".
- id: E3
  title: The real login page matches the canvas, font included
  as: none
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - Open the login page, logged out.
    - On your computer, open https://claude.ai/artifact/Fi653crxT7uArKg4apB9vR and find the web frame Main.
    - Compare the page with the frame Main.
    - Open the Quick login list and compare it with the web frame QuickLoginOpen.
    - Compare the letter shapes on the page with the canvas text.
  expect: Layout, colours, headings and wording match both frames, and the page text uses the same typeface as the canvas.
- id: E4
  title: The Storybook stories show both states and the named menu
  as: none
  services: [storybook]
  url: http://localhost:6006/?path=/story/molecules-quickloginselect--closed
  steps:
    - Open the link and look at the closed Quick login box.
    - In the side list, open QuickLoginSelect, then Open.
    - Compare the open menu with the web frame QuickLoginOpenNamed on the canvas.
    - In the side list, open LoginForm, then With Quick Login.
  expect: Closed shows an empty box reading "Choose an account"; Open matches QuickLoginOpenNamed, from "Pod Chief · Tester 5" down to a bare "Sector Admin"; With Quick Login shows the box above Email.
```
