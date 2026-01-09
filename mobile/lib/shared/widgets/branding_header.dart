import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../theme/colors.dart';

/// Branding header widget displaying the MunServ logo and tagline
///
/// This header appears at the top of all screens, above the standard AppBar.
/// Uses the terracotta brand color as background with the dark logo variant.
class BrandingHeader extends StatelessWidget {
  /// Content height (excluding safe area)
  static const double _contentHeight = 64.0;

  /// Logo height within the header
  static const double _logoHeight = 36.0;

  const BrandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        height: _contentHeight + topPadding,
        width: double.infinity,
        color: BrandColors.defaultBrand.secondary, // Terracotta
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/app-logo-dark.png',
              height: _logoHeight,
              fit: BoxFit.contain,
              semanticLabel: l10n.appTitle,
            ),
            const SizedBox(height: 2),
            // Tagline
            Text(
              l10n.appTagline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
