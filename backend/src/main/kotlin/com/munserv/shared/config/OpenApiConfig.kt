package com.munserv.shared.config

import io.swagger.v3.oas.models.Components
import io.swagger.v3.oas.models.OpenAPI
import io.swagger.v3.oas.models.info.Contact
import io.swagger.v3.oas.models.info.Info
import io.swagger.v3.oas.models.info.License
import io.swagger.v3.oas.models.security.SecurityRequirement
import io.swagger.v3.oas.models.security.SecurityScheme
import io.swagger.v3.oas.models.servers.Server
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

/**
 * OpenAPI/Swagger configuration for MunServ API documentation.
 *
 * Swagger UI available at: /swagger-ui.html
 * OpenAPI spec available at: /v3/api-docs
 */
@Configuration
class OpenApiConfig {
    @Value("\${spring.application.name:MunServ API}")
    private lateinit var applicationName: String

    @Value("\${server.port:8080}")
    private lateinit var serverPort: String

    @Bean
    fun openAPI(): OpenAPI =
        OpenAPI()
            .info(apiInfo())
            .servers(servers())
            .components(securityComponents())
            .addSecurityItem(SecurityRequirement().addList(BEARER_AUTH))

    private fun apiInfo(): Info =
        Info()
            .title("MunServ API")
            .description(
                """
                MunServ - Municipal Service Issue Tracker API.

                Community-based infrastructure issue reporting system. Members report issues
                (potholes, leaks, broken lights) via mobile app with photos and GPS.
                Administrators manage via web portal.

                ## Authentication

                Most endpoints require JWT authentication. Obtain tokens via:
                - `/api/v1/auth/login` - Member login with phone + PIN
                - `/api/v1/auth/admin/login` - Admin login with email + password

                Include token in Authorization header: `Bearer <token>`

                ## Error Responses

                All errors follow this structure:
                ```json
                {
                  "error": {
                    "code": "ERROR_CODE",
                    "message": "Human-readable message"
                  }
                }
                ```
                """.trimIndent(),
            )
            .version("1.0.0")
            .contact(
                Contact()
                    .name("MunServ Development Team")
                    .email("dev@munserv.example.com"),
            )
            .license(
                License()
                    .name("Proprietary")
                    .url("https://munserv.example.com/license"),
            )

    private fun servers(): List<Server> =
        listOf(
            Server()
                .url("http://localhost:$serverPort")
                .description("Local Development Server"),
            Server()
                .url("https://api.munserv.example.com")
                .description("Production Server"),
        )

    private fun securityComponents(): Components =
        Components()
            .addSecuritySchemes(
                BEARER_AUTH,
                SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")
                    .description("JWT authentication token obtained from login endpoints"),
            )

    companion object {
        const val BEARER_AUTH = "bearerAuth"
    }
}
