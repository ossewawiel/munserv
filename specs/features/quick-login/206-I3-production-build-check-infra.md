---
issue: 206
story: I3
title: "CI fails when a production build contains a demo account"
platform: infra
status: pending
depends_on: []
touches:
  - scripts
  - .github/workflows/ci.yml
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-10-30"
files_changed: []
tests_added: []
---

# I3 · CI fails when a production build contains a demo account (Infra)

Read `domain/README.md`. A "demo account" is any account in `scripts/console/accounts.yaml` (see `specs/features/quick-login/spec.md`). This handoff is complete on its own.
Branch: `feat/i3-no-demo-accounts-in-builds` from `origin/master`. Put `Plan step: S46` and `Closes #206` in the PR body.

## Outcome
A web bundle or an APK built without the quick-login input that still contains a dev email or password turns CI red, and the log names the file and the account.

## Acceptance criteria
- [ ] `scripts/check-no-demo-accounts.py <path>` exits non-zero and names the file and the account when any email or password from accounts.yaml appears under the path, including inside an APK
- [ ] The web CI job runs it on `web/dist` after `pnpm build`; the mobile job runs it on the debug APK after its build step
- [ ] A test shows it fails on a bundle with a planted account and passes on a clean one
- [ ] CI on the PR is green, which shows master ships no demo account

## Visual
None.

## Contract
None. It reads `email` and `password` from every top-level entry of `scripts/console/accounts.yaml`, `super_user` included. It does not depend on I1's `group` field.

## Steps
1. `scripts/check-no-demo-accounts.py` (new, executable, stdlib + PyYAML):
   - CLI `check-no-demo-accounts.py [--accounts PATH] PATH [PATH ...]`. `--accounts` defaults to `scripts/console/accounts.yaml` next to the script.
   - Needles: for each account key, its `email` and `password`, each encoded as UTF-8 **and** as UTF-16-LE. Skip a value shorter than 6 characters, and print that you skipped it.
   - Walk every regular file under each path; a path may also be a single file. A file for which `zipfile.is_zipfile` is true (`.apk`, `.jar`, `.aab`, `.zip`) is opened and each member is scanned, recursing into nested zips. Every other file is read as bytes.
   - Each hit prints `demo account <key> (<email|password>) found in <file>` or `... in <file>!<member>`.
   - Exit codes: `1` if anything is found. `2` if a path does not exist or no file was scanned, so an empty `dist/` never passes. `0` otherwise, printing `no demo account in <n> files`.
   - Test: step 2.
2. `scripts/test-check-no-demo-accounts.py` (new, `unittest`, temp folder and temp accounts file):
   - `test_planted_email_in_a_bundle_fails`
   - `test_planted_password_fails`
   - `test_clean_bundle_passes`
   - `test_account_inside_an_apk_fails` (write a zip named `app-debug.apk`)
   - `test_utf16_string_fails`
   - `test_missing_path_exits_2`
   - `test_empty_folder_exits_2`
   - `test_output_names_file_and_account`
3. `.github/workflows/ci.yml`:
   - Job `domain`: add the step `Test the demo-account build check` with `run: python3 scripts/test-check-no-demo-accounts.py`.
   - Job `web`: add `actions/setup-python@v5` (3.12) and `pip install --quiet pyyaml` before Install. After Build, add the step `No demo account in the production bundle` with `run: python3 ../scripts/check-no-demo-accounts.py dist`.
   - Job `mobile`: the same Python setup. After `Build debug APK`, add the step `No demo account in the APK` with `run: python3 ../scripts/check-no-demo-accounts.py build/app/outputs/flutter-apk/app-debug.apk`.
   - Job `changes`: add `scripts/console/accounts.yaml` and `scripts/check-no-demo-accounts.py` to both the `web` and `mobile` filters, so an account change re-runs both scans.

## Do not
- Do not set `VITE_DEMO_ACCOUNTS` or `--dart-define-from-file` anywhere in CI. The point is that the default build is clean.
- Do not weaken the needles to make a hit go away. If master's bundle or APK contains a dev credential, stop and report `BLOCKED:` with the file and account.
- Do not scan source folders (`web/src`, `mobile/lib`). Tests and fixtures may hold the emails; only shipped build output counts.
- Do not depend on `scripts/demo_accounts.py` (story I1). This check must work on its own.

## Done when
```bash
python3 scripts/test-check-no-demo-accounts.py && (cd web && pnpm build) && python3 scripts/check-no-demo-accounts.py web/dist
```
Then push, run `scripts/watch-ci.sh <pr>` and confirm the Web and Mobile jobs ran the new step green. Update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: CI ran the new check on the portal and the app and stayed green
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/206
  steps:
    - '`gh pr checks feat/i3-no-demo-accounts-in-builds --repo ossewawiel/munserv`'
  expect: Every check passes, including Web (React) and Mobile (Flutter).
- id: E2
  title: A file with a dev email in it fails the check
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/206
  steps:
    - '`mkdir -p /tmp/planted && echo "admin@ward42.example.com" > /tmp/planted/app.js`'
    - '`cd /home/ossewawiel/Work/munserv-console && python3 scripts/check-no-demo-accounts.py /tmp/planted; echo "exit $?"`'
  expect: The output names the sector_admin account and the file app.js, and ends with exit 1.
- id: E3
  title: The check's own tests pass
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/206
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && python3 scripts/test-check-no-demo-accounts.py`'
  expect: Every test passes, including the one with an account hidden inside an app package.
```
