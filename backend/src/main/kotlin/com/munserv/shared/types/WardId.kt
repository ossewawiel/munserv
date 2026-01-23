package com.munserv.shared.types

import java.util.UUID

/**
 * Type-safe wrapper for Ward identifiers.
 * Prevents accidentally passing sector/pod/member IDs where ward IDs are expected.
 */
@JvmInline
value class WardId(val value: UUID) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): WardId = WardId(UUID.fromString(value))

        fun generate(): WardId = WardId(UUID.randomUUID())
    }
}
