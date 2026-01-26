package com.munserv.admin.repository

import com.munserv.admin.domain.Admin
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId

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
     * Find all admins in a ward.
     */
    fun findByWardId(wardId: WardId): List<Admin>

    /**
     * Find all admins in a pod.
     */
    fun findByPodId(podId: PodId): List<Admin>

    /**
     * Find admin by email.
     */
    fun findByEmail(email: String): Admin?

    /**
     * Save a new admin with password hash.
     * Returns the saved admin.
     *
     * @param admin The admin domain object
     * @param passwordHash The hashed password for authentication
     * @param temporaryPassword The temporary password (for onboarding flow)
     */
    fun save(
        admin: Admin,
        passwordHash: String,
        temporaryPassword: String? = null,
    ): Admin

    /**
     * Update an existing admin without changing the password.
     * Returns the updated admin.
     */
    fun update(admin: Admin): Admin

    /**
     * Update an existing admin with a new password.
     * Returns the updated admin.
     */
    fun updateWithPassword(
        admin: Admin,
        passwordHash: String,
    ): Admin

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

    /**
     * Find the Pod Chief for a given pod.
     * Returns null if no Pod Chief exists.
     */
    fun findPodChief(podId: PodId): Admin?

    /**
     * Check if a Pod Chief exists and has completed onboarding.
     * Returns true if Pod Chief exists with onboardingStatus == ACTIVE.
     */
    fun existsPodChiefOnboarded(podId: PodId): Boolean
}

/**
 * Admin with password hash for authentication purposes.
 */
data class AdminWithPasswordHash(
    val admin: Admin,
    val passwordHash: String,
)
