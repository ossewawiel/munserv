---
issue: 26
title: "[W15] Add new pod administrator"
platform: web
status: completed
created_by: central-agent
created_at: 2026-01-26
updated_at: 2026-01-26
dependencies: []
files_changed:
  - src/features/pod-chief/components/CreatePodAdminDialog.tsx
  - src/locales/en/translation.json
tests_added: []
commits: []
blockers: []
---

# Issue #26: Add New Pod Administrator (Web)

## Context

The Pod Administrators page (W14) was implemented and the "Add Administrator" dialog exists. However, the dialog is missing the **ward/sector selection** functionality required by the acceptance criteria.

When a Pod Chief creates a new administrator, they should be able to:
1. Enter email and display name
2. Select a role (pod_admin, ward_admin, ward_chief, sector_admin, sector_chief)
3. **Based on role level**, select the appropriate ward or sector assignment

## Root Cause / Gap Analysis

Current implementation in `CreatePodAdminDialog.tsx`:
- Has email, displayName, and role fields
- Does NOT include ward/sector selection dropdowns
- The `CreatePodAdministratorRequest` type already supports `wardId` and `sectorId` fields
- The backend expects these fields for non-pod-level roles

## Acceptance Criteria

From issue #26:
- [ ] Form: email, name, surname, ward/sector selection
- [ ] Sends welcome email with temp password (backend handles this)
- [ ] New admin appears in list as pending

**Note:** The backend uses `displayName` (not separate firstName/lastName), so current implementation is correct for that field.

## What To Fix

### File to Modify
- `src/features/pod-chief/components/CreatePodAdminDialog.tsx`

### Changes Required

1. **Add ward/sector selection logic based on role**
   - When role is `pod_admin` or `pod_chief`: No ward/sector selection needed
   - When role is `ward_admin` or `ward_chief`: Show ward dropdown (required)
   - When role is `sector_admin` or `sector_chief`: Show sector dropdown (required)

2. **Get wards and sectors data**
   - Use `usePodSetup()` hook from `@/shared/hooks/usePodSetup` which provides:
     - `status.wards: Array<{ id: string; name: string }>`
     - `status.sectors: Array<{ id: string; name: string }>`

3. **Add state management**
   ```typescript
   const [wardId, setWardId] = useState<string>('');
   const [sectorId, setSectorId] = useState<string>('');
   ```

4. **Add MUI Select components for ward/sector**
   - Show ward dropdown when role is ward-level (ward_admin, ward_chief)
   - Show sector dropdown when role is sector-level (sector_admin, sector_chief)
   - Validate that appropriate selection is made before submission

5. **Update form submission**
   ```typescript
   onSubmit({
     email: email.trim(),
     displayName: displayName.trim(),
     role,
     wardId: isWardLevel ? wardId : undefined,
     sectorId: isSectorLevel ? sectorId : undefined,
   });
   ```

6. **Add i18n keys** to `locales/en/translation.json` under `podAdministrators.form`:
   ```json
   "form": {
     "email": "Email Address",
     "displayName": "Display Name",
     "role": "Role",
     "selectWard": "Assign to Ward",
     "selectSector": "Assign to Sector",
     "wardRequired": "Ward selection is required for this role",
     "sectorRequired": "Sector selection is required for this role",
     "emailRequired": "Email is required",
     "emailInvalid": "Invalid email format",
     "displayNameRequired": "Display name is required",
     "emailReadonly": "Email cannot be changed"
   }
   ```

### Helper Functions Needed

```typescript
import { AdminRole, getAdminLevel } from '@/shared/types/admin';

// Check role level for conditional rendering
const roleLevel = getAdminLevel(role); // returns 'pod' | 'ward' | 'sector'
const requiresWard = roleLevel === 'ward';
const requiresSector = roleLevel === 'sector';
```

## Files to Reference

- `src/shared/hooks/usePodSetup.ts` - Provides wards/sectors lists
- `src/shared/types/admin.ts` - Role utilities (`getAdminLevel`, `AdminRole`)
- `src/features/pod-chief/types.ts` - Type definitions

## Test Cases

1. **Pod-level role (pod_admin)**: No ward/sector dropdown shown
2. **Ward-level role (ward_admin)**: Ward dropdown shown, required
3. **Sector-level role (sector_admin)**: Sector dropdown shown, required
4. **Validation**: Cannot submit without ward/sector when role requires it
5. **Reset on role change**: Clear ward/sector selection when role changes

## Definition of Done

- [x] Ward dropdown appears when ward-level role is selected
- [x] Sector dropdown appears when sector-level role is selected
- [x] Form validates that ward/sector is selected when required
- [x] Submitted request includes wardId or sectorId based on role
- [x] Selection clears when role changes to a different level
- [x] No TypeScript errors
- [x] No ESLint errors

## Implementation Notes

**Implemented 2026-01-26:**

1. Added `usePodSetup` hook to get wards/sectors lists
2. Added `getRoleLevel` utility to determine role level (pod/ward/sector)
3. Added state for `wardId` and `sectorId` with validation
4. Ward dropdown shown when role is `ward_admin` or `ward_chief`
5. Sector dropdown shown when role is `sector_admin` or `sector_chief`
6. Form submission includes wardId/sectorId based on role level
7. Selection clears when changing to a different role level
8. Added i18n keys: `selectWard`, `selectSector`, `wardRequired`, `sectorRequired`
