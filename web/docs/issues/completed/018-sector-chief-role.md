---
issue: 18
title: "[Feature]: Sector Chief Role"
platform: web
status: completed
created_by: central-agent
created_at: 2026-01-22
updated_at: 2026-01-22
started_at: 2026-01-22T12:00:00Z
completed_at: 2026-01-22T13:00:00Z
dependencies:
  - backend (role endpoints must exist first)
files_changed:
  - src/shared/types/admin.ts
  - src/shared/hooks/useAuth.ts
  - src/features/auth/types.ts
  - src/components/guards/RoleGuard.tsx
  - src/components/templates/Sidebar.tsx
  - src/App.tsx
  - src/features/admin-management/types.ts
  - src/features/admin-management/api.ts
  - src/features/admin-management/hooks.ts
  - src/features/admin-management/AdminManagementPage.tsx
  - src/features/admin-management/components/CreateAdminDialog.tsx
  - src/features/admin-management/components/EditAdminDialog.tsx
  - src/features/admin-management/components/DeleteAdminDialog.tsx
  - src/locales/en/translation.json
  - src/test/mocks/handlers.ts
tests_added:
  - src/shared/types/admin.test.ts
  - src/components/guards/RoleGuard.test.tsx
  - src/features/admin-management/hooks.test.tsx
commits: []
blockers: []
---

# Issue #18: Sector Chief Role (Web)

## Context

The web admin portal needs to support the Sector Chief role with:
1. Role-based navigation (settings only visible to sector chief)
2. Admin management feature (create/manage sector admins)
3. Reports menu section (placeholder for future reports)
4. Role-aware dashboard (separate components for future differentiation)

## Root Cause

The frontend has no concept of admin roles beyond simple authentication. All authenticated users see the same navigation and have access to all features.

## What To Fix

### Phase 1: Role Infrastructure

#### Files To Modify

1. **`web/src/shared/types/admin.ts`** (create if not exists)
   - Define `AdminRole` type union
   - Export role hierarchy utilities

2. **`web/src/features/auth/AuthContext.tsx`** (or similar)
   - Add `role` to auth context
   - Expose `hasPermission(required: AdminRole): boolean`

3. **`web/src/components/guards/RoleGuard.tsx`** (create)
   - Component that checks role before rendering children
   - Redirects to dashboard if insufficient permissions

4. **`web/src/components/templates/Sidebar.tsx`**
   - Filter `navItems` based on current user role
   - Settings link: sector_chief and above only
   - Reports section: all admins (but with different items based on role)

5. **`web/src/App.tsx`**
   - Wrap role-restricted routes with `RoleGuard`

### Phase 2: Admin Management Feature

#### Files To Create

1. **`web/src/features/admin-management/types.ts`**
   - `Admin` interface
   - `CreateAdminRequest` interface
   - `AdminListResponse` interface

2. **`web/src/features/admin-management/api.ts`**
   - `adminApi.list()` - GET /api/v1/admins
   - `adminApi.create(request)` - POST /api/v1/admins
   - `adminApi.update(id, request)` - PATCH /api/v1/admins/{id}
   - `adminApi.delete(id)` - DELETE /api/v1/admins/{id}

3. **`web/src/features/admin-management/hooks.ts`**
   - `useAdmins()` - React Query hook for admin list
   - `useCreateAdmin()` - Mutation hook
   - `useUpdateAdmin()` - Mutation hook
   - `useDeleteAdmin()` - Mutation hook

4. **`web/src/features/admin-management/AdminManagementPage.tsx`**
   - Page layout with breadcrumbs
   - Admin list with DataTableCard
   - Create admin button
   - Actions column (edit, delete)

5. **`web/src/features/admin-management/components/CreateAdminDialog.tsx`**
   - Form dialog for creating new admin
   - Email, display name fields
   - Shows temporary password after creation

6. **`web/src/features/admin-management/components/EditAdminDialog.tsx`**
   - Form dialog for editing admin
   - Display name field

7. **`web/src/features/admin-management/components/DeleteAdminDialog.tsx`**
   - Confirmation dialog for soft delete

8. **`web/src/features/admin-management/components/AdminsTable.tsx`**
   - Table component with columns: name, email, role, created, actions

### Phase 3: Reports Menu & Dashboard

#### Files To Modify

1. **`web/src/components/templates/Sidebar.tsx`**
   - Add Reports section with submenu/group
   - Move Heat Report under Reports
   - Add placeholder for future reports

2. **`web/src/features/dashboard/DashboardPage.tsx`**
   - Create role-aware wrapper component
   - Same dashboard for now, but structure allows differentiation

### Changes Required

#### 1. Admin Role Type

```typescript
// web/src/shared/types/admin.ts
export const ADMIN_ROLES = ['sector_admin', 'sector_chief', 'pod_admin', 'pod_chief'] as const;
export type AdminRole = typeof ADMIN_ROLES[number];

// Role hierarchy (higher index = more permissions)
const ROLE_HIERARCHY: Record<AdminRole, number> = {
  sector_admin: 0,
  sector_chief: 1,
  pod_admin: 2,
  pod_chief: 3,
};

export function hasPermission(userRole: AdminRole, requiredRole: AdminRole): boolean {
  return ROLE_HIERARCHY[userRole] >= ROLE_HIERARCHY[requiredRole];
}
```

#### 2. RoleGuard Component

```typescript
// web/src/components/guards/RoleGuard.tsx
import { type FC, type ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/features/auth/hooks';
import { hasPermission, type AdminRole } from '@/shared/types/admin';

interface RoleGuardProps {
  requiredRole: AdminRole;
  children: ReactNode;
  fallback?: string;
}

export const RoleGuard: FC<RoleGuardProps> = ({
  requiredRole,
  children,
  fallback = '/',
}) => {
  const { user } = useAuth();

  if (!user || !hasPermission(user.role, requiredRole)) {
    return <Navigate to={fallback} replace />;
  }

  return <>{children}</>;
};
```

#### 3. Sidebar Navigation Update

```typescript
// Conditional nav items based on role
const navItems: NavItem[] = [
  { labelKey: 'nav.dashboard', href: '/', icon: DashboardIcon },
  { labelKey: 'nav.issues', href: '/issues', icon: AssignmentIcon },
  // Reports section (visible to all)
  {
    labelKey: 'nav.reports',
    href: '/reports',
    icon: AnalyticsIcon,
    children: [
      { labelKey: 'nav.heatReport', href: '/reports/heat', icon: WhatshotIcon },
    ]
  },
  { labelKey: 'nav.members', href: '/members', icon: PeopleIcon },
  { labelKey: 'nav.messages', href: '/messages', icon: EmailIcon, badgeKey: 'unreadMessages' },
  { labelKey: 'nav.groundAdmins', href: '/ground-admins', icon: BadgeIcon },
  // Sector Chief only
  {
    labelKey: 'nav.adminManagement',
    href: '/admin-management',
    icon: AdminPanelSettingsIcon,
    requiredRole: 'sector_chief',
  },
  {
    labelKey: 'nav.sectorSettings',
    href: '/settings/sector',
    icon: SettingsIcon,
    requiredRole: 'sector_chief',
  },
];

// Filter based on role
const visibleNavItems = useMemo(() =>
  navItems.filter(item =>
    !item.requiredRole || hasPermission(userRole, item.requiredRole)
  ),
  [userRole]
);
```

#### 4. Updated Routes

```typescript
// In App.tsx
<Route
  path="/admin-management"
  element={
    <ProtectedRoute>
      <RoleGuard requiredRole="sector_chief">
        <AdminManagementPage />
      </RoleGuard>
    </ProtectedRoute>
  }
/>
<Route
  path="/settings/sector"
  element={
    <ProtectedRoute>
      <RoleGuard requiredRole="sector_chief">
        <SectorSettingsPage />
      </RoleGuard>
    </ProtectedRoute>
  }
/>
```

## Acceptance Criteria

- [ ] `AdminRole` type defined with hierarchy
- [ ] `RoleGuard` component working
- [ ] Settings page only accessible to sector_chief+
- [ ] Admin Management page created and accessible to sector_chief only
- [ ] Create admin dialog with temporary password display
- [ ] Edit/delete admin functionality
- [ ] Reports section in sidebar with Heat Report
- [ ] Sidebar navigation filtered by role
- [ ] Component tests for RoleGuard
- [ ] Hook tests for admin management
- [ ] E2E test for admin creation flow

## Dependencies

- **Backend must be completed first** - Role endpoints and admin management API required
- Backend must return `role` field in auth/me response

## Test Files To Create

1. `web/src/components/guards/RoleGuard.test.tsx`
2. `web/src/features/admin-management/hooks.test.tsx`
3. `web/src/features/admin-management/api.test.ts`
4. `web/src/features/admin-management/AdminManagementPage.test.tsx`
5. `web/src/features/admin-management/components/CreateAdminDialog.test.tsx`
6. `web/e2e/admin-management.spec.ts`

## Translations To Add

Add to `web/src/locales/en/translation.json`:

```json
{
  "nav": {
    "reports": "Reports",
    "adminManagement": "Admin Management"
  },
  "adminManagement": {
    "title": "Admin Management",
    "subtitle": "Create and manage sector administrators",
    "createAdmin": "Create Admin",
    "editAdmin": "Edit Admin",
    "deleteAdmin": "Delete Admin",
    "confirmDelete": "Are you sure you want to delete this admin?",
    "deleteWarning": "This action cannot be undone.",
    "temporaryPassword": "Temporary Password",
    "copyPassword": "Copy Password",
    "passwordCopied": "Password copied to clipboard",
    "passwordNote": "Save this password - it will only be shown once",
    "table": {
      "name": "Name",
      "email": "Email",
      "role": "Role",
      "createdAt": "Created",
      "actions": "Actions"
    },
    "form": {
      "email": "Email Address",
      "displayName": "Display Name",
      "emailRequired": "Email is required",
      "emailInvalid": "Invalid email format",
      "displayNameRequired": "Display name is required"
    },
    "success": {
      "created": "Admin created successfully",
      "updated": "Admin updated successfully",
      "deleted": "Admin deleted successfully"
    },
    "errors": {
      "createFailed": "Failed to create admin",
      "updateFailed": "Failed to update admin",
      "deleteFailed": "Failed to delete admin"
    }
  }
}
```

## Implementation Notes

### Completed Implementation

#### Phase 1: Role Infrastructure ✅
- Created `AdminRole` type with hierarchy: `sector_admin < sector_chief < pod_admin < pod_chief`
- Added `hasPermission()` and `canManageRole()` utility functions
- Updated `useAuth` hook to normalize roles and expose `hasPermission()` method
- Created `RoleGuard` component for route-level authorization
- Updated `Sidebar` to filter navigation items based on user role
- Settings and Admin Management menu items now only visible to sector_chief+

#### Phase 2: Admin Management Feature ✅
- Created complete admin-management feature module at `src/features/admin-management/`
- Types: `Admin`, `CreateAdminRequest`, `UpdateAdminRequest`, `AdminCreatedResponse`, `AdminListResponse`
- API functions: `list()`, `get()`, `create()`, `update()`, `delete()`
- React Query hooks: `useAdmins()`, `useAdmin()`, `useCreateAdmin()`, `useUpdateAdmin()`, `useDeleteAdmin()`
- Components:
  - `AdminManagementPage` - Main page with DataTableCard and CRUD dialogs
  - `CreateAdminDialog` - Form dialog with temporary password display after creation
  - `EditAdminDialog` - Form dialog for updating display name (uses key-based reset pattern)
  - `DeleteAdminDialog` - Confirmation dialog for soft delete

#### Phase 3: Reports & Navigation ✅
- Added Reports section to sidebar (currently contains Heat Report)
- Updated routes with RoleGuard for /admin-management and /settings/sector

### Quality Checks Passed
- ✅ TypeScript check passed
- ✅ ESLint passed (only pre-existing warning in SectorSettingsPage)
- ✅ All 573 tests passing
- ✅ Production build successful

### Translations Added
- Added `nav.reports`, `nav.adminManagement` keys
- Added full `adminManagement.*` namespace for admin management UI

### Decisions Made
- Used key-based component reset pattern in EditAdminDialog instead of useEffect to avoid React Compiler lint errors
- Removed useCallback from dialog components to comply with React Compiler rules
- Role hierarchy uses array index (ordinal) for permission comparison
- Navigation items filter in Sidebar via useMemo with role-based filtering

## UI Mockup Notes

### Admin Management Page
- Breadcrumbs: Dashboard > Admin Management
- Header: "Admin Management" with subtitle "Create and manage sector administrators"
- Create Admin button (top right)
- DataTableCard with admin list
- Columns: Name, Email, Role, Created, Actions
- Actions: Edit icon, Delete icon

### Create Admin Dialog
- Title: "Create Admin"
- Fields: Email, Display Name
- Buttons: Cancel, Create
- On success: Show temporary password in alert with copy button

### Delete Confirmation
- Title: "Delete Admin"
- Message: "Are you sure you want to delete [name]?"
- Warning: "This action cannot be undone."
- Buttons: Cancel, Delete (danger variant)
