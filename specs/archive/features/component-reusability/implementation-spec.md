# Mobile Component Reusability - Implementation Specification

**Feature:** Component Reusability Refactoring
**Platform:** Mobile (Flutter)
**Priority:** High
**Estimated Effort:** 8-12 hours

## Overview

Refactor mobile Flutter components for consistency, reusability, and Material 3 compliance. This addresses inconsistent card widths, duplicate empty state implementations, magic number usage, and fragmented widget patterns.

## Goals

1. **Consistent Issue Cards** - All issue list items render at full available width
2. **Unified Empty States** - Single `EmptyState` widget with factory constructors
3. **Sizing Constants** - Replace all magic numbers with `Spacing`, `IconSizes`, `ThumbnailSizes`
4. **Reusable Components** - Extract private widgets to shared library
5. **M3 Compliance** - Proper theme usage, no hardcoded colors or opacity hacks
6. **Consistent Card Styling** - All cards use `surface` color, `elevation: 0`, and `outlineVariant` border

---

## Phase 1: Sizing Constants Foundation

### 1.1 Add IconSizes and ThumbnailSizes Constants

**File:** `lib/shared/theme/typography.dart`

**Add after existing `Spacing` class:**

```dart
/// Standard icon sizes following M3 specifications.
abstract class IconSizes {
  /// Extra small icons (12dp) - Inline indicators
  static const double xs = 12;

  /// Small icons (16dp) - Dense UI elements
  static const double sm = 16;

  /// Medium icons (24dp) - Default Material icon size
  static const double md = 24;

  /// Large icons (32dp) - Prominent actions
  static const double lg = 32;

  /// Extra large icons (48dp) - Feature icons, map markers
  static const double xl = 48;

  /// Double extra large icons (64dp) - Card leading icons
  static const double xxl = 64;

  /// Display icons (80dp) - Empty state illustrations
  static const double display = 80;
}

/// Standard thumbnail/image sizes.
abstract class ThumbnailSizes {
  /// Small thumbnails (48dp) - Compact avatars
  static const double sm = 48;

  /// Medium thumbnails (64dp) - Card thumbnails, standard avatars
  static const double md = 64;

  /// Large thumbnails (100dp) - Photo picker tiles
  static const double lg = 100;

  /// Extra large thumbnails (120dp) - Preview images
  static const double xl = 120;
}
```

### 1.2 Verification

After adding, run:
```bash
flutter analyze lib/shared/theme/typography.dart
```

---

## Card Styling Standard

All cards in the app MUST use consistent styling to match the visual design:

### Required Card Properties

```dart
Card(
  elevation: 0,                              // No shadow or surface tint
  color: colors.surface,                     // Same as AppBar background (#FAF9F7)
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    side: BorderSide(color: colors.outlineVariant),  // Visible border
  ),
  child: ...
)
```

### Property Reference

| Property | Value | Reason |
|----------|-------|--------|
| `elevation` | `0` | Removes shadow and M3 surface tint overlay |
| `color` | `colors.surface` | Matches AppBar header strip background |
| `shape.borderRadius` | `Radii.md` | Consistent rounded corners (16dp) |
| `shape.side` | `colors.outlineVariant` | Distinct visible border for separation from map overlay |

### Why Not Default Card Styling?

The default M3 `Card` has:
- `elevation: 1` which applies a `surfaceTint` overlay that makes the card appear slightly different from the AppBar
- No border, making cards blend into the semi-transparent map background

By using `elevation: 0` and an explicit border, cards match the AppBar background exactly and stand out clearly from the map overlay.

### Cards This Applies To

- `IssueCard` (all variants: list, mapPreview, compact)
- `QuickActionCard` (home page action buttons)
- `_UserInfoCard` (profile page)
- `_SettingsItem` (profile page settings items)
- Any new card widgets added to the app

---

## Phase 2: IssueCard Consolidation

### 2.1 Current State Analysis

**Problem:** Two separate implementations exist:
- `IssueCard` in `lib/features/issues/presentation/widgets/issue_card.dart` - Uses icon (64dp)
- `_IssuePreviewCard` in `lib/features/issues/presentation/pages/issue_map_page.dart` (lines 354-468) - Uses thumbnail

**Impact:** Visual inconsistency between list view and map preview.

### 2.2 Implementation Steps

#### Step 2.2.1: Add Variant Enum

**File:** `lib/features/issues/presentation/widgets/issue_card.dart`

Add at top of file after imports:

```dart
/// Display variants for [IssueCard].
enum IssueCardVariant {
  /// Full-width card with large icon. Used in issue lists, my reports, home page.
  list,

  /// Compact card with thumbnail image. Used in map bottom sheet.
  mapPreview,

  /// Minimal card for constrained spaces.
  compact,
}
```

#### Step 2.2.2: Update IssueCard Class

**File:** `lib/features/issues/presentation/widgets/issue_card.dart`

Replace existing `IssueCard` class with:

```dart
/// Displays an issue summary in a card format.
///
/// Supports multiple display variants:
/// - [IssueCardVariant.list] - Full-width with icon (default)
/// - [IssueCardVariant.mapPreview] - Compact with thumbnail and close button
/// - [IssueCardVariant.compact] - Minimal information
///
/// ## Usage
/// ```dart
/// // In issue list
/// IssueCard(issue: issue, onTap: () => viewDetail(issue.id))
///
/// // In map bottom sheet
/// IssueCard(
///   issue: issue,
///   variant: IssueCardVariant.mapPreview,
///   onTap: () => viewDetail(issue.id),
///   onClose: () => clearSelection(),
/// )
/// ```
class IssueCard extends StatelessWidget {
  /// The issue to display.
  final IssueSummary issue;

  /// Display variant. Defaults to [IssueCardVariant.list].
  final IssueCardVariant variant;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when close button is tapped (mapPreview variant only).
  final VoidCallback? onClose;

  const IssueCard({
    super.key,
    required this.issue,
    this.variant = IssueCardVariant.list,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      IssueCardVariant.list => _buildListVariant(context),
      IssueCardVariant.mapPreview => _buildMapPreviewVariant(context),
      IssueCardVariant.compact => _buildCompactVariant(context),
    };
  }

  Widget _buildListVariant(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        splashColor: colors.secondary.withValues(alpha: 0.1),
        highlightColor: colors.secondary.withValues(alpha: 0.05),
        child: Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              // Issue type icon
              IssueTypeIcon(
                type: issue.type,
                size: IconSizes.xxl,
              ),
              SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type and state row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.type.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IssueStateBadge(state: issue.state, compact: true),
                      ],
                    ),
                    SizedBox(height: Spacing.xs),
                    // Location
                    if (issue.location != null)
                      Text(
                        '${issue.location!.latitude.toStringAsFixed(4)}, ${issue.location!.longitude.toStringAsFixed(4)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    SizedBox(height: Spacing.xs),
                    // Date
                    Text(
                      _formatRelativeDate(issue.reportedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Spacing.sm),
              // Heat badge
              HeatBadge(heat: issue.heat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreviewVariant(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.all(Spacing.md),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              // Thumbnail or fallback icon
              _buildThumbnail(colors),
              SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.type.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IssueStateBadge(state: issue.state, compact: true),
                      ],
                    ),
                    SizedBox(height: Spacing.xs),
                    if (issue.location != null)
                      Text(
                        '${issue.location!.latitude.toStringAsFixed(4)}, ${issue.location!.longitude.toStringAsFixed(4)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Close button and heat
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      iconSize: IconSizes.md,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  SizedBox(height: Spacing.sm),
                  HeatBadge(heat: issue.heat),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactVariant(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              IssueTypeIcon(type: issue.type, size: IconSizes.lg),
              SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  issue.type.displayName,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IssueStateBadge(state: issue.state, compact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colors) {
    final photoUrl = issue.photos.isNotEmpty ? issue.photos.first : null;

    return Container(
      width: ThumbnailSizes.md,
      height: ThumbnailSizes.md,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(colors),
            )
          : _buildFallbackIcon(colors),
    );
  }

  Widget _buildFallbackIcon(ColorScheme colors) {
    return Center(
      child: IssueTypeIcon(
        type: issue.type,
        size: IconSizes.lg,
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

#### Step 2.2.3: Update issue_map_page.dart

**File:** `lib/features/issues/presentation/pages/issue_map_page.dart`

1. **Remove** the entire `_IssuePreviewCard` class (lines ~354-468)

2. **Update** the bottom sheet builder to use `IssueCard`:

Find the section that builds the preview card (around line 320-350) and replace with:

```dart
// Replace _IssuePreviewCard usage with IssueCard
if (_selectedIssue != null)
  Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: IssueCard(
      issue: _selectedIssue!,
      variant: IssueCardVariant.mapPreview,
      onTap: () => _navigateToDetail(_selectedIssue!.id),
      onClose: () => setState(() => _selectedIssue = null),
    ),
  ),
```

3. **Add import** at top of file:
```dart
import '../widgets/issue_card.dart';
```

### 2.3 Verification

```bash
cd mobile
flutter analyze lib/features/issues/
flutter test test/features/issues/
```

---

## Phase 3: EmptyState Consolidation

### 3.1 Current State Analysis

**Problem:** Multiple inline `_EmptyState` classes across pages:
- `issue_list_page.dart` (lines 89-130)
- `my_reports_page.dart` (lines 61-102)
- `home_page.dart` (lines 326-362)

### 3.2 Implementation Steps

#### Step 3.2.1: Update EmptyState Widget

**File:** `lib/shared/widgets/empty_state.dart`

Replace entire file with:

```dart
import 'package:flutter/material.dart';
import 'package:munserv/shared/theme/typography.dart';

/// Empty state display for lists and error conditions.
///
/// Use factory constructors for common scenarios:
/// - [EmptyState.noIssues] - No issues to display
/// - [EmptyState.noReports] - User has no reports
/// - [EmptyState.noResults] - Search returned nothing
/// - [EmptyState.networkError] - Network/connection error
/// - [EmptyState.locationError] - Location permission/service error
///
/// ## Usage
/// ```dart
/// // In issue list
/// if (issues.isEmpty) {
///   return EmptyState.noIssues(
///     onRefresh: () => ref.invalidate(issuesProvider),
///   );
/// }
/// ```
class EmptyState extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Main title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Optional action button.
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  /// No issues to display.
  factory EmptyState.noIssues({
    VoidCallback? onRefresh,
  }) {
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: 'No Issues',
      subtitle: 'All clear! No issues have been reported in this area.',
      action: onRefresh != null
          ? OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            )
          : null,
    );
  }

  /// User has no reports.
  factory EmptyState.noReports({
    VoidCallback? onReport,
  }) {
    return EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Reports Yet',
      subtitle: 'You haven\'t reported any issues yet. Tap below to report your first issue.',
      action: onReport != null
          ? FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }

  /// Search returned no results.
  factory EmptyState.noResults({
    String? query,
    VoidCallback? onClear,
  }) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results',
      subtitle: query != null
          ? 'No issues found matching "$query".'
          : 'No issues match your current filters.',
      action: onClear != null
          ? OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Network or connection error.
  factory EmptyState.networkError({
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.cloud_off,
      title: 'Connection Error',
      subtitle: 'Unable to connect to the server. Please check your internet connection.',
      action: onRetry != null
          ? FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            )
          : null,
    );
  }

  /// Location permission or service error.
  factory EmptyState.locationError({
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.location_off,
      title: 'Location Unavailable',
      subtitle: 'Please enable location services to see issues near you.',
      action: onRetry != null
          ? FilledButton(
              onPressed: onRetry,
              child: const Text('Enable Location'),
            )
          : null,
    );
  }

  /// Generic empty state with custom action.
  factory EmptyState.custom({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: onAction != null && actionLabel != null
          ? FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: IconSizes.display,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: Spacing.lg),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: Spacing.sm),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: Spacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

#### Step 3.2.2: Update issue_list_page.dart

**File:** `lib/features/issues/presentation/pages/issue_list_page.dart`

1. **Add import:**
```dart
import 'package:munserv/shared/widgets/empty_state.dart';
```

2. **Remove** inline `_EmptyState` class (lines ~89-130)

3. **Replace** usage with:
```dart
if (issues.isEmpty) {
  return EmptyState.noIssues(
    onRefresh: () => ref.invalidate(issuesProvider),
  );
}
```

#### Step 3.2.3: Update my_reports_page.dart

**File:** `lib/features/issues/presentation/pages/my_reports_page.dart`

1. **Add import:**
```dart
import 'package:munserv/shared/widgets/empty_state.dart';
```

2. **Remove** inline `_EmptyState` class (lines ~61-102)

3. **Replace** usage with:
```dart
if (reports.isEmpty) {
  return EmptyState.noReports(
    onReport: () => context.push('/report'),
  );
}
```

#### Step 3.2.4: Update home_page.dart

**File:** `lib/features/home/presentation/pages/home_page.dart`

1. **Add import:**
```dart
import 'package:munserv/shared/widgets/empty_state.dart';
```

2. **Remove** inline `_EmptyState` class (lines ~326-362)

3. **Replace** usage with:
```dart
if (recentIssues.isEmpty) {
  return SliverFillRemaining(
    child: EmptyState.noIssues(
      onRefresh: () => ref.invalidate(recentIssuesProvider),
    ),
  );
}
```

### 3.3 Verification

```bash
flutter analyze lib/features/issues/ lib/features/home/
flutter test
```

---

## Phase 4: QuickActionCard Extraction

### 4.1 Current State

**Problem:** `_QuickActionCard` is private in `home_page.dart`, not reusable.

### 4.2 Implementation Steps

#### Step 4.2.1: Create QuickActionCard Widget

**File:** `lib/shared/widgets/quick_action_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:munserv/shared/theme/typography.dart';

/// A tappable card for quick actions on the home screen.
///
/// ## Usage
/// ```dart
/// QuickActionCard(
///   icon: Icons.report,
///   label: 'Report Issue',
///   backgroundColor: colors.errorContainer,
///   onTap: () => navigateToReport(),
/// )
/// ```
class QuickActionCard extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text below icon.
  final String label;

  /// Optional background color. Defaults to primaryContainer.
  final Color? backgroundColor;

  /// Optional icon color. Defaults to onPrimaryContainer.
  final Color? iconColor;

  /// Called when card is tapped.
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bgColor = backgroundColor ?? colors.primaryContainer;
    final fgColor = iconColor ?? colors.onPrimaryContainer;

    return Card(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: IconSizes.xl,
                color: fgColor,
              ),
              SizedBox(height: Spacing.sm),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: fgColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Step 4.2.2: Export Widget

**File:** `lib/shared/widgets/widgets.dart`

Add export:
```dart
export 'quick_action_card.dart';
```

#### Step 4.2.3: Update home_page.dart

1. **Add import:**
```dart
import 'package:munserv/shared/widgets/quick_action_card.dart';
```

2. **Remove** private `_QuickActionCard` class

3. **Replace** usages with `QuickActionCard`

### 4.3 Verification

```bash
flutter analyze lib/shared/widgets/ lib/features/home/
```

---

## Phase 5: StepIndicator Extraction

### 5.1 Current State

**Problem:** `_StepIndicator` is private in `report_issue_page.dart`.

### 5.2 Implementation Steps

#### Step 5.2.1: Create StepIndicator Widget

**File:** `lib/shared/widgets/step_indicator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:munserv/shared/theme/typography.dart';

/// Progress indicator for multi-step wizards.
///
/// ## Usage
/// ```dart
/// StepIndicator(
///   totalSteps: 4,
///   currentStep: 2, // 0-indexed
///   labels: ['Photo', 'Type', 'Location', 'Review'],
/// )
/// ```
class StepIndicator extends StatelessWidget {
  /// Total number of steps.
  final int totalSteps;

  /// Current step (0-indexed).
  final int currentStep;

  /// Optional step labels.
  final List<String>? labels;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.labels,
  }) : assert(currentStep >= 0 && currentStep < totalSteps);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (index) {
        // Even indices are dots, odd indices are connectors
        if (index.isOdd) {
          return _buildConnector(colors, index ~/ 2);
        } else {
          final stepIndex = index ~/ 2;
          return _buildDot(colors, textTheme, stepIndex);
        }
      }),
    );
  }

  Widget _buildDot(ColorScheme colors, TextTheme textTheme, int stepIndex) {
    final isCompleted = stepIndex < currentStep;
    final isCurrent = stepIndex == currentStep;
    final isActive = isCompleted || isCurrent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCurrent ? 12 : 8,
          height: isCurrent ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? colors.primary : colors.outlineVariant,
          ),
        ),
        if (labels != null && stepIndex < labels!.length) ...[
          SizedBox(height: Spacing.xs),
          Text(
            labels![stepIndex],
            style: textTheme.labelSmall?.copyWith(
              color: isActive ? colors.primary : colors.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnector(ColorScheme colors, int beforeIndex) {
    final isCompleted = beforeIndex < currentStep;

    return Container(
      width: Spacing.lg,
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: Spacing.xs),
      color: isCompleted ? colors.primary : colors.outlineVariant,
    );
  }
}
```

#### Step 5.2.2: Export Widget

**File:** `lib/shared/widgets/widgets.dart`

Add export:
```dart
export 'step_indicator.dart';
```

#### Step 5.2.3: Update report_issue_page.dart

1. **Add import:**
```dart
import 'package:munserv/shared/widgets/step_indicator.dart';
```

2. **Remove** private `_StepIndicator` class

3. **Replace** usages with `StepIndicator`

---

## Phase 6: Magic Number Cleanup

### 6.1 Files to Update

| File | Lines | Current | Replace With |
|------|-------|---------|--------------|
| `error_display.dart` | 28 | `64` | `IconSizes.xxl` |
| `error_display.dart` | 32 | `24` | `Spacing.lg` |
| `error_display.dart` | 35 | `24` | `Spacing.lg` |
| `issue_card.dart` | 39 | `64` | `IconSizes.xxl` |
| `issue_type_icon.dart` | Various | Size params | Use `IconSizes` |
| `report_issue_page.dart` | 485 | `100` | `ThumbnailSizes.lg` |
| `issue_map_page.dart` | 252 | `40`, `48` | `IconSizes.xl` |

### 6.2 Implementation

For each file:
1. Add import: `import 'package:munserv/shared/theme/typography.dart';`
2. Replace magic numbers with constants

---

## Testing Checklist

### Unit Tests

- [ ] `IssueCard` renders all variants correctly
- [ ] `EmptyState` factory constructors create correct widgets
- [ ] `QuickActionCard` calls onTap when pressed
- [ ] `StepIndicator` shows correct step as active

### Widget Tests

- [ ] Issue list shows full-width cards
- [ ] Map preview card appears with close button
- [ ] Empty states display with correct icons/text
- [ ] Step indicator highlights current step

### Visual Tests

- [ ] Cards are same width across all screens
- [ ] No visual regressions in issue list
- [ ] No visual regressions in map view
- [ ] Empty states look consistent

---

## Verification Commands

```bash
# Analyze all modified files
flutter analyze lib/shared/ lib/features/issues/ lib/features/home/

# Run all tests
flutter test

# Run specific widget tests
flutter test test/shared/widgets/

# Check for unused code
dart fix --dry-run

# Format code
dart format lib/
```

---

## Definition of Done

- [ ] All issue cards render at full available width
- [ ] No inline `_EmptyState` classes exist in any page
- [ ] All sizing uses `Spacing`, `IconSizes`, `ThumbnailSizes` constants
- [ ] `IssueCard` supports `list`, `mapPreview`, and `compact` variants
- [ ] `EmptyState` has factory constructors for all common cases
- [ ] `QuickActionCard` extracted to `shared/widgets/`
- [ ] `StepIndicator` extracted to `shared/widgets/`
- [ ] All widgets exported from `shared/widgets/widgets.dart`
- [ ] No magic numbers in widget code
- [ ] All tests pass
- [ ] No lint warnings
- [ ] Visual consistency verified on all screens

---

## Handoff to Mobile Dev Agent

To implement this specification:

```bash
cd /home/marsel/munserv/mobile
```

Then invoke the mobile dev cycle:

```
/dev-cycle task="Implement component reusability refactoring per specs/features/component-reusability/implementation-spec.md"
```

The agent should:
1. Read this specification completely
2. Follow phases in order (1 through 6)
3. Run verification after each phase
4. Mark phases complete in todo list
5. Create tests for new/modified widgets
