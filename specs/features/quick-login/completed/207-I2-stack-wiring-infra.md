---
issue: 207
story: I2
title: "Quick-login input on the showcase and eyeball stacks"
platform: infra
status: completed
depends_on: [205]
touches:
  - scripts/console
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-10-30"
files_changed: [scripts/console/demo_input.py, scripts/console/showcase.py, scripts/console/remote.py, scripts/console/services.yaml, scripts/console/mobile.py, scripts/test-console.py]
tests_added: [DemoInputTests, ServiceTemplateTests, MobileWirelessDebuggingTests, showcase web_build_env test]
---

# I2 · Quick-login input on the showcase and eyeball stacks (Infra)

Read `domain/demo-account.md` (added by I1) and `specs/features/quick-login/spec.md` § The build input. This handoff is complete on its own.
Branch: `feat/i2-quick-login-stack-wiring` from `origin/master` after #205 merged. Put `Plan step: S46` and `Closes #207` in the PR body.

## Outcome
Every build the console makes (showcase web, eyeball web, phone installs, `flutter run`) carries the quick-login input. Builds made by hand carry none.

## Acceptance criteria
- [ ] The showcase build (TUI `u`, then `b`) passes the web input to `pnpm build`, and the site on :4000 shows the dropdown
- [ ] The eyeball web on :3000 (`scripts/eyeball-up.sh`) starts `pnpm dev` with the web input
- [ ] Phone installs from both checkouts (TUI `p`, then `i` or `s`) and the console's `flutter run` pass `--dart-define-from-file` with a freshly generated file
- [ ] `pnpm dev`, `pnpm build` and `flutter run` started by hand without the input show no dropdown
- [ ] `git status` is clean in both checkouts after a build
- [ ] Console tests cover the env and the build commands

The dropdown itself ships in W31 (#208) and M8 (#209). The ":4000 shows the dropdown" part is confirmed by the feature done check after they merge. This story proves that the input reaches each build.

## Visual
None.

## Contract
- `python3 scripts/demo_accounts.py web` prints the value of `VITE_DEMO_ACCOUNTS`.
- `python3 scripts/demo_accounts.py mobile --out <mobile dir>/demo-accounts.json` writes the dart-define file.
- `demo-accounts.json` is gitignored (I1).

## Steps
1. `scripts/console/demo_input.py` (new):
   - Constants: `SCRIPT = ROOT / "scripts" / "demo_accounts.py"` (ROOT from `.config`, the console's own repo, so accounts come from one file), `MOBILE_FILE = "demo-accounts.json"` and `DART_DEFINE = f"--dart-define-from-file={MOBILE_FILE}"`.
   - `web_value() -> str` runs `[sys.executable, str(SCRIPT), "web"]` and returns its stdout. Cache the result keyed on the mtime of `scripts/console/accounts.yaml`: `services_config()` expands placeholders on every poll and must not start a process each time. On a non-zero exit, raise `ApiError` with the stderr.
   - `write_mobile_file(mobile_dir: Path) -> Path` runs `mobile --out <mobile_dir>/demo-accounts.json` and returns the path.
   - `count(value: str) -> int` returns `len(json.loads(value))`, for log lines.
   - Test: `scripts/test-console.py` class `DemoInputTests`: `test_web_value_is_a_json_array`, `test_web_value_is_cached_until_accounts_change`, `test_write_mobile_file_writes_the_define_file`.
2. `scripts/console/showcase.py`:
   - `web_build_env()` adds `"VITE_DEMO_ACCOUNTS": demo_input.web_value()`.
   - In `_run_build`, before `web: build`, write the line `say(f"web: quick login with {demo_input.count(...)} accounts")`.
   - Test: `ShowcaseTests` (or the existing showcase test class) `test_web_build_env_carries_the_demo_accounts`.
3. `scripts/console/remote.py`:
   - In `expand()`, add the placeholder `{demo_accounts_web}`, filled with `shlex.quote(demo_input.web_value())`. It stays lazy like the others: computed only when the text contains it.
   - Update the `expand` docstring and the placeholder paragraph at the top of `scripts/console/services.yaml`.
   - Test: `test_expand_fills_demo_accounts_web_shell_quoted`.
4. `scripts/console/services.yaml`, service `web`: prefix `start` with `VITE_DEMO_ACCOUNTS={demo_accounts_web} `. Leave `storybook` without it. Test: `test_web_start_command_carries_the_demo_accounts` asserts that `services_config()["web"]["start"]` starts with `VITE_DEMO_ACCOUNTS='[`.
5. `scripts/console/mobile.py`:
   - In `_run_install_job`, call `demo_input.write_mobile_file(mobile_dir)` before the build and log `quick login with <n> accounts`. Append `demo_input.DART_DEFINE` to `build_cmd`.
   - In `start_run`, write the file first and append the same flag to `command`.
   - Tests (patch `subprocess.run`, `lan_ip` and `demo_input.write_mobile_file`): `test_install_build_passes_the_define_file`, `test_install_from_showcase_checkout_writes_the_file_there`, `test_run_command_passes_the_define_file`.

## Do not
- Do not write `.env`, `.env.local` or any other file into `web/`. The web input travels as an environment variable only.
- Do not add the input to `storybook`, `mock-api` or the CI workflow, or to a hand-run command in any CLAUDE.md.
- Do not copy `accounts.yaml` into the checkouts and do not add it to `local_files`. `demo_input` reads the console's own copy.
- Do not change `scripts/demo_accounts.py`. If its output is wrong, that is an I1 bug.

## Done when
```bash
python3 scripts/test-console.py && python3 scripts/test-tui.py && python3 scripts/test-demo-accounts.py
```
After merge, restart the console on master (`systemctl --user restart munserv-console`) so the new wiring runs. Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
The running console is master's code until this merges, so these checks call the PR checkout's code directly.

```yaml
- id: E1
  title: The showcase portal build gets the six administrator accounts
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/207
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && python3 -c "import json; from scripts.console import showcase; print(len(json.loads(showcase.web_build_env()[''VITE_DEMO_ACCOUNTS''])))"`'
  expect: The command prints 6.
- id: E2
  title: The eyeball portal starts with the accounts
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/207
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && python3 -c "from scripts.console import services; print(services.services_config()[''web''][''start''][:60])"`'
  expect: The printed line starts with VITE_DEMO_ACCOUNTS followed by a list of accounts.
- id: E3
  title: Phone builds get the accounts file and git stays clean
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/207
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && python3 scripts/test-console.py 2>&1 | tail -3`'
    - '`cd /home/ossewawiel/Work/munserv-console && python3 -c "from pathlib import Path; from scripts.console import demo_input; print(demo_input.write_mobile_file(Path(''mobile'').resolve()))" && git status --short`'
  expect: The tests end with OK, the second command prints the file path, and git lists no changed files.
- id: E4
  title: A build by hand has no accounts
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/207
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && grep -c "VITE_DEMO_ACCOUNTS" web/package.json mobile/pubspec.yaml`'
  expect: Both counts are 0, so the input only arrives through the console.
```
