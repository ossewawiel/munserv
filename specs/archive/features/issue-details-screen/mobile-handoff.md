# Mobile Handoff: Issue Details Screen

## Quick Start

**Full specification:** `specs/features/issue-details-screen/spec.md`

Before starting, read these files in order:
1. `specs/features/issue-details-screen/spec.md` - Complete implementation details
2. `mobile/CLAUDE.md` - Architecture patterns, styling rules

---

## Task Summary

| # | File to Create | Type |
|---|----------------|------|
| 1 | `lib/shared/widgets/issue_location_map.dart` | StatelessWidget |
| 2 | `lib/shared/widgets/photo_thumbnail_carousel.dart` | StatelessWidget |
| 3 | `lib/features/issues/presentation/widgets/issue_timeline.dart` | StatelessWidget (extract) |
| 4 | `lib/features/issues/presentation/pages/fullscreen_map_page.dart` | ConsumerStatefulWidget |
| 5 | `lib/features/issues/presentation/pages/photo_gallery_page.dart` | ConsumerStatefulWidget |

| # | File to Modify |
|---|----------------|
| 6 | `lib/features/issues/presentation/pages/issue_detail_page.dart` |
| 7 | `lib/routing/app_router.dart` |

---

## Commands

```bash
cd /home/marsel/munserv/mobile

# 1. Add dependency
flutter pub add photo_view

# 2. After implementation
flutter analyze
flutter test
```

---

## Critical Styling Rules

**From `mobile/CLAUDE.md` - these MUST be followed:**

```dart
// SPACING - Never use magic numbers
SizedBox(height: Spacing.md)   // ✅
SizedBox(height: 16)           // ❌

// RADII - Never use magic numbers
BorderRadius.circular(Radii.md)  // ✅
BorderRadius.circular(8)         // ❌

// ICONS - Use constants
Icon(icon, size: IconSizes.xl)   // ✅
Icon(icon, size: 48)             // ❌

// COLORS - Always from theme
final colors = Theme.of(context).colorScheme;
colors.primary                   // ✅
Color(0xFF233D36)               // ❌
```

---

## File Contents

All implementation code is in `spec.md` sections:
- Section "1. IssueLocationMap Widget" - Full code
- Section "2. PhotoThumbnailCarousel Widget" - Full code
- Section "3. FullscreenMapPage" - Full code
- Section "4. PhotoGalleryPage" - Full code
- Section "5. IssueTimeline Widget" - Full code
- Section "6. Updated IssueDetailPage Structure" - Modification instructions
- Section "7. Router Updates" - Modification instructions

---

## Test Files

Create tests following the patterns in `spec.md` "Testing Requirements" section:
- `test/shared/widgets/issue_location_map_test.dart`
- `test/shared/widgets/photo_thumbnail_carousel_test.dart`
- `test/features/issues/presentation/widgets/issue_timeline_test.dart`

---

## Definition of Done

From spec.md - all items must be checked:
- [ ] `photo_view` dependency added
- [ ] All widgets created with tests
- [ ] All pages created with tests
- [ ] `IssueDetailPage` updated
- [ ] Routes added
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] No hardcoded colors or magic numbers
