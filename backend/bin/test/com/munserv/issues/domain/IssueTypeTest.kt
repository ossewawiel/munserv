package com.munserv.issues.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test

class IssueTypeTest {
    @Test
    fun `should create IssueType from valid string - pothole`() {
        val type = IssueType.fromString("pothole")
        type shouldBe IssueType.POTHOLE
    }

    @Test
    fun `should create IssueType from valid string - water_leak`() {
        val type = IssueType.fromString("water_leak")
        type shouldBe IssueType.WATER_LEAK
    }

    @Test
    fun `should create IssueType from valid string - sewage_leak`() {
        val type = IssueType.fromString("sewage_leak")
        type shouldBe IssueType.SEWAGE_LEAK
    }

    @Test
    fun `should create IssueType from valid string - traffic_light`() {
        val type = IssueType.fromString("traffic_light")
        type shouldBe IssueType.TRAFFIC_LIGHT
    }

    @Test
    fun `should create IssueType from valid string - street_light`() {
        val type = IssueType.fromString("street_light")
        type shouldBe IssueType.STREET_LIGHT
    }

    @Test
    fun `should create IssueType from valid string - illegal_dumping`() {
        val type = IssueType.fromString("illegal_dumping")
        type shouldBe IssueType.ILLEGAL_DUMPING
    }

    @Test
    fun `should create IssueType from valid string - other`() {
        val type = IssueType.fromString("other")
        type shouldBe IssueType.OTHER
    }

    @Test
    fun `should be case insensitive`() {
        IssueType.fromString("POTHOLE") shouldBe IssueType.POTHOLE
        IssueType.fromString("Pothole") shouldBe IssueType.POTHOLE
        IssueType.fromString("WATER_LEAK") shouldBe IssueType.WATER_LEAK
    }

    @Test
    fun `should throw for unknown type`() {
        shouldThrow<IllegalArgumentException> {
            IssueType.fromString("unknown")
        }
    }

    @Test
    fun `toString should return snake_case value`() {
        IssueType.POTHOLE.toApiString() shouldBe "pothole"
        IssueType.WATER_LEAK.toApiString() shouldBe "water_leak"
        IssueType.SEWAGE_LEAK.toApiString() shouldBe "sewage_leak"
        IssueType.TRAFFIC_LIGHT.toApiString() shouldBe "traffic_light"
        IssueType.STREET_LIGHT.toApiString() shouldBe "street_light"
        IssueType.ILLEGAL_DUMPING.toApiString() shouldBe "illegal_dumping"
        IssueType.OTHER.toApiString() shouldBe "other"
    }

    @Test
    fun `displayName should be human readable`() {
        IssueType.POTHOLE.displayName shouldBe "Pothole"
        IssueType.WATER_LEAK.displayName shouldBe "Water Leak"
        IssueType.SEWAGE_LEAK.displayName shouldBe "Sewage Leak"
        IssueType.TRAFFIC_LIGHT.displayName shouldBe "Traffic Light"
        IssueType.STREET_LIGHT.displayName shouldBe "Street Light"
        IssueType.ILLEGAL_DUMPING.displayName shouldBe "Illegal Dumping"
        IssueType.OTHER.displayName shouldBe "Other"
    }
}
