import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../shared/models/issue.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/typography.dart';
import '../../providers/issue_providers.dart';
import '../widgets/widgets.dart';

/// Default center point for the map (Ward 42 - Northcliff)
const _defaultCenter = LatLng(-26.1367, 27.9833);
const _defaultZoom = 14.0;

/// Page showing issues on a map
class IssueMapPage extends ConsumerStatefulWidget {
  const IssueMapPage({super.key});

  @override
  ConsumerState<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends ConsumerState<IssueMapPage> {
  final MapController _mapController = MapController();
  IssueSummary? _selectedIssue;
  GeoPoint? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMarkerTapped(IssueSummary issue) {
    setState(() => _selectedIssue = issue);
    // Animate to the selected issue location
    _mapController.move(
      LatLng(issue.location.latitude, issue.location.longitude),
      _mapController.camera.zoom,
    );
  }

  void _clearSelection() {
    setState(() => _selectedIssue = null);
  }

  Future<void> _goToCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    final locationService = ref.read(locationServiceProvider);
    final location = await locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _isLoadingLocation = false;
      _currentLocation = location;
    });

    if (location != null) {
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        16.0, // Zoom in closer when going to current location
      );
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get current location. Please enable location services.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => locationService.openLocationSettings(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(allIssuesListProvider);
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapViewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.pop(),
            tooltip: 'List View',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map area
          issuesAsync.when(
            data: (issues) => _IssueMap(
              issues: issues,
              mapController: _mapController,
              selectedIssue: _selectedIssue,
              currentLocation: _currentLocation,
              onMarkerTapped: _onMarkerTapped,
            ),
            loading: () => const LoadingSpinner(),
            error: (error, _) => ErrorDisplay(
              error: error,
              onRetry: () => ref.invalidate(allIssuesListProvider),
            ),
          ),

          // Current location button (top right)
          Positioned(
            top: Spacing.md,
            right: Spacing.md,
            child: FloatingActionButton.small(
              heroTag: 'location_btn',
              onPressed: _goToCurrentLocation,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.primary,
              child: _isLoadingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Issue detail card (bottom sheet style)
          if (_selectedIssue != null)
            Positioned(
              left: Spacing.md,
              right: Spacing.md,
              bottom: Spacing.md,
              child: _IssuePreviewCard(
                issue: _selectedIssue!,
                onTap: () => context.push('/issues/${_selectedIssue!.id}'),
                onClose: _clearSelection,
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedIssue == null
          ? FloatingActionButton(
              heroTag: 'report_btn',
              onPressed: () => context.push('/issues/report'),
              child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
  }
}

/// The actual map widget using flutter_map with OpenStreetMap tiles
class _IssueMap extends StatelessWidget {
  final List<IssueSummary> issues;
  final MapController mapController;
  final IssueSummary? selectedIssue;
  final GeoPoint? currentLocation;
  final void Function(IssueSummary) onMarkerTapped;

  const _IssueMap({
    required this.issues,
    required this.mapController,
    required this.selectedIssue,
    required this.currentLocation,
    required this.onMarkerTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate initial center from issues if available
    final center = issues.isNotEmpty
        ? LatLng(
            issues.map((i) => i.location.latitude).reduce((a, b) => a + b) /
                issues.length,
            issues.map((i) => i.location.longitude).reduce((a, b) => a + b) /
                issues.length,
          )
        : _defaultCenter;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _defaultZoom,
        minZoom: 10,
        maxZoom: 18,
        onTap: (_, point) {
          // Clear selection when tapping on map (not on marker)
          // point is available if needed for future use
        },
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.munserv.munserv_mobile',
          maxZoom: 19,
        ),
        // Issue markers
        MarkerLayer(
          markers: [
            // Current location marker (if available)
            if (currentLocation != null)
              Marker(
                point: LatLng(currentLocation!.latitude, currentLocation!.longitude),
                width: 24,
                height: 24,
                child: const _CurrentLocationMarker(),
              ),
            // Issue markers
            ...issues.map((issue) => _buildIssueMarker(issue)),
          ],
        ),
      ],
    );
  }

  Marker _buildIssueMarker(IssueSummary issue) {
    final isSelected = selectedIssue?.id == issue.id;
    final color = HeatColors.fromHeat(issue.heat);

    return Marker(
      point: LatLng(issue.location.latitude, issue.location.longitude),
      width: isSelected ? 48 : 40,
      height: isSelected ? 48 : 40,
      child: GestureDetector(
        onTap: () => onMarkerTapped(issue),
        child: _IssueMarkerIcon(
          issue: issue,
          isSelected: isSelected,
          color: color,
        ),
      ),
    );
  }
}

/// Marker showing current user location
class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Custom marker icon widget for issues
class _IssueMarkerIcon extends StatelessWidget {
  final IssueSummary issue;
  final bool isSelected;
  final Color color;

  const _IssueMarkerIcon({
    required this.issue,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 10 : 8),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.4 : 0.25),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getTypeIcon(issue.type),
        color: Colors.white,
        size: isSelected ? 22 : 18,
      ),
    );
  }

  IconData _getTypeIcon(dynamic type) {
    if (type == null) return Icons.help_outline;
    final typeName = type.toString().split('.').last;
    return switch (typeName) {
      'pothole' => Icons.warning_rounded,
      'waterLeak' => Icons.water_drop,
      'sewageLeak' => Icons.water_damage,
      'trafficLight' => Icons.traffic,
      'streetLight' => Icons.lightbulb,
      'illegalDumping' => Icons.delete,
      _ => Icons.help_outline,
    };
  }
}

/// Card showing issue preview when a marker is selected
class _IssuePreviewCard extends StatelessWidget {
  final IssueSummary issue;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _IssuePreviewCard({
    required this.issue,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: issue.thumbnailUrl != null
                    ? Image.network(
                        issue.thumbnailUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 64,
                          height: 64,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.report_problem_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: IssueTypeBadge(type: issue.type)),
                        const SizedBox(width: Spacing.sm),
                        Flexible(
                            child:
                                IssueStateBadge(state: issue.state, compact: true)),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${issue.location.latitude.toStringAsFixed(4)}, ${issue.location.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Heat and close
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: Spacing.sm),
                  HeatBadge(heat: issue.heat),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
