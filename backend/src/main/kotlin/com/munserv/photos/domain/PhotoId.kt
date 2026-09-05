package com.munserv.photos.domain

import java.util.UUID

/**
 * Type-safe wrapper for Photo IDs.
 * Prevents accidentally mixing photo IDs with other UUID types.
 */
@JvmInline
value class PhotoId(
    val value: UUID,
) {
    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): PhotoId = PhotoId(UUID.fromString(value))

        fun generate(): PhotoId = PhotoId(UUID.randomUUID())
    }
}
