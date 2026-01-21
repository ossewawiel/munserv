package com.munserv.admin.repository

import com.munserv.admin.domain.Admin
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

/**
 * Spring Data JPA repository for Admin entities.
 */
interface SpringDataAdminRepository : JpaRepository<AdminEntity, UUID> {
    fun findBySectorIdAndDeletedAtIsNull(sectorId: UUID): List<AdminEntity>

    fun findByEmailAndDeletedAtIsNull(email: String): AdminEntity?

    fun findByIdAndDeletedAtIsNull(id: UUID): AdminEntity?
}

/**
 * Implementation of AdminRepository using Spring Data JPA.
 */
@Repository
class JpaAdminRepository(
    private val jpa: SpringDataAdminRepository,
) : AdminRepository {
    override fun findById(id: AdminId): Admin? = jpa.findByIdAndDeletedAtIsNull(id.value)?.toDomain()

    override fun findBySectorId(sectorId: SectorId): List<Admin> =
        jpa.findBySectorIdAndDeletedAtIsNull(sectorId.value).map { it.toDomain() }

    override fun findByEmail(email: String): Admin? = jpa.findByEmailAndDeletedAtIsNull(email)?.toDomain()
}
