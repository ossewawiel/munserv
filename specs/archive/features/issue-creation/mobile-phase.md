# Issue Creation - Mobile Phase

## Status: Complete ✅

**Completed:** January 2026

## Overview
Fix and complete the issue creation flow in the Flutter mobile app.

## Implementation Summary

### Files Modified
| File | Change |
|------|--------|
| `lib/features/issues/presentation/pages/report_issue_page.dart` | Added sectorId from auth, image validation |
| `lib/features/issues/presentation/widgets/location_step.dart` | Integrated real LocationService |
| `lib/features/issues/data/issue_api.dart` | Added sectorId to API payload |
| `lib/features/issues/domain/report_issue_request.dart` | Added sectorId field |
| `lib/l10n/app_en.arb` | Added i18n error message keys |

### Bugs Fixed
1. ~~**Location is hardcoded**~~ → Now uses real GPS via LocationService
2. ~~**No sectorId in request**~~ → Read from member profile
3. ~~**No image validation**~~ → Added size (5MB) and format checks

---

## Reference: Original Analysis

### What Was Working (Before Fix)
- Photo capture via ImagePicker (camera + gallery)
- Photo grid display with remove functionality
- Issue type selection (7 types)
- Description input
- Two-step API upload (create issue → upload photos)
- Error handling with SnackBar

---

## Implementation Tasks

### Task 1: Integrate Real Location Service
**File**: `lib/features/issues/presentation/widgets/location_step.dart`

**Problem** (lines 35-44):
```dart
// TODO: Implement actual location fetching with geolocator package
await Future.delayed(const Duration(seconds: 1));
widget.onLocationChanged(
  const GeoPoint(latitude: -26.1052, longitude: 28.0564),  // HARDCODED!
);
```

**Solution**:
```dart
import 'package:munserv/shared/services/location_service.dart';

Future<void> _fetchLocation() async {
  setState(() => _isLoading = true);

  try {
    final service = LocationService();
    final location = await service.getCurrentLocation();

    if (location != null && mounted) {
      widget.onLocationChanged(location);
      setState(() {
        _hasLocation = true;
        _isLoading = false;
      });
    } else {
      // Handle permission denied or service disabled
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).locationPermissionDenied)),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).locationError)),
      );
    }
  }
}
```

**Tests Required**:
- [ ] Unit test: LocationStep calls LocationService on init
- [ ] Widget test: Shows loading indicator while fetching
- [ ] Widget test: Displays error on permission denied
- [ ] Widget test: Updates parent when location received

---

### Task 2: Add sectorId to Request Model
**File**: `lib/features/issues/domain/report_issue_request.dart`

**Current**:
```dart
@freezed
class ReportIssueRequest with _$ReportIssueRequest {
  const factory ReportIssueRequest({
    required IssueType type,
    required GeoPoint location,
    String? description,
  }) = _ReportIssueRequest;
}
```

**Required**:
```dart
@freezed
class ReportIssueRequest with _$ReportIssueRequest {
  const factory ReportIssueRequest({
    required IssueType type,
    required GeoPoint location,
    required String sectorId,  // ADD THIS
    String? description,
  }) = _ReportIssueRequest;
}
```

**Also update** `lib/features/issues/data/issue_api.dart`:
```dart
Future<Result<Issue>> createIssue(ReportIssueRequest request) async {
  final response = await _dio.post('/issues', data: {
    'type': request.type.apiString,
    'latitude': request.location.latitude,
    'longitude': request.location.longitude,
    'sectorId': request.sectorId,  // ADD THIS
    'description': request.description,
  });
}
```

**Tests Required**:
- [ ] Unit test: ReportIssueRequest includes sectorId
- [ ] API test: POST /issues includes sectorId in payload

---

### Task 3: Get sectorId from Auth State
**File**: `lib/features/issues/presentation/pages/report_issue_page.dart`

**Current** (lines 80-84):
```dart
final request = ReportIssueRequest(
  type: _selectedType!,
  location: _location!,
  description: _description,
);
```

**Required**:
```dart
// At top of _submit method
final authState = ref.read(authStateProvider);
final member = authState.member;
if (member == null || member.sectorId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(S.of(context).noSectorAssigned)),
  );
  return;
}

final request = ReportIssueRequest(
  type: _selectedType!,
  location: _location!,
  sectorId: member.sectorId!,  // ADD THIS
  description: _description,
);
```

**Prerequisite**: Verify `MemberProfile` model has `sectorId` field.

---

### Task 4: Add Image Compression Validation
**File**: `lib/features/issues/presentation/pages/report_issue_page.dart`

**Current** (lines 293-305):
```dart
final picker = ImagePicker();
final image = await picker.pickImage(
  source: camera ? ImageSource.camera : ImageSource.gallery,
  maxWidth: 1920,
  maxHeight: 1920,
  imageQuality: 85,
);
```

**Enhancement** - Add file size validation:
```dart
Future<void> _pickAndValidatePhoto(ImageSource source) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(
    source: source,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );

  if (image != null) {
    final file = File(image.path);
    final sizeInMB = await file.length() / (1024 * 1024);

    if (sizeInMB > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).photoTooLarge)),
        );
      }
      return;
    }

    // Validate extension
    final ext = path.extension(image.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).unsupportedPhotoFormat)),
        );
      }
      return;
    }

    _addPhoto(image.path);
  }
}
```

---

### Task 5: Add Map Preview (Enhancement)
**File**: `lib/features/issues/presentation/widgets/location_step.dart`

**Current** (placeholder):
```dart
Icon(Icons.map, size: 64)
Text('Map preview')
```

**Enhancement** - Use flutter_map (already in pubspec):
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Widget _buildMapPreview(GeoPoint location) {
  return SizedBox(
    height: 200,
    child: FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(location.latitude, location.longitude),
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,  // Disable interaction for preview
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(location.latitude, location.longitude),
              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    ),
  );
}
```

---

### Task 6: Add i18n Keys
**File**: `lib/l10n/app_en.arb`

```json
{
  "locationPermissionDenied": "Location permission denied. Please enable in settings.",
  "locationError": "Unable to get your location. Please try again.",
  "noSectorAssigned": "Your account is not assigned to a sector.",
  "photoTooLarge": "Photo is too large. Maximum size is 5MB.",
  "unsupportedPhotoFormat": "Unsupported photo format. Use JPEG, PNG, or WebP.",
  "issueSubmittedSuccess": "Issue reported successfully!",
  "issueSubmitFailed": "Failed to submit issue. Please try again."
}
```

---

## Testing Checklist

### Unit Tests
- [ ] `location_step_test.dart` - LocationService integration
- [ ] `report_issue_request_test.dart` - sectorId included
- [ ] `issue_api_test.dart` - API payload includes sectorId

### Widget Tests
- [ ] `location_step_widget_test.dart` - Loading/error states
- [ ] `report_issue_page_test.dart` - Full flow submission

### Integration Tests
- [ ] E2E: Create issue with real backend
- [ ] E2E: Upload photos successfully
- [ ] E2E: Verify issue appears in "My Issues"

---

## Commands

```bash
# Run code generation after model changes
cd mobile && flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
cd mobile && flutter test test/features/issues/

# Run specific test
cd mobile && flutter test test/features/issues/presentation/widgets/location_step_test.dart
```

---

## Definition of Done

- [ ] Real GPS location captured (not hardcoded)
- [ ] sectorId included in API request
- [ ] Photos validated before upload (size, format)
- [ ] Map preview shows actual location
- [ ] All i18n keys added
- [ ] Unit tests passing
- [ ] Widget tests passing
- [ ] Code generation runs without errors
- [ ] No lint warnings

---

## Handoff Notes

**For agent execution:**
```
cd mobile
Read mobile/CLAUDE.md first for Riverpod/Freezed patterns.

Priority order:
1. Task 2 (sectorId in model) - Required for backend to accept request
2. Task 3 (get sectorId from auth) - Required for submission
3. Task 1 (real location) - Required for accurate reports
4. Task 4 (validation) - Important for UX
5. Task 5 (map preview) - Enhancement
6. Task 6 (i18n) - Required for polish
```
