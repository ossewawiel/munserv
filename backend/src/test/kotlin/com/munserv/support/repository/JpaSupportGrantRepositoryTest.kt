package com.munserv.support.repository

import com.munserv.TestContainersConfig
import com.munserv.admin.domain.AdminRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import java.time.Duration
import java.time.Instant

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig::class, JpaSupportGrantRepositoryImpl::class)
class JpaSupportGrantRepositoryTest {
    @Autowired
    private lateinit var repository: SupportGrantRepository

    // Default pod ID from V003 migration
    private val defaultPodId = PodId.fromString("550e8400-e29b-41d4-a716-446655440000")

    // Pod Chief test account from V030 migration
    private val podChiefId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440031")

    private val grantedAt = Instant.parse("2026-09-05T10:00:00Z")

    private fun newGrant(): SupportGrant =
        SupportGrant.create(
            id = SupportGrantId.generate(),
            podId = defaultPodId,
            grantedRole = AdminRole.POD_ADMIN,
            purpose = "Investigate duplicate issue reports in sector 3",
            grantedBy = podChiefId,
            grantedAt = grantedAt,
        )

    @Nested
    inner class Save {
        @Test
        fun `should save and find a support grant by id`() {
            val grant = newGrant()

            val saved = repository.save(grant)
            val found = repository.findById(saved.id)

            found shouldNotBe null
            found?.id shouldBe grant.id
            found?.podId shouldBe defaultPodId
            found?.grantedRole shouldBe AdminRole.POD_ADMIN
            found?.status shouldBe SupportGrantStatus.ACTIVE
        }

        @Test
        fun `should return null for a non-existent id`() {
            repository.findById(SupportGrantId.generate()) shouldBe null
        }
    }

    @Nested
    inner class FindByPodId {
        @Test
        fun `should find grants for a pod newest first`() {
            val older = repository.save(newGrant().revoked(grantedAt.plus(Duration.ofMinutes(1)), podChiefId))
            val newer =
                repository.save(
                    newGrant().copy(id = SupportGrantId.generate(), grantedAt = grantedAt.plus(Duration.ofMinutes(5))),
                )

            val grants = repository.findByPodId(defaultPodId)

            grants.map { it.id } shouldBe listOf(newer.id, older.id)
        }

        @Test
        fun `should return empty list for a pod with no grants`() {
            repository.findByPodId(PodId.generate()).shouldBeEmpty()
        }
    }

    @Nested
    inner class FindByPodIdAndStatus {
        @Test
        fun `should filter grants by status`() {
            val active = repository.save(newGrant())
            val revoked =
                repository.save(
                    newGrant().copy(id = SupportGrantId.generate()).revoked(grantedAt.plus(Duration.ofMinutes(1)), podChiefId),
                )

            val activeGrants = repository.findByPodIdAndStatus(defaultPodId, SupportGrantStatus.ACTIVE)
            val revokedGrants = repository.findByPodIdAndStatus(defaultPodId, SupportGrantStatus.REVOKED)

            activeGrants.map { it.id } shouldBe listOf(active.id)
            revokedGrants.map { it.id } shouldBe listOf(revoked.id)
        }
    }

    @Nested
    inner class FindActiveByPodId {
        @Test
        fun `should return the active grant for a pod`() {
            val grant = repository.save(newGrant())

            val active = repository.findActiveByPodId(defaultPodId)

            active?.id shouldBe grant.id
        }

        @Test
        fun `should return null when there is no active grant`() {
            repository.findActiveByPodId(PodId.generate()) shouldBe null
        }
    }

    @Nested
    inner class FindExpiredActive {
        @Test
        fun `should return only expired active grants when findExpiredActive is called`() {
            val now = grantedAt.plus(Duration.ofHours(2))
            val expiredActive = repository.save(newGrant())
            val revoked =
                repository.save(
                    newGrant().copy(id = SupportGrantId.generate()).revoked(grantedAt.plus(Duration.ofMinutes(1)), podChiefId),
                )

            val result = repository.findExpiredActive(now)

            result.map { it.id } shouldHaveSize 1
            result.first().id shouldBe expiredActive.id
            result.map { it.id } shouldNotBe listOf(revoked.id)
        }
    }
}
