package com.munserv.auth.repository

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId

/**
 * Domain repository interface for Member aggregate.
 * Implementations handle data access details.
 */
interface MemberRepository {
    fun findById(id: MemberId): Member?

    fun findByPhoneHash(phoneHash: String): Member?

    fun findByEmailHash(emailHash: String): Member?

    fun findBySectorId(sectorId: SectorId): List<Member>

    fun findBySectorIdAndStatus(
        sectorId: SectorId,
        status: MemberStatus,
    ): List<Member>

    fun save(member: Member): Member

    fun delete(id: MemberId)

    fun existsByPhoneHash(phoneHash: String): Boolean

    fun existsByEmailHash(emailHash: String): Boolean

    // ==================== Ground Admin Methods ====================

    /**
     * Finds all Ground Admins in a sector.
     */
    fun findBySectorIdAndIsGroundAdmin(
        sectorId: SectorId,
        isGroundAdmin: Boolean,
    ): List<Member>

    /**
     * Finds Ground Admins in a sector with specific status.
     */
    fun findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
        sectorId: SectorId,
        isGroundAdmin: Boolean,
        status: GroundAdminStatus,
    ): List<Member>

    /**
     * Finds sector admins (for notifications).
     */
    fun findAdminsBySectorId(sectorId: SectorId): List<Member>
}
