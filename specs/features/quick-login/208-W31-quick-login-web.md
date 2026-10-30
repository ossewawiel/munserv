---
issue: 208
story: W31
title: "Quick login dropdown on the portal login page"
platform: web
status: pending
depends_on: [207]
touches:
  - web/src/features/auth
  - web/src/components/molecules
  - web/src/shared/types
  - web/src/locales
  - domain/language.yaml
ui: true
design_canvas: ""
design_artboards: []
design_approved: false
created_by: feature-planner
created_at: "2026-10-30"
files_changed: []
tests_added: []
---

# W31 · Quick login dropdown on the portal login page (Web)

Read `domain/README.md`, `domain/demo-account.md` and `domain/admin-role.md`. This handoff is complete on its own. Put `Plan step: S46` in the PR body.

## Outcome
On a demo or dev build, a tester picks an administrator account on the login page and lands where a typed login would land, without typing.

## Acceptance criteria
- [ ] When `VITE_DEMO_ACCOUNTS` holds a non-empty JSON array at build time, the login page shows a Quick login dropdown above the form
- [ ] Options sit under role headings in this order: Pod chief, Pod admin, Ward chief, Ward admin, Sector chief, Sector admin; each reads "<Role> · <name>", or "<Role>" when there is no name
- [ ] Picking an option fills the email and password and submits; the redirect matches a typed login (onboarding, super user, dashboard)
- [ ] A failed quick login shows the normal login error
- [ ] When the variable is unset, empty or not a valid array, no dropdown renders and the production bundle holds no account data
- [ ] Strings are i18n keys in en, af and zu; Storybook has stories for both states; lint, typecheck, tests and the visual gate pass
- [ ] The page matches the approved canvas

## Visual
Match the artboards to be produced by the designer (`design/canvases/quick-login/<Artboard>.dc.html`): the login page with the dropdown closed, and with it open showing the role headings. The designer fills in the names. Without the input, the page stays exactly as today's `LoginForm` Default story.

## Contract
`specs/features/quick-login/spec.md` § The build input. `VITE_DEMO_ACCOUNTS` is a JSON array of `{ "group": AdminRole, "name": string, "email": string, "password": string }`. Example: `[{"group":"sector_admin","name":"","email":"admin@ward42.example.com","password":"admin123"}]`. Login stays `POST /auth/admin/login` through the existing `useLogin`; nothing new on the wire.

## Steps
1. `web/src/env.d.ts` (new): `/// <reference types="vite/client" />` plus `interface ImportMetaEnv { readonly VITE_DEMO_ACCOUNTS?: string }`.
2. `web/src/shared/types/demoAccount.ts` (new): `export interface DemoAccount { readonly group: AdminRole; readonly name: string; readonly email: string; readonly password: string }`; `export const DEMO_ACCOUNT_GROUP_ORDER: readonly AdminRole[] = [...ADMIN_ROLES].reverse();` (highest first); `export function parseDemoAccounts(raw: string | undefined): readonly DemoAccount[]`, which returns `[]` for undefined, blank, invalid JSON or a non-array, and keeps only entries passing an `isDemoAccount(value: unknown)` guard (group in `ADMIN_ROLES`, three strings). Test: `demoAccount.test.ts`: `should return no accounts when the value is undefined`, `... is not json`, `... is not an array`, `should drop an entry whose group is not an admin role`, `should keep valid entries in order`.
3. `web/src/features/auth/demoAccounts.ts` (new): `export const DEMO_ACCOUNTS = parseDemoAccounts(import.meta.env.VITE_DEMO_ACCOUNTS);`. This is the only place that reads the variable.
4. `web/src/components/molecules/QuickLoginSelect.tsx` (new), exported from `molecules/index.ts`. Props: `{ readonly accounts: readonly DemoAccount[]; readonly onPick: (account: DemoAccount) => void; readonly disabled?: boolean }`. It is a MUI `TextField select` labelled `t('auth.quickLogin.label')`. For each group in `DEMO_ACCOUNT_GROUP_ORDER` that has accounts, render a `ListSubheader` with `t(`roles.${group}`)`, then one `MenuItem` per account, keyed by email. Item text is `t('auth.quickLogin.option', { role, name })`, or the role alone when `name` is empty. The control resets to empty after a pick. Story: `QuickLoginSelect.stories.tsx` with fake `example.test` accounts in all six groups. Test: `QuickLoginSelect.test.tsx`: `should list the role headings highest first`, `should show the name after the role when there is one`, `should show the role alone when there is no name`, `should call onPick with the chosen account`.
5. `web/src/components/molecules/LoginForm.tsx`: add the optional prop `quickLoginAccounts?: readonly DemoAccount[]`. When it is non-empty, render `QuickLoginSelect` above the email field, disabled while `isLoading`. On pick, set `email` and `password` and call `onSubmit(account.email, account.password)`. Add the story `WithQuickLogin`. Test: `LoginForm.test.tsx` (new or extend): `should not render quick login without accounts`, `should fill the fields and submit when an account is picked`.
6. `web/src/features/auth/LoginPage.tsx`: pass `quickLoginAccounts={DEMO_ACCOUNTS}`. Test: `LoginPage.test.tsx`, mocking `./demoAccounts`: `should log in and redirect when a quick login account is picked`, `should show the login error when a quick login fails`, `should not show quick login when there are no demo accounts`.
7. `web/src/locales/{en,af,zu}/translation.json`: add `auth.quickLogin.label`, `auth.quickLogin.placeholder` and `auth.quickLogin.option` (`"{{role}} · {{name}}"`). Use real Afrikaans and isiZulu. The canvas outranks the English copy.
8. `domain/language.yaml`, concept `demo_account`: add `code: { typescript: [DemoAccount, parseDemoAccounts, DEMO_ACCOUNT_GROUP_ORDER] }`. If M8 merged first, keep its `dart:` line. Also update the TypeScript row in `domain/demo-account.md`.
9. Run `pnpm test:visual:update` for the new stories and commit the new baselines. The PR needs the `design-approved` label.

## Do not
- Do not put real dev emails or passwords in stories, tests or fixtures that ship; use `example.test`. Never hardcode an account list in source.
- Do not list members or the ground admin. The portal logs in admins only, and the parser drops other groups.
- Do not add a confirm button, remember the last pick or store the password anywhere.
- Do not read `import.meta.env` outside `features/auth/demoAccounts.ts`, and do not gate on `import.meta.env.DEV`. The input alone decides.
- Do not change `useLogin`, `getRedirectPath`, the Select atom or anything in backend or mobile.

## Done when
```bash
cd web && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build && pnpm test:visual && cd .. && python3 scripts/validate-domain-language.py && python3 scripts/check-no-demo-accounts.py web/dist
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: The list shows administrator roles only, and Sector Admin logs straight in
  as: sector_admin
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - Open the login page, logged out.
    - Open the Quick login list and read the headings.
    - Pick Sector Admin.
  expect: Headings read Pod Chief to Sector Admin, highest first, with no members, and picking Sector Admin opens the dashboard.
- id: E2
  title: Picking a pod chief follows the normal path
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/login
  steps:
    - Open the Quick login list.
    - Pick Pod Chief.
  expect: You land on the same page a typed pod chief login reaches, with the pod chief menu.
- id: E3
  title: A failed quick login shows the usual error
  as: none
  services: [db, web]
  url: http://localhost:3000/login
  steps:
    - In the operator screen, stop the backend.
    - Open the Quick login list and pick Sector Admin.
    - Start the backend again.
  expect: The form shows the same error message a wrong password shows, and stays on the login page.
- id: E4
  title: A normal build carries no dev account
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/208
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console/web && pnpm build > /dev/null && python3 ../scripts/check-no-demo-accounts.py dist`'
  expect: The command ends with "no demo account" and the file count.
```
