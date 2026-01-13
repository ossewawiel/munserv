import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'MunServ'**
  String get appTitle;

  /// Title for phone entry screen
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get phoneEntryTitle;

  /// Subtitle for phone entry screen
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code'**
  String get phoneEntrySubtitle;

  /// Label for phone input field
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// Hint text for phone input
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneHint;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Title for OTP verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get otpTitle;

  /// Subtitle for OTP verification screen
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phoneNumber}'**
  String otpSubtitle(String phoneNumber);

  /// Button to resend OTP
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendOtp;

  /// Countdown text for OTP resend
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendOtpIn(int seconds);

  /// Title for profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Your Details'**
  String get profileTitle;

  /// Subtitle for profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself'**
  String get profileSubtitle;

  /// Label for first name field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// Label for surname field
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surnameLabel;

  /// Label for address field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// Hint text for address input
  ///
  /// In en, this message translates to:
  /// **'Your residential address'**
  String get addressHint;

  /// Button to detect current location
  ///
  /// In en, this message translates to:
  /// **'Detect My Location'**
  String get detectLocation;

  /// Title for PIN setup screen
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get pinSetupTitle;

  /// Subtitle for PIN setup screen
  ///
  /// In en, this message translates to:
  /// **'You\'ll use this to log in'**
  String get pinSetupSubtitle;

  /// Label for PIN input
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get pinLabel;

  /// Label for PIN confirmation input
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get pinConfirmLabel;

  /// Error message when PINs don't match
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// Title for login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// Subtitle for login screen
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue'**
  String get loginSubtitle;

  /// Button to use biometric login
  ///
  /// In en, this message translates to:
  /// **'Use Fingerprint / Face ID'**
  String get useBiometrics;

  /// Link to reset PIN
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// Invalid phone number error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get errorInvalidPhone;

  /// Invalid OTP error
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get errorInvalidOtp;

  /// Invalid PIN error
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN'**
  String get errorInvalidPin;

  /// Registration success message
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get successRegistration;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Issues navigation label
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// Report navigation label
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Title for issues list page
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issuesTitle;

  /// Title for issue detail page
  ///
  /// In en, this message translates to:
  /// **'Issue Details'**
  String get issueDetailTitle;

  /// Title for my reports page
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReportsTitle;

  /// Title for report issue page
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssueTitle;

  /// Title for map view page
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapViewTitle;

  /// App tagline shown below logo in branding header
  ///
  /// In en, this message translates to:
  /// **'Municipal Service Watchdog'**
  String get appTagline;

  /// Subtitle for email login screen
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to continue'**
  String get loginWithEmailSubtitle;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// Error when email is empty
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Error for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Error when password is empty
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// Question for users without account
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountQuestion;

  /// Instructions to register on web portal
  ///
  /// In en, this message translates to:
  /// **'Register at munserv.app to join your community'**
  String get registerOnWebInstruction;

  /// Title for change password screen
  ///
  /// In en, this message translates to:
  /// **'Change Your Password'**
  String get changePasswordTitle;

  /// Subtitle for change password screen
  ///
  /// In en, this message translates to:
  /// **'Please set a new secure password to continue'**
  String get changePasswordSubtitle;

  /// Label for current password field
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// Helper text for temporary password field
  ///
  /// In en, this message translates to:
  /// **'Enter the temporary password from your welcome email'**
  String get tempPasswordHelp;

  /// Label for new password field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPasswordLabel;

  /// Change password button text
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordButton;

  /// Error when password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// Error when password lacks uppercase
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordNeedsUppercase;

  /// Error when password lacks lowercase
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordNeedsLowercase;

  /// Error when password lacks number
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordNeedsNumber;

  /// Error when passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMustMatch;

  /// Password requirements description
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with uppercase, lowercase, and numbers'**
  String get passwordRequirements;

  /// Title for PIN setup screen (email flow)
  ///
  /// In en, this message translates to:
  /// **'Set Up Your PIN'**
  String get setupPinTitle;

  /// Subtitle for PIN setup screen (email flow)
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN for quick access'**
  String get setupPinSubtitle;

  /// Title for PIN confirmation screen
  ///
  /// In en, this message translates to:
  /// **'Confirm Your PIN'**
  String get confirmPinTitle;

  /// Subtitle for PIN confirmation screen
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN again to confirm'**
  String get confirmPinSubtitle;

  /// Button to restart PIN entry
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get startOver;

  /// Title for biometric enable dialog
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Login'**
  String get enableBiometricTitle;

  /// Message for biometric enable dialog
  ///
  /// In en, this message translates to:
  /// **'Would you like to use {biometricType} for faster login?'**
  String enableBiometricMessage(String biometricType);

  /// Button to skip biometric setup
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// Button to enable a feature
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// Error when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please enable in settings.'**
  String get locationPermissionDenied;

  /// Generic location error message
  ///
  /// In en, this message translates to:
  /// **'Unable to get your location. Please try again.'**
  String get locationError;

  /// Error when user has no sector assigned
  ///
  /// In en, this message translates to:
  /// **'Your account is not assigned to a sector.'**
  String get noSectorAssigned;

  /// Error when photo exceeds size limit
  ///
  /// In en, this message translates to:
  /// **'Photo is too large. Maximum size is 5MB.'**
  String get photoTooLarge;

  /// Error when photo format is not supported
  ///
  /// In en, this message translates to:
  /// **'Unsupported photo format. Use JPEG, PNG, or WebP.'**
  String get unsupportedPhotoFormat;

  /// Success message after issue submission
  ///
  /// In en, this message translates to:
  /// **'Issue reported successfully!'**
  String get issueSubmittedSuccess;

  /// Error message when issue submission fails
  ///
  /// In en, this message translates to:
  /// **'Failed to submit issue. Please try again.'**
  String get issueSubmitFailed;

  /// Subtitle for PIN login screen showing user email
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue as {email}'**
  String pinLoginSubtitle(String email);

  /// Button to switch to a different account
  ///
  /// In en, this message translates to:
  /// **'Use Different Account'**
  String get useDifferentAccount;

  /// Info text on PIN login screen
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN to quickly access your account.'**
  String get pinLoginInfo;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
