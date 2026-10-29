package com.munserv.sectors.repository

import com.munserv.TestContainersConfig
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.SectorId
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.EnumSource
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.boot.jpa.test.autoconfigure.TestEntityManager
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import java.time.Instant

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig::class, JpaSectorSettingsRepository::class)
class SectorSettingsRepositoryTest {
    @Autowired
    private lateinit var repository: SectorSettingsRepository

    @Autowired
    private lateinit var entityManager: TestEntityManager

    private val sectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001")

    @Test
    fun `should read seeded settings when modes are stored as snake_case labels`() {
        val settings = repository.findBySectorId(sectorId).shouldNotBeNull()

        settings.newIssueVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
        settings.fixVerificationMode shouldBe VerificationMode.ALL_NOTIFIED
    }

    @ParameterizedTest
    @EnumSource(VerificationMode::class)
    fun `should persist every verification mode when saved`(mode: VerificationMode) {
        val now = Instant.now()
        val seeded = repository.findBySectorId(sectorId).shouldNotBeNull()
        repository.save(seeded.withNewIssueVerificationMode(mode, now).withFixVerificationMode(mode, now))
        entityManager.flush()
        entityManager.clear()

        val loaded = repository.findBySectorId(sectorId).shouldNotBeNull()

        loaded.newIssueVerificationMode shouldBe mode
        loaded.fixVerificationMode shouldBe mode
    }
}
