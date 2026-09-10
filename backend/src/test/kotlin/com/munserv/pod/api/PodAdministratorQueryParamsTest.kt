package com.munserv.pod.api

import com.munserv.admin.domain.AdminListQuery
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.AdminSort
import com.munserv.admin.domain.AdminSortColumn
import com.munserv.admin.domain.SortDirection
import com.munserv.shared.types.WardId
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import org.junit.jupiter.api.Test

class PodAdministratorQueryParamsTest {
    private fun params(
        sort: String? = null,
        q: String? = null,
        roles: List<String>? = null,
        wardId: String? = null,
    ) = PodAdministratorQueryParams(sort, q, roles, wardId)

    @Test
    fun `should return the default query when nothing is given`() {
        val result = params().toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Parsed>()
        (result as PodAdministratorQueryResult.Parsed).query shouldBe AdminListQuery.DEFAULT
    }

    @Test
    fun `should parse every sort column`() {
        AdminSortColumn.entries.forEach { column ->
            val result = params(sort = "${column.wireValue}:asc").toQuery()

            result.shouldBeInstanceOf<PodAdministratorQueryResult.Parsed>()
            (result as PodAdministratorQueryResult.Parsed).query.sort shouldBe AdminSort(column, SortDirection.ASC)
        }
    }

    @Test
    fun `should parse both directions`() {
        val asc = params(sort = "email:asc").toQuery() as PodAdministratorQueryResult.Parsed
        val desc = params(sort = "email:desc").toQuery() as PodAdministratorQueryResult.Parsed

        asc.query.sort.direction shouldBe SortDirection.ASC
        desc.query.sort.direction shouldBe SortDirection.DESC
    }

    @Test
    fun `should reject a sort without a direction`() {
        val result = params(sort = "displayName").toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Invalid>()
        (result as PodAdministratorQueryResult.Invalid).code shouldBe "invalid_sort"
    }

    @Test
    fun `should reject an unknown sort column`() {
        val result = params(sort = "assignedTo:asc").toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Invalid>()
        (result as PodAdministratorQueryResult.Invalid).code shouldBe "invalid_sort"
    }

    @Test
    fun `should reject an unknown direction`() {
        val result = params(sort = "email:sideways").toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Invalid>()
        (result as PodAdministratorQueryResult.Invalid).code shouldBe "invalid_sort"
    }

    @Test
    fun `should parse repeated roles`() {
        val result = params(roles = listOf("ward_admin", "ward_chief")).toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Parsed>()
        (result as PodAdministratorQueryResult.Parsed).query.roles shouldBe
            setOf(AdminRole.WARD_ADMIN, AdminRole.WARD_CHIEF)
    }

    @Test
    fun `should reject an unknown role`() {
        val result = params(roles = listOf("super_user")).toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Invalid>()
        (result as PodAdministratorQueryResult.Invalid).code shouldBe "invalid_role"
    }

    @Test
    fun `should reject a ward id that is not a uuid`() {
        val result = params(wardId = "not-a-uuid").toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Invalid>()
        (result as PodAdministratorQueryResult.Invalid).code shouldBe "invalid_ward_id"
    }

    @Test
    fun `should treat a blank search as absent`() {
        val result = params(q = "   ").toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Parsed>()
        (result as PodAdministratorQueryResult.Parsed).query.search shouldBe null
    }

    @Test
    fun `should parse a valid ward id`() {
        val wardId = "550e8400-e29b-41d4-a716-446655440030"
        val result = params(wardId = wardId).toQuery()

        result.shouldBeInstanceOf<PodAdministratorQueryResult.Parsed>()
        (result as PodAdministratorQueryResult.Parsed).query.wardId shouldBe WardId.fromString(wardId)
    }
}
