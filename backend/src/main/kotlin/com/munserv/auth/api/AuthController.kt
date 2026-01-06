package com.munserv.auth.api

import com.munserv.auth.service.AuthResult
import com.munserv.auth.service.AuthService
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/**
 * Controller for authentication endpoints.
 * Matches mock API contract.
 */
@RestController
@RequestMapping("/api/v1/auth")
class AuthController(
    private val authService: AuthService,
) {
    @PostMapping("/register")
    fun register(
        @Valid @RequestBody request: RegisterRequest,
    ): ResponseEntity<*> =
        when (val result = authService.register(request.phone)) {
            is AuthResult.OtpSent ->
                ResponseEntity.ok(OtpResponse(message = "OTP sent successfully"))

            is AuthResult.PhoneAlreadyRegistered ->
                ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(ErrorResponse("phone_registered", "Phone number is already registered"))

            is AuthResult.InvalidPhoneNumber ->
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", "Invalid phone number format"))

            else ->
                ResponseEntity
                    .internalServerError()
                    .body(ErrorResponse("error", "Unexpected error"))
        }

    @PostMapping("/verify-otp")
    fun verifyOtp(
        @Valid @RequestBody request: VerifyOtpRequest,
    ): ResponseEntity<*> =
        when (val result = authService.verifyOtp(request.phone, request.code)) {
            is AuthResult.OtpVerified ->
                ResponseEntity.ok(OtpResponse(message = "OTP verified successfully"))

            is AuthResult.InvalidOtp ->
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_otp", "Invalid or expired OTP"))

            is AuthResult.InvalidPhoneNumber ->
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", "Invalid phone number format"))

            else ->
                ResponseEntity
                    .internalServerError()
                    .body(ErrorResponse("error", "Unexpected error"))
        }

    @PostMapping("/complete-registration")
    fun completeRegistration(
        @Valid @RequestBody request: CompleteRegistrationRequest,
    ): ResponseEntity<*> =
        when (
            val result =
                authService.completeRegistration(
                    phone = request.phone,
                    pin = request.pin,
                    firstName = request.firstName,
                    surname = request.surname,
                    address = request.address,
                    sectorId = request.sectorId,
                    latitude = request.latitude,
                    longitude = request.longitude,
                )
        ) {
            is AuthResult.RegistrationComplete ->
                ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
                        RegistrationResponse(
                            memberId = result.memberId.value.toString(),
                            accessToken = result.tokens.accessToken,
                            refreshToken = result.tokens.refreshToken,
                            expiresIn = result.tokens.expiresIn,
                        ),
                    )

            is AuthResult.InvalidPhoneNumber ->
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", "Invalid phone number format"))

            is AuthResult.InvalidPin ->
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_pin", "PIN must be exactly 4 digits"))

            else ->
                ResponseEntity
                    .internalServerError()
                    .body(ErrorResponse("error", "Unexpected error"))
        }

    @PostMapping("/login")
    fun login(
        @Valid @RequestBody request: LoginRequest,
    ): ResponseEntity<*> =
        when (val result = authService.login(request.phone, request.pin)) {
            is AuthResult.LoginSuccess ->
                ResponseEntity.ok(
                    LoginResponse(
                        memberId = result.memberId.value.toString(),
                        accessToken = result.tokens.accessToken,
                        refreshToken = result.tokens.refreshToken,
                        expiresIn = result.tokens.expiresIn,
                    ),
                )

            is AuthResult.InvalidCredentials ->
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_credentials", "Invalid phone number or PIN"))

            is AuthResult.AccountSuspended ->
                ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse("account_suspended", "Account is suspended or deleted"))

            else ->
                ResponseEntity
                    .internalServerError()
                    .body(ErrorResponse("error", "Unexpected error"))
        }

    @PostMapping("/admin/login")
    fun adminLogin(
        @Valid @RequestBody request: AdminLoginRequest,
    ): ResponseEntity<*> =
        when (val result = authService.adminLogin(request.email, request.password)) {
            is AuthResult.AdminLoginSuccess ->
                ResponseEntity.ok(
                    AdminLoginResponse(
                        adminId = result.adminId,
                        email = result.email,
                        displayName = result.displayName,
                        sectorId = result.sectorId,
                        accessToken = result.tokens.accessToken,
                        refreshToken = result.tokens.refreshToken,
                        expiresIn = result.tokens.expiresIn,
                    ),
                )

            is AuthResult.InvalidCredentials ->
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_credentials", "Invalid email or password"))

            else ->
                ResponseEntity
                    .internalServerError()
                    .body(ErrorResponse("error", "Unexpected error"))
        }

    @PostMapping("/refresh")
    fun refreshToken(
        @Valid @RequestBody request: RefreshTokenRequest,
    ): ResponseEntity<*> =
        when (val result = authService.refreshToken(request.refreshToken)) {
            is AuthResult.TokenRefreshed ->
                ResponseEntity.ok(result.tokens.toResponse())

            is AuthResult.InvalidToken ->
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_token", "Invalid or expired refresh token"))

            else ->
                ResponseEntity
                    .internalServerError()
                    .body(ErrorResponse("error", "Unexpected error"))
        }
}
