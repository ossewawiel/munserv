package com.munserv.groundadmin.repository

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository for Ground Admin application entities.
 */
@Repository
interface JpaGroundAdminApplicationRepository : JpaRepository<GroundAdminApplicationEntity, UUID> {
    @Query(
        """
        SELECT a FROM GroundAdminApplicationEntity a
        WHERE a.memberId = :memberId
        AND a.sectorId = :sectorId
        AND a.status = 'pending'
        """,
    )
    fun findPendingForMemberInSector(
        memberId: UUID,
        sectorId: UUID,
    ): GroundAdminApplicationEntity?

    fun findBySectorIdAndStatus(
        sectorId: UUID,
        status: String,
    ): List<GroundAdminApplicationEntity>

    fun findByMemberIdAndStatus(
        memberId: UUID,
        status: String,
    ): List<GroundAdminApplicationEntity>
}
