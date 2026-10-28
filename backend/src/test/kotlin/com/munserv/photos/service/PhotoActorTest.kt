package com.munserv.photos.service

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import java.time.Instant

class PhotoActorTest {
    private val reporterId = MemberId.generate()
    private val issue =
        Issue(
            id = IssueId.generate(),
            sectorId = SectorId.generate(),
            reporterId = reporterId,
            type = IssueType.POTHOLE,
            state = IssueState.Reported,
            location = GeoPoint(-26.0, 28.0),
            address = null,
            description = null,
            heat = 10,
            reportCount = 1,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
        )

    @Test
    fun `should allow the reporter`() {
        PhotoActor.Member(reporterId).isReporterOrAdminOf(issue) shouldBe true
    }

    @Test
    fun `should allow an admin`() {
        PhotoActor.Admin.isReporterOrAdminOf(issue) shouldBe true
    }

    @Test
    fun `should refuse another member`() {
        PhotoActor.Member(MemberId.generate()).isReporterOrAdminOf(issue) shouldBe false
    }
}
