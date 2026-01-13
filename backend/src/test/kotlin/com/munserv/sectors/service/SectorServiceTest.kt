package com.munserv.sectors.service

import com.munserv.sectors.domain.Sector
import com.munserv.sectors.repository.SectorRepository
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

class SectorServiceTest {
    private lateinit var sectorService: SectorService
    private lateinit var sectorRepository: SectorRepository

    private val testSectorId = SectorId.generate()
    private val testSector = createTestSector(testSectorId)

    @BeforeEach
    fun setup() {
        clearAllMocks()
        sectorRepository = mockk()
        sectorService = SectorService(sectorRepository)
    }

    @Test
    fun `findAll should return all sectors`() {
        // Arrange
        val sector1 = createTestSector(SectorId.generate(), "Sector 1")
        val sector2 = createTestSector(SectorId.generate(), "Sector 2")
        val sectors = listOf(sector1, sector2)
        every { sectorRepository.findAll() } returns sectors

        // Act
        val result = sectorService.findAll()

        // Assert
        result shouldHaveSize 2
        result shouldContainExactly sectors
        verify { sectorRepository.findAll() }
    }

    @Test
    fun `findAll should return empty list when no sectors exist`() {
        // Arrange
        every { sectorRepository.findAll() } returns emptyList()

        // Act
        val result = sectorService.findAll()

        // Assert
        result shouldHaveSize 0
        verify { sectorRepository.findAll() }
    }

    @Test
    fun `findById should return sector when found`() {
        // Arrange
        every { sectorRepository.findById(testSectorId) } returns testSector

        // Act
        val result = sectorService.findById(testSectorId)

        // Assert
        result shouldNotBe null
        result?.id shouldBe testSectorId
        result?.name shouldBe testSector.name
        verify { sectorRepository.findById(testSectorId) }
    }

    @Test
    fun `findById should return null when sector not found`() {
        // Arrange
        val unknownId = SectorId.generate()
        every { sectorRepository.findById(unknownId) } returns null

        // Act
        val result = sectorService.findById(unknownId)

        // Assert
        result shouldBe null
        verify { sectorRepository.findById(unknownId) }
    }

    private fun createTestSector(
        id: SectorId,
        name: String = "Test Sector",
    ): Sector =
        Sector(
            id = id,
            podId = PodId.generate(),
            name = name,
            center = GeoPoint(latitude = -26.2041, longitude = 28.0473),
            boundary = null,
        )
}
