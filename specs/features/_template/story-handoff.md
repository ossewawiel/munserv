---
issue: 0
story: W00
title: ""
platform: backend | web | mobile
status: pending
depends_on: []          # other story ids or issue numbers that must be merged first
touches: []             # feature folders this story edits; the orchestrator serialises overlaps
ui: false               # true when the story adds or changes a screen; then a canvas is required before dispatch
design_canvas: ""       # set by the designer: canvas URL
design_artboards: []    # set by the designer: artboard files under design/canvases/<feature>/
design_approved: false  # set by the user (through the orchestrator) after reviewing the canvas
created_by: feature-planner
created_at: ""
files_changed: []
tests_added: []
---

# W00 · Title (Platform)

Read `domain/README.md` for every term used below. This handoff is complete on its own; do not read the feature spec or other platforms' handoffs unless a step says so.

## Outcome
One sentence: what a user or caller can do after this story that they could not before.

## Acceptance criteria
- [ ] AC1 (copied verbatim from the GitHub issue)
- [ ] AC2

## Visual (ui stories only)
Which artboard each screen and state must match, by file name. "None" for non-UI stories.
The artboards and their annotations outrank this handoff on visual detail (copy, order, severity,
formatting): describe *what* here, never restate *how it looks*. Each artboard in scope needs a
story or use-case so the visual gate renders it.

## Contract
API or type changes this story depends on, quoted from `specs/contracts/api.md` / `types.md`. "None" if none.

## Steps
Numbered, imperative, one file per step where possible. Each step names the file path, what to add or change, and the test that proves it.

1. `path/to/File.kt`: add `X`. Test: `path/to/FileTest.kt` `should ... when ...`.
2. ...

## Do not
- Things that look reasonable but are wrong for this story (other platforms, renames, refactors outside the listed files).

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.

## Eyeball
Rules for every check: `url` is the complete address a tester can paste into a browser (scheme, host, port, path, and for Swagger the deep link `http://localhost:8080/swagger-ui/index.html#/<Tag>/<operationId>`). Steps that go through Swagger name the deep link of each operation, the exact request body, and say where the token goes (Authorize button). Never write a bare path like `/api/v1/pod/logo`.

Manual acceptance checks a human runs in `scripts/eyeball.py` before merge. The planner writes 2 to
6 checks that together cover every acceptance criterion above; the implementer corrects `url` (and
`as`, if the route or account changed) if it differs from what shipped; the reviewer verifies the
checks still cover every AC. `as` is an account key from `scripts/eyeball/accounts.yaml`, or `none`.
`services` lists what must be running, from `db`, `backend`, `web`, `mobile`, `mock-api`,
`storybook`. `url` is a full local URL (`http://localhost:3000/...`), or a mobile screen name
(`MembersListScreen`) for `platform: mobile` stories.

```yaml
- id: E1
  title: Pod chief grants support access
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Log in as the pod chief and open Pod Settings > Support Access.
    - Click Grant, pick a role and enter a reason, then submit.
  expect: A new active grant appears in the list with the chosen role, granted time and a revoke button.
- id: E2
  title: Super user cannot reuse an expired grant
  as: super_user
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - Wait for the grant from E1 to expire, or revoke it from Pod Settings.
    - Log in with the super user credentials.
  expect: Login is refused with an error explaining there is no active grant.
```
