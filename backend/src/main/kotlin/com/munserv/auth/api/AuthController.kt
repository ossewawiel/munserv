package com.munserv.auth.api

import com.munserv.auth.service.AuthResult
import com.munserv.auth.service.AuthService
import com.munserv.auth.service.CompleteRegistrationCommand
import com.munserv.auth.service.RegistrationResult
import com.munserv.auth.service.RegistrationService
import com.munserv.auth.service.WebRegistrationCommand
import com.munserv.shared.types.GeoPoint
import com.munserv.shared.types.MemberId
import com.munserv.shared.types.SectorId
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * Controller for authentication endpoints.
 * Matches mock API contract.
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "User registration, login, and token management")
class AuthController(
    private val authService: AuthService,
    private val registrationService: RegistrationService,
) {
    companion object {
        private const val ERROR_INVALID_PHONE = "Invalid phone number format"
        private const val ERROR_UNEXPECTED = "Unexpected error"
    }

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
            is AuthResult.OtpSent -> {
                ResponseEntity.ok(OtpResponse(message = "OTP sent successfully"))
            }

            is AuthResult.PhoneAlreadyRegistered -> {
                ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(ErrorResponse("phone_registered", "Phone number is already registered"))
            }

            is AuthResult.InvalidPhoneNumber -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", ERROR_INVALID_PHONE))
            }

            // Exhaustive handling of all AuthResult cases - these should never occur for register()
            is AuthResult.OtpVerified,
            is AuthResult.RegistrationComplete,
            is AuthResult.InvalidOtp,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.PhoneCheckResult,
            is AuthResult.LoginSuccess,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.InvalidCredentials,
            is AuthResult.AccountSuspended,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.PendingApproval,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
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
            is AuthResult.OtpVerified -> {
                ResponseEntity.ok(OtpResponse(message = "OTP verified successfully"))
            }

            is AuthResult.InvalidOtp -> {
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_otp", "Invalid or expired OTP"))
            }

            is AuthResult.InvalidPhoneNumber -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", ERROR_INVALID_PHONE))
            }

            // Exhaustive handling - these should never occur for verifyOtp()
            is AuthResult.OtpSent,
            is AuthResult.RegistrationComplete,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.PhoneCheckResult,
            is AuthResult.LoginSuccess,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.InvalidCredentials,
            is AuthResult.AccountSuspended,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.PendingApproval,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
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
                    CompleteRegistrationCommand(
                        phone = request.phone,
                        pin = request.pin,
                        firstName = request.firstName,
                        surname = request.surname,
                        address = request.address,
                        sectorId = request.sectorId,
                        location = GeoPoint(request.latitude, request.longitude),
                    ),
                )
        ) {
            is AuthResult.RegistrationComplete -> {
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
            }

            is AuthResult.InvalidPhoneNumber -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", ERROR_INVALID_PHONE))
            }

            is AuthResult.InvalidPin -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_pin", "PIN must be exactly 4 digits"))
            }

            is AuthResult.InvalidSectorId -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_sector", "Invalid sector ID format"))
            }

            // Exhaustive handling - these should never occur for completeRegistration()
            is AuthResult.OtpSent,
            is AuthResult.OtpVerified,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidOtp,
            is AuthResult.PhoneCheckResult,
            is AuthResult.LoginSuccess,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.InvalidCredentials,
            is AuthResult.AccountSuspended,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.PendingApproval,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
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
            is AuthResult.LoginSuccess -> {
                ResponseEntity.ok(
                    LoginResponse(
                        memberId = result.memberId.value.toString(),
                        accessToken = result.tokens.accessToken,
                        refreshToken = result.tokens.refreshToken,
                        expiresIn = result.tokens.expiresIn,
                    ),
                )
            }

            is AuthResult.InvalidCredentials -> {
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_credentials", "Invalid phone number or PIN"))
            }

            is AuthResult.AccountSuspended -> {
                ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse("account_suspended", "Account is suspended or deleted"))
            }

            // Exhaustive handling - these should never occur for login()
            is AuthResult.OtpSent,
            is AuthResult.OtpVerified,
            is AuthResult.RegistrationComplete,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidPhoneNumber,
            is AuthResult.InvalidOtp,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.PhoneCheckResult,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.PendingApproval,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
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
            is AuthResult.AdminLoginSuccess -> {
                val expiresAt =
                    java.time.Instant
                        .now()
                        .plusSeconds(result.tokens.expiresIn)
                        .toString()

                // Build sector response only if admin has sector info
                val sector =
                    if (result.sectorId != null && result.sectorName != null &&
                        result.sectorCenterLat != null && result.sectorCenterLng != null
                    ) {
                        AdminSector(
                            id = result.sectorId,
                            name = result.sectorName,
                            center =
                                GeoPointResponse(
                                    lat = result.sectorCenterLat,
                                    lng = result.sectorCenterLng,
                                ),
                        )
                    } else {
                        null
                    }

                ResponseEntity.ok(
                    AdminLoginResponse(
                        tokens =
                            AdminTokens(
                                accessToken = result.tokens.accessToken,
                                refreshToken = result.tokens.refreshToken,
                                expiresAt = expiresAt,
                            ),
                        profile =
                            AdminProfile(
                                admin =
                                    AdminUser(
                                        id = result.adminId,
                                        email = result.email,
                                        displayName = result.displayName,
                                        role = result.role,
                                        level = result.level,
                                        podId = result.podId,
                                        wardId = result.wardId,
                                        sectorId = result.sectorId,
                                        onboardingStatus = result.onboardingStatus,
                                    ),
                                sector = sector,
                            ),
                    ),
                )
            }

            is AuthResult.SuperUserLoginSuccess -> {
                val expiresAt =
                    java.time.Instant
                        .now()
                        .plusSeconds(result.tokens.expiresIn)
                        .toString()

                ResponseEntity.ok(
                    AdminLoginResponse(
                        tokens =
                            AdminTokens(
                                accessToken = result.tokens.accessToken,
                                refreshToken = result.tokens.refreshToken,
                                expiresAt = expiresAt,
                            ),
                        profile =
                            AdminProfile(
                                admin =
                                    AdminUser(
                                        id = "super-user",
                                        email = "",
                                        displayName = "Super User",
                                        role = "SUPER_USER",
                                        level = "system",
                                        podId = result.podId,
                                        wardId = null,
                                        sectorId = null,
                                        onboardingStatus = null,
                                    ),
                                sector = null,
                                bootstrapStatus = result.bootstrapStatus,
                            ),
                    ),
                )
            }

            is AuthResult.InvalidCredentials -> {
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_credentials", "Invalid email or password"))
            }

            // Exhaustive handling - these should never occur for adminLogin()
            is AuthResult.OtpSent,
            is AuthResult.OtpVerified,
            is AuthResult.RegistrationComplete,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidPhoneNumber,
            is AuthResult.InvalidOtp,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.PhoneCheckResult,
            is AuthResult.LoginSuccess,
            is AuthResult.AccountSuspended,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.PendingApproval,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
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
            is AuthResult.TokenRefreshed -> {
                ResponseEntity.ok(result.tokens.toResponse())
            }

            is AuthResult.InvalidToken -> {
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_token", "Invalid or expired refresh token"))
            }

            // Exhaustive handling - these should never occur for refreshToken()
            is AuthResult.OtpSent,
            is AuthResult.OtpVerified,
            is AuthResult.RegistrationComplete,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidPhoneNumber,
            is AuthResult.InvalidOtp,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.PhoneCheckResult,
            is AuthResult.LoginSuccess,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.InvalidCredentials,
            is AuthResult.AccountSuspended,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.PendingApproval,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
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
            is AuthResult.PhoneCheckResult -> {
                ResponseEntity.ok(CheckPhoneResponse(isRegistered = result.isRegistered))
            }

            is AuthResult.InvalidPhoneNumber -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_phone", ERROR_INVALID_PHONE))
            }

            // Exhaustive handling - these should never occur for checkPhone()
            is AuthResult.OtpSent,
            is AuthResult.OtpVerified,
            is AuthResult.RegistrationComplete,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidOtp,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.LoginSuccess,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.InvalidCredentials,
            is AuthResult.AccountSuspended,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.PendingApproval,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
        }

    /**
     * Public registration for web form submissions.
     * Creates member with PendingApproval status.
     */
    @Operation(summary = "Register member via web form")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "201", description = "Registration submitted"),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "409", description = "Email already registered"),
        ],
    )
    @PostMapping("/register/web")
    fun registerWeb(
        @Valid @RequestBody request: WebRegisterRequest,
    ): ResponseEntity<*> {
        val command =
            WebRegistrationCommand(
                email = request.email,
                firstName = request.firstName,
                surname = request.surname,
                phone = request.phone,
                address = request.address,
                location = GeoPoint(request.latitude, request.longitude),
                sectorId = SectorId(UUID.fromString(request.sectorId)),
            )

        return when (val result = registrationService.registerMember(command)) {
            is RegistrationResult.Success -> {
                ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
                        WebRegisterResponse(
                            message = "Registration submitted. You will be notified once approved.",
                            memberId =
                                result.member.id.value
                                    .toString(),
                        ),
                    )
            }

            is RegistrationResult.EmailAlreadyRegistered -> {
                ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(ErrorResponse("email_registered", "Email address already registered"))
            }

            is RegistrationResult.InvalidSector -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("invalid_sector", "Invalid sector ID"))
            }

            is RegistrationResult.ValidationError -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("validation_error", result.errors.joinToString(", ")))
            }

            is RegistrationResult.Approved,
            is RegistrationResult.Rejected,
            is RegistrationResult.MemberNotFound,
            is RegistrationResult.InvalidStatus,
            -> {
                ResponseEntity.internalServerError().build<Unit>()
            }
        }
    }

    /**
     * Member login with email and password.
     * Used by mobile app after admin approval.
     */
    @Operation(summary = "Member login with email and password")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Login successful"),
            ApiResponse(responseCode = "401", description = "Invalid credentials"),
            ApiResponse(responseCode = "403", description = "Account pending or suspended"),
        ],
    )
    @PostMapping("/member/login")
    fun memberLogin(
        @Valid @RequestBody request: MemberLoginRequest,
    ): ResponseEntity<*> =
        when (val result = authService.loginWithEmail(request.email, request.password)) {
            is AuthResult.MemberLoginSuccess -> {
                ResponseEntity.ok(
                    MemberLoginResponse(
                        memberId = result.memberId.value.toString(),
                        accessToken = result.tokens.accessToken,
                        refreshToken = result.tokens.refreshToken,
                        expiresIn = result.tokens.expiresIn,
                        mustChangePassword = result.mustChangePassword,
                    ),
                )
            }

            is AuthResult.InvalidCredentials -> {
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_credentials", "Invalid email or password"))
            }

            is AuthResult.PendingApproval -> {
                ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse("pending_approval", "Your registration is pending admin approval"))
            }

            is AuthResult.AccountSuspended -> {
                ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse("account_suspended", "Your account has been suspended"))
            }

            // Exhaustive handling - these should never occur for memberLogin()
            is AuthResult.OtpSent,
            is AuthResult.OtpVerified,
            is AuthResult.RegistrationComplete,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidPhoneNumber,
            is AuthResult.InvalidOtp,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.PhoneCheckResult,
            is AuthResult.LoginSuccess,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.PasswordChanged,
            is AuthResult.MemberNotFound,
            is AuthResult.ValidationError,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
        }

    /**
     * Change password for authenticated member.
     */
    @Operation(summary = "Change member password")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "200", description = "Password changed"),
            ApiResponse(responseCode = "400", description = "Validation error"),
            ApiResponse(responseCode = "401", description = "Invalid current password"),
        ],
    )
    @PostMapping("/change-password")
    fun changePassword(
        @AuthenticationPrincipal memberId: String?,
        @Valid @RequestBody request: ChangePasswordRequest,
    ): ResponseEntity<*> {
        if (memberId == null) {
            return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(ErrorResponse("unauthorized", "Authentication required"))
        }

        return when (
            val result =
                authService.changePassword(
                    MemberId(UUID.fromString(memberId)),
                    request.currentPassword,
                    request.newPassword,
                )
        ) {
            is AuthResult.PasswordChanged -> {
                ResponseEntity.ok(
                    MessageResponse("Password changed successfully"),
                )
            }

            is AuthResult.InvalidCredentials -> {
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("invalid_password", "Current password is incorrect"))
            }

            is AuthResult.ValidationError -> {
                ResponseEntity
                    .badRequest()
                    .body(ErrorResponse("validation_error", result.errors.joinToString(", ")))
            }

            is AuthResult.MemberNotFound -> {
                ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse("not_found", "Member not found"))
            }

            // Exhaustive handling - these should never occur for changePassword()
            is AuthResult.OtpSent,
            is AuthResult.OtpVerified,
            is AuthResult.RegistrationComplete,
            is AuthResult.PhoneAlreadyRegistered,
            is AuthResult.InvalidPhoneNumber,
            is AuthResult.InvalidOtp,
            is AuthResult.InvalidPin,
            is AuthResult.InvalidSectorId,
            is AuthResult.PhoneCheckResult,
            is AuthResult.LoginSuccess,
            is AuthResult.AdminLoginSuccess,
            is AuthResult.SuperUserLoginSuccess,
            is AuthResult.AccountSuspended,
            is AuthResult.TokenRefreshed,
            is AuthResult.InvalidToken,
            is AuthResult.MemberLoginSuccess,
            is AuthResult.PendingApproval,
            -> {
                throw IllegalStateException("Unexpected result type: ${result::class.simpleName}")
            }
        }
    }
}
