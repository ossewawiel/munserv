# Mobile Requirements

## MVP Stories

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| M1 | Login with email/password | Enter email + password → if first login: change password → setup PIN → access app | 🟢 Done | [#3](https://github.com/ossewawiel/munserv/issues/3) |
| M2 | Login with PIN/biometric | Enter PIN or use fingerprint → access app | 🟢 Done | - |
| M3 | View issues on map | See map centered on my sector with issue markers | 🟢 Done | - |
| M4 | View issue list | See list of issues, filter by type/state | 🟢 Done | - |
| M5 | Report new issue | Take photo → select type → confirm location → submit | 🟢 Done | - |
| M6 | View issue details | See photo(s), type, state, location, timestamps | 🟢 Done | - |
| M7 | View my reports | See list of issues I reported with current status | 🟢 Done | - |

## Quick Login Stories (demo and dev builds only)

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| M8 | As a tester on a demo or dev build of the app, I can pick a member account from a dropdown on the email login page, so that I am logged in as that member without typing | `DEMO_ACCOUNTS` from `--dart-define-from-file` shows a Quick login dropdown above the form on `EmailLoginPage` ǀ Options under Member and Ground admin, each "<Role> · <name>" ǀ Picking fills email and password and submits; first-login steps follow ǀ A failed quick login shows the normal error banner ǀ No define: no dropdown ǀ ARB strings; Widgetbook use-case and goldens; format, analyze, tests, debug APK pass ǀ Matches the approved canvas | 🔴 Pending | [#209](https://github.com/ossewawiel/munserv/issues/209) |

**Note:** M1 changed from phone+OTP to email+password. Registration now happens on web (W8).

## Status Legend
- 🟢 Done
- 🟡 In Progress
- 🔴 Pending

## Stack
Flutter 3.x + Riverpod + Freezed + Material Design 3
