# Backend Handoff: Fix Ground Admin Invitation Status Query

**Priority**: Critical
**Estimated Effort**: 1-2 hours
**Related Bug**: `bug-fix-invitation-flow.md`

## Problem Statement

The `AdminController.getMembers()` endpoint fails to return members with pending Ground Admin invitations because of a case mismatch in the status query parameter.

## Root Cause

```kotlin
// AdminController.kt:205
val pendingApplications = applicationRepository.findBySectorIdAndStatus(id, "PENDING")
//                                                                           ^^^^^^^^ UPPERCASE

// But database stores:
// status = 'pending' (lowercase)

// Because ApplicationStatus enum uses:
// PENDING("pending")  // lowercase dbValue
```

## Required Changes

### 1. Fix AdminController.kt

**File**: `backend/src/main/kotlin/com/munserv/admin/api/AdminController.kt`

**Change 1** (Line ~205):
```kotlin
// Before:
val pendingApplications = applicationRepository.findBySectorIdAndStatus(id, "PENDING")

// After:
val pendingApplications = applicationRepository.findBySectorIdAndStatus(
    id,
    ApplicationStatus.PENDING.toDbValue()
)
```

**Change 2** (Line ~234):
```kotlin
// Before:
val pendingApps = applicationRepository.findBySectorIdAndStatus(id, "PENDING")

// After:
val pendingApps = applicationRepository.findBySectorIdAndStatus(
    id,
    ApplicationStatus.PENDING.toDbValue()
)
```

**Add import** at top of file:
```kotlin
import com.munserv.groundadmin.domain.ApplicationStatus
```

### 2. Verify Repository Query (Optional Enhancement)

**File**: `backend/src/main/kotlin/com/munserv/groundadmin/repository/JpaGroundAdminApplicationRepository.kt`

Consider making the status comparison case-insensitive for robustness:

```kotlin
// Optional: Use native query with LOWER() for case-insensitive matching
@Query(
    """
    SELECT a FROM GroundAdminApplicationEntity a
    WHERE a.sectorId = :sectorId
    AND LOWER(a.status) = LOWER(:status)
    """
)
fun findBySectorIdAndStatus(
    sectorId: UUID,
    status: String,
): List<GroundAdminApplicationEntity>
```

Or define status as enum in entity and use `@Enumerated(EnumType.STRING)`.

### 3. Add Unit Test

**File**: `backend/src/test/kotlin/com/munserv/admin/api/AdminControllerTest.kt`

Add test to verify pending invitations are returned:

```kotlin
@Test
@WithMockAdmin
fun `GET members with hasInvitationPending returns invited members`() {
    // Arrange
    val sectorId = testSectorId
    val memberId = MemberId(UUID.randomUUID())

    val member = createTestMember(memberId, sectorId)
    val invitation = GroundAdminApplication.createInvitation(
        memberId = memberId,
        sectorId = sectorId,
        invitedBy = adminId
    )

    every { memberRepository.findById(any<MemberId>()) } returns member
    every { applicationRepository.findBySectorIdAndStatus(sectorId, "pending") } returns listOf(invitation)

    // Act & Assert
    mockMvc.get("/api/v1/admin/members") {
        param("sectorId", sectorId.value.toString())
        param("hasInvitationPending", "true")
    }.andExpect {
        status { isOk() }
        jsonPath("$.items.length()") { value(1) }
        jsonPath("$.items[0].hasInvitationPending") { value(true) }
    }
}
```

### 4. Add Integration Test

**File**: `backend/src/test/kotlin/com/munserv/groundadmin/service/GroundAdminServiceIntegrationTest.kt`

```kotlin
@SpringBootTest
@Testcontainers
class GroundAdminServiceIntegrationTest {

    @Test
    @Transactional
    fun `invite creates application with pending status and message`() {
        // Arrange
        val admin = createAndSaveAdmin()
        val member = createAndSaveMember(sectorId = admin.sectorId)

        // Act
        val result = groundAdminService.invite(admin.id, member.id, "Welcome!")

        // Assert
        result.shouldBeInstanceOf<GroundAdminResult.Success>()

        // Verify application record
        val applications = applicationRepository.findBySectorIdAndStatus(
            admin.sectorId,
            ApplicationStatus.PENDING.toDbValue()
        )
        applications.shouldHaveSize(1)
        applications[0].apply {
            memberId shouldBe member.id
            type shouldBe ApplicationType.INVITATION
            status shouldBe ApplicationStatus.PENDING
            invitedBy shouldBe admin.id
        }

        // Verify message record
        val messages = messageRepository.findByRecipientId(member.id.value)
        messages.shouldHaveSize(1)
        messages[0].apply {
            type shouldBe MessageType.GROUND_ADMIN_INVITATION
            actionType shouldBe "accept_decline"
        }
    }
}
```

## Verification Steps

1. **Run existing tests**:
   ```bash
   ./gradlew test --tests "*GroundAdminServiceTest*"
   ./gradlew test --tests "*AdminControllerTest*"
   ```

2. **Start backend and test manually**:
   ```bash
   ./gradlew bootRun
   ```

3. **Test API directly**:
   ```bash
   # Get members with pending invitations
   curl -H "Authorization: Bearer $TOKEN" \
     "http://localhost:8080/api/v1/admin/members?sectorId=$SECTOR_ID&hasInvitationPending=true"

   # Should return members with hasInvitationPending: true
   ```

4. **Verify database**:
   ```sql
   -- Check applications table
   SELECT id, member_id, type, status, created_at
   FROM ground_admin_applications
   WHERE status = 'pending'
   ORDER BY created_at DESC;

   -- Check messages table
   SELECT id, type, recipient_id, action_type, created_at
   FROM messages
   WHERE type = 'ground_admin_invitation'
   ORDER BY created_at DESC;
   ```

## Definition of Done

- [x] `AdminController.kt` uses `ApplicationStatus.PENDING.toDbValue()` for queries (Fixed 2026-01-20)
- [ ] Unit test verifies `hasInvitationPending` filter works
- [ ] Integration test verifies full invite flow creates correct records
- [x] All existing tests pass (Verified 2026-01-20 - unrelated `IssueStateHistoryRepositoryTest` failure pre-existed)
- [ ] Manual verification: invited member appears in "Pending GA Invites" tab

## Related Files

| File | Purpose |
|------|---------|
| `AdminController.kt` | Main fix location |
| `ApplicationStatus.kt` | Enum with `toDbValue()` |
| `JpaGroundAdminApplicationRepository.kt` | Repository queries |
| `GroundAdminService.kt` | Business logic (no changes needed) |
