package com.munserv.shared.email

import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.stereotype.Service

/**
 * Service for sending emails via SMTP.
 */
@Service
class EmailService(
    private val mailSender: JavaMailSender,
    @Value("\${munserv.email.from:noreply@munserv.app}")
    private val fromAddress: String,
    @Value("\${munserv.app.name:MunServ}")
    private val appName: String,
    @Value("\${munserv.app.download-url:https://munserv.app/download}")
    private val downloadUrl: String,
) {
    private val log = LoggerFactory.getLogger(EmailService::class.java)

    /**
     * Sends welcome email to newly approved member.
     * Includes temporary password and app download link.
     */
    fun sendWelcomeEmail(
        toEmail: String,
        memberName: String,
        tempPassword: String,
    ) {
        val subject = "Welcome to $appName - Your Account is Approved!"

        val body =
            """
            |Hello $memberName,
            |
            |Great news! Your registration with $appName has been approved.
            |
            |You can now download the mobile app and log in with the following credentials:
            |
            |Email: $toEmail
            |Temporary Password: $tempPassword
            |
            |IMPORTANT: You will be required to change your password on first login.
            |
            |Download the app:
            |$downloadUrl
            |
            |Password Requirements:
            |- At least 8 characters
            |- At least one uppercase letter (A-Z)
            |- At least one lowercase letter (a-z)
            |- At least one number (0-9)
            |
            |If you did not register for $appName, please ignore this email.
            |
            |Thank you for joining our community!
            |
            |The $appName Team
            """.trimMargin()

        sendEmail(toEmail, subject, body)
    }

    /**
     * Sends a simple email.
     */
    private fun sendEmail(
        to: String,
        subject: String,
        body: String,
    ) {
        try {
            val message =
                SimpleMailMessage().apply {
                    setFrom(fromAddress)
                    setTo(to)
                    setSubject(subject)
                    setText(body)
                }
            mailSender.send(message)
            log.info("Email sent to: ${maskEmail(to)}")
        } catch (e: Exception) {
            log.error("Failed to send email to: ${maskEmail(to)}", e)
            throw EmailSendException("Failed to send email", e)
        }
    }

    private fun maskEmail(email: String): String {
        val parts = email.split("@")
        if (parts.size != 2) return "***"
        val local = parts[0]
        val maskedLocal = if (local.length <= 2) "*" else "${local.first()}***${local.last()}"
        return "$maskedLocal@${parts[1]}"
    }
}

/**
 * Exception thrown when email sending fails.
 */
class EmailSendException(message: String, cause: Throwable) : RuntimeException(message, cause)
