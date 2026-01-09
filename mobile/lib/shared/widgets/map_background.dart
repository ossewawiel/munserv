import 'package:flutter/material.dart';

/// A container that displays the vintage map background with a surface color overlay.
///
/// This widget creates a layered background similar to the web app's AuthLayout:
/// - Base layer: vintage map image covering the full area
/// - Overlay: surface color at 85% opacity for readability
/// - Content: child widget on top
///
/// Usage:
/// ```dart
/// MapBackground(
///   child: YourContent(),
/// )
/// ```
class MapBackground extends StatelessWidget {
  /// The content to display on top of the map background.
  final Widget child;

  /// The overlay opacity (0.0 to 1.0). Defaults to 0.90 (90%).
  final double overlayOpacity;

  const MapBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.90,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use the theme's surface color for the overlay to maintain consistency
    final overlayColor = colorScheme.surface;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/vintage-map.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: overlayColor.withValues(alpha: overlayOpacity),
        child: child,
      ),
    );
  }
}
