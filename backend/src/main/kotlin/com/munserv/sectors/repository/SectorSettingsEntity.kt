package com.munserv.sectors.repository

import com.munserv.sectors.domain.SectorSettings
import com.munserv.shared.enums.VerificationMode
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.SectorSettingsId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

/**
 * JPA Entity for sector_settings table.
 * Converts between database representation and domain model.
 */
@Entity
@Table(name = "sector_settings")
class SectorSettingsEntity(
    @Id
    val id: UUID,
    @Column(name = "sector_id", nullable = false, unique = true)
    val sectorId: UUID,
    @Enumerated(EnumType.STRING)
    @Column(name = "new_issue_verification_mode", nullable = false)
    val newIssueVerificationMode: VerificationMode,
    @Enumerated(EnumType.STRING)
    @Column(name = "fix_verification_mode", nullable = false)
    val fixVerificationMode: VerificationMode,
    @Column(name = "days_fixed_before_closed", nullable = false)
    val daysFixedBeforeClosed: Int,
    @Column(name = "minimum_ground_admins", nullable = false)
    val minimumGroundAdmins: Int,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,
    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
) {
    /**
     * Convert JPA entity to domain model.
     */
    fun toDomain(): SectorSettings =
        SectorSettings(
            id = SectorSettingsId(id),
            sectorId = SectorId(sectorId),
            newIssueVerificationMode = newIssueVerificationMode,
            fixVerificationMode = fixVerificationMode,
            daysFixedBeforeClosed = daysFixedBeforeClosed,
            minimumGroundAdmins = minimumGroundAdmins,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    companion object {
        /**
         * Convert domain model to JPA entity.
         */
        fun fromDomain(settings: SectorSettings): SectorSettingsEntity =
            SectorSettingsEntity(
                id = settings.id.value,
                sectorId = settings.sectorId.value,
                newIssueVerificationMode = settings.newIssueVerificationMode,
                fixVerificationMode = settings.fixVerificationMode,
                daysFixedBeforeClosed = settings.daysFixedBeforeClosed,
                minimumGroundAdmins = settings.minimumGroundAdmins,
                createdAt = settings.createdAt,
                updatedAt = settings.updatedAt,
            )
    }
}
