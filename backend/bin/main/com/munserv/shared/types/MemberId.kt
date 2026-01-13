package com.munserv.shared.types

import java.util.UUID

/**
 * Type-safe wrapper for Member IDs.
 * Prevents accidentally mixing member IDs with other UUID types.
 */
@JvmInline
value class MemberId(val value: UUID) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): MemberId = MemberId(UUID.fromString(value))

        fun generate(): MemberId = MemberId(UUID.randomUUID())
    }
}
