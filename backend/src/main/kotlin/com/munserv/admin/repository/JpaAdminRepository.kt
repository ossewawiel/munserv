package com.munserv.admin.repository

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.OnboardingStatus
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository for Admin entities.
 */
interface SpringDataAdminRepository : JpaRepository<AdminEntity, UUID> {
    fun findBySectorIdAndDeletedAtIsNull(sectorId: UUID): List<AdminEntity>

    fun findByWardIdAndDeletedAtIsNull(wardId: UUID): List<AdminEntity>

    fun findByPodIdAndDeletedAtIsNull(podId: UUID): List<AdminEntity>

    fun findByEmailAndDeletedAtIsNull(email: String): AdminEntity?

    fun findByIdAndDeletedAtIsNull(id: UUID): AdminEntity?

    fun existsByEmailAndDeletedAtIsNull(email: String): Boolean

    fun countBySectorIdAndDeletedAtIsNull(sectorId: UUID): Int

    @Query(
        """
        SELECT * FROM admins a
        WHERE a.pod_id = :podId
        AND a.role = CAST(:role AS admin_role)
        AND a.deleted_at IS NULL
        """,
        nativeQuery = true,
    )
    fun findByPodIdAndRoleAndDeletedAtIsNull(
        podId: UUID,
        role: String,
    ): AdminEntity?

    @Query(
        """
        SELECT CASE WHEN COUNT(*) > 0 THEN true ELSE false END
        FROM admins a
        WHERE a.pod_id = :podId
        AND a.role = CAST(:role AS admin_role)
        AND a.onboarding_status = CAST(:onboardingStatus AS onboarding_status)
        AND a.deleted_at IS NULL
        """,
        nativeQuery = true,
    )
    fun existsByPodIdAndRoleAndOnboardingStatusAndDeletedAtIsNull(
        podId: UUID,
        role: String,
        onboardingStatus: String,
    ): Boolean
}

/**
 * Implementation of AdminRepository using Spring Data JPA.
 */
@Repository
class JpaAdminRepository(
    private val jpa: SpringDataAdminRepository,
    private val passwordEncoder: PasswordEncoder,
) : AdminRepository {
    override fun findById(id: AdminId): Admin? = jpa.findByIdAndDeletedAtIsNull(id.value)?.toDomain()

    override fun findBySectorId(sectorId: SectorId): List<Admin> =
        jpa.findBySectorIdAndDeletedAtIsNull(sectorId.value).map { it.toDomain() }

    override fun findByWardId(wardId: WardId): List<Admin> = jpa.findByWardIdAndDeletedAtIsNull(wardId.value).map { it.toDomain() }

    override fun findByPodId(podId: PodId): List<Admin> = jpa.findByPodIdAndDeletedAtIsNull(podId.value).map { it.toDomain() }

    override fun findByEmail(email: String): Admin? = jpa.findByEmailAndDeletedAtIsNull(email)?.toDomain()

    override fun save(
        admin: Admin,
        passwordHash: String,
        temporaryPassword: String?,
    ): Admin {
        val temporaryPasswordHash = temporaryPassword?.let { passwordEncoder.encode(it) }
        return jpa.save(AdminEntity.fromDomain(admin, passwordHash, temporaryPasswordHash)).toDomain()
    }

    override fun update(admin: Admin): Admin {
        val existing =
            jpa.findById(admin.id.value).orElseThrow {
                IllegalArgumentException("Admin not found: ${admin.id.value}")
            }
        val updated = AdminEntity.fromDomain(admin, existing.passwordHash, existing.temporaryPasswordHash)
        return jpa.save(updated).toDomain()
    }

    override fun updateWithPassword(
        admin: Admin,
        passwordHash: String,
    ): Admin {
        // Clear temporary password hash when password is changed
        val updated = AdminEntity.fromDomain(admin, passwordHash, null)
        return jpa.save(updated).toDomain()
    }

    override fun existsByEmail(email: String): Boolean = jpa.existsByEmailAndDeletedAtIsNull(email)

    override fun countBySectorId(sectorId: SectorId): Int = jpa.countBySectorIdAndDeletedAtIsNull(sectorId.value)

    override fun findByEmailWithPasswordHash(email: String): AdminWithPasswordHash? {
        val entity = jpa.findByEmailAndDeletedAtIsNull(email) ?: return null
        return AdminWithPasswordHash(
            admin = entity.toDomain(),
            passwordHash = entity.passwordHash,
        )
    }

    override fun findPodChief(podId: PodId): Admin? =
        jpa
            .findByPodIdAndRoleAndDeletedAtIsNull(
                podId.value,
                AdminRole.POD_CHIEF.toDbValue(),
            )?.toDomain()

    override fun existsPodChiefOnboarded(podId: PodId): Boolean =
        jpa.existsByPodIdAndRoleAndOnboardingStatusAndDeletedAtIsNull(
            podId.value,
            AdminRole.POD_CHIEF.toDbValue(),
            OnboardingStatus.ACTIVE.toDbValue(),
        )
}
