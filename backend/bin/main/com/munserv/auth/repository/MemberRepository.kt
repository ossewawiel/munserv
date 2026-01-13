package com.munserv.auth.repository

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
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
}
