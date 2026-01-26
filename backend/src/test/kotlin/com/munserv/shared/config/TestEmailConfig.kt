package com.munserv.shared.config

import com.munserv.shared.email.EmailService
import io.mockk.mockk
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Primary
import org.springframework.mail.javamail.JavaMailSender

/**
 * Test configuration that provides a mock EmailService.
 * This prevents actual emails from being sent during tests.
 */
@TestConfiguration
class TestEmailConfig {
    @Bean
    @Primary
    fun mockMailSender(): JavaMailSender = mockk(relaxed = true)

    @Bean
    @Primary
    fun mockEmailService(mailSender: JavaMailSender): EmailService =
        EmailService(
            mailSender = mailSender,
            fromAddress = "test@munserv.app",
            overrideRecipient = "test-catchall@munserv.local",
            appName = "MunServ Test",
            downloadUrl = "https://test.munserv.app/download",
            adminPortalUrl = "http://localhost:3000",
        )
}
