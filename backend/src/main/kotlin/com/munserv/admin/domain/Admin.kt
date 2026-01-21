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
 * Admin roles within a sector.
 */
enum class AdminRole {
    SECTOR_ADMIN,
    SUPER_ADMIN,
    ;

    fun toDbValue(): String = name.lowercase()

    companion object {
        fun fromDbValue(value: String): AdminRole =
            when (value.lowercase()) {
                "sector_admin" -> SECTOR_ADMIN
                "super_admin" -> SUPER_ADMIN
                else -> throw IllegalArgumentException("Unknown admin role: $value")
            }
    }
}
