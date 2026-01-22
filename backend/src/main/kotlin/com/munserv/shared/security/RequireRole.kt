package com.munserv.shared.security

import com.munserv.admin.domain.AdminRole

/**
 * Annotation to require a minimum admin role for accessing an endpoint.
 * The annotated method will only be accessible to admins with the specified
 * role or higher (based on role hierarchy).
 *
 * Usage:
 * ```
 * @RequireRole(AdminRole.SECTOR_CHIEF)
 * fun updateSettings() { ... }
 * ```
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
@MustBeDocumented
annotation class RequireRole(
    val role: AdminRole,
)
