---
issue: 37
title: "Super user login to fresh pod"
platform: web
status: completed
created_by: central-agent
created_at: 2026-01-26T12:00:00Z
updated_at: 2026-01-26T12:30:00Z
dependencies:
  - backend-auth-super-user
files_changed:
  - src/features/auth/types.ts
  - src/features/auth/hooks.ts
  - src/features/auth/LoginPage.tsx
  - src/features/bootstrap/CreatePodChiefPage.tsx
  - src/App.tsx
  - src/shared/types/admin.ts
  - src/shared/hooks/useAuth.ts
  - src/shared/hooks/usePodSetup.ts
  - src/components/templates/Sidebar.tsx
  - src/locales/en/translation.json
  - src/features/dashboard/hooks.ts
  - src/features/issues/hooks.ts
  - src/features/members/hooks.ts
tests_added: []
commits: []
blockers: []
---

# Issue #37: Super User Login to Fresh Pod (Web)

## Context

This story enables a super user to log in to a fresh pod deployment using the **existing login page**. No separate bootstrap login page is needed. The backend returns a special response for super users, and the frontend routes them to `/bootstrap/create-pod-chief`.

## Architecture

**Single Login Page with Role-Based Routing:**
1. User enters credentials on existing `/login` page
2. Backend `AuthService.adminLogin()` checks super user credentials first
3. Returns response with `role: "SUPER_USER"` and `bootstrapStatus`
4. Frontend routes based on response:
   - `role: "SUPER_USER"` → `/bootstrap/create-pod-chief`
   - `role: *` with `onboardingStatus: "pending"` → `/onboarding/change-password`
   - `role: *` with `onboardingStatus: "active"` → `/`

## What To Fix

Modify the existing login page to handle super user responses with role-based routing.

### Files To Modify

1. **`src/features/auth/types.ts`** - Add new response fields
2. **`src/features/auth/LoginPage.tsx`** - Add role-based routing logic
3. **`src/App.tsx`** - Add route for `/bootstrap/create-pod-chief`
4. **`src/locales/en/translation.json`** - Add i18n keys (minimal for W22)

### Files To Create (Placeholder for W23)

1. **`src/features/bootstrap/CreatePodChiefPage.tsx`** - Placeholder page (full implementation is W23)

## Implementation Details

### 1. Update Auth Types (`src/features/auth/types.ts`)

```typescript
// Update AdminUser interface
export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  role: string;
  level: string;
  podId: string | null;
  wardId: string | null;
  sectorId: string | null;
  onboardingStatus: string | null;  // ADD THIS
}

// Update AdminProfile interface
export interface AdminProfile {
  admin: AdminUser;
  sector: AdminSector | null;
  bootstrapStatus?: string;  // ADD THIS - only set for super user
}
```

### 2. Modify Login Page (`src/features/auth/LoginPage.tsx`)

Add role-based routing after successful login:

```typescript
const handleLoginSuccess = (response: AdminLoginResponse) => {
  // Store tokens
  localStorage.setItem('accessToken', response.tokens.accessToken);
  localStorage.setItem('refreshToken', response.tokens.refreshToken);
  localStorage.setItem('admin', JSON.stringify(response.profile.admin));

  const { admin, bootstrapStatus } = response.profile;

  // Route based on role and status
  if (admin.role === 'SUPER_USER') {
    // Super user - go to create Pod Chief
    localStorage.setItem('isSuperUser', 'true');
    navigate('/bootstrap/create-pod-chief', { replace: true });
    return;
  }

  // Regular admin - check onboarding status
  if (admin.onboardingStatus === 'pending') {
    navigate('/onboarding/change-password', { replace: true });
    return;
  }

  if (admin.onboardingStatus === 'password_changed') {
    navigate('/onboarding/complete-profile', { replace: true });
    return;
  }

  // Fully onboarded - go to dashboard
  navigate('/', { replace: true });
};
```

### 3. Add Route (`src/App.tsx`)

```typescript
// Import placeholder page
import { CreatePodChiefPage } from '@/features/bootstrap/CreatePodChiefPage';

// Add route (before catch-all)
<Route path="/bootstrap/create-pod-chief" element={<CreatePodChiefPage />} />
```

### 4. Create Placeholder Page (`src/features/bootstrap/CreatePodChiefPage.tsx`)

```typescript
import { type FC } from 'react';
import { Navigate } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

import { AuthLayout } from '@/components/templates/AuthLayout';

/**
 * Placeholder for Create Pod Chief page.
 * Full implementation in W23.
 */
export const CreatePodChiefPage: FC = () => {
  // Check if user is super user
  const isSuperUser = localStorage.getItem('isSuperUser') === 'true';

  if (!isSuperUser) {
    return <Navigate to="/login" replace />;
  }

  return (
    <AuthLayout
      header="Create Pod Chief"
      subtitle="This page will be implemented in W23"
    >
      <Box sx={{ textAlign: 'center', py: 4 }}>
        <Typography variant="body1" color="text.secondary">
          Pod Chief creation form coming soon.
        </Typography>
      </Box>
    </AuthLayout>
  );
};

export default CreatePodChiefPage;
```

## Acceptance Criteria

- [ ] Login form accepts super user credentials (same as regular admin login)
- [ ] Backend validates against environment config (handled by backend)
- [ ] On success with `role: "SUPER_USER"`, stores `isSuperUser` flag in localStorage
- [ ] Redirects super user to `/bootstrap/create-pod-chief`
- [ ] Shows clear error message on invalid credentials (existing behavior)
- [ ] Super user blocked if pod is already bootstrapped (handled by backend returning InvalidCredentials)
- [ ] Placeholder page exists at `/bootstrap/create-pod-chief`
- [ ] Placeholder page redirects non-super-users to `/login`

## Dependencies

- **Backend:** Must modify `AuthService.adminLogin()` to support super user login
- Reference: `specs/features/pod-chief-bootstrap/backend-handoff.md` Phase 2
- Backend changes:
  - Add `SuperUserLoginSuccess` to `AuthResult`
  - Modify `adminLogin()` to check super user credentials first
  - Update `AuthController` response handling
  - Add `onboardingStatus` and `bootstrapStatus` to response DTOs

## Implementation Notes

### Changes Made

1. **Added SUPER_USER role support** (`src/shared/types/admin.ts`)
   - Added `SUPER_USER_ROLE` constant and `UserRole` type
   - Added `isAdminRole()` type guard to distinguish regular admins from super users

2. **Updated AdminUser interface** (`src/features/auth/types.ts`)
   - Changed `role` type from `AdminRole` to `UserRole` (includes SUPER_USER)
   - Made `sectorId` nullable (super users don't have a sector)
   - Added optional `onboardingStatus` and `level` fields

3. **Added role-based routing** (`src/features/auth/LoginPage.tsx`)
   - Added `getRedirectPath()` helper function
   - Routes SUPER_USER to `/bootstrap/create-pod-chief`
   - Routes admins with `onboardingStatus: 'pending'` to `/onboarding/change-password`
   - Routes admins with `onboardingStatus: 'password_changed'` to `/onboarding/complete-profile`

4. **Updated auth hooks** (`src/features/auth/hooks.ts`)
   - Added `isSuperUser` localStorage flag for super user sessions
   - Clear flag on logout

5. **Created placeholder page** (`src/features/bootstrap/CreatePodChiefPage.tsx`)
   - Checks `isSuperUser` flag, redirects non-super-users to login
   - Placeholder content for W23 implementation

6. **Updated useAuth hook** (`src/shared/hooks/useAuth.ts`)
   - Handle SUPER_USER role in `getStoredAdmin()`
   - Super users always pass permission checks in `hasPermission()`

7. **Updated Sidebar** (`src/components/templates/Sidebar.tsx`)
   - Added `checkPermission()` helper that handles super user case
   - Super users see pod-level navigation

8. **Fixed type issues** in hooks that use `sectorId`:
   - `src/features/dashboard/hooks.ts`
   - `src/features/issues/hooks.ts`
   - `src/features/members/hooks.ts`

9. **Added i18n keys** (`src/locales/en/translation.json`)
   - Bootstrap keys for W22/W23
   - Onboarding keys for W26/W27

### Decisions Made

- Super users have all permissions (bypass role hierarchy)
- Used `UserRole` union type to include SUPER_USER alongside AdminRole
- Added `isAdminRole()` type guard for safe role checking
- Placeholder page for CreatePodChief (full implementation in W23)

## Related Stories

- **W23** (Create Pod Chief) - Full implementation of `/bootstrap/create-pod-chief` page
- **W26** (Change Password) - Onboarding flow for new admins
- **W27** (Complete Profile) - Optional profile completion
