package com.munserv.admin.repository

import com.munserv.admin.domain.Admin
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId

/**
 * Domain repository interface for Admin entities.
 * Implementations handle data access details.
 */
interface AdminRepository {
    /**
     * Find admin by ID.
     */
    fun findById(id: AdminId): Admin?

    /**
     * Find all admins in a sector.
     */
    fun findBySectorId(sectorId: SectorId): List<Admin>

    /**
     * Find admin by email.
     */
    fun findByEmail(email: String): Admin?
}
