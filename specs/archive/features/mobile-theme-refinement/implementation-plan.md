# Mobile Theme Refinement - Implementation Plan

**Goal:** Finalize Material Design 3 look and feel with distinctive issue type icons and enhanced visual identity.

**Scope:** Mobile Flutter app (`/mobile`)

**Prerequisites:** Read `mobile/CLAUDE.md` before starting.

---

## Overview

This plan enhances the MunServ mobile app's visual identity while staying within M3 guidelines. Key changes:

1. **Custom Issue Type Icons** - Distinctive icons replacing thumbnail photos in lists
2. **Enhanced Shape System** - More approachable corner radii
3. **Improved Interaction Feedback** - Terracotta-tinted ripples and state layers
4. **Refined Typography** - Bolder headlines for better hierarchy
5. **Polished Components** - Subtle enhancements to cards, badges, and indicators

---

## Task 1: Create Issue Type Icon System

**File:** `mobile/lib/shared/theme/issue_type_icons.dart` (NEW)

Create a centralized icon configuration system with distinctive colors and icons for each issue type.

```dart
import 'package:flutter/material.dart';
import '../models/issue_type.dart';

/// Centralized configuration for issue type visual representation
/// Each issue type has a distinctive icon, color, and optional gradient
class IssueTypeVisuals {
  final IconData icon;
  final IconData filledIcon;
  final Color color;
  final Color lightColor;
  final String semanticLabel;

  const IssueTypeVisuals({
    required this.icon,
    required this.filledIcon,
    required this.color,
    required this.lightColor,
    required this.semanticLabel,
  });

  /// Get visuals for an issue type
  static IssueTypeVisuals forType(IssueType type) => _visuals[type]!;

  static const Map<IssueType, IssueTypeVisuals> _visuals = {
    IssueType.pothole: IssueTypeVisuals(
      icon: Icons.warning_amber_rounded,
      filledIcon: Icons.warning_rounded,
      color: Color(0xFFE65100), // Deep Orange
      lightColor: Color(0xFFFFF3E0),
      semanticLabel: 'Pothole hazard',
    ),
    IssueType.waterLeak: IssueTypeVisuals(
      icon: Icons.water_drop_outlined,
      filledIcon: Icons.water_drop,
      color: Color(0xFF0288D1), // Light Blue
      lightColor: Color(0xFFE1F5FE),
      semanticLabel: 'Water leak',
    ),
    IssueType.sewageLeak: IssueTypeVisuals(
      icon: Icons.waves_outlined,
      filledIcon: Icons.waves,
      color: Color(0xFF5D4037), // Brown
      lightColor: Color(0xFFEFEBE9),
      semanticLabel: 'Sewage leak',
    ),
    IssueType.trafficLight: IssueTypeVisuals(
      icon: Icons.traffic_outlined,
      filledIcon: Icons.traffic,
      color: Color(0xFFC62828), // Red
      lightColor: Color(0xFFFFEBEE),
      semanticLabel: 'Traffic light issue',
    ),
    IssueType.streetLight: IssueTypeVisuals(
      icon: Icons.lightbulb_outline,
      filledIcon: Icons.lightbulb,
      color: Color(0xFFF9A825), // Amber
      lightColor: Color(0xFFFFFDE7),
      semanticLabel: 'Street light issue',
    ),
    IssueType.illegalDumping: IssueTypeVisuals(
      icon: Icons.delete_outline,
      filledIcon: Icons.delete,
      color: Color(0xFF2E7D32), // Green (environmental)
      lightColor: Color(0xFFE8F5E9),
      semanticLabel: 'Illegal dumping',
    ),
    IssueType.roadDamage: IssueTypeVisuals(
      icon: Icons.trending_down_outlined,
      filledIcon: Icons.trending_down,
      color: Color(0xFF37474F), // Blue Grey
      lightColor: Color(0xFFECEFF1),
      semanticLabel: 'Road damage',
    ),
    IssueType.other: IssueTypeVisuals(
      icon: Icons.help_outline,
      filledIcon: Icons.help,
      color: Color(0xFF616161), // Grey
      lightColor: Color(0xFFF5F5F5),
      semanticLabel: 'Other issue',
    ),
  };
}
```

---

## Task 2: Create Large Issue Type Icon Widget

**File:** `mobile/lib/features/issues/presentation/widgets/issue_type_icon.dart` (NEW)

Create a large, distinctive icon widget to replace thumbnails in issue cards.

```dart
import 'package:flutter/material.dart';
import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/issue_type_icons.dart';
import '../../../../shared/theme/typography.dart';

/// Large distinctive icon for issue type display
/// Used in issue cards as an alternative to thumbnail photos
class IssueTypeIcon extends StatelessWidget {
  final IssueType type;
  final double size;
  final bool showBackground;
  final bool filled;

  const IssueTypeIcon({
    super.key,
    required this.type,
    this.size = 56,
    this.showBackground = true,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = IssueTypeVisuals.forType(type);
    final iconSize = size * 0.5;

    if (!showBackground) {
      return Icon(
        filled ? visuals.filledIcon : visuals.icon,
        color: visuals.color,
        size: iconSize,
        semanticLabel: visuals.semanticLabel,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visuals.lightColor,
        borderRadius: BorderRadius.circular(size * 0.25), // Rounded square
        border: Border.all(
          color: visuals.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          filled ? visuals.filledIcon : visuals.icon,
          color: visuals.color,
          size: iconSize,
          semanticLabel: visuals.semanticLabel,
        ),
      ),
    );
  }
}

/// Circular variant for map markers and compact displays
class IssueTypeIconCircle extends StatelessWidget {
  final IssueType type;
  final double size;
  final bool showBorder;

  const IssueTypeIconCircle({
    super.key,
    required this.type,
    this.size = 40,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = IssueTypeVisuals.forType(type);
    final iconSize = size * 0.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visuals.lightColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: visuals.color.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: visuals.color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          visuals.filledIcon,
          color: visuals.color,
          size: iconSize,
        ),
      ),
    );
  }
}
```

---

## Task 3: Update Issue Card to Use Icons

**File:** `mobile/lib/features/issues/presentation/widgets/issue_card.dart` (MODIFY)

Replace the thumbnail image with the new `IssueTypeIcon` widget.

### Changes Required:

1. Import the new `issue_type_icon.dart`
2. Replace the thumbnail `ClipRRect` section (lines 37-64) with `IssueTypeIcon`
3. Adjust layout to accommodate the icon

### New Implementation:

```dart
import 'package:flutter/material.dart';

import '../../../../shared/models/issue.dart';
import '../../../../shared/theme/typography.dart';
import 'heat_indicator.dart';
import 'issue_state_badge.dart';
import 'issue_type_badge.dart';
import 'issue_type_icon.dart'; // ADD THIS IMPORT

/// Card displaying an issue summary in a list
class IssueCard extends StatelessWidget {
  final IssueSummary issue;
  final VoidCallback? onTap;
  final bool showThumbnail; // ADD: Option to show photo thumbnail instead

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.showThumbnail = false, // Default to icon view
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // Use terracotta-tinted splash color
        splashColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
        highlightColor: theme.colorScheme.secondary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Issue Type Icon (replaces thumbnail)
              IssueTypeIcon(
                type: issue.type,
                size: 64,
              ),
              const SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type name and state row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.type.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        IssueStateBadge(state: issue.state, compact: true),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xs),
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
                    const SizedBox(height: Spacing.xs),
                    // Date
                    Text(
                      _formatDate(issue.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Heat indicator
              HeatBadge(heat: issue.heat),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
```

---

## Task 4: Update Issue Type Badge

**File:** `mobile/lib/features/issues/presentation/widgets/issue_type_badge.dart` (MODIFY)

Refactor to use the centralized `IssueTypeVisuals` configuration.

```dart
import 'package:flutter/material.dart';

import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/issue_type_icons.dart';
import '../../../../shared/theme/typography.dart';

/// Badge displaying the issue type with an icon
class IssueTypeBadge extends StatelessWidget {
  final IssueType type;
  final bool showLabel;
  final double? iconSize;

  const IssueTypeBadge({
    super.key,
    required this.type,
    this.showLabel = true,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = IssueTypeVisuals.forType(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? Spacing.sm : Spacing.xs,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: visuals.lightColor,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: visuals.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visuals.filledIcon,
            color: visuals.color,
            size: iconSize ?? 16,
          ),
          if (showLabel) ...[
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                type.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: visuals.color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## Task 5: Enhance Theme - Shapes and Interaction

**File:** `mobile/lib/shared/theme/app_theme.dart` (MODIFY)

### 5.1 Add Custom Shape Definitions

Add at the top of the file, after imports:

```dart
/// M3 Shape Scale with slightly larger radii for approachable feel
class AppShapes {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 16; // Increased from 12
  static const double large = 20;  // Increased from 16
  static const double extraLarge = 28;

  static BorderRadius get extraSmallRadius => BorderRadius.circular(extraSmall);
  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get extraLargeRadius => BorderRadius.circular(extraLarge);
}
```

### 5.2 Update Card Theme (around line 53)

```dart
// Cards - M3: 16dp radius (increased), 1dp elevation, surfaceContainerLow
cardTheme: CardThemeData(
  elevation: 1,
  color: colorScheme.surfaceContainerLow,
  surfaceTintColor: colorScheme.surfaceTint,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppShapes.medium), // 16dp
  ),
  margin: EdgeInsets.zero,
  clipBehavior: Clip.antiAlias,
),
```

### 5.3 Add Ripple/Splash Configuration

Add after the `ThemeData` opening (around line 30):

```dart
// Custom splash factory for terracotta-tinted feedback
splashFactory: InkSparkle.splashFactory,
splashColor: colorScheme.secondary.withValues(alpha: 0.12),
highlightColor: colorScheme.secondary.withValues(alpha: 0.08),
```

### 5.4 Update FAB Theme (around line 192)

Change FAB to use secondary color for accent:

```dart
// FAB - M3: 56dp, 16dp radius, secondary accent for distinction
floatingActionButtonTheme: FloatingActionButtonThemeData(
  backgroundColor: colorScheme.secondary, // Terracotta
  foregroundColor: colorScheme.onSecondary,
  elevation: 3,
  highlightElevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppShapes.large), // 20dp
  ),
  sizeConstraints: const BoxConstraints.tightFor(
    width: 56,
    height: 56,
  ),
),
```

---

## Task 6: Enhance Typography for Bolder Headlines

**File:** `mobile/lib/shared/theme/typography.dart` (MODIFY)

Update headline weights for stronger hierarchy (around lines 40-55):

```dart
// Headline styles - Source Sans 3 (section headers) - BOLDER
headlineLarge: GoogleFonts.sourceSans3(
  fontSize: 32,
  fontWeight: FontWeight.w700, // Changed from w600
  color: baseColor,
),
headlineMedium: GoogleFonts.sourceSans3(
  fontSize: 28,
  fontWeight: FontWeight.w700, // Changed from w600
  color: baseColor,
),
headlineSmall: GoogleFonts.sourceSans3(
  fontSize: 24,
  fontWeight: FontWeight.w700, // Changed from w600
  color: baseColor,
),
```

---

## Task 7: Update Widgets Barrel Export

**File:** `mobile/lib/features/issues/presentation/widgets/widgets.dart` (MODIFY)

Add export for the new widget:

```dart
export 'heat_indicator.dart';
export 'issue_card.dart';
export 'issue_filter_bar.dart';
export 'issue_state_badge.dart';
export 'issue_type_badge.dart';
export 'issue_type_icon.dart'; // ADD THIS LINE
```

---

## Task 8: Update Report Issue Page Icons

**File:** `mobile/lib/features/issues/presentation/pages/report_issue_page.dart` (MODIFY)

Update the issue type selection grid to use the new icon widgets for consistency.

Find the issue type selection section and update to use `IssueTypeIcon`:

```dart
// In the issue type selection GridView
GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  mainAxisSpacing: Spacing.md,
  crossAxisSpacing: Spacing.md,
  childAspectRatio: 1.5,
  children: IssueType.values.map((type) {
    final isSelected = selectedType == type;
    final visuals = IssueTypeVisuals.forType(type);

    return InkWell(
      onTap: () => onTypeSelected(type),
      borderRadius: BorderRadius.circular(AppShapes.medium),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? visuals.color.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShapes.medium),
          border: Border.all(
            color: isSelected ? visuals.color : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IssueTypeIcon(
              type: type,
              size: 48,
              showBackground: false,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              type.displayName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? visuals.color : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }).toList(),
),
```

---

## Task 9: Add Empty State Illustrations

**File:** `mobile/lib/shared/widgets/empty_state.dart` (NEW)

Create a reusable empty state widget with themed illustrations:

```dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Empty state widget with themed illustration
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  /// No issues found empty state
  factory EmptyState.noIssues({VoidCallback? onReport}) {
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: 'No issues found',
      subtitle: 'There are no issues matching your filters.\nBe the first to report one!',
      iconColor: const Color(0xFF4CAF50),
      action: onReport != null
          ? FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }

  /// No reports from user
  factory EmptyState.noReports({VoidCallback? onReport}) {
    return EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No reports yet',
      subtitle: 'You haven\'t reported any issues yet.\nHelp improve your community!',
      action: onReport != null
          ? FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }

  /// Network error state
  factory EmptyState.networkError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Connection lost',
      subtitle: 'Please check your internet connection and try again.',
      iconColor: const Color(0xFFFF9800),
      action: onRetry != null
          ? OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with decorative background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: effectiveIconColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: Spacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Task 10: Run Code Generation and Tests

After all changes are complete, run:

```bash
cd /home/marsel/munserv/mobile

# Generate Freezed/Riverpod code (if any models changed)
dart run build_runner build --delete-conflicting-outputs

# Run static analysis
flutter analyze

# Run tests
flutter test

# Build to verify no compilation errors
flutter build apk --debug
```

---

## Files Summary

| Action | File Path |
|--------|-----------|
| CREATE | `lib/shared/theme/issue_type_icons.dart` |
| CREATE | `lib/features/issues/presentation/widgets/issue_type_icon.dart` |
| CREATE | `lib/shared/widgets/empty_state.dart` |
| MODIFY | `lib/features/issues/presentation/widgets/issue_card.dart` |
| MODIFY | `lib/features/issues/presentation/widgets/issue_type_badge.dart` |
| MODIFY | `lib/features/issues/presentation/widgets/widgets.dart` |
| MODIFY | `lib/features/issues/presentation/pages/report_issue_page.dart` |
| MODIFY | `lib/shared/theme/app_theme.dart` |
| MODIFY | `lib/shared/theme/typography.dart` |

---

## Visual Summary

### Before vs After - Issue Card

```
BEFORE:                           AFTER:
┌─────────────────────────┐      ┌─────────────────────────┐
│ ┌─────┐ Pothole  [Rep]  │      │ ┌─────┐ Pothole   [Rep] │
│ │photo│ 📍 -26.1, 28.0  │  →   │ │  ⚠  │ 📍 -26.1, 28.0  │
│ │     │ 2h ago     🔥75 │      │ └─────┘ 2h ago     🔥75 │
│ └─────┘                 │      │ (orange bg, icon)       │
└─────────────────────────┘      └─────────────────────────┘
```

### Icon Style per Type

| Type | Icon | Color |
|------|------|-------|
| Pothole | `warning_rounded` | Deep Orange #E65100 |
| Water Leak | `water_drop` | Light Blue #0288D1 |
| Sewage Leak | `waves` | Brown #5D4037 |
| Traffic Light | `traffic` | Red #C62828 |
| Street Light | `lightbulb` | Amber #F9A825 |
| Illegal Dumping | `delete` | Green #2E7D32 |
| Road Damage | `trending_down` | Blue Grey #37474F |
| Other | `help` | Grey #616161 |

---

## Definition of Done

- [x] All 3 new files created
- [x] All 6 modified files updated
- [x] `flutter analyze` passes with no errors
- [x] `flutter test` passes
- [x] App builds successfully
- [x] Issue list displays icons instead of thumbnails
- [x] FAB uses terracotta color
- [x] Cards have 16dp corner radius
- [x] Headlines are bolder (weight 700)
