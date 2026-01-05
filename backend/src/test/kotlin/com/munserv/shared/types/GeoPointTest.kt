package com.munserv.shared.types

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test

class GeoPointTest {
    @Test
    fun `should create GeoPoint with valid coordinates`() {
        val point = GeoPoint(latitude = -26.1350, longitude = 27.9800)

        point.latitude shouldBe -26.1350
        point.longitude shouldBe 27.9800
    }

    @Test
    fun `should create GeoPoint at equator and prime meridian`() {
        val point = GeoPoint(latitude = 0.0, longitude = 0.0)

        point.latitude shouldBe 0.0
        point.longitude shouldBe 0.0
    }

    @Test
    fun `should create GeoPoint at extreme valid latitudes`() {
        val north = GeoPoint(latitude = 90.0, longitude = 0.0)
        val south = GeoPoint(latitude = -90.0, longitude = 0.0)

        north.latitude shouldBe 90.0
        south.latitude shouldBe -90.0
    }

    @Test
    fun `should create GeoPoint at extreme valid longitudes`() {
        val east = GeoPoint(latitude = 0.0, longitude = 180.0)
        val west = GeoPoint(latitude = 0.0, longitude = -180.0)

        east.longitude shouldBe 180.0
        west.longitude shouldBe -180.0
    }

    @Test
    fun `should reject latitude above 90`() {
        shouldThrow<IllegalArgumentException> {
            GeoPoint(latitude = 90.1, longitude = 0.0)
        }.message shouldBe "Latitude must be between -90 and 90"
    }

    @Test
    fun `should reject latitude below -90`() {
        shouldThrow<IllegalArgumentException> {
            GeoPoint(latitude = -90.1, longitude = 0.0)
        }.message shouldBe "Latitude must be between -90 and 90"
    }

    @Test
    fun `should reject longitude above 180`() {
        shouldThrow<IllegalArgumentException> {
            GeoPoint(latitude = 0.0, longitude = 180.1)
        }.message shouldBe "Longitude must be between -180 and 180"
    }

    @Test
    fun `should reject longitude below -180`() {
        shouldThrow<IllegalArgumentException> {
            GeoPoint(latitude = 0.0, longitude = -180.1)
        }.message shouldBe "Longitude must be between -180 and 180"
    }

    @Test
    fun `should have correct equality`() {
        val point1 = GeoPoint(latitude = -26.1350, longitude = 27.9800)
        val point2 = GeoPoint(latitude = -26.1350, longitude = 27.9800)
        val point3 = GeoPoint(latitude = -26.1351, longitude = 27.9800)

        (point1 == point2) shouldBe true
        (point1 == point3) shouldBe false
    }

    @Test
    fun `should have correct hashCode`() {
        val point1 = GeoPoint(latitude = -26.1350, longitude = 27.9800)
        val point2 = GeoPoint(latitude = -26.1350, longitude = 27.9800)

        point1.hashCode() shouldBe point2.hashCode()
    }

    @Test
    fun `should have meaningful toString`() {
        val point = GeoPoint(latitude = -26.1350, longitude = 27.9800)

        point.toString() shouldBe "GeoPoint(latitude=-26.135, longitude=27.98)"
    }
}
