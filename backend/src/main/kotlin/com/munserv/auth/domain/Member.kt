package com.munserv.auth.domain

import com.munserv.shared.enums.GroundAdminStatus
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import java.math.BigDecimal
import java.time.Instant

/**
 * Domain entity representing a community member.
 * Pure Kotlin data class with business logic, no framework dependencies.
 *
 * Supports two authentication flows:
 * 1. Legacy phone+PIN (mobile app registration with OTP)
 * 2. Email+password (web registration with admin approval)
 */
data class Member(
    val id: MemberId,
    val sectorId: SectorId,
    // Email authentication fields (web registration)
    val email: String,
    val emailHash: String,
    val passwordHash: String?,
    val mustChangePassword: Boolean = true,
    // Phone authentication fields (legacy mobile registration, now nullable)
    val phoneHash: String?,
    val pinHash: String?,
    // Contact information
    val phone: String,
    val firstName: String,
    val surname: String,
    val address: String,
    val registrationLocation: GeoPoint,
    // Status
    val status: MemberStatus = MemberStatus.Active,
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now(),
    // Ground Admin fields
    val isGroundAdmin: Boolean = false,
    val groundAdminStatus: GroundAdminStatus? = null,
    val groundAdminSince: Instant? = null,
    val groundAdminResponseRate: BigDecimal? = null,
) {
    val fullName: String
        get() = "$firstName $surname"

    val isActive: Boolean
        get() = status == MemberStatus.Active

    val canLogin: Boolean
        get() = status == MemberStatus.Active && passwordHash != null

    fun canTransitionTo(newStatus: MemberStatus): Boolean = status.canTransitionTo(newStatus)

    fun withStatus(newStatus: MemberStatus): Member = copy(status = newStatus, updatedAt = Instant.now())

    fun withPassword(
        hash: String,
        mustChange: Boolean = true,
    ): Member = copy(passwordHash = hash, mustChangePassword = mustChange, updatedAt = Instant.now())

    fun withPinHash(newPinHash: String): Member = copy(pinHash = newPinHash, updatedAt = Instant.now())

    fun clearMustChangePassword(): Member = copy(mustChangePassword = false, updatedAt = Instant.now())

    // ==================== Ground Admin Methods ====================

    /**
     * Promotes this member to Ground Admin status.
     * Sets initial values for all GA fields.
     */
    fun promoteToGroundAdmin(): Member =
        copy(
            isGroundAdmin = true,
            groundAdminStatus = GroundAdminStatus.ACTIVE,
            groundAdminSince = Instant.now(),
            groundAdminResponseRate = BigDecimal("100.00"),
            updatedAt = Instant.now(),
        )

    /**
     * Removes Ground Admin status from this member.
     * Sets status to INACTIVE but preserves historical data.
     */
    fun demoteFromGroundAdmin(): Member =
        copy(
            isGroundAdmin = false,
            groundAdminStatus = GroundAdminStatus.INACTIVE,
            updatedAt = Instant.now(),
        )

    /**
     * Sets Ground Admin status to ON_HOLD.
     * Used when GA is temporarily unavailable.
     */
    fun setGroundAdminOnHold(): Member =
        copy(
            groundAdminStatus = GroundAdminStatus.ON_HOLD,
            updatedAt = Instant.now(),
        )

    /**
     * Reactivates a Ground Admin from ON_HOLD status.
     */
    fun reactivateGroundAdmin(): Member =
        copy(
            groundAdminStatus = GroundAdminStatus.ACTIVE,
            updatedAt = Instant.now(),
        )

    /**
     * Updates the Ground Admin response rate.
     */
    fun updateResponseRate(rate: BigDecimal): Member =
        copy(
            groundAdminResponseRate = rate,
            updatedAt = Instant.now(),
        )
}
