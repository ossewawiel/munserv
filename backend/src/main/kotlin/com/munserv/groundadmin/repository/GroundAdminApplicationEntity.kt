package com.munserv.groundadmin.repository

import com.munserv.groundadmin.domain.ApplicationStatus
import com.munserv.groundadmin.domain.ApplicationType
import com.munserv.groundadmin.domain.GroundAdminApplication
import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for ground_admin_applications table.
 */
@Entity
@Table(name = "ground_admin_applications")
class GroundAdminApplicationEntity(
    @Id
    val id: UUID,
    @Column(name = "member_id", nullable = false)
    val memberId: UUID,
    @Column(name = "sector_id", nullable = false)
    val sectorId: UUID,
    @Column(nullable = false, length = 20)
    val type: String,
    @Column(name = "invited_by")
    val invitedBy: UUID? = null,
    @Column(nullable = false, length = 20)
    val status: String = "pending",
    @Column(name = "processed_by")
    val processedBy: UUID? = null,
    @Column(name = "processed_at")
    val processedAt: Instant? = null,
    @Column(name = "decline_reason", columnDefinition = "TEXT")
    val declineReason: String? = null,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant = Instant.now(),
) {
    fun toDomain(): GroundAdminApplication =
        GroundAdminApplication(
            id = GroundAdminApplicationId(id),
            memberId = MemberId(memberId),
            sectorId = SectorId(sectorId),
            type = ApplicationType.fromString(type),
            invitedBy = invitedBy?.let { MemberId(it) },
            status = ApplicationStatus.fromString(status),
            processedBy = processedBy?.let { MemberId(it) },
            processedAt = processedAt,
            declineReason = declineReason,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    companion object {
        fun fromDomain(application: GroundAdminApplication): GroundAdminApplicationEntity =
            GroundAdminApplicationEntity(
                id = application.id.value,
                memberId = application.memberId.value,
                sectorId = application.sectorId.value,
                type = application.type.toDbValue(),
                invitedBy = application.invitedBy?.value,
                status = application.status.toDbValue(),
                processedBy = application.processedBy?.value,
                processedAt = application.processedAt,
                declineReason = application.declineReason,
                createdAt = application.createdAt,
                updatedAt = application.updatedAt,
            )
    }
}
