package com.munserv.audit.service

import com.munserv.audit.domain.AuditAction
import com.munserv.audit.domain.AuditActorType
import com.munserv.audit.domain.AuditLog
import com.munserv.audit.repository.AuditLogRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import io.kotest.matchers.shouldBe
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

class AuditServiceTest {
    private val repository: AuditLogRepository = mockk()
    private val fixedInstant = Instant.parse("2026-01-15T10:00:00Z")
    private val clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)
    private lateinit var service: AuditService

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        service = AuditService(repository, clock)
    }

    @Nested
    inner class LogSuperUserLoginAttempt {
        @Test
        fun `should log super user login success`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSuperUserLoginAttempt(
                email = "super@example.com",
                success = true,
                podId = testPodId,
            )

            // Assert
            verify { repository.save(any()) }
            slot.captured.action shouldBe AuditAction.SUPER_USER_LOGIN_SUCCESS
            slot.captured.actorEmail shouldBe "super@example.com"
            slot.captured.actorType shouldBe AuditActorType.SUPER_USER
            slot.captured.podId shouldBe testPodId
            slot.captured.createdAt shouldBe fixedInstant
        }

        @Test
        fun `should log super user login failure`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSuperUserLoginAttempt(
                email = "super@example.com",
                success = false,
                podId = testPodId,
            )

            // Assert
            slot.captured.action shouldBe AuditAction.SUPER_USER_LOGIN_FAILURE
            slot.captured.actorEmail shouldBe "super@example.com"
        }

        @Test
        fun `should include IP address when provided`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSuperUserLoginAttempt(
                email = "super@example.com",
                success = true,
                podId = testPodId,
                ipAddress = "192.168.1.1",
            )

            // Assert
            slot.captured.ipAddress shouldBe "192.168.1.1"
        }

        @Test
        fun `should include user agent when provided`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSuperUserLoginAttempt(
                email = "super@example.com",
                success = true,
                podId = testPodId,
                userAgent = "Mozilla/5.0",
            )

            // Assert
            slot.captured.userAgent shouldBe "Mozilla/5.0"
        }

        @Test
        fun `should have null target fields for login`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSuperUserLoginAttempt(
                email = "super@example.com",
                success = true,
                podId = testPodId,
            )

            // Assert
            slot.captured.targetType shouldBe null
            slot.captured.targetId shouldBe null
            slot.captured.details shouldBe null
        }
    }

    @Nested
    inner class LogPodChiefCreated {
        private val testAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))

        @Test
        fun `should log Pod Chief creation with details`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logPodChiefCreated(
                superUserEmail = "super@example.com",
                adminId = testAdminId,
                adminEmail = "chief@example.com",
                podId = testPodId,
            )

            // Assert
            slot.captured.action shouldBe AuditAction.POD_CHIEF_CREATED
            slot.captured.actorEmail shouldBe "super@example.com"
            slot.captured.actorType shouldBe AuditActorType.SUPER_USER
            slot.captured.targetType shouldBe "ADMIN"
            slot.captured.targetId shouldBe testAdminId.value
        }

        @Test
        fun `should include admin email and role in details`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logPodChiefCreated(
                superUserEmail = "super@example.com",
                adminId = testAdminId,
                adminEmail = "chief@example.com",
                podId = testPodId,
            )

            // Assert
            slot.captured.details?.get("adminEmail") shouldBe "chief@example.com"
            slot.captured.details?.get("role") shouldBe "POD_CHIEF"
        }

        @Test
        fun `should include IP and user agent when provided`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logPodChiefCreated(
                superUserEmail = "super@example.com",
                adminId = testAdminId,
                adminEmail = "chief@example.com",
                podId = testPodId,
                ipAddress = "10.0.0.1",
                userAgent = "Admin/1.0",
            )

            // Assert
            slot.captured.ipAddress shouldBe "10.0.0.1"
            slot.captured.userAgent shouldBe "Admin/1.0"
        }
    }

    @Nested
    inner class LogSupportAccessGranted {
        private val testGrantId = UUID.fromString("550e8400-e29b-41d4-a716-446655440002")

        @Test
        fun `should log support access grant`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSupportAccessGranted(
                podChiefEmail = "chief@example.com",
                grantId = testGrantId,
                grantedRole = "SECTOR_ADMIN",
                purpose = "Investigate issue #123",
                podId = testPodId,
            )

            // Assert
            slot.captured.action shouldBe AuditAction.SUPPORT_ACCESS_GRANTED
            slot.captured.actorEmail shouldBe "chief@example.com"
            slot.captured.actorType shouldBe AuditActorType.POD_CHIEF
            slot.captured.targetType shouldBe "SUPPORT_GRANT"
            slot.captured.targetId shouldBe testGrantId
        }

        @Test
        fun `should include granted role and purpose in details`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSupportAccessGranted(
                podChiefEmail = "chief@example.com",
                grantId = testGrantId,
                grantedRole = "SECTOR_ADMIN",
                purpose = "Investigate issue #123",
                podId = testPodId,
            )

            // Assert
            slot.captured.details?.get("grantedRole") shouldBe "SECTOR_ADMIN"
            slot.captured.details?.get("purpose") shouldBe "Investigate issue #123"
        }
    }

    @Nested
    inner class LogSupportAccessRevoked {
        private val testGrantId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003")

        @Test
        fun `should log support access revocation by Pod Chief`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSupportAccessRevoked(
                revokerEmail = "chief@example.com",
                actorType = AuditActorType.POD_CHIEF,
                grantId = testGrantId,
                reason = "Access no longer needed",
                podId = testPodId,
            )

            // Assert
            slot.captured.action shouldBe AuditAction.SUPPORT_ACCESS_REVOKED
            slot.captured.actorEmail shouldBe "chief@example.com"
            slot.captured.actorType shouldBe AuditActorType.POD_CHIEF
            slot.captured.details?.get("reason") shouldBe "Access no longer needed"
        }

        @Test
        fun `should log support access revocation by System`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSupportAccessRevoked(
                revokerEmail = "system",
                actorType = AuditActorType.SYSTEM,
                grantId = testGrantId,
                reason = null,
                podId = testPodId,
            )

            // Assert
            slot.captured.actorType shouldBe AuditActorType.SYSTEM
            slot.captured.details shouldBe null
        }
    }

    @Nested
    inner class LogSupportAccessExpired {
        private val testGrantId = UUID.fromString("550e8400-e29b-41d4-a716-446655440005")

        @Test
        fun `should log support access expired with SYSTEM actor`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSupportAccessExpired(
                grantId = testGrantId,
                podId = testPodId,
            )

            // Assert
            slot.captured.action shouldBe AuditAction.SUPPORT_ACCESS_EXPIRED
            slot.captured.actorEmail shouldBe "system"
            slot.captured.actorType shouldBe AuditActorType.SYSTEM
            slot.captured.targetType shouldBe "SUPPORT_GRANT"
            slot.captured.targetId shouldBe testGrantId
        }
    }

    @Nested
    inner class LogSupportAccessLogin {
        private val testGrantId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004")

        @Test
        fun `should log support access login`() {
            // Arrange
            val slot = slot<AuditLog>()
            every { repository.save(capture(slot)) } answers { slot.captured }

            // Act
            service.logSupportAccessLogin(
                superUserEmail = "support@example.com",
                grantId = testGrantId,
                podId = testPodId,
                ipAddress = "172.16.0.1",
                userAgent = "Support/2.0",
            )

            // Assert
            slot.captured.action shouldBe AuditAction.SUPPORT_ACCESS_LOGIN
            slot.captured.actorEmail shouldBe "support@example.com"
            slot.captured.actorType shouldBe AuditActorType.SUPER_USER
            slot.captured.targetType shouldBe "SUPPORT_GRANT"
            slot.captured.targetId shouldBe testGrantId
            slot.captured.ipAddress shouldBe "172.16.0.1"
            slot.captured.userAgent shouldBe "Support/2.0"
        }
    }
}
