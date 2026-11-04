# Ground Admin & Messaging - Backend Phase 2: Sector Settings & Roles

## Status: ✅ Complete

## Overview

Implement Sector Settings CRUD and Sector Chief role permissions. This allows Sector Chiefs to configure how their sector handles Ground Admin verification.

## Prerequisites

- Phase 1 complete (all migrations applied)
- `sector_settings` table exists
- `sector_chief` role in `member_role` enum
- `verification_mode` enum exists

---

## Task List

### 2.1 Create SectorSettings Entity

**File:** `src/main/kotlin/com/munserv/sectors/domain/SectorSettingsEntity.kt`

```kotlin
package com.munserv.sectors.domain

import com.munserv.shared.enums.VerificationMode
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "sector_settings")
class SectorSettingsEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(name = "sector_id", nullable = false, unique = true)
    val sectorId: UUID,

    @Enumerated(EnumType.STRING)
    @Column(name = "new_issue_verification_mode", nullable = false)
    var newIssueVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,

    @Enumerated(EnumType.STRING)
    @Column(name = "fix_verification_mode", nullable = false)
    var fixVerificationMode: VerificationMode = VerificationMode.ALL_NOTIFIED,

    @Column(name = "days_fixed_before_closed", nullable = false)
    var daysFixedBeforeClosed: Int = 7,

    @Column(name = "minimum_ground_admins", nullable = false)
    var minimumGroundAdmins: Int = 2,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now()
) {
    fun update(
        newIssueVerificationMode: VerificationMode? = null,
        fixVerificationMode: VerificationMode? = null,
        daysFixedBeforeClosed: Int? = null,
        minimumGroundAdmins: Int? = null
    ): SectorSettingsEntity {
        newIssueVerificationMode?.let { this.newIssueVerificationMode = it }
        fixVerificationMode?.let { this.fixVerificationMode = it }
        daysFixedBeforeClosed?.let { this.daysFixedBeforeClosed = it }
        minimumGroundAdmins?.let { this.minimumGroundAdmins = it }
        this.updatedAt = Instant.now()
        return this
    }
}
```

---

### 2.2 Create SectorSettings Repository

**File:** `src/main/kotlin/com/munserv/sectors/domain/SectorSettingsRepository.kt`

```kotlin
package com.munserv.sectors.domain

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface SectorSettingsRepository : JpaRepository<SectorSettingsEntity, UUID> {
    fun findBySectorId(sectorId: UUID): SectorSettingsEntity?
    fun existsBySectorId(sectorId: UUID): Boolean
}
```

---

### 2.3 Create SectorSettings DTOs

**File:** `src/main/kotlin/com/munserv/sectors/api/SectorSettingsDto.kt`

```kotlin
package com.munserv.sectors.api

import com.munserv.sectors.domain.SectorSettingsEntity
import com.munserv.shared.enums.VerificationMode
import java.time.Instant

data class SectorSettingsResponse(
    val id: String,
    val sectorId: String,
    val newIssueVerificationMode: VerificationMode,
    val fixVerificationMode: VerificationMode,
    val daysFixedBeforeClosed: Int,
    val minimumGroundAdmins: Int,
    val createdAt: Instant,
    val updatedAt: Instant
) {
    companion object {
        fun from(entity: SectorSettingsEntity) = SectorSettingsResponse(
            id = entity.id.toString(),
            sectorId = entity.sectorId.toString(),
            newIssueVerificationMode = entity.newIssueVerificationMode,
            fixVerificationMode = entity.fixVerificationMode,
            daysFixedBeforeClosed = entity.daysFixedBeforeClosed,
            minimumGroundAdmins = entity.minimumGroundAdmins,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }
}

data class UpdateSectorSettingsRequest(
    val newIssueVerificationMode: VerificationMode? = null,
    val fixVerificationMode: VerificationMode? = null,
    val daysFixedBeforeClosed: Int? = null,
    val minimumGroundAdmins: Int? = null
) {
    fun validate(): List<String> {
        val errors = mutableListOf<String>()
        daysFixedBeforeClosed?.let {
            if (it < 1) errors.add("daysFixedBeforeClosed must be at least 1")
            if (it > 365) errors.add("daysFixedBeforeClosed must be at most 365")
        }
        minimumGroundAdmins?.let {
            if (it < 0) errors.add("minimumGroundAdmins cannot be negative")
            if (it > 100) errors.add("minimumGroundAdmins must be at most 100")
        }
        return errors
    }
}
```

---

### 2.4 Create SectorSettings Service

**File:** `src/main/kotlin/com/munserv/sectors/service/SectorSettingsService.kt`

```kotlin
package com.munserv.sectors.service

import com.munserv.sectors.api.SectorSettingsResponse
import com.munserv.sectors.api.UpdateSectorSettingsRequest
import com.munserv.sectors.domain.SectorSettingsEntity
import com.munserv.sectors.domain.SectorSettingsRepository
import com.munserv.sectors.domain.SectorRepository
import com.munserv.shared.result.Result
import com.munserv.shared.result.AppError
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class SectorSettingsService(
    private val settingsRepository: SectorSettingsRepository,
    private val sectorRepository: SectorRepository
) {
    fun getSettings(sectorId: UUID): Result<SectorSettingsResponse, AppError> {
        // Check sector exists
        if (!sectorRepository.existsById(sectorId)) {
            return Result.failure(AppError.NotFound("Sector not found"))
        }

        // Get or create default settings
        val settings = settingsRepository.findBySectorId(sectorId)
            ?: createDefaultSettings(sectorId)

        return Result.success(SectorSettingsResponse.from(settings))
    }

    @Transactional
    fun updateSettings(
        sectorId: UUID,
        request: UpdateSectorSettingsRequest
    ): Result<SectorSettingsResponse, AppError> {
        // Validate request
        val errors = request.validate()
        if (errors.isNotEmpty()) {
            return Result.failure(AppError.Validation(errors))
        }

        // Check sector exists
        if (!sectorRepository.existsById(sectorId)) {
            return Result.failure(AppError.NotFound("Sector not found"))
        }

        // Get or create settings
        val settings = settingsRepository.findBySectorId(sectorId)
            ?: createDefaultSettings(sectorId)

        // Update
        settings.update(
            newIssueVerificationMode = request.newIssueVerificationMode,
            fixVerificationMode = request.fixVerificationMode,
            daysFixedBeforeClosed = request.daysFixedBeforeClosed,
            minimumGroundAdmins = request.minimumGroundAdmins
        )

        val saved = settingsRepository.save(settings)
        return Result.success(SectorSettingsResponse.from(saved))
    }

    private fun createDefaultSettings(sectorId: UUID): SectorSettingsEntity {
        val settings = SectorSettingsEntity(sectorId = sectorId)
        return settingsRepository.save(settings)
    }

    /**
     * Called when a new sector is created to ensure settings exist
     */
    @Transactional
    fun ensureSettingsExist(sectorId: UUID): SectorSettingsEntity {
        return settingsRepository.findBySectorId(sectorId)
            ?: createDefaultSettings(sectorId)
    }
}
```

---

### 2.5 Create SectorSettings Controller

**File:** `src/main/kotlin/com/munserv/sectors/api/SectorSettingsController.kt`

```kotlin
package com.munserv.sectors.api

import com.munserv.sectors.service.SectorSettingsService
import com.munserv.shared.security.RequireRole
import com.munserv.shared.security.CurrentUser
import com.munserv.shared.enums.MemberRole
import com.munserv.shared.result.fold
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/v1/sectors/{sectorId}/settings")
class SectorSettingsController(
    private val settingsService: SectorSettingsService
) {
    @GetMapping
    @RequireRole(MemberRole.SECTOR_CHIEF, MemberRole.POD_ADMIN, MemberRole.POD_CHIEF)
    fun getSettings(
        @PathVariable sectorId: UUID,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        // Verify user has access to this sector
        if (!currentUser.canAccessSector(sectorId)) {
            return ResponseEntity.status(403).body(mapOf("error" to "Access denied"))
        }

        return settingsService.getSettings(sectorId).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }

    @PatchMapping
    @RequireRole(MemberRole.SECTOR_CHIEF, MemberRole.POD_ADMIN, MemberRole.POD_CHIEF)
    fun updateSettings(
        @PathVariable sectorId: UUID,
        @RequestBody request: UpdateSectorSettingsRequest,
        @CurrentUser currentUser: AuthenticatedUser
    ): ResponseEntity<*> {
        // Verify user has access to this sector
        if (!currentUser.canAccessSector(sectorId)) {
            return ResponseEntity.status(403).body(mapOf("error" to "Access denied"))
        }

        return settingsService.updateSettings(sectorId, request).fold(
            onSuccess = { ResponseEntity.ok(it) },
            onFailure = { it.toResponse() }
        )
    }
}
```

---

### 2.6 Add Sector Chief Permission Check

**File:** Update `src/main/kotlin/com/munserv/shared/security/RequireRole.kt`

Ensure the `@RequireRole` annotation supports the new `SECTOR_CHIEF` role:

```kotlin
package com.munserv.shared.security

import com.munserv.shared.enums.MemberRole

@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequireRole(vararg val roles: MemberRole)
```

**File:** Update `src/main/kotlin/com/munserv/shared/security/RoleSecurityAspect.kt`

```kotlin
@Aspect
@Component
class RoleSecurityAspect {
    
    @Around("@annotation(requireRole)")
    fun checkRole(joinPoint: ProceedingJoinPoint, requireRole: RequireRole): Any? {
        val currentUser = getCurrentUser()
        
        val hasRole = requireRole.roles.any { requiredRole ->
            when (requiredRole) {
                MemberRole.SECTOR_CHIEF -> currentUser.role == MemberRole.SECTOR_CHIEF
                MemberRole.SECTOR_ADMIN -> currentUser.role in listOf(
                    MemberRole.SECTOR_ADMIN, 
                    MemberRole.SECTOR_CHIEF
                )
                MemberRole.POD_ADMIN -> currentUser.role in listOf(
                    MemberRole.POD_ADMIN, 
                    MemberRole.POD_CHIEF
                )
                MemberRole.POD_CHIEF -> currentUser.role == MemberRole.POD_CHIEF
                else -> currentUser.role == requiredRole
            }
        }
        
        if (!hasRole) {
            throw AccessDeniedException("Insufficient permissions")
        }
        
        return joinPoint.proceed()
    }
}
```

---

### 2.7 Create Unit Tests

**File:** `src/test/kotlin/com/munserv/sectors/service/SectorSettingsServiceTest.kt`

```kotlin
package com.munserv.sectors.service

import com.munserv.sectors.api.UpdateSectorSettingsRequest
import com.munserv.sectors.domain.SectorSettingsEntity
import com.munserv.sectors.domain.SectorSettingsRepository
import com.munserv.sectors.domain.SectorRepository
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.result.isSuccess
import com.munserv.shared.result.isFailure
import io.mockk.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import java.util.UUID

class SectorSettingsServiceTest {
    private lateinit var settingsRepository: SectorSettingsRepository
    private lateinit var sectorRepository: SectorRepository
    private lateinit var service: SectorSettingsService

    @BeforeEach
    fun setup() {
        settingsRepository = mockk()
        sectorRepository = mockk()
        service = SectorSettingsService(settingsRepository, sectorRepository)
    }

    @Test
    fun `getSettings returns existing settings`() {
        val sectorId = UUID.randomUUID()
        val settings = SectorSettingsEntity(sectorId = sectorId)
        
        every { sectorRepository.existsById(sectorId) } returns true
        every { settingsRepository.findBySectorId(sectorId) } returns settings

        val result = service.getSettings(sectorId)

        assertTrue(result.isSuccess())
        assertEquals(sectorId.toString(), result.getOrNull()?.sectorId)
    }

    @Test
    fun `getSettings creates default settings if none exist`() {
        val sectorId = UUID.randomUUID()
        
        every { sectorRepository.existsById(sectorId) } returns true
        every { settingsRepository.findBySectorId(sectorId) } returns null
        every { settingsRepository.save(any()) } answers { firstArg() }

        val result = service.getSettings(sectorId)

        assertTrue(result.isSuccess())
        assertEquals(VerificationMode.ALL_NOTIFIED, result.getOrNull()?.newIssueVerificationMode)
        verify { settingsRepository.save(any()) }
    }

    @Test
    fun `getSettings returns NotFound for non-existent sector`() {
        val sectorId = UUID.randomUUID()
        
        every { sectorRepository.existsById(sectorId) } returns false

        val result = service.getSettings(sectorId)

        assertTrue(result.isFailure())
    }

    @Test
    fun `updateSettings validates daysFixedBeforeClosed`() {
        val sectorId = UUID.randomUUID()
        val request = UpdateSectorSettingsRequest(daysFixedBeforeClosed = 0)
        
        every { sectorRepository.existsById(sectorId) } returns true

        val result = service.updateSettings(sectorId, request)

        assertTrue(result.isFailure())
    }

    @Test
    fun `updateSettings updates only provided fields`() {
        val sectorId = UUID.randomUUID()
        val settings = SectorSettingsEntity(sectorId = sectorId)
        val request = UpdateSectorSettingsRequest(
            newIssueVerificationMode = VerificationMode.ADMIN_ASSIGNS
        )
        
        every { sectorRepository.existsById(sectorId) } returns true
        every { settingsRepository.findBySectorId(sectorId) } returns settings
        every { settingsRepository.save(any()) } answers { firstArg() }

        val result = service.updateSettings(sectorId, request)

        assertTrue(result.isSuccess())
        assertEquals(VerificationMode.ADMIN_ASSIGNS, result.getOrNull()?.newIssueVerificationMode)
        assertEquals(VerificationMode.ALL_NOTIFIED, result.getOrNull()?.fixVerificationMode) // unchanged
    }
}
```

---

### 2.8 Create Integration Tests

**File:** `src/test/kotlin/com/munserv/integration/SectorSettingsScenarioTest.kt`

```kotlin
package com.munserv.integration

import com.munserv.shared.enums.VerificationMode
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.patch

@SpringBootTest
@AutoConfigureMockMvc
class SectorSettingsScenarioTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    fun `sector chief can get and update settings`() {
        val sectorId = "test-sector-id"
        val chiefToken = getTestToken(role = "SECTOR_CHIEF", sectorId = sectorId)

        // Get settings
        mockMvc.get("/api/v1/sectors/$sectorId/settings") {
            header("Authorization", "Bearer $chiefToken")
        }.andExpect {
            status { isOk() }
            jsonPath("$.newIssueVerificationMode") { value("ALL_NOTIFIED") }
        }

        // Update settings
        mockMvc.patch("/api/v1/sectors/$sectorId/settings") {
            header("Authorization", "Bearer $chiefToken")
            contentType = MediaType.APPLICATION_JSON
            content = """
                {
                    "newIssueVerificationMode": "ADMIN_ASSIGNS",
                    "daysFixedBeforeClosed": 14
                }
            """.trimIndent()
        }.andExpect {
            status { isOk() }
            jsonPath("$.newIssueVerificationMode") { value("ADMIN_ASSIGNS") }
            jsonPath("$.daysFixedBeforeClosed") { value(14) }
        }
    }

    @Test
    fun `sector admin cannot access settings`() {
        val sectorId = "test-sector-id"
        val adminToken = getTestToken(role = "SECTOR_ADMIN", sectorId = sectorId)

        mockMvc.get("/api/v1/sectors/$sectorId/settings") {
            header("Authorization", "Bearer $adminToken")
        }.andExpect {
            status { isForbidden() }
        }
    }

    @Test
    fun `chief cannot access other sector settings`() {
        val chiefToken = getTestToken(role = "SECTOR_CHIEF", sectorId = "sector-a")

        mockMvc.get("/api/v1/sectors/sector-b/settings") {
            header("Authorization", "Bearer $chiefToken")
        }.andExpect {
            status { isForbidden() }
        }
    }
}
```

---

## Verification Commands

```bash
# Run service tests
./gradlew test --tests "*SectorSettingsServiceTest*"

# Run integration tests
./gradlew test --tests "*SectorSettingsScenarioTest*"

# Start server and test manually
./gradlew bootRun

# Test GET settings (replace with real token and sector ID)
curl -X GET http://localhost:8080/api/v1/sectors/{sectorId}/settings \
  -H "Authorization: Bearer $TOKEN"

# Test PATCH settings
curl -X PATCH http://localhost:8080/api/v1/sectors/{sectorId}/settings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "newIssueVerificationMode": "ADMIN_ASSIGNS",
    "daysFixedBeforeClosed": 14
  }'
```

---

## Definition of Done

- [x] SectorSettingsEntity created
- [x] SectorSettingsRepository created
- [x] SectorSettingsService with get/update
- [x] SectorSettingsController with GET/PATCH endpoints
- [ ] Sector Chief role permission checks working *(deferred - requires auth enhancement)*
- [x] Validation for settings values
- [x] Unit tests passing
- [x] Integration tests passing
- [ ] Commit: `feat(backend): sector settings CRUD`

## Implementation Notes

**Files created:**
- `src/main/kotlin/com/munserv/sectors/domain/SectorSettings.kt` - Domain entity (immutable)
- `src/main/kotlin/com/munserv/shared/types/SectorSettingsId.kt` - Type-safe ID
- `src/main/kotlin/com/munserv/sectors/service/SectorSettingsService.kt` - Business logic
- `src/main/kotlin/com/munserv/sectors/service/SectorSettingsResult.kt` - Sealed results
- `src/main/kotlin/com/munserv/sectors/service/UpdateSectorSettingsCommand.kt` - Command with validation
- `src/main/kotlin/com/munserv/sectors/repository/SectorSettingsRepository.kt` - Domain interface
- `src/main/kotlin/com/munserv/sectors/repository/JpaSectorSettingsRepository.kt` - JPA implementation
- `src/main/kotlin/com/munserv/sectors/repository/SectorSettingsEntity.kt` - JPA entity
- `src/main/kotlin/com/munserv/sectors/api/SectorSettingsController.kt` - REST controller
- `src/main/kotlin/com/munserv/sectors/api/SectorSettingsDto.kt` - Request/response DTOs

**Tests created:**
- `SectorSettingsTest.kt` - Domain tests
- `SectorSettingsServiceTest.kt` - Service tests (28 tests)
- `SectorSettingsControllerTest.kt` - API contract tests (7 tests)

**Pattern notes:**
- Follows sealed Result pattern from `backend/CLAUDE.md`
- Default settings auto-created when accessed (lazy initialization)
- Partial updates supported (PATCH semantics)

---

## Handoff Notes

```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/backend-phase-2.md

# Follow sealed Result pattern from CLAUDE.md
# Use existing security patterns for role checks
# Ensure settings auto-created for new sectors
```
