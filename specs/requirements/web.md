# Web Requirements

## MVP Stories

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| W1 | Login with email/password | Enter credentials → access dashboard | 🟢 Done | - |
| W2 | View dashboard | See summary stats: open issues, by type, by state | 🟢 Done | - |
| W3 | View issues list | See paginated list, filter by type/state, sort by heat | 🟢 Done | - |
| W4 | View issue details | See all info, photo(s), reporter (admin only), history | 🟢 Done | - |
| W5 | Change issue state | Select new state → add optional note → save | 🟢 Done | - |
| W6 | View heat report | See issues ranked by heat score | 🟢 Done | - |
| W7 | View members list | See sector members with status filter (all/pending/active/suspended) | 🟢 Done | - |
| W8 | Register as member | (Public) Fill form with name, email, phone, address, location → submit → pending status | 🔴 Pending | [#4](https://github.com/ossewawiel/munserv/issues/4) |
| W9 | Approve/reject member | Review pending registration → approve (sends email) or reject (deletes) | 🔴 Done | [#5](https://github.com/ossewawiel/munserv/issues/5) |

## Status Legend
- 🟢 Done
- 🟡 In Progress
- 🔴 Pending

## Stack
React 19 + TypeScript 5.9 + Vite 7 + Tailwind CSS 4 + React Query
