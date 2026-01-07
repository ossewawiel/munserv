package com.munserv.auth.api

import com.munserv.auth.service.AuthResult
import com.munserv.auth.service.AuthService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

/**
 * Controller for authentication endpoints.
 * Matches mock API contract.
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "User registration, login, and token management")
class AuthController(
    private val authService: AuthService,
) {
    @Operation(summary = "Request OTP", description = "Request a one-time password for phone number verification")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "OTP sent successfully"),
            ApiResponse(responseCode = "400", description = "Invalid phone number format"),
            ApiResponse(responseCode = "409", description = "Phone number already registered"),
        ],
    )
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

    @Operation(summary = "Verify OTP", description = "Verify the one-time password sent to phone")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "OTP verified successfully"),
            ApiResponse(responseCode = "400", description = "Invalid phone number format"),
            ApiResponse(responseCode = "401", description = "Invalid or expired OTP"),
        ],
    )
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

    @Operation(summary = "Complete registration", description = "Complete member registration with profile details and PIN")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "201", description = "Registration completed successfully"),
            ApiResponse(responseCode = "400", description = "Invalid phone number or PIN format"),
        ],
    )
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

    @Operation(summary = "Member login", description = "Authenticate member with phone number and PIN")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Login successful"),
            ApiResponse(responseCode = "401", description = "Invalid credentials"),
            ApiResponse(responseCode = "403", description = "Account suspended"),
        ],
    )
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

    @Operation(summary = "Admin login", description = "Authenticate administrator with email and password")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Admin login successful"),
            ApiResponse(responseCode = "401", description = "Invalid credentials"),
        ],
    )
    @PostMapping("/admin/login")
    fun adminLogin(
        @Valid @RequestBody request: AdminLoginRequest,
    ): ResponseEntity<*> =
        when (val result = authService.adminLogin(request.email, request.password)) {
            is AuthResult.AdminLoginSuccess ->
                ResponseEntity.ok(
                    AdminLoginResponse(
                        tokens = AdminTokens(
                            accessToken = result.tokens.accessToken,
                            refreshToken = result.tokens.refreshToken,
                            expiresAt = java.time.Instant.now()
                                .plusSeconds(result.tokens.expiresIn)
                                .toString(),
                        ),
                        profile = AdminProfile(
                            admin = AdminUser(
                                id = result.adminId,
                                email = result.email,
                                displayName = result.displayName,
                                sectorId = result.sectorId,
                                role = result.role,
                            ),
                            sector = AdminSector(
                                id = result.sectorId,
                                name = result.sectorName,
                                center = GeoPointResponse(
                                    lat = result.sectorCenterLat,
                                    lng = result.sectorCenterLng,
                                ),
                            ),
                        ),
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

    @Operation(summary = "Refresh token", description = "Exchange a valid refresh token for new access and refresh tokens")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Tokens refreshed successfully"),
            ApiResponse(responseCode = "401", description = "Invalid or expired refresh token"),
        ],
    )
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

    @Operation(summary = "Check phone registration", description = "Check if a phone number is already registered")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Phone check successful"),
            ApiResponse(responseCode = "400", description = "Invalid phone number format"),
        ],
    )
    @GetMapping("/check-phone")
    fun checkPhone(
        @RequestParam phone: String,
    ): ResponseEntity<*> =
        when (val result = authService.checkPhone(phone)) {
            is AuthResult.PhoneCheckResult ->
                ResponseEntity.ok(CheckPhoneResponse(isRegistered = result.isRegistered))

            is AuthResult.InvalidPhoneNumber ->
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", "Invalid phone number format"))

            else ->
                ResponseEntity
                    .internalServerError()
                    .body(ErrorResponse("error", "Unexpected error"))
        }
}
