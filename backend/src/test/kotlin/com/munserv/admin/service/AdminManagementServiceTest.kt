package com.munserv.admin.service

import com.munserv.admin.domain.Admin
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.CreateAdminCommand
import com.munserv.admin.domain.UpdateAdminCommand
import com.munserv.admin.repository.AdminRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.SectorId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldHaveLength
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.security.crypto.password.PasswordEncoder
import java.time.Clock
import java.time.Instant
import java.time.ZoneId

class AdminManagementServiceTest {
    private lateinit var adminRepository: AdminRepository
    private lateinit var passwordEncoder: PasswordEncoder
    private lateinit var clock: Clock
    private lateinit var service: AdminManagementService

    private val fixedInstant = Instant.parse("2026-01-22T10:00:00Z")
    private val testSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val otherSectorId = SectorId.fromString("550e8400-e29b-41d4-a716-446655440002")

    private val sectorChiefId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440010")
    private val sectorAdminId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440011")
    private val podAdminId = AdminId.fromString("550e8400-e29b-41d4-a716-446655440012")

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        adminRepository = mockk()
        passwordEncoder = mockk()
        clock = Clock.fixed(fixedInstant, ZoneId.of("UTC"))
        service = AdminManagementService(adminRepository, passwordEncoder, clock)
    }

    private fun createTestAdmin(
        id: AdminId = AdminId.generate(),
        sectorId: SectorId = testSectorId,
        email: String = "admin@example.com",
        displayName: String = "Test Admin",
        role: AdminRole = AdminRole.SECTOR_ADMIN,
        deletedAt: Instant? = null,
    ) = Admin(
        id = id,
        sectorId = sectorId,
        email = email,
        displayName = displayName,
        role = role,
        createdAt = fixedInstant,
        updatedAt = fixedInstant,
        deletedAt = deletedAt,
    )

    @Nested
    inner class CreateAdmin {
        @Test
        fun `should create admin successfully when sector chief creates sector admin`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val command =
                CreateAdminCommand(
                    email = "newadmin@example.com",
                    displayName = "New Admin",
                    role = AdminRole.SECTOR_ADMIN,
                    sectorId = testSectorId,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.existsByEmail("newadmin@example.com") } returns false
            every { passwordEncoder.encode(any()) } returns "hashed_password"
            every { adminRepository.save(any(), "hashed_password", any()) } answers {
                firstArg<Admin>()
            }

            val result = service.createAdmin(command, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.Created>()
            val created = result as AdminResult.Created
            created.admin.email shouldBe "newadmin@example.com"
            created.admin.displayName shouldBe "New Admin"
            created.admin.role shouldBe AdminRole.SECTOR_ADMIN
            created.admin.sectorId shouldBe testSectorId
            created.temporaryPassword shouldHaveLength 12
        }

        @Test
        fun `should return EmailAlreadyExists when email is taken`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val command =
                CreateAdminCommand(
                    email = "existing@example.com",
                    displayName = "New Admin",
                    role = AdminRole.SECTOR_ADMIN,
                    sectorId = testSectorId,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.existsByEmail("existing@example.com") } returns true

            val result = service.createAdmin(command, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.EmailAlreadyExists>()
            (result as AdminResult.EmailAlreadyExists).email shouldBe "existing@example.com"
        }

        @Test
        fun `should return InsufficientRoleToManage when sector chief tries to create sector chief`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val command =
                CreateAdminCommand(
                    email = "newchief@example.com",
                    displayName = "New Chief",
                    role = AdminRole.SECTOR_CHIEF,
                    sectorId = testSectorId,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief

            val result = service.createAdmin(command, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.InsufficientRoleToManage>()
            val insufficientRole = result as AdminResult.InsufficientRoleToManage
            insufficientRole.actorRole shouldBe AdminRole.SECTOR_CHIEF
            insufficientRole.targetRole shouldBe AdminRole.SECTOR_CHIEF
        }

        @Test
        fun `should return CrossSectorOperation when sector chief creates admin in different sector`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                    sectorId = testSectorId,
                )
            val command =
                CreateAdminCommand(
                    email = "newadmin@example.com",
                    displayName = "New Admin",
                    role = AdminRole.SECTOR_ADMIN,
                    sectorId = otherSectorId,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief

            val result = service.createAdmin(command, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.CrossSectorOperation>()
            val crossSector = result as AdminResult.CrossSectorOperation
            crossSector.actorSectorId shouldBe testSectorId
            crossSector.targetSectorId shouldBe otherSectorId
        }

        @Test
        fun `should return ValidationError for invalid email`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val command =
                CreateAdminCommand(
                    email = "invalid-email",
                    displayName = "New Admin",
                    role = AdminRole.SECTOR_ADMIN,
                    sectorId = testSectorId,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief

            val result = service.createAdmin(command, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.ValidationError>()
        }

        @Test
        fun `should allow pod admin to create sector chief`() {
            val podAdmin =
                createTestAdmin(
                    id = podAdminId,
                    role = AdminRole.POD_ADMIN,
                )
            val command =
                CreateAdminCommand(
                    email = "newchief@example.com",
                    displayName = "New Chief",
                    role = AdminRole.SECTOR_CHIEF,
                    sectorId = testSectorId,
                )

            every { adminRepository.findById(podAdminId) } returns podAdmin
            every { adminRepository.existsByEmail("newchief@example.com") } returns false
            every { passwordEncoder.encode(any()) } returns "hashed_password"
            every { adminRepository.save(any(), "hashed_password", any()) } answers {
                firstArg<Admin>()
            }

            val result = service.createAdmin(command, podAdminId)

            result.shouldBeInstanceOf<AdminResult.Created>()
            (result as AdminResult.Created).admin.role shouldBe AdminRole.SECTOR_CHIEF
        }
    }

    @Nested
    inner class ListAdmins {
        @Test
        fun `should list admins in same sector`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val admins =
                listOf(
                    createTestAdmin(email = "admin1@example.com"),
                    createTestAdmin(email = "admin2@example.com"),
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.findBySectorId(testSectorId) } returns admins

            val result = service.listAdmins(testSectorId, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.ListSuccess>()
            val listResult = result as AdminResult.ListSuccess
            listResult.admins.size shouldBe 2
            listResult.total shouldBe 2
        }

        @Test
        fun `should return CrossSectorOperation when listing admins in different sector`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                    sectorId = testSectorId,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief

            val result = service.listAdmins(otherSectorId, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.CrossSectorOperation>()
        }
    }

    @Nested
    inner class GetAdmin {
        @Test
        fun `should return admin when found and in same sector`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val targetAdmin =
                createTestAdmin(
                    id = sectorAdminId,
                    email = "target@example.com",
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.findById(sectorAdminId) } returns targetAdmin

            val result = service.getAdmin(sectorAdminId, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.Success>()
            (result as AdminResult.Success).admin.email shouldBe "target@example.com"
        }

        @Test
        fun `should return NotFound when admin does not exist`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.findById(sectorAdminId) } returns null

            val result = service.getAdmin(sectorAdminId, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.NotFound>()
        }
    }

    @Nested
    inner class UpdateAdmin {
        @Test
        fun `should update admin display name successfully`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val targetAdmin =
                createTestAdmin(
                    id = sectorAdminId,
                    displayName = "Old Name",
                )
            val command = UpdateAdminCommand(displayName = "New Name")

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.findById(sectorAdminId) } returns targetAdmin
            every { adminRepository.update(any()) } answers {
                firstArg<Admin>()
            }

            val result = service.updateAdmin(sectorAdminId, command, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.Success>()
            (result as AdminResult.Success).admin.displayName shouldBe "New Name"
            verify { adminRepository.update(match { it.displayName == "New Name" }) }
        }

        @Test
        fun `should allow admin to update own profile`() {
            val sectorAdmin =
                createTestAdmin(
                    id = sectorAdminId,
                    role = AdminRole.SECTOR_ADMIN,
                    displayName = "Old Name",
                )
            val command = UpdateAdminCommand(displayName = "New Name")

            every { adminRepository.findById(sectorAdminId) } returns sectorAdmin
            every { adminRepository.update(any()) } answers {
                firstArg<Admin>()
            }

            val result = service.updateAdmin(sectorAdminId, command, sectorAdminId)

            result.shouldBeInstanceOf<AdminResult.Success>()
        }

        @Test
        fun `should return InsufficientRoleToManage when sector admin tries to update peer`() {
            val sectorAdmin1 =
                createTestAdmin(
                    id = sectorAdminId,
                    role = AdminRole.SECTOR_ADMIN,
                )
            val sectorAdmin2 =
                createTestAdmin(
                    id = AdminId.generate(),
                    role = AdminRole.SECTOR_ADMIN,
                )
            val command = UpdateAdminCommand(displayName = "New Name")

            every { adminRepository.findById(sectorAdminId) } returns sectorAdmin1
            every { adminRepository.findById(sectorAdmin2.id) } returns sectorAdmin2

            val result = service.updateAdmin(sectorAdmin2.id, command, sectorAdminId)

            result.shouldBeInstanceOf<AdminResult.InsufficientRoleToManage>()
        }
    }

    @Nested
    inner class DeleteAdmin {
        @Test
        fun `should soft delete admin successfully`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val targetAdmin =
                createTestAdmin(
                    id = sectorAdminId,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.findById(sectorAdminId) } returns targetAdmin
            every { adminRepository.update(any()) } answers {
                firstArg<Admin>()
            }

            val result = service.deleteAdmin(sectorAdminId, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.Deleted>()
            verify {
                adminRepository.update(
                    match {
                        it.deletedAt == fixedInstant
                    },
                )
            }
        }

        @Test
        fun `should return CannotDeleteSelf when trying to delete own account`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief

            val result = service.deleteAdmin(sectorChiefId, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.CannotDeleteSelf>()
        }

        @Test
        fun `should return InsufficientRoleToManage when sector chief tries to delete sector chief`() {
            val sectorChief1 =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )
            val sectorChief2 =
                createTestAdmin(
                    id = AdminId.generate(),
                    role = AdminRole.SECTOR_CHIEF,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief1
            every { adminRepository.findById(sectorChief2.id) } returns sectorChief2

            val result = service.deleteAdmin(sectorChief2.id, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.InsufficientRoleToManage>()
        }

        @Test
        fun `should return NotFound when admin does not exist`() {
            val sectorChief =
                createTestAdmin(
                    id = sectorChiefId,
                    role = AdminRole.SECTOR_CHIEF,
                )

            every { adminRepository.findById(sectorChiefId) } returns sectorChief
            every { adminRepository.findById(sectorAdminId) } returns null

            val result = service.deleteAdmin(sectorAdminId, sectorChiefId)

            result.shouldBeInstanceOf<AdminResult.NotFound>()
        }
    }
}
