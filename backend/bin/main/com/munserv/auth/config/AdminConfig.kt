package com.munserv.auth.config

import org.springframework.boot.context.properties.ConfigurationProperties

/**
 * Configuration properties for MVP admin authentication.
 *
 * WARNING: This is for MVP development only.
 * TODO: Replace with proper admin table and authentication in production.
 *
 * Override these values via environment variables in non-local environments:
 * - ADMIN_EMAIL
 * - ADMIN_PASSWORD
 * - ADMIN_ID
 * - etc.
 */
@ConfigurationProperties(prefix = "admin")
data class AdminConfig(
    val email: String,
    val password: String,
    val id: String,
    val displayName: String,
    val sectorId: String,
    val role: String,
    val sectorName: String,
    val sectorCenterLat: Double,
    val sectorCenterLng: Double,
)
