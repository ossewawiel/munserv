package com.munserv.shared.config

import com.munserv.shared.security.JwtAuthenticationFilter
import com.munserv.support.api.SupportGrantActivityFilter
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Lazy
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter

@Configuration
@EnableWebSecurity
class SecurityConfig(
    private val jwtAuthenticationFilter: JwtAuthenticationFilter,
    @Lazy private val supportGrantActivityFilter: SupportGrantActivityFilter,
) {
    @Bean
    fun passwordEncoder(): PasswordEncoder = BCryptPasswordEncoder()

    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain =
        http
            .csrf { it.disable() }
            .cors { }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .authorizeHttpRequests { auth ->
                auth
                    // Public endpoints
                    .requestMatchers("/actuator/health", "/actuator/info")
                    .permitAll()
                    // Public auth endpoints
                    .requestMatchers("/api/v1/auth/register")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/register/web")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/verify-otp")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/complete-registration")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/login")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/member/login")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/admin/login")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/refresh")
                    .permitAll()
                    .requestMatchers("/api/v1/auth/check-phone")
                    .permitAll()
                    // Protected auth endpoints (require authentication)
                    .requestMatchers("/api/v1/auth/change-password")
                    .authenticated()
                    .requestMatchers("/api/v1/sectors", "/api/v1/sectors/**")
                    .permitAll()
                    .requestMatchers("/uploads/**")
                    .permitAll()
                    // Swagger/OpenAPI documentation endpoints
                    .requestMatchers("/swagger-ui.html", "/swagger-ui/**")
                    .permitAll()
                    .requestMatchers("/v3/api-docs/**", "/v3/api-docs.yaml")
                    .permitAll()
                    .requestMatchers("/swagger-resources/**", "/webjars/**")
                    .permitAll()
                    // Protected endpoints require authentication
                    .requestMatchers("/api/v1/issues/**")
                    .authenticated()
                    .requestMatchers("/api/v1/members/**")
                    .authenticated()
                    .requestMatchers("/api/v1/admin/**")
                    .hasRole("ADMIN")
                    // Bootstrap endpoints require super user role
                    .requestMatchers("/api/v1/bootstrap/**")
                    .hasRole("SUPER_USER")
                    // Support access endpoints require an authenticated admin (pod chief only, enforced by @RequireRole)
                    .requestMatchers("/api/v1/support-access/**")
                    .authenticated()
                    // Default: allow all for now (remaining endpoints)
                    .anyRequest()
                    .permitAll()
            }.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)
            .addFilterAfter(supportGrantActivityFilter, JwtAuthenticationFilter::class.java)
            .build()
}
