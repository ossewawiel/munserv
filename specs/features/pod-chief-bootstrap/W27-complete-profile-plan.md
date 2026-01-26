# Implementation Plan: W27 - Pod Chief completes optional profile info

**Issue:** [#42](https://github.com/ossewawiel/munserv/issues/42)
**Milestone:** pod-chief-bootstrap
**Platforms:** Web (Onboarding module)

## Summary

Pod Chief can complete optional profile info (known-as, contact phone, address) or skip directly to dashboard after changing password. Sets onboarding status to ACTIVE when complete or skipped.

## Current State Analysis

### Backend ✅ Ready
- `OnboardingController.completeProfile()` endpoint exists at `POST /api/v1/admin/onboarding/complete-profile`
- `OnboardingService.completeProfile()` transitions status from PASSWORD_CHANGED to ACTIVE
- `OnboardingStatus` enum has full flow: PENDING → PASSWORD_CHANGED → PROFILE_COMPLETE → ACTIVE
- Currently only accepts `displayName` parameter

### Web - Missing
- No `CompleteProfilePage` component
- No route for `/onboarding/complete-profile`
- No onboarding feature module
- LoginPage already redirects to `/onboarding/complete-profile` when status is `password_changed`
- Translations exist in `translation.json` under `onboarding.*`

## Implementation Tasks

### Backend Changes (Minor)

| Task | File | Description |
|------|------|-------------|
| B1 | `OnboardingController.kt` | Extend `CompleteProfileRequest` to include optional fields: knownAs, contactPhone, address |
| B2 | `OnboardingService.kt` | Update `completeProfile()` to handle new optional fields |
| B3 | `Admin.kt` | Add optional fields: knownAs, contactPhone, address |
| B4 | `AdminEntity.kt` | Add corresponding database columns |
| B5 | Migration | Create Flyway migration for new columns |
| B6 | Tests | Update unit tests for new fields |

### Web Changes (New Feature)

| Task | File | Description |
|------|------|-------------|
| W1 | `features/onboarding/types.ts` | Create onboarding types |
| W2 | `features/onboarding/api.ts` | API functions for onboarding |
| W3 | `features/onboarding/hooks.ts` | React Query hooks |
| W4 | `features/onboarding/CompleteProfilePage.tsx` | Profile completion form page |
| W5 | `App.tsx` | Add route for `/onboarding/complete-profile` |
| W6 | `locales/en/translation.json` | Verify/add any missing translations |
| W7 | Tests | Add tests for new components and hooks |

## Detailed Implementation

### Backend: CompleteProfileRequest DTO Extension

```kotlin
@Schema(description = "Profile completion request")
data class CompleteProfileRequest(
    @field:Size(max = 100, message = "Display name must be 100 characters or less")
    @field:Schema(description = "Display name (optional update)", example = "John D. Smith")
    val displayName: String? = null,

    @field:Size(max = 50, message = "Known-as must be 50 characters or less")
    @field:Schema(description = "Nickname or preferred name", example = "Johnny")
    val knownAs: String? = null,

    @field:Size(max = 20, message = "Contact phone must be 20 characters or less")
    @field:Schema(description = "Contact phone number", example = "+27123456789")
    val contactPhone: String? = null,

    @field:Size(max = 255, message = "Address must be 255 characters or less")
    @field:Schema(description = "Physical address", example = "123 Main St, City")
    val address: String? = null,
)
```

### Web: CompleteProfilePage Component

```typescript
// Location: web/src/features/onboarding/CompleteProfilePage.tsx

interface CompleteProfileFormData {
  displayName: string;
  knownAs?: string;
  contactPhone?: string;
  address?: string;
}

export const CompleteProfilePage: FC = () => {
  // Pre-fill displayName from auth context
  // Optional fields for knownAs, contactPhone, address
  // Skip button redirects to dashboard (calls API with just displayName)
  // Complete button submits all fields
  // On success: redirect to dashboard with welcome message
};
```

### Database Migration

```sql
-- V15__add_admin_profile_fields.sql
ALTER TABLE admins
ADD COLUMN known_as VARCHAR(50) NULL,
ADD COLUMN contact_phone VARCHAR(20) NULL,
ADD COLUMN address VARCHAR(255) NULL;
```

## Implementation Order

1. **Database** - Add migration for new columns
2. **Backend domain** - Update Admin.kt with new fields
3. **Backend repository** - Update AdminEntity.kt mapping
4. **Backend service** - Update OnboardingService to handle fields
5. **Backend controller** - Update CompleteProfileRequest DTO
6. **Backend tests** - Update existing tests
7. **Web types** - Create onboarding types
8. **Web API** - Create API functions
9. **Web hooks** - Create React Query hooks
10. **Web page** - Create CompleteProfilePage component
11. **Web routing** - Add route to App.tsx
12. **Web tests** - Add component tests

## Acceptance Criteria Mapping

| Criteria | Implementation |
|----------|----------------|
| Display name field is editable | Pre-filled TextField in form |
| Optional fields: known-as, contact phone, address | Optional TextFields |
| Can skip directly to dashboard | Skip button calls API with current displayName only |
| Onboarding status changes to ACTIVE | Backend already does this |
| Welcome message displayed after completion | Redirect to dashboard with toast/snackbar |

## Dependencies

- W26 (Pod Chief must change password) - Must be complete (user at PASSWORD_CHANGED status)
- Auth context must provide current admin displayName

## Files to Create/Modify

### New Files
- `web/src/features/onboarding/types.ts`
- `web/src/features/onboarding/api.ts`
- `web/src/features/onboarding/hooks.ts`
- `web/src/features/onboarding/CompleteProfilePage.tsx`
- `web/src/features/onboarding/CompleteProfilePage.test.tsx`
- `backend/src/main/resources/db/migration/V15__add_admin_profile_fields.sql`

### Modified Files
- `backend/src/main/kotlin/com/munserv/admin/api/OnboardingController.kt`
- `backend/src/main/kotlin/com/munserv/admin/service/OnboardingService.kt`
- `backend/src/main/kotlin/com/munserv/admin/domain/Admin.kt`
- `backend/src/main/kotlin/com/munserv/admin/repository/AdminEntity.kt`
- `web/src/App.tsx`

## Definition of Done

- [ ] Database migration applied successfully
- [ ] Backend accepts optional profile fields
- [ ] Backend tests pass
- [ ] CompleteProfilePage renders correctly
- [ ] Form pre-fills displayName from current admin
- [ ] Skip button works (calls API, redirects to dashboard)
- [ ] Complete button works (submits all fields, redirects)
- [ ] Route `/onboarding/complete-profile` works
- [ ] Onboarding guard prevents access if not at PASSWORD_CHANGED status
- [ ] All web tests pass
- [ ] No lint errors
- [ ] Integration tested end-to-end
