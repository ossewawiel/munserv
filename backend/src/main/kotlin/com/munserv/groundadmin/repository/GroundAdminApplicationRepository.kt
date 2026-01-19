package com.munserv.groundadmin.repository

import com.munserv.groundadmin.domain.GroundAdminApplication
import com.munserv.groundadmin.domain.GroundAdminApplicationId
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId

/**
 * Domain repository interface for Ground Admin applications.
 * Implementations handle data access details.
 */
interface GroundAdminApplicationRepository {
    fun findById(id: GroundAdminApplicationId): GroundAdminApplication?

    fun findPendingForMemberInSector(
        memberId: MemberId,
        sectorId: SectorId,
    ): GroundAdminApplication?

    fun findBySectorIdAndStatus(
        sectorId: SectorId,
        status: String,
    ): List<GroundAdminApplication>

    fun findByMemberIdAndStatus(
        memberId: MemberId,
        status: String,
    ): List<GroundAdminApplication>

    fun save(application: GroundAdminApplication): GroundAdminApplication

    fun delete(id: GroundAdminApplicationId)
}
