package com.munserv.admin.domain

import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId
import java.time.Instant

/**
 * Domain entity representing an Admin user.
 * Admins manage sectors via the web portal.
 */
data class Admin(
    val id: AdminId,
    val sectorId: SectorId,
    val email: String,
    val displayName: String,
    val role: AdminRole,
    val createdAt: Instant,
    val updatedAt: Instant,
    val deletedAt: Instant? = null,
) {
    val fullName: String get() = displayName

    val isDeleted: Boolean get() = deletedAt != null
}

/**
 * Admin roles within the system.
 * Ordered by permission level (lowest to highest).
 * Each higher role inherits permissions of lower roles.
 *
 * Permission hierarchy:
 * POD_CHIEF (3) > POD_ADMIN (2) > SECTOR_CHIEF (1) > SECTOR_ADMIN (0)
 */
enum class AdminRole {
    SECTOR_ADMIN,
    SECTOR_CHIEF,
    POD_ADMIN,
    POD_CHIEF,
    ;

    fun toDbValue(): String = name.lowercase()

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
                "pod_admin" -> POD_ADMIN
                "pod_chief" -> POD_CHIEF
                else -> throw IllegalArgumentException("Unknown admin role: $value")
            }
    }
}
