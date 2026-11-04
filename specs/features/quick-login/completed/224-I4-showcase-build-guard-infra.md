---
issue: 224
story: I4
title: "Showcase build refuses while the worktree is behind origin/master"
platform: infra
status: completed
depends_on: []
touches:
  - scripts/console
  - scripts/test-console.py
  - scripts/test-tui.py
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-10-30"
files_changed: [scripts/console/showcase.py, scripts/test-console.py, scripts/test-tui.py]
tests_added: [test_build_is_refused_when_origin_master_moved_on, test_build_starts_when_the_worktree_is_current, test_build_without_a_worktree_skips_the_check, test_running_build_is_returned_without_a_fetch, test_failed_fetch_answers_409, test_demo_build_shows_the_console_refusal]
---

# I4 · Showcase build refuses while the worktree is behind origin/master (Infra)

Read `domain/README.md`. The main session implements this story (no infra implementer in the factory). Put `Plan step: S46` in the PR body.

## Outcome
Pressing build on a showcase that has not been updated answers with a clear refusal instead of quietly building old code.

## Acceptance criteria
- [ ] `POST /api/showcase/build` fetches origin/master, then answers 409 "Update the showcase first: it is behind origin/master" when the showcase worktree HEAD is not origin/master
- [ ] When HEAD equals origin/master, or the worktree does not exist yet, the build starts as today
- [ ] A failed fetch answers 409 with the git error, as update does
- [ ] A build job that is already running is returned as today, without a fetch
- [ ] The TUI's demo build key (`b`) shows the refusal text; a TUI test proves it
- [ ] Tests in `scripts/test-console.py` cover behind, current and missing worktree; `python3 scripts/test-console.py` and `python3 scripts/test-tui.py` pass

## Visual
None.

## Contract
Console API only, no wire change to the product. `POST /api/showcase/build` keeps `{"ok": true, "job": {...}}` on success. A refusal is the console's existing error shape, `{"ok": false, "error": "<message>"}` with status 409, produced by `ApiError` in `scripts/console/server.py`.

## Background
`showcase.start_build` (`scripts/console/showcase.py`) starts `_run_build` on whatever commit the worktree `../munserv-demo` sits on. `_run_build` already runs `update()` when no worktree exists. The TUI already surfaces the error text: `ConsoleApi._request` (`scripts/tui/api.py`) raises `ConsoleError("POST /api/showcase/build: <error>")`, and `run_showcase_action` (`scripts/tui/app.py`) notifies it with `severity="error"`. So the TUI needs a test, not a code change.

## Steps
1. `scripts/console/showcase.py`: add `BEHIND_MESSAGE = "Update the showcase first: it is behind origin/master"` and `behind_master() -> bool`. It runs `git -C <ROOT> fetch origin master`, then compares the full `git -C <checkout> rev-parse HEAD` with `git -C <ROOT> rev-parse origin/master` (`run_captured`, `BRANCH`). The worktree shares the main repo's refs, so one fetch covers both. In `start_build`, after the `running_job` early return and before `new_job`, guard when `is_worktree(checkout())`. Catch `CommandError` from `behind_master()` and raise `ApiError(str(e), 409)`. When it returns `True`, raise `ApiError(BEHIND_MESSAGE, 409)`. Test: step 2.
2. `scripts/test-console.py`, class `ShowcaseTests`: reuse the bare-origin fixture from `test_update_creates_a_detached_worktree_then_follows_origin_master`. Move it into a helper if two tests need it. Patch `showcase.ROOT`, `showcase.checkout`, `showcase.copy_local_files`, `services.running_job` (returns `None`), `services.new_job` and `threading.Thread`, so no build runs. Tests: `test_build_is_refused_when_origin_master_moved_on` (update, push a commit to origin from a second clone, then `start_build` raises `ApiError` 409 with `BEHIND_MESSAGE`); `test_build_starts_when_the_worktree_is_current` (update, then `start_build` returns the new job); `test_build_without_a_worktree_skips_the_check` (`checkout` points at a missing dir; patch `behind_master` and assert it was not called); `test_running_build_is_returned_without_a_fetch` (`running_job` returns a job; `behind_master` not called); `test_failed_fetch_answers_409` (`behind_master` raises `CommandError`).
3. `scripts/test-tui.py`: add `self.build_error = ""` to the stub beside `pair_error`. In `do_POST`, when the path is `/api/showcase/build` and `stub.build_error` is set, answer `{"ok": False, "error": stub.build_error}` with 409. Test: `test_demo_build_shows_the_console_refusal`. Set `build_error` to the message and replace `app.notify` with a recorder, as the pairing test does. Press `b`, then wait until a recorded text contains "Update the showcase first".

## Do not
- Do not make build run `update()` by itself when behind; the operator decides (TUI `u`).
- Do not change `update()`, `start()`, `_run_build` or the TUI app code.
- Do not compare short SHAs; use full `rev-parse` output.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
python3 scripts/test-console.py && python3 scripts/test-tui.py
```
After merge, restart the console on master (`systemctl --user restart munserv-console`) so the guard runs. Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
Run after the merge and the console restart above. E2 moves the showcase back one commit on purpose; its last steps restore it.

```yaml
- id: E1
  title: The console and screen tests pass
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/224
  steps:
    - '`cd /home/ossewawiel/Work/munserv && python3 scripts/test-console.py 2>&1 | tail -3 && python3 scripts/test-tui.py 2>&1 | tail -3`'
  expect: Both test runs end with OK.
- id: E2
  title: An old showcase refuses to build until it is updated
  as: none
  services: [db]
  url: https://github.com/ossewawiel/munserv/issues/224
  steps:
    - '`git -C /home/ossewawiel/Work/munserv-demo checkout -q --detach origin/master~1`'
    - Open the operator screen with ./tui.sh and press b.
    - Read the message at the bottom right.
    - Press u, wait for the update message, then press b.
  expect: 'The first b shows "Update the showcase first: it is behind origin/master"; after u, b starts the showcase build.'
```
