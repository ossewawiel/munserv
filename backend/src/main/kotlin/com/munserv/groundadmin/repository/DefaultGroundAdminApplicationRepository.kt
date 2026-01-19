package com.munserv.groundadmin.repository

import com.munserv.groundadmin.domain.GroundAdminApplication
import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository

/**
 * Default implementation of GroundAdminApplicationRepository using JPA.
 */
@Repository
class DefaultGroundAdminApplicationRepository(
    private val jpa: JpaGroundAdminApplicationRepository,
) : GroundAdminApplicationRepository {
    override fun findById(id: GroundAdminApplicationId): GroundAdminApplication? = jpa.findByIdOrNull(id.value)?.toDomain()

    override fun findPendingForMemberInSector(
        memberId: MemberId,
        sectorId: SectorId,
    ): GroundAdminApplication? = jpa.findPendingForMemberInSector(memberId.value, sectorId.value)?.toDomain()

    override fun findBySectorIdAndStatus(
        sectorId: SectorId,
        status: String,
    ): List<GroundAdminApplication> = jpa.findBySectorIdAndStatus(sectorId.value, status).map { it.toDomain() }

    override fun findByMemberIdAndStatus(
        memberId: MemberId,
        status: String,
    ): List<GroundAdminApplication> = jpa.findByMemberIdAndStatus(memberId.value, status).map { it.toDomain() }

    override fun save(application: GroundAdminApplication): GroundAdminApplication =
        jpa.save(GroundAdminApplicationEntity.fromDomain(application)).toDomain()

    override fun delete(id: GroundAdminApplicationId) {
        jpa.deleteById(id.value)
    }
}
