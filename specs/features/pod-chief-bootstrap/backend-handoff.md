# Handoff: Backend

**Feature:** pod-chief-bootstrap
**Milestone:** [#2](https://github.com/ossewawiel/munserv/milestone/2)
**Stories:** B5, B6, B7, B8, W25
**Platform:** Kotlin + Spring Boot

---

## Context

Enable super user to bootstrap a fresh pod by creating the first Pod Chief. The super user is authenticated via configuration-based credentials (environment variables). After the Pod Chief completes onboarding, the super user loses bootstrap access but can later be granted temporary access for debugging/maintenance.

---

## Phase 1: Configuration & Repository (B5, B6)

### Files to Create

#### `bootstrap/config/BootstrapConfig.kt`

```kotlin
package com.munserv.bootstrap.config

import org.springframework.boot.context.properties.ConfigurationProperties

/**
 * Configuration properties for super user bootstrap.
 * Credentials must be set via environment variables.
 */
@ConfigurationProperties(prefix = "bootstrap.super-user")
data class BootstrapConfig(
    val email: String = "",
    val password: String = "",
    val enabled: Boolean = true,
)
```

#### `application.yml` additions

```yaml
bootstrap:
  super-user:
    email: ${SUPER_USER_EMAIL:}
    password: ${SUPER_USER_PASSWORD:}
    enabled: ${SUPER_USER_ENABLED:true}
```

### Files to Modify

#### `admin/repository/AdminRepository.kt`

Add these methods:

```kotlin
/**
 * Find the Pod Chief for a given pod.
 * Returns null if no Pod Chief exists.
 */
fun findPodChief(podId: PodId): Admin?

/**
 * Check if a Pod Chief exists and has completed onboarding.
 */
fun existsPodChiefOnboarded(podId: PodId): Boolean
```

#### `admin/repository/JpaAdminRepository.kt`

Implement:

```kotlin
override fun findPodChief(podId: PodId): Admin? =
    jpa.findByPodIdAndRoleAndDeletedAtIsNull(podId.value, "pod_chief")?.toDomain()

override fun existsPodChiefOnboarded(podId: PodId): Boolean =
    jpa.existsByPodIdAndRoleAndOnboardingStatusAndDeletedAtIsNull(
        podId.value,
        "pod_chief",
        "active"
    )
```

#### `admin/repository/SpringDataAdminRepository.kt`

Add JPA query methods:

```kotlin
fun findByPodIdAndRoleAndDeletedAtIsNull(podId: UUID, role: String): AdminEntity?

fun existsByPodIdAndRoleAndOnboardingStatusAndDeletedAtIsNull(
    podId: UUID,
    role: String,
    onboardingStatus: String
): Boolean
```

### Database Migration

#### `V034__bootstrap_indexes.sql`

```sql
-- Index for fast Pod Chief lookups
CREATE INDEX IF NOT EXISTS idx_admins_role_pod_id
ON admins(role, pod_id) WHERE deleted_at IS NULL;

-- Index for onboarding status queries
CREATE INDEX IF NOT EXISTS idx_admins_onboarding_status
ON admins(onboarding_status) WHERE deleted_at IS NULL;
```

---

## Phase 2: Bootstrap Service & Auth Integration (W22, W23, W24, W25)

### Architecture: Single Login Endpoint

**All admin logins use the existing `/api/v1/auth/admin/login` endpoint.**

The `AuthService.adminLogin()` method is modified to:
1. First check if credentials match super user config
2. If super user AND pod is eligible → return `SuperUserLoginSuccess`
3. Otherwise fall back to database admin lookup

### Files to Modify

#### `auth/service/AuthResult.kt` - Add super user result

Add this new result type to the existing `AuthResult` sealed interface:

```kotlin
// Add to existing AuthResult sealed interface
data class SuperUserLoginSuccess(
    val tokens: TokenPair,
    val podId: String,
    val bootstrapStatus: String,  // "requires_bootstrap" or "pod_chief_pending"
) : AuthResult
```

#### `auth/service/AuthService.kt` - Modify adminLogin()

Modify the existing `adminLogin()` method to check super user credentials first:

```kotlin
@Service
class AuthService(
    private val memberRepository: MemberRepository,
    private val otpService: OtpService,
    private val jwtService: JwtService,
    private val adminConfig: AdminConfig,
    private val adminRepository: AdminRepository,
    private val sectorRepository: SectorRepository,
    private val bootstrapConfig: BootstrapConfig,  // ADD THIS
    private val bootstrapService: BootstrapService, // ADD THIS
    private val podService: PodService,             // ADD THIS
) {
    companion object {
        private const val MEMBER_ROLE = "member"
        private const val ADMIN_ROLE = "admin"
        private const val SUPER_USER_ROLE = "super_user"  // ADD THIS
    }

    /**
     * Admin login with email and password.
     *
     * Checks super user credentials first, then falls back to database admin.
     */
    @Transactional(readOnly = true)
    fun adminLogin(
        email: String,
        password: String,
    ): AuthResult {
        val podId = podService.getCurrentPodId()

        // 1. Check if this is a super user login attempt
        if (bootstrapConfig.isConfigured() &&
            email == bootstrapConfig.email &&
            password == bootstrapConfig.password
        ) {
            return handleSuperUserLogin(podId)
        }

        // 2. Fall back to database admin lookup (existing code)
        val adminWithPassword =
            adminRepository.findByEmailWithPasswordHash(email)
                ?: return AuthResult.InvalidCredentials

        val admin = adminWithPassword.admin

        // Verify password
        if (!Password.verify(password, adminWithPassword.passwordHash)) {
            return AuthResult.InvalidCredentials
        }

        // Get sector details if admin has a sector
        val sector = admin.sectorId?.let { sectorRepository.findById(it) }

        val adminId = MemberId(admin.id.value)
        val tokens = jwtService.generateTokenPair(adminId, ADMIN_ROLE)

        return AuthResult.AdminLoginSuccess(
            adminId = admin.id.value.toString(),
            email = admin.email,
            displayName = admin.displayName,
            role = admin.role.toDbValue().uppercase(),
            level = admin.level.name.lowercase(),
            tokens = tokens,
            podId = admin.podId?.value?.toString(),
            wardId = admin.wardId?.value?.toString(),
            sectorId = admin.sectorId?.value?.toString(),
            sectorName = sector?.name,
            sectorCenterLat = sector?.center?.latitude,
            sectorCenterLng = sector?.center?.longitude,
            onboardingStatus = admin.onboardingStatus.toDbValue(),  // ADD THIS
        )
    }

    /**
     * Handle super user login for bootstrap.
     */
    private fun handleSuperUserLogin(podId: PodId): AuthResult {
        // Check bootstrap eligibility
        val status = bootstrapService.getStatus(podId)

        return when (status) {
            is BootstrapStatus.NotEligible -> {
                // Pod already bootstrapped - super user cannot log in
                AuthResult.InvalidCredentials
            }
            is BootstrapStatus.Eligible,
            is BootstrapStatus.PodChiefOnboarding -> {
                // Super user can log in
                val memberId = MemberId(UUID.randomUUID())
                val tokens = jwtService.generateTokenPair(memberId, SUPER_USER_ROLE)

                AuthResult.SuperUserLoginSuccess(
                    tokens = tokens,
                    podId = podId.value.toString(),
                    bootstrapStatus = when (status) {
                        is BootstrapStatus.Eligible -> "requires_bootstrap"
                        is BootstrapStatus.PodChiefOnboarding -> "pod_chief_pending"
                        else -> "unknown"
                    },
                )
            }
        }
    }

    // ... rest of existing methods unchanged
}
```

#### `auth/api/AuthController.kt` - Handle new result type

Modify the `adminLogin` endpoint to handle the new `SuperUserLoginSuccess` result:

```kotlin
@PostMapping("/admin/login")
fun adminLogin(
    @Valid @RequestBody request: AdminLoginRequest,
): ResponseEntity<*> =
    when (val result = authService.adminLogin(request.email, request.password)) {
        is AuthResult.AdminLoginSuccess -> {
            val expiresAt = java.time.Instant.now()
                .plusSeconds(result.tokens.expiresIn)
                .toString()

            val sector = if (result.sectorId != null && result.sectorName != null &&
                result.sectorCenterLat != null && result.sectorCenterLng != null
            ) {
                AdminSector(
                    id = result.sectorId,
                    name = result.sectorName,
                    center = GeoPointResponse(
                        lat = result.sectorCenterLat,
                        lng = result.sectorCenterLng,
                    ),
                )
            } else null

            ResponseEntity.ok(
                AdminLoginResponse(
                    tokens = AdminTokens(
                        accessToken = result.tokens.accessToken,
                        refreshToken = result.tokens.refreshToken,
                        expiresAt = expiresAt,
                    ),
                    profile = AdminProfile(
                        admin = AdminUser(
                            id = result.adminId,
                            email = result.email,
                            displayName = result.displayName,
                            role = result.role,
                            level = result.level,
                            podId = result.podId,
                            wardId = result.wardId,
                            sectorId = result.sectorId,
                            onboardingStatus = result.onboardingStatus,  // ADD THIS
                        ),
                        sector = sector,
                    ),
                ),
            )
        }

        // ADD THIS CASE
        is AuthResult.SuperUserLoginSuccess -> {
            val expiresAt = java.time.Instant.now()
                .plusSeconds(result.tokens.expiresIn)
                .toString()

            ResponseEntity.ok(
                AdminLoginResponse(
                    tokens = AdminTokens(
                        accessToken = result.tokens.accessToken,
                        refreshToken = result.tokens.refreshToken,
                        expiresAt = expiresAt,
                    ),
                    profile = AdminProfile(
                        admin = AdminUser(
                            id = "super-user",
                            email = "",  // Don't expose super user email
                            displayName = "Super User",
                            role = "SUPER_USER",
                            level = "system",
                            podId = result.podId,
                            wardId = null,
                            sectorId = null,
                            onboardingStatus = null,
                        ),
                        sector = null,
                        bootstrapStatus = result.bootstrapStatus,  // ADD THIS FIELD
                    ),
                ),
            )
        }

        is AuthResult.InvalidCredentials ->
            ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse("invalid_credentials", "Invalid email or password"))

        // ... other cases unchanged
    }
```

#### `auth/api/AuthResponse.kt` - Add fields

Update the response DTOs:

```kotlin
data class AdminUser(
    val id: String,
    val email: String,
    val displayName: String,
    val role: String,
    val level: String,
    val podId: String?,
    val wardId: String?,
    val sectorId: String?,
    val onboardingStatus: String? = null,  // ADD THIS
)

data class AdminProfile(
    val admin: AdminUser,
    val sector: AdminSector?,
    val bootstrapStatus: String? = null,  // ADD THIS - only set for super user
)
```

### Files to Create

#### `bootstrap/service/BootstrapResult.kt`

```kotlin
package com.munserv.bootstrap.service

import com.munserv.admin.domain.Admin

sealed interface BootstrapResult {
    data class PodChiefCreated(val admin: Admin, val temporaryPassword: String) : BootstrapResult
    data class StatusResult(val status: BootstrapStatus, val canBootstrap: Boolean) : BootstrapResult

    data object PodAlreadyBootstrapped : BootstrapResult
    data object NotAuthorized : BootstrapResult
    data class ValidationError(val errors: List<String>) : BootstrapResult
    data class EmailAlreadyExists(val email: String) : BootstrapResult
}
```

#### `bootstrap/api/BootstrapDto.kt`

```kotlin
package com.munserv.bootstrap.api

data class BootstrapStatusResponse(
    val status: String,
    val canBootstrap: Boolean,
    val message: String,
)

data class CreatePodChiefRequest(
    val email: String,
    val displayName: String,
)

data class CreatePodChiefResponse(
    val adminId: String,
    val email: String,
    val displayName: String,
    val temporaryPassword: String,
    val message: String,
)
```

#### `bootstrap/api/BootstrapController.kt`

Note: This controller only has status and create-pod-chief endpoints. Login is handled by AuthController.

```kotlin
package com.munserv.bootstrap.api

@RestController
@RequestMapping("/api/v1/bootstrap")
@Tag(name = "Bootstrap", description = "Pod bootstrap endpoints for super user")
class BootstrapController(
    private val bootstrapService: BootstrapService,
    private val podService: PodService,
) {
    @GetMapping("/status")
    @Operation(summary = "Check bootstrap status")
    fun getStatus(): ResponseEntity<BootstrapStatusResponse> {
        val podId = podService.getCurrentPodId()
        val status = bootstrapService.getStatus(podId)
        val canBootstrap = status is BootstrapStatus.Eligible && bootstrapService.isBootstrapEnabled()

        return ResponseEntity.ok(
            BootstrapStatusResponse(
                status = status.toStatusString(),
                canBootstrap = canBootstrap,
                message = status.toMessage(),
            )
        )
    }

    @PostMapping("/pod-chief")
    @Operation(summary = "Create Pod Chief")
    @SecurityRequirement(name = "bearerAuth")
    fun createPodChief(@RequestBody request: CreatePodChiefRequest): ResponseEntity<*> {
        val podId = podService.getCurrentPodId()
        return when (val result = bootstrapService.createPodChief(
            CreatePodChiefCommand(request.email, request.displayName), podId
        )) {
            is BootstrapResult.PodChiefCreated -> ResponseEntity.status(201).body(
                CreatePodChiefResponse(
                    adminId = result.admin.id.value.toString(),
                    email = result.admin.email,
                    displayName = result.admin.displayName,
                    temporaryPassword = result.temporaryPassword,
                    message = "Pod Chief created. Welcome email sent.",
                )
            )
            is BootstrapResult.EmailAlreadyExists -> ResponseEntity.status(409).body(
                mapOf("error" to "Email already in use")
            )
            is BootstrapResult.PodAlreadyBootstrapped -> ResponseEntity.status(409).body(
                mapOf("error" to "Pod Chief already exists")
            )
            else -> ResponseEntity.internalServerError().build()
        }
    }
}

private fun BootstrapStatus.toStatusString(): String = when (this) {
    is BootstrapStatus.Eligible -> "requires_bootstrap"
    is BootstrapStatus.PodChiefOnboarding -> "pod_chief_pending"
    is BootstrapStatus.NotEligible -> "bootstrapped"
}

private fun BootstrapStatus.toMessage(): String = when (this) {
    is BootstrapStatus.Eligible -> "Pod requires bootstrap - no Pod Chief exists"
    is BootstrapStatus.PodChiefOnboarding -> "Pod Chief exists but hasn't completed onboarding"
    is BootstrapStatus.NotEligible -> "Pod is fully bootstrapped"
}
```

#### `bootstrap/service/BootstrapService.kt` - Add createPodChief

Add the `createPodChief` method to the existing BootstrapService:

```kotlin
@Transactional
fun createPodChief(command: CreatePodChiefCommand, podId: PodId): BootstrapResult {
    // Validate pod doesn't already have a Pod Chief
    if (adminRepository.findPodChief(podId) != null) {
        return BootstrapResult.PodAlreadyBootstrapped
    }

    // Validate email not taken
    if (adminRepository.existsByEmail(command.email)) {
        return BootstrapResult.EmailAlreadyExists(command.email)
    }

    // Generate temporary password
    val temporaryPassword = generateTemporaryPassword()
    val passwordHash = passwordEncoder.encode(temporaryPassword)

    val now = Instant.now(clock)
    val admin = Admin(
        id = AdminId.generate(),
        podId = podId,
        email = command.email,
        displayName = command.displayName,
        role = AdminRole.POD_CHIEF,
        onboardingStatus = OnboardingStatus.PENDING,
        createdAt = now,
        updatedAt = now,
    )

    val savedAdmin = adminRepository.save(admin, passwordHash, temporaryPassword)

    // Send welcome email
    emailService.sendPodChiefWelcomeEmail(
        toEmail = command.email,
        displayName = command.displayName,
        tempPassword = temporaryPassword,
    )

    auditService.logPodChiefCreated(savedAdmin.id, podId)

    return BootstrapResult.PodChiefCreated(savedAdmin, temporaryPassword)
}

private fun generateTemporaryPassword(): String {
    val random = SecureRandom()
    val chars = ('A'..'Z') + ('a'..'z') + ('0'..'9')
    return (1..12).map { chars[random.nextInt(chars.size)] }.joinToString("")
}

data class CreatePodChiefCommand(
    val email: String,
    val displayName: String,
)
```
```

#### `shared/email/EmailService.kt` addition

Add this method to EmailService:

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

---

## Phase 3: Audit Logging (B7)

### Files to Create

#### `audit/service/AuditService.kt`

```kotlin
package com.munserv.audit.service

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

@Service
class AuditService {
    private val log = LoggerFactory.getLogger(AuditService::class.java)

    fun logBootstrapAttempt(email: String, result: String, podId: PodId) {
        log.info("AUDIT: Bootstrap attempt - email={}, result={}, podId={}",
            maskEmail(email), result, podId.value)
    }

    fun logPodChiefCreated(adminId: AdminId, podId: PodId) {
        log.info("AUDIT: Pod Chief created - adminId={}, podId={}",
            adminId.value, podId.value)
    }

    fun logSupportAccessGranted(grantId: UUID, grantedBy: AdminId, role: String, podId: PodId) {
        log.info("AUDIT: Support access granted - grantId={}, grantedBy={}, role={}, podId={}",
            grantId, grantedBy.value, role, podId.value)
    }

    fun logSupportAccessRevoked(grantId: UUID, revokedBy: AdminId, podId: PodId) {
        log.info("AUDIT: Support access revoked - grantId={}, revokedBy={}, podId={}",
            grantId, revokedBy.value, podId.value)
    }

    fun logSuperUserAction(action: String, grantId: UUID, podId: PodId) {
        log.info("AUDIT: Super user action - action={}, grantId={}, podId={}",
            action, grantId, podId.value)
    }

    private fun maskEmail(email: String): String {
        val parts = email.split("@")
        if (parts.size != 2) return "***"
        val local = parts[0]
        val maskedLocal = if (local.length <= 2) "*" else "${local.first()}***${local.last()}"
        return "$maskedLocal@${parts[1]}"
    }
}
```

---

## Phase 4: Support Access (B8)

### Database Migration

#### `V035__super_user_grants.sql`

```sql
-- Support access grants for super user
CREATE TABLE super_user_grants (
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

CREATE INDEX idx_super_user_grants_pod_status ON super_user_grants(pod_id, status);
CREATE INDEX idx_super_user_grants_expires ON super_user_grants(expires_at) WHERE status = 'active';

COMMENT ON TABLE super_user_grants IS 'Tracks temporary super user access grants for debugging/maintenance';
```

### Files to Create

#### `support/domain/SuperUserGrant.kt`

```kotlin
package com.munserv.support.domain

data class SuperUserGrant(
    val id: SuperUserGrantId,
    val podId: PodId,
    val grantedRole: AdminRole,
    val purpose: String,
    val grantedBy: AdminId,
    val grantedAt: Instant,
    val expiresAt: Instant,
    val lastActivity: Instant?,
    val status: GrantStatus,
    val revokedAt: Instant?,
    val revokedBy: AdminId?,
) {
    val isActive: Boolean get() = status == GrantStatus.ACTIVE

    fun isExpired(now: Instant): Boolean = now.isAfter(expiresAt)

    fun isInactiveFor(duration: Duration, now: Instant): Boolean {
        val lastActiveAt = lastActivity ?: grantedAt
        return now.isAfter(lastActiveAt.plus(duration))
    }
}

@JvmInline
value class SuperUserGrantId(val value: UUID) {
    companion object {
        fun generate(): SuperUserGrantId = SuperUserGrantId(UUID.randomUUID())
    }
}

enum class GrantStatus {
    ACTIVE, EXPIRED, REVOKED;

    fun toDbValue(): String = name.lowercase()

    companion object {
        fun fromDbValue(value: String): GrantStatus = valueOf(value.uppercase())
    }
}
```

#### `support/service/SupportAccessService.kt`

```kotlin
package com.munserv.support.service

@Service
class SupportAccessService(
    private val grantRepository: SuperUserGrantRepository,
    private val bootstrapConfig: BootstrapConfig,
    private val jwtService: JwtService,
    private val auditService: AuditService,
    private val clock: Clock = Clock.systemUTC(),
) {
    companion object {
        private val INACTIVITY_TIMEOUT = Duration.ofHours(1)
        private const val SUPER_USER_GRANT_ROLE_PREFIX = "super_user_grant:"
    }

    @Transactional
    fun createGrant(
        podId: PodId,
        grantedBy: AdminId,
        role: AdminRole,
        purpose: String,
    ): SupportAccessResult {
        val now = Instant.now(clock)
        val grant = SuperUserGrant(
            id = SuperUserGrantId.generate(),
            podId = podId,
            grantedRole = role,
            purpose = purpose,
            grantedBy = grantedBy,
            grantedAt = now,
            expiresAt = now.plus(INACTIVITY_TIMEOUT),
            lastActivity = null,
            status = GrantStatus.ACTIVE,
            revokedAt = null,
            revokedBy = null,
        )

        val saved = grantRepository.save(grant)
        auditService.logSupportAccessGranted(saved.id.value, grantedBy, role.name, podId)

        return SupportAccessResult.GrantCreated(saved)
    }

    fun loginWithGrant(email: String, password: String, podId: PodId): SupportAccessResult {
        // Verify super user credentials
        if (email != bootstrapConfig.email || password != bootstrapConfig.password) {
            return SupportAccessResult.InvalidCredentials
        }

        // Find active grant
        val grant = grantRepository.findActiveByPodId(podId)
            ?: return SupportAccessResult.NoActiveGrant

        // Check if grant is still valid
        val now = Instant.now(clock)
        if (grant.isExpired(now) || grant.isInactiveFor(INACTIVITY_TIMEOUT, now)) {
            expireGrant(grant.id)
            return SupportAccessResult.GrantExpired
        }

        // Generate token with granted role
        val memberId = MemberId(UUID.randomUUID())
        val tokens = jwtService.generateTokenPair(
            memberId,
            "${SUPER_USER_GRANT_ROLE_PREFIX}${grant.grantedRole.toDbValue()}"
        )

        return SupportAccessResult.LoginSuccess(tokens, grant)
    }

    @Transactional
    fun updateActivity(grantId: SuperUserGrantId) {
        val now = Instant.now(clock)
        grantRepository.updateLastActivity(grantId, now)
    }

    @Transactional
    fun revokeGrant(grantId: SuperUserGrantId, revokedBy: AdminId, podId: PodId): SupportAccessResult {
        val grant = grantRepository.findById(grantId)
            ?: return SupportAccessResult.NotFound

        if (grant.podId != podId) {
            return SupportAccessResult.NotAuthorized
        }

        val now = Instant.now(clock)
        val revoked = grant.copy(
            status = GrantStatus.REVOKED,
            revokedAt = now,
            revokedBy = revokedBy,
        )

        grantRepository.save(revoked)
        auditService.logSupportAccessRevoked(grantId.value, revokedBy, podId)

        return SupportAccessResult.GrantRevoked
    }

    @Transactional
    fun expireGrant(grantId: SuperUserGrantId) {
        grantRepository.updateStatus(grantId, GrantStatus.EXPIRED)
    }

    fun listGrants(podId: PodId): List<SuperUserGrant> =
        grantRepository.findByPodId(podId)
}
```

---

## Tests Required

### Unit Tests

- [ ] `BootstrapConfigTest` - Configuration loading
- [ ] `BootstrapServiceTest` - All service methods
- [ ] `SupportAccessServiceTest` - Grant creation, login, revocation
- [ ] `AuditServiceTest` - Logging verification

### Integration Tests

- [ ] `BootstrapControllerTest` - API contract tests
- [ ] `SupportAccessControllerTest` - API contract tests
- [ ] `JpaAdminRepositoryTest` - Pod Chief queries

### Test Scenarios

1. Fresh pod - super user can login and create Pod Chief
2. Pod Chief pending - super user can still login
3. Pod Chief onboarded - super user blocked from bootstrap
4. Invalid credentials - login rejected
5. Super user disabled - login rejected
6. Grant creation and login flow
7. Grant expiry on inactivity
8. Grant manual revocation

---

## Definition of Done

- [ ] All acceptance criteria met
- [ ] All unit tests passing (coverage > 80%)
- [ ] All integration tests passing
- [ ] `./gradlew ktlintCheck` passes
- [ ] `./gradlew test` passes
- [ ] OpenAPI documentation updated
- [ ] Security review: credentials never logged, rate limiting configured
- [ ] Audit logging verified
