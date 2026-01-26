# Handoff: Web - W26 Pod Chief Change Password

**GitHub Issue:** [#41](https://github.com/ossewawiel/munserv/issues/41)
**Story:** W26 - Pod Chief must change password on first login
**Milestone:** pod-chief-bootstrap

## Summary

Implement the change password page for Pod Chief onboarding. When a Pod Chief logs in with their temporary password, they must change it before accessing the dashboard. The backend API (`/api/v1/admin/onboarding/change-password`) already exists.

## Prerequisites

- [x] Backend onboarding API implemented (`OnboardingController`, `OnboardingService`)
- [x] Login redirect logic exists in `LoginPage.tsx` (redirects to `/onboarding/change-password` when `onboardingStatus === 'pending'`)
- [x] Translation keys exist in `translation.json` under `onboarding.*`

## Acceptance Criteria

- [x] Redirect to change password page after login with temp password
- [x] Cannot skip or access dashboard until password changed
- [x] Password validated against requirements (8+ chars, upper, lower, number)
- [x] Onboarding status changes to PASSWORD_CHANGED
- [x] Clear feedback on validation errors

## Files to Create

| File | Purpose |
|------|---------|
| `web/src/features/onboarding/ChangePasswordPage.tsx` | Main page component |
| `web/src/features/onboarding/components/ChangePasswordForm.tsx` | Form component with validation |
| `web/src/features/onboarding/components/PasswordRequirements.tsx` | Requirements checklist |
| `web/src/features/onboarding/api.ts` | API functions for onboarding |
| `web/src/features/onboarding/hooks.ts` | React Query hooks |
| `web/src/features/onboarding/types.ts` | TypeScript types |
| `web/src/features/onboarding/index.ts` | Public exports |

## Files to Modify

| File | Change |
|------|--------|
| `web/src/App.tsx` | Add `/onboarding/change-password` route |
| `web/src/components/guards/ProtectedRoute.tsx` | Check onboarding status and redirect if pending |

## Implementation Steps

### 1. Create Feature Types (`types.ts`)

```typescript
export interface OnboardingStatusResponse {
  status: 'pending' | 'password_changed' | 'profile_complete' | 'active';
  requiresPasswordChange: boolean;
  requiresProfileCompletion: boolean;
  isOnboarded: boolean;
  displayName: string;
}

export interface ChangePasswordRequest {
  newPassword: string;
}

export interface CompleteProfileRequest {
  displayName?: string;
}
```

### 2. Create API Layer (`api.ts`)

```typescript
import { apiClient } from '@/lib/api-client';
import type { OnboardingStatusResponse, ChangePasswordRequest, CompleteProfileRequest } from './types';

export const onboardingApi = {
  getStatus: () =>
    apiClient.get<OnboardingStatusResponse>('/admin/onboarding/status').then((r) => r.data),

  changePassword: (data: ChangePasswordRequest) =>
    apiClient.post<OnboardingStatusResponse>('/admin/onboarding/change-password', data).then((r) => r.data),

  completeProfile: (data: CompleteProfileRequest) =>
    apiClient.post<OnboardingStatusResponse>('/admin/onboarding/complete-profile', data).then((r) => r.data),
};
```

### 3. Create Hooks (`hooks.ts`)

```typescript
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { onboardingApi } from './api';

export const onboardingKeys = {
  all: ['onboarding'] as const,
  status: () => [...onboardingKeys.all, 'status'] as const,
};

export function useOnboardingStatus() {
  return useQuery({
    queryKey: onboardingKeys.status(),
    queryFn: onboardingApi.getStatus,
  });
}

export function useChangePassword() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: onboardingApi.changePassword,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: onboardingKeys.status() });
    },
  });
}
```

### 4. Create PasswordRequirements Component

Shows real-time validation feedback:
- Minimum 8 characters ✓/✗
- At least one uppercase letter ✓/✗
- At least one lowercase letter ✓/✗
- At least one number ✓/✗

Use check/x icons with green/gray colors.

### 5. Create ChangePasswordForm Component

- Password field (with visibility toggle)
- Confirm password field
- PasswordRequirements checklist
- Submit button (disabled until all requirements met)
- Form validation with React Hook Form + Zod

### 6. Create ChangePasswordPage

- Uses `AuthLayout` (same as login)
- Title: "Change Password"
- Description explaining requirement
- ChangePasswordForm
- On success: redirect to `/onboarding/complete-profile` OR `/` (dashboard)

### 7. Update ProtectedRoute

Add onboarding status check:
```typescript
const { admin } = useAuth();

// If admin needs password change, redirect
if (admin?.onboardingStatus === 'pending') {
  return <Navigate to="/onboarding/change-password" replace />;
}

// If admin needs profile completion, redirect
if (admin?.onboardingStatus === 'password_changed') {
  return <Navigate to="/onboarding/complete-profile" replace />;
}
```

### 8. Add Route in App.tsx

```typescript
import { ChangePasswordPage } from '@/features/onboarding/ChangePasswordPage';

// In Routes:
<Route path="/onboarding/change-password" element={<ChangePasswordPage />} />
```

## Password Validation Rules

Match backend validation in `OnboardingService.kt`:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit

## Error Handling

| Scenario | Handling |
|----------|----------|
| Network error | Show generic error toast |
| 400 validation_error | Show validation message from API |
| 400 invalid_step | Redirect to appropriate page |
| 401 unauthorized | Redirect to login |

## Tests Required

- [x] `ChangePasswordForm.test.tsx` - Form validation, submission
- [x] `PasswordRequirements.test.tsx` - Requirements checking
- [x] `hooks.test.ts` - API integration with MSW

## Definition of Done

- [x] Page renders at `/onboarding/change-password`
- [x] Cannot access dashboard without changing password
- [x] Password requirements shown with real-time validation
- [x] Passwords must match before submit enabled
- [x] API called on submit
- [x] On success, redirects to profile completion or dashboard
- [x] On error, shows clear message
- [x] All tests passing
- [x] No TypeScript errors
- [x] Translations used (no hardcoded strings)
- [x] Follows MUI styling (no Tailwind)

## Related Files for Reference

- `web/src/features/auth/LoginPage.tsx` - Similar page structure
- `web/src/components/molecules/LoginForm.tsx` - Form pattern
- `web/src/components/templates/AuthLayout.tsx` - Layout to use
- `backend/src/main/kotlin/com/munserv/admin/api/OnboardingController.kt` - API contract
- `backend/src/main/kotlin/com/munserv/admin/service/OnboardingService.kt` - Validation rules
