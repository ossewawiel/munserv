package com.munserv.bootstrap.config

import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.context.annotation.Profile
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Component

/**
 * Resets bootstrap state on startup for testing the Pod Chief onboarding flow.
 *
 * Only active when the 'reset-bootstrap' profile is enabled.
 *
 * Usage:
 *   ./gradlew bootRun --args='--spring.profiles.active=local,reset-bootstrap'
 *
 * Or in VS Code tasks:
 *   "./gradlew bootRun --args='--spring.profiles.active=local,reset-bootstrap'"
 *
 * WARNING: This deletes the Pod Chief admin. Only use in development!
 */
@Component
@Profile("reset-bootstrap")
class BootstrapResetRunner(
    private val jdbcTemplate: JdbcTemplate,
) : ApplicationRunner {
    private val logger = LoggerFactory.getLogger(javaClass)

    override fun run(args: ApplicationArguments) {
        logger.warn("╔════════════════════════════════════════════════════════════╗")
        logger.warn("║  RESET-BOOTSTRAP PROFILE ACTIVE                            ║")
        logger.warn("║  Deleting Pod Chief to enable bootstrap testing...         ║")
        logger.warn("╚════════════════════════════════════════════════════════════╝")

        val deleted =
            jdbcTemplate.update(
                "DELETE FROM admins WHERE role = CAST('pod_chief' AS admin_role)",
            )

        if (deleted > 0) {
            logger.warn("Deleted $deleted Pod Chief admin(s). Bootstrap flow is now available.")
        } else {
            logger.info("No Pod Chief found. Bootstrap flow already available.")
        }
    }
}
