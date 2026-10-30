# Demo account

## Definition
A dev account from `scripts/console/accounts.yaml` that demo and dev builds offer on the login page, so a tester picks a role instead of typing credentials. Quick login is the picker that fills and submits the login form with it.

## Why it exists
Testers switch between roles many times per eyeball run. Typing an email and password each time is slow and error-prone. The showcase and eyeball stacks offer the accounts in one pick, and production builds never offer them.

## Code names
| Platform | Identifier |
|---|---|
| Python | `scripts/demo_accounts.py` |
| TypeScript | `DemoAccount`, `parseDemoAccounts`, `DEMO_ACCOUNT_GROUP_ORDER` in `web/src/shared/types/demoAccount.ts` |
| Dart | added by story M8 |
| Database | none |

## Invariants
- A demo account is never present in a production build. CI's check from story I3 enforces this.
- `scripts/console/accounts.yaml` is the only source. An account is offered only when it has a `group`.
- The portal offers only admin roles. The app offers only `member` and `ground_admin`.
- `super_user` is never a demo account.
- `demo_account_group` values: `pod_chief`, `pod_admin`, `ward_chief`, `ward_admin`, `sector_chief`, `sector_admin`, `member`, `ground_admin`.

## Relationships
- Each demo account is an [admin](admin-role.md) or a [member](member.md); `ground_admin` is a [ground admin](ground-admin.md).

## Say / do not say
- Say **demo account** and **quick login**.
- Do not say "test user", "backdoor" or "auto-login".

## Decided by
specs/features/quick-login/spec.md
