# Eyeball block reference

Rules for the `## Eyeball` block of a handoff. Read this when you write or correct one. Do not copy it into the handoff; `_template/story-handoff.md` holds the block's shape.

**Required only when `ui: true` or `user_facing: true`.** For any other story, delete this section; the story goes from reviewer `APPROVE` straight to ready to merge.

**Plain-English rule for `steps` and `expect`.** One action per step. At most 20 words per step. Plain words: no jargon, no code names, no abbreviations a member of the public would not know. A step that is a terminal command is the command alone in one pair of backticks (for example `` `curl -s http://localhost:8080/actuator/health` ``); the TUI shows a Run key for it and prints the output under the step, and the word limit does not apply to the command. `expect` is one sentence a tester can judge by looking.

Rules for every check: `url` is the complete address a tester can paste into a browser (scheme, host, port, path, and for Swagger the deep link `http://localhost:8080/swagger-ui/index.html#/<Tag>/<operationId>`). Steps that go through Swagger name the deep link of each operation, the exact request body, and say where the token goes (Authorize button). Never write a bare path like `/api/v1/pod/logo`. The tester reaches the laptop through a terminal only (root `CLAUDE.md`, "When a person must act"); the console rewrites `localhost` in `url` to the LAN host, so browser links stay as they are. A step that needs the laptop itself (a mail in Mailpit, a log line, a database row) is an exact command to paste into that terminal, never "open http://localhost:8026" or a desktop app.

Manual acceptance checks a human runs before merge, from the console's Eyeball section or the TUI's Eyeball screen (`./tui.sh`, then `y`). The planner writes 2 to
6 checks that together cover every acceptance criterion above. Each check names the criteria it
proves in `covers` (`[AC1, AC3]`, numbered in the order above). A criterion no person can see
(lint, tests, a gate passing) goes in the front matter's `eyeball_exempt: [AC6]` instead.
`python3 scripts/lint-handoffs.py <handoff>` refuses a block that is prose, misses a key, names an
unknown account or service, or leaves a criterion uncovered; CI runs it on every new handoff.
The implementer corrects `url` (and
`as`, if the route or account changed) if it differs from what shipped; the reviewer verifies each
`covers` claim against what the check's `expect` actually proves. `as` is an account key from `scripts/console/accounts.yaml`, or `none`.
`services` lists what must be running, from `db`, `backend`, `web`, `mobile`, `mock-api`,
`storybook`. `url` is a full local URL (`http://localhost:3000/...`), or a mobile screen name
(`MembersListScreen`) for `platform: mobile` stories.

**Auto checks.** Add `auto: true` to a check a machine can run before the tester opens the PR. The console runs it on the public host (the address `scripts/eyeball-up.sh` prints), as the `as` account from `scripts/console/accounts.yaml`, and pre-ticks the check with its evidence. Two kinds:
- `probe`: HTTP requests, no screen. Each has `method`, `path` (from `/api/v1/...`), optional `body`, `expect_status` and optional `expect_body` (text or a list of texts the response must contain). `save: {name: "dotted.path"}` keeps a value from the JSON response; a later `path` or `body` string uses it as `{name}`. Give a list of requests for a chain. Write a probe for every check that needs no screen. A probe may delete or create data: use it only where the check already does.
- `page`: Playwright opens `url` as the account, asserts every text in `page.expect_text` is visible and saves a screenshot. It proves reachability and text, never layout.
A check without `auto` stays manual. Keep `steps` and `expect` on an auto check: the tester reads them next to the evidence.

## Examples

```yaml
- id: E1
  title: Pod chief grants support access
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/settings/pod
  steps:
    - Log in as the pod chief.
    - Open Pod Settings, then Support Access.
    - Click Grant.
    - Pick a role and type a reason.
    - Click Submit.
  expect: A new active grant appears in the list with the chosen role, granted time and a revoke button.
  covers: [AC1]
- id: E2
  title: Super user cannot reuse an expired grant
  as: super_user
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - Open Pod Settings, then Support Access, and click Revoke on the grant from E1.
    - Log in as the super user.
  expect: Login is refused with an error explaining there is no active grant.
  covers: [AC2]
- id: E3
  title: Anonymous delete is refused
  as: none
  auto: true
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Photos/deletePhoto
  probe:
    method: DELETE
    path: /api/v1/photos/00000000-0000-0000-0000-000000000000
    expect_status: 401
    expect_body: UNAUTHENTICATED
  steps:
    - Open the deletePhoto operation without logging in.
    - Press Try it out, then Execute.
  expect: The answer is 401 with the code UNAUTHENTICATED.
  covers: [AC2]
- id: E4
  title: Admin sees the issue list
  as: sector_admin
  auto: true
  services: [db, backend, web]
  url: http://localhost:3000/issues
  page:
    expect_text: [Issues]
  steps:
    - Log in as the sector admin.
    - Open Issues.
  expect: The issue list shows.
  covers: [AC1]
```
