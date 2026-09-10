package com.munserv.pod.api

import com.munserv.admin.domain.AdminListQuery
import com.munserv.admin.domain.AdminRole
import com.munserv.admin.domain.AdminSort
import com.munserv.admin.domain.AdminSortColumn
import com.munserv.admin.domain.SortDirection
import com.munserv.shared.types.WardId
import java.util.UUID

/**
 * Raw query parameters for GET /pod/administrators, before validation.
 * Parsing lives here, not in the controller.
 */
data class PodAdministratorQueryParams(
    val sort: String?,
    val q: String?,
    val roles: List<String>?,
    val wardId: String?,
) {
    fun toQuery(): PodAdministratorQueryResult {
        val parsedSort = parseSort(sort) ?: return invalidSort(sort)
        val parsedRoles = parseRoles(roles) ?: return invalidRole()

        if (!wardId.isNullOrBlank() && runCatching { UUID.fromString(wardId) }.isFailure) {
            return invalidWardId(wardId)
        }
        val parsedWardId = wardId?.takeIf { it.isNotBlank() }?.let { WardId(UUID.fromString(it)) }

        return PodAdministratorQueryResult.Parsed(
            AdminListQuery(
                search = q?.trim()?.takeIf { it.isNotEmpty() },
                roles = parsedRoles,
                wardId = parsedWardId,
                sort = parsedSort,
            ),
        )
    }

    private fun parseSort(value: String?): AdminSort? {
        if (value.isNullOrBlank()) return AdminListQuery.DEFAULT_SORT

        val parts = value.split(":")
        if (parts.size != 2) return null

        val column = AdminSortColumn.fromWireValue(parts[0]) ?: return null
        val direction = SortDirection.fromWireValue(parts[1]) ?: return null
        return AdminSort(column, direction)
    }

    private fun parseRoles(values: List<String>?): Set<AdminRole>? {
        if (values.isNullOrEmpty()) return emptySet()

        val parsed = mutableSetOf<AdminRole>()
        for (value in values) {
            parsed += AdminRole.fromDbValueOrNull(value) ?: return null
        }
        return parsed
    }

    private fun invalidSort(value: String?): PodAdministratorQueryResult.Invalid =
        PodAdministratorQueryResult.Invalid(
            "invalid_sort",
            "Invalid sort '$value'. Use <column>:<asc|desc> with column one of email, displayName, role, createdAt",
        )

    private fun invalidRole(): PodAdministratorQueryResult.Invalid =
        PodAdministratorQueryResult.Invalid(
            "invalid_role",
            "Invalid role. Use one of ${AdminRole.entries.joinToString(", ") { it.toDbValue() }}",
        )

    private fun invalidWardId(value: String?): PodAdministratorQueryResult.Invalid =
        PodAdministratorQueryResult.Invalid(
            "invalid_ward_id",
            "Invalid wardId '$value'. Must be a UUID.",
        )
}

/**
 * Result of parsing [PodAdministratorQueryParams].
 */
sealed interface PodAdministratorQueryResult {
    data class Parsed(
        val query: AdminListQuery,
    ) : PodAdministratorQueryResult

    data class Invalid(
        val code: String,
        val message: String,
    ) : PodAdministratorQueryResult
}
