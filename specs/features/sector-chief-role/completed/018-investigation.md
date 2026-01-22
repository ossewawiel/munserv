# Investigation: Sector Chief Role

**Issue:** #18
**Date:** 2026-01-22
**Platforms:** Database, Backend, Web

## Problem Statement

The Sector Chief role is partially defined in the system but not fully implemented. The role exists in the database enum but:
- The Kotlin domain only recognizes `SECTOR_ADMIN` and `SUPER_ADMIN`
- No role-based access control differentiates sector chief from sector admin
- Dashboard is not role-aware (same for all admin types)
- Settings are accessible to all admins, not just sector chiefs
- No admin management functionality exists (sector chief should create/manage sector admins)
- No reports menu infrastructure exists

## Investigation Steps

### 1. Database Layer
- **Checked:** `admin_role` enum already includes `sector_chief`
- **Current values:** `{sector_admin,sector_chief,pod_admin,pod_chief}`
- **Migration file:** `V002__create_enums.sql`
- **Table:** `admins` table uses `admin_role` enum for the `role` column

### 2. Backend Layer
- **Found:** `AdminRole` enum in `Admin.kt` only has `SECTOR_ADMIN` and `SUPER_ADMIN`
- **Missing:** `SECTOR_CHIEF` not mapped in Kotlin domain
- **Settings Controller:** `SectorSettingsController.kt` has no role-based authorization
- **Ground Admin Feature Spec:** Already documents role hierarchy with sector chief

### 3. Web Layer
- **Found:** `SectorSettingsPage` exists but has no role guard
- **Found:** Sidebar shows Settings link to all admins
- **Missing:** Role-based route guards
- **Missing:** Admin management feature
- **Missing:** Reports menu section

### 4. Existing Architecture

From `specs/features/ground-admin-messaging/spec.md`:
```
Pod Chief
└── Pod Admin
    └── Sector Chief        ← Setup, settings, creates admins
        └── Sector Admin    ← Day-to-day operations
            └── Ground Admin ← Flag on member
                └── Member
```

## Root Cause

The `sector_chief` role was added to the database enum during initial design but never fully implemented in the application layers. The feature was partially documented in the Ground Admin spec but deferred.

## Affected Components

### Database
- No schema changes required (enum already has `sector_chief`)

### Backend
- `backend/src/main/kotlin/com/munserv/admin/domain/Admin.kt` - Add `SECTOR_CHIEF` to enum
- `backend/src/main/kotlin/com/munserv/admin/repository/AdminEntity.kt` - Update mapping
- `backend/src/main/kotlin/com/munserv/shared/security/` - Add role-based authorization
- `backend/src/main/kotlin/com/munserv/admin/service/` - Add admin management service
- `backend/src/main/kotlin/com/munserv/admin/api/` - Add admin management endpoints
- `backend/src/main/kotlin/com/munserv/sectors/api/SectorSettingsController.kt` - Add role guard

### Web
- `web/src/shared/types/admin.ts` - Add `sector_chief` role type
- `web/src/features/auth/` - Expose role in auth context
- `web/src/components/guards/` - Add role-based route guards
- `web/src/components/templates/Sidebar.tsx` - Role-conditional navigation
- `web/src/features/admin-management/` - New feature for creating/managing sector admins
- `web/src/features/reports/` - New reports menu infrastructure
- `web/src/features/dashboard/` - Role-aware dashboard components

## Feature Requirements

### From Issue #18 Acceptance Criteria

1. **Sector Settings Access** (Sector Chief only)
   - View and modify sector settings
   - Already implemented in UI, needs role guard

2. **Admin Management** (Sector Chief only)
   - Create sector admins
   - Manage sector admin access (activate/suspend/delete)
   - New feature module required

3. **Reports Menu**
   - Reports section in sidebar
   - Placeholder for future reports
   - Heat Report already exists, can be moved under Reports

4. **Role-Aware Dashboard**
   - Separate dashboard components for sector chief vs sector admin
   - Same structure initially but decoupled for future differentiation

5. **Full Sector Admin Capabilities**
   - Sector chief inherits all sector admin functionality
   - Role hierarchy: sector_chief > sector_admin

## Implementation Approach

### Phase 1: Backend - Role Infrastructure
1. Update `AdminRole` enum with proper hierarchy
2. Add role-based authorization annotations
3. Create permission hierarchy (sector_chief includes sector_admin permissions)
4. Guard settings endpoints for sector_chief+

### Phase 2: Backend - Admin Management
1. Create admin management service
2. Add endpoints: create/list/update/delete sector admins
3. Sector chief can only manage admins in their sector

### Phase 3: Web - Role Infrastructure
1. Add role to auth context
2. Create role-based route guard component
3. Update Sidebar with conditional navigation

### Phase 4: Web - Admin Management Feature
1. Create admin management page
2. Create admin list/form components
3. Add to sidebar (sector chief only)

### Phase 5: Web - Dashboard & Reports
1. Create role-aware dashboard wrapper
2. Add Reports menu section to sidebar
3. Move Heat Report under Reports

## Dependencies

- No cross-platform dependencies (backend and web can be developed in parallel after Phase 1)
- Database is already prepared

## Test Strategy

### Backend
- Unit tests for `AdminRole` hierarchy
- Integration tests for role-based endpoint access
- Admin management service tests

### Web
- Component tests for role guards
- Hook tests for role-based queries
- E2E tests for admin management workflow

## Open Questions

1. **Dashboard differentiation:** What specific metrics/cards should sector chief see that sector admin doesn't? (Issue says "keep same for now, separate for future")
2. **Report types:** What reports should be available initially? (Issue says "not yet known")
3. **Password policy:** When sector chief creates admin, what's the initial password flow?

## Recommendation

Proceed with implementation. The database is ready, and the architecture is well-documented. Start with backend role infrastructure, then web role infrastructure, finally the admin management feature.
