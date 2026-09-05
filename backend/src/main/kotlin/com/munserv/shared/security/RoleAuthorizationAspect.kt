package com.munserv.shared.security

import com.munserv.admin.domain.AdminRole
import com.munserv.admin.repository.AdminRepository
import com.munserv.shared.types.AdminId
import com.munserv.support.domain.SupportGrantId
import com.munserv.support.service.SupportAccessResult
import com.munserv.support.service.SupportAccessService
import org.aspectj.lang.ProceedingJoinPoint
import org.aspectj.lang.annotation.Around
import org.aspectj.lang.annotation.Aspect
import org.aspectj.lang.reflect.MethodSignature
import org.springframework.context.annotation.Lazy
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import java.util.UUID

/**
 * AOP aspect that enforces role-based access control for methods
 * annotated with @RequireRole.
 *
 * The aspect extracts the current user's ID from the Spring Security context,
 * looks up their admin record to get their role, and verifies they have
 * sufficient permissions to access the endpoint.
 */
@Aspect
@Component
class RoleAuthorizationAspect(
    private val adminRepository: AdminRepository,
    @Lazy private val supportAccessService: SupportAccessService,
) {
    companion object {
        private const val SUPPORT_GRANT_AUTHORITY = "ROLE_SUPPORT_GRANT"
    }

    /**
     * Intercepts method calls annotated with @RequireRole and verifies
     * the current user has the required role or higher.
     *
     * @throws AccessDeniedException if user lacks required role
     */
    @Around("@annotation(com.munserv.shared.security.RequireRole)")
    fun checkRole(joinPoint: ProceedingJoinPoint): Any? {
        val requiredRole = extractRequiredRole(joinPoint)
        val currentAdminRole = getCurrentAdminRole()

        if (currentAdminRole == null || !currentAdminRole.hasPermission(requiredRole)) {
            throw AccessDeniedException("Requires ${requiredRole.name} role or higher")
        }

        return joinPoint.proceed()
    }

    /**
     * Intercepts class-level @RequireRole annotations.
     */
    @Around("@within(com.munserv.shared.security.RequireRole)")
    fun checkClassRole(joinPoint: ProceedingJoinPoint): Any? {
        val targetClass = joinPoint.target.javaClass
        val requireRole =
            targetClass.getAnnotation(RequireRole::class.java)
                ?: throw IllegalStateException("@RequireRole annotation not found on class")

        val currentAdminRole = getCurrentAdminRole()

        if (currentAdminRole == null || !currentAdminRole.hasPermission(requireRole.role)) {
            throw AccessDeniedException("Requires ${requireRole.role.name} role or higher")
        }

        return joinPoint.proceed()
    }

    private fun extractRequiredRole(joinPoint: ProceedingJoinPoint): AdminRole {
        val signature = joinPoint.signature as MethodSignature
        val method = signature.method
        val requireRole =
            method.getAnnotation(RequireRole::class.java)
                ?: throw IllegalStateException("@RequireRole annotation not found")
        return requireRole.role
    }

    private fun getCurrentAdminRole(): AdminRole? {
        val authentication =
            SecurityContextHolder.getContext().authentication
                ?: return null

        val subject =
            authentication.principal as? String
                ?: return null

        if (authentication.authorities.any { it.authority == SUPPORT_GRANT_AUTHORITY }) {
            val grantId =
                try {
                    SupportGrantId(UUID.fromString(subject))
                } catch (e: IllegalArgumentException) {
                    return null
                }

            return when (val result = supportAccessService.currentGrant(grantId)) {
                is SupportAccessResult.Granted -> result.view.grant.grantedRole
                else -> null
            }
        }

        val adminId =
            try {
                AdminId(UUID.fromString(subject))
            } catch (e: IllegalArgumentException) {
                return null
            }

        val admin =
            adminRepository.findById(adminId)
                ?: return null

        return admin.role
    }
}
