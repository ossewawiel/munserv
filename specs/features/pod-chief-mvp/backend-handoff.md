# Handoff: Backend

**Feature:** pod-chief-mvp
**Milestone:** [pod-chief-mvp](https://github.com/ossewawiel/munserv/milestone/1)
**Related Issues:** #21-#32

## Context

Implement backend APIs for Pod Chief MVP: pod setup status tracking, settings management, dashboard statistics, and administrator management with onboarding flow.

## Prerequisites

Read first:
- `backend/CLAUDE.md` - Required patterns
- `specs/Domain_and_Data_Modeling.md` - Entity definitions
- Existing: `Admin.kt`, `AdminRole`, `PodId`

## Files to Create

### Migrations
```
backend/src/main/resources/db/migration/
├── V031__add_pod_setup_fields.sql
└── V032__add_admin_onboarding_status.sql
```

### Domain Layer
```
backend/src/main/kotlin/com/munserv/pod/domain/
├── PodSettings.kt           # Pod settings value object
├── PodSetupStatus.kt        # Sealed class for setup status
├── SetupStep.kt             # Enum for setup steps
└── PodDashboardStats.kt     # Dashboard statistics
```

### Service Layer
```
backend/src/main/kotlin/com/munserv/pod/service/
├── PodService.kt
├── PodResult.kt             # Sealed result interface
├── PodDashboardService.kt
└── PodAdministratorService.kt
```

### API Layer
```
backend/src/main/kotlin/com/munserv/pod/api/
├── PodController.kt
├── PodDashboardController.kt
├── PodAdministratorController.kt
├── PodDto.kt                # Request/Response DTOs
└── PodAdministratorDto.kt
```

### Repository Layer
```
backend/src/main/kotlin/com/munserv/pod/repository/
├── PodRepository.kt
├── JpaPodRepository.kt
└── PodEntity.kt             # Extend existing or create
```

## Files to Modify

- `backend/src/main/kotlin/com/munserv/admin/domain/Admin.kt` - Add onboarding status
- `backend/src/main/kotlin/com/munserv/admin/repository/AdminEntity.kt` - Add column mapping

## Implementation Steps

### Step 1: Database Migrations

**V031__add_pod_setup_fields.sql:**
```sql
-- Add setup tracking fields to pods table
ALTER TABLE pods ADD COLUMN IF NOT EXISTS logo_url VARCHAR(500);
ALTER TABLE pods ADD COLUMN IF NOT EXISTS display_name VARCHAR(200);
ALTER TABLE pods ADD COLUMN IF NOT EXISTS setup_completed_at TIMESTAMPTZ;

-- Setup steps tracking
CREATE TABLE IF NOT EXISTS pod_setup_steps (
    pod_id UUID NOT NULL REFERENCES pods(id),
    step VARCHAR(50) NOT NULL,
    completed_at TIMESTAMPTZ,
    PRIMARY KEY (pod_id, step)
);

COMMENT ON TABLE pod_setup_steps IS 'Tracks Pod Chief setup progress';
```

**V032__add_admin_onboarding_status.sql:**
```sql
-- Onboarding status for invited administrators
CREATE TYPE onboarding_status AS ENUM ('pending', 'password_changed', 'profile_complete', 'active');

ALTER TABLE admins ADD COLUMN IF NOT EXISTS onboarding_status onboarding_status DEFAULT 'active';
ALTER TABLE admins ADD COLUMN IF NOT EXISTS temporary_password_hash VARCHAR(255);
ALTER TABLE admins ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- Existing admins are already active
UPDATE admins SET onboarding_status = 'active' WHERE onboarding_status IS NULL;
```

### Step 2: Domain Layer

**PodSetupStatus.kt:**
```kotlin
sealed class PodSetupStatus {
    data class Incomplete(val missingSteps: List<SetupStep>) : PodSetupStatus()
    object Complete : PodSetupStatus()

    val isComplete: Boolean get() = this is Complete
}

enum class SetupStep {
    POD_NAME,
    POD_BOUNDARIES,
    WARDS_SECTORS,
    FIRST_ADMIN;

    fun toDbValue(): String = name.lowercase()

    companion object {
        fun fromDbValue(value: String): SetupStep =
            entries.first { it.name.equals(value, ignoreCase = true) }
    }
}
```

**PodSettings.kt:**
```kotlin
data class PodSettings(
    val podId: PodId,
    val name: String,
    val displayName: String,  // "Munserv Pod {name}"
    val logoUrl: String?,
    val config: Map<String, Any>,
    val updatedAt: Instant
) {
    companion object {
        fun displayNameFor(name: String): String = "Munserv Pod $name"
    }
}
```

**PodDashboardStats.kt:**
```kotlin
data class PodDashboardStats(
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val pendingIssues: Int,
    val activeAdministrators: Int,
    val totalMembers: Int,
    val activeGroundAdmins: Int,
    val wardCount: Int,
    val sectorCount: Int
)

data class WardDashboardStats(
    val wardId: WardId,
    val wardName: String,
    val totalIssues: Int,
    val openIssues: Int,
    val resolvedThisMonth: Int,
    val sectorCount: Int,
    val activeGroundAdmins: Int
)
```

### Step 3: Service Layer

**PodService.kt:**
```kotlin
@Service
class PodService(
    private val podRepository: PodRepository,
    private val setupStepRepository: PodSetupStepRepository,
    private val wardRepository: WardRepository,
    private val adminRepository: AdminRepository
) {
    fun getSetupStatus(podId: PodId): PodSetupStatus {
        val completedSteps = setupStepRepository.findCompletedSteps(podId)
        val allSteps = SetupStep.entries.toSet()
        val missing = allSteps - completedSteps

        return if (missing.isEmpty()) {
            PodSetupStatus.Complete
        } else {
            PodSetupStatus.Incomplete(missing.toList())
        }
    }

    fun getSettings(podId: PodId): PodResult<PodSettings> {
        val pod = podRepository.findById(podId)
            ?: return PodResult.NotFound(podId)
        return PodResult.Success(pod.toSettings())
    }

    fun updateSettings(podId: PodId, command: UpdatePodSettingsCommand): PodResult<PodSettings> {
        val pod = podRepository.findById(podId)
            ?: return PodResult.NotFound(podId)

        val updated = pod.copy(
            name = command.name ?: pod.name,
            logoUrl = command.logoUrl ?: pod.logoUrl,
            displayName = command.name?.let { PodSettings.displayNameFor(it) } ?: pod.displayName
        )

        val saved = podRepository.save(updated)

        // Mark setup step as complete if name set
        if (command.name != null) {
            setupStepRepository.markComplete(podId, SetupStep.POD_NAME)
        }

        return PodResult.Success(saved.toSettings())
    }
}
```

**PodResult.kt:**
```kotlin
sealed interface PodResult<out T> {
    data class Success<T>(val data: T) : PodResult<T>
    data class NotFound(val podId: PodId) : PodResult<Nothing>
    data class ValidationError(val errors: List<String>) : PodResult<Nothing>
    data class Unauthorized(val reason: String) : PodResult<Nothing>
}
```

### Step 4: Controller Layer

**PodController.kt:**
```kotlin
@RestController
@RequestMapping("/api/v1/pod")
@Tag(name = "Pod Settings", description = "Pod configuration and setup")
@RequireRole(AdminRole.POD_CHIEF)
class PodController(
    private val podService: PodService
) {
    @GetMapping("/status")
    @Operation(summary = "Get pod setup status")
    fun getSetupStatus(@CurrentAdmin admin: Admin): ResponseEntity<PodSetupStatusResponse> {
        val status = podService.getSetupStatus(admin.podId!!)
        return ResponseEntity.ok(status.toResponse())
    }

    @GetMapping("/settings")
    @Operation(summary = "Get pod settings")
    fun getSettings(@CurrentAdmin admin: Admin): ResponseEntity<*> =
        when (val result = podService.getSettings(admin.podId!!)) {
            is PodResult.Success -> ResponseEntity.ok(result.data.toResponse())
            is PodResult.NotFound -> ResponseEntity.notFound().build<Unit>()
            else -> ResponseEntity.internalServerError().build<Unit>()
        }

    @PatchMapping("/settings")
    @Operation(summary = "Update pod settings")
    fun updateSettings(
        @CurrentAdmin admin: Admin,
        @Valid @RequestBody request: UpdatePodSettingsRequest
    ): ResponseEntity<*> =
        when (val result = podService.updateSettings(admin.podId!!, request.toCommand())) {
            is PodResult.Success -> ResponseEntity.ok(result.data.toResponse())
            is PodResult.NotFound -> ResponseEntity.notFound().build<Unit>()
            is PodResult.ValidationError -> ResponseEntity.badRequest().body(result.errors)
            else -> ResponseEntity.internalServerError().build<Unit>()
        }
}
```

**PodAdministratorController.kt:**
```kotlin
@RestController
@RequestMapping("/api/v1/pod/administrators")
@Tag(name = "Pod Administrators", description = "Manage pod administrators")
@RequireRole(AdminRole.POD_CHIEF)
class PodAdministratorController(
    private val adminService: PodAdministratorService,
    private val emailService: EmailService
) {
    @GetMapping
    @Operation(summary = "List pod administrators")
    fun listAdministrators(
        @CurrentAdmin admin: Admin,
        @RequestParam(defaultValue = "1") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<PaginatedResponse<PodAdministratorResponse>> {
        val admins = adminService.listByPod(admin.podId!!, page, size)
        return ResponseEntity.ok(admins.toResponse())
    }

    @PostMapping
    @Operation(summary = "Create new pod administrator")
    fun createAdministrator(
        @CurrentAdmin admin: Admin,
        @Valid @RequestBody request: CreatePodAdministratorRequest
    ): ResponseEntity<*> =
        when (val result = adminService.create(admin.podId!!, request.toCommand())) {
            is AdminResult.Success -> {
                emailService.sendAdminInvitation(result.admin)
                ResponseEntity.status(201).body(result.admin.toResponse())
            }
            is AdminResult.ValidationError -> ResponseEntity.badRequest().body(result.errors)
            is AdminResult.AlreadyExists -> ResponseEntity.status(409).body("Email already registered")
            else -> ResponseEntity.internalServerError().build<Unit>()
        }
}
```

### Step 5: DTOs

**PodDto.kt:**
```kotlin
// Responses
data class PodSetupStatusResponse(
    val isComplete: Boolean,
    val missingSteps: List<String>
)

data class PodSettingsResponse(
    val name: String,
    val displayName: String,
    val logoUrl: String?
)

// Requests
data class UpdatePodSettingsRequest(
    @field:Size(min = 2, max = 100)
    val name: String?,
    val logoUrl: String?
) {
    fun toCommand() = UpdatePodSettingsCommand(name, logoUrl)
}
```

**PodAdministratorDto.kt:**
```kotlin
data class PodAdministratorResponse(
    val id: String,
    val email: String,
    val displayName: String,
    val role: String,
    val wardIds: List<String>,
    val sectorIds: List<String>,
    val status: String,
    val createdAt: String
)

data class CreatePodAdministratorRequest(
    @field:NotBlank
    @field:Email
    val email: String,

    @field:NotBlank
    @field:Size(min = 2, max = 100)
    val firstName: String,

    @field:NotBlank
    @field:Size(min = 2, max = 100)
    val lastName: String,

    @field:NotBlank
    val role: String,  // POD_ADMIN, WARD_ADMIN, etc.

    val wardIds: List<String>?,
    val sectorIds: List<String>?
)
```

## Tests Required

### Unit Tests

- [ ] `PodServiceTest.kt`
  - `should return Incomplete when setup steps missing`
  - `should return Complete when all steps done`
  - `should update settings and mark step complete`

- [ ] `PodDashboardServiceTest.kt`
  - `should aggregate pod statistics correctly`
  - `should filter stats by ward`

- [ ] `PodAdministratorServiceTest.kt`
  - `should create administrator with pending status`
  - `should generate temporary password`
  - `should complete onboarding steps in order`

### Integration Tests

- [ ] `PodControllerTest.kt` - API contract tests
- [ ] `PodDashboardControllerTest.kt` - Dashboard endpoints
- [ ] `PodAdministratorControllerTest.kt` - Admin CRUD

## Definition of Done

- [ ] All migrations run successfully
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] OpenAPI documentation complete
- [ ] No ktlint errors
- [ ] SonarQube quality gate passed
- [ ] Follows backend/CLAUDE.md patterns

## API Summary

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/pod/status` | Get setup status |
| GET | `/api/v1/pod/settings` | Get pod settings |
| PATCH | `/api/v1/pod/settings` | Update pod settings |
| GET | `/api/v1/pod/dashboard` | Get pod dashboard stats |
| GET | `/api/v1/pod/dashboard/wards/{id}` | Get ward stats |
| GET | `/api/v1/pod/administrators` | List administrators |
| POST | `/api/v1/pod/administrators` | Create administrator |
| PATCH | `/api/v1/pod/administrators/{id}/onboarding` | Complete onboarding step |
