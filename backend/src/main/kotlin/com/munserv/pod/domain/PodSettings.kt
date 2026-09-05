package com.munserv.pod.domain

import com.munserv.shared.types.PodId
import java.time.Instant

/**
 * Value object representing the configurable settings of a pod.
 * This is a read-only view of pod configuration for API responses.
 */
data class PodSettings(
    val podId: PodId,
    val name: String,
    val displayName: String,
    val logoUrl: String?,
    val updatedAt: Instant,
) {
    companion object {
        /**
         * Create PodSettings from a Pod domain entity.
         */
        fun fromPod(pod: Pod): PodSettings =
            PodSettings(
                podId = pod.id,
                name = pod.name,
                displayName = pod.displayName,
                logoUrl = pod.logoUrl,
                updatedAt = pod.updatedAt,
            )
    }
}
