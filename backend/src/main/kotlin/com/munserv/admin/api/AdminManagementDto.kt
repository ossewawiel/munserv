package com.munserv.admin.api

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.CreateAdminCommand
import com.munserv.admin.domain.UpdateAdminCommand
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import io.swagger.v3.oas.annotations.media.Schema
import java.util.UUID

/**
 * Request DTO for creating a new admin.
 */
@Schema(description = "Request to create a new admin user")
data class CreateAdminRequest(
    @field:Schema(
        description = "Email address for the new admin",
        example = "newadmin@sector.example",
        required = true,
    )
    val email: String,
    @field:Schema(
        description = "Display name for the admin",
        example = "John Smith",
        required = true,
    )
    val displayName: String,
    @field:Schema(
        description = "Admin role to assign",
        example = "sector_admin",
        allowableValues = ["sector_admin", "sector_chief", "ward_admin", "ward_chief", "pod_admin", "pod_chief"],
        required = true,
    )
    val role: String,
    @field:Schema(
        description = "Pod UUID (required for pod_admin/pod_chief roles)",
        example = "550e8400-e29b-41d4-a716-446655440000",
        required = false,
    )
    val podId: String? = null,
    @field:Schema(
        description = "Ward UUID (required for ward_admin/ward_chief roles)",
        example = "550e8400-e29b-41d4-a716-446655440030",
        required = false,
    )
    val wardId: String? = null,
    @field:Schema(
        description = "Sector UUID (required for sector_admin/sector_chief roles)",
        example = "550e8400-e29b-41d4-a716-446655440001",
        required = false,
    )
    val sectorId: String? = null,
) {
    /**
     * Convert to domain command.
     * For backwards compatibility, accepts an optional sectorId override for sector-level admins.
     */
    fun toCommand(defaultSectorId: SectorId? = null): CreateAdminCommand =
        CreateAdminCommand(
            email = email,
            displayName = displayName,
            role = AdminRole.fromDbValue(role),
            podId = podId?.let { PodId(UUID.fromString(it)) },
            wardId = wardId?.let { WardId(UUID.fromString(it)) },
            sectorId = sectorId?.let { SectorId(UUID.fromString(it)) } ?: defaultSectorId,
        )
}

/**
 * Request DTO for updating an existing admin.
 */
@Schema(description = "Request to update an existing admin user")
data class UpdateAdminRequest(
    @field:Schema(
        description = "New display name for the admin (optional)",
        example = "John D. Smith",
        required = false,
    )
    val displayName: String? = null,
) {
    fun toCommand(): UpdateAdminCommand =
        UpdateAdminCommand(
            displayName = displayName,
        )
}

/**
 * Response DTO for a single admin.
 */
@Schema(description = "Admin user details")
data class AdminResponse(
    @field:Schema(description = "Admin UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val id: String,
    @field:Schema(description = "Admin email address", example = "admin@sector.example")
    val email: String,
    @field:Schema(description = "Admin display name", example = "John Smith")
    val displayName: String,
    @field:Schema(description = "Admin role", example = "sector_admin")
    val role: String,
    @field:Schema(description = "Organizational level", example = "sector")
    val level: String,
    @field:Schema(description = "Pod UUID (for pod-level admins)", example = "550e8400-e29b-41d4-a716-446655440000")
    val podId: String? = null,
    @field:Schema(description = "Ward UUID (for ward-level admins)", example = "550e8400-e29b-41d4-a716-446655440030")
    val wardId: String? = null,
    @field:Schema(description = "Sector UUID (for sector-level admins)", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String? = null,
    @field:Schema(description = "Creation timestamp", example = "2026-01-22T10:00:00Z")
    val createdAt: String,
    @field:Schema(description = "Deletion timestamp (null if not deleted)", example = "null")
    val deletedAt: String? = null,
) {
    companion object {
        fun from(admin: Admin): AdminResponse =
            AdminResponse(
                id = admin.id.value.toString(),
                email = admin.email,
                displayName = admin.displayName,
                role = admin.role.toDbValue(),
                level = admin.level.name.lowercase(),
                podId = admin.podId?.value?.toString(),
                wardId = admin.wardId?.value?.toString(),
                sectorId = admin.sectorId?.value?.toString(),
                createdAt = admin.createdAt.toString(),
                deletedAt = admin.deletedAt?.toString(),
            )
    }
}

/**
 * Response DTO for admin creation, includes temporary password.
 */
@Schema(description = "Response after creating a new admin")
data class AdminCreatedResponse(
    @field:Schema(description = "Admin UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val id: String,
    @field:Schema(description = "Admin email address", example = "admin@sector.example")
    val email: String,
    @field:Schema(description = "Admin display name", example = "John Smith")
    val displayName: String,
    @field:Schema(description = "Admin role", example = "sector_admin")
    val role: String,
    @field:Schema(description = "Organizational level", example = "sector")
    val level: String,
    @field:Schema(description = "Pod UUID (for pod-level admins)", example = "550e8400-e29b-41d4-a716-446655440000")
    val podId: String? = null,
    @field:Schema(description = "Ward UUID (for ward-level admins)", example = "550e8400-e29b-41d4-a716-446655440030")
    val wardId: String? = null,
    @field:Schema(description = "Sector UUID (for sector-level admins)", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String? = null,
    @field:Schema(description = "Temporary password (show once)", example = "TempPass123!")
    val temporaryPassword: String,
    @field:Schema(description = "Creation timestamp", example = "2026-01-22T10:00:00Z")
    val createdAt: String,
) {
    companion object {
        fun from(
            admin: Admin,
            temporaryPassword: String,
        ): AdminCreatedResponse =
            AdminCreatedResponse(
                id = admin.id.value.toString(),
                email = admin.email,
                displayName = admin.displayName,
                role = admin.role.toDbValue(),
                level = admin.level.name.lowercase(),
                podId = admin.podId?.value?.toString(),
                wardId = admin.wardId?.value?.toString(),
                sectorId = admin.sectorId?.value?.toString(),
                temporaryPassword = temporaryPassword,
                createdAt = admin.createdAt.toString(),
            )
    }
}

/**
 * Response DTO for listing admins.
 */
@Schema(description = "Paginated list of admin users")
data class AdminListResponse(
    @field:Schema(description = "List of admins")
    val items: List<AdminResponse>,
    @field:Schema(description = "Total count of admins")
    val total: Int,
)
