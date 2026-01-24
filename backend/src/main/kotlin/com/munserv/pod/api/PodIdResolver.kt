package com.munserv.pod.api

import com.munserv.admin.repository.AdminRepository
import com.munserv.shared.types.AdminId
import com.munserv.shared.types.PodId
import org.springframework.stereotype.Component

/**
 * Resolves the pod ID for an authenticated admin.
 * Looks up the admin's pod assignment from the admin repository.
 */
@Component
class PodIdResolver(
    private val adminRepository: AdminRepository,
) {
    /**
     * Resolve the pod ID for the given admin.
     * Returns null if the admin doesn't exist or doesn't have a pod assigned.
     */
    fun resolvePodId(adminId: AdminId): PodId? {
        val admin = adminRepository.findById(adminId) ?: return null
        return admin.podId
    }
}
