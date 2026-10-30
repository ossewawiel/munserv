# Quick login

Plan step: S46. Milestone: [Quick login (S46)](https://github.com/ossewawiel/munserv/milestone/3).

## Goal
On demo and dev builds, a tester picks a dev account from a dropdown on the login page and is
logged in as that account without typing. Production builds never contain a dev account.

## Actors
- **Tester**: the user or a demo audience on the showcase stack (web :4000, API :8090, worktree
  `../munserv-demo`) or the eyeball stack (web :3000, API :8080, checkout `../munserv-console`).
- **CI**: proves that production builds carry no dev account.

## Decisions (settled, do not re-ask)
1. Quick login exists in demo and dev builds only. The flag is off by default: a build without
   the input shows nothing and contains nothing.
2. `scripts/console/accounts.yaml` is the only source of accounts. `scripts/demo_accounts.py`
   turns it into the build input. The generated file is never committed.
3. The web portal lists **admin accounts only**, because it logs in through
   `POST /auth/admin/login`. The app lists **member accounts only** (Member, Ground admin),
   because it logs in through `POST /auth/member/login` and has no admin UI.
4. `super_user` is never offered: it is environment configuration, not an account.
5. Admin options carry no person name ("Sector Admin"); member options carry the first name
   ("Ground admin · Sipho"). Picking an option submits at once; there is no confirm button.
6. Infra stories use the `I*` prefix, `platform:infra` and `specs/requirements/infra.md`. The
   main session implements them; the factory dispatches only W31 and M8.

## Domain
New concept file `domain/demo-account.md` (story I1). It covers "demo account" and
"quick login". All role and group values reuse `admin_role` and `ground_admin` wire values.

## The build input (contract between I1, I2, W31 and M8)
An account entry is a JSON object:

```json
{ "group": "ground_admin", "name": "Sipho", "email": "sipho.dlamini@example.com", "password": "Ground456" }
```

| Field | Type | Rule |
|---|---|---|
| `group` | string | One of `pod_chief`, `pod_admin`, `ward_chief`, `ward_admin`, `sector_chief`, `sector_admin`, `member`, `ground_admin` |
| `name` | string | `first_name` from accounts.yaml, or `""` |
| `email` | string | as in accounts.yaml |
| `password` | string | as in accounts.yaml |

Order: by group in the order above, then by name.

- **Web**: `VITE_DEMO_ACCOUNTS` is the JSON array of the accounts with `platform: web`, printed
  by `python3 scripts/demo_accounts.py web`. It is passed as an environment variable to
  `pnpm build` or `pnpm dev`; no file is written.
- **Mobile**: `python3 scripts/demo_accounts.py mobile --out <checkout>/mobile/demo-accounts.json`
  writes `{"DEMO_ACCOUNTS": "<the JSON array, as a string>"}` with the accounts that have
  `platform: mobile`. The build passes `--dart-define-from-file=demo-accounts.json` and the app
  reads `String.fromEnvironment('DEMO_ACCOUNTS')`. `demo-accounts.json` is in `.gitignore`.
- A client treats an unset, empty, non-JSON or non-array value as "no accounts" and renders
  nothing. It skips an entry whose group it does not show.

## Stories
| Id | Issue | Platform | ui | Depends on |
|---|---|---|---|---|
| I1 | [#205](https://github.com/ossewawiel/munserv/issues/205) | infra | false | none |
| I3 | [#206](https://github.com/ossewawiel/munserv/issues/206) | infra | false | none |
| I2 | [#207](https://github.com/ossewawiel/munserv/issues/207) | infra | false | #205 |
| W31 | [#208](https://github.com/ossewawiel/munserv/issues/208) | web | true | #207 |
| M8 | [#209](https://github.com/ossewawiel/munserv/issues/209) | mobile | true | #207 |

## Done check for the whole feature
1. On the showcase site (http://localhost:4000/login, opened through the LAN link), picking
   "Sector Admin" logs you in to the dashboard.
2. In the showcase app (TUI `p`, then `s`, against API :8090), picking "Ground admin · Sipho"
   logs you in.
3. The production build check from I3 passes in CI on master.

## Out of scope
- Member login on the web portal.
- Admin login in the app.
- Any backend change.
