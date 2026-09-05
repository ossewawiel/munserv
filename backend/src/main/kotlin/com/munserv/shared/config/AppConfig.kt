package com.munserv.shared.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.scheduling.annotation.EnableScheduling
import java.time.Clock

/**
 * Application-wide configuration beans.
 */
@Configuration
@EnableScheduling
class AppConfig {
    /**
     * Provides system clock for time-dependent operations.
     * Can be overridden in tests with a fixed clock.
     */
    @Bean
    fun clock(): Clock = Clock.systemUTC()
}
