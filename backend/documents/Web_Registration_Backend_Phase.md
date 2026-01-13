# Web Registration - Backend Phase Implementation

**Feature:** Member Registration via Web with Admin Approval
**Phase:** Backend (1 of 3)
**Status:** ✅ COMPLETE
**Dependencies:** None (must be completed first)

---

## 1. Overview

This phase implements the backend changes required to support web-based member registration with admin approval workflow. It replaces the SMS OTP-based registration with a cost-effective email-based system.

### 1.1 Goals
- Add `PendingApproval` member status
- Enable member registration without OTP (web form submission)
- Implement admin approval/rejection workflow
- Send welcome email with auto-generated temporary password
- Support email+password member login
- Force password change on first login

### 1.2 New Registration Flow
```
Web Form → PendingApproval → Admin Approves → Email Sent → Mobile Login → Password Change → PIN Setup
```

---

## 2. Domain Model Changes

### 2.1 MemberStatus Update

**File:** `src/main/kotlin/com/munserv/auth/domain/MemberStatus.kt`

**Current States:** Active, Suspended, Deleted

**Add:** `PendingApproval` state

```kotlin
sealed class MemberStatus {
    abstract val allowedTransitions: Set<MemberStatus>

    fun canTransitionTo(newStatus: MemberStatus): Boolean =
        allowedTransitions.contains(newStatus)

    // NEW: Registration pending admin approval
    object PendingApproval : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = setOf(Active, Deleted)
        override fun toString(): String = "pending_approval"
    }

    object Active : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = setOf(Suspended, Deleted)
        override fun toString(): String = "active"
    }

    object Suspended : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = setOf(Active, Deleted)
        override fun toString(): String = "suspended"
    }

    object Deleted : MemberStatus() {
        override val allowedTransitions: Set<MemberStatus> = emptySet()
        override fun toString(): String = "deleted"
    }

    companion object {
        fun fromString(value: String): MemberStatus =
            when (value.lowercase()) {
                "pending_approval" -> PendingApproval
                "active" -> Active
                "suspended" -> Suspended
                "deleted" -> Deleted
                else -> throw IllegalArgumentException("Unknown member status: $value")
            }
    }
}
```

**State Transition Diagram:**
```
[PendingApproval] ──approve──► [Active] ◄──unsuspend──► [Suspended]
        │                          │                         │
        │                          ▼                         ▼
        └─────reject─────────► [Deleted] ◄────delete────────┘
```

### 2.2 Member Entity Update

**File:** `src/main/kotlin/com/munserv/auth/domain/Member.kt`

Add new fields to the domain entity:

```kotlin
data class Member(
    val id: MemberId,
    val sectorId: SectorId,

    // Authentication fields
    val email: String,                           // NEW: unique email address
    val emailHash: String,                       // NEW: SHA-256 hash for lookups
    val passwordHash: String?,                   // NEW: BCrypt hash (null until approved)
    val mustChangePassword: Boolean = true,      // NEW: force password change flag

    // Existing fields (now optional for backwards compatibility)
    val phoneHash: String?,                      // CHANGED: now nullable
    val pinHash: String?,                        // CHANGED: now nullable

    // Profile fields
    val firstName: String,
    val surname: String,
    val phone: String,                           // NEW: plain phone for contact (not auth)
    val address: String,
    val registrationLocation: GeoPoint,

    // Status
    val status: MemberStatus = MemberStatus.PendingApproval,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    val fullName: String get() = "$firstName $surname"
    val isActive: Boolean get() = status == MemberStatus.Active
    val canLogin: Boolean get() = status == MemberStatus.Active && passwordHash != null

    fun canTransitionTo(newStatus: MemberStatus): Boolean =
        status.canTransitionTo(newStatus)

    fun withStatus(newStatus: MemberStatus): Member =
        copy(status = newStatus, updatedAt = Instant.now())

    fun withPassword(hash: String, mustChange: Boolean = true): Member =
        copy(passwordHash = hash, mustChangePassword = mustChange, updatedAt = Instant.now())

    fun withPinHash(hash: String): Member =
        copy(pinHash = hash, updatedAt = Instant.now())

    fun clearMustChangePassword(): Member =
        copy(mustChangePassword = false, updatedAt = Instant.now())
}
```

### 2.3 New Value Object: Email

**New File:** `src/main/kotlin/com/munserv/auth/domain/Email.kt`

```kotlin
package com.munserv.auth.domain

import java.security.MessageDigest

/**
 * Value object representing a validated email address.
 * Provides hashing for privacy-preserving lookups and masking for display.
 */
@JvmInline
value class Email private constructor(val value: String) {

    /**
     * Returns SHA-256 hash for database lookups.
     * Never store plain email for query purposes.
     */
    fun hash(): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(value.lowercase().toByteArray())
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    /**
     * Returns masked email for display: j***@example.com
     */
    fun masked(): String {
        val parts = value.split("@")
        if (parts.size != 2) return "***@***"

        val local = parts[0]
        val domain = parts[1]

        val maskedLocal = if (local.length <= 2) {
            "*".repeat(local.length)
        } else {
            local.first() + "*".repeat(local.length - 2) + local.last()
        }

        return "$maskedLocal@$domain"
    }

    override fun toString(): String = masked()

    companion object {
        private val EMAIL_REGEX = Regex(
            "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\$"
        )

        /**
         * Creates Email from string, validating format.
         * @throws IllegalArgumentException if email format is invalid
         */
        fun fromString(value: String): Email {
            val trimmed = value.trim().lowercase()
            require(isValid(trimmed)) { "Invalid email format: $value" }
            return Email(trimmed)
        }

        /**
         * Validates email format without creating instance.
         */
        fun isValid(email: String): Boolean =
            email.isNotBlank() && EMAIL_REGEX.matches(email.trim())

        /**
         * Attempts to create Email, returning null if invalid.
         */
        fun fromStringOrNull(value: String): Email? =
            runCatching { fromString(value) }.getOrNull()
    }
}
```

### 2.4 New Value Object: Password

**New File:** `src/main/kotlin/com/munserv/auth/domain/Password.kt`

```kotlin
package com.munserv.auth.domain

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import java.security.SecureRandom

/**
 * Password utilities for hashing, validation, and generation.
 * Uses BCrypt with cost factor 12 for secure hashing.
 */
object Password {
    private val encoder = BCryptPasswordEncoder(12)
    private val secureRandom = SecureRandom()

    // Password requirements
    const val MIN_LENGTH = 8
    private val UPPERCASE_REGEX = Regex("[A-Z]")
    private val LOWERCASE_REGEX = Regex("[a-z]")
    private val DIGIT_REGEX = Regex("[0-9]")

    /**
     * Hashes a plain-text password using BCrypt.
     */
    fun hash(plaintext: String): String = encoder.encode(plaintext)

    /**
     * Verifies a plain-text password against a BCrypt hash.
     * Returns false for invalid input instead of throwing.
     */
    fun verify(plaintext: String, hash: String): Boolean = runCatching {
        encoder.matches(plaintext, hash)
    }.getOrDefault(false)

    /**
     * Validates password meets requirements.
     * Returns list of validation errors (empty if valid).
     */
    fun validate(password: String): List<String> {
        val errors = mutableListOf<String>()

        if (password.length < MIN_LENGTH) {
            errors.add("Password must be at least $MIN_LENGTH characters")
        }
        if (!UPPERCASE_REGEX.containsMatchIn(password)) {
            errors.add("Password must contain at least one uppercase letter")
        }
        if (!LOWERCASE_REGEX.containsMatchIn(password)) {
            errors.add("Password must contain at least one lowercase letter")
        }
        if (!DIGIT_REGEX.containsMatchIn(password)) {
            errors.add("Password must contain at least one number")
        }

        return errors
    }

    /**
     * Checks if password is valid (meets all requirements).
     */
    fun isValid(password: String): Boolean = validate(password).isEmpty()

    /**
     * Generates a secure random password that meets all requirements.
     * Format: 4 random chars + 4 digits + 4 random chars (mix of upper/lower)
     * Example: Xk7m4829Np2q
     */
    fun generate(length: Int = 12): String {
        require(length >= 8) { "Password length must be at least 8" }

        val uppercase = "ABCDEFGHJKLMNPQRSTUVWXYZ"  // Excluded I, O
        val lowercase = "abcdefghjkmnpqrstuvwxyz"   // Excluded i, l, o
        val digits = "23456789"                      // Excluded 0, 1

        val password = StringBuilder()

        // Ensure at least one of each required type
        password.append(uppercase[secureRandom.nextInt(uppercase.length)])
        password.append(lowercase[secureRandom.nextInt(lowercase.length)])
        password.append(digits[secureRandom.nextInt(digits.length)])
        password.append(digits[secureRandom.nextInt(digits.length)])

        // Fill remaining with mixed characters
        val allChars = uppercase + lowercase + digits
        repeat(length - 4) {
            password.append(allChars[secureRandom.nextInt(allChars.length)])
        }

        // Shuffle to randomize position of required characters
        return password.toString().toList().shuffled(secureRandom).joinToString("")
    }
}
```

---

## 3. Repository Layer Changes

### 3.1 MemberEntity Update

**File:** `src/main/kotlin/com/munserv/auth/repository/MemberEntity.kt`

```kotlin
@Entity
@Table(name = "members")
class MemberEntity(
    @Id
    val id: UUID,

    @Column(name = "sector_id", nullable = false)
    val sectorId: UUID,

    // NEW: Email fields
    @Column(nullable = false, length = 255)
    val email: String,

    @Column(name = "email_hash", nullable = false, length = 64)
    val emailHash: String,

    @Column(name = "password_hash", length = 60)
    val passwordHash: String?,

    @Column(name = "must_change_password", nullable = false)
    val mustChangePassword: Boolean = true,

    // EXISTING (now nullable)
    @Column(name = "phone_hash", length = 64)
    val phoneHash: String?,

    @Column(name = "pin_hash", length = 64)
    val pinHash: String?,

    // Contact info (not for auth)
    @Column(length = 20)
    val phone: String?,

    // Profile
    @Column(name = "first_name", nullable = false, length = 50)
    val firstName: String,

    @Column(nullable = false, length = 50)
    val surname: String,

    @Column(columnDefinition = "TEXT", nullable = false)
    val address: String,

    @Column(name = "registration_location", columnDefinition = "geography(Point,4326)", nullable = false)
    val registrationLocation: Point,

    @Column(nullable = false, length = 20)
    val status: String,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,

    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,

    @Column(name = "deleted_at")
    val deletedAt: Instant? = null,
) {
    fun toDomain(): Member = Member(
        id = MemberId(id),
        sectorId = SectorId(sectorId),
        email = email,
        emailHash = emailHash,
        passwordHash = passwordHash,
        mustChangePassword = mustChangePassword,
        phoneHash = phoneHash,
        pinHash = pinHash,
        phone = phone ?: "",
        firstName = firstName,
        surname = surname,
        address = address,
        registrationLocation = GeoPoint(
            registrationLocation.y,  // latitude
            registrationLocation.x   // longitude
        ),
        status = MemberStatus.fromString(status),
        createdAt = createdAt,
        updatedAt = updatedAt,
    )

    companion object {
        fun fromDomain(member: Member): MemberEntity {
            val point = GeometryFactory(PrecisionModel(), 4326).createPoint(
                Coordinate(
                    member.registrationLocation.longitude,
                    member.registrationLocation.latitude
                )
            )
            return MemberEntity(
                id = member.id.value,
                sectorId = member.sectorId.value,
                email = member.email,
                emailHash = member.emailHash,
                passwordHash = member.passwordHash,
                mustChangePassword = member.mustChangePassword,
                phoneHash = member.phoneHash,
                pinHash = member.pinHash,
                phone = member.phone,
                firstName = member.firstName,
                surname = member.surname,
                address = member.address,
                registrationLocation = point,
                status = member.status.toString(),
                createdAt = member.createdAt,
                updatedAt = member.updatedAt,
            )
        }
    }
}
```

### 3.2 MemberRepository Interface Update

**File:** `src/main/kotlin/com/munserv/auth/repository/MemberRepository.kt`

```kotlin
interface MemberRepository {
    fun findById(id: MemberId): Member?
    fun findByPhoneHash(phoneHash: String): Member?
    fun findByEmailHash(emailHash: String): Member?  // NEW
    fun findBySectorId(sectorId: SectorId): List<Member>
    fun findBySectorIdAndStatus(sectorId: SectorId, status: MemberStatus): List<Member>  // NEW
    fun save(member: Member): Member
    fun delete(id: MemberId)  // NEW
    fun existsByPhoneHash(phoneHash: String): Boolean
    fun existsByEmailHash(emailHash: String): Boolean  // NEW
}
```

### 3.3 JpaMemberRepository Update

**File:** `src/main/kotlin/com/munserv/auth/repository/JpaMemberRepository.kt`

Add implementations for new methods:

```kotlin
@Repository
class JpaMemberRepository(
    private val jpa: MemberJpaRepository
) : MemberRepository {

    override fun findByEmailHash(emailHash: String): Member? =
        jpa.findByEmailHash(emailHash)?.toDomain()

    override fun existsByEmailHash(emailHash: String): Boolean =
        jpa.existsByEmailHash(emailHash)

    override fun findBySectorIdAndStatus(sectorId: SectorId, status: MemberStatus): List<Member> =
        jpa.findBySectorIdAndStatus(sectorId.value, status.toString())
            .map { it.toDomain() }

    override fun delete(id: MemberId) {
        jpa.deleteById(id.value)
    }

    // ... existing methods
}

interface MemberJpaRepository : JpaRepository<MemberEntity, UUID> {
    fun findByPhoneHash(phoneHash: String): MemberEntity?
    fun findByEmailHash(emailHash: String): MemberEntity?
    fun existsByPhoneHash(phoneHash: String): Boolean
    fun existsByEmailHash(emailHash: String): Boolean

    @Query("SELECT m FROM MemberEntity m WHERE m.sectorId = :sectorId AND m.status = :status")
    fun findBySectorIdAndStatus(sectorId: UUID, status: String): List<MemberEntity>
}
```

---

## 4. Service Layer

### 4.1 New RegistrationService

**New File:** `src/main/kotlin/com/munserv/auth/service/RegistrationService.kt`

```kotlin
package com.munserv.auth.service

import com.munserv.auth.domain.*
import com.munserv.auth.repository.MemberRepository
import com.munserv.sectors.service.SectorService
import com.munserv.shared.email.EmailService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant
import java.util.UUID

/**
 * Handles web-based member registration and admin approval workflow.
 */
@Service
class RegistrationService(
    private val memberRepository: MemberRepository,
    private val sectorService: SectorService,
    private val emailService: EmailService,
    private val clock: Clock,
) {
    /**
     * Registers a new member from web form submission.
     * Creates member with PendingApproval status.
     */
    @Transactional
    fun registerMember(command: WebRegistrationCommand): RegistrationResult {
        // Validate email format
        val email = Email.fromStringOrNull(command.email)
            ?: return RegistrationResult.ValidationError(
                listOf("Invalid email format")
            )

        // Check if email already registered
        if (memberRepository.existsByEmailHash(email.hash())) {
            return RegistrationResult.EmailAlreadyRegistered
        }

        // Validate sector exists
        val sector = sectorService.findById(command.sectorId)
            ?: return RegistrationResult.InvalidSector

        // Create member with PendingApproval status
        val now = Instant.now(clock)
        val member = Member(
            id = MemberId(UUID.randomUUID()),
            sectorId = command.sectorId,
            email = email.value,
            emailHash = email.hash(),
            passwordHash = null,  // Set on approval
            mustChangePassword = true,
            phoneHash = null,
            pinHash = null,
            phone = command.phone,
            firstName = command.firstName.trim(),
            surname = command.surname.trim(),
            address = command.address.trim(),
            registrationLocation = command.location,
            status = MemberStatus.PendingApproval,
            createdAt = now,
            updatedAt = now,
        )

        val saved = memberRepository.save(member)
        return RegistrationResult.Success(saved)
    }

    /**
     * Approves a pending member registration.
     * Generates temporary password and sends welcome email.
     */
    @Transactional
    fun approveMember(memberId: MemberId): RegistrationResult {
        val member = memberRepository.findById(memberId)
            ?: return RegistrationResult.MemberNotFound

        // Must be pending approval
        if (member.status != MemberStatus.PendingApproval) {
            return RegistrationResult.InvalidStatus(
                current = member.status.toString(),
                expected = "pending_approval"
            )
        }

        // Generate temporary password
        val tempPassword = Password.generate()
        val passwordHash = Password.hash(tempPassword)

        // Update member status and set password
        val approved = member
            .withStatus(MemberStatus.Active)
            .withPassword(passwordHash, mustChange = true)

        val saved = memberRepository.save(approved)

        // Send welcome email
        emailService.sendWelcomeEmail(
            toEmail = saved.email,
            memberName = saved.fullName,
            tempPassword = tempPassword,
        )

        return RegistrationResult.Approved(saved)
    }

    /**
     * Rejects a pending member registration.
     * Deletes the member record.
     */
    @Transactional
    fun rejectMember(memberId: MemberId): RegistrationResult {
        val member = memberRepository.findById(memberId)
            ?: return RegistrationResult.MemberNotFound

        // Must be pending approval
        if (member.status != MemberStatus.PendingApproval) {
            return RegistrationResult.InvalidStatus(
                current = member.status.toString(),
                expected = "pending_approval"
            )
        }

        // Delete the record
        memberRepository.delete(memberId)
        return RegistrationResult.Rejected(memberId)
    }
}

/**
 * Command object for web registration.
 */
data class WebRegistrationCommand(
    val email: String,
    val firstName: String,
    val surname: String,
    val phone: String,
    val address: String,
    val location: GeoPoint,
    val sectorId: SectorId,
)

/**
 * Sealed interface for registration operation results.
 */
sealed interface RegistrationResult {
    data class Success(val member: Member) : RegistrationResult
    data class Approved(val member: Member) : RegistrationResult
    data class Rejected(val memberId: MemberId) : RegistrationResult
    data object EmailAlreadyRegistered : RegistrationResult
    data object MemberNotFound : RegistrationResult
    data object InvalidSector : RegistrationResult
    data class InvalidStatus(val current: String, val expected: String) : RegistrationResult
    data class ValidationError(val errors: List<String>) : RegistrationResult
}
```

### 4.2 AuthService Updates

**File:** `src/main/kotlin/com/munserv/auth/service/AuthService.kt`

Add new methods for email-based authentication:

```kotlin
/**
 * Authenticates a member using email and password.
 * Used by mobile app after admin approval.
 */
fun loginWithEmail(emailString: String, password: String): AuthResult {
    // Validate email format
    val email = Email.fromStringOrNull(emailString)
        ?: return AuthResult.InvalidCredentials

    // Find member by email
    val member = memberRepository.findByEmailHash(email.hash())
        ?: return AuthResult.InvalidCredentials

    // Check member can login
    when (member.status) {
        MemberStatus.PendingApproval -> return AuthResult.PendingApproval
        MemberStatus.Suspended -> return AuthResult.AccountSuspended
        MemberStatus.Deleted -> return AuthResult.InvalidCredentials
        MemberStatus.Active -> { /* OK */ }
    }

    // Must have password set (approved by admin)
    val passwordHash = member.passwordHash
        ?: return AuthResult.PendingApproval

    // Verify password
    if (!Password.verify(password, passwordHash)) {
        return AuthResult.InvalidCredentials
    }

    // Generate tokens
    val tokens = jwtService.generateTokenPair(member.id, MEMBER_ROLE)

    return AuthResult.MemberLoginSuccess(
        memberId = member.id,
        tokens = tokens,
        mustChangePassword = member.mustChangePassword,
    )
}

/**
 * Changes a member's password.
 * Used for first-time password change after approval.
 */
@Transactional
fun changePassword(
    memberId: MemberId,
    currentPassword: String,
    newPassword: String,
): AuthResult {
    val member = memberRepository.findById(memberId)
        ?: return AuthResult.MemberNotFound

    // Must have existing password
    val currentHash = member.passwordHash
        ?: return AuthResult.InvalidCredentials

    // Verify current password
    if (!Password.verify(currentPassword, currentHash)) {
        return AuthResult.InvalidCredentials
    }

    // Validate new password
    val validationErrors = Password.validate(newPassword)
    if (validationErrors.isNotEmpty()) {
        return AuthResult.ValidationError(validationErrors)
    }

    // Update password
    val updated = member
        .withPassword(Password.hash(newPassword), mustChange = false)
    memberRepository.save(updated)

    return AuthResult.PasswordChanged(memberId)
}

companion object {
    const val MEMBER_ROLE = "member"
    const val ADMIN_ROLE = "admin"
}
```

### 4.3 AuthResult Updates

**File:** `src/main/kotlin/com/munserv/auth/service/AuthResult.kt`

Add new result types:

```kotlin
sealed interface AuthResult {
    // Existing results...

    // NEW: Member email+password login
    data class MemberLoginSuccess(
        val memberId: MemberId,
        val tokens: TokenPair,
        val mustChangePassword: Boolean,
    ) : AuthResult

    // NEW: Password changed successfully
    data class PasswordChanged(val memberId: MemberId) : AuthResult

    // NEW: Member not found
    data object MemberNotFound : AuthResult

    // NEW: Registration pending admin approval
    data object PendingApproval : AuthResult
}
```

---

## 5. Email Service

### 5.1 EmailService Implementation

**New File:** `src/main/kotlin/com/munserv/shared/email/EmailService.kt`

```kotlin
package com.munserv.shared.email

import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.stereotype.Service

/**
 * Service for sending emails via SMTP.
 */
@Service
class EmailService(
    private val mailSender: JavaMailSender,
    @Value("\${munserv.email.from:noreply@munserv.app}")
    private val fromAddress: String,
    @Value("\${munserv.app.name:MunServ}")
    private val appName: String,
    @Value("\${munserv.app.download-url:https://munserv.app/download}")
    private val downloadUrl: String,
) {
    private val log = LoggerFactory.getLogger(EmailService::class.java)

    /**
     * Sends welcome email to newly approved member.
     * Includes temporary password and app download link.
     */
    fun sendWelcomeEmail(
        toEmail: String,
        memberName: String,
        tempPassword: String,
    ) {
        val subject = "Welcome to $appName - Your Account is Approved!"

        val body = """
            |Hello $memberName,
            |
            |Great news! Your registration with $appName has been approved.
            |
            |You can now download the mobile app and log in with the following credentials:
            |
            |Email: $toEmail
            |Temporary Password: $tempPassword
            |
            |IMPORTANT: You will be required to change your password on first login.
            |
            |Download the app:
            |$downloadUrl
            |
            |Password Requirements:
            |- At least 8 characters
            |- At least one uppercase letter (A-Z)
            |- At least one lowercase letter (a-z)
            |- At least one number (0-9)
            |
            |If you did not register for $appName, please ignore this email.
            |
            |Thank you for joining our community!
            |
            |The $appName Team
        """.trimMargin()

        sendEmail(toEmail, subject, body)
    }

    /**
     * Sends a simple email.
     */
    private fun sendEmail(to: String, subject: String, body: String) {
        try {
            val message = SimpleMailMessage().apply {
                setFrom(fromAddress)
                setTo(to)
                setSubject(subject)
                setText(body)
            }
            mailSender.send(message)
            log.info("Email sent to: ${maskEmail(to)}")
        } catch (e: Exception) {
            log.error("Failed to send email to: ${maskEmail(to)}", e)
            throw EmailSendException("Failed to send email", e)
        }
    }

    private fun maskEmail(email: String): String {
        val parts = email.split("@")
        if (parts.size != 2) return "***"
        val local = parts[0]
        val maskedLocal = if (local.length <= 2) "*" else "${local.first()}***${local.last()}"
        return "$maskedLocal@${parts[1]}"
    }
}

class EmailSendException(message: String, cause: Throwable) : RuntimeException(message, cause)
```

### 5.2 Email Configuration

**File:** `src/main/resources/application.yml`

Add SMTP configuration:

```yaml
spring:
  mail:
    host: ${SMTP_HOST:smtp.gmail.com}
    port: ${SMTP_PORT:587}
    username: ${SMTP_USERNAME:}
    password: ${SMTP_PASSWORD:}
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true
            required: true
          connectiontimeout: 5000
          timeout: 5000
          writetimeout: 5000

munserv:
  email:
    from: ${EMAIL_FROM:noreply@munserv.app}
  app:
    name: ${APP_NAME:MunServ}
    download-url: ${APP_DOWNLOAD_URL:https://play.google.com/store/apps/details?id=com.munserv}
```

---

## 6. API Layer

### 6.1 AuthController Updates

**File:** `src/main/kotlin/com/munserv/auth/api/AuthController.kt`

Add new endpoints:

```kotlin
/**
 * Public registration for web form submissions.
 * Creates member with PendingApproval status.
 */
@Operation(summary = "Register member via web form")
@ApiResponses(
    ApiResponse(responseCode = "201", description = "Registration submitted"),
    ApiResponse(responseCode = "400", description = "Validation error"),
    ApiResponse(responseCode = "409", description = "Email already registered"),
)
@PostMapping("/register/web")
fun registerWeb(
    @Valid @RequestBody request: WebRegisterRequest
): ResponseEntity<*> {
    val command = WebRegistrationCommand(
        email = request.email,
        firstName = request.firstName,
        surname = request.surname,
        phone = request.phone,
        address = request.address,
        location = GeoPoint(request.latitude, request.longitude),
        sectorId = SectorId(UUID.fromString(request.sectorId)),
    )

    return when (val result = registrationService.registerMember(command)) {
        is RegistrationResult.Success -> ResponseEntity
            .status(HttpStatus.CREATED)
            .body(WebRegisterResponse(
                message = "Registration submitted. You will be notified once approved.",
                memberId = result.member.id.value.toString(),
            ))
        is RegistrationResult.EmailAlreadyRegistered -> ResponseEntity
            .status(HttpStatus.CONFLICT)
            .body(ErrorResponse("email_registered", "Email address already registered"))
        is RegistrationResult.InvalidSector -> ResponseEntity
            .badRequest()
            .body(ErrorResponse("invalid_sector", "Invalid sector ID"))
        is RegistrationResult.ValidationError -> ResponseEntity
            .badRequest()
            .body(ErrorResponse("validation_error", result.errors.joinToString(", ")))
        else -> ResponseEntity.internalServerError().build()
    }
}

/**
 * Member login with email and password.
 * Used by mobile app after admin approval.
 */
@Operation(summary = "Member login with email and password")
@ApiResponses(
    ApiResponse(responseCode = "200", description = "Login successful"),
    ApiResponse(responseCode = "401", description = "Invalid credentials"),
    ApiResponse(responseCode = "403", description = "Account pending or suspended"),
)
@PostMapping("/member/login")
fun memberLogin(
    @Valid @RequestBody request: MemberLoginRequest
): ResponseEntity<*> = when (val result = authService.loginWithEmail(request.email, request.password)) {
    is AuthResult.MemberLoginSuccess -> ResponseEntity.ok(
        MemberLoginResponse(
            memberId = result.memberId.value.toString(),
            accessToken = result.tokens.accessToken,
            refreshToken = result.tokens.refreshToken,
            expiresIn = result.tokens.expiresIn,
            mustChangePassword = result.mustChangePassword,
        )
    )
    is AuthResult.InvalidCredentials -> ResponseEntity
        .status(HttpStatus.UNAUTHORIZED)
        .body(ErrorResponse("invalid_credentials", "Invalid email or password"))
    is AuthResult.PendingApproval -> ResponseEntity
        .status(HttpStatus.FORBIDDEN)
        .body(ErrorResponse("pending_approval", "Your registration is pending admin approval"))
    is AuthResult.AccountSuspended -> ResponseEntity
        .status(HttpStatus.FORBIDDEN)
        .body(ErrorResponse("account_suspended", "Your account has been suspended"))
    else -> ResponseEntity.internalServerError().build()
}

/**
 * Change password for authenticated member.
 */
@Operation(summary = "Change member password")
@SecurityRequirement(name = "bearerAuth")
@ApiResponses(
    ApiResponse(responseCode = "200", description = "Password changed"),
    ApiResponse(responseCode = "400", description = "Validation error"),
    ApiResponse(responseCode = "401", description = "Invalid current password"),
)
@PostMapping("/change-password")
fun changePassword(
    @AuthenticationPrincipal memberId: String,
    @Valid @RequestBody request: ChangePasswordRequest
): ResponseEntity<*> = when (val result = authService.changePassword(
    MemberId(UUID.fromString(memberId)),
    request.currentPassword,
    request.newPassword,
)) {
    is AuthResult.PasswordChanged -> ResponseEntity.ok(
        MessageResponse("Password changed successfully")
    )
    is AuthResult.InvalidCredentials -> ResponseEntity
        .status(HttpStatus.UNAUTHORIZED)
        .body(ErrorResponse("invalid_password", "Current password is incorrect"))
    is AuthResult.ValidationError -> ResponseEntity
        .badRequest()
        .body(ErrorResponse("validation_error", result.errors.joinToString(", ")))
    is AuthResult.MemberNotFound -> ResponseEntity
        .status(HttpStatus.UNAUTHORIZED)
        .body(ErrorResponse("not_found", "Member not found"))
    else -> ResponseEntity.internalServerError().build()
}
```

### 6.2 AdminController Updates

**File:** `src/main/kotlin/com/munserv/admin/api/AdminController.kt`

Add member approval/rejection endpoints:

```kotlin
/**
 * Approve a pending member registration.
 * Generates temporary password and sends welcome email.
 */
@Operation(summary = "Approve pending member registration")
@SecurityRequirement(name = "bearerAuth")
@ApiResponses(
    ApiResponse(responseCode = "200", description = "Member approved"),
    ApiResponse(responseCode = "400", description = "Invalid status"),
    ApiResponse(responseCode = "404", description = "Member not found"),
)
@PostMapping("/members/{id}/approve")
fun approveMember(
    @PathVariable id: String
): ResponseEntity<*> = when (val result = registrationService.approveMember(MemberId(UUID.fromString(id)))) {
    is RegistrationResult.Approved -> ResponseEntity.ok(
        MemberApprovedResponse(
            memberId = result.member.id.value.toString(),
            email = result.member.email,
            message = "Member approved. Welcome email sent.",
        )
    )
    is RegistrationResult.MemberNotFound -> ResponseEntity
        .status(HttpStatus.NOT_FOUND)
        .body(ErrorResponse("not_found", "Member not found"))
    is RegistrationResult.InvalidStatus -> ResponseEntity
        .badRequest()
        .body(ErrorResponse(
            "invalid_status",
            "Member status is ${result.current}, expected ${result.expected}"
        ))
    else -> ResponseEntity.internalServerError().build()
}

/**
 * Reject a pending member registration.
 * Deletes the member record.
 */
@Operation(summary = "Reject pending member registration")
@SecurityRequirement(name = "bearerAuth")
@ApiResponses(
    ApiResponse(responseCode = "204", description = "Member rejected"),
    ApiResponse(responseCode = "400", description = "Invalid status"),
    ApiResponse(responseCode = "404", description = "Member not found"),
)
@DeleteMapping("/members/{id}")
fun rejectMember(
    @PathVariable id: String
): ResponseEntity<*> = when (val result = registrationService.rejectMember(MemberId(UUID.fromString(id)))) {
    is RegistrationResult.Rejected -> ResponseEntity.noContent().build()
    is RegistrationResult.MemberNotFound -> ResponseEntity
        .status(HttpStatus.NOT_FOUND)
        .body(ErrorResponse("not_found", "Member not found"))
    is RegistrationResult.InvalidStatus -> ResponseEntity
        .badRequest()
        .body(ErrorResponse(
            "invalid_status",
            "Member status is ${result.current}, expected ${result.expected}"
        ))
    else -> ResponseEntity.internalServerError().build()
}

/**
 * List members with optional status filter.
 */
@Operation(summary = "List members in sector")
@SecurityRequirement(name = "bearerAuth")
@GetMapping("/members")
fun getMembers(
    @Parameter(description = "Sector ID") @RequestParam sectorId: String,
    @Parameter(description = "Filter by status") @RequestParam(required = false) status: String?,
    @Parameter(description = "Page number") @RequestParam(defaultValue = "1") page: Int,
    @Parameter(description = "Page size") @RequestParam(defaultValue = "20") limit: Int,
): ResponseEntity<MembersListResponse> {
    // Implementation with status filter support
}
```

### 6.3 Request/Response DTOs

**File:** `src/main/kotlin/com/munserv/auth/api/AuthRequest.kt`

Add new DTOs:

```kotlin
/**
 * Web registration request.
 */
data class WebRegisterRequest(
    @field:NotBlank(message = "Email is required")
    @field:jakarta.validation.constraints.Email(message = "Invalid email format")
    val email: String,

    @field:NotBlank(message = "First name is required")
    @field:Size(max = 50, message = "First name too long")
    val firstName: String,

    @field:NotBlank(message = "Surname is required")
    @field:Size(max = 50, message = "Surname too long")
    val surname: String,

    @field:NotBlank(message = "Phone is required")
    @field:Size(max = 20, message = "Phone number too long")
    val phone: String,

    @field:NotBlank(message = "Address is required")
    @field:Size(max = 500, message = "Address too long")
    val address: String,

    @field:DecimalMin("-90.0") @field:DecimalMax("90.0")
    val latitude: Double,

    @field:DecimalMin("-180.0") @field:DecimalMax("180.0")
    val longitude: Double,

    @field:NotBlank(message = "Sector ID is required")
    val sectorId: String,
)

/**
 * Member login request (email + password).
 */
data class MemberLoginRequest(
    @field:NotBlank(message = "Email is required")
    @field:jakarta.validation.constraints.Email(message = "Invalid email format")
    val email: String,

    @field:NotBlank(message = "Password is required")
    val password: String,
)

/**
 * Change password request.
 */
data class ChangePasswordRequest(
    @field:NotBlank(message = "Current password is required")
    val currentPassword: String,

    @field:NotBlank(message = "New password is required")
    @field:Size(min = 8, message = "Password must be at least 8 characters")
    val newPassword: String,
)
```

**File:** `src/main/kotlin/com/munserv/auth/api/AuthResponse.kt`

Add new response DTOs:

```kotlin
/**
 * Web registration response.
 */
data class WebRegisterResponse(
    val message: String,
    val memberId: String,
)

/**
 * Member login response.
 */
data class MemberLoginResponse(
    val memberId: String,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
    val mustChangePassword: Boolean,
)

/**
 * Member approved response.
 */
data class MemberApprovedResponse(
    val memberId: String,
    val email: String,
    val message: String,
)
```

---

## 7. Database Migration

**New File:** `src/main/resources/db/migration/V011__add_member_email_authentication.sql`

```sql
-- V011__add_member_email_authentication.sql
-- Add email-based authentication fields to members table
-- Support for web registration with admin approval workflow

-- ================================================
-- 1. Add new status value to enum
-- ================================================
ALTER TYPE member_status ADD VALUE IF NOT EXISTS 'pending_approval';

-- ================================================
-- 2. Add email authentication columns
-- ================================================
ALTER TABLE members
    ADD COLUMN IF NOT EXISTS email VARCHAR(255),
    ADD COLUMN IF NOT EXISTS email_hash VARCHAR(64),
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(60),
    ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS phone VARCHAR(20);  -- Plain phone for contact

-- ================================================
-- 3. Make phone_hash and pin_hash nullable
-- (Required for web registrations without PIN setup)
-- ================================================
ALTER TABLE members
    ALTER COLUMN phone_hash DROP NOT NULL,
    ALTER COLUMN pin_hash DROP NOT NULL;

-- ================================================
-- 4. Migrate existing members
-- Existing members get placeholder email based on their ID
-- They will need to update their email through admin action
-- ================================================
UPDATE members
SET
    email = COALESCE(email, 'legacy-' || id::text || '@pending-migration.local'),
    email_hash = COALESCE(email_hash, encode(sha256(('legacy-' || id::text || '@pending-migration.local')::bytea), 'hex')),
    must_change_password = COALESCE(must_change_password, false)
WHERE email IS NULL;

-- ================================================
-- 5. Add NOT NULL constraints after migration
-- ================================================
ALTER TABLE members
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN email_hash SET NOT NULL,
    ALTER COLUMN must_change_password SET NOT NULL;

-- ================================================
-- 6. Add unique constraints and indexes
-- ================================================
-- Unique email
ALTER TABLE members
    ADD CONSTRAINT uq_members_email UNIQUE (email);

-- Unique email hash for lookups
ALTER TABLE members
    ADD CONSTRAINT uq_members_email_hash UNIQUE (email_hash);

-- Index for email hash lookups
CREATE INDEX IF NOT EXISTS idx_members_email_hash ON members(email_hash);

-- Index for status filtering
CREATE INDEX IF NOT EXISTS idx_members_status ON members(status);

-- Composite index for sector + status queries
CREATE INDEX IF NOT EXISTS idx_members_sector_status ON members(sector_id, status);

-- ================================================
-- 7. Add comment for documentation
-- ================================================
COMMENT ON COLUMN members.email IS 'Member email address for login and contact';
COMMENT ON COLUMN members.email_hash IS 'SHA-256 hash of lowercase email for lookups';
COMMENT ON COLUMN members.password_hash IS 'BCrypt hashed password, null until approved';
COMMENT ON COLUMN members.must_change_password IS 'True if member must change password on next login';
COMMENT ON COLUMN members.phone IS 'Plain phone number for contact purposes';
```

---

## 8. Configuration Updates

### 8.1 Application Properties

**File:** `src/main/resources/application.yml`

Add new configuration sections:

```yaml
# Add to existing config
spring:
  mail:
    host: ${SMTP_HOST:localhost}
    port: ${SMTP_PORT:587}
    username: ${SMTP_USERNAME:}
    password: ${SMTP_PASSWORD:}
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true

munserv:
  email:
    from: ${EMAIL_FROM:noreply@munserv.app}
  app:
    name: ${APP_NAME:MunServ}
    download-url: ${APP_DOWNLOAD_URL:https://munserv.app/download}
```

### 8.2 Security Configuration

**File:** `src/main/kotlin/com/munserv/shared/security/SecurityConfig.kt`

Add public endpoint patterns:

```kotlin
.authorizeHttpRequests { auth ->
    auth
        // Existing public endpoints
        .requestMatchers("/api/v1/auth/login").permitAll()
        .requestMatchers("/api/v1/auth/admin/login").permitAll()
        .requestMatchers("/api/v1/auth/refresh").permitAll()
        // NEW: Web registration
        .requestMatchers("/api/v1/auth/register/web").permitAll()
        // NEW: Member login
        .requestMatchers("/api/v1/auth/member/login").permitAll()
        // Require auth for everything else
        .anyRequest().authenticated()
}
```

---

## 9. Testing Requirements

### 9.1 Unit Tests

**File:** `src/test/kotlin/com/munserv/auth/domain/EmailTest.kt`

```kotlin
class EmailTest {
    @Test
    fun `should validate correct email formats`() {
        Email.isValid("test@example.com") shouldBe true
        Email.isValid("user.name+tag@domain.co.uk") shouldBe true
    }

    @Test
    fun `should reject invalid email formats`() {
        Email.isValid("invalid") shouldBe false
        Email.isValid("@nodomain.com") shouldBe false
        Email.isValid("noat.com") shouldBe false
    }

    @Test
    fun `should normalize email to lowercase`() {
        val email = Email.fromString("Test@EXAMPLE.COM")
        email.value shouldBe "test@example.com"
    }

    @Test
    fun `should mask email correctly`() {
        Email.fromString("john.doe@example.com").masked() shouldBe "j*******e@example.com"
        Email.fromString("ab@test.com").masked() shouldBe "**@test.com"
    }

    @Test
    fun `should produce consistent hash`() {
        val email1 = Email.fromString("test@example.com")
        val email2 = Email.fromString("TEST@EXAMPLE.COM")
        email1.hash() shouldBe email2.hash()
    }
}
```

**File:** `src/test/kotlin/com/munserv/auth/domain/PasswordTest.kt`

```kotlin
class PasswordTest {
    @Test
    fun `should validate password requirements`() {
        Password.validate("Abc12345").shouldBeEmpty()
        Password.validate("short").shouldContain("at least 8 characters")
        Password.validate("alllowercase1").shouldContain("uppercase")
        Password.validate("ALLUPPERCASE1").shouldContain("lowercase")
        Password.validate("NoNumbers").shouldContain("number")
    }

    @Test
    fun `should generate valid passwords`() {
        repeat(100) {
            val password = Password.generate()
            Password.isValid(password) shouldBe true
        }
    }

    @Test
    fun `should hash and verify passwords`() {
        val plain = "TestPassword123"
        val hash = Password.hash(plain)

        Password.verify(plain, hash) shouldBe true
        Password.verify("WrongPassword", hash) shouldBe false
    }
}
```

**File:** `src/test/kotlin/com/munserv/auth/service/RegistrationServiceTest.kt`

```kotlin
class RegistrationServiceTest {
    private val memberRepository: MemberRepository = mockk()
    private val sectorService: SectorService = mockk()
    private val emailService: EmailService = mockk(relaxed = true)
    private val clock = Clock.fixed(Instant.now(), ZoneId.UTC)

    private lateinit var service: RegistrationService

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        service = RegistrationService(memberRepository, sectorService, emailService, clock)
    }

    @Test
    fun `registerMember should create pending member`() {
        // Arrange
        val command = createTestCommand()
        every { memberRepository.existsByEmailHash(any()) } returns false
        every { sectorService.findById(any()) } returns createTestSector()
        every { memberRepository.save(any()) } answers { firstArg() }

        // Act
        val result = service.registerMember(command)

        // Assert
        result.shouldBeInstanceOf<RegistrationResult.Success>()
        (result as RegistrationResult.Success).member.status shouldBe MemberStatus.PendingApproval
        verify { memberRepository.save(match { it.status == MemberStatus.PendingApproval }) }
    }

    @Test
    fun `registerMember should reject duplicate email`() {
        val command = createTestCommand()
        every { memberRepository.existsByEmailHash(any()) } returns true

        val result = service.registerMember(command)

        result shouldBe RegistrationResult.EmailAlreadyRegistered
    }

    @Test
    fun `approveMember should activate and send email`() {
        val member = createTestMember(status = MemberStatus.PendingApproval)
        every { memberRepository.findById(any()) } returns member
        every { memberRepository.save(any()) } answers { firstArg() }

        val result = service.approveMember(member.id)

        result.shouldBeInstanceOf<RegistrationResult.Approved>()
        verify { emailService.sendWelcomeEmail(any(), any(), any()) }
        verify { memberRepository.save(match {
            it.status == MemberStatus.Active &&
            it.passwordHash != null
        }) }
    }

    @Test
    fun `rejectMember should delete pending member`() {
        val member = createTestMember(status = MemberStatus.PendingApproval)
        every { memberRepository.findById(any()) } returns member
        every { memberRepository.delete(any()) } just Runs

        val result = service.rejectMember(member.id)

        result.shouldBeInstanceOf<RegistrationResult.Rejected>()
        verify { memberRepository.delete(member.id) }
    }
}
```

### 9.2 Integration Tests

**File:** `src/test/kotlin/com/munserv/auth/api/WebRegistrationIntegrationTest.kt`

```kotlin
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class WebRegistrationIntegrationTest {
    @Autowired private lateinit var mockMvc: MockMvc
    @Autowired private lateinit var memberRepository: MemberRepository

    @Test
    fun `POST register-web should create pending member`() {
        val request = """
            {
                "email": "newmember@example.com",
                "firstName": "John",
                "surname": "Doe",
                "phone": "+27821234567",
                "address": "123 Main St",
                "latitude": -26.2041,
                "longitude": 28.0473,
                "sectorId": "$testSectorId"
            }
        """.trimIndent()

        mockMvc.post("/api/v1/auth/register/web") {
            contentType = MediaType.APPLICATION_JSON
            content = request
        }.andExpect {
            status { isCreated() }
            jsonPath("$.memberId") { exists() }
        }
    }
}
```

---

## 10. Implementation Checklist

Use this checklist with `/dev-cycle` for implementation:

### Domain Layer
- [x] Update `MemberStatus.kt` - add PendingApproval ✓
- [x] Update `Member.kt` - add email/password fields ✓
- [x] Create `Email.kt` - email value object ✓
- [x] Create `Password.kt` - password utilities ✓
- [x] Write unit tests for Email ✓
- [x] Write unit tests for Password ✓
- [x] Write unit tests for MemberStatus transitions ✓
- [x] Write unit tests for Member entity (canLogin, withPassword, clearMustChangePassword) ✓

### Repository Layer
- [x] Update `MemberEntity.kt` - add JPA columns ✓
- [x] Update `MemberRepository.kt` - add new methods ✓
- [x] Update `JpaMemberRepository.kt` - implement new methods ✓
- [x] Create migration `V011__add_member_email_authentication.sql` ✓
- [x] Write integration tests for MemberRepository ✓

### Service Layer
- [x] Create `RegistrationService.kt` ✓
- [x] Create `RegistrationResult.kt` ✓
- [x] Update `AuthService.kt` - add loginWithEmail, changePassword ✓
- [x] Update `AuthResult.kt` - add new result types ✓
- [x] Create `EmailService.kt` ✓
- [x] Write unit tests for RegistrationService ✓
- [x] Write unit tests for AuthService (new methods) ✓
- [x] Write unit tests for EmailService ✓

### API Layer
- [x] Add request DTOs (WebRegisterRequest, MemberLoginRequest, ChangePasswordRequest) ✓
- [x] Add response DTOs (WebRegisterResponse, MemberLoginResponse, MemberApprovedResponse) ✓
- [x] Update `AuthController.kt` - add new endpoints ✓
- [x] Update `AdminController.kt` - add approve/reject endpoints ✓
- [x] Update `SecurityConfig.kt` - add public endpoints ✓
- [x] Write API contract tests ✓

### Configuration
- [x] Update `application.yml` - add SMTP config ✓
- [x] Update `build.gradle.kts` - add spring-boot-starter-mail dependency ✓
- [x] Create test SMTP configuration ✓

### Integration Testing
- [x] Write integration tests for registration flow ✓
- [x] Write integration tests for approval flow ✓
- [x] Write integration test for EmailService autowiring ✓

---

## 11. API Contract Summary

### Public Endpoints (No Auth)

```
POST /api/v1/auth/register/web
Request: { email, firstName, surname, phone, address, latitude, longitude, sectorId }
Response: 201 { message, memberId }
Errors: 400 (validation), 409 (email exists)

POST /api/v1/auth/member/login
Request: { email, password }
Response: 200 { memberId, accessToken, refreshToken, expiresIn, mustChangePassword }
Errors: 401 (invalid), 403 (pending/suspended)
```

### Protected Endpoints (JWT Required)

```
POST /api/v1/auth/change-password
Request: { currentPassword, newPassword }
Response: 200 { message }
Errors: 400 (validation), 401 (wrong password)

POST /api/v1/admin/members/{id}/approve
Response: 200 { memberId, email, message }
Errors: 400 (wrong status), 404 (not found)

DELETE /api/v1/admin/members/{id}
Response: 204
Errors: 400 (wrong status), 404 (not found)
```

---

## 12. Environment Variables

```bash
# SMTP Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Email Settings
EMAIL_FROM=noreply@munserv.app
APP_NAME=MunServ
APP_DOWNLOAD_URL=https://play.google.com/store/apps/details?id=com.munserv
```

---

*✅ Backend Phase Complete - All implementation checklist items verified and tested. Ready for Web Phase (2 of 3).*
