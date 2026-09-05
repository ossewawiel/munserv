package com.munserv.auth.repository

import com.munserv.auth.domain.Member
import com.munserv.auth.domain.MemberStatus
import com.munserv.shared.enums.GroundAdminStatus
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

    // Ground Admin queries
    fun findBySectorIdAndIsGroundAdmin(
        sectorId: UUID,
        isGroundAdmin: Boolean,
    ): List<MemberEntity>

    @Query(
        value = """
            SELECT * FROM members m
            WHERE m.sector_id = :sectorId
            AND m.is_ground_admin = :isGroundAdmin
            AND m.ground_admin_status = CAST(:status AS ground_admin_status)
        """,
        nativeQuery = true,
    )
    fun findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
        sectorId: UUID,
        isGroundAdmin: Boolean,
        status: String,
    ): List<MemberEntity>

    @Query(
        value = """
            SELECT * FROM members m
            WHERE m.sector_id = :sectorId
            AND m.status = 'active'
            AND (m.password_hash IS NOT NULL)
        """,
        nativeQuery = true,
    )
    fun findAdminsBySectorId(sectorId: UUID): List<MemberEntity>
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

    // Ground Admin methods
    override fun findBySectorIdAndIsGroundAdmin(
        sectorId: SectorId,
        isGroundAdmin: Boolean,
    ): List<Member> = jpa.findBySectorIdAndIsGroundAdmin(sectorId.value, isGroundAdmin).map { it.toDomain() }

    override fun findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
        sectorId: SectorId,
        isGroundAdmin: Boolean,
        status: GroundAdminStatus,
    ): List<Member> =
        jpa
            .findBySectorIdAndIsGroundAdminAndGroundAdminStatus(
                sectorId.value,
                isGroundAdmin,
                status.toApiString(),
            ).map { it.toDomain() }

    override fun findAdminsBySectorId(sectorId: SectorId): List<Member> = jpa.findAdminsBySectorId(sectorId.value).map { it.toDomain() }
}
