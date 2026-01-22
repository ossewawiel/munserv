package com.munserv.admin.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.CreateAdminCommand
import com.munserv.admin.domain.UpdateAdminCommand
import com.munserv.admin.repository.AdminRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.Clock
import java.time.Instant

/**
 * Service for admin management operations.
 * Handles CRUD operations for sector admins with proper authorization checks.
 *
 * Authorization rules:
 * - Sector chiefs can only manage admins in their own sector
 * - Sector chiefs can only manage admins with lower roles (sector_admin)
 * - Pod admins/chiefs can manage across sectors within their pod (future)
 */
@Service
class AdminManagementService(
    private val adminRepository: AdminRepository,
    private val passwordEncoder: PasswordEncoder,
    private val clock: Clock = Clock.systemUTC(),
) {
    /**
     * Create a new sector admin.
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

        // 2. Sector chiefs can only create admins in their own sector
        if (actor.role == AdminRole.SECTOR_CHIEF && actor.sectorId != command.sectorId) {
            return AdminResult.CrossSectorOperation(actor.sectorId, command.sectorId)
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

        // Sector chiefs can only see admins in their own sector
        if (actor.role == AdminRole.SECTOR_CHIEF && actor.sectorId != sectorId) {
            return AdminResult.CrossSectorOperation(actor.sectorId, sectorId)
        }

        val admins = adminRepository.findBySectorId(sectorId)

        return AdminResult.ListSuccess(admins, admins.size)
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

        // Sector chiefs can only see admins in their own sector
        if (actor.role == AdminRole.SECTOR_CHIEF && actor.sectorId != targetAdmin.sectorId) {
            return AdminResult.CrossSectorOperation(actor.sectorId, targetAdmin.sectorId)
        }

        return AdminResult.Success(targetAdmin)
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
        // 1. Sector chiefs can only manage admins in their own sector
        if (actor.role == AdminRole.SECTOR_CHIEF && actor.sectorId != targetAdmin.sectorId) {
            return AdminResult.CrossSectorOperation(actor.sectorId, targetAdmin.sectorId)
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
        // 1. Sector chiefs can only delete admins in their own sector
        if (actor.role == AdminRole.SECTOR_CHIEF && actor.sectorId != targetAdmin.sectorId) {
            return AdminResult.CrossSectorOperation(actor.sectorId, targetAdmin.sectorId)
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
