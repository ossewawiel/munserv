package com.munserv.shared.email

import com.munserv.TestContainersConfig
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles

/**
 * Integration test to verify EmailService is properly configured and can be autowired.
 */
@SpringBootTest
@Import(TestContainersConfig::class)
@ActiveProfiles("test")
class EmailServiceIntegrationTest {
    @Autowired
    private lateinit var emailService: EmailService

    @Test
    fun `EmailService should be autowired successfully`() {
        emailService shouldNotBe null
    }
}
