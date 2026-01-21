---
issue: 12
title: "Incorrect mobile theme on message details"
platform: mobile
status: completed
created_by: central-agent
created_at: 2026-01-21
updated_at: 2026-01-21
started_at: 2026-01-21
completed_at: 2026-01-21
dependencies: []
files_changed:
  - lib/features/messages/presentation/pages/message_detail_page.dart
tests_added: []
commits: []
blockers: []
---

# Issue #12: Incorrect mobile theme on message details (Mobile)

## Context

The message detail screen does not follow the standard mobile theme pattern. All detail pages that are navigated to from the main shell should use `BrandedScaffold` to display:
1. The burnt orange branding header with MunServ logo
2. The faded vintage map background

The issue detail page (`issue_detail_page.dart`) correctly implements this pattern, but the message detail page does not.

## Root Cause

`message_detail_page.dart` uses plain `Scaffold` instead of `BrandedScaffold`.

## What To Fix

### Files To Modify
- `mobile/lib/features/messages/presentation/pages/message_detail_page.dart`

### Changes Required

1. **Add import for BrandedScaffold** (around line 10):
   ```dart
   import '../../../../shared/widgets/branded_scaffold.dart';
   ```

2. **Replace Scaffold with BrandedScaffold** (line 55):

   **Before:**
   ```dart
   return Scaffold(
     appBar: AppBar(title: Text(l10n.messageDetail)),
     body: messageAsync.when(
   ```

   **After:**
   ```dart
   return BrandedScaffold(
     appBar: AppBar(title: Text(l10n.messageDetail)),
     body: messageAsync.when(
   ```

That's it - `BrandedScaffold` is a drop-in replacement for `Scaffold` that automatically adds the branding header and map background.

## Reference Implementation

See `mobile/lib/features/issues/presentation/pages/issue_detail_page.dart` for the correct pattern:

```dart
return BrandedScaffold(
  appBar: AppBar(
    titleSpacing: 0,
    title: ...,
    actions: [...],
  ),
  body: issueAsync.when(
    data: (issue) => _IssueDetailContent(issue: issue),
    loading: () => const LoadingSpinner(),
    error: (error, _) => ErrorDisplay(...),
  ),
);
```

## Acceptance Criteria

- [ ] Message detail screen shows burnt orange branding header at top
- [ ] Message detail screen shows faded map background behind content
- [ ] AppBar appears below the branding header
- [ ] Screen matches visual style of Issue Detail screen
- [ ] Tests pass
- [ ] Quality checks pass (`flutter analyze`)

## Dependencies

None - this is a standalone mobile fix.

## Implementation Notes

### Changes Made
- Added import for `BrandedScaffold` widget
- Replaced `Scaffold` with `BrandedScaffold` on line 56

This is a drop-in replacement that automatically adds:
- Burnt orange branding header with MunServ logo at top
- Faded vintage map background behind content
- Consistent visual style matching Issue Detail and other detail pages

### Tests
- No new tests added (existing tests pass)
- Flutter analyze: No issues found
- All 369 existing tests pass

### Decisions Made
- Used existing `BrandedScaffold` widget as specified in mobile CLAUDE.md
- No additional changes needed since BrandedScaffold is a drop-in replacement for Scaffold
