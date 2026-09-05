package com.munserv.shared.types

import java.util.UUID

/**
 * Type-safe wrapper for Admin IDs.
 * Prevents accidentally mixing admin IDs with other UUID types.
 */
@JvmInline
value class AdminId(
    val value: UUID,
) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): AdminId = AdminId(UUID.fromString(value))

        fun generate(): AdminId = AdminId(UUID.randomUUID())
    }
}
