import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../providers/issue_providers.dart';

/// Fullscreen interactive map showing issue location.
/// Supports pinch-to-zoom and pan gestures.
class FullscreenMapPage extends ConsumerStatefulWidget {
  final String issueId;

  const FullscreenMapPage({super.key, required this.issueId});

  @override
  ConsumerState<FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends ConsumerState<FullscreenMapPage> {
  final MapController _mapController = MapController();
  double _currentZoom = 16;

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(issueDetailProvider(widget.issueId));
    final colors = Theme.of(context).colorScheme;

    return BrandedScaffold(
      showMapBackground: false, // Don't show vintage map behind actual map
      appBar: AppBar(title: const Text('Location')),
      body: issueAsync.when(
        data: (issue) {
          final center = LatLng(issue.latitude, issue.longitude);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _currentZoom,
                  minZoom: 10,
                  maxZoom: 18,
                  onPositionChanged: (position, hasGesture) {
                    setState(() => _currentZoom = position.zoom);
                  },
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
                          color: colors.error,
                          size: IconSizes.xl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Zoom controls
              Positioned(
                right: Spacing.md,
                bottom: Spacing.xl,
                child: Column(
                  children: [
                    _ZoomButton(
                      icon: Icons.add,
                      onPressed: () {
                        final newZoom = (_currentZoom + 1).clamp(10.0, 18.0);
                        _mapController.move(
                          _mapController.camera.center,
                          newZoom,
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ZoomButton(
                      icon: Icons.remove,
                      onPressed: () {
                        final newZoom = (_currentZoom - 1).clamp(10.0, 18.0);
                        _mapController.move(
                          _mapController.camera.center,
                          newZoom,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Address overlay (if available)
              if (issue.address != null)
                Positioned(
                  left: Spacing.md,
                  right: Spacing.md,
                  bottom: Spacing.md,
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: colors.primary,
                          size: IconSizes.md,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            issue.address!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(issueDetailProvider(widget.issueId)),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(Radii.sm),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: colors.onSurface),
        ),
      ),
    );
  }
}
