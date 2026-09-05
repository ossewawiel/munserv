import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/typography.dart';

/// Rectangular map preview showing a single location marker.
/// Non-interactive in preview mode; tap to expand to fullscreen.
///
/// Usage:
/// ```dart
/// IssueLocationMap(
///   latitude: issue.latitude,
///   longitude: issue.longitude,
///   onTap: () => context.push('/issues/${issue.id}/map'),
/// )
/// ```
class IssueLocationMap extends StatelessWidget {
  /// Latitude of the issue location.
  final double latitude;

  /// Longitude of the issue location.
  final double longitude;

  /// Called when the map is tapped. Use to navigate to fullscreen view.
  final VoidCallback? onTap;

  /// Size of the map (width and height).
  /// Defaults to filling available width with 16:10 aspect ratio.
  final double? size;

  const IssueLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final center = LatLng(latitude, longitude);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        child: AspectRatio(
          aspectRatio: 16 / 10, // Rectangular for more space below
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Radii.md - 1,
              ), // Slightly smaller to fit inside border
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // Disable all gestures
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.munserv.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: IconSizes.xl,
                            height: IconSizes.xl,
                            child: Icon(
                              Icons.location_pin,
                              color: colors.error, // Red for visibility
                              size: IconSizes.xl,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Tap indicator overlay - larger for easier tapping
                  if (onTap != null)
                    Positioned(
                      bottom: Spacing.sm,
                      right: Spacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen,
                              size: IconSizes.md,
                              color: colors.primary,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              'Tap to expand',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
