package com.munserv.admin.domain

import com.munserv.shared.types.WardId

/**
 * Sort column for the pod administrator list.
 * Values are the response field names (camelCase), because they name JSON fields.
 */
enum class AdminSortColumn(
    val wireValue: String,
) {
    EMAIL("email"),
    DISPLAY_NAME("displayName"),
    ROLE("role"),
    CREATED_AT("createdAt"),
    ;

    companion object {
        fun fromWireValue(value: String): AdminSortColumn? = entries.find { it.wireValue == value }
    }
}

/**
 * Sort direction for the pod administrator list.
 */
enum class SortDirection(
    val wireValue: String,
) {
    ASC("asc"),
    DESC("desc"),
    ;

    companion object {
        fun fromWireValue(value: String): SortDirection? = entries.find { it.wireValue == value }
    }
}

/**
 * A sort for the pod administrator list: a column and a direction.
 */
data class AdminSort(
    val column: AdminSortColumn,
    val direction: SortDirection,
)

/**
 * Query over the pod administrator list: search, role and ward filters, and a sort.
 * Pure domain, no Spring.
 */
data class AdminListQuery(
    val search: String? = null,
    val roles: Set<AdminRole> = emptySet(),
    val wardId: WardId? = null,
    val sort: AdminSort = DEFAULT_SORT,
) {
    companion object {
        val DEFAULT_SORT = AdminSort(AdminSortColumn.CREATED_AT, SortDirection.ASC)
        val DEFAULT = AdminListQuery()
    }
}

/**
 * Applies this query to a list of admins: filters by search, roles and ward, then sorts.
 * Does not mutate the input list.
 */
fun AdminListQuery.applyTo(admins: List<Admin>): List<Admin> {
    val term = search?.trim()?.takeIf { it.isNotEmpty() }

    val filtered =
        admins.filter { admin ->
            val matchesSearch =
                term == null ||
                    admin.email.contains(term, ignoreCase = true) ||
                    admin.displayName.contains(term, ignoreCase = true)
            val matchesRoles = roles.isEmpty() || admin.role in roles
            val matchesWard = wardId == null || admin.wardId == wardId
            matchesSearch && matchesRoles && matchesWard
        }

    val comparator =
        when (sort.column) {
            AdminSortColumn.EMAIL -> compareBy(String.CASE_INSENSITIVE_ORDER) { admin: Admin -> admin.email }
            AdminSortColumn.DISPLAY_NAME -> compareBy(String.CASE_INSENSITIVE_ORDER) { admin: Admin -> admin.displayName }
            AdminSortColumn.ROLE -> compareBy { admin: Admin -> admin.role }
            AdminSortColumn.CREATED_AT -> compareBy { admin: Admin -> admin.createdAt }
        }

    val ordered = filtered.sortedWith(comparator)
    return if (sort.direction == SortDirection.DESC) ordered.reversed() else ordered
}
