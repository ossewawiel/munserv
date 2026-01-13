package com.munserv.shared.types

import java.util.UUID

/**
 * Type-safe wrapper for Pod identifiers.
 * Prevents accidentally passing sector/member IDs where pod IDs are expected.
 */
@JvmInline
value class PodId(val value: UUID) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): PodId = PodId(UUID.fromString(value))

        fun generate(): PodId = PodId(UUID.randomUUID())
    }
}
