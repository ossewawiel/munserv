package com.munserv.admin.api

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.CreateAdminCommand
import com.munserv.admin.domain.UpdateAdminCommand
import com.munserv.shared.types.SectorId
import io.swagger.v3.oas.annotations.media.Schema

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
        allowableValues = ["sector_admin"],
        required = true,
    )
    val role: String,
) {
    fun toCommand(sectorId: SectorId): CreateAdminCommand =
        CreateAdminCommand(
            email = email,
            displayName = displayName,
            role = AdminRole.fromDbValue(role),
            sectorId = sectorId,
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
    @field:Schema(description = "Sector UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String,
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
                sectorId = admin.sectorId.value.toString(),
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
    @field:Schema(description = "Sector UUID", example = "550e8400-e29b-41d4-a716-446655440001")
    val sectorId: String,
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
                sectorId = admin.sectorId.value.toString(),
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
