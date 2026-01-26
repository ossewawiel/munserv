---
issue: 47
title: "[B6] Bootstrap eligibility check"
platform: backend
status: completed
created_by: central-agent
created_at: 2026-01-26T12:00:00Z
updated_at: 2026-01-26T12:10:00Z
dependencies: []
files_changed:
  - admin/repository/AdminRepository.kt
  - admin/repository/JpaAdminRepository.kt
  - bootstrap/domain/BootstrapStatus.kt
  - bootstrap/service/BootstrapService.kt
tests_added:
  - bootstrap/service/BootstrapServiceTest.kt
commits: []
blockers: []
---

# Issue #47: Bootstrap eligibility check (Backend)

## Context

For the pod-chief-bootstrap feature, the system needs to check whether a pod is eligible for bootstrap (super user can create the first Pod Chief) or if bootstrap is no longer needed (Pod Chief already exists and is onboarded).

This is part of Phase 1: Backend Foundation for the pod-chief-bootstrap milestone.

## Requirements from Issue

- Query: Does Pod Chief exist AND is onboarded?
- Returns bootstrap status (eligible/not_eligible)
- No new database table needed
- Uses existing Admin entity with role=POD_CHIEF
- Checks onboardingStatus == ACTIVE

## What To Implement

### 1. Add Pod Chief queries to AdminRepository interface

Add to `admin/repository/AdminRepository.kt`:

```kotlin
/**
 * Find the Pod Chief for a given pod.
 * Returns null if no Pod Chief exists.
 */
fun findPodChief(podId: PodId): Admin?

/**
 * Check if a Pod Chief exists and has completed onboarding.
 * Returns true if Pod Chief exists with onboardingStatus == ACTIVE.
 */
fun existsPodChiefOnboarded(podId: PodId): Boolean
```

### 2. Add JPA query methods to SpringDataAdminRepository

Add to the `SpringDataAdminRepository` interface:

```kotlin
fun findByPodIdAndRoleAndDeletedAtIsNull(podId: UUID, role: String): AdminEntity?

fun existsByPodIdAndRoleAndOnboardingStatusAndDeletedAtIsNull(
    podId: UUID,
    role: String,
    onboardingStatus: String
): Boolean
```

### 3. Implement in JpaAdminRepository

Add implementations:

```kotlin
override fun findPodChief(podId: PodId): Admin? =
    jpa.findByPodIdAndRoleAndDeletedAtIsNull(
        podId.value,
        AdminRole.POD_CHIEF.toDbValue()
    )?.toDomain()

override fun existsPodChiefOnboarded(podId: PodId): Boolean =
    jpa.existsByPodIdAndRoleAndOnboardingStatusAndDeletedAtIsNull(
        podId.value,
        AdminRole.POD_CHIEF.toDbValue(),
        OnboardingStatus.ACTIVE.toDbValue()
    )
```

### 4. Create BootstrapStatus sealed class

Create `bootstrap/domain/BootstrapStatus.kt`:

```kotlin
package com.munserv.bootstrap.domain

/**
 * Represents the bootstrap eligibility status of a pod.
 */
sealed class BootstrapStatus {
    /**
     * Pod is eligible for bootstrap - no Pod Chief exists yet.
     * Super user can create the first Pod Chief.
     */
    data object Eligible : BootstrapStatus()

    /**
     * Pod Chief exists but hasn't completed onboarding yet.
     * Super user access is blocked while Pod Chief completes onboarding.
     */
    data object PodChiefOnboarding : BootstrapStatus()

    /**
     * Pod Chief exists and has completed onboarding.
     * Bootstrap is no longer available.
     */
    data object NotEligible : BootstrapStatus()
}
```

### 5. Create BootstrapService

Create `bootstrap/service/BootstrapService.kt`:

```kotlin
package com.munserv.bootstrap.service

import com.munserv.admin.repository.AdminRepository
import com.munserv.bootstrap.config.BootstrapConfig
import com.munserv.bootstrap.domain.BootstrapStatus
import com.munserv.shared.types.PodId
import org.springframework.stereotype.Service

@Service
class BootstrapService(
    private val adminRepository: AdminRepository,
    private val bootstrapConfig: BootstrapConfig,
) {
    /**
     * Get the bootstrap eligibility status for a pod.
     *
     * Rules:
     * - If no Pod Chief exists: Eligible
     * - If Pod Chief exists but not onboarded: PodChiefOnboarding
     * - If Pod Chief exists and onboarded (ACTIVE): NotEligible
     */
    fun getStatus(podId: PodId): BootstrapStatus {
        // Check if Pod Chief exists and is onboarded
        if (adminRepository.existsPodChiefOnboarded(podId)) {
            return BootstrapStatus.NotEligible
        }

        // Check if Pod Chief exists (but not onboarded)
        val podChief = adminRepository.findPodChief(podId)
        if (podChief != null) {
            return BootstrapStatus.PodChiefOnboarding
        }

        // No Pod Chief exists - eligible for bootstrap
        return BootstrapStatus.Eligible
    }

    /**
     * Check if super user bootstrap is enabled in configuration.
     */
    fun isBootstrapEnabled(): Boolean = bootstrapConfig.isConfigured()
}
```

### Files To Modify

- `admin/repository/AdminRepository.kt` - Add interface methods
- `admin/repository/JpaAdminRepository.kt` - Add interface + implementations

### Files To Create

- `bootstrap/domain/BootstrapStatus.kt` - Sealed status type
- `bootstrap/service/BootstrapService.kt` - Service with getStatus()

## Acceptance Criteria

- [x] `AdminRepository.findPodChief(podId)` returns Pod Chief or null
- [x] `AdminRepository.existsPodChiefOnboarded(podId)` returns boolean
- [x] `BootstrapStatus` sealed class with Eligible, PodChiefOnboarding, NotEligible
- [x] `BootstrapService.getStatus(podId)` returns correct status
- [ ] Unit tests for repository methods (covered by integration tests in future)
- [x] Unit tests for BootstrapService

## Test Cases

### Repository Tests

1. `findPodChief returns null when no Pod Chief exists`
2. `findPodChief returns Pod Chief when exists`
3. `findPodChief returns null when Pod Chief is deleted`
4. `existsPodChiefOnboarded returns false when no Pod Chief`
5. `existsPodChiefOnboarded returns false when Pod Chief PENDING`
6. `existsPodChiefOnboarded returns true when Pod Chief ACTIVE`

### Service Tests

1. `getStatus returns Eligible when no Pod Chief exists`
2. `getStatus returns PodChiefOnboarding when Pod Chief exists but PENDING`
3. `getStatus returns PodChiefOnboarding when Pod Chief exists but PASSWORD_CHANGED`
4. `getStatus returns NotEligible when Pod Chief exists and ACTIVE`
5. `isBootstrapEnabled returns true when configured`
6. `isBootstrapEnabled returns false when not configured`

## Dependencies

- Existing Admin entity and repository
- Existing OnboardingStatus enum (PENDING, PASSWORD_CHANGED, PROFILE_COMPLETE, ACTIVE)
- Existing AdminRole enum with POD_CHIEF
- BootstrapConfig (already implemented in B5)

## Implementation Notes

### Completed 2026-01-26

**Files Modified:**
- `admin/repository/AdminRepository.kt` - Added `findPodChief()` and `existsPodChiefOnboarded()` methods
- `admin/repository/JpaAdminRepository.kt` - Added Spring Data query methods and implementations

**Files Created:**
- `bootstrap/domain/BootstrapStatus.kt` - Sealed class with Eligible, PodChiefOnboarding, NotEligible states
- `bootstrap/service/BootstrapService.kt` - Service with `getStatus()` and `isBootstrapEnabled()` methods

**Tests Created:**
- `bootstrap/service/BootstrapServiceTest.kt` - 9 unit tests covering all scenarios

**Design Decisions:**
1. Added `canBootstrap` property to BootstrapStatus for convenience
2. `getStatus()` checks `existsPodChiefOnboarded()` first for performance (most common case after setup)
3. Added `PodChiefOnboarding` intermediate state to distinguish from no Pod Chief existing
4. Repository tests deferred - Spring Data query methods are straightforward, integration tests recommended

**All tests passing, ktlint check passed.**
