package com.munserv.pod.api

import com.munserv.admin.api.AdminCreatedResponse
import com.munserv.admin.api.AdminListResponse
import com.munserv.admin.api.AdminResponse
import com.munserv.admin.api.CreateAdminRequest
import com.munserv.admin.api.UpdateAdminRequest
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.service.AdminManagementService
import com.munserv.admin.service.AdminResult
import com.munserv.shared.security.RequireRole
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
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
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * REST controller for pod administrator management.
 * Provides endpoints for Pod Chiefs to manage all administrators within their pod.
 *
 * All endpoints require POD_CHIEF role.
 */
@RestController
@RequestMapping("/api/v1/pod/administrators")
@Tag(name = "Pod Administrators", description = "Manage pod administrators. Requires pod_chief role.")
@SecurityRequirement(name = "bearerAuth")
@RequireRole(AdminRole.POD_CHIEF)
class PodAdministratorController(
    private val adminService: AdminManagementService,
    private val podIdResolver: PodIdResolver,
) {
    @Operation(
        summary = "List all administrators in the pod",
        description = "Returns all administrators (at any level) within the current pod.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Administrators retrieved successfully",
                content = [Content(schema = Schema(implementation = AdminListResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
        ],
    )
    @GetMapping
    fun listAdministrators(): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Not authenticated"),
                )

        val podId =
            getCurrentPodId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Could not determine pod for current user"),
                )

        return when (val result = adminService.listAdminsByPod(podId, actorId)) {
            is AdminResult.ListSuccess ->
                ResponseEntity.ok(
                    AdminListResponse(
                        items = result.admins.map { AdminResponse.from(it) },
                        total = result.total,
                    ),
                )
            is AdminResult.Unauthorized ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", result.reason),
                )
            is AdminResult.OutOfScope ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("out_of_scope", result.reason),
                )
            else ->
                ResponseEntity.internalServerError().build<Any>()
        }
    }

    @Operation(
        summary = "Get administrator by ID",
        description = "Retrieve a single administrator's details.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Administrator retrieved successfully",
                content = [Content(schema = Schema(implementation = AdminResponse::class))],
            ),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions or out of scope"),
            ApiResponse(responseCode = "404", description = "Administrator not found"),
        ],
    )
    @GetMapping("/{id}")
    fun getAdministrator(
        @Parameter(description = "Administrator UUID")
        @PathVariable id: UUID,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Not authenticated"),
                )

        return when (val result = adminService.getAdmin(AdminId(id), actorId)) {
            is AdminResult.Success ->
                ResponseEntity.ok(AdminResponse.from(result.admin))
            is AdminResult.NotFound ->
                ResponseEntity.notFound().build<Any>()
            is AdminResult.CrossPodOperation ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("cross_pod", "Cannot access administrator in a different pod"),
                )
            is AdminResult.OutOfScope ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("out_of_scope", result.reason),
                )
            is AdminResult.Unauthorized ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", result.reason),
                )
            else ->
                ResponseEntity.internalServerError().build<Any>()
        }
    }

    @Operation(
        summary = "Create a new administrator",
        description = "Create a new administrator within the pod. A temporary password will be generated.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "201",
                description = "Administrator created successfully",
                content = [Content(schema = Schema(implementation = AdminCreatedResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "409", description = "Email already exists"),
        ],
    )
    @PostMapping
    fun createAdministrator(
        @RequestBody request: CreateAdminRequest,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Not authenticated"),
                )

        val podId =
            getCurrentPodId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Could not determine pod for current user"),
                )

        // Convert request to command, ensuring podId is set for pod-level roles
        val command =
            request.toCommand().let { cmd ->
                // For pod-level admins, ensure podId is set to current pod
                when (cmd.role.level) {
                    com.munserv.admin.domain.AdminLevel.POD -> cmd.copy(podId = podId)
                    else -> cmd
                }
            }

        return when (val result = adminService.createAdmin(command, actorId)) {
            is AdminResult.Created ->
                ResponseEntity.status(HttpStatus.CREATED).body(
                    AdminCreatedResponse.from(result.admin, result.temporaryPassword),
                )
            is AdminResult.EmailAlreadyExists ->
                ResponseEntity.status(HttpStatus.CONFLICT).body(
                    ErrorResponse("email_exists", "Email ${result.email} is already registered"),
                )
            is AdminResult.ValidationError ->
                ResponseEntity.badRequest().body(
                    ErrorResponse("validation_error", result.errors.joinToString("; ")),
                )
            is AdminResult.InsufficientRoleToManage ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse(
                        "insufficient_permissions",
                        "Cannot create administrator with role ${result.targetRole.toDbValue()}",
                    ),
                )
            is AdminResult.CrossPodOperation ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("cross_pod", "Cannot create administrator in a different pod"),
                )
            is AdminResult.OutOfScope ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("out_of_scope", result.reason),
                )
            is AdminResult.Unauthorized ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", result.reason),
                )
            else ->
                ResponseEntity.internalServerError().build<Any>()
        }
    }

    @Operation(
        summary = "Update an administrator",
        description = "Update an existing administrator's details.",
    )
    @ApiResponses(
        value = [
            ApiResponse(
                responseCode = "200",
                description = "Administrator updated successfully",
                content = [Content(schema = Schema(implementation = AdminResponse::class))],
            ),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Administrator not found"),
        ],
    )
    @PatchMapping("/{id}")
    fun updateAdministrator(
        @Parameter(description = "Administrator UUID")
        @PathVariable id: UUID,
        @RequestBody request: UpdateAdminRequest,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Not authenticated"),
                )

        return when (val result = adminService.updateAdmin(AdminId(id), request.toCommand(), actorId)) {
            is AdminResult.Success ->
                ResponseEntity.ok(AdminResponse.from(result.admin))
            is AdminResult.NotFound ->
                ResponseEntity.notFound().build<Any>()
            is AdminResult.ValidationError ->
                ResponseEntity.badRequest().body(
                    ErrorResponse("validation_error", result.errors.joinToString("; ")),
                )
            is AdminResult.InsufficientRoleToManage ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse(
                        "insufficient_permissions",
                        "Cannot modify administrator with role ${result.targetRole.toDbValue()}",
                    ),
                )
            is AdminResult.CrossPodOperation ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("cross_pod", "Cannot modify administrator in a different pod"),
                )
            is AdminResult.OutOfScope ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("out_of_scope", result.reason),
                )
            is AdminResult.Unauthorized ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", result.reason),
                )
            else ->
                ResponseEntity.internalServerError().build<Any>()
        }
    }

    @Operation(
        summary = "Delete an administrator",
        description = "Soft delete an administrator (set deletedAt timestamp).",
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "204", description = "Administrator deleted successfully"),
            ApiResponse(responseCode = "401", description = "Not authenticated"),
            ApiResponse(responseCode = "403", description = "Insufficient permissions"),
            ApiResponse(responseCode = "404", description = "Administrator not found"),
        ],
    )
    @DeleteMapping("/{id}")
    fun deleteAdministrator(
        @Parameter(description = "Administrator UUID")
        @PathVariable id: UUID,
    ): ResponseEntity<*> {
        val actorId =
            getCurrentAdminId()
                ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", "Not authenticated"),
                )

        return when (val result = adminService.deleteAdmin(AdminId(id), actorId)) {
            is AdminResult.Deleted ->
                ResponseEntity.noContent().build<Any>()
            is AdminResult.NotFound ->
                ResponseEntity.notFound().build<Any>()
            is AdminResult.CannotDeleteSelf ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("cannot_delete_self", "Cannot delete your own account"),
                )
            is AdminResult.InsufficientRoleToManage ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse(
                        "insufficient_permissions",
                        "Cannot delete administrator with role ${result.targetRole.toDbValue()}",
                    ),
                )
            is AdminResult.CrossPodOperation ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("cross_pod", "Cannot delete administrator in a different pod"),
                )
            is AdminResult.OutOfScope ->
                ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                    ErrorResponse("out_of_scope", result.reason),
                )
            is AdminResult.Unauthorized ->
                ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    ErrorResponse("unauthorized", result.reason),
                )
            else ->
                ResponseEntity.internalServerError().build<Any>()
        }
    }

    private fun getCurrentPodId(): PodId? {
        val adminId = getCurrentAdminId() ?: return null
        return podIdResolver.resolvePodId(adminId)
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
