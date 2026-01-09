package com.munserv.auth.repository

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA interface for member persistence.
 */
interface MemberJpaRepository : JpaRepository<MemberEntity, UUID> {
    fun findByPhoneHash(phoneHash: String): MemberEntity?

    fun findByEmailHash(emailHash: String): MemberEntity?

    fun findBySectorId(sectorId: UUID): List<MemberEntity>

    @Query(
        value = "SELECT * FROM members m WHERE m.sector_id = :sectorId AND m.status = CAST(:status AS member_status)",
        nativeQuery = true,
    )
    fun findBySectorIdAndStatus(
        sectorId: UUID,
        status: String,
    ): List<MemberEntity>

    fun existsByPhoneHash(phoneHash: String): Boolean

    fun existsByEmailHash(emailHash: String): Boolean
}

/**
 * Implementation of domain MemberRepository using JPA.
 */
@Repository
class JpaMemberRepository(
    private val jpa: MemberJpaRepository,
) : MemberRepository {
    override fun findById(id: MemberId): Member? = jpa.findByIdOrNull(id.value)?.toDomain()

    override fun findByPhoneHash(phoneHash: String): Member? = jpa.findByPhoneHash(phoneHash)?.toDomain()

    override fun findByEmailHash(emailHash: String): Member? = jpa.findByEmailHash(emailHash)?.toDomain()

    override fun findBySectorId(sectorId: SectorId): List<Member> = jpa.findBySectorId(sectorId.value).map { it.toDomain() }

    override fun findBySectorIdAndStatus(
        sectorId: SectorId,
        status: MemberStatus,
    ): List<Member> = jpa.findBySectorIdAndStatus(sectorId.value, status.toString()).map { it.toDomain() }

    override fun save(member: Member): Member = jpa.save(MemberEntity.fromDomain(member)).toDomain()

    override fun delete(id: MemberId) {
        jpa.deleteById(id.value)
    }

    override fun existsByPhoneHash(phoneHash: String): Boolean = jpa.existsByPhoneHash(phoneHash)

    override fun existsByEmailHash(emailHash: String): Boolean = jpa.existsByEmailHash(emailHash)
}
