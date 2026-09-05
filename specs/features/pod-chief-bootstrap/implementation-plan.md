# Implementation Plan: pod-chief-bootstrap

**Milestone:** [#2 pod-chief-bootstrap](https://github.com/ossewawiel/munserv/milestone/2)
**Platforms:** Backend, Web
**Total Stories:** 13 (9 Web, 4 Backend)

## Summary

Enable super user to bootstrap a fresh pod by creating the first Pod Chief, with automatic access revocation after Pod Chief completes onboarding. Includes temporary support access feature for ongoing maintenance.

---

## Phase 1: Backend Foundation

**Stories:** B5, B6
**Dependencies:** None
**Can run in parallel:** Yes

### Backend Tasks

- [ ] Create `bootstrap/config/BootstrapConfig.kt` - Configuration properties
- [ ] Add `bootstrap.super-user.*` properties to `application.yml`
- [ ] Add `findPodChief(podId)` to AdminRepository interface
- [ ] Add `existsPodChiefOnboarded(podId)` to AdminRepository interface
- [ ] Implement Pod Chief queries in JpaAdminRepository
- [ ] Create database index migration `V034__bootstrap_indexes.sql`
- [ ] Write unit tests for BootstrapConfig
- [ ] Write unit tests for repository methods

### Files to Create/Modify

```
backend/src/main/kotlin/com/munserv/
├── bootstrap/
│   └── config/
│       └── BootstrapConfig.kt              [CREATE]
├── admin/
│   ├── repository/
│   │   ├── AdminRepository.kt              [MODIFY - add Pod Chief queries]
│   │   └── JpaAdminRepository.kt           [MODIFY - implement queries]
│   └── repository/
│       └── SpringDataAdminRepository.kt    [MODIFY - add JPA methods]
└── resources/
    ├── application.yml                     [MODIFY - add bootstrap config]
    └── db/migration/
        └── V034__bootstrap_indexes.sql     [CREATE]
```

---

## Phase 2: Bootstrap API

**Stories:** W22, W23, W24, W25
**Dependencies:** Phase 1
**Can run in parallel:** Backend and Web can work in parallel after Phase 1

### Architecture Decision: Single Login Endpoint

**All admin logins go through the existing `/api/v1/auth/admin/login` endpoint.**

The backend determines authentication type based on credentials:
1. Check if credentials match super user config (from BootstrapConfig)
2. If super user credentials AND pod is eligible for bootstrap → return `role: "super_user"`
3. Otherwise, fall back to database admin lookup (existing behavior)

**Benefits:**
- Frontend doesn't need to know which login endpoint to call
- Single login page for all admin types
- Routing based on response `role` field

### Backend Tasks

- [x] Create `bootstrap/domain/BootstrapStatus.kt` - Sealed status type (Done in B6)
- [ ] Create `bootstrap/service/BootstrapResult.kt` - Sealed result type
- [x] Create `bootstrap/service/BootstrapService.kt` - Bootstrap logic (Done in B6)
- [ ] Create `bootstrap/api/BootstrapDto.kt` - Request/response DTOs
- [ ] Create `bootstrap/api/BootstrapController.kt` - REST endpoints (status + create only)
- [ ] **Modify `AuthService.adminLogin()`** - Check super user credentials first
- [ ] **Add `AuthResult.SuperUserLoginSuccess`** - New result type for super user
- [ ] Add `sendPodChiefWelcomeEmail()` to EmailService
- [ ] Write unit tests for BootstrapService
- [ ] Write integration tests for modified AuthService

### Web Tasks

- [ ] Create `features/bootstrap/types.ts` - TypeScript types
- [ ] Create `features/bootstrap/api.ts` - API functions
- [ ] Create `features/bootstrap/hooks.ts` - React Query hooks
- [ ] **Modify existing LoginPage** - Handle `super_user` role in response
- [ ] Create `features/bootstrap/CreatePodChiefPage.tsx` - Create Pod Chief page
- [ ] Create `features/bootstrap/components/CreatePodChiefForm.tsx` - Form component
- [ ] Add route `/bootstrap/create-pod-chief` (no separate login page needed)
- [ ] Add i18n keys for bootstrap feature
- [ ] Write component tests

### API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/v1/bootstrap/status` | Public | Check if pod needs bootstrap |
| POST | `/api/v1/auth/admin/login` | Public | **Existing** - now also handles super user |
| POST | `/api/v1/bootstrap/pod-chief` | Super User | Create Pod Chief |

### Login Response Routing

| Response `role` | Redirect To |
|-----------------|-------------|
| `super_user` | `/bootstrap/create-pod-chief` |
| Any admin with `onboardingStatus: "pending"` | `/onboarding/change-password` |
| Any admin with `onboardingStatus: "active"` | `/dashboard` |

---

## Phase 3: Onboarding Flow

**Stories:** W26, W27
**Dependencies:** Phase 2 (Pod Chief must be created)
**Can run in parallel:** Yes (reuses existing admin patterns)

### Backend Tasks

- [ ] Verify existing OnboardingService supports Pod Chief flow
- [ ] Add password change endpoint if not exists
- [ ] Add profile completion endpoint if not exists
- [ ] Ensure onboarding status transitions are correct

### Web Tasks

- [ ] Create `features/onboarding/types.ts` - TypeScript types
- [ ] Create `features/onboarding/api.ts` - API functions
- [ ] Create `features/onboarding/hooks.ts` - React Query hooks
- [ ] Create `features/onboarding/ChangePasswordPage.tsx` - Change password page
- [ ] Create `features/onboarding/CompleteProfilePage.tsx` - Complete profile page
- [ ] Create `features/onboarding/components/ChangePasswordForm.tsx`
- [ ] Create `features/onboarding/components/ProfileForm.tsx`
- [ ] Update `useAuth` hook - Add `onboardingStatus` field
- [ ] Update `ProtectedRoute` - Implement onboarding redirect logic
- [ ] Add routes `/onboarding/change-password` and `/onboarding/complete-profile`
- [ ] Add i18n keys for onboarding feature
- [ ] Write component tests

### Routes

| Route | Component | Auth |
|-------|-----------|------|
| `/onboarding/change-password` | ChangePasswordPage | Admin (PENDING) |
| `/onboarding/complete-profile` | CompleteProfilePage | Admin (PASSWORD_CHANGED) |

---

## Phase 4: Support Access

**Stories:** B7, B8, W28, W29, W30
**Dependencies:** Phase 2 (Bootstrap complete)
**Can run in parallel:** Yes (independent of onboarding)

### Backend Tasks

- [ ] Create database migration `V035__create_support_grants.sql`
- [ ] Create `support/domain/SupportGrant.kt` - Domain entity
- [ ] Create `support/domain/SupportGrantStatus.kt` - Enum
- [ ] Create `support/repository/SupportGrantRepository.kt` - Interface
- [ ] Create `support/repository/SupportGrantEntity.kt` - JPA entity
- [ ] Create `support/repository/JpaSupportGrantRepository.kt` - Implementation
- [ ] Create `support/service/SupportAccessResult.kt` - Sealed result type
- [ ] Create `support/service/SupportAccessService.kt` - Service logic
- [ ] Create `support/api/SupportAccessDto.kt` - DTOs
- [ ] Create `support/api/SupportAccessController.kt` - REST endpoints
- [ ] Create `audit/service/AuditService.kt` - Audit logging
- [ ] Add scheduled job for grant expiry cleanup
- [ ] Add activity tracking middleware
- [ ] Write unit tests
- [ ] Write integration tests

### Web Tasks

- [ ] Create `features/support-access/types.ts` - TypeScript types
- [ ] Create `features/support-access/api.ts` - API functions
- [ ] Create `features/support-access/hooks.ts` - React Query hooks
- [ ] Create `features/support-access/components/GrantAccessDialog.tsx`
- [ ] Create `features/support-access/components/ActiveSessionsTable.tsx`
- [ ] Create `features/support-access/components/SessionHistoryTable.tsx`
- [ ] Create `features/support-access/components/SessionExpiryTimer.tsx`
- [ ] Add Support Access section to Pod Settings page
- [ ] Update auth hook - Add `isSuperUser`, `grantExpiry` fields
- [ ] Implement auto-logout on grant expiry
- [ ] Add i18n keys for support access feature
- [ ] Write component tests

### API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/v1/support-access/grants` | Pod Chief | List active and past grants |
| POST | `/api/v1/support-access/grants` | Pod Chief | Create temporary grant |
| DELETE | `/api/v1/support-access/grants/{id}` | Pod Chief | Revoke grant |
| GET | `/api/v1/support-access/grants/current` | Grant-scoped | Caller's own grant (B9) |

### Database Changes

```sql
-- V035__create_support_grants.sql
CREATE TABLE support_grants (
    id UUID PRIMARY KEY,
    pod_id UUID NOT NULL REFERENCES pods(id),
    granted_role VARCHAR(50) NOT NULL,
    purpose TEXT NOT NULL,
    granted_by UUID NOT NULL REFERENCES admins(id),
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES admins(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_grants_pod_status ON support_grants(pod_id, status);
CREATE INDEX idx_support_grants_expires ON support_grants(expires_at) WHERE status = 'active';
```

---

## Implementation Order Summary

```
Phase 1: Backend Foundation (B5, B6)
    │
    ├── No dependencies, start immediately
    │
    ▼
Phase 2: Bootstrap API (W22, W23, W24, W25)
    │
    ├── Backend: BootstrapService, BootstrapController, EmailService
    ├── Web: Bootstrap feature module, login/create pages
    │
    ▼
Phase 3: Onboarding Flow (W26, W27)
    │
    ├── Backend: Verify/extend existing OnboardingService
    ├── Web: Onboarding feature module, change password/profile pages
    │
    ▼
Phase 4: Support Access (B7, B8, W28, W29, W30)
    │
    ├── Backend: Grants table, AuditService, SupportAccessService
    ├── Web: Support access components, Pod Settings integration
    │
    ▼
Done
```

---

## Estimated Scope

| Platform | New Files | Modified Files | Tests |
|----------|-----------|----------------|-------|
| Backend | ~20 | ~8 | ~15 |
| Web | ~25 | ~5 | ~12 |
| Database | 2 migrations | - | - |

---

## Definition of Done

- [ ] All acceptance criteria met for each story
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Lint/format checks passing
- [ ] i18n keys added for all user-facing text
- [ ] OpenAPI documentation updated
- [ ] Manual testing of full flow completed
- [ ] Security review passed (credentials, rate limiting, audit)
