package com.munserv.support.service

import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component

/**
 * Scheduled job that expires stale support grants (active grants past their expiry).
 */
@Component
class SupportGrantExpiryJob(
    private val supportAccessService: SupportAccessService,
) {
    @Scheduled(fixedDelayString = "\${support-access.expiry-job-interval-ms:60000}")
    fun run() {
        supportAccessService.expireStaleGrants()
    }
}
