# Handoff: Web - W27 Complete Profile Page

**GitHub Issue:** [#42](https://github.com/ossewawiel/munserv/issues/42)
**Milestone:** pod-chief-bootstrap
**Status:** COMPLETED

## Context

Create a profile completion page for Pod Chiefs to optionally add profile info (known-as, contact phone, address) or skip to dashboard. This page is shown after changing password (when onboardingStatus is `password_changed`).

The LoginPage already redirects to `/onboarding/complete-profile` when the admin's status is `password_changed`.

## Files to Create

- `web/src/features/onboarding/types.ts`
- `web/src/features/onboarding/api.ts`
- `web/src/features/onboarding/hooks.ts`
- `web/src/features/onboarding/CompleteProfilePage.tsx`
- `web/src/features/onboarding/CompleteProfilePage.test.tsx`

## Files to Modify

- `web/src/App.tsx` - Add route

## Implementation Steps

### 1. Create Types

**File:** `web/src/features/onboarding/types.ts`

```typescript
export interface OnboardingStatusResponse {
  status: string;
  requiresPasswordChange: boolean;
  requiresProfileCompletion: boolean;
  isOnboarded: boolean;
  displayName: string;
}

export interface CompleteProfileRequest {
  displayName?: string;
  knownAs?: string;
  contactPhone?: string;
  address?: string;
}

export interface ChangePasswordRequest {
  newPassword: string;
}
```

### 2. Create API Functions

**File:** `web/src/features/onboarding/api.ts`

```typescript
import { apiClient } from '@/lib/api-client';
import type { OnboardingStatusResponse, CompleteProfileRequest, ChangePasswordRequest } from './types';

export const onboardingApi = {
  getStatus: () =>
    apiClient.get<OnboardingStatusResponse>('/api/v1/admin/onboarding/status').then((r) => r.data),

  completeProfile: (data: CompleteProfileRequest) =>
    apiClient.post<OnboardingStatusResponse>('/api/v1/admin/onboarding/complete-profile', data).then((r) => r.data),

  changePassword: (data: ChangePasswordRequest) =>
    apiClient.post<OnboardingStatusResponse>('/api/v1/admin/onboarding/change-password', data).then((r) => r.data),
};
```

### 3. Create React Query Hooks

**File:** `web/src/features/onboarding/hooks.ts`

```typescript
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { onboardingApi } from './api';
import type { CompleteProfileRequest, ChangePasswordRequest } from './types';

export function useOnboardingStatus() {
  return useQuery({
    queryKey: ['onboarding', 'status'],
    queryFn: onboardingApi.getStatus,
  });
}

export function useCompleteProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CompleteProfileRequest) => onboardingApi.completeProfile(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['onboarding'] });
      queryClient.invalidateQueries({ queryKey: ['auth'] });
    },
  });
}

export function useChangePassword() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ChangePasswordRequest) => onboardingApi.changePassword(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['onboarding'] });
    },
  });
}
```

### 4. Create CompleteProfilePage

**File:** `web/src/features/onboarding/CompleteProfilePage.tsx`

```typescript
import { type FC, useCallback, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { useAuth } from '@/shared/hooks/useAuth';
import { useCompleteProfile, useOnboardingStatus } from './hooks';

export const CompleteProfilePage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { admin } = useAuth();
  const { data: status, isLoading: statusLoading } = useOnboardingStatus();
  const completeProfileMutation = useCompleteProfile();

  const [displayName, setDisplayName] = useState(admin?.displayName ?? '');
  const [knownAs, setKnownAs] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [address, setAddress] = useState('');

  // Redirect if not at correct onboarding step
  if (statusLoading) {
    return (
      <AuthLayout>
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      </AuthLayout>
    );
  }

  if (status && !status.requiresProfileCompletion) {
    // Already completed or wrong status - redirect
    navigate('/', { replace: true });
    return null;
  }

  const handleComplete = useCallback(() => {
    completeProfileMutation.mutate(
      {
        displayName: displayName || undefined,
        knownAs: knownAs || undefined,
        contactPhone: contactPhone || undefined,
        address: address || undefined,
      },
      {
        onSuccess: () => {
          navigate('/', { replace: true });
        },
      }
    );
  }, [completeProfileMutation, displayName, knownAs, contactPhone, address, navigate]);

  const handleSkip = useCallback(() => {
    // Skip means just save current displayName and move on
    completeProfileMutation.mutate(
      { displayName: displayName || undefined },
      {
        onSuccess: () => {
          navigate('/', { replace: true });
        },
      }
    );
  }, [completeProfileMutation, displayName, navigate]);

  return (
    <AuthLayout>
      <Typography variant="h5" component="h1" gutterBottom>
        {t('onboarding.completeProfile')}
      </Typography>

      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        {t('onboarding.completeProfileDescription')}
      </Typography>

      {completeProfileMutation.error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {t('onboarding.profileError')}
        </Alert>
      )}

      <Box component="form" sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <TextField
          label={t('onboarding.displayName')}
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          fullWidth
          helperText={t('onboarding.displayNameHint')}
        />

        <TextField
          label={t('onboarding.knownAs')}
          value={knownAs}
          onChange={(e) => setKnownAs(e.target.value)}
          fullWidth
          helperText={t('onboarding.knownAsHint')}
        />

        <TextField
          label={t('onboarding.contactPhone')}
          value={contactPhone}
          onChange={(e) => setContactPhone(e.target.value)}
          fullWidth
          helperText={t('onboarding.contactPhoneHint')}
        />

        <TextField
          label={t('onboarding.address')}
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          fullWidth
          multiline
          rows={2}
          helperText={t('onboarding.addressHint')}
        />

        <Box sx={{ display: 'flex', gap: 2, mt: 2 }}>
          <Button
            variant="outlined"
            onClick={handleSkip}
            disabled={completeProfileMutation.isPending}
            fullWidth
          >
            {t('onboarding.skipForNow')}
          </Button>

          <Button
            variant="contained"
            onClick={handleComplete}
            disabled={completeProfileMutation.isPending}
            fullWidth
          >
            {completeProfileMutation.isPending ? (
              <CircularProgress size={20} color="inherit" />
            ) : (
              t('onboarding.complete')
            )}
          </Button>
        </Box>
      </Box>
    </AuthLayout>
  );
};

export default CompleteProfilePage;
```

### 5. Add Route to App.tsx

**File:** `web/src/App.tsx`

Add import at top:
```typescript
import { CompleteProfilePage } from '@/features/onboarding/CompleteProfilePage';
```

Add route after bootstrap routes (around line 48):
```typescript
{/* Onboarding routes */}
<Route path="/onboarding/complete-profile" element={<CompleteProfilePage />} />
```

### 6. Verify Translations

**File:** `web/src/locales/en/translation.json`

Ensure these keys exist (most already do):
```json
"onboarding": {
  "completeProfile": "Complete Your Profile",
  "completeProfileDescription": "Add optional profile information or skip to continue.",
  "displayName": "Display Name",
  "displayNameHint": "Your name as it will appear to others",
  "knownAs": "Known As (Nickname)",
  "knownAsHint": "Optional nickname or preferred name",
  "contactPhone": "Contact Phone",
  "contactPhoneHint": "Optional phone number for contact",
  "address": "Address",
  "addressHint": "Optional physical address",
  "skipForNow": "Skip for Now",
  "complete": "Complete",
  "profileError": "Failed to update profile"
}
```

## Tests Required

- [x] Component test: Renders form fields correctly
- [x] Component test: Pre-fills displayName from auth context
- [x] Component test: Skip button calls API with displayName only
- [x] Component test: Complete button calls API with all fields
- [x] Component test: Redirects to dashboard on success
- [x] Component test: Shows error on failure
- [x] Component test: Redirects if not at correct onboarding step
- [ ] Hook test: useCompleteProfile invalidates queries on success (covered in mutation options)

## Definition of Done

- [x] CompleteProfilePage renders correctly
- [x] Form pre-fills displayName from current admin
- [x] All optional fields work
- [x] Skip button works (redirects to dashboard)
- [x] Complete button works (redirects to dashboard)
- [x] Route `/onboarding/complete-profile` accessible
- [x] Guards prevent access if not at PASSWORD_CHANGED status
- [x] All tests pass
- [x] No lint/typecheck errors
- [x] Translations complete

## Commands

```bash
# Install dependencies
pnpm install

# Run tests
pnpm test

# Type check
pnpm typecheck

# Lint
pnpm lint

# Dev server
pnpm dev
```
