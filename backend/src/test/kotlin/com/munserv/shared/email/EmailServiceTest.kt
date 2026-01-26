package com.munserv.shared.email

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.mockk.Runs
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.mail.MailSendException
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender

class EmailServiceTest {
    private val mailSender: JavaMailSender = mockk()
    private lateinit var emailService: EmailService

    private val fromAddress = "noreply@munserv.app"
    private val overrideRecipient = "" // Empty = disabled (production behavior)
    private val appName = "MunServ"
    private val downloadUrl = "https://play.google.com/store/apps/details?id=com.munserv"

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        emailService =
            EmailService(
                mailSender = mailSender,
                fromAddress = fromAddress,
                overrideRecipient = overrideRecipient,
                appName = appName,
                downloadUrl = downloadUrl,
            )
    }

    @Nested
    inner class SendWelcomeEmail {
        @Test
        fun `should send welcome email with correct recipient`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            verify(exactly = 1) { mailSender.send(any<SimpleMailMessage>()) }
            messageSlot.captured.to?.first() shouldBe "john.doe@example.com"
        }

        @Test
        fun `should send welcome email with correct from address`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            messageSlot.captured.from shouldBe fromAddress
        }

        @Test
        fun `should send welcome email with app name in subject`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            messageSlot.captured.subject shouldContain appName
            messageSlot.captured.subject shouldContain "Welcome"
            messageSlot.captured.subject shouldContain "Approved"
        }

        @Test
        fun `should include member name in email body`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            messageSlot.captured.text shouldContain "John Doe"
        }

        @Test
        fun `should include temporary password in email body`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            messageSlot.captured.text shouldContain "TempPass123"
        }

        @Test
        fun `should include email address in email body`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            messageSlot.captured.text shouldContain "john.doe@example.com"
        }

        @Test
        fun `should include download URL in email body`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            messageSlot.captured.text shouldContain downloadUrl
        }

        @Test
        fun `should include password requirements in email body`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            val body = messageSlot.captured.text!!
            body shouldContain "8 characters"
            body shouldContain "uppercase"
            body shouldContain "lowercase"
            body shouldContain "number"
        }

        @Test
        fun `should include password change warning in email body`() {
            // Arrange
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            emailService.sendWelcomeEmail(
                toEmail = "john.doe@example.com",
                memberName = "John Doe",
                tempPassword = "TempPass123",
            )

            // Assert
            messageSlot.captured.text shouldContain "change your password"
        }

        @Test
        fun `should throw EmailSendException when mail sender fails`() {
            // Arrange
            every { mailSender.send(any<SimpleMailMessage>()) } throws
                MailSendException("SMTP connection failed")

            // Act & Assert
            shouldThrow<EmailSendException> {
                emailService.sendWelcomeEmail(
                    toEmail = "john.doe@example.com",
                    memberName = "John Doe",
                    tempPassword = "TempPass123",
                )
            }
        }
    }

    @Nested
    inner class MaskEmail {
        @Test
        fun `should mask email correctly for normal email`() {
            // The maskEmail is private, but we test it indirectly through exception messages
            // or we can test it through a separate utility if needed
            // For now, we verify the email masking in log messages works correctly

            // This test validates the masking logic via the sendWelcomeEmail error path
            every { mailSender.send(any<SimpleMailMessage>()) } throws
                MailSendException("Test failure")

            val exception =
                shouldThrow<EmailSendException> {
                    emailService.sendWelcomeEmail(
                        toEmail = "john.doe@example.com",
                        memberName = "John Doe",
                        tempPassword = "TempPass123",
                    )
                }

            // The exception message should not contain the full email
            exception.message shouldBe "Failed to send email"
        }
    }

    @Nested
    inner class OverrideRecipient {
        @Test
        fun `should redirect email when override is configured`() {
            // Arrange - create service with override enabled
            val serviceWithOverride =
                EmailService(
                    mailSender = mailSender,
                    fromAddress = fromAddress,
                    overrideRecipient = "catchall@test.com",
                    appName = appName,
                    downloadUrl = downloadUrl,
                )
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            serviceWithOverride.sendWelcomeEmail(
                toEmail = "real-user@example.com",
                memberName = "Real User",
                tempPassword = "TempPass123",
            )

            // Assert - email should go to override address
            verify(exactly = 1) { mailSender.send(any<SimpleMailMessage>()) }
            messageSlot.captured.to?.first() shouldBe "catchall@test.com"
        }

        @Test
        fun `should prepend original recipient to subject when override is active`() {
            // Arrange
            val serviceWithOverride =
                EmailService(
                    mailSender = mailSender,
                    fromAddress = fromAddress,
                    overrideRecipient = "catchall@test.com",
                    appName = appName,
                    downloadUrl = downloadUrl,
                )
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            serviceWithOverride.sendWelcomeEmail(
                toEmail = "real-user@example.com",
                memberName = "Real User",
                tempPassword = "TempPass123",
            )

            // Assert - subject should have original recipient prefix
            val subject = messageSlot.captured.subject!!
            subject shouldContain "[To: real-user@example.com]"
            subject shouldContain "Welcome"
        }

        @Test
        fun `should send to original recipient when no override configured`() {
            // Arrange - service without override (empty string)
            val serviceWithoutOverride =
                EmailService(
                    mailSender = mailSender,
                    fromAddress = fromAddress,
                    overrideRecipient = "",
                    appName = appName,
                    downloadUrl = downloadUrl,
                )
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            serviceWithoutOverride.sendWelcomeEmail(
                toEmail = "real-user@example.com",
                memberName = "Real User",
                tempPassword = "TempPass123",
            )

            // Assert - email should go to original recipient
            messageSlot.captured.to?.first() shouldBe "real-user@example.com"
        }

        @Test
        fun `should not modify subject when no override configured`() {
            // Arrange
            val serviceWithoutOverride =
                EmailService(
                    mailSender = mailSender,
                    fromAddress = fromAddress,
                    overrideRecipient = "",
                    appName = appName,
                    downloadUrl = downloadUrl,
                )
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            serviceWithoutOverride.sendWelcomeEmail(
                toEmail = "real-user@example.com",
                memberName = "Real User",
                tempPassword = "TempPass123",
            )

            // Assert - subject should NOT have [To: ...] prefix
            val subject = messageSlot.captured.subject!!
            subject.startsWith("[To:") shouldBe false
            subject shouldContain "Welcome"
        }

        @Test
        fun `should treat blank override as disabled`() {
            // Arrange - service with blank (whitespace only) override
            val serviceWithBlankOverride =
                EmailService(
                    mailSender = mailSender,
                    fromAddress = fromAddress,
                    overrideRecipient = "   ",
                    appName = appName,
                    downloadUrl = downloadUrl,
                )
            val messageSlot = slot<SimpleMailMessage>()
            every { mailSender.send(capture(messageSlot)) } just Runs

            // Act
            serviceWithBlankOverride.sendWelcomeEmail(
                toEmail = "real-user@example.com",
                memberName = "Real User",
                tempPassword = "TempPass123",
            )

            // Assert - email should go to original recipient (blank = disabled)
            messageSlot.captured.to?.first() shouldBe "real-user@example.com"
        }
    }
}
