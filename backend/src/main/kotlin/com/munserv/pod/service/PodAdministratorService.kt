package com.munserv.pod.service

import com.munserv.admin.domain.CreateAdminCommand
import com.munserv.admin.service.AdminManagementService
import com.munserv.admin.service.AdminResult
import com.munserv.messages.service.MessageFactory
import com.munserv.messages.service.MessageService
import com.munserv.shared.types.AdminId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * Service for pod-level administrator creation.
 *
 * Wraps [AdminManagementService.createAdmin] to also send the new administrator
 * an `admin_welcome` message with their initial onboarding tasks.
 */
@Service
class PodAdministratorService(
    private val adminService: AdminManagementService,
    private val messageService: MessageService,
) {
    @Transactional
    fun createAdministrator(
        command: CreateAdminCommand,
        createdBy: AdminId,
    ): AdminResult {
        val result = adminService.createAdmin(command, createdBy)

        if (result is AdminResult.Created) {
            messageService.createMessage(
                MessageFactory.adminWelcome(
                    recipientId = result.admin.id.value,
                    displayName = result.admin.displayName,
                    role = result.admin.role.toDbValue(),
                ),
            )
        }

        return result
    }
}
