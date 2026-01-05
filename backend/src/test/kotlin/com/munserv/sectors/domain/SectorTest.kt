package com.munserv.sectors.domain

import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import java.time.Instant

class SectorTest {
    private val podId = PodId.generate()
    private val sectorId = SectorId.generate()
    private val center = GeoPoint(latitude = -26.1367, longitude = 27.9833)

    @Test
    fun `should create Sector with required fields`() {
        val sector =
            Sector(
                id = sectorId,
                podId = podId,
                name = "Ward 42 - Northcliff",
                center = center,
            )

        sector.id shouldBe sectorId
        sector.podId shouldBe podId
        sector.name shouldBe "Ward 42 - Northcliff"
        sector.center shouldBe center
        sector.boundary shouldBe null
    }

    @Test
    fun `should create Sector with optional boundary`() {
        val boundary =
            listOf(
                GeoPoint(-26.1300, 27.9700),
                GeoPoint(-26.1300, 28.0000),
                GeoPoint(-26.1500, 28.0000),
                GeoPoint(-26.1500, 27.9700),
                GeoPoint(-26.1300, 27.9700),
            )

        val sector =
            Sector(
                id = sectorId,
                podId = podId,
                name = "Ward 42 - Northcliff",
                center = center,
                boundary = boundary,
            )

        sector.boundary shouldNotBe null
        sector.boundary?.size shouldBe 5
    }

    @Test
    fun `should have correct equality based on all fields`() {
        val timestamp = Instant.parse("2026-01-05T12:00:00Z")
        val sector1 =
            Sector(
                id = sectorId,
                podId = podId,
                name = "Ward 42",
                center = center,
                createdAt = timestamp,
                updatedAt = timestamp,
            )
        val sector2 =
            Sector(
                id = sectorId,
                podId = podId,
                name = "Ward 42",
                center = center,
                createdAt = timestamp,
                updatedAt = timestamp,
            )
        val sector3 =
            Sector(
                id = SectorId.generate(),
                podId = podId,
                name = "Ward 42",
                center = center,
                createdAt = timestamp,
                updatedAt = timestamp,
            )

        sector1 shouldBe sector2
        sector1 shouldNotBe sector3
    }

    @Test
    fun `should create immutable copy with updated name`() {
        val sector =
            Sector(
                id = sectorId,
                podId = podId,
                name = "Old Name",
                center = center,
            )

        val updated = sector.copy(name = "New Name")

        sector.name shouldBe "Old Name"
        updated.name shouldBe "New Name"
        updated.id shouldBe sector.id
    }

    @Test
    fun `should preserve timestamps`() {
        val now = Instant.now()
        val sector =
            Sector(
                id = sectorId,
                podId = podId,
                name = "Ward 42",
                center = center,
                createdAt = now,
                updatedAt = now,
            )

        sector.createdAt shouldBe now
        sector.updatedAt shouldBe now
    }
}
