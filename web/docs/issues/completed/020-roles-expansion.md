---
issue: 20
title: "Adding the Rest of the Roles"
platform: web
status: completed
created_by: central-agent
created_at: 2026-01-23
updated_at: 2026-01-23
dependencies:
  - backend (completed)
files_changed:
  - web/src/shared/types/admin.ts
  - web/src/components/templates/Sidebar.tsx
  - web/src/locales/en/translation.json
  - web/src/App.tsx
tests_added: []
commits: []
blockers: []
---

# Issue #20: Adding the Rest of the Roles (Web)

## Status: COMPLETED

## Implementation Summary

### Type System Changes

1. **admin.ts**
   - Added `ward_admin`, `ward_chief` to `ADMIN_ROLES`
   - Updated `ROLE_HIERARCHY` with new ordinals (0-5)
   - Added `AdminLevel` type ('sector' | 'ward' | 'pod')
   - Added `ROLE_LEVEL` mapping
   - Added `ADMIN_ROLE_LABELS` for new roles
   - Added helper functions:
     - `getRoleLevel()` - Get organizational level for a role
     - `isChiefRole()` - Check if role is a chief/supervisor
     - `getManageableRoles()` - Get roles a user can manage

### Navigation Changes

2. **Sidebar.tsx**
   - Added nav item for Ward Settings (`/settings/ward`, requires `ward_chief`)
   - Added nav item for Pod Settings (`/settings/pod`, requires `pod_chief`)

### Localization Changes

3. **translation.json**
   - Added `nav.wardSettings`: "Ward Settings"
   - Added `nav.podSettings`: "Pod Settings"
   - Updated `nav.sectorSettings`: "Sector Settings"

### Routing Changes

4. **App.tsx**
   - Added `PlaceholderPage` component for coming-soon features
   - Added route `/settings/ward` with `RoleGuard` requiring `ward_chief`
   - Added route `/settings/pod` with `RoleGuard` requiring `pod_chief`

## Acceptance Criteria (All Met)

- [x] Role types include all 6 roles
- [x] Role hierarchy ordinals are correct
- [x] Sidebar shows correct menu items per role level
- [x] Ward/Pod settings routes are protected by role guards
- [x] TypeScript compiles successfully
- [x] Placeholder pages display for unimplemented features
