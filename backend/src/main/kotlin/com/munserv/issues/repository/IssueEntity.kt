package com.munserv.issues.repository

import com.munserv.issues.domain.Issue
import com.munserv.issues.domain.IssueId
import com.munserv.issues.domain.IssueState
import com.munserv.issues.domain.IssueType
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.ColumnTransformer
import org.locationtech.jts.geom.Coordinate
import org.locationtech.jts.geom.GeometryFactory
import org.locationtech.jts.geom.Point
import org.locationtech.jts.geom.PrecisionModel
import java.time.Instant
import java.util.UUID

/**
 * JPA Entity for issues table.
 * Converts between database representation and domain model.
 */
@Entity
@Table(name = "issues")
class IssueEntity(
    @Id
    val id: UUID,
    @Column(name = "sector_id", nullable = false)
    val sectorId: UUID,
    @Column(name = "reporter_id", nullable = false)
    val reporterId: UUID,
    @Column(nullable = false, columnDefinition = "issue_type")
    @ColumnTransformer(write = "?::issue_type")
    val type: String,
    @Column(nullable = false, columnDefinition = "issue_state")
    @ColumnTransformer(write = "?::issue_state")
    val state: String,
    @Column(columnDefinition = "geography(Point,4326)", nullable = false)
    val location: Point,
    @Column
    val address: String? = null,
    @Column
    val description: String? = null,
    @Column(nullable = false)
    val heat: Int,
    @Column(name = "report_count", nullable = false)
    val reportCount: Int,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
    @Column(name = "deleted_at")
    val deletedAt: Instant? = null,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): Issue =
        Issue(
            id = IssueId(id),
            sectorId = SectorId(sectorId),
            reporterId = MemberId(reporterId),
            type = IssueType.fromString(type),
            state = IssueState.fromString(state),
            location =
                GeoPoint(
                    latitude = location.y,
                    longitude = location.x,
                ),
            address = address,
            description = description,
            heat = heat,
            reportCount = reportCount,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    companion object {
        private val geometryFactory = GeometryFactory(PrecisionModel(), 4326)

        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(issue: Issue): IssueEntity {
            val locationPoint =
                geometryFactory.createPoint(
                    Coordinate(issue.location.longitude, issue.location.latitude),
                )

            return IssueEntity(
                id = issue.id.value,
                sectorId = issue.sectorId.value,
                reporterId = issue.reporterId.value,
                type = issue.type.toApiString(),
                state = issue.state.toApiString(),
                location = locationPoint,
                address = issue.address,
                description = issue.description,
                heat = issue.heat,
                reportCount = issue.reportCount,
                createdAt = issue.createdAt,
                updatedAt = issue.updatedAt,
            )
        }
    }
}
