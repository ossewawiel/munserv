package com.munserv.support.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.admin.repository.AdminRepository
import com.munserv.audit.domain.AuditActorType
import com.munserv.audit.service.AuditService
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import com.munserv.support.repository.SupportGrantRepository
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

class SupportAccessServiceTest {
    private val supportGrantRepository: SupportGrantRepository = mockk()
    private val adminRepository: AdminRepository = mockk()
    private val auditService: AuditService = mockk(relaxed = true)
    private val fixedInstant = Instant.parse("2026-09-05T10:00:00Z")
    private val clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)
    private lateinit var service: SupportAccessService

    private val testPodId = PodId(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
    private val podChiefId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
    private val podAdminId = AdminId(UUID.fromString("550e8400-e29b-41d4-a716-446655440032"))

    private fun podChief(): Admin =
        Admin(
            id = podChiefId,
            podId = testPodId,
            email = "chief@example.com",
            displayName = "Thandi Mokoena",
            role = AdminRole.POD_CHIEF,
            onboardingStatus = OnboardingStatus.ACTIVE,
            createdAt = fixedInstant,
            updatedAt = fixedInstant,
        )

    private fun podAdmin(): Admin =
        Admin(
            id = podAdminId,
            podId = testPodId,
            email = "admin@example.com",
            displayName = "Support Admin",
            role = AdminRole.POD_ADMIN,
            onboardingStatus = OnboardingStatus.ACTIVE,
            createdAt = fixedInstant,
            updatedAt = fixedInstant,
        )

    private fun testGrant(status: SupportGrantStatus = SupportGrantStatus.ACTIVE): SupportGrant =
        SupportGrant
            .create(
                id = SupportGrantId.generate(),
                podId = testPodId,
                grantedRole = AdminRole.POD_ADMIN,
                purpose = "Investigate duplicate issue reports",
                grantedBy = podChiefId,
                grantedAt = fixedInstant.minus(Duration.ofMinutes(10)),
            ).let {
                when (status) {
                    SupportGrantStatus.ACTIVE -> it
                    SupportGrantStatus.REVOKED -> it.revoked(fixedInstant, podChiefId)
                    SupportGrantStatus.EXPIRED -> it.expired(fixedInstant)
                }
            }

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        service = SupportAccessService(supportGrantRepository, adminRepository, auditService, clock)
    }

    @Nested
    inner class Grant {
        @Test
        fun `should grant support access when actor is pod chief`() {
            every { adminRepository.findById(podChiefId) } returns podChief()
            every { supportGrantRepository.findActiveByPodId(testPodId) } returns null
            val slot = slot<SupportGrant>()
            every { supportGrantRepository.save(capture(slot)) } answers { slot.captured }

            val result = service.grant(podChiefId, AdminRole.POD_ADMIN, "Investigate duplicate issue reports")

            result.shouldBeInstanceOf<SupportAccessResult.Granted>()
            (result as SupportAccessResult.Granted).view.grant.status shouldBe SupportGrantStatus.ACTIVE
            result.view.grantedByName shouldBe "Thandi Mokoena"
            verify { auditService.logSupportAccessGranted(any(), any(), any(), any(), any()) }
        }

        @Test
        fun `should return NotAuthorized when actor is not pod chief`() {
            every { adminRepository.findById(podAdminId) } returns podAdmin()

            val result = service.grant(podAdminId, AdminRole.WARD_ADMIN, "Investigate duplicate issue reports")

            result.shouldBeInstanceOf<SupportAccessResult.NotAuthorized>()
        }

        @Test
        fun `should return NotAuthorized when actor does not exist`() {
            every { adminRepository.findById(podChiefId) } returns null

            val result = service.grant(podChiefId, AdminRole.POD_ADMIN, "Investigate duplicate issue reports")

            result.shouldBeInstanceOf<SupportAccessResult.NotAuthorized>()
        }

        @Test
        fun `should return ValidationError when purpose is too short`() {
            every { adminRepository.findById(podChiefId) } returns podChief()

            val result = service.grant(podChiefId, AdminRole.POD_ADMIN, "short")

            result.shouldBeInstanceOf<SupportAccessResult.ValidationError>()
        }

        @Test
        fun `should return ValidationError when granted role is not below pod chief`() {
            every { adminRepository.findById(podChiefId) } returns podChief()

            val result = service.grant(podChiefId, AdminRole.POD_CHIEF, "Investigate duplicate issue reports")

            result.shouldBeInstanceOf<SupportAccessResult.ValidationError>()
        }

        @Test
        fun `should return ActiveGrantExists when the pod already has an active grant`() {
            every { adminRepository.findById(podChiefId) } returns podChief()
            every { supportGrantRepository.findActiveByPodId(testPodId) } returns testGrant()

            val result = service.grant(podChiefId, AdminRole.POD_ADMIN, "Investigate duplicate issue reports")

            result.shouldBeInstanceOf<SupportAccessResult.ActiveGrantExists>()
        }
    }

    @Nested
    inner class ListGrants {
        @Test
        fun `should return grants for the actor's pod`() {
            val grant = testGrant()
            every { adminRepository.findById(podChiefId) } returns podChief()
            every { supportGrantRepository.findByPodId(testPodId) } returns listOf(grant)

            val result = service.list(podChiefId, null)

            result.shouldBeInstanceOf<SupportAccessResult.Grants>()
            (result as SupportAccessResult.Grants).views shouldBe listOf(SupportGrantView(grant, "Thandi Mokoena"))
        }

        @Test
        fun `should filter grants by status when provided`() {
            val grant = testGrant(SupportGrantStatus.REVOKED)
            every { adminRepository.findById(podChiefId) } returns podChief()
            every { supportGrantRepository.findByPodIdAndStatus(testPodId, SupportGrantStatus.REVOKED) } returns listOf(grant)

            val result = service.list(podChiefId, SupportGrantStatus.REVOKED)

            result.shouldBeInstanceOf<SupportAccessResult.Grants>()
            verify { supportGrantRepository.findByPodIdAndStatus(testPodId, SupportGrantStatus.REVOKED) }
        }

        @Test
        fun `should return NotAuthorized when actor is not pod chief`() {
            every { adminRepository.findById(podAdminId) } returns podAdmin()

            val result = service.list(podAdminId, null)

            result.shouldBeInstanceOf<SupportAccessResult.NotAuthorized>()
        }
    }

    @Nested
    inner class Revoke {
        @Test
        fun `should revoke an active grant`() {
            val grant = testGrant()
            every { adminRepository.findById(podChiefId) } returns podChief()
            every { supportGrantRepository.findById(grant.id) } returns grant
            val slot = slot<SupportGrant>()
            every { supportGrantRepository.save(capture(slot)) } answers { slot.captured }

            val result = service.revoke(podChiefId, grant.id)

            result.shouldBeInstanceOf<SupportAccessResult.Revoked>()
            slot.captured.status shouldBe SupportGrantStatus.REVOKED
            slot.captured.revokedBy shouldBe podChiefId
            verify {
                auditService.logSupportAccessRevoked(
                    "chief@example.com",
                    AuditActorType.POD_CHIEF,
                    grant.id.value,
                    "revoked_by_pod_chief",
                    testPodId,
                )
            }
        }

        @Test
        fun `should return NotFound when grant does not exist`() {
            every { adminRepository.findById(podChiefId) } returns podChief()
            every { supportGrantRepository.findById(any()) } returns null

            val result = service.revoke(podChiefId, SupportGrantId.generate())

            result.shouldBeInstanceOf<SupportAccessResult.NotFound>()
        }

        @Test
        fun `should return NotAuthorized when the grant belongs to a different pod`() {
            val otherPodChief = podChief().copy(podId = PodId.generate())
            val grant = testGrant()
            every { adminRepository.findById(podChiefId) } returns otherPodChief
            every { supportGrantRepository.findById(grant.id) } returns grant

            val result = service.revoke(podChiefId, grant.id)

            result.shouldBeInstanceOf<SupportAccessResult.NotAuthorized>()
        }

        @Test
        fun `should return GrantNotActive when the grant status is terminal`() {
            val grant = testGrant(SupportGrantStatus.EXPIRED)
            every { adminRepository.findById(podChiefId) } returns podChief()
            every { supportGrantRepository.findById(grant.id) } returns grant

            val result = service.revoke(podChiefId, grant.id)

            result.shouldBeInstanceOf<SupportAccessResult.GrantNotActive>()
        }
    }

    @Nested
    inner class RevokeOnLogout {
        @Test
        fun `should revoke a grant with no actor on logout`() {
            val grant = testGrant()
            every { supportGrantRepository.findById(grant.id) } returns grant
            val slot = slot<SupportGrant>()
            every { supportGrantRepository.save(capture(slot)) } answers { slot.captured }

            val result = service.revokeOnLogout(grant.id)

            result.shouldBeInstanceOf<SupportAccessResult.Revoked>()
            slot.captured.revokedBy shouldBe null
            verify {
                auditService.logSupportAccessRevoked(
                    "system",
                    AuditActorType.SYSTEM,
                    grant.id.value,
                    "logout",
                    testPodId,
                )
            }
        }

        @Test
        fun `should return NotFound when grant does not exist`() {
            every { supportGrantRepository.findById(any()) } returns null

            val result = service.revokeOnLogout(SupportGrantId.generate())

            result.shouldBeInstanceOf<SupportAccessResult.NotFound>()
        }

        @Test
        fun `should return GrantNotActive when the grant status is terminal`() {
            val grant = testGrant(SupportGrantStatus.REVOKED)
            every { supportGrantRepository.findById(grant.id) } returns grant

            val result = service.revokeOnLogout(grant.id)

            result.shouldBeInstanceOf<SupportAccessResult.GrantNotActive>()
        }
    }

    @Nested
    inner class RecordActivity {
        @Test
        fun `should record activity for an active grant`() {
            val grant = testGrant().copy(lastActivity = null)
            every { supportGrantRepository.findById(grant.id) } returns grant
            val slot = slot<SupportGrant>()
            every { supportGrantRepository.save(capture(slot)) } answers { slot.captured }

            val result = service.recordActivity(grant.id, fixedInstant)

            result shouldBe true
            slot.captured.lastActivity shouldBe fixedInstant
        }

        @Test
        fun `should return false when the grant does not exist`() {
            every { supportGrantRepository.findById(any()) } returns null

            val result = service.recordActivity(SupportGrantId.generate(), fixedInstant)

            result shouldBe false
        }

        @Test
        fun `should return false when the grant is not active`() {
            val grant = testGrant(SupportGrantStatus.EXPIRED)
            every { supportGrantRepository.findById(grant.id) } returns grant

            val result = service.recordActivity(grant.id, fixedInstant)

            result shouldBe false
        }

        @Test
        fun `should skip the write when activity is recorded twice inside the throttle window`() {
            val grant = testGrant().copy(lastActivity = fixedInstant.minus(Duration.ofSeconds(30)))
            every { supportGrantRepository.findById(grant.id) } returns grant

            val result = service.recordActivity(grant.id, fixedInstant)

            result shouldBe false
            verify(exactly = 0) { supportGrantRepository.save(any()) }
        }

        @Test
        fun `should record activity again once the throttle window has elapsed`() {
            val grant = testGrant().copy(lastActivity = fixedInstant.minus(Duration.ofSeconds(90)))
            every { supportGrantRepository.findById(grant.id) } returns grant
            val slot = slot<SupportGrant>()
            every { supportGrantRepository.save(capture(slot)) } answers { slot.captured }

            val result = service.recordActivity(grant.id, fixedInstant)

            result shouldBe true
            slot.captured.lastActivity shouldBe fixedInstant
        }
    }

    @Nested
    inner class ExpireStaleGrants {
        @Test
        fun `should expire all stale grants and log each one`() {
            val first = testGrant()
            val second = testGrant()
            every { supportGrantRepository.findExpiredActive(fixedInstant) } returns listOf(first, second)
            every { supportGrantRepository.save(any()) } answers { firstArg() }

            val count = service.expireStaleGrants()

            count shouldBe 2
            verify(exactly = 2) { auditService.logSupportAccessExpired(any(), any()) }
        }

        @Test
        fun `should return zero when there are no stale grants`() {
            every { supportGrantRepository.findExpiredActive(fixedInstant) } returns emptyList()

            val count = service.expireStaleGrants()

            count shouldBe 0
            verify(exactly = 0) { auditService.logSupportAccessExpired(any(), any()) }
        }
    }
}
