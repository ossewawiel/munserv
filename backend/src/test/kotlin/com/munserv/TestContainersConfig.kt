package com.munserv

import org.springframework.boot.test.context.TestConfiguration
import org.springframework.boot.testcontainers.service.connection.ServiceConnection
import org.springframework.context.annotation.Bean
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.wait.strategy.Wait
import org.testcontainers.utility.DockerImageName
import java.time.Duration

/**
 * TestContainers configuration for integration tests.
 * Uses PostGIS-enabled PostgreSQL container.
 */
@TestConfiguration(proxyBeanMethods = false)
class TestContainersConfig {
    companion object {
        private val postgisImage =
            DockerImageName
                .parse("postgis/postgis:15-3.3")
                .asCompatibleSubstituteFor("postgres")
    }

    @Bean
    @ServiceConnection
    fun postgresContainer(): PostgreSQLContainer<*> =
        PostgreSQLContainer(postgisImage).apply {
            withDatabaseName("testdb")
            withUsername("test")
            withPassword("test")
            withStartupTimeout(Duration.ofMinutes(3))
            waitingFor(Wait.forListeningPort())
        }
}
