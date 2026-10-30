---
issue: 205
story: I1
title: "Generate quick-login build input from accounts.yaml"
platform: infra
status: pending
depends_on: []
touches:
  - domain
  - scripts/console/accounts.yaml
  - scripts
  - .gitignore
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

# I1 · Generate quick-login build input from accounts.yaml (Infra)

Read `domain/README.md` and `domain/admin-role.md`. This handoff is complete on its own.
Branch: `feat/i1-demo-account-input` from `origin/master`. Put `Plan step: S46` and `Closes #205` in the PR body.

## Outcome
A developer runs one script and gets the quick-login input for the web and mobile builds, read from `scripts/console/accounts.yaml` only.

## Acceptance criteria
- [ ] `domain/demo-account.md` defines "demo account" and "quick login" (demo and dev builds only, never production), with a matching `domain/language.yaml` entry; domain validation passes
- [ ] Every account offered for quick login in accounts.yaml has a `group` field (`pod_chief`, `pod_admin`, `ward_chief`, `ward_admin`, `sector_chief`, `sector_admin`, `member`, `ground_admin`); `super_user` has none and is never offered; John's entry gains `first_name: John`
- [ ] `python3 scripts/demo_accounts.py web` prints a JSON array of the web accounts
- [ ] `python3 scripts/demo_accounts.py mobile --out <file>` writes the dart-define file `{"DEMO_ACCOUNTS": "<json array>"}` with the mobile accounts
- [ ] Each entry is `{group, name, email, password}`, ordered by group then name; `name` is `first_name` or empty
- [ ] The output file name is in `.gitignore`
- [ ] Unit tests run in CI's guardrails job

## Visual
None.

## Contract
`specs/features/quick-login/spec.md` § The build input. Entry: `{"group": "ground_admin", "name": "Sipho", "email": "sipho.dlamini@example.com", "password": "Ground456"}`. Group order: `pod_chief`, `pod_admin`, `ward_chief`, `ward_admin`, `sector_chief`, `sector_admin`, `member`, `ground_admin`. Web output: the bare array, compact JSON. Mobile file: `{"DEMO_ACCOUNTS": "<array as a JSON string>"}`.

## Steps
1. `domain/demo-account.md` (new), in the section order of `domain/README.md` § How a concept file is laid out. Definition: a dev account from `scripts/console/accounts.yaml` that demo and dev builds offer on the login page. Quick login is the picker that fills and submits the form with it. Invariants: it is never present in a production build, and CI's check from story I3 enforces this. The portal offers only admin roles and the app offers only member and ground admin. `super_user` is never a demo account. Code names: Python `scripts/demo_accounts.py`; TypeScript and Dart "added by W31 and M8". Say **demo account** and **quick login**; do not say "test user", "backdoor" or "auto-login". Decided by: `specs/features/quick-login/spec.md`. Add a row to the table in `domain/README.md`.
2. `domain/language.yaml`: add a `demo_account` concept with `definition`, `file: demo-account.md`, and `values: { demo_account_group: [pod_chief, pod_admin, ward_chief, ward_admin, sector_chief, sector_admin, member, ground_admin] }`. Add **no** `code:` block: the validator fails on a TypeScript or Dart name that does not exist yet. Test: `python3 scripts/validate-domain-language.py`.
3. `scripts/console/accounts.yaml`: add `group:` to `sector_admin`, `sector_chief`, `pod_chief`, `pod_admin`, `ward_chief`, `ward_admin` (the role value), `member` and `other_member` (`member`), and `ground_admin` (`ground_admin`). Leave `super_user` without one. Add `first_name: John` and `surname: Doe` to `member`. Add one header comment line saying that `group` opts an account into quick login (`scripts/demo_accounts.py`).
4. `scripts/demo_accounts.py` (new, executable, stdlib + PyYAML only):
   - `GROUP_ORDER` is a tuple in the contract order.
   - `DEFAULT_ACCOUNTS = Path(__file__).resolve().parent / "console" / "accounts.yaml"`.
   - `load(path) -> dict` reads the file.
   - `entries(accounts, platform) -> list[dict]` keeps accounts that have a `group` and whose `platform` matches. It sorts by `(GROUP_ORDER.index(group), name)` and builds each entry with exactly the four contract keys. It raises `ValueError` naming the account key when a group is not in `GROUP_ORDER`.
   - `web_value(accounts) -> str` returns `json.dumps(entries(...,"web"), separators=(",", ":"))`.
   - `mobile_define(accounts) -> dict` returns `{"DEMO_ACCOUNTS": <same dump for "mobile">}`.
   - CLI: `argparse` with `--accounts PATH` and subcommands `web` (prints the value) and `mobile --out FILE` (writes the JSON, creates the parent folder, prints the path). On `ValueError` it prints to stderr and exits 2.
   - Test: step 5.
5. `scripts/test-demo-accounts.py` (new, `unittest`, a temporary accounts file): `test_web_lists_only_web_accounts_with_a_group`, `test_super_user_is_never_offered`, `test_entries_follow_group_order_then_name`, `test_name_is_empty_without_first_name`, `test_mobile_file_holds_the_array_as_a_string`, `test_unknown_group_exits_2`, `test_real_accounts_file_gives_six_web_and_three_mobile_entries`.
6. `.gitignore`: add `demo-accounts.json` under "Environment & secrets".
7. `.github/workflows/ci.yml`, job `domain`: add the step `Test the quick-login input generator` with `run: python3 scripts/test-demo-accounts.py`, after the TUI step.

## Do not
- Do not touch web, mobile or the console's Python modules. I2 wires the stacks; W31 and M8 build the dropdown.
- Do not add a `label` field or derive names from emails. Admin entries have an empty `name` on purpose.
- Do not write the output inside the repository by default. `--out` is required for `mobile`.
- Do not change `scripts/dev-seed.py`. It reads `other_member` and `ground_admin` by key, and those keys stay.

## Done when
```bash
python3 scripts/validate-domain-language.py && python3 scripts/test-demo-accounts.py && python3 scripts/demo_accounts.py web && python3 scripts/test-console.py
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: The portal input lists the six administrator accounts
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/205
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && python3 scripts/demo_accounts.py web`'
  expect: One line of text lists six accounts, pod chief first and sector admin last, with no super user and no members.
- id: E2
  title: The app input lists the members and leaves no file behind in git
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/205
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && python3 scripts/demo_accounts.py mobile --out mobile/demo-accounts.json && cat mobile/demo-accounts.json`'
    - '`cd /home/ossewawiel/Work/munserv-console && git status --short`'
  expect: The file names John, Thandi and Sipho under one DEMO_ACCOUNTS key, and the second command prints nothing.
- id: E3
  title: The new words pass the domain language check
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/205
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console && python3 scripts/validate-domain-language.py`'
    - '`cd /home/ossewawiel/Work/munserv-console && python3 scripts/test-demo-accounts.py`'
  expect: Both commands end with zero errors and every test passes.
```
