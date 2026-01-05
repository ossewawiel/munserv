package com.munserv.sectors.repository

import com.munserv.sectors.domain.Sector
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.locationtech.jts.geom.Coordinate
import org.locationtech.jts.geom.GeometryFactory
import org.locationtech.jts.geom.Point
import org.locationtech.jts.geom.Polygon
import org.locationtech.jts.geom.PrecisionModel
import java.time.Instant
import java.util.UUID

/**
 * JPA Entity for sectors table.
 * Converts between database representation and domain model.
 */
@Entity
@Table(name = "sectors")
class SectorEntity(
    @Id
    val id: UUID,
    @Column(name = "pod_id", nullable = false)
    val podId: UUID,
    @Column(nullable = false, length = 100)
    val name: String,
    @Column(columnDefinition = "geography(Point,4326)", nullable = false)
    val center: Point,
    @Column(columnDefinition = "geography(Polygon,4326)")
    val boundary: Polygon? = null,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): Sector =
        Sector(
            id = SectorId(id),
            podId = PodId(podId),
            name = name,
            center =
                GeoPoint(
                    latitude = center.y,
                    longitude = center.x,
                ),
            boundary =
                boundary?.let { polygon ->
                    polygon.coordinates.map { coord ->
                        GeoPoint(latitude = coord.y, longitude = coord.x)
                    }
                },
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    companion object {
        private val geometryFactory = GeometryFactory(PrecisionModel(), 4326)

        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(sector: Sector): SectorEntity {
            val centerPoint =
                geometryFactory.createPoint(
                    Coordinate(sector.center.longitude, sector.center.latitude),
                )

            val boundaryPolygon =
                sector.boundary?.let { points ->
                    val coordinates =
                        points.map { point ->
                            Coordinate(point.longitude, point.latitude)
                        }.toTypedArray()
                    geometryFactory.createPolygon(coordinates)
                }

            return SectorEntity(
                id = sector.id.value,
                podId = sector.podId.value,
                name = sector.name,
                center = centerPoint,
                boundary = boundaryPolygon,
                createdAt = sector.createdAt,
                updatedAt = sector.updatedAt,
            )
        }
    }
}
