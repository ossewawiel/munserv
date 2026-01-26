# Handoff: Backend - W27 Complete Profile

**GitHub Issue:** [#42](https://github.com/ossewawiel/munserv/issues/42)
**Milestone:** pod-chief-bootstrap
**Status:** COMPLETED

## Context

Extend the existing `completeProfile` endpoint to accept optional profile fields (knownAs, contactPhone, address) in addition to displayName. The endpoint already transitions status from PASSWORD_CHANGED to ACTIVE.

## Files Created/Modified

### New Files
- `backend/src/main/resources/db/migration/V033__add_admin_profile_fields.sql`

### Modified Files
- `backend/src/main/kotlin/com/munserv/admin/domain/Admin.kt` - Added knownAs, contactPhone, address fields
- `backend/src/main/kotlin/com/munserv/admin/repository/AdminEntity.kt` - Added JPA mappings and updated toDomain/fromDomain
- `backend/src/main/kotlin/com/munserv/admin/api/OnboardingController.kt` - Extended CompleteProfileRequest DTO
- `backend/src/main/kotlin/com/munserv/admin/service/OnboardingService.kt` - Updated completeProfile method signature
- `backend/src/test/kotlin/com/munserv/admin/service/OnboardingServiceTest.kt` - Added 3 new test cases

## Implementation Summary

### Database Migration V033
```sql
ALTER TABLE admins
ADD COLUMN known_as VARCHAR(50) NULL,
ADD COLUMN contact_phone VARCHAR(20) NULL,
ADD COLUMN address VARCHAR(255) NULL;
```

### Admin Domain Changes
Added three optional fields to Admin data class:
- `knownAs: String? = null`
- `contactPhone: String? = null`
- `address: String? = null`

### CompleteProfileRequest DTO
Extended with new optional fields with validation:
- knownAs (max 50 chars)
- contactPhone (max 20 chars)
- address (max 255 chars)

### OnboardingService.completeProfile()
Updated signature to accept new parameters:
```kotlin
fun completeProfile(
    adminId: AdminId,
    displayName: String?,
    knownAs: String? = null,
    contactPhone: String? = null,
    address: String? = null,
): OnboardingResult
```

## Tests Added

- `should complete profile with all optional fields` - Verifies all fields saved
- `should complete profile with displayName only (skip scenario)` - Verifies skip flow works
- `should complete profile with partial optional fields` - Verifies partial completion

## Verification

```bash
# All admin module tests pass
./gradlew test --tests "com.munserv.admin.*"  # PASSED

# Onboarding tests specifically
./gradlew test --tests "*OnboardingServiceTest*"  # PASSED

# Code formatting
./gradlew ktlintFormat  # PASSED
```

## Definition of Done

- [x] Migration V033 created
- [x] Admin domain updated with new fields
- [x] AdminEntity JPA mapping updated
- [x] CompleteProfileRequest DTO extended
- [x] OnboardingService updated to handle new fields
- [x] Controller passes new fields to service
- [x] Unit tests added (3 new tests)
- [x] All existing tests pass
- [x] No ktlint errors
- [x] OpenAPI docs updated automatically via annotations

## API Endpoint

**POST** `/api/v1/admin/onboarding/complete-profile`

**Request Body:**
```json
{
  "displayName": "John D. Smith",
  "knownAs": "Johnny",
  "contactPhone": "+27123456789",
  "address": "123 Main St, City"
}
```

All fields are optional. The endpoint transitions onboarding status from `password_changed` to `active`.
