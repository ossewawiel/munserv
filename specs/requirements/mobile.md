# Mobile Requirements

## MVP Stories

| ID | Story | Acceptance Criteria | Status |
|----|-------|---------------------|--------|
| M1 | Login with email/password | Enter email + password → if first login: change password → setup PIN → access app | 🔴 Pending |
| M2 | Login with PIN/biometric | Enter PIN or use fingerprint → access app | 🟢 Done |
| M3 | View issues on map | See map centered on my sector with issue markers | 🟢 Done |
| M4 | View issue list | See list of issues, filter by type/state | 🟢 Done |
| M5 | Report new issue | Take photo → select type → confirm location → submit | 🟢 Done |
| M6 | View issue details | See photo(s), type, state, location, timestamps | 🟢 Done |
| M7 | View my reports | See list of issues I reported with current status | 🟢 Done |

**Note:** M1 changed from phone+OTP to email+password. Registration now happens on web (W8).

## Status Legend
- 🟢 Done
- 🟡 In Progress
- 🔴 Pending

## Stack
Flutter 3.x + Riverpod + Freezed + Material Design 3
