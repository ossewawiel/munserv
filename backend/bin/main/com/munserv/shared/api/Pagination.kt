package com.munserv.shared.api

import io.swagger.v3.oas.annotations.media.Schema
import kotlin.math.ceil

/**
 * Pagination metadata for list responses.
 */
@Schema(description = "Pagination information")
data class Pagination(
    @Schema(description = "Current page number (1-based)", example = "1")
    val page: Int,
    @Schema(description = "Items per page", example = "20")
    val limit: Int,
    @Schema(description = "Total number of items", example = "100")
    val totalItems: Int,
    @Schema(description = "Total number of pages", example = "5")
    val totalPages: Int,
)

/**
 * Result of paginating a list.
 */
data class PaginatedResult<T>(
    val items: List<T>,
    val pagination: Pagination,
)

/**
 * Paginate a list with the given page and limit parameters.
 *
 * @param page The page number (1-based). Values < 1 are coerced to 1.
 * @param limit The maximum number of items per page. Must be > 0.
 * @return A PaginatedResult containing the items for the requested page and pagination metadata.
 */
fun <T> List<T>.paginate(
    page: Int,
    limit: Int,
): PaginatedResult<T> {
    require(limit > 0) { "Limit must be positive" }

    val totalItems = this.size
    val totalPages = if (totalItems == 0) 1 else ceil(totalItems.toDouble() / limit).toInt()
    val validPage = page.coerceIn(1, totalPages)

    val startIndex = (validPage - 1) * limit
    val endIndex = minOf(startIndex + limit, totalItems)
    val items = if (startIndex < totalItems) this.subList(startIndex, endIndex) else emptyList()

    return PaginatedResult(
        items = items,
        pagination =
            Pagination(
                page = validPage,
                limit = limit,
                totalItems = totalItems,
                totalPages = totalPages,
            ),
    )
}

/**
 * Extension to convert Pagination to issues module PaginationInfo for backward compatibility.
 */
fun Pagination.toPaginationInfo() =
    com.munserv.issues.api.PaginationInfo(
        page = page,
        limit = limit,
        totalItems = totalItems,
        totalPages = totalPages,
    )
