import 'package:flutter/material.dart';

/// Size presets for the app logo
enum AppLogoSize {
  /// Small logo for AppBar (height: 32)
  small,

  /// Medium logo for secondary branding (height: 48)
  medium,

  /// Large logo for auth/splash screens (height: 80)
  large,
}

/// Reusable MunServ logo widget
///
/// The logo maintains its aspect ratio at all sizes.
/// Use [AppLogoSize] presets or provide custom [height].
class AppLogo extends StatelessWidget {
  /// The size preset for the logo
  final AppLogoSize? size;

  /// Custom height (overrides size preset)
  final double? height;

  /// Optional semantic label for accessibility
  final String semanticLabel;

  const AppLogo({
    super.key,
    this.size,
    this.height,
    this.semanticLabel = 'MunServ logo',
  }) : assert(
         size != null || height != null,
         'Either size or height must be provided',
       );

  /// Convenience constructor for small (AppBar) size
  const AppLogo.small({super.key, this.semanticLabel = 'MunServ logo'})
    : size = AppLogoSize.small,
      height = null;

  /// Convenience constructor for large (auth screen) size
  const AppLogo.large({super.key, this.semanticLabel = 'MunServ logo'})
    : size = AppLogoSize.large,
      height = null;

  double get _height =>
      height ??
      switch (size!) {
        AppLogoSize.small => 32,
        AppLogoSize.medium => 48,
        AppLogoSize.large => 80,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        'assets/app_logo.png',
        height: _height,
        fit: BoxFit.contain,
      ),
    );
  }
}
