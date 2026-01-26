/**
 * Onboarding status values
 */
export type OnboardingStatusValue =
  | 'pending'
  | 'password_changed'
  | 'profile_complete'
  | 'active';

/**
 * Response from onboarding status endpoint
 */
export interface OnboardingStatusResponse {
  status: OnboardingStatusValue;
  requiresPasswordChange: boolean;
  requiresProfileCompletion: boolean;
  isOnboarded: boolean;
  displayName: string;
}

/**
 * Request to change password during onboarding
 */
export interface ChangePasswordRequest {
  newPassword: string;
}

/**
 * Request to complete profile during onboarding
 */
export interface CompleteProfileRequest {
  displayName?: string;
  knownAs?: string;
  contactPhone?: string;
  address?: string;
}

/**
 * Password validation state
 */
export interface PasswordValidation {
  minLength: boolean;
  hasUppercase: boolean;
  hasLowercase: boolean;
  hasNumber: boolean;
}

/**
 * Check if all password requirements are met
 */
export function isPasswordValid(validation: PasswordValidation): boolean {
  return (
    validation.minLength &&
    validation.hasUppercase &&
    validation.hasLowercase &&
    validation.hasNumber
  );
}

/**
 * Validate a password against requirements
 */
export function validatePassword(password: string): PasswordValidation {
  return {
    minLength: password.length >= 8,
    hasUppercase: /[A-Z]/.test(password),
    hasLowercase: /[a-z]/.test(password),
    hasNumber: /\d/.test(password),
  };
}
