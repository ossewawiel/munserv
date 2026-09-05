package com.munserv.sectors.repository

import com.munserv.TestContainersConfig
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles

@SpringBootTest
@Import(TestContainersConfig::class)
@ActiveProfiles("test")
class SectorRepositoryTest {
    @Autowired
    private lateinit var sectorRepository: SectorRepository

    // Default pod ID from V003 migration
    private val defaultPodId = PodId.fromString("550e8400-e29b-41d4-a716-446655440000")

    // Sector IDs from V004 migration
    private val northcliffSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val fairlandsSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440002")

    @Test
    fun `should find all sectors`() {
        val sectors = sectorRepository.findAll()

        sectors shouldHaveSize 2
    }

    @Test
    fun `should find sector by id`() {
        val sector = sectorRepository.findById(northcliffSectorId)

        sector shouldNotBe null
        sector?.name shouldBe "Ward 42 - Northcliff"
        sector?.podId shouldBe defaultPodId
    }

    @Test
    fun `should return null for non-existent sector`() {
        val nonExistentId = SectorId.generate()

        val sector = sectorRepository.findById(nonExistentId)

        sector shouldBe null
    }

    @Test
    fun `should find sectors by pod id`() {
        val sectors = sectorRepository.findByPodId(defaultPodId)

        sectors shouldHaveSize 2
        sectors.any { it.name == "Ward 42 - Northcliff" } shouldBe true
        sectors.any { it.name == "Ward 43 - Fairlands" } shouldBe true
    }

    @Test
    fun `should return empty list for non-existent pod`() {
        val nonExistentPodId = PodId.generate()

        val sectors = sectorRepository.findByPodId(nonExistentPodId)

        sectors shouldHaveSize 0
    }

    @Test
    fun `should check if sector exists`() {
        sectorRepository.existsById(northcliffSectorId) shouldBe true
        sectorRepository.existsById(SectorId.generate()) shouldBe false
    }

    @Test
    fun `should have correct center coordinates`() {
        val sector = sectorRepository.findById(northcliffSectorId)

        sector shouldNotBe null
        sector?.center?.latitude shouldBe -26.1367
        sector?.center?.longitude shouldBe 27.9833
    }
}
