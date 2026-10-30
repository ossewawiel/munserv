---
issue: 209
story: M8
title: "Quick login dropdown on the app's email login page"
platform: mobile
status: pending
depends_on: [207]
touches:
  - mobile/lib/features/auth
  - mobile/lib/l10n
  - mobile/widgetbook
  - mobile/test
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

# M8 · Quick login dropdown on the app's email login page (Mobile)

Read `domain/README.md`, `domain/demo-account.md`, `domain/member.md` and `domain/ground-admin.md`. Load `mobile-design-system`. This handoff is complete on its own. Put `Plan step: S46` in the PR body.

## Outcome
On a demo or dev build, a tester picks a member account on the email login page and is logged in as that member, without typing.

## Acceptance criteria
- [ ] When `DEMO_ACCOUNTS` (from `--dart-define-from-file`) holds a non-empty JSON array, `EmailLoginPage` shows a Quick login dropdown above the form
- [ ] Options sit under Member and Ground admin headings; each reads "<Role> · <name>", for example "Ground admin · Sipho"
- [ ] Picking an option fills the email and password and submits; first-login steps (change password, PIN setup) follow as after a typed login
- [ ] A failed quick login shows the normal error banner
- [ ] Without the define, no dropdown renders
- [ ] Strings are in the ARB files; a Widgetbook use-case and goldens cover both states; format, analyze (infos fatal), tests and the debug APK pass
- [ ] The page matches the approved canvas

## Visual
Match the artboards to be produced by the designer (`design/canvases/quick-login/<Artboard>.dc.html`): `EmailLoginPage` with the dropdown closed, and with it open showing the Member and Ground admin headings. The designer fills in the names. "Both states" for goldens means closed and open. Without the define, the page is unchanged.

## Contract
`specs/features/quick-login/spec.md` § The build input. The define file is `{"DEMO_ACCOUNTS": "<JSON array as a string>"}`. Each entry is `{"group": "member" | "ground_admin", "name": string, "email": string, "password": string}`. Login stays `authProvider.notifier.loginWithEmail` (`POST /auth/member/login`); nothing new on the wire.

## Steps
1. `lib/features/auth/domain/demo_account.dart` (new): `enum DemoAccountGroup { member, groundAdmin }` with `static DemoAccountGroup? fromWire(String value)` (`member`, `ground_admin`); a Freezed `DemoAccount` (`group`, `name`, `email`, `password`, private constructor); a top-level `List<DemoAccount> parseDemoAccounts(String raw)`. The parser returns `const []` for a blank string, invalid JSON (catch `FormatException` only) or a non-list. It keeps an entry only when it is a `Map<String, Object?>` with a known group and three `String`s, so web groups drop out. Use `Object?`, never `dynamic`. Run build_runner. Test: `test/features/auth/domain/demo_account_test.dart`: `returns no accounts for an empty value`, `... for invalid json`, `... when the value is not a list`, `drops an entry with an admin group`, `keeps valid entries in order`.
2. `lib/features/auth/providers/demo_accounts_provider.dart` (new): `@Riverpod(keepAlive: true) List<DemoAccount> demoAccounts(Ref ref) => parseDemoAccounts(const String.fromEnvironment(_demoAccountsDefine));` with `const _demoAccountsDefine = 'DEMO_ACCOUNTS';`. Test: `test/features/auth/providers/demo_accounts_provider_test.dart` `is empty when the app is built without the define`.
3. `lib/features/auth/presentation/widgets/quick_login_dropdown.dart` (new), exported from `widgets.dart`: `QuickLoginDropdown({required List<DemoAccount> accounts, required ValueChanged<DemoAccount> onSelected, bool enabled = true})`. It is a Material 3 dropdown labelled `l10n.quickLoginLabel`. The headings `quickLoginGroupMember` and `quickLoginGroupGroundAdmin` are non-selectable items. Options read `l10n.quickLoginOption(role, name)`, or the role alone when `name` is empty. Use theme tokens and `Spacing` only. Test: `test/features/auth/presentation/widgets/quick_login_dropdown_test.dart`: `shows member and ground admin headings`, `reads role then name`, `calls onSelected with the chosen account`, `does nothing when disabled`.
4. `lib/features/auth/presentation/pages/email_login_page.dart`: `ref.watch(demoAccountsProvider)`. When it is non-empty, render `QuickLoginDropdown` as the first child of the form column, then `Spacing.md`, disabled while `_isLoading`. `onSelected` sets `_emailController.text` and `_passwordController.text`, then calls `_login()`. Test: `test/features/auth/presentation/pages/email_login_page_test.dart` (new or extend; override `demoAccountsProvider` and the auth notifier): `hides quick login without demo accounts`, `fills the fields and logs in when an account is picked`, `shows the error banner when a quick login fails`.
5. `lib/l10n/app_en.arb`: add `quickLoginLabel`, `quickLoginGroupMember` ("Member"), `quickLoginGroupGroundAdmin` ("Ground admin") and `quickLoginOption` (`"{role} · {name}"` with `@` placeholders), each with a description. Run `flutter gen-l10n`. The canvas outranks the copy.
6. `widgetbook/use_cases/quick_login_dropdown.dart` (new): use-case `Default` with fake `example.test` accounts; regenerate `main.directories.g.dart` with build_runner.
7. `test/goldens/quick_login_dropdown_golden_test.dart` (new): closed and open, light and dark, using `golden_test_helper.dart`. Run `flutter test test/goldens --update-goldens`. The PR needs `design-approved`.
8. `domain/language.yaml`, concept `demo_account`: add `dart: [DemoAccount, DemoAccountGroup]` under `code:`. If W31 merged first, keep its `typescript:` line. Also update the Dart row in `domain/demo-account.md`.

## Do not
- Do not hardcode an account list or real dev credentials in `lib/`, tests or Widgetbook; use `example.test`.
- Do not list admin roles. The app logs in members only.
- Do not gate on `kDebugMode`. The define alone decides, so the showcase debug build and a release build behave the same way.
- Do not touch the router, `PinLoginPage`, `AuthNotifier` or anything outside `mobile/` and the `demo_account` entry.
- Do not move the widget to `shared/widgets/`. It has one use.

## Done when
```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs && dart format --set-exit-if-changed lib test && flutter analyze --fatal-infos && flutter test && flutter build apk --debug && cd .. && python3 scripts/validate-domain-language.py && python3 scripts/check-no-demo-accounts.py mobile/build/app/outputs/flutter-apk/app-debug.apk
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.

## Eyeball
Install with the operator screen: `./tui.sh`, then `p`, then `i` (eyeball checkout, API 8080).

```yaml
- id: E1
  title: Picking Ground admin Sipho logs in
  as: ground_admin
  services: [db, backend, mobile]
  url: EmailLoginPage
  steps:
    - Install and open the app on the phone.
    - If the app asks for a PIN, tap Use Different Account.
    - Open the Quick login list.
    - Pick Ground admin · Sipho.
  expect: The app signs in by itself and moves on to set up a PIN or to the home screen as Sipho.
- id: E2
  title: The list shows members only
  as: none
  services: [db, backend, mobile]
  url: EmailLoginPage
  steps:
    - Log out in the app, then tap Use Different Account if asked.
    - Open the Quick login list.
  expect: Two headings, Member and Ground admin, list John, Thandi and Sipho, with no administrators.
- id: E3
  title: A failed quick login shows the usual error
  as: none
  services: [db, mobile]
  url: EmailLoginPage
  steps:
    - In the operator screen, stop the backend.
    - Open the Quick login list and pick Member · John.
    - Start the backend again.
  expect: The red error banner appears under the form and the app stays on the login page.
- id: E4
  title: A normal build carries no dev account
  as: none
  services: []
  url: https://github.com/ossewawiel/munserv/issues/209
  steps:
    - '`cd /home/ossewawiel/Work/munserv-console/mobile && flutter build apk --debug > /dev/null && python3 ../scripts/check-no-demo-accounts.py build/app/outputs/flutter-apk/app-debug.apk`'
  expect: The command ends with "no demo account", so a build without the accounts file has none inside.
```
