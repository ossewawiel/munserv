package com.munserv.admin.domain

import com.munserv.shared.types.AdminId
import com.munserv.shared.types.WardId
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Test
import java.time.Instant

class AdminListQueryTest {
    private val wardA = WardId.generate()
    private val wardB = WardId.generate()

    private fun admin(
        email: String = "admin@example.com",
        displayName: String = "Admin",
        role: AdminRole = AdminRole.SECTOR_ADMIN,
        createdAt: Instant = Instant.parse("2026-01-01T00:00:00Z"),
        wardId: WardId? = null,
    ) = Admin(
        id = AdminId.generate(),
        wardId = wardId,
        email = email,
        displayName = displayName,
        role = role,
        createdAt = createdAt,
        updatedAt = createdAt,
    )

    @Test
    fun `should return every admin when the query is default`() {
        val admins = listOf(admin(email = "a@example.com"), admin(email = "b@example.com"))

        val result = AdminListQuery.DEFAULT.applyTo(admins)

        result shouldBe admins
    }

    @Test
    fun `should sort by created date ascending by default`() {
        val older = admin(email = "older@example.com", createdAt = Instant.parse("2026-01-01T00:00:00Z"))
        val newer = admin(email = "newer@example.com", createdAt = Instant.parse("2026-02-01T00:00:00Z"))

        val result = AdminListQuery.DEFAULT.applyTo(listOf(newer, older))

        result shouldBe listOf(older, newer)
    }

    @Test
    fun `should sort by display name ignoring case`() {
        val zeta = admin(email = "zeta@example.com", displayName = "zeta")
        val alpha = admin(email = "alpha@example.com", displayName = "Alpha")

        val query = AdminListQuery(sort = AdminSort(AdminSortColumn.DISPLAY_NAME, SortDirection.ASC))
        val result = query.applyTo(listOf(zeta, alpha))

        result shouldBe listOf(alpha, zeta)
    }

    @Test
    fun `should sort by role hierarchy from lowest to highest`() {
        val podChief = admin(email = "chief@example.com", role = AdminRole.POD_CHIEF)
        val sectorAdmin = admin(email = "sector@example.com", role = AdminRole.SECTOR_ADMIN)

        val query = AdminListQuery(sort = AdminSort(AdminSortColumn.ROLE, SortDirection.ASC))
        val result = query.applyTo(listOf(podChief, sectorAdmin))

        result shouldBe listOf(sectorAdmin, podChief)
    }

    @Test
    fun `should reverse the order when the direction is desc`() {
        val older = admin(email = "older@example.com", createdAt = Instant.parse("2026-01-01T00:00:00Z"))
        val newer = admin(email = "newer@example.com", createdAt = Instant.parse("2026-02-01T00:00:00Z"))

        val query = AdminListQuery(sort = AdminSort(AdminSortColumn.CREATED_AT, SortDirection.DESC))
        val result = query.applyTo(listOf(older, newer))

        result shouldBe listOf(newer, older)
    }

    @Test
    fun `should match the search term in the email`() {
        val match = admin(email = "khumalo@example.com")
        val noMatch = admin(email = "other@example.com")

        val query = AdminListQuery(search = "khumalo")
        val result = query.applyTo(listOf(match, noMatch))

        result shouldBe listOf(match)
    }

    @Test
    fun `should match the search term in the display name ignoring case`() {
        val match = admin(email = "a@example.com", displayName = "Sipho Khumalo")
        val noMatch = admin(email = "b@example.com", displayName = "Other Name")

        val query = AdminListQuery(search = "KHUMALO")
        val result = query.applyTo(listOf(match, noMatch))

        result shouldBe listOf(match)
    }

    @Test
    fun `should ignore a blank search term`() {
        val admins = listOf(admin(email = "a@example.com"), admin(email = "b@example.com"))

        val query = AdminListQuery(search = "   ")
        val result = query.applyTo(admins)

        result shouldBe admins
    }

    @Test
    fun `should keep only the given roles`() {
        val wardAdmin = admin(email = "ward@example.com", role = AdminRole.WARD_ADMIN)
        val sectorAdmin = admin(email = "sector@example.com", role = AdminRole.SECTOR_ADMIN)

        val query = AdminListQuery(roles = setOf(AdminRole.WARD_ADMIN))
        val result = query.applyTo(listOf(wardAdmin, sectorAdmin))

        result shouldBe listOf(wardAdmin)
    }

    @Test
    fun `should keep only admins in the given ward`() {
        val inWard = admin(email = "in@example.com", wardId = wardA)
        val outOfWard = admin(email = "out@example.com", wardId = wardB)

        val query = AdminListQuery(wardId = wardA)
        val result = query.applyTo(listOf(inWard, outOfWard))

        result shouldBe listOf(inWard)
    }

    @Test
    fun `should combine search role and ward with and`() {
        val matching = admin(email = "khumalo@example.com", role = AdminRole.WARD_ADMIN, wardId = wardA)
        val wrongRole = admin(email = "khumalo2@example.com", role = AdminRole.SECTOR_ADMIN, wardId = wardA)
        val wrongWard = admin(email = "khumalo3@example.com", role = AdminRole.WARD_ADMIN, wardId = wardB)
        val wrongSearch = admin(email = "other@example.com", role = AdminRole.WARD_ADMIN, wardId = wardA)

        val query = AdminListQuery(search = "khumalo", roles = setOf(AdminRole.WARD_ADMIN), wardId = wardA)
        val result = query.applyTo(listOf(matching, wrongRole, wrongWard, wrongSearch))

        result shouldBe listOf(matching)
    }
}
