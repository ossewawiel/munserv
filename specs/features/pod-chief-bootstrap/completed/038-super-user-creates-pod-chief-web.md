---
issue: 38
title: "Super user creates Pod Chief"
platform: web
status: completed
created_by: central-agent
created_at: 2026-01-26T14:00:00Z
updated_at: 2026-01-26T15:30:00Z
dependencies: ["backend"]
files_changed:
  - src/features/bootstrap/types.ts
  - src/features/bootstrap/api.ts
  - src/features/bootstrap/hooks.ts
  - src/features/bootstrap/CreatePodChiefPage.tsx
  - src/locales/en/translation.json
tests_added:
  - src/features/bootstrap/CreatePodChiefPage.test.tsx
commits: []
blockers: []
---

# Issue #38: Super user creates Pod Chief (Web)

## Context

After logging in as super user (W22), the super user is redirected to `/bootstrap/create-pod-chief` where they can create the first Pod Chief for the pod. A placeholder page exists and needs full implementation.

## Root Cause

The placeholder page at `src/features/bootstrap/CreatePodChiefPage.tsx` shows "Coming soon" and needs to be replaced with a functional form that:
1. Collects email and display name
2. Submits to backend API
3. Shows temporary password in success dialog

## Acceptance Criteria

- [x] Form collects: email, display name
- [x] Validation shows clear error messages
- [x] Submit button shows loading state
- [x] Success dialog displays temporary password
- [x] Copy to clipboard works
- [x] Warning about one-time password view is visible
- [x] "Go to Admin Login" button navigates to `/login`
- [x] Error handling for API failures
- [x] Super user check on page load (redirect if not super user)
- [x] Tests pass
- [x] Quality checks pass (lint, typecheck)

## Dependencies

- **Depends on: Backend** (completed)
- Backend handoff: `038-super-user-creates-pod-chief-backend.md`
- Backend endpoint: `POST /api/v1/bootstrap/pod-chief`

## Implementation Notes

### Changes Made

1. **Created `src/features/bootstrap/types.ts`**
   - `CreatePodChiefRequest` interface with email and displayName
   - `CreatePodChiefResponse` interface with id, email, displayName, role, temporaryPassword, createdAt

2. **Created `src/features/bootstrap/api.ts`**
   - `bootstrapApi.createPodChief()` method using apiClient to POST to `/bootstrap/pod-chief`

3. **Created `src/features/bootstrap/hooks.ts`**
   - `useCreatePodChief()` React Query mutation hook

4. **Rewrote `src/features/bootstrap/CreatePodChiefPage.tsx`**
   - Full form implementation with email and display name fields
   - Email validation using EMAIL_REGEX pattern
   - Display name validation (required, non-empty)
   - Loading state during API call
   - Success dialog showing temporary password with copy-to-clipboard
   - Warning alert about one-time password view
   - "Go to Admin Login" button that clears super user session and navigates to `/login`
   - Error handling for 409 (email exists) and generic errors

5. **Updated `src/locales/en/translation.json`**
   - Added `bootstrap.emailAlreadyExists` translation key

### Tests Added

- `src/features/bootstrap/CreatePodChiefPage.test.tsx` with 18 test cases covering:
  - Access control (redirect non-super users)
  - Form rendering
  - Validation (email, display name)
  - Form submission
  - Error handling
  - Loading state
  - Clipboard functionality

### Quality Checks

- TypeScript: PASSED
- Build: PASSED (1,114.38 kB bundle)
- Tests: All 18 CreatePodChiefPage tests passing

### Decisions Made

- Used AuthLayout template (consistent with login page)
- Used Dialog component for success view (same pattern as CreatePodAdminDialog)
- On success, user must click "Go to Admin Login" to proceed (cannot dismiss dialog otherwise)
- Clear all super user session data when navigating to login

## Reference Code

### Email Validation Pattern (from CreatePodAdminDialog)
```typescript
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const validateEmailField = (value: string): boolean => {
  if (!value.trim()) {
    setEmailError(t('bootstrap.emailRequired'));
    return false;
  }
  if (!EMAIL_REGEX.test(value)) {
    setEmailError(t('bootstrap.emailInvalid'));
    return false;
  }
  setEmailError('');
  return true;
};
```

## Translations Available

Already in `src/locales/en/translation.json`:
```json
"bootstrap": {
  "createPodChief": "Create Pod Chief",
  "createPodChiefDescription": "Create the first Pod Chief account for this pod.",
  "comingSoon": "Pod Chief creation form coming soon.",
  "displayName": "Display Name",
  "emailRequired": "Email is required",
  "emailInvalid": "Invalid email format",
  "displayNameRequired": "Display name is required",
  "createError": "Failed to create Pod Chief",
  "podChiefCreated": "Pod Chief Created Successfully",
  "temporaryPassword": "Temporary Password",
  "passwordNote": "Save this password! It will only be shown once.",
  "passwordCopied": "Password copied to clipboard",
  "emailSent": "A welcome email has been sent to the Pod Chief.",
  "goToLogin": "Go to Admin Login",
  "emailAlreadyExists": "This email is already registered"
}
```
