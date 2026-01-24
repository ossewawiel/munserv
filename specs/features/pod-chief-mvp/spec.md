# Feature: pod-chief-mvp

**Goal:** Complete web portal MVP for Pod Chief role with navigation, dashboard, administrator management, messages, and settings.
**Platforms:** web, backend
**Status:** 🟡 In Progress
**Milestone:** [pod-chief-mvp](https://github.com/ossewawiel/munserv/milestone/1)

## Original Requirements

The MVP menu for a Pod Chief should consist of Dashboard, Pod Administrators, Reports, Messages and Pod Settings.

**Dashboard:**
- If the pod is not yet set up or not completely set up yet, the Dashboard will consist of Banners describing the tasks to be done and settings that still need to be specified.
- If set up, the Dashboard will contain the Pod Chief indicators and widgets.

**Ward/Sector Dashboards:**
- A second menu item will be available called 'Ward Dashboards' or 'Sector Dashboards' (depending on pod config).
- This is a submenu header with entries for each configured ward/sector.
- Shows the same dashboard widgets filtered by specific ward/sector.

**Pod Administrators:**
- Only visible once Pod setup is completed (wards/sectors must exist).
- Table list of all administrators with name, contact, ward/sector assignment, and actions column.
- Add button for new administrators.
- For MVP: no filtering/searching yet, but prepare UI for search input, column sorting, and filter slide-in panel (disabled).
- To add an administrator: email, name, surname, ward/sector selection required.
- New admin receives welcome email with temp password.
- On first login: change password, fill required profile info, receive welcome message with tasks.

**Reports:**
- Empty for MVP but structure in place.
- Submenu: Pod reports + ward/sector-specific entries.
- Each clicks to a tabbed table page.

**Messages:**
- System messages for the Pod Chief.

**Pod Settings:**
- Pod name: appears in header as "Munserv Pod [name]" with Munserv icon (orange on background).
- Logo upload.
- Pod boundaries on map: placeholder only for MVP.
- Ward/sector boundaries: placeholder only for MVP.

## Stories

### Backend

| ID | Title | Issue | Enables |
|----|-------|-------|---------|
| B1 | Pod setup status and settings API | [#33](https://github.com/ossewawiel/munserv/issues/33) | W11, W18, W19 |
| B2 | Pod dashboard statistics API | [#34](https://github.com/ossewawiel/munserv/issues/34) | W12, W13 |
| B3 | Pod administrators management API | [#35](https://github.com/ossewawiel/munserv/issues/35) | W14, W15 |
| B4 | Administrator onboarding API | [#36](https://github.com/ossewawiel/munserv/issues/36) | W16 |

### Web

| ID | Title | Issue | Depends On |
|----|-------|-------|------------|
| W10 | Role-specific navigation menu | [#21](https://github.com/ossewawiel/munserv/issues/21) | - |
| W11 | Setup task banners | [#22](https://github.com/ossewawiel/munserv/issues/22) | B1 |
| W12 | Dashboard widgets | [#23](https://github.com/ossewawiel/munserv/issues/23) | B2 |
| W13 | Ward/sector dashboards | [#24](https://github.com/ossewawiel/munserv/issues/24) | B2 |
| W14 | Pod administrators table | [#25](https://github.com/ossewawiel/munserv/issues/25) | B3, W21 |
| W15 | Add pod administrator | [#26](https://github.com/ossewawiel/munserv/issues/26) | B3 |
| W16 | Administrator onboarding | [#27](https://github.com/ossewawiel/munserv/issues/27) | B4 |
| W17 | System messages | [#28](https://github.com/ossewawiel/munserv/issues/28) | - |
| W18 | Pod name and logo | [#29](https://github.com/ossewawiel/munserv/issues/29) | B1 |
| W19 | Boundary placeholder | [#30](https://github.com/ossewawiel/munserv/issues/30) | - |
| W20 | Reports menu structure | [#31](https://github.com/ossewawiel/munserv/issues/31) | - |
| W21 | Generic data table component | [#32](https://github.com/ossewawiel/munserv/issues/32) | - |

## Dependencies

- Role hierarchy must support Pod Chief role
- Pod entity with setup status tracking
- Ward/Sector entities must exist for conditional features

## API Endpoints Needed

- `GET /pod/status` - Get pod setup status
- `GET /pod/settings` - Get pod settings
- `PATCH /pod/settings` - Update pod settings (name, logo)
- `GET /pod/administrators` - List pod administrators
- `POST /pod/administrators` - Create pod administrator
- `GET /pod/dashboard` - Pod-level dashboard stats
- `GET /wards/{id}/dashboard` or `GET /sectors/{id}/dashboard` - Ward/sector stats
- Administrator onboarding endpoints

## Notes

- Generic table component (W21) should be built first as it's used by W14 and reports
- Boundary mapping (W19) is placeholder only - no actual implementation for MVP
- "Ward" vs "Sector" terminology adapts based on pod configuration
- Administrator invitation flow similar to existing member invitation patterns
