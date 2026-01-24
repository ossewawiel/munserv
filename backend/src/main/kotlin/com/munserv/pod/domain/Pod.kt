package com.munserv.pod.domain

import com.munserv.shared.types.PodId
import java.time.Instant

/**
 * Domain entity representing a Pod (deployment instance).
 * A pod is an independent deployment with its own database and infrastructure.
 */
data class Pod(
    val id: PodId,
    val name: String,
    val displayName: String,
    val logoUrl: String?,
    val config: Map<String, Any>,
    val setupCompletedAt: Instant?,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    /**
     * Whether setup has been completed.
     */
    val isSetupComplete: Boolean get() = setupCompletedAt != null

    /**
     * Update the pod name and auto-generate display name.
     */
    fun withName(newName: String, now: Instant): Pod = copy(
        name = newName,
        displayName = displayNameFor(newName),
        updatedAt = now,
    )

    /**
     * Update the logo URL.
     */
    fun withLogoUrl(newLogoUrl: String?, now: Instant): Pod = copy(
        logoUrl = newLogoUrl,
        updatedAt = now,
    )

    /**
     * Mark setup as completed.
     */
    fun markSetupComplete(now: Instant): Pod = copy(
        setupCompletedAt = now,
        updatedAt = now,
    )

    companion object {
        /**
         * Generate display name from pod name.
         */
        fun displayNameFor(name: String): String = "Munserv Pod $name"
    }
}
