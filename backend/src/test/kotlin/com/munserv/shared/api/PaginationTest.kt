package com.munserv.shared.api

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for Pagination and paginate extension function.
 */
class PaginationTest {
    @Nested
    inner class PaginationDataClass {
        @Test
        fun `Pagination should store all fields correctly`() {
            val pagination =
                Pagination(
                    page = 2,
                    limit = 10,
                    totalItems = 25,
                    totalPages = 3,
                )

            pagination.page shouldBe 2
            pagination.limit shouldBe 10
            pagination.totalItems shouldBe 25
            pagination.totalPages shouldBe 3
        }
    }

    @Nested
    inner class PaginatedResultDataClass {
        @Test
        fun `PaginatedResult should store items and pagination`() {
            val items = listOf("a", "b", "c")
            val pagination = Pagination(1, 10, 3, 1)
            val result = PaginatedResult(items, pagination)

            result.items shouldBe items
            result.pagination shouldBe pagination
        }
    }

    @Nested
    inner class PaginateExtensionFunction {
        @Test
        fun `paginate should return first page of items`() {
            val items = (1..25).toList()

            val result = items.paginate(page = 1, limit = 10)

            result.items shouldBe listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
            result.pagination.page shouldBe 1
            result.pagination.limit shouldBe 10
            result.pagination.totalItems shouldBe 25
            result.pagination.totalPages shouldBe 3
        }

        @Test
        fun `paginate should return second page of items`() {
            val items = (1..25).toList()

            val result = items.paginate(page = 2, limit = 10)

            result.items shouldBe listOf(11, 12, 13, 14, 15, 16, 17, 18, 19, 20)
            result.pagination.page shouldBe 2
        }

        @Test
        fun `paginate should return partial last page`() {
            val items = (1..25).toList()

            val result = items.paginate(page = 3, limit = 10)

            result.items shouldBe listOf(21, 22, 23, 24, 25)
            result.pagination.page shouldBe 3
            result.pagination.totalPages shouldBe 3
        }

        @Test
        fun `paginate should coerce page less than 1 to 1`() {
            val items = (1..25).toList()

            val result = items.paginate(page = 0, limit = 10)

            result.pagination.page shouldBe 1
            result.items shouldBe listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        }

        @Test
        fun `paginate should coerce page greater than total pages to last page`() {
            val items = (1..25).toList()

            val result = items.paginate(page = 100, limit = 10)

            result.pagination.page shouldBe 3
            result.items shouldBe listOf(21, 22, 23, 24, 25)
        }

        @Test
        fun `paginate should handle empty list`() {
            val items = emptyList<Int>()

            val result = items.paginate(page = 1, limit = 10)

            result.items shouldBe emptyList()
            result.pagination.page shouldBe 1
            result.pagination.totalItems shouldBe 0
            result.pagination.totalPages shouldBe 1
        }

        @Test
        fun `paginate should throw exception for non-positive limit`() {
            val items = listOf(1, 2, 3)

            shouldThrow<IllegalArgumentException> {
                items.paginate(page = 1, limit = 0)
            }
        }

        @Test
        fun `paginate should throw exception for negative limit`() {
            val items = listOf(1, 2, 3)

            shouldThrow<IllegalArgumentException> {
                items.paginate(page = 1, limit = -1)
            }
        }

        @Test
        fun `paginate should handle list exactly divisible by limit`() {
            val items = (1..20).toList()

            val result = items.paginate(page = 2, limit = 10)

            result.items shouldBe listOf(11, 12, 13, 14, 15, 16, 17, 18, 19, 20)
            result.pagination.totalPages shouldBe 2
        }

        @Test
        fun `paginate should handle single item list`() {
            val items = listOf("only")

            val result = items.paginate(page = 1, limit = 10)

            result.items shouldBe listOf("only")
            result.pagination.totalItems shouldBe 1
            result.pagination.totalPages shouldBe 1
        }

        @Test
        fun `paginate should handle limit of 1`() {
            val items = listOf("a", "b", "c")

            val result = items.paginate(page = 2, limit = 1)

            result.items shouldBe listOf("b")
            result.pagination.page shouldBe 2
            result.pagination.totalPages shouldBe 3
        }

        @Test
        fun `paginate should handle limit larger than list size`() {
            val items = listOf(1, 2, 3)

            val result = items.paginate(page = 1, limit = 100)

            result.items shouldBe listOf(1, 2, 3)
            result.pagination.page shouldBe 1
            result.pagination.totalItems shouldBe 3
            result.pagination.totalPages shouldBe 1
        }
    }

    @Nested
    inner class ToPaginationInfoExtension {
        @Test
        fun `toPaginationInfo should convert Pagination to PaginationInfo`() {
            val pagination =
                Pagination(
                    page = 2,
                    limit = 10,
                    totalItems = 25,
                    totalPages = 3,
                )

            val paginationInfo = pagination.toPaginationInfo()

            paginationInfo.page shouldBe 2
            paginationInfo.limit shouldBe 10
            paginationInfo.totalItems shouldBe 25
            paginationInfo.totalPages shouldBe 3
        }
    }
}
