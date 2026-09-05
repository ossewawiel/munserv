package com.munserv.support.repository

import com.munserv.shared.types.PodId
import com.munserv.support.domain.SupportGrant
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.domain.SupportGrantStatus
import java.time.Instant

/**
 * Domain repository interface for SupportGrant entities.
 * Implementations handle data access details.
 */
interface SupportGrantRepository {
    /**
     * Find a support grant by ID.
     */
    fun findById(id: SupportGrantId): SupportGrant?

    /**
     * Save (insert or update) a support grant.
     */
    fun save(grant: SupportGrant): SupportGrant

    /**
     * Find all support grants for a pod, newest first.
     */
    fun findByPodId(podId: PodId): List<SupportGrant>

    /**
     * Find all support grants for a pod with the given status, newest first.
     */
    fun findByPodIdAndStatus(
        podId: PodId,
        status: SupportGrantStatus,
    ): List<SupportGrant>

    /**
     * Find the active support grant for a pod, if any.
     */
    fun findActiveByPodId(podId: PodId): SupportGrant?

    /**
     * Find active support grants whose expiry has passed as of [now].
     */
    fun findExpiredActive(now: Instant): List<SupportGrant>
}
