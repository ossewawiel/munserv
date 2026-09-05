package com.munserv.support.domain

import java.util.UUID

/**
 * Type-safe wrapper for Support Grant IDs.
 * Prevents accidentally mixing support grant IDs with other UUID types.
 */
@JvmInline
value class SupportGrantId(
    val value: UUID,
) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): SupportGrantId = SupportGrantId(UUID.fromString(value))

        fun generate(): SupportGrantId = SupportGrantId(UUID.randomUUID())
    }
}
