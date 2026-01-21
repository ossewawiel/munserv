# Feature: Issue Details Screen Enhancement

## Overview

Enhance the mobile Issue Details screen with an interactive map, photo carousel, and comprehensive issue information in a scrollable layout.

**Platform:** Mobile (Flutter)
**Priority:** High
**Status:** 🔴 Pending (Mobile - ready for implementation)

---

## User Stories

### M-DETAILS-1: View Issue Location on Map
**As a** member viewing an issue
**I want to** see a map showing the exact location
**So that** I can understand where the problem is located

**Acceptance Criteria:**
- Rectangular map preview (16:10 aspect ratio) shows issue location with marker
- Map has thin border matching card styling
- Map is non-interactive in preview mode (no accidental scrolling)
- "Tap to expand" button with primary color styling for easy tapping
- Tapping map opens fullscreen view

### M-DETAILS-2: Fullscreen Map View
**As a** member viewing an issue
**I want to** expand the map to fullscreen
**So that** I can zoom and pan to see the surrounding area

**Acceptance Criteria:**
- Fullscreen map with zoom controls (+/- buttons)
- Pinch-to-zoom gesture support
- Pan/drag to move around map
- Back button returns to issue details
- Orange app header with "Location" title

### M-DETAILS-3: View Issue Photos
**As a** member viewing an issue
**I want to** see all photos in a horizontal carousel
**So that** I can quickly browse the visual evidence

**Acceptance Criteria:**
- Horizontal scrolling thumbnail carousel
- Thumbnail size ~120px height
- Page indicator dots showing current position
- Smooth scroll animation

### M-DETAILS-4: Fullscreen Photo Gallery
**As a** member viewing an issue
**I want to** view photos in fullscreen
**So that** I can see details clearly

**Acceptance Criteria:**
- Tapping any thumbnail opens fullscreen gallery at that photo
- Swipe left/right to navigate between photos
- Photo counter "1 of 5" in app bar
- Pinch-to-zoom on individual photos
- Back button returns to issue details
- Orange app header maintained

### M-DETAILS-5: View Status Timeline
**As a** member viewing an issue
**I want to** see the complete status history
**So that** I can track progress on the issue

**Acceptance Criteria:**
- Vertical timeline with colored state indicators
- Each entry shows: state name, timestamp, optional note
- Colors match issue state colors (reported=orange, confirmed=blue, etc.)
- Most recent state at bottom (chronological order)

---

## Architecture Reference

### Layer Architecture (from `mobile/CLAUDE.md`)

```
Presentation (UI) → Providers (State) → Repository (Data) → API (Network)
```

| Layer | Responsibility | Pattern |
|-------|----------------|---------|
| Presentation | Widgets, pages | `StatelessWidget` for pure UI, `ConsumerWidget` for data |
| Providers | State management | Riverpod `@riverpod` annotation |
| Repository | Data operations | `Result<T>` pattern |
| API | HTTP calls | Dio client |

### When to Use Which Widget Type

| Type | Use When | Example |
|------|----------|---------|
| `StatelessWidget` | Pure presentation, no provider access | `IssueLocationMap`, `PhotoThumbnailCarousel` |
| `ConsumerWidget` | Needs to read providers | `FullscreenMapPage`, `PhotoGalleryPage` |
| `ConsumerStatefulWidget` | Needs providers + local state (PageController, etc.) | `PhotoGalleryPage` if tracking page index |

### Folder Structure

New files follow this structure:

```
lib/
├── shared/
│   └── widgets/
│       ├── issue_location_map.dart      ← NEW (shared, reusable)
│       └── photo_thumbnail_carousel.dart ← NEW (shared, reusable)
├── features/
│   └── issues/
│       └── presentation/
│           ├── pages/
│           │   ├── issue_detail_page.dart      ← MODIFY
│           │   ├── fullscreen_map_page.dart    ← NEW
│           │   └── photo_gallery_page.dart     ← NEW
│           └── widgets/
│               └── issue_timeline.dart          ← NEW (extract from detail page)
└── routing/
    └── app_router.dart                          ← MODIFY
```

---

## Styling Reference

### Required Imports for All New Files

```dart
// For shared widgets
import '../theme/typography.dart';  // Spacing, Radii, IconSizes, ThumbnailSizes

// For feature widgets/pages
import '../../../../shared/theme/typography.dart';
import '../../../../shared/theme/colors.dart';  // IssueStateColors, HeatColors

// For pages using BrandedScaffold
import '../../../../shared/widgets/branded_scaffold.dart';
```

### Spacing Constants (from `shared/theme/typography.dart`)

```dart
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

**Usage:**
```dart
// ✅ CORRECT
SizedBox(height: Spacing.md)
EdgeInsets.all(Spacing.md)
EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm)

// ❌ WRONG - Magic numbers forbidden
SizedBox(height: 16)
EdgeInsets.all(16)
```

### Border Radius Constants (from `shared/theme/typography.dart`)

```dart
class Radii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}
```

**Usage:**
```dart
// ✅ CORRECT
ClipRRect(borderRadius: BorderRadius.circular(Radii.md), ...)
BorderRadius.circular(Radii.sm)

// ❌ WRONG
BorderRadius.circular(8)
```

### Icon Sizes (from `shared/theme/typography.dart`)

```dart
abstract class IconSizes {
  static const double xs = 12;      // Inline indicators
  static const double sm = 16;      // Dense UI elements
  static const double md = 24;      // Default Material icon size
  static const double lg = 32;      // Prominent actions
  static const double xl = 48;      // Feature icons, MAP MARKERS
  static const double xxl = 64;     // Card leading icons
  static const double display = 80; // Empty state illustrations
}
```

**Usage for map marker:**
```dart
Icon(
  Icons.location_pin,
  size: IconSizes.xl,  // 48 - for map markers
  color: colors.primary,
)
```

### Thumbnail Sizes (from `shared/theme/typography.dart`)

```dart
abstract class ThumbnailSizes {
  static const double sm = 48;   // Compact avatars
  static const double md = 64;   // Card thumbnails
  static const double lg = 100;  // Photo picker tiles
  static const double xl = 120;  // Preview images - USE FOR CAROUSEL
}
```

### Theme Colors (from `shared/theme/colors.dart`)

**Getting colors in build method:**
```dart
@override
Widget build(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  // Use colors.* for all color references
  colors.primary            // Forest green - primary actions, markers
  colors.secondary          // Terracotta - accents
  colors.surface            // Card backgrounds
  colors.onSurface          // Primary text
  colors.onSurfaceVariant   // Secondary text
  colors.outlineVariant     // Borders, dividers
  colors.surfaceContainerHighest // Error placeholder backgrounds
}
```

### Issue State Colors (for timeline)

```dart
import '../../../../shared/theme/colors.dart';

// Get color for a state
IssueStateColors.fromState('reported')    // Orange: 0xFFFF9800
IssueStateColors.fromState('confirmed')   // Blue: 0xFF2196F3
IssueStateColors.fromState('in_progress') // Purple: 0xFF9C27B0
IssueStateColors.fromState('fixed')       // Green: 0xFF4CAF50
IssueStateColors.fromState('rejected')    // Gray: 0xFF9E9E9E

// Direct access
IssueStateColors.reported   // Orange
IssueStateColors.confirmed  // Blue
IssueStateColors.inProgress // Purple
IssueStateColors.fixed      // Green
IssueStateColors.rejected   // Gray
```

### Card Styling Standard (CRITICAL)

All cards MUST use this exact styling:

```dart
Card(
  elevation: 0,                              // No shadow
  color: colors.surface,                     // Match AppBar background
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),  // 8dp
    side: BorderSide(color: colors.outlineVariant), // Visible border
  ),
  child: ...
)
```

**Why:**
- `elevation: 0` removes shadow AND surface tint overlay
- `colors.surface` matches the AppBar header strip
- Visible border provides clear card boundaries

---

## Screen Layout

```
┌────────────────────────────────────────┐
│ [←] [🔧] Pothole           [Reported] │  ← AppBar: type icon + name, state badge
├────────────────────────────────────────┤
│                                        │
│  ┌────────────────────────────────┐   │
│  │                                │   │  16:10 aspect ratio
│  │        RECTANGULAR MAP         │   │  Thin border (outlineVariant)
│  │    📍 Issue marker             │   │  Tap → FullscreenMapPage
│  │            [Tap to expand]     │   │  Large button for easy tapping
│  └────────────────────────────────┘   │
│                                        │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │  ThumbnailSizes.xl (120px)
│  │ 📷 1│ │ 📷 2│ │ 📷 3│ │ 📷 4│ ...  │  Tap → PhotoGalleryPage
│  └─────┘ └─────┘ └─────┘ └─────┘      │
│                                        │
│  📝 Description                        │
│  Large pothole near the intersection...│
│                                        │
│  ┌─────────────┐ ┌─────────────┐      │
│  │ 👥 Reports  │ │ 🔥 Heat     │      │  Stat cards with border
│  │     12      │ │     75      │      │  elevation: 0, surface color
│  └─────────────┘ └─────────────┘      │
│                                        │
│  ─────── Status History ────────      │
│  ● Reported    Jan 12, 10:30          │
│  │                                     │
│  ● Confirmed   Jan 13, 14:15          │
│             "Verified by field team"   │
│                                        │
└────────────────────────────────────────┘
          ↕ Scrollable ↕
```

**AppBar Design:**
- Issue type icon with rounded square background (32dp, monochrome primary color)
- Issue type display name as title
- State badge positioned in actions area
- `titleSpacing: 0` for tighter alignment

---

## Routes

| Route | Page | Parameters |
|-------|------|------------|
| `/issues/:id` | `IssueDetailPage` | `id` (path) |
| `/issues/:id/map` | `FullscreenMapPage` | `id` (path) |
| `/issues/:id/photos` | `PhotoGalleryPage` | `id` (path), `index` (query, default 0) |

### Navigation Code

```dart
import 'package:go_router/go_router.dart';

// From issue detail to fullscreen map
context.push('/issues/${issue.id}/map');

// From issue detail to photo gallery (starting at photo index 2)
context.push('/issues/${issue.id}/photos?index=2');

// Back to issue detail
context.pop();
```

---

## Data Requirements

### IssueDetail Model (existing in `lib/features/issues/domain/state_history.dart`)

```dart
@freezed
abstract class IssueDetail with _$IssueDetail {
  const IssueDetail._();  // Private constructor for convenience getters

  const factory IssueDetail({
    required String id,
    required String type,
    required String state,
    required GeoPoint location,    // ← Nested location object from API
    String? address,               // ← For display
    String? description,
    required int heat,
    required List<String> photoUrls,  // ← For carousel/gallery
    required String sectorId,
    required String reporterId,
    required int reportCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<StateHistoryEntry> stateHistory,  // ← For timeline
  }) = _IssueDetail;

  // Convenience getters for map usage
  double get latitude => location.latitude;
  double get longitude => location.longitude;
}
```

### StateHistoryEntry Model (existing)

```dart
@freezed
abstract class StateHistoryEntry with _$StateHistoryEntry {
  const factory StateHistoryEntry({
    required IssueState state,
    required DateTime changedAt,
    String? changedBy,
    String? note,
  }) = _StateHistoryEntry;
}
```

### Existing Provider (use this to get issue data)

```dart
// In lib/features/issues/providers/issue_providers.dart
@riverpod
Future<IssueDetail> issueDetail(IssueDetailRef ref, String issueId) async {
  // Already implemented - fetches from API
}

// Usage in pages:
final issueAsync = ref.watch(issueDetailProvider(issueId));
```

---

## Dependencies

### Required Packages

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `flutter_map` | ^7.0.2 | Map rendering | ✅ Installed |
| `latlong2` | ^0.9.1 | Coordinate handling | ✅ Installed |
| `photo_view` | ^0.15.0 | Pinch-to-zoom for photos | ⚠️ **Add** |
| `go_router` | - | Navigation | ✅ Installed |

### Add photo_view

```bash
cd /home/marsel/munserv/mobile
flutter pub add photo_view
flutter pub get
```

---

## Implementation Details

### 1. IssueLocationMap Widget

**Location:** `lib/shared/widgets/issue_location_map.dart`

**Type:** `StatelessWidget` (pure presentation, no provider access needed)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/typography.dart';

/// Square map preview showing a single location marker.
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

  /// Size of the map (width and height, since it's square).
  /// Defaults to filling available width with 1:1 aspect ratio.
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
          aspectRatio: 1, // Square
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
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
                // Tap indicator overlay
                if (onTap != null)
                  Positioned(
                    bottom: Spacing.sm,
                    right: Spacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fullscreen,
                            size: IconSizes.sm,
                            color: colors.onSurface,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            'Tap to expand',
                            style: Theme.of(context).textTheme.labelSmall,
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
    );
  }
}
```

### 2. PhotoThumbnailCarousel Widget

**Location:** `lib/shared/widgets/photo_thumbnail_carousel.dart`

**Type:** `StatelessWidget` (pure presentation)

```dart
import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Horizontal scrolling carousel of photo thumbnails.
/// Each thumbnail is tappable to open fullscreen gallery.
///
/// Usage:
/// ```dart
/// PhotoThumbnailCarousel(
///   photoUrls: issue.photoUrls,
///   onPhotoTap: (index) => context.push(
///     '/issues/${issue.id}/photos?index=$index',
///   ),
/// )
/// ```
class PhotoThumbnailCarousel extends StatelessWidget {
  /// List of photo URLs to display.
  final List<String> photoUrls;

  /// Called when a photo is tapped. Receives the index of the tapped photo.
  final void Function(int index)? onPhotoTap;

  /// Height of the thumbnails. Defaults to ThumbnailSizes.xl (120).
  final double thumbnailHeight;

  const PhotoThumbnailCarousel({
    super.key,
    required this.photoUrls,
    this.onPhotoTap,
    this.thumbnailHeight = ThumbnailSizes.xl,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: thumbnailHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: photoUrls.length,
        itemBuilder: (context, index) {
          final isLast = index == photoUrls.length - 1;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : Spacing.sm),
            child: GestureDetector(
              onTap: () => onPhotoTap?.call(index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: AspectRatio(
                  aspectRatio: 1, // Square thumbnails
                  child: Image.network(
                    photoUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: colors.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: colors.onSurfaceVariant,
                        size: IconSizes.lg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### 3. FullscreenMapPage

**Location:** `lib/features/issues/presentation/pages/fullscreen_map_page.dart`

**Type:** `ConsumerWidget` (needs provider to get issue data)

```dart
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
                    if (position.zoom != null) {
                      setState(() => _currentZoom = position.zoom!);
                    }
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
```

### 4. PhotoGalleryPage

**Location:** `lib/features/issues/presentation/pages/photo_gallery_page.dart`

**Type:** `ConsumerStatefulWidget` (needs provider + PageController state)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../providers/issue_providers.dart';

/// Fullscreen photo gallery with swipe navigation and pinch-to-zoom.
class PhotoGalleryPage extends ConsumerStatefulWidget {
  final String issueId;
  final int initialIndex;

  const PhotoGalleryPage({
    super.key,
    required this.issueId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends ConsumerState<PhotoGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(issueDetailProvider(widget.issueId));
    final colors = Theme.of(context).colorScheme;

    return BrandedScaffold(
      showMapBackground: false,
      appBar: AppBar(
        title: issueAsync.whenData(
          (issue) => Text('${_currentIndex + 1} of ${issue.photoUrls.length}'),
        ).value ?? const Text('Photos'),
      ),
      body: issueAsync.when(
        data: (issue) {
          if (issue.photoUrls.isEmpty) {
            return Center(
              child: Text(
                'No photos available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: issue.photoUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(issue.photoUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: IconSizes.display,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Failed to load image',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event?.expectedTotalBytes != null
                    ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                    : null,
              ),
            ),
            backgroundDecoration: BoxDecoration(color: colors.surface),
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
```

### 5. IssueTimeline Widget

**Location:** `lib/features/issues/presentation/widgets/issue_timeline.dart`

**Extract from existing `_StateHistoryList` in `issue_detail_page.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/typography.dart';
import '../../domain/state_history.dart';

/// Vertical timeline showing issue state history.
/// Displays colored dots for each state with timestamps and optional notes.
class IssueTimeline extends StatelessWidget {
  final List<StateHistoryEntry> history;

  const IssueTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      children: history.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == history.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: IssueStateColors.fromState(item.state.name),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: Spacing.sm),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.state.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDateTime(item.changedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      if (item.note != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          item.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (item.changedBy != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'by ${item.changedBy}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
```

### 6. Updated IssueDetailPage Structure

**Modify:** `lib/features/issues/presentation/pages/issue_detail_page.dart`

Key changes to `_IssueDetailContent`:

```dart
// Add imports at top of file
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/issue_location_map.dart';
import '../../../../shared/widgets/photo_thumbnail_carousel.dart';
import '../widgets/issue_timeline.dart';

// Replace build method of _IssueDetailContent
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.md),

        // NEW: Map preview
        IssueLocationMap(
          latitude: issue.latitude,
          longitude: issue.longitude,
          onTap: () => context.push('/issues/${issue.id}/map'),
        ),

        const SizedBox(height: Spacing.md),

        // NEW: Photo carousel (replaces old _PhotoCarousel)
        PhotoThumbnailCarousel(
          photoUrls: issue.photoUrls,
          onPhotoTap: (index) => context.push(
            '/issues/${issue.id}/photos?index=$index',
          ),
        ),

        // Main content padding
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type and State badges (existing)
              Row(
                children: [
                  IssueTypeBadge(type: IssueType.fromString(issue.type)),
                  const SizedBox(width: Spacing.sm),
                  IssueStateBadge(state: IssueState.fromString(issue.state)),
                  const Spacer(),
                  HeatIndicator(heat: issue.heat),
                ],
              ),
              const SizedBox(height: Spacing.lg),

              // Location info (existing _InfoSection)
              _InfoSection(
                icon: Icons.location_on,
                title: 'Location',
                content: issue.address ??
                    '${issue.latitude.toStringAsFixed(6)}, ${issue.longitude.toStringAsFixed(6)}',
              ),

              // Description (existing)
              if (issue.description != null) ...[
                const SizedBox(height: Spacing.md),
                _InfoSection(
                  icon: Icons.description,
                  title: 'Description',
                  content: issue.description!,
                ),
              ],

              // Stats (existing)
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      label: 'Reports',
                      value: issue.reportCount.toString(),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      label: 'Heat',
                      value: issue.heat.toString(),
                      color: HeatColors.fromHeat(issue.heat),
                    ),
                  ),
                ],
              ),

              // Timestamps (existing)
              const SizedBox(height: Spacing.lg),
              _TimestampInfo(
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt,
              ),

              // State history - NOW USING EXTRACTED WIDGET
              if (issue.stateHistory.isNotEmpty) ...[
                const SizedBox(height: Spacing.lg),
                Text('Status History', style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                IssueTimeline(history: issue.stateHistory),
              ],

              // Bottom padding
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### 7. Router Updates

**Modify:** `lib/routing/app_router.dart`

Add imports:
```dart
import '../features/issues/presentation/pages/fullscreen_map_page.dart';
import '../features/issues/presentation/pages/photo_gallery_page.dart';
```

Add routes after existing `/issues/:id` route (around line 158):

```dart
// Existing route
GoRoute(
  path: '/issues/:id',
  name: 'issueDetail',
  builder: (context, state) {
    final id = state.pathParameters['id'];
    assert(id != null, 'Issue ID is required');
    return IssueDetailPage(issueId: id ?? '');
  },
),

// NEW: Fullscreen map route
GoRoute(
  path: '/issues/:id/map',
  name: 'issueMap',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return FullscreenMapPage(issueId: id);
  },
),

// NEW: Photo gallery route
GoRoute(
  path: '/issues/:id/photos',
  name: 'issuePhotos',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final indexStr = state.uri.queryParameters['index'] ?? '0';
    final index = int.tryParse(indexStr) ?? 0;
    return PhotoGalleryPage(issueId: id, initialIndex: index);
  },
),
```

---

## Testing Requirements

### Test File Locations

```
test/
├── shared/
│   └── widgets/
│       ├── issue_location_map_test.dart      ← NEW
│       └── photo_thumbnail_carousel_test.dart ← NEW
└── features/
    └── issues/
        └── presentation/
            ├── pages/
            │   ├── fullscreen_map_page_test.dart  ← NEW
            │   └── photo_gallery_page_test.dart   ← NEW
            └── widgets/
                └── issue_timeline_test.dart       ← NEW
```

### Test Pattern (follow existing tests)

Reference: `test/shared/widgets/empty_state_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munserv_mobile/shared/widgets/issue_location_map.dart';

void main() {
  group('IssueLocationMap', () {
    testWidgets('renders map widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
            ),
          ),
        ),
      );

      expect(find.byType(IssueLocationMap), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IssueLocationMap));
      expect(tapped, isTrue);
    });

    testWidgets('shows expand hint when onTap provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tap to expand'), findsOneWidget);
    });

    testWidgets('hides expand hint when no onTap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
            ),
          ),
        ),
      );

      expect(find.text('Tap to expand'), findsNothing);
    });
  });
}
```

### PhotoThumbnailCarousel Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munserv_mobile/shared/widgets/photo_thumbnail_carousel.dart';

void main() {
  group('PhotoThumbnailCarousel', () {
    testWidgets('renders nothing when photoUrls is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(photoUrls: []),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders thumbnails for each photo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: [
                'https://example.com/1.jpg',
                'https://example.com/2.jpg',
                'https://example.com/3.jpg',
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsNWidgets(3));
    });

    testWidgets('calls onPhotoTap with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: [
                'https://example.com/1.jpg',
                'https://example.com/2.jpg',
              ],
              onPhotoTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      // Tap the first photo
      await tester.tap(find.byType(GestureDetector).first);
      expect(tappedIndex, equals(0));
    });
  });
}
```

---

## Quality Gates

Run these commands after implementation:

```bash
cd /home/marsel/munserv/mobile

# 1. Generate code (if any freezed/riverpod changes)
dart run build_runner build --delete-conflicting-outputs

# 2. Static analysis
flutter analyze

# 3. Run all tests
flutter test

# 4. Run specific new tests
flutter test test/shared/widgets/issue_location_map_test.dart
flutter test test/shared/widgets/photo_thumbnail_carousel_test.dart
flutter test test/features/issues/presentation/widgets/issue_timeline_test.dart

# 5. Format code
dart format lib/shared/widgets/issue_location_map.dart
dart format lib/shared/widgets/photo_thumbnail_carousel.dart
dart format lib/features/issues/presentation/pages/fullscreen_map_page.dart
dart format lib/features/issues/presentation/pages/photo_gallery_page.dart
dart format lib/features/issues/presentation/widgets/issue_timeline.dart
```

---

## Definition of Done

- [ ] `flutter pub add photo_view` executed
- [ ] `IssueLocationMap` widget created with tests
- [ ] `PhotoThumbnailCarousel` widget created with tests
- [ ] `FullscreenMapPage` created with tests
- [ ] `PhotoGalleryPage` created with tests
- [ ] `IssueTimeline` extracted with tests
- [ ] `IssueDetailPage` updated with new layout
- [ ] Routes added to `app_router.dart`
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` passes
- [ ] Manual test: map tap → fullscreen → zoom → back works
- [ ] Manual test: photo tap → gallery → swipe → zoom → back works
- [ ] No hardcoded colors (use `colors.*` from theme)
- [ ] No magic numbers (use `Spacing.*`, `Radii.*`, `IconSizes.*`, `ThumbnailSizes.*`)
- [ ] Card styling follows standard (`elevation: 0`, `colors.surface`, `outlineVariant` border)
