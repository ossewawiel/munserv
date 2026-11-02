---
issue: 223
story: W33
title: "pnpm build fails on an invalid VITE_DEMO_ACCOUNTS"
platform: web
status: completed
depends_on: []
touches:
  - web/vite.config.ts
  - web/tsconfig.node.json
  - web/config
ui: false
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-10-30"
files_changed:
  - web/config/demoAccountsInput.ts
  - web/tsconfig.node.json
  - web/vite.config.ts
tests_added:
  - web/config/demoAccountsInput.test.ts
---

# W33 · `pnpm build` fails on an invalid VITE_DEMO_ACCOUNTS (Web)

Read `domain/README.md` and `domain/demo-account.md`. This handoff is complete on its own. Put `Plan step: S46` in the PR body.

## Outcome
A build with a set-but-malformed quick-login input stops before it writes a bundle, so the raw string, with any credentials in it, never lands in `dist`.

## Acceptance criteria
- [ ] `pnpm build` fails, naming `VITE_DEMO_ACCOUNTS` and the reason, when the value is set but is not a JSON array of objects with string `group`, `name`, `email` and `password`
- [ ] `pnpm build` fails when an entry's `group` is outside the `demo_account_group` values in `domain/language.yaml`
- [ ] An unset or blank value builds as today; an empty array and any valid array build
- [ ] The failure message never contains the raw value, an email or a password
- [ ] A Vitest test covers the check, including one that its group list equals `demo_account_group` in `domain/language.yaml`
- [ ] lint, typecheck, tests and build pass

## Visual
None.

## Contract
`specs/features/quick-login/spec.md` § The build input. An entry is `{ "group": string, "name": string, "email": string, "password": string }`. `group` is one of `pod_chief`, `pod_admin`, `ward_chief`, `ward_admin`, `sector_chief`, `sector_admin`, `member`, `ground_admin` (`demo_account_group`). The web client still drops non-admin groups at runtime (`parseDemoAccounts`); this check only rejects input that is malformed.

## Background
Vite inlines `import.meta.env.VITE_DEMO_ACCOUNTS` into the bundle as a string literal (`web/src/features/auth/demoAccounts.ts`). When the value is set but invalid, no dropdown renders, but the string still ships. The W31 review (PR #220, section 3) asked for a build-time check.

## Steps
1. `web/config/demoAccountsInput.ts` (new). This is build tooling, not app code, so it lives outside `src`. Export:
   - `DEMO_ACCOUNT_GROUPS`, an `as const` array of the eight `demo_account_group` values in the order above, with a one-line comment that it mirrors `domain/language.yaml`.
   - `type DemoAccountsInputCheck = { readonly ok: true } | { readonly ok: false; readonly reason: string }`.
   - `checkDemoAccountsInput(raw: string | undefined): DemoAccountsInputCheck`. Return `{ ok: true }` for `undefined` or a blank string. Otherwise `JSON.parse` inside try/catch (`unknown`, never `any`). The reasons are `not valid JSON`, `not a JSON array`, `entry <i> is not an object`, `entry <i>: <field> is not a string` and `entry <i>: group is not a demo_account_group value`. A reason holds only these fixed words, the index and the field name, never text from the value. An empty array is valid.
   Test: `web/config/demoAccountsInput.test.ts` (import `describe`, `it`, `expect` from `vitest`; the node project has no vitest globals): `should accept an unset value`, `... a blank value`, `... an empty array`, `... one valid entry of every group`, `should reject a value that is not JSON`, `... a JSON object`, `... an entry without a password`, `... a group outside demo_account_group`, `should never put the value in the reason` (an invalid input holding `"pw-secret"` and `x@example.test`; the reason contains neither), `should list the same groups as domain/language.yaml` (read `../../domain/language.yaml` with `node:fs` via `new URL(..., import.meta.url)`, take the `demo_account_group: [...]` line with a regex and compare as sets).
2. `web/tsconfig.node.json`: change `"include"` to `["vite.config.ts", "config"]` so `tsc -b` checks the new folder. Test: `pnpm typecheck`.
3. `web/vite.config.ts`: switch to the function form `defineConfig(({ command, mode }) => ({ ... }))` and keep every existing setting. Before returning, when `command === 'build'`, read `loadEnv(mode, __dirname, 'VITE_').VITE_DEMO_ACCOUNTS` (`loadEnv` from `vite`; it covers `.env` files and the shell). Pass it to `checkDemoAccountsInput`. On `{ ok: false }`, throw `new Error(\`VITE_DEMO_ACCOUNTS is set but invalid: ${reason}\`)`. Vite stops a build only on a thrown error, so this throw is the one boundary where the Result becomes an exception. Do not check on `serve`: `pnpm dev`, Vitest and Storybook dev load this file too. `pnpm build-storybook` loads it with `command === 'build'`; with the variable unset, it passes. Test: the build commands in Done when.

## Do not
- Do not reject `member` or `ground_admin` entries. They are valid `demo_account_group` values; the portal drops them at runtime. (Known residue: a valid member-only array still inlines its string. The I3 check `scripts/check-no-demo-accounts.py` and the rule that production never sets the variable cover that case.)
- Do not import `src/shared/types/demoAccount.ts` or `@/` paths into `vite.config.ts`; the node project has no `@` alias.
- Do not print, log or echo the value, an email or a password anywhere.
- Do not change `parseDemoAccounts`, `demoAccounts.ts`, the CI workflow or anything outside the `touches` list.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
set -e
cd web
pnpm lint && pnpm typecheck && pnpm test:run
VITE_DEMO_ACCOUNTS="$(python3 ../scripts/demo_accounts.py web)" pnpm build
if VITE_DEMO_ACCOUNTS='{"group":"pod_chief"}' pnpm build; then echo "invalid input built"; exit 1; fi
if out=$(VITE_DEMO_ACCOUNTS='[{"group":"super_user","name":"","email":"x@example.test","password":"pw-secret"}]' pnpm build 2>&1); then echo "bad group built"; exit 1; fi
if printf '%s' "$out" | grep -q -e pw-secret -e x@example.test; then echo "value leaked"; exit 1; fi
pnpm build && python3 ../scripts/check-no-demo-accounts.py dist
```
The last line leaves `dist` as a clean, input-free build. Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: A build with a broken account list stops
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/223
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console/web && VITE_DEMO_ACCOUNTS=''{"group":"pod_chief"}'' pnpm build 2>&1 | tail -5`'
  expect: 'The build stops with "VITE_DEMO_ACCOUNTS is set but invalid: not a JSON array".'
- id: E2
  title: A build with an unknown group stops and hides the password
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/223
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console/web && VITE_DEMO_ACCOUNTS=''[{"group":"super_user","name":"","email":"x@example.test","password":"pw-secret"}]'' pnpm build 2>&1 | tail -5`'
  expect: 'The build stops with "entry 0: group is not a demo_account_group value", and neither pw-secret nor x@example.test appears.'
- id: E3
  title: Real accounts and no accounts both build
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/223
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console/web && VITE_DEMO_ACCOUNTS="$(python3 ../scripts/demo_accounts.py web)" pnpm build > /dev/null && pnpm build > /dev/null && python3 ../scripts/check-no-demo-accounts.py dist`'
  expect: Both builds finish and the last line says "no demo account" with a file count.
```
