---
issue: 38
title: "Super user creates Pod Chief"
platform: backend
status: completed
created_by: central-agent
created_at: 2026-01-26T15:00:00Z
updated_at: 2026-01-26T15:00:00Z
dependencies: []
files_changed:
  - src/main/kotlin/com/munserv/bootstrap/api/BootstrapController.kt
  - src/main/kotlin/com/munserv/bootstrap/api/BootstrapDto.kt
  - src/main/kotlin/com/munserv/bootstrap/service/BootstrapResult.kt
  - src/main/kotlin/com/munserv/bootstrap/service/BootstrapService.kt
  - src/main/kotlin/com/munserv/shared/email/EmailService.kt
  - src/main/kotlin/com/munserv/shared/config/SecurityConfig.kt
tests_added:
  - src/test/kotlin/com/munserv/bootstrap/service/BootstrapServiceTest.kt (extended)
commits: []
blockers: []
---

# Issue #38: Super user creates Pod Chief (Backend)

## Context

The web frontend needs a backend API endpoint to create the first Pod Chief. Super user login is already implemented in `AuthService.adminLogin()`. Now we need the endpoint that allows the authenticated super user to create the Pod Chief.

## Root Cause

The `POST /api/v1/bootstrap/pod-chief` endpoint doesn't exist yet. The bootstrap service (`BootstrapService`) has status checks but no `createPodChief` method.

## What To Fix

### Files To Create

#### 1. `bootstrap/api/BootstrapDto.kt`

```kotlin
package com.munserv.bootstrap.api

data class CreatePodChiefRequest(
    val email: String,
    val displayName: String,
)

data class CreatePodChiefResponse(
    val id: String,
    val email: String,
    val displayName: String,
    val role: String,
    val temporaryPassword: String,
    val createdAt: String,
)
```

#### 2. `bootstrap/api/BootstrapController.kt`

```kotlin
package com.munserv.bootstrap.api

import com.munserv.bootstrap.service.BootstrapResult
import com.munserv.bootstrap.service.BootstrapService
import com.munserv.pod.service.PodService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/bootstrap")
@Tag(name = "Bootstrap", description = "Pod bootstrap endpoints for super user")
class BootstrapController(
    private val bootstrapService: BootstrapService,
    private val podService: PodService,
) {
    @PostMapping("/pod-chief")
    @Operation(summary = "Create Pod Chief", description = "Creates the first Pod Chief for a fresh pod")
    @SecurityRequirement(name = "bearerAuth")
    fun createPodChief(
        @RequestBody request: CreatePodChiefRequest,
    ): ResponseEntity<*> {
        val podId = podService.getCurrentPodId()

        return when (val result = bootstrapService.createPodChief(request.email, request.displayName, podId)) {
            is BootstrapResult.PodChiefCreated -> ResponseEntity.status(201).body(
                CreatePodChiefResponse(
                    id = result.admin.id.value.toString(),
                    email = result.admin.email,
                    displayName = result.admin.displayName,
                    role = result.admin.role.toDbValue(),
                    temporaryPassword = result.temporaryPassword,
                    createdAt = result.admin.createdAt.toString(),
                )
            )
            is BootstrapResult.EmailAlreadyExists -> ResponseEntity.status(409).body(
                mapOf("error" to "email_exists", "message" to "Email already in use")
            )
            is BootstrapResult.PodAlreadyBootstrapped -> ResponseEntity.status(409).body(
                mapOf("error" to "already_bootstrapped", "message" to "Pod Chief already exists")
            )
            is BootstrapResult.ValidationError -> ResponseEntity.badRequest().body(
                mapOf("error" to "validation_error", "messages" to result.errors)
            )
            is BootstrapResult.NotAuthorized -> ResponseEntity.status(403).body(
                mapOf("error" to "not_authorized", "message" to "Not authorized to create Pod Chief")
            )
            else -> ResponseEntity.internalServerError().body(
                mapOf("error" to "internal_error")
            )
        }
    }
}
```

#### 3. `bootstrap/service/BootstrapResult.kt`

```kotlin
package com.munserv.bootstrap.service

import com.munserv.admin.domain.Admin

sealed interface BootstrapResult {
    data class PodChiefCreated(val admin: Admin, val temporaryPassword: String) : BootstrapResult
    data object PodAlreadyBootstrapped : BootstrapResult
    data object NotAuthorized : BootstrapResult
    data class ValidationError(val errors: List<String>) : BootstrapResult
    data class EmailAlreadyExists(val email: String) : BootstrapResult
}
```

### Files To Modify

#### 1. `bootstrap/service/BootstrapService.kt` - Add createPodChief method

Add the following to the existing BootstrapService:

```kotlin
import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.shared.email.EmailService
import com.munserv.shared.types.AdminId
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.Clock
import java.time.Instant

// Add to constructor
@Service
class BootstrapService(
    private val adminRepository: AdminRepository,
    private val bootstrapConfig: BootstrapConfig,
    private val passwordEncoder: PasswordEncoder,
    private val emailService: EmailService,
    private val clock: Clock = Clock.systemUTC(),
) {
    // ... existing getStatus() and isBootstrapEnabled() methods ...

    /**
     * Create the first Pod Chief for a pod.
     *
     * @param email Pod Chief's email address
     * @param displayName Pod Chief's display name
     * @param podId The pod to create Pod Chief for
     * @return BootstrapResult indicating success or failure
     */
    @Transactional
    fun createPodChief(
        email: String,
        displayName: String,
        podId: PodId,
    ): BootstrapResult {
        // Validate inputs
        val errors = mutableListOf<String>()
        if (email.isBlank()) {
            errors.add("Email is required")
        } else if (!EMAIL_REGEX.matches(email)) {
            errors.add("Invalid email format")
        }
        if (displayName.isBlank()) {
            errors.add("Display name is required")
        }
        if (errors.isNotEmpty()) {
            return BootstrapResult.ValidationError(errors)
        }

        // Check if Pod Chief already exists
        if (adminRepository.findPodChief(podId) != null) {
            return BootstrapResult.PodAlreadyBootstrapped
        }

        // Check if email is already in use
        if (adminRepository.existsByEmail(email)) {
            return BootstrapResult.EmailAlreadyExists(email)
        }

        // Generate temporary password
        val temporaryPassword = generateTemporaryPassword()
        val passwordHash = passwordEncoder.encode(temporaryPassword)

        // Create Pod Chief
        val now = Instant.now(clock)
        val admin = Admin(
            id = AdminId.generate(),
            podId = podId,
            wardId = null,
            sectorId = null,
            email = email,
            displayName = displayName,
            role = AdminRole.POD_CHIEF,
            onboardingStatus = OnboardingStatus.PENDING,
            createdAt = now,
            updatedAt = now,
        )

        val savedAdmin = adminRepository.save(admin, passwordHash, temporaryPassword)

        // Send welcome email
        emailService.sendPodChiefWelcomeEmail(
            toEmail = email,
            displayName = displayName,
            tempPassword = temporaryPassword,
        )

        return BootstrapResult.PodChiefCreated(savedAdmin, temporaryPassword)
    }

    private fun generateTemporaryPassword(): String {
        val random = SecureRandom()
        return (1..TEMP_PASSWORD_LENGTH)
            .map { TEMP_PASSWORD_CHARS[random.nextInt(TEMP_PASSWORD_CHARS.size)] }
            .joinToString("")
    }

    companion object {
        private val EMAIL_REGEX = Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
        private const val TEMP_PASSWORD_LENGTH = 12
        private val TEMP_PASSWORD_CHARS = ('A'..'Z') + ('a'..'z') + ('0'..'9')
    }
}
```

#### 2. `shared/email/EmailService.kt` - Add welcome email method

Add this method to the existing EmailService:

```kotlin
/**
 * Sends welcome email to newly created Pod Chief.
 */
fun sendPodChiefWelcomeEmail(
    toEmail: String,
    displayName: String,
    tempPassword: String,
) {
    val originalSubject = "Welcome to $appName - Your Pod Chief Account"

    val body = """
        |Hello $displayName,
        |
        |You have been appointed as Pod Chief for your $appName pod.
        |
        |Please log in to the admin portal with the following credentials:
        |
        |Email: $toEmail
        |Temporary Password: $tempPassword
        |
        |IMPORTANT: You will be required to change your password on first login.
        |
        |After changing your password, you can optionally complete your profile
        |before accessing the dashboard.
        |
        |Admin Portal: ${getPortalUrl()}
        |
        |Password Requirements:
        |- At least 8 characters
        |- At least one uppercase letter (A-Z)
        |- At least one lowercase letter (a-z)
        |- At least one number (0-9)
        |
        |As Pod Chief, you will be responsible for:
        |- Setting up your pod configuration
        |- Managing pod administrators
        |- Overseeing issue resolution across the pod
        |
        |If you did not expect this email, please contact support.
        |
        |The $appName Team
        """.trimMargin()

    val effectiveRecipient = resolveRecipient(toEmail)
    val effectiveSubject = resolveSubject(originalSubject, toEmail)
    sendEmail(effectiveRecipient, effectiveSubject, body)
}
```

#### 3. `shared/config/SecurityConfig.kt` - Permit bootstrap endpoint

Add the bootstrap endpoint to the security configuration:

```kotlin
// In the security filter chain configuration
.requestMatchers("/api/v1/bootstrap/**").hasRole("SUPER_USER")
```

## Acceptance Criteria

- [ ] `POST /api/v1/bootstrap/pod-chief` endpoint exists
- [ ] Requires `SUPER_USER` role JWT
- [ ] Validates email format and display name
- [ ] Returns 409 if Pod Chief already exists
- [ ] Returns 409 if email already in use
- [ ] Returns 201 with temporary password on success
- [ ] Sends welcome email to new Pod Chief
- [ ] Pod Chief created with PENDING onboarding status
- [ ] Tests pass
- [ ] Quality checks pass (ktlint, test coverage)

## Dependencies

None - this can be implemented independently.

## Test Scenarios

1. **Happy path**: Super user creates Pod Chief -> returns 201 with temp password
2. **Pod already has Pod Chief**: Returns 409 with `already_bootstrapped` error
3. **Email already in use**: Returns 409 with `email_exists` error
4. **Invalid email format**: Returns 400 with validation error
5. **Empty display name**: Returns 400 with validation error
6. **Unauthorized (no SUPER_USER role)**: Returns 403

## Implementation Notes

### Changes Made

1. **Created `BootstrapResult.kt`** - Sealed interface for bootstrap operation results
   - `PodChiefCreated` - Success with admin and temporary password
   - `PodAlreadyBootstrapped` - Pod Chief already exists
   - `EmailAlreadyExists` - Email in use
   - `ValidationError` - Input validation failed
   - `NotAuthorized` - Authorization failed

2. **Created `BootstrapDto.kt`** - Request/response DTOs
   - `CreatePodChiefRequest` - email, displayName
   - `CreatePodChiefResponse` - includes temporaryPassword for one-time view
   - `BootstrapErrorResponse` - standard error format
   - `BootstrapValidationErrorResponse` - validation errors list

3. **Created `BootstrapController.kt`** - REST endpoint
   - `POST /api/v1/bootstrap/pod-chief`
   - Uses `@SecurityRequirement(name = "bearerAuth")` for SUPER_USER role
   - Full OpenAPI annotations for Swagger documentation

4. **Modified `BootstrapService.kt`** - Added createPodChief method
   - Added dependencies: PasswordEncoder, EmailService, Clock
   - Input validation (email format, display name required)
   - Checks for existing Pod Chief
   - Generates 12-character temporary password
   - Creates admin with PENDING onboarding status
   - Sends welcome email via EmailService

5. **Modified `EmailService.kt`** - Added sendPodChiefWelcomeEmail
   - Follows existing pattern from sendWelcomeEmail
   - Includes temp password and login instructions
   - Lists Pod Chief responsibilities

6. **Modified `SecurityConfig.kt`** - Added bootstrap endpoint protection
   - `.requestMatchers("/api/v1/bootstrap/**").hasRole("SUPER_USER")`

### Tests Added

Extended `BootstrapServiceTest.kt` with `CreatePodChief` nested class:
- Happy path: successful creation with temp password
- Welcome email sent
- PodAlreadyBootstrapped when Pod Chief exists
- EmailAlreadyExists when email taken
- ValidationError for blank email
- ValidationError for invalid email format
- ValidationError for blank displayName
- Multiple validation errors
- Password hashing verification
- Timestamp from clock verification

### Decisions Made

- Used existing `PodRepository.findFirst()` for single-pod MVP deployment
- Followed existing EmailService pattern with override recipient support
- 12-character alphanumeric temporary password (same as AdminManagementService)
- Validation regex matches existing CreateAdminCommand pattern

### Quality Checks

- ktlintCheck: PASSED
- Unit tests: PASSED (all bootstrap tests)
- Compilation: PASSED

### Note on Integration Tests

16 integration tests fail due to PostgreSQL connection issues (PSQLException).
These are pre-existing infrastructure/environment issues unrelated to this change:
- PodDashboardControllerTest (9 tests)
- SectorSettingsControllerTest (7 tests)

These tests use `@SpringBootTest` and require a running PostgreSQL database.
