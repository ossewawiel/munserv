---
issue: 221
story: M9
title: "M8 Eyeball block: canvas and Widgetbook checks"
platform: mobile
status: pending
depends_on: []
touches:
  - specs/features/quick-login/209-M8-quick-login-mobile.md
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-10-30"
files_changed: []
tests_added: []
---

# M9 · M8 Eyeball block: canvas and Widgetbook checks (Mobile, docs only)

Read `domain/README.md` and `domain/demo-account.md`. This handoff is complete on its own. Put `Plan step: S46` in the PR body. Use the conventional title `docs(specs): M8 Eyeball covers canvas and Widgetbook (#221)`.

## Outcome
The M8 handoff's Eyeball block covers all seven M8 acceptance criteria, so the eyeball run is a real human look at the quick login on a phone and in Widgetbook.

## Acceptance criteria
- [ ] The M8 handoff's Eyeball block has a check that compares the real email login page on a phone, with Quick login closed and open, against the M8 canvas frames Main and QuickLoginOpen (https://claude.ai/artifact/Fi653crxT7uArKg4apB9vR)
- [ ] The M8 Eyeball block has a check that opens QuickLoginDropdown > Default in the published Widgetbook and toggles Enabled
- [ ] Together, the M8 checks cover all seven M8 acceptance criteria
- [ ] Only the Eyeball block of `209-M8-quick-login-mobile.md` changes; no code changes; the block parses as a list of checks with an id

## Visual
None. This story changes no screen. The checks it adds point the tester at the approved app frames `design/canvases/quick-login/Main.dc.html` and `QuickLoginOpen.dc.html` (canvas link above).

## Contract
None.

## Background
PR #219 (M8) merged before its review. The review found the code meets every criterion, with two Eyeball gaps:
- AC7 ("The page matches the approved canvas") has no check. The goldens render in the Ahem test font, so the eyeball run is the only look at real text on a real phone.
- AC6 (Widgetbook use-case) has no check. The use-case is `mobile/widgetbook/use_cases/quick_login_dropdown.dart`: use-case `Default` under component `QuickLoginDropdown`, with a boolean knob labelled `Enabled` and the fake accounts John, Thandi (Member) and Sipho (Ground admin).

## Steps
1. `specs/features/quick-login/209-M8-quick-login-mobile.md`, the Eyeball section: append these two checks to the end of the YAML list, after E4, exactly as written. Keep E1 to E4 unchanged. Test: the parse command in Done when prints `['E1', 'E2', 'E3', 'E4', 'E5', 'E6']`.

```yaml
- id: E5
  title: The login page on the phone matches the canvas
  as: none
  services: [db, backend, mobile]
  url: EmailLoginPage
  steps:
    - Open the app on the phone. If it asks for a PIN, tap Use Different Account.
    - On your computer, open https://claude.ai/artifact/Fi653crxT7uArKg4apB9vR and find the app frame Main.
    - Compare the login page on the phone with the frame Main.
    - Open the Quick login list on the phone.
    - Compare the open list with the app frame QuickLoginOpen.
  expect: Both phone screens match their frames in order, colours, filled boxes, row heights, heading indent and wording.
- id: E6
  title: The Widgetbook entry works switched on and off
  as: none
  services: []
  url: https://ossewawiel.github.io/munserv/widgetbook/
  steps:
    - Open the Widgetbook link.
    - In the side list, open QuickLoginDropdown, then Default.
    - Open the Quick login list and read the names.
    - In the settings panel, switch Enabled off.
    - Try to open the Quick login list again.
  expect: Switched on, the list shows John and Thandi under Member and Sipho under Ground admin; switched off, the box is greyed out and does not open.
```

2. Same file, frontmatter: change nothing. The M8 frontmatter stays `status: completed`.

## Do not
- Do not edit E1 to E4, the M8 acceptance criteria, steps or frontmatter.
- Do not touch any file under `mobile/`, the goldens or the Widgetbook use-case.
- Do not point a step at a `localhost` address; the tester has no browser on the laptop.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
python3 -c "from pathlib import Path; from scripts.console.eyeball import frontmatter_and_body, eyeball_block; ids=[c['id'] for c in eyeball_block(frontmatter_and_body(Path('specs/features/quick-login/209-M8-quick-login-mobile.md').read_text())[1])]; print(ids); assert ids==['E1','E2','E3','E4','E5','E6']"
test "$(git diff --name-only origin/master -- . ':!specs/features/quick-login/221-M9-m8-eyeball-gaps-mobile.md')" = "specs/features/quick-login/209-M8-quick-login-mobile.md"
cd mobile && dart format --set-exit-if-changed lib test && flutter analyze --fatal-infos && flutter test
```
The last line is the stop-gate hook's mobile gate; it runs on an unchanged `mobile/` and must stay green. Then update this frontmatter (`status: completed`, `files_changed`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
These are the two checks this story adds to M8. Running them here is the acceptance. Install with the operator screen first: `./tui.sh`, then `p`, then `i` (eyeball checkout, API 8080).

```yaml
- id: E1
  title: The login page on the phone matches the canvas
  as: none
  services: [db, backend, mobile]
  url: EmailLoginPage
  steps:
    - Open the app on the phone. If it asks for a PIN, tap Use Different Account.
    - On your computer, open https://claude.ai/artifact/Fi653crxT7uArKg4apB9vR and find the app frame Main.
    - Compare the login page on the phone with the frame Main.
    - Open the Quick login list on the phone.
    - Compare the open list with the app frame QuickLoginOpen.
  expect: Both phone screens match their frames in order, colours, filled boxes, row heights, heading indent and wording.
- id: E2
  title: The Widgetbook entry works switched on and off
  as: none
  services: []
  url: https://ossewawiel.github.io/munserv/widgetbook/
  steps:
    - Open the Widgetbook link.
    - In the side list, open QuickLoginDropdown, then Default.
    - Open the Quick login list and read the names.
    - In the settings panel, switch Enabled off.
    - Try to open the Quick login list again.
  expect: Switched on, the list shows John and Thandi under Member and Sipho under Ground admin; switched off, the box is greyed out and does not open.
```
