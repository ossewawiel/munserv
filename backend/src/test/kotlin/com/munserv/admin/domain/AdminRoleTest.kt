package com.munserv.admin.domain

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class AdminRoleTest {
    @Nested
    inner class FromDbValue {
        @Test
        fun `should parse sector_admin`() {
            AdminRole.fromDbValue("sector_admin") shouldBe AdminRole.SECTOR_ADMIN
        }

        @Test
        fun `should parse sector_chief`() {
            AdminRole.fromDbValue("sector_chief") shouldBe AdminRole.SECTOR_CHIEF
        }

        @Test
        fun `should parse pod_admin`() {
            AdminRole.fromDbValue("pod_admin") shouldBe AdminRole.POD_ADMIN
        }

        @Test
        fun `should parse pod_chief`() {
            AdminRole.fromDbValue("pod_chief") shouldBe AdminRole.POD_CHIEF
        }

        @Test
        fun `should be case insensitive`() {
            AdminRole.fromDbValue("SECTOR_ADMIN") shouldBe AdminRole.SECTOR_ADMIN
            AdminRole.fromDbValue("Sector_Chief") shouldBe AdminRole.SECTOR_CHIEF
            AdminRole.fromDbValue("POD_ADMIN") shouldBe AdminRole.POD_ADMIN
        }

        @Test
        fun `should throw for unknown role`() {
            shouldThrow<IllegalArgumentException> {
                AdminRole.fromDbValue("unknown")
            }
        }
    }

    @Nested
    inner class ToDbValue {
        @Test
        fun `should return lowercase snake_case`() {
            AdminRole.SECTOR_ADMIN.toDbValue() shouldBe "sector_admin"
            AdminRole.SECTOR_CHIEF.toDbValue() shouldBe "sector_chief"
            AdminRole.POD_ADMIN.toDbValue() shouldBe "pod_admin"
            AdminRole.POD_CHIEF.toDbValue() shouldBe "pod_chief"
        }
    }

    @Nested
    inner class HasPermission {
        @Test
        fun `SECTOR_ADMIN has permission for SECTOR_ADMIN only`() {
            AdminRole.SECTOR_ADMIN.hasPermission(AdminRole.SECTOR_ADMIN) shouldBe true
            AdminRole.SECTOR_ADMIN.hasPermission(AdminRole.SECTOR_CHIEF) shouldBe false
            AdminRole.SECTOR_ADMIN.hasPermission(AdminRole.POD_ADMIN) shouldBe false
            AdminRole.SECTOR_ADMIN.hasPermission(AdminRole.POD_CHIEF) shouldBe false
        }

        @Test
        fun `SECTOR_CHIEF has permission for SECTOR_ADMIN and SECTOR_CHIEF`() {
            AdminRole.SECTOR_CHIEF.hasPermission(AdminRole.SECTOR_ADMIN) shouldBe true
            AdminRole.SECTOR_CHIEF.hasPermission(AdminRole.SECTOR_CHIEF) shouldBe true
            AdminRole.SECTOR_CHIEF.hasPermission(AdminRole.POD_ADMIN) shouldBe false
            AdminRole.SECTOR_CHIEF.hasPermission(AdminRole.POD_CHIEF) shouldBe false
        }

        @Test
        fun `POD_ADMIN has permission for SECTOR_ADMIN, SECTOR_CHIEF, and POD_ADMIN`() {
            AdminRole.POD_ADMIN.hasPermission(AdminRole.SECTOR_ADMIN) shouldBe true
            AdminRole.POD_ADMIN.hasPermission(AdminRole.SECTOR_CHIEF) shouldBe true
            AdminRole.POD_ADMIN.hasPermission(AdminRole.POD_ADMIN) shouldBe true
            AdminRole.POD_ADMIN.hasPermission(AdminRole.POD_CHIEF) shouldBe false
        }

        @Test
        fun `POD_CHIEF has permission for all roles`() {
            AdminRole.POD_CHIEF.hasPermission(AdminRole.SECTOR_ADMIN) shouldBe true
            AdminRole.POD_CHIEF.hasPermission(AdminRole.SECTOR_CHIEF) shouldBe true
            AdminRole.POD_CHIEF.hasPermission(AdminRole.POD_ADMIN) shouldBe true
            AdminRole.POD_CHIEF.hasPermission(AdminRole.POD_CHIEF) shouldBe true
        }
    }

    @Nested
    inner class CanManage {
        @Test
        fun `SECTOR_ADMIN cannot manage any role`() {
            AdminRole.SECTOR_ADMIN.canManage(AdminRole.SECTOR_ADMIN) shouldBe false
            AdminRole.SECTOR_ADMIN.canManage(AdminRole.SECTOR_CHIEF) shouldBe false
            AdminRole.SECTOR_ADMIN.canManage(AdminRole.POD_ADMIN) shouldBe false
            AdminRole.SECTOR_ADMIN.canManage(AdminRole.POD_CHIEF) shouldBe false
        }

        @Test
        fun `SECTOR_CHIEF can manage SECTOR_ADMIN only`() {
            AdminRole.SECTOR_CHIEF.canManage(AdminRole.SECTOR_ADMIN) shouldBe true
            AdminRole.SECTOR_CHIEF.canManage(AdminRole.SECTOR_CHIEF) shouldBe false
            AdminRole.SECTOR_CHIEF.canManage(AdminRole.POD_ADMIN) shouldBe false
            AdminRole.SECTOR_CHIEF.canManage(AdminRole.POD_CHIEF) shouldBe false
        }

        @Test
        fun `POD_ADMIN can manage SECTOR_ADMIN and SECTOR_CHIEF`() {
            AdminRole.POD_ADMIN.canManage(AdminRole.SECTOR_ADMIN) shouldBe true
            AdminRole.POD_ADMIN.canManage(AdminRole.SECTOR_CHIEF) shouldBe true
            AdminRole.POD_ADMIN.canManage(AdminRole.POD_ADMIN) shouldBe false
            AdminRole.POD_ADMIN.canManage(AdminRole.POD_CHIEF) shouldBe false
        }

        @Test
        fun `POD_CHIEF can manage all except POD_CHIEF`() {
            AdminRole.POD_CHIEF.canManage(AdminRole.SECTOR_ADMIN) shouldBe true
            AdminRole.POD_CHIEF.canManage(AdminRole.SECTOR_CHIEF) shouldBe true
            AdminRole.POD_CHIEF.canManage(AdminRole.POD_ADMIN) shouldBe true
            AdminRole.POD_CHIEF.canManage(AdminRole.POD_CHIEF) shouldBe false
        }
    }

    @Nested
    inner class RoleHierarchy {
        @Test
        fun `roles should be ordered from lowest to highest`() {
            AdminRole.SECTOR_ADMIN.ordinal shouldBe 0
            AdminRole.SECTOR_CHIEF.ordinal shouldBe 1
            AdminRole.POD_ADMIN.ordinal shouldBe 2
            AdminRole.POD_CHIEF.ordinal shouldBe 3
        }
    }
}
