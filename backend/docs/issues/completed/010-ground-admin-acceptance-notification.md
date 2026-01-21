---
issue: 10
title: "Web messaging when ground admin accepted"
platform: backend
status: completed
created_by: central-agent
created_at: 2026-01-21T00:00:00Z
updated_at: 2026-01-21T00:00:00Z
started_at: 2026-01-21T00:00:00Z
completed_at: 2026-01-21T00:00:00Z
dependencies: []
files_changed:
  - src/main/resources/db/migration/V024__add_ground_admin_invitation_accepted_message_type.sql
  - src/main/kotlin/com/munserv/shared/enums/MessageType.kt
  - src/main/kotlin/com/munserv/groundadmin/service/GroundAdminService.kt
tests_added:
  - src/test/kotlin/com/munserv/groundadmin/service/GroundAdminServiceTest.kt
commits: []
blockers: []
---

# Issue #10: Web messaging when ground admin accepted (Backend)

## Context

When a member accepts a Ground Admin invitation, the sector admin who sent the invitation should receive a notification message. Currently, the `acceptInvitation()` method promotes the member but does not create any notification for the admin.

This is an asymmetry with `declineInvitation()` which correctly sends a `GROUND_ADMIN_INVITATION_DECLINED` message to the inviter.

## Root Cause

In `GroundAdminService.acceptInvitation()` (line 78-108), after successfully accepting the invitation and promoting the member, no message is created to notify the inviting admin.

## What To Fix

### 1. Create Flyway Migration for New Message Type

Create file: `backend/src/main/resources/db/migration/V024__add_ground_admin_invitation_accepted_message_type.sql`

```sql
-- V024__add_ground_admin_invitation_accepted_message_type.sql
-- Description: Add message type for ground admin invitation acceptance notification
-- Author: Claude
-- Date: 2026-01-21

-- UP
ALTER TYPE message_type ADD VALUE 'ground_admin_invitation_accepted';

-- DOWN (not possible to remove enum values in PostgreSQL)
-- Would need to recreate the enum type
```

### 2. Update MessageType Enum

File: `backend/src/main/kotlin/com/munserv/shared/enums/MessageType.kt`

Add new enum value after `GROUND_ADMIN_INVITATION_DECLINED`:

```kotlin
GROUND_ADMIN_INVITATION_ACCEPTED("ground_admin_invitation_accepted"),
```

### 3. Update GroundAdminService.acceptInvitation()

File: `backend/src/main/kotlin/com/munserv/groundadmin/service/GroundAdminService.kt`

After line 106 (after `memberRepository.save(promoted)`), add notification to the inviter:

```kotlin
// Notify the inviter
application.invitedBy?.let { inviterId ->
    val admin = adminRepository.findById(AdminId(inviterId.value))
    val message = MessageEntity(
        type = MessageType.GROUND_ADMIN_INVITATION_ACCEPTED,
        title = "Ground Admin Invitation Accepted",
        body = "${member.fullName} has accepted your invitation to become a Ground Admin.",
        recipientId = inviterId.value,
        recipientType = "admin",
        senderId = memberId.value,
        senderType = "member",
        relatedEntityId = memberId.value,
        relatedEntityType = "member",
        actionType = "view",
    )
    messageService.createMessage(message)
}
```

### Files To Modify

1. `backend/src/main/resources/db/migration/V024__add_ground_admin_invitation_accepted_message_type.sql` (CREATE)
2. `backend/src/main/kotlin/com/munserv/shared/enums/MessageType.kt` (EDIT)
3. `backend/src/main/kotlin/com/munserv/groundadmin/service/GroundAdminService.kt` (EDIT)

### Changes Required

1. **Migration**: Add `ground_admin_invitation_accepted` value to `message_type` PostgreSQL enum
2. **MessageType.kt**: Add `GROUND_ADMIN_INVITATION_ACCEPTED` enum entry
3. **GroundAdminService.kt**: In `acceptInvitation()`, after promoting member, create notification message for the inviter

## Pattern Reference

Follow the same pattern used in `declineInvitation()` (lines 114-153):

```kotlin
// Notify the inviter
application.invitedBy?.let { inviterId ->
    val member = memberRepository.findById(memberId)!!
    val message = MessageEntity(
        type = MessageType.GROUND_ADMIN_INVITATION_DECLINED,
        // ... message fields
    )
    messageService.createMessage(message)
}
```

## Acceptance Criteria

- [ ] New Flyway migration creates enum value without errors
- [ ] `MessageType` Kotlin enum includes `GROUND_ADMIN_INVITATION_ACCEPTED`
- [ ] When member accepts invitation, admin receives message
- [ ] Message has correct type, title, body
- [ ] Message `recipientType` is "admin" (goes to admins table users)
- [ ] Message `relatedEntityId` points to member (for "view" action navigation)
- [ ] Tests pass
- [ ] Quality checks pass (ktlintCheck, sonar)

## Test Cases to Add

File: `backend/src/test/kotlin/com/munserv/groundadmin/service/GroundAdminServiceTest.kt`

Add test case:

```kotlin
@Test
fun `acceptInvitation should notify inviter with acceptance message`() {
    // Arrange
    val invitation = createTestInvitation(invitedBy = adminId)
    every { applicationRepository.findById(invitation.id) } returns invitation
    every { memberRepository.findById(memberId) } returns testMember
    every { applicationRepository.save(any()) } answers { firstArg() }
    every { memberRepository.save(any()) } answers { firstArg() }
    every { messageService.createMessage(any()) } answers { firstArg() }

    // Act
    val result = service.acceptInvitation(memberId, invitation.id)

    // Assert
    result.shouldBeInstanceOf<GroundAdminResult.Success>()

    val messageSlot = slot<MessageEntity>()
    verify { messageService.createMessage(capture(messageSlot)) }

    with(messageSlot.captured) {
        type shouldBe MessageType.GROUND_ADMIN_INVITATION_ACCEPTED
        recipientId shouldBe adminId.value
        recipientType shouldBe "admin"
        senderId shouldBe memberId.value
        relatedEntityId shouldBe memberId.value
        actionType shouldBe "view"
    }
}
```

## Dependencies

- None (this is Phase 1 - no external dependencies)

## Implementation Notes

### Changes Made
1. **V024 Migration**: Added `ground_admin_invitation_accepted` value to the `message_type` PostgreSQL enum
2. **MessageType.kt**: Added `GROUND_ADMIN_INVITATION_ACCEPTED("ground_admin_invitation_accepted")` enum entry after `GROUND_ADMIN_INVITATION_DECLINED`
3. **GroundAdminService.kt**: In `acceptInvitation()` method (after line 106), added notification logic to send a message to the inviting admin when a member accepts

### Tests Added
- `GroundAdminServiceTest.kt`: Added test `should notify inviter with acceptance message when invitation accepted` in the `AcceptInvitation` nested class
  - Verifies message type is `GROUND_ADMIN_INVITATION_ACCEPTED`
  - Verifies `recipientId` is the admin's ID
  - Verifies `recipientType` is "admin"
  - Verifies `relatedEntityId` points to the member for navigation

### Decisions Made
- Used `recipientType = "admin"` since the inviter is always an admin (per V023 migration that changed `invited_by` FK to reference `admins` table)
- Used `actionType = "view"` to allow the admin to navigate to the member's profile
- Set `relatedEntityId = memberId.value` and `relatedEntityType = "member"` for proper navigation context
- Followed the same pattern as `declineInvitation()` but with appropriate message type and recipient type

### Quality Checks
- ✅ ktlintCheck passed
- ✅ All GroundAdminServiceTest tests passing
- ✅ Build successful
