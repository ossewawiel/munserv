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
| W8 | Register as member | (Public) Fill form with name, email, phone, address, location → submit → pending status | 🟢 Done | [#4](https://github.com/ossewawiel/munserv/issues/4) |
| W9 | Approve/reject member | Review pending registration → approve (sends email) or reject (deletes) | 🟢 Done | [#5](https://github.com/ossewawiel/munserv/issues/5) |

## Pod Chief MVP Stories

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| W10 | As a Pod Chief, I can see a role-specific navigation menu | Menu shows: Dashboard, Pod Administrators (conditional), Reports, Messages, Pod Settings ǀ Ward/Sector Dashboards submenu appears after setup | 🟢 Done | [#21](https://github.com/ossewawiel/munserv/issues/21) |
| W11 | As a Pod Chief, I can see setup task banners when pod is incomplete | Banners describe remaining setup tasks ǀ Each banner links to relevant settings ǀ Banners disappear when task completed | 🟢 Done | [#22](https://github.com/ossewawiel/munserv/issues/22) |
| W12 | As a Pod Chief, I can see dashboard widgets when pod setup is complete | Shows Pod Chief indicators ǀ Summary stats for entire pod ǀ Key metrics visible | 🟢 Done | [#23](https://github.com/ossewawiel/munserv/issues/23) |
| W13 | As a Pod Chief, I can view ward/sector-specific dashboards | Submenu lists configured wards/sectors ǀ Dashboard shows same widgets filtered by ward/sector ǀ Label adapts to "Ward" or "Sector" based on pod config | 🟢 Done | [#24](https://github.com/ossewawiel/munserv/issues/24) |
| W14 | As a Pod Chief, I can view a table list of pod administrators | Shows name, contact, ward/sector assignment ǀ Actions column present ǀ Add button available ǀ Table prepared for search/sort/filter (disabled for MVP) | 🟢 Done | [#25](https://github.com/ossewawiel/munserv/issues/25) |
| W15 | As a Pod Chief, I can add a new pod administrator | Form: email, name, surname, ward/sector selection ǀ Sends welcome email with temp password ǀ New admin appears in list as pending | 🟢 Done | [#26](https://github.com/ossewawiel/munserv/issues/26) |
| W16 | As a Pod Administrator, I can complete onboarding after first login | Change temp password ǀ Fill required profile info ǀ Receive welcome message with initial tasks ǀ Redirected to dashboard | 🟢 Done | [#27](https://github.com/ossewawiel/munserv/issues/27) |
| W17 | As a Pod Chief, I can view system messages | Messages list displayed ǀ Mark as read ǀ Shows unread count in menu | 🔴 Pending | [#28](https://github.com/ossewawiel/munserv/issues/28) |
| W18 | As a Pod Chief, I can configure the pod name and logo | Set pod name ǀ Name appears in header as "Munserv Pod [name]" ǀ Upload logo ǀ Munserv icon shows in orange on background | 🔴 Pending | [#29](https://github.com/ossewawiel/munserv/issues/29) |
| W19 | As a Pod Chief, I can see placeholder for boundary configuration | Pod boundaries section visible but disabled ǀ Ward/sector boundaries section visible but disabled ǀ "Coming soon" indicator | 🔴 Pending | [#30](https://github.com/ossewawiel/munserv/issues/30) |
| W20 | As a Pod Chief, I can see the Reports menu structure | Pod reports submenu entry ǀ Ward/sector submenu entries ǀ Clicking goes to placeholder page with tabbed structure | 🔴 Pending | [#31](https://github.com/ossewawiel/munserv/issues/31) |
| W21 | As a developer, I can use a generic data table component | Supports column definitions ǀ Sort by columns (prepared) ǀ Search input (prepared) ǀ Filter slide-out panel (prepared) ǀ Actions column ǀ Add button slot | 🟢 Done | [#32](https://github.com/ossewawiel/munserv/issues/32) |

## Pod Chief Bootstrap Stories

| ID | Story | Acceptance Criteria | Status | Issue |
|----|-------|---------------------|--------|-------|
| W22 | As a super user, I can log in to a fresh pod | Login form accepts super user credentials ǀ Validates against env config ǀ Returns JWT with `role: super_user` ǀ Rate limited | 🟢 Done | [#37](https://github.com/ossewawiel/munserv/issues/37) |
| W23 | As a super user, I can create a Pod Chief | Form: email, display name ǀ Triggers welcome email with temp password ǀ Shows temp password in success dialog ǀ Pod Chief created with PENDING status | 🟢 Done | [#38](https://github.com/ossewawiel/munserv/issues/38) |
| W24 | As a super user, I cannot log in after Pod Chief is onboarded | Login denied with clear error ǀ Error message explains pod already bootstrapped ǀ Shows option to request temporary access | 🟢 Done | [#39](https://github.com/ossewawiel/munserv/issues/39) |
| W25 | As a Pod Chief, I receive email with temp password | Welcome email sent ǀ Contains login instructions ǀ Contains temp password ǀ Contains download/access link | 🟢 Done | [#40](https://github.com/ossewawiel/munserv/issues/40) |
| W26 | As a Pod Chief, I must change password on first login | Redirect to change password page ǀ Cannot skip or access dashboard ǀ Password validated against requirements ǀ Status changes to PASSWORD_CHANGED | 🟢 Done | [#41](https://github.com/ossewawiel/munserv/issues/41) |
| W27 | As a Pod Chief, I can complete optional profile info | Display name editable ǀ Known-as, contact, address fields optional ǀ Can skip to dashboard ǀ Status changes to ACTIVE when complete | 🟢 Done | [#42](https://github.com/ossewawiel/munserv/issues/42) |
| W28 | As a Pod Chief, I can grant super user temporary access | Located in Pod Settings > Support Access section ǀ Grant button opens dialog ǀ Select role (from manageable roles) ǀ Set purpose/reason ǀ Access auto-revokes after logout OR 1 hour inactivity ǀ Audit logged | 🟢 Done | [#43](https://github.com/ossewawiel/munserv/issues/43) |
| W29 | As a super user, I can use temporary access for debugging | Login with temp grant ǀ Role-limited access ǀ Session shows expiry timer ǀ Auto-logout on expiry ǀ All actions audit logged | 🔴 Pending | [#44](https://github.com/ossewawiel/munserv/issues/44) |
| W30 | As a Pod Chief, I can view/revoke active super user sessions | Located in Pod Settings > Support Access section ǀ See active sessions with role, granted time, last activity ǀ Manual revoke button ǀ Session history log | 🟢 Done | [#45](https://github.com/ossewawiel/munserv/issues/45) |

## Status Legend
- 🟢 Done
- 🟡 In Progress
- 🔴 Pending

## Stack
React 19 + TypeScript 5.9 + Vite 7 + MUI v7 + React Query
