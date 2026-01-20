# Bug Fix: Ground Admin Invitation Flow Not Persisting

## Issue Summary

When an admin invites a member to become a Ground Admin through the web UI:
1. Admin clicks "Send Invite" on a member
2. The dialog closes (appears successful)
3. **BUG**: Member does NOT move to pending invite state
4. **BUG**: Member is NOT present in the "Pending GA Invites" tab
5. **BUG**: Member does NOT receive the invitation message in the mobile app

## Root Cause Analysis

### Bug #1: Backend Query Status Case Mismatch

**Location**: `backend/src/main/kotlin/com/munserv/groundadmin/repository/JpaGroundAdminApplicationRepository.kt:18-19`

**Problem**: The JPA query uses hardcoded lowercase `'pending'` but the `AdminController.kt:205` queries with uppercase `"PENDING"`:

```kotlin
// JPA Query (line 18-19)
@Query("""
    SELECT a FROM GroundAdminApplicationEntity a
    WHERE a.memberId = :memberId
    AND a.sectorId = :sectorId
    AND a.status = 'pending'   // ← Lowercase 'pending'
""")
fun findPendingForMemberInSector(...)

// But AdminController calls with (line 205):
val pendingApplications = applicationRepository.findBySectorIdAndStatus(id, "PENDING")  // ← Uppercase 'PENDING'
```

The `findBySectorIdAndStatus` method does a case-sensitive match, but the database stores lowercase `"pending"` while the controller passes uppercase `"PENDING"`.

**Evidence**:
- `ApplicationStatus.kt:7` defines `PENDING("pending")` with lowercase `toDbValue()`
- `GroundAdminApplication.kt:21` uses `ApplicationStatus.PENDING` which serializes to lowercase `"pending"`
- `AdminController.kt:205` passes string `"PENDING"` (uppercase)

### Bug #2: Spring Data Query Method Case Sensitivity

**Location**: `backend/src/main/kotlin/com/munserv/groundadmin/repository/JpaGroundAdminApplicationRepository.kt:26-29`

```kotlin
fun findBySectorIdAndStatus(
    sectorId: UUID,
    status: String,  // ← String comparison is case-sensitive in database
): List<GroundAdminApplicationEntity>
```

The Spring Data derived query `findBySectorIdAndStatus` generates SQL like:
```sql
SELECT * FROM ground_admin_applications WHERE sector_id = ? AND status = ?
```

If the database has `status = 'pending'` (lowercase) but we pass `"PENDING"` (uppercase), no rows are returned.

## Affected Code Paths

### Backend

| File | Line | Issue |
|------|------|-------|
| `AdminController.kt` | 205 | Passes `"PENDING"` (uppercase) |
| `AdminController.kt` | 234 | Passes `"PENDING"` (uppercase) |
| `JpaGroundAdminApplicationRepository.kt` | 26-29 | Case-sensitive status match |
| `ApplicationStatus.kt` | 7 | Stores lowercase `"pending"` |

### Web UI

The web UI code appears correct:
- `useInviteGroundAdmin()` properly invalidates `['members']` query cache
- API call to `POST /members/{id}/ground-admin/invite` is correct
- The mutation succeeds (dialog closes, no error)

The web UI shows stale data because the backend query returns empty results.

### Mobile

Mobile cannot display the invitation because:
1. The `messages` table record IS created correctly (this works)
2. But the member won't see themselves in "pending invite" state in web UI
3. Mobile message display should work IF the message was created

## Fix Strategy

### Phase 1: Backend Fix (Critical)

Fix the case sensitivity issue in `AdminController.kt`:

```kotlin
// Change from:
val pendingApplications = applicationRepository.findBySectorIdAndStatus(id, "PENDING")

// To:
val pendingApplications = applicationRepository.findBySectorIdAndStatus(id, "pending")

// Or better - use the enum's toDbValue():
val pendingApplications = applicationRepository.findBySectorIdAndStatus(id, ApplicationStatus.PENDING.toDbValue())
```

### Phase 2: Verify Message Creation

Add integration test to verify:
1. `GroundAdminApplication` record is created with status `"pending"`
2. `Message` record is created with type `GROUND_ADMIN_INVITATION`
3. Both records are committed to database

### Phase 3: Web UI Verification

After backend fix, verify:
1. Members list refreshes and shows `hasInvitationPending: true`
2. "Pending GA Invites" tab shows the invited member
3. Revoke invite action works

### Phase 4: Mobile Verification

Verify:
1. Messages list shows the invitation
2. Accept/Decline buttons work
3. Actions update the application status correctly

## Test Scenarios

### Manual Testing

1. **Pre-fix verification**:
   - Check database for existing `ground_admin_applications` records
   - Note the `status` column value (should be lowercase `pending`)

2. **Send invitation**:
   - Login as admin
   - Go to Members page
   - Find a member who is not a Ground Admin
   - Click invite icon
   - Enter optional message
   - Click "Send Invitation"

3. **Verify database** (after fix):
   ```sql
   SELECT * FROM ground_admin_applications
   WHERE status = 'pending'
   ORDER BY created_at DESC;
   ```

4. **Verify web UI**:
   - Refresh Members page
   - Check "Pending GA Invites" tab
   - Verify invited member appears

5. **Verify mobile**:
   - Login as the invited member
   - Check Messages screen
   - Verify invitation appears
   - Test Accept/Decline buttons

## Files to Modify

### Backend (Priority 1)

1. `backend/src/main/kotlin/com/munserv/admin/api/AdminController.kt`
   - Lines 205, 234: Change `"PENDING"` to `ApplicationStatus.PENDING.toDbValue()`

### Backend Tests (Priority 2)

2. `backend/src/test/kotlin/com/munserv/admin/api/AdminControllerTest.kt`
   - Add test for pending invitations filter

3. `backend/src/test/kotlin/com/munserv/groundadmin/service/GroundAdminServiceTest.kt`
   - Add integration test for full invite flow

## Acceptance Criteria

- [x] Backend query uses correct case for status comparison (Fixed 2026-01-20)
- [ ] Inviting a member creates `GroundAdminApplication` with `status = 'pending'`
- [ ] Inviting a member creates `Message` with `type = 'ground_admin_invitation'`
- [ ] Web UI "Pending GA Invites" tab shows invited members
- [ ] Mobile Messages screen shows invitation
- [ ] Accept/Decline actions work from mobile
- [ ] Unit tests cover the fixed behavior
