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

    /**
     * Save a new admin with password hash.
     * Returns the saved admin.
     */
    fun save(
        admin: Admin,
        passwordHash: String,
    ): Admin

    /**
     * Update an existing admin without changing the password.
     * Returns the updated admin.
     */
    fun update(admin: Admin): Admin

    /**
     * Check if an email is already registered.
     */
    fun existsByEmail(email: String): Boolean

    /**
     * Count admins in a sector (excluding deleted).
     */
    fun countBySectorId(sectorId: SectorId): Int

    /**
     * Find admin by email and return with password hash for authentication.
     * Returns null if admin not found or deleted.
     */
    fun findByEmailWithPasswordHash(email: String): AdminWithPasswordHash?
}

/**
 * Admin with password hash for authentication purposes.
 */
data class AdminWithPasswordHash(
    val admin: Admin,
    val passwordHash: String,
)
