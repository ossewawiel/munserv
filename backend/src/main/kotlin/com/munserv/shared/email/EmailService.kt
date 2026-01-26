package com.munserv.shared.email

import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.stereotype.Service

/**
 * Service for sending emails via SMTP.
 *
 * Supports an override-recipient setting for dev/test environments that redirects
 * all emails to a single address, preventing accidental emails to real users.
 */
@Service
class EmailService(
    private val mailSender: JavaMailSender,
    @Value("\${munserv.email.from:noreply@munserv.app}")
    private val fromAddress: String,
    @Value("\${munserv.email.override-recipient:}")
    private val overrideRecipient: String,
    @Value("\${munserv.app.name:MunServ}")
    private val appName: String,
    @Value("\${munserv.app.download-url:https://munserv.app/download}")
    private val downloadUrl: String,
    @Value("\${munserv.app.admin-portal-url:http://localhost:3000}")
    private val adminPortalUrl: String,
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
        val originalSubject = "Welcome to $appName - Your Account is Approved!"

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

        val effectiveRecipient = resolveRecipient(toEmail)
        val effectiveSubject = resolveSubject(originalSubject, toEmail)
        sendEmail(effectiveRecipient, effectiveSubject, body)
    }

    /**
     * Sends welcome email to newly created Pod Chief.
     * Includes temporary password and admin portal instructions.
     */
    fun sendPodChiefWelcomeEmail(
        toEmail: String,
        displayName: String,
        tempPassword: String,
    ) {
        val originalSubject = "Welcome to $appName - Your Pod Chief Account"

        val body =
            """
            |Hello $displayName,
            |
            |You have been appointed as Pod Chief for your $appName pod.
            |
            |Please log in to the admin portal with the following credentials:
            |
            |Email: $toEmail
            |Temporary Password: $tempPassword
            |
            |Access the admin portal at:
            |$adminPortalUrl
            |
            |IMPORTANT: You will be required to change your password on first login.
            |
            |After changing your password, you can optionally complete your profile
            |before accessing the dashboard.
            |
            |Password Requirements:
            |- At least 8 characters
            |- At least one uppercase letter (A-Z)
            |- At least one lowercase letter (a-z)
            |- At least one number (0-9)
            |
            |As Pod Chief, you will be responsible for:
            |- Setting up your pod configuration
            |- Managing pod administrators
            |- Overseeing issue resolution across the pod
            |
            |If you did not expect this email, please contact support.
            |
            |The $appName Team
            """.trimMargin()

        val effectiveRecipient = resolveRecipient(toEmail)
        val effectiveSubject = resolveSubject(originalSubject, toEmail)
        sendEmail(effectiveRecipient, effectiveSubject, body)
    }

    /**
     * Resolves the effective recipient, redirecting to override address if configured.
     */
    private fun resolveRecipient(originalRecipient: String): String {
        return if (overrideRecipient.isNotBlank()) {
            log.warn(
                "EMAIL OVERRIDE ACTIVE: Redirecting email from {} to {}",
                maskEmail(originalRecipient),
                overrideRecipient,
            )
            overrideRecipient
        } else {
            originalRecipient
        }
    }

    /**
     * Resolves the effective subject, prepending original recipient when override is active.
     */
    private fun resolveSubject(
        originalSubject: String,
        originalRecipient: String,
    ): String {
        return if (overrideRecipient.isNotBlank()) {
            "[To: $originalRecipient] $originalSubject"
        } else {
            originalSubject
        }
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
