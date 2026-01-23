package com.munserv.admin.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminLevel
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.CreateAdminCommand
import com.munserv.admin.domain.UpdateAdminCommand
import com.munserv.admin.repository.AdminRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import com.munserv.shared.types.SectorId
import com.munserv.shared.types.WardId
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.Clock
import java.time.Instant

/**
 * Service for admin management operations.
 * Handles CRUD operations for admins with proper authorization checks.
 *
 * Authorization rules (6-level hierarchy):
 * - POD_CHIEF (5) > POD_ADMIN (4) > WARD_CHIEF (3) > WARD_ADMIN (2) > SECTOR_CHIEF (1) > SECTOR_ADMIN (0)
 * - Admins can only manage admins with strictly lower roles
 * - Scope restrictions:
 *   - Sector admins can only manage within their sector
 *   - Ward admins can manage across sectors within their ward
 *   - Pod admins can manage across wards/sectors within their pod
 */
@Service
class AdminManagementService(
    private val adminRepository: AdminRepository,
    private val passwordEncoder: PasswordEncoder,
    private val clock: Clock = Clock.systemUTC(),
) {
    /**
     * Create a new admin at any level (sector, ward, or pod).
     *
     * @param command The creation command with admin details
     * @param createdBy The admin performing the operation
     * @return AdminResult indicating success or failure
     */
    @Transactional
    fun createAdmin(
        command: CreateAdminCommand,
        createdBy: AdminId,
    ): AdminResult {
        // Get the creating admin
        val actor =
            adminRepository.findById(createdBy)
                ?: return AdminResult.Unauthorized("Actor admin not found")

        // Validate command
        val validationErrors = command.validate()
        if (validationErrors.isNotEmpty()) {
            return AdminResult.ValidationError(validationErrors)
        }

        // Authorization checks
        // 1. Actor must be able to manage the target role
        if (!actor.role.canManage(command.role)) {
            return AdminResult.InsufficientRoleToManage(actor.role, command.role)
        }

        // 2. Check scope based on actor's level
        val scopeCheck = checkCreationScope(actor, command)
        if (scopeCheck != null) {
            return scopeCheck
        }

        // Check for duplicate email
        if (adminRepository.existsByEmail(command.email)) {
            return AdminResult.EmailAlreadyExists(command.email)
        }

        // Generate temporary password
        val temporaryPassword = generateTemporaryPassword()
        val passwordHash = passwordEncoder.encode(temporaryPassword)

        // Create the admin
        val now = Instant.now(clock)
        val newAdmin =
            Admin(
                id = AdminId.generate(),
                podId = command.podId,
                wardId = command.wardId,
                sectorId = command.sectorId,
                email = command.email,
                displayName = command.displayName,
                role = command.role,
                createdAt = now,
                updatedAt = now,
            )

        val savedAdmin = adminRepository.save(newAdmin, passwordHash)

        return AdminResult.Created(savedAdmin, temporaryPassword)
    }

    /**
     * Check if actor can create admin with the given command scope.
     * Returns null if allowed, or an AdminResult error if not.
     */
    private fun checkCreationScope(
        actor: Admin,
        command: CreateAdminCommand,
    ): AdminResult? {
        return when (actor.level) {
            AdminLevel.SECTOR -> {
                // Sector admins can only create within their sector
                if (command.sectorId != null && command.sectorId != actor.sectorId) {
                    AdminResult.CrossSectorOperation(actor.sectorId!!, command.sectorId)
                } else {
                    null
                }
            }
            AdminLevel.WARD -> {
                // Ward admins can create sector admins in their ward, but not ward/pod admins
                // The role check already handles that; just check ward scope
                if (command.wardId != null && command.wardId != actor.wardId) {
                    AdminResult.CrossWardOperation(actor.wardId!!, command.wardId)
                } else {
                    null
                }
            }
            AdminLevel.POD -> {
                // Pod admins can create ward/sector admins in their pod
                if (command.podId != null && command.podId != actor.podId) {
                    AdminResult.CrossPodOperation(actor.podId!!, command.podId)
                } else {
                    null
                }
            }
        }
    }

    /**
     * List admins in a sector.
     *
     * @param sectorId The sector to list admins for
     * @param requestedBy The admin requesting the list
     * @return AdminResult with list of admins
     */
    @Transactional(readOnly = true)
    fun listAdmins(
        sectorId: SectorId,
        requestedBy: AdminId,
    ): AdminResult {
        val actor =
            adminRepository.findById(requestedBy)
                ?: return AdminResult.Unauthorized("Actor admin not found")

        // Check if actor can view admins in this sector
        val scopeCheck = checkViewScope(actor, sectorId = sectorId)
        if (scopeCheck != null) {
            return scopeCheck
        }

        val admins = adminRepository.findBySectorId(sectorId)

        return AdminResult.ListSuccess(admins, admins.size)
    }

    /**
     * List admins in a ward.
     *
     * @param wardId The ward to list admins for
     * @param requestedBy The admin requesting the list
     * @return AdminResult with list of admins
     */
    @Transactional(readOnly = true)
    fun listAdminsByWard(
        wardId: WardId,
        requestedBy: AdminId,
    ): AdminResult {
        val actor =
            adminRepository.findById(requestedBy)
                ?: return AdminResult.Unauthorized("Actor admin not found")

        // Check if actor can view admins in this ward
        val scopeCheck = checkViewScope(actor, wardId = wardId)
        if (scopeCheck != null) {
            return scopeCheck
        }

        val admins = adminRepository.findByWardId(wardId)

        return AdminResult.ListSuccess(admins, admins.size)
    }

    /**
     * List admins in a pod.
     *
     * @param podId The pod to list admins for
     * @param requestedBy The admin requesting the list
     * @return AdminResult with list of admins
     */
    @Transactional(readOnly = true)
    fun listAdminsByPod(
        podId: PodId,
        requestedBy: AdminId,
    ): AdminResult {
        val actor =
            adminRepository.findById(requestedBy)
                ?: return AdminResult.Unauthorized("Actor admin not found")

        // Check if actor can view admins in this pod
        val scopeCheck = checkViewScope(actor, podId = podId)
        if (scopeCheck != null) {
            return scopeCheck
        }

        val admins = adminRepository.findByPodId(podId)

        return AdminResult.ListSuccess(admins, admins.size)
    }

    /**
     * Check if actor can view admins in the given scope.
     * Returns null if allowed, or an AdminResult error if not.
     */
    private fun checkViewScope(
        actor: Admin,
        podId: PodId? = null,
        wardId: WardId? = null,
        sectorId: SectorId? = null,
    ): AdminResult? {
        return when (actor.level) {
            AdminLevel.SECTOR -> {
                // Sector admins can only view within their sector
                if (sectorId != null && sectorId != actor.sectorId) {
                    AdminResult.CrossSectorOperation(actor.sectorId!!, sectorId)
                } else if (wardId != null || podId != null) {
                    AdminResult.OutOfScope("Sector-level admin cannot view ward/pod-level admins")
                } else {
                    null
                }
            }
            AdminLevel.WARD -> {
                // Ward admins can view within their ward
                if (wardId != null && wardId != actor.wardId) {
                    AdminResult.CrossWardOperation(actor.wardId!!, wardId)
                } else if (podId != null) {
                    AdminResult.OutOfScope("Ward-level admin cannot view pod-level admins")
                } else {
                    // Allow viewing sector admins in their ward
                    null
                }
            }
            AdminLevel.POD -> {
                // Pod admins can view within their pod
                if (podId != null && podId != actor.podId) {
                    AdminResult.CrossPodOperation(actor.podId!!, podId)
                } else {
                    null
                }
            }
        }
    }

    /**
     * Get a single admin by ID.
     *
     * @param id The admin ID
     * @param requestedBy The admin requesting the info
     * @return AdminResult with admin or error
     */
    @Transactional(readOnly = true)
    fun getAdmin(
        id: AdminId,
        requestedBy: AdminId,
    ): AdminResult {
        val actor =
            adminRepository.findById(requestedBy)
                ?: return AdminResult.Unauthorized("Actor admin not found")

        val targetAdmin =
            adminRepository.findById(id)
                ?: return AdminResult.NotFound(id)

        // Check if actor can view this admin
        val scopeCheck = checkAdminInScope(actor, targetAdmin)
        if (scopeCheck != null) {
            return scopeCheck
        }

        return AdminResult.Success(targetAdmin)
    }

    /**
     * Check if the target admin is within the actor's scope.
     * Returns null if in scope, or an AdminResult error if not.
     */
    private fun checkAdminInScope(
        actor: Admin,
        target: Admin,
    ): AdminResult? {
        return when (actor.level) {
            AdminLevel.SECTOR -> {
                // Sector admins can only access admins in their sector
                if (target.sectorId != null && target.sectorId != actor.sectorId) {
                    AdminResult.CrossSectorOperation(actor.sectorId!!, target.sectorId)
                } else if (target.level != AdminLevel.SECTOR) {
                    AdminResult.OutOfScope("Sector-level admin cannot access ward/pod-level admins")
                } else {
                    null
                }
            }
            AdminLevel.WARD -> {
                // Ward admins can access admins in their ward or sectors within their ward
                when (target.level) {
                    AdminLevel.SECTOR -> null // TODO: verify sector belongs to ward
                    AdminLevel.WARD -> {
                        if (target.wardId != actor.wardId) {
                            AdminResult.CrossWardOperation(actor.wardId!!, target.wardId)
                        } else {
                            null
                        }
                    }
                    AdminLevel.POD -> AdminResult.OutOfScope("Ward-level admin cannot access pod-level admins")
                }
            }
            AdminLevel.POD -> {
                // Pod admins can access all admins in their pod
                when (target.level) {
                    AdminLevel.SECTOR -> null // TODO: verify sector belongs to pod
                    AdminLevel.WARD -> null // TODO: verify ward belongs to pod
                    AdminLevel.POD -> {
                        if (target.podId != actor.podId) {
                            AdminResult.CrossPodOperation(actor.podId!!, target.podId)
                        } else {
                            null
                        }
                    }
                }
            }
        }
    }

    /**
     * Update an existing admin.
     *
     * @param id The admin ID to update
     * @param command The update command
     * @param updatedBy The admin performing the update
     * @return AdminResult indicating success or failure
     */
    @Transactional
    fun updateAdmin(
        id: AdminId,
        command: UpdateAdminCommand,
        updatedBy: AdminId,
    ): AdminResult {
        val actor =
            adminRepository.findById(updatedBy)
                ?: return AdminResult.Unauthorized("Actor admin not found")

        val targetAdmin =
            adminRepository.findById(id)
                ?: return AdminResult.NotFound(id)

        // Validate command
        val validationErrors = command.validate()
        if (validationErrors.isNotEmpty()) {
            return AdminResult.ValidationError(validationErrors)
        }

        // Authorization checks
        // 1. Check scope
        val scopeCheck = checkAdminInScope(actor, targetAdmin)
        if (scopeCheck != null) {
            return scopeCheck
        }

        // 2. Can only manage admins with lower roles (except self)
        if (actor.id != id && !actor.role.canManage(targetAdmin.role)) {
            return AdminResult.InsufficientRoleToManage(actor.role, targetAdmin.role)
        }

        // Apply updates
        val now = Instant.now(clock)
        val updatedAdmin =
            targetAdmin.copy(
                displayName = command.displayName ?: targetAdmin.displayName,
                updatedAt = now,
            )

        val savedAdmin = adminRepository.update(updatedAdmin)

        return AdminResult.Success(savedAdmin)
    }

    /**
     * Soft delete an admin (set deletedAt timestamp).
     *
     * @param id The admin ID to delete
     * @param deletedBy The admin performing the deletion
     * @return AdminResult indicating success or failure
     */
    @Transactional
    fun deleteAdmin(
        id: AdminId,
        deletedBy: AdminId,
    ): AdminResult {
        val actor =
            adminRepository.findById(deletedBy)
                ?: return AdminResult.Unauthorized("Actor admin not found")

        val targetAdmin =
            adminRepository.findById(id)
                ?: return AdminResult.NotFound(id)

        // Cannot delete self
        if (actor.id == id) {
            return AdminResult.CannotDeleteSelf
        }

        // Authorization checks
        // 1. Check scope
        val scopeCheck = checkAdminInScope(actor, targetAdmin)
        if (scopeCheck != null) {
            return scopeCheck
        }

        // 2. Can only delete admins with lower roles
        if (!actor.role.canManage(targetAdmin.role)) {
            return AdminResult.InsufficientRoleToManage(actor.role, targetAdmin.role)
        }

        // Soft delete
        val now = Instant.now(clock)
        val deletedAdmin =
            targetAdmin.copy(
                deletedAt = now,
                updatedAt = now,
            )

        adminRepository.update(deletedAdmin)

        return AdminResult.Deleted
    }

    private fun generateTemporaryPassword(): String {
        val random = SecureRandom()
        return (1..TEMP_PASSWORD_LENGTH)
            .map { TEMP_PASSWORD_CHARS[random.nextInt(TEMP_PASSWORD_CHARS.size)] }
            .joinToString("")
    }

    companion object {
        private const val TEMP_PASSWORD_LENGTH = 12
        private val TEMP_PASSWORD_CHARS = ('A'..'Z') + ('a'..'z') + ('0'..'9')
    }
}
