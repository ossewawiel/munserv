# Investigation: Incorrect mobile theme on message details

**Issue:** #12
**Date:** 2026-01-21
**Platforms:** Mobile

## Problem Statement

When viewing message details, the screen layout does not follow the standard mobile theme:
- Missing burnt orange App Header (BrandingHeader)
- Missing faded map background (MapBackground)
- Does not match other detail screens like Issue Details

## Investigation Steps

1. Reviewed `message_detail_page.dart` - uses plain `Scaffold`
2. Reviewed `issue_detail_page.dart` - correctly uses `BrandedScaffold`
3. Reviewed `BrandedScaffold` component - provides BrandingHeader + MapBackground
4. Reviewed `AppShell` - provides branding for tab-level pages only
5. Confirmed detail pages navigated from shell must use `BrandedScaffold`

## Root Cause

`message_detail_page.dart` (line 55) uses:
```dart
return Scaffold(
  appBar: AppBar(title: Text(l10n.messageDetail)),
  body: messageAsync.when(...),
);
```

It should use `BrandedScaffold` like `issue_detail_page.dart`:
```dart
return BrandedScaffold(
  appBar: AppBar(title: Text(l10n.messageDetail)),
  body: messageAsync.when(...),
);
```

## Affected Components

### Mobile
- `mobile/lib/features/messages/presentation/pages/message_detail_page.dart`
  - Line 55: Uses `Scaffold` instead of `BrandedScaffold`

## Fix Approach

1. Import `BrandedScaffold` from shared widgets
2. Replace `Scaffold` with `BrandedScaffold`
3. The `BrandedScaffold` automatically provides:
   - BrandingHeader (burnt orange with logo)
   - MapBackground (faded vintage map)
   - Proper AppBar positioning

## Related Files (Correct Implementations)

- `mobile/lib/features/issues/presentation/pages/issue_detail_page.dart` - Uses BrandedScaffold correctly
- `mobile/lib/shared/widgets/branded_scaffold.dart` - The widget to use
- `mobile/lib/shared/widgets/branding_header.dart` - Burnt orange header
- `mobile/lib/shared/widgets/map_background.dart` - Faded map background
