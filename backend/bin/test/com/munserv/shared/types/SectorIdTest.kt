package com.munserv.shared.types

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import java.util.UUID

class SectorIdTest {
    @Test
    fun `should create SectorId with valid UUID`() {
        val uuid = UUID.randomUUID()
        val sectorId = SectorId(uuid)

        sectorId.value shouldBe uuid
    }

    @Test
    fun `should create SectorId from string`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440001"
        val sectorId = SectorId.fromString(uuidString)

        sectorId.value.toString() shouldBe uuidString
    }

    @Test
    fun `should throw exception for invalid UUID string`() {
        shouldThrow<IllegalArgumentException> {
            SectorId.fromString("not-a-uuid")
        }
    }

    @Test
    fun `should have correct equality`() {
        val uuid = UUID.randomUUID()
        val sectorId1 = SectorId(uuid)
        val sectorId2 = SectorId(uuid)
        val sectorId3 = SectorId(UUID.randomUUID())

        sectorId1 shouldBe sectorId2
        sectorId1 shouldNotBe sectorId3
    }

    @Test
    fun `should have correct hashCode`() {
        val uuid = UUID.randomUUID()
        val sectorId1 = SectorId(uuid)
        val sectorId2 = SectorId(uuid)

        sectorId1.hashCode() shouldBe sectorId2.hashCode()
    }

    @Test
    fun `should have meaningful toString`() {
        val uuidString = "550e8400-e29b-41d4-a716-446655440001"
        val sectorId = SectorId.fromString(uuidString)

        sectorId.toString() shouldBe uuidString
    }

    @Test
    fun `should generate new SectorId`() {
        val sectorId = SectorId.generate()

        sectorId.value shouldNotBe null
    }
}
