# Infrastructure Requirements

Stories for scripts, the factory console and CI. Ids are `I*`, labels `platform:infra`. The
factory has no infra implementer: the main session implements these stories directly.

## Quick Login Stories

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| I1 | As a developer, I can generate the quick-login build input from `scripts/console/accounts.yaml` so that demo builds list the real dev accounts with nothing copied by hand | `domain/demo-account.md` and a `language.yaml` entry; domain validation passes ǀ Quick-login accounts carry `group`; `super_user` has none; John gains `first_name` ǀ `scripts/demo_accounts.py web` prints the web accounts as JSON ǀ `scripts/demo_accounts.py mobile --out <file>` writes `{"DEMO_ACCOUNTS": "<json array>"}` ǀ Entries `{group, name, email, password}` ordered by group then name ǀ Output file name gitignored ǀ Unit tests in CI's guardrails job | 🔴 Pending | [#205](https://github.com/ossewawiel/munserv/issues/205) |
| I2 | As a tester, I get quick login on the showcase and eyeball stacks without setting anything, so that I can switch roles in one pick | Showcase build passes the web input to `pnpm build`; :4000 shows the dropdown ǀ Eyeball web on :3000 starts `pnpm dev` with the web input ǀ Phone installs (`i`, `s`) and `flutter run` pass `--dart-define-from-file` with a fresh file ǀ Hand-run builds without the input show no dropdown ǀ `git status` clean after a build ǀ Console tests cover the env and build commands | 🔴 Pending | [#207](https://github.com/ossewawiel/munserv/issues/207) |
| I3 | As the project, CI fails when a production build contains a demo account, so that dev credentials never ship | `scripts/check-no-demo-accounts.py <path>` exits non-zero naming file and account, APKs included ǀ Web job scans `web/dist`, mobile job scans the debug APK ǀ Test: planted bundle fails, clean passes ǀ CI green on the PR | 🔴 Pending | [#206](https://github.com/ossewawiel/munserv/issues/206) |

## Status Legend
- 🟢 Done
- 🟡 In Progress
- 🔴 Pending
