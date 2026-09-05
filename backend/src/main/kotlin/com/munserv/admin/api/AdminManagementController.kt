package com.munserv.admin.api

import com.munserv.admin.domain.AdminRole
import com.munserv.admin.service.AdminManagementService
import com.munserv.admin.service.AdminResult
import com.munserv.shared.security.RequireRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.media.Content
import io.swagger.v3.oas.annotations.media.Schema
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for admin user management.
 * Allows sector chiefs to create, list, update, and delete sector admins.
 *
 * All endpoints require SECTOR_CHIEF role or higher.
 */
@RestController
@RequestMapping("/api/v1/admins")
@Tag(name = "Admin Management", description = "Endpoints for managing admin users. Requires sector_chief role.")
@SecurityRequirement(name = "bearerAuth")
@RequireRole(AdminRole.SECTOR_CHIEF)
class AdminManagementController(
    private val adminManagementService: AdminManagementService,
) {
    @Operation(
        summary = "Create a new admin",
        description = "Create a new sector admin. A temporary password will be generated.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "201",
                description = "Admin created successfully",
                content = [Content(schema = Schema(implementation = AdminCreatedResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "409", description = "Email already exists"),
        ],
    )
    @PostMapping
    fun createAdmin(
        @RequestBody request: CreateAdminRequest,
        @Parameter(description = "Sector UUID for the new admin")
        @RequestParam sectorId: String,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        val command = request.toCommand(SectorId(UUID.fromString(sectorId)))

        return when (val result = adminManagementService.createAdmin(command, actorId)) {
            is AdminResult.Created -> {
                ResponseEntity.status(HttpStatus.CREATED).body(
                    AdminCreatedResponse.from(result.admin, result.temporaryPassword),
                )
            }

            is AdminResult.EmailAlreadyExists -> {
                ResponseEntity.status(HttpStatus.CONFLICT).body(
                    ErrorBody("email_exists", "Email ${result.email} is already registered"),
                )
            }

            is AdminResult.ValidationError -> {
                ResponseEntity.badRequest().body(
                    ErrorBody("validation_error", result.errors.joinToString("; ")),
                )
            }

            is AdminResult.InsufficientRoleToManage -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody(
                        "insufficient_permissions",
                        "Role ${result.actorRole.toDbValue()} cannot manage ${result.targetRole.toDbValue()} role",
                    ),
                )
            }

            is AdminResult.CrossSectorOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_sector", "Cannot manage admins in a different sector"),
                )
            }

            is AdminResult.CrossWardOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_ward", "Cannot manage admins in a different ward"),
                )
            }

            is AdminResult.CrossPodOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_pod", "Cannot manage admins in a different pod"),
                )
            }

            is AdminResult.OutOfScope -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("out_of_scope", result.reason),
                )
            }

            is AdminResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", result.reason),
                )
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    @Operation(
        summary = "List admins in a sector",
        description = "Retrieve a list of all admins in the specified sector.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "List retrieved successfully",
                content = [Content(schema = Schema(implementation = AdminListResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Cannot view admins in a different sector"),
        ],
    )
    @GetMapping
    fun listAdmins(
        @Parameter(description = "Sector UUID to list admins for")
        @RequestParam sectorId: String,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        return when (val result = adminManagementService.listAdmins(SectorId(UUID.fromString(sectorId)), actorId)) {
            is AdminResult.ListSuccess -> {
                ResponseEntity.ok(
                    AdminListResponse(
                        items = result.admins.map { AdminResponse.from(it) },
                        total = result.total,
                    ),
                )
            }

            is AdminResult.CrossSectorOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_sector", "Cannot view admins in a different sector"),
                )
            }

            is AdminResult.CrossWardOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_ward", "Cannot view admins in a different ward"),
                )
            }

            is AdminResult.CrossPodOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_pod", "Cannot view admins in a different pod"),
                )
            }

            is AdminResult.OutOfScope -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("out_of_scope", result.reason),
                )
            }

            is AdminResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", result.reason),
                )
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    @Operation(
        summary = "Get admin by ID",
        description = "Retrieve a single admin by their ID.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Admin retrieved successfully",
                content = [Content(schema = Schema(implementation = AdminResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Cannot view admin in a different sector"),
            ApiResponse(responseCode = "404", description = "Admin not found"),
        ],
    )
    @GetMapping("/{id}")
    fun getAdmin(
        @Parameter(description = "Admin UUID")
        @PathVariable id: String,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        return when (val result = adminManagementService.getAdmin(AdminId(UUID.fromString(id)), actorId)) {
            is AdminResult.Success -> {
                ResponseEntity.ok(AdminResponse.from(result.admin))
            }

            is AdminResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is AdminResult.CrossSectorOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_sector", "Cannot view admin in a different sector"),
                )
            }

            is AdminResult.CrossWardOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_ward", "Cannot view admin in a different ward"),
                )
            }

            is AdminResult.CrossPodOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_pod", "Cannot view admin in a different pod"),
                )
            }

            is AdminResult.OutOfScope -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("out_of_scope", result.reason),
                )
            }

            is AdminResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", result.reason),
                )
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    @Operation(
        summary = "Update an admin",
        description = "Update an existing admin's details. Only provided fields will be updated.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Admin updated successfully",
                content = [Content(schema = Schema(implementation = AdminResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Admin not found"),
        ],
    )
    @PatchMapping("/{id}")
    fun updateAdmin(
        @Parameter(description = "Admin UUID")
        @PathVariable id: String,
        @RequestBody request: UpdateAdminRequest,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        return when (
            val result =
                adminManagementService.updateAdmin(
                    AdminId(UUID.fromString(id)),
                    request.toCommand(),
                    actorId,
                )
        ) {
            is AdminResult.Success -> {
                ResponseEntity.ok(AdminResponse.from(result.admin))
            }

            is AdminResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is AdminResult.ValidationError -> {
                ResponseEntity.badRequest().body(
                    ErrorBody("validation_error", result.errors.joinToString("; ")),
                )
            }

            is AdminResult.InsufficientRoleToManage -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody(
                        "insufficient_permissions",
                        "Role ${result.actorRole.toDbValue()} cannot manage ${result.targetRole.toDbValue()} role",
                    ),
                )
            }

            is AdminResult.CrossSectorOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_sector", "Cannot manage admin in a different sector"),
                )
            }

            is AdminResult.CrossWardOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_ward", "Cannot manage admin in a different ward"),
                )
            }

            is AdminResult.CrossPodOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_pod", "Cannot manage admin in a different pod"),
                )
            }

            is AdminResult.OutOfScope -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("out_of_scope", result.reason),
                )
            }

            is AdminResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", result.reason),
                )
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    @Operation(
        summary = "Delete an admin",
        description = "Soft delete an admin (set deletedAt timestamp).",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "204", description = "Admin deleted successfully"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Admin not found"),
        ],
    )
    @DeleteMapping("/{id}")
    fun deleteAdmin(
        @Parameter(description = "Admin UUID")
        @PathVariable id: String,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", "Not authenticated"),
                )

        return when (val result = adminManagementService.deleteAdmin(AdminId(UUID.fromString(id)), actorId)) {
            is AdminResult.Deleted -> {
                ResponseEntity.noContent().build<Any>()
            }

            is AdminResult.NotFound -> {
                ResponseEntity.notFound().build<Any>()
            }

            is AdminResult.CannotDeleteSelf -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cannot_delete_self", "Cannot delete your own account"),
                )
            }

            is AdminResult.InsufficientRoleToManage -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody(
                        "insufficient_permissions",
                        "Role ${result.actorRole.toDbValue()} cannot manage ${result.targetRole.toDbValue()} role",
                    ),
                )
            }

            is AdminResult.CrossSectorOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_sector", "Cannot delete admin in a different sector"),
                )
            }

            is AdminResult.CrossWardOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_ward", "Cannot delete admin in a different ward"),
                )
            }

            is AdminResult.CrossPodOperation -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("cross_pod", "Cannot delete admin in a different pod"),
                )
            }

            is AdminResult.OutOfScope -> {
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorBody("out_of_scope", result.reason),
                )
            }

            is AdminResult.Unauthorized -> {
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorBody("unauthorized", result.reason),
                )
            }

            else -> {
                ResponseEntity.internalServerError().build<Any>()
            }
        }
    }

    private fun getCurrentAdminId(): AdminId? {
        val authentication =
            SecurityContextHolder.getContext().authentication
                ?: return null

        val subject =
            authentication.principal as? String
                ?: return null

        return try {
            AdminId(UUID.fromString(subject))
        } catch (e: IllegalArgumentException) {
            null
        }
    }
}

/**
 * Simple error response body.
 */
@Schema(description = "Error response")
data class ErrorBody(
    @field:Schema(description = "Error code", example = "validation_error")
    val code: String,
    @field:Schema(description = "Error message", example = "Display name is required")
    val message: String,
)
