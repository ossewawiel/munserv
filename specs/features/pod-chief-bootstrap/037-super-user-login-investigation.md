# Investigation: Super User Login to Fresh Pod

**Issue:** #37
**Date:** 2026-01-26
**Platforms:** Web (with Backend API dependency)

## Problem Statement

As a super user, I need to log in to a fresh pod so that I can bootstrap the initial Pod Chief account. This is part of the Pod Chief Bootstrap feature (W22).

## Architecture Decision

**Single Login Endpoint Approach:**
- Super user uses the existing `/api/v1/auth/admin/login` endpoint (no separate bootstrap login)
- Backend `AuthService.adminLogin()` checks super user credentials first
- Returns `SuperUserLoginSuccess` with `role: "SUPER_USER"` and `bootstrapStatus`
- Frontend routes based on response: super user → `/bootstrap/create-pod-chief`

## Investigation Steps

1. **Reviewed Backend Implementation Status:**
   - B5 (Super user configuration via environment) - CLOSED/Implemented
   - B6 (Bootstrap eligibility check) - CLOSED/Implemented
   - Backend bootstrap module exists at `/backend/src/main/kotlin/com/munserv/bootstrap/`

2. **Reviewed Existing Backend Code:**
   - `BootstrapConfig.kt` - Handles super user credentials from environment variables
   - `BootstrapService.kt` - Provides `getStatus(podId)` returning eligibility status
   - `BootstrapStatus.kt` - Sealed class with `Eligible`, `PodChiefOnboarding`, `NotEligible`

3. **Identified Backend Changes Needed:**
   - Modify `AuthService.adminLogin()` to check super user credentials first
   - Add `SuperUserLoginSuccess` to `AuthResult` sealed interface
   - Update `AuthController` to handle new result type
   - Update `AdminProfile` response DTO with `onboardingStatus` and `bootstrapStatus`

4. **Web Changes Needed:**
   - Update auth types with new response fields
   - Modify `LoginPage` to route super users to `/bootstrap/create-pod-chief`
   - No separate bootstrap login page required

## Root Cause

The existing admin login endpoint needs to be extended to support super user authentication, with role-based routing on the frontend.

## Affected Components

### Backend
- `auth/service/AuthResult.kt` - Add `SuperUserLoginSuccess` result type
- `auth/service/AuthService.kt` - Modify `adminLogin()` to check super user first
- `auth/api/AuthController.kt` - Handle `SuperUserLoginSuccess` in response
- `auth/api/AuthResponse.kt` - Add `onboardingStatus` and `bootstrapStatus` to DTOs

### Web
- `features/auth/types.ts` - Add new response fields
- `features/auth/LoginPage.tsx` - Add role-based routing logic
- `src/App.tsx` - Add route for `/bootstrap/create-pod-chief`

## Fix Approach

### Phase 1: Backend
1. Add `SuperUserLoginSuccess` to `AuthResult`
2. Modify `AuthService.adminLogin()` to check super user credentials
3. Update `AuthController` to handle new result
4. Add `onboardingStatus` and `bootstrapStatus` to response DTOs

### Phase 2: Web (This Story - W22)
1. Update `features/auth/types.ts` with new response fields
2. Modify `LoginPage.tsx` to route super users appropriately
3. Add placeholder route for `/bootstrap/create-pod-chief` (actual page is W23)

## Dependencies

- **Backend:** Must modify `AuthService.adminLogin()` and `AuthController`
- Reference: `specs/features/pod-chief-bootstrap/backend-handoff.md` Phase 2

## Execution Order

1. **Backend** (no dependencies) - Modify auth to support super user login
2. **Web** (after backend) - Update login page with role-based routing
