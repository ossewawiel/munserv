import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/theme/typography.dart';

/// Step widget for selecting/confirming location in issue reporting flow
class LocationStep extends StatefulWidget {
  final GeoPoint? location;
  final void Function(GeoPoint) onLocationChanged;

  const LocationStep({
    super.key,
    required this.location,
    required this.onLocationChanged,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _isLoading = false;
  String? _errorMessage;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    if (widget.location == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();

      if (!mounted) return;

      if (location != null) {
        widget.onLocationChanged(location);
        setState(() => _isLoading = false);
      } else {
        // Permission denied or service disabled
        setState(() {
          _isLoading = false;
          _errorMessage = S.of(context).locationPermissionDenied;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = S.of(context).locationError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = widget.location;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirm Location',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'We\'ll use your current location. You can adjust if needed.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Map placeholder
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: _buildMapContent(theme, location),
          ),

          const SizedBox(height: Spacing.md),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],

          // Refresh location button
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _getCurrentLocation,
            icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(_isLoading ? 'Getting Location...' : 'Refresh Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(ThemeData theme, GeoPoint? location) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (location == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Location unavailable',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Map preview',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: Spacing.md,
          left: Spacing.md,
          right: Spacing.md,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
