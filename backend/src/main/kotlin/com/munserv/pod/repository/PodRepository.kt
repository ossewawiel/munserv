package com.munserv.pod.repository

import com.munserv.pod.domain.Pod
import com.munserv.shared.types.PodId

/**
 * Repository interface for Pod aggregate.
 * Provides domain-level data access operations.
 */
interface PodRepository {
    /**
     * Find a pod by its ID.
     */
    fun findById(id: PodId): Pod?

    /**
     * Check if a pod exists.
     */
    fun existsById(id: PodId): Boolean

    /**
     * Save a pod (create or update).
     */
    fun save(pod: Pod): Pod
}
