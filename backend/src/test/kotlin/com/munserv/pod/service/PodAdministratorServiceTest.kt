package com.munserv.pod.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.CreateAdminCommand
import com.munserv.admin.service.AdminManagementService
import com.munserv.admin.service.AdminResult
import com.munserv.messages.domain.MessageEntity
import com.munserv.messages.service.MessageService
import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Instant

class PodAdministratorServiceTest {
    private lateinit var adminService: AdminManagementService
    private lateinit var messageService: MessageService
    private lateinit var service: PodAdministratorService

    private val fixedInstant = Instant.parse("2026-09-06T10:00:00Z")
    private val actorId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val newAdminId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440011")

    private val command =
        CreateAdminCommand(
            email = "newadmin@example.com",
            displayName = "Jane Ward",
            role = AdminRole.SECTOR_ADMIN,
            sectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001"),
        )

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        adminService = mockk()
        messageService = mockk()
        service = PodAdministratorService(adminService, messageService)
    }

    private fun createTestAdmin() =
        Admin(
            id = newAdminId,
            sectorId = command.sectorId,
            email = command.email,
            displayName = command.displayName,
            role = command.role,
            createdAt = fixedInstant,
            updatedAt = fixedInstant,
        )

    @Test
    fun `should create a welcome message when the administrator is created`() {
        val admin = createTestAdmin()
        every { adminService.createAdmin(command, actorId) } returns
            AdminResult.Created(admin, "temp-password")
        val messageSlot = slot<MessageEntity>()
        every { messageService.createMessage(capture(messageSlot)) } answers { messageSlot.captured }

        val result = service.createAdministrator(command, actorId)

        result.shouldBeInstanceOf<AdminResult.Created>()
        verify(exactly = 1) { messageService.createMessage(any()) }
        messageSlot.captured.type shouldBe MessageType.ADMIN_WELCOME
        messageSlot.captured.recipientId shouldBe newAdminId.value
        messageSlot.captured.status shouldBe MessageStatus.UNREAD
    }

    @Test
    fun `should not create a message when creation fails`() {
        every { adminService.createAdmin(command, actorId) } returns
            AdminResult.EmailAlreadyExists(command.email)

        val result = service.createAdministrator(command, actorId)

        result.shouldBeInstanceOf<AdminResult.EmailAlreadyExists>()
        verify(exactly = 0) { messageService.createMessage(any()) }
    }

    @Test
    fun `should return the result of the admin service unchanged`() {
        val failure = AdminResult.ValidationError(listOf("Email is required"))
        every { adminService.createAdmin(command, actorId) } returns failure

        val result = service.createAdministrator(command, actorId)

        result shouldBe failure
    }
}
