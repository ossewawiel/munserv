# Investigation: Super user creates Pod Chief

**Issue:** #38
**Date:** 2026-01-26
**Platforms:** Web (with Backend API dependency)

## Problem Statement

Super user needs a UI to create the first Pod Chief after logging into a fresh pod. Currently, there's a placeholder page at `/bootstrap/create-pod-chief` that needs full implementation.

## Investigation Steps

1. Checked feature spec at `specs/features/pod-chief-bootstrap/spec.md`
2. Examined existing placeholder at `web/src/features/bootstrap/CreatePodChiefPage.tsx`
3. Reviewed similar implementation in `CreatePodAdminDialog.tsx` for patterns
4. Checked backend API availability for bootstrap endpoint
5. Verified translations already exist in `locales/en/translation.json`

## Current State

### Web (Placeholder exists)
- `CreatePodChiefPage.tsx` - Placeholder with "Coming soon" message
- Routing exists at `/bootstrap/create-pod-chief` in `App.tsx`
- Translations ready in `bootstrap.*` namespace
- Auth types include `bootstrapStatus` field for super user context

### Backend (Partial implementation)
- `BootstrapService` exists with `getStatus()` and `isBootstrapEnabled()`
- No dedicated `POST /api/v1/bootstrap/pod-chief` endpoint yet
- Existing `POST /api/v1/pod/administrators` requires `POD_CHIEF` role (not suitable for super user)

## API Endpoint Needed

Per spec, the endpoint should be:

```
POST /api/v1/bootstrap/pod-chief
Auth: Super User JWT (role: SUPER_USER)
```

**Request:**
```json
{
  "email": "podchief@example.com",
  "displayName": "John Doe"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "email": "podchief@example.com",
  "displayName": "John Doe",
  "role": "pod_chief",
  "temporaryPassword": "TempPass123!",
  "createdAt": "2026-01-26T10:00:00Z"
}
```

## Affected Components

### Web
- `src/features/bootstrap/CreatePodChiefPage.tsx` - Full form implementation needed
- `src/features/bootstrap/api.ts` - New API file for bootstrap endpoints
- `src/features/bootstrap/hooks.ts` - New hooks file for mutations
- `src/features/bootstrap/types.ts` - New types file

### Backend (Separate Issue)
- New `BootstrapController` needed at `/api/v1/bootstrap`
- `POST /api/v1/bootstrap/pod-chief` endpoint
- Should reuse `AdminManagementService.createAdmin()` internally

## Fix Approach

### Web Implementation
1. Create bootstrap feature module with api, hooks, types
2. Replace placeholder with full form:
   - Email field with validation
   - Display name field with validation
   - Submit button with loading state
3. Success dialog showing:
   - Temporary password (one-time view)
   - Copy to clipboard functionality
   - "Welcome email sent" message
   - "Go to Admin Login" button
4. Error handling for:
   - Invalid email format
   - Email already exists (409)
   - Network errors

### Pattern Reference
Use `CreatePodAdminDialog.tsx` as pattern reference for:
- Form validation approach
- Success dialog with temporary password display
- Copy to clipboard functionality

## Dependencies

- Backend `POST /api/v1/bootstrap/pod-chief` endpoint required
- Backend handoff: `038-super-user-creates-pod-chief-backend.md`
- Web handoff: `038-super-user-creates-pod-chief-web.md`

## Execution Order

1. **Backend** (no dependencies) - Must complete first
2. **Web** (depends on backend) - Can start after backend provides API
