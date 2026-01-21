// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MunServ';

  @override
  String get phoneEntryTitle => 'Enter Phone Number';

  @override
  String get phoneEntrySubtitle => 'We\'ll send you a verification code';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get phoneHint => 'Enter your phone number';

  @override
  String get continueButton => 'Continue';

  @override
  String get otpTitle => 'Verify Phone';

  @override
  String otpSubtitle(String phoneNumber) {
    return 'Enter the 6-digit code sent to $phoneNumber';
  }

  @override
  String get resendOtp => 'Resend Code';

  @override
  String resendOtpIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get profileTitle => 'Your Details';

  @override
  String get profileSubtitle => 'Tell us a bit about yourself';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get surnameLabel => 'Surname';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressHint => 'Your residential address';

  @override
  String get detectLocation => 'Detect My Location';

  @override
  String get pinSetupTitle => 'Create PIN';

  @override
  String get pinSetupSubtitle => 'You\'ll use this to log in';

  @override
  String get pinLabel => 'Enter PIN';

  @override
  String get pinConfirmLabel => 'Confirm PIN';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Enter your PIN to continue';

  @override
  String get useBiometrics => 'Use Fingerprint / Face ID';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorInvalidPhone => 'Please enter a valid phone number';

  @override
  String get errorInvalidOtp => 'Invalid verification code';

  @override
  String get errorInvalidPin => 'Invalid PIN';

  @override
  String get successRegistration => 'Registration successful!';

  @override
  String get home => 'Home';

  @override
  String get issues => 'Issues';

  @override
  String get report => 'Report';

  @override
  String get profile => 'Profile';

  @override
  String get issuesTitle => 'Issues';

  @override
  String get issueDetailTitle => 'Issue Details';

  @override
  String get myReportsTitle => 'My Reports';

  @override
  String get reportIssueTitle => 'Report Issue';

  @override
  String get mapViewTitle => 'Map View';

  @override
  String get appTagline => 'Municipal Service Watchdog';

  @override
  String get loginWithEmailSubtitle =>
      'Enter your email and password to continue';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get loginButton => 'Log In';

  @override
  String get noAccountQuestion => 'Don\'t have an account?';

  @override
  String get registerOnWebInstruction =>
      'Register at munserv.app to join your community';

  @override
  String get changePasswordTitle => 'Change Your Password';

  @override
  String get changePasswordSubtitle =>
      'Please set a new secure password to continue';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get tempPasswordHelp =>
      'Enter the temporary password from your welcome email';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmPasswordLabel => 'Confirm New Password';

  @override
  String get changePasswordButton => 'Change Password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordNeedsUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordNeedsLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordNeedsNumber => 'Password must contain at least one number';

  @override
  String get passwordsMustMatch => 'Passwords do not match';

  @override
  String get passwordRequirements =>
      'At least 8 characters, with uppercase, lowercase, and numbers';

  @override
  String get setupPinTitle => 'Set Up Your PIN';

  @override
  String get setupPinSubtitle => 'Create a 4-digit PIN for quick access';

  @override
  String get confirmPinTitle => 'Confirm Your PIN';

  @override
  String get confirmPinSubtitle => 'Enter your PIN again to confirm';

  @override
  String get startOver => 'Start Over';

  @override
  String get enableBiometricTitle => 'Enable Biometric Login';

  @override
  String enableBiometricMessage(String biometricType) {
    return 'Would you like to use $biometricType for faster login?';
  }

  @override
  String get notNow => 'Not Now';

  @override
  String get enable => 'Enable';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Please enable in settings.';

  @override
  String get locationError => 'Unable to get your location. Please try again.';

  @override
  String get noSectorAssigned => 'Your account is not assigned to a sector.';

  @override
  String get photoTooLarge => 'Photo is too large. Maximum size is 5MB.';

  @override
  String get unsupportedPhotoFormat =>
      'Unsupported photo format. Use JPEG, PNG, or WebP.';

  @override
  String get issueSubmittedSuccess => 'Issue reported successfully!';

  @override
  String get issueSubmitFailed => 'Failed to submit issue. Please try again.';

  @override
  String pinLoginSubtitle(String email) {
    return 'Enter your PIN to continue as $email';
  }

  @override
  String get useDifferentAccount => 'Use Different Account';

  @override
  String get pinLoginInfo =>
      'Enter your 4-digit PIN to quickly access your account.';

  @override
  String get messages => 'Messages';

  @override
  String get noMessages => 'No Messages';

  @override
  String get noMessagesSubtitle =>
      'You don\'t have any messages yet. Check back later.';

  @override
  String get unread => 'Unread';

  @override
  String get actioned => 'Actioned';

  @override
  String get all => 'All';

  @override
  String get filter => 'Filter';

  @override
  String get refresh => 'Refresh';

  @override
  String get messageDetail => 'Message';

  @override
  String get actionCompleted => 'Action completed';

  @override
  String get actionTaken => 'Action taken';

  @override
  String get viewRelatedIssue => 'View Related Issue';

  @override
  String get verifyNow => 'Verify Now';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get confirm => 'Confirm';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get accepted => 'Accepted';

  @override
  String get declined => 'Declined';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get dismissed => 'Dismissed';

  @override
  String get becomeGroundAdmin => 'Become a Ground Admin';

  @override
  String get whatIsGroundAdmin => 'What is a Ground Admin?';

  @override
  String get groundAdminDescription =>
      'Ground Admins are trusted community members who help verify issues on the ground. They confirm that reported problems exist and that fixes are complete.';

  @override
  String get responsibilities => 'Responsibilities';

  @override
  String get verifyNewIssues => 'Verify that reported issues exist';

  @override
  String get confirmFixes => 'Confirm when issues are properly fixed';

  @override
  String get providePhotoEvidence => 'Provide photo evidence when needed';

  @override
  String get respondPromptly => 'Respond to verification requests promptly';

  @override
  String get applyNow => 'Apply Now';

  @override
  String get applicationSubmitted => 'Your application has been submitted';

  @override
  String get groundAdminInvitation => 'Ground Admin Invitation';

  @override
  String invitedByAdmin(String name) {
    return '$name has invited you to become a Ground Admin';
  }

  @override
  String get invitedToBeGroundAdmin =>
      'You have been invited to become a Ground Admin';

  @override
  String get groundAdminInvitationDescription =>
      'As a Ground Admin, you\'ll help verify issues in your community. This is a volunteer role that helps keep your neighborhood safe and well-maintained.';

  @override
  String get asGroundAdminYouWill => 'As a Ground Admin, you will:';

  @override
  String get helpYourCommunity => 'Help improve your community';

  @override
  String get groundAdminStatus => 'Ground Admin';

  @override
  String get responseRate => 'Response Rate';

  @override
  String get pendingVerifications => 'Pending Verifications';

  @override
  String get totalVerifications => 'Total Verifications';

  @override
  String get memberSince => 'Member Since';

  @override
  String get stepDownFromRole => 'Step Down from Role';

  @override
  String get verifyIssueExists => 'Verify Issue Exists';

  @override
  String get verifyIssueFix => 'Verify Fix';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get photoOptional => 'Optional: Take a photo as evidence';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get additionalNote => 'Additional Note';

  @override
  String get noteHint => 'Add any additional observations...';

  @override
  String get confirmExists => 'Confirm Issue Exists';

  @override
  String get confirmFixed => 'Confirm Fix is Complete';

  @override
  String get cannotVerify => 'Cannot Verify';

  @override
  String get notFixed => 'Not Fixed';

  @override
  String get verificationSubmitted => 'Verification submitted';

  @override
  String get verificationNotFound => 'Verification request not found';

  @override
  String get selectReason => 'Please select a reason:';

  @override
  String get viewOnMap => 'View on Map';
}
