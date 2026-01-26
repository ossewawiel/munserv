package com.munserv.admin.domain

import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import java.time.Instant

/**
 * Domain entity representing an Admin user.
 * Admins manage at different organizational levels: sector, ward, or pod.
 *
 * Scope rules:
 * - SECTOR_ADMIN/SECTOR_CHIEF: must have sectorId set
 * - WARD_ADMIN/WARD_CHIEF: must have wardId set
 * - POD_ADMIN/POD_CHIEF: must have podId set
 */
data class Admin(
    val id: AdminId,
    val podId: PodId? = null,
    val wardId: WardId? = null,
    val sectorId: SectorId? = null,
    val email: String,
    val displayName: String,
    val knownAs: String? = null,
    val contactPhone: String? = null,
    val address: String? = null,
    val role: AdminRole,
    val onboardingStatus: OnboardingStatus = OnboardingStatus.ACTIVE,
    val onboardingCompletedAt: Instant? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
    val deletedAt: Instant? = null,
) {
    val fullName: String get() = displayName

    val isDeleted: Boolean get() = deletedAt != null

    /**
     * Returns the organizational level this admin operates at.
     */
    val level: AdminLevel
        get() = role.level

    /**
     * Returns true if the administrator needs to complete onboarding.
     */
    val requiresOnboarding: Boolean
        get() = !onboardingStatus.isOnboarded

    /**
     * Returns true if the administrator needs to change their password.
     */
    val requiresPasswordChange: Boolean
        get() = onboardingStatus.requiresPasswordChange

    /**
     * Returns true if the administrator needs to complete their profile.
     */
    val requiresProfileCompletion: Boolean
        get() = onboardingStatus.requiresProfileCompletion
}

/**
 * Organizational level for admin roles.
 */
enum class AdminLevel {
    SECTOR,
    WARD,
    POD,
}

/**
 * Admin roles within the system.
 * Ordered by permission level (lowest to highest).
 * Each higher role inherits permissions of lower roles.
 *
 * Permission hierarchy (6 levels):
 * POD_CHIEF (5) > POD_ADMIN (4) > WARD_CHIEF (3) > WARD_ADMIN (2) > SECTOR_CHIEF (1) > SECTOR_ADMIN (0)
 */
enum class AdminRole {
    SECTOR_ADMIN,
    SECTOR_CHIEF,
    WARD_ADMIN,
    WARD_CHIEF,
    POD_ADMIN,
    POD_CHIEF,
    ;

    fun toDbValue(): String = name.lowercase()

    /**
     * Returns the organizational level this role operates at.
     */
    val level: AdminLevel
        get() =
            when (this) {
                SECTOR_ADMIN, SECTOR_CHIEF -> AdminLevel.SECTOR
                WARD_ADMIN, WARD_CHIEF -> AdminLevel.WARD
                POD_ADMIN, POD_CHIEF -> AdminLevel.POD
            }

    /**
     * Returns true if this is a chief (supervisor) role at its level.
     */
    val isChief: Boolean
        get() = this in listOf(SECTOR_CHIEF, WARD_CHIEF, POD_CHIEF)

    /**
     * Check if this role has at least the given permission level.
     * A role has permission if its ordinal is >= the required role's ordinal.
     */
    fun hasPermission(required: AdminRole): Boolean = this.ordinal >= required.ordinal

    /**
     * Check if this role can manage the given target role.
     * A role can manage another role if it has a higher permission level.
     */
    fun canManage(targetRole: AdminRole): Boolean = this.ordinal > targetRole.ordinal

    companion object {
        fun fromDbValue(value: String): AdminRole =
            when (value.lowercase()) {
                "sector_admin" -> SECTOR_ADMIN
                "sector_chief" -> SECTOR_CHIEF
                "ward_admin" -> WARD_ADMIN
                "ward_chief" -> WARD_CHIEF
                "pod_admin" -> POD_ADMIN
                "pod_chief" -> POD_CHIEF
                else -> throw IllegalArgumentException("Unknown admin role: $value")
            }
    }
}
