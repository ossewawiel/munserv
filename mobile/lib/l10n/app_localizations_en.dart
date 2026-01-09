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
}
