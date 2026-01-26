package com.munserv.bootstrap.config

import org.springframework.boot.context.properties.ConfigurationProperties

/**
 * Configuration properties for super user bootstrap access.
 *
 * Used to configure the super user who can create the first Pod Chief
 * on a fresh pod deployment. After Pod Chief completes onboarding,
 * the super user loses access.
 *
 * SECURITY:
 * - enabled defaults to false (must explicitly enable)
 * - Credentials must be set via environment variables
 * - Never log credentials
 *
 * Environment variables:
 * - BOOTSTRAP_SUPER_USER_ENABLED
 * - SUPER_USER_EMAIL
 * - SUPER_USER_PASSWORD
 */
@ConfigurationProperties(prefix = "bootstrap.super-user")
data class BootstrapConfig(
    /** Whether super user bootstrap is enabled */
    val enabled: Boolean = false,
    /** Super user email address for authentication */
    val email: String? = null,
    /** Super user password */
    val password: String? = null,
) {
    /**
     * Check if super user is properly configured.
     * Returns true only if enabled and both credentials are set.
     */
    fun isConfigured(): Boolean = enabled && !email.isNullOrBlank() && !password.isNullOrBlank()
}
