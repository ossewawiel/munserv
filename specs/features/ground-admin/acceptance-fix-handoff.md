# Bug Fix: Ground Admin Acceptance not working

**Issue:** #8
**Status:** In Progress
**Platform(s):** Web, Backend, Database

## Problem

When a member accepts an invitation to become a Ground Admin on the mobile app, this is not reflected in the Web Application. The member remains in the "Pending GA" tab instead of moving to the active Ground Admins list.

### Expected Behavior
1. Member accepts invitation on Mobile application
2. Sector Admin goes to messages and should see a message regarding the acceptance. A button in the message details should navigate the admin to the Ground Admins Members list.
3. Or the admin goes to the members list and clicks on the Ground Admins tab.
4. The Member that accepted the invitation should now be visible in the list. In the action column a new button should be present that allows the admin to revoke the member's status as Ground admin.

### Actual Behavior
Nothing changes on web site. Member is still shown in Pending GA tab.

## Root Cause

**The `MessageService.performAction()` method only updates the message status but does NOT call `GroundAdminService.acceptInvitation()` to actually process the acceptance.**

### Flow Analysis

1. Admin invites member → Creates `GroundAdminApplication` (status=pending) + Message (type=ground_admin_invitation)
2. Member opens message on mobile → Shows invitation with Accept/Decline buttons
3. Member clicks "Accept" → Mobile calls `POST /messages/{id}/action` with `{ "action": "accept" }`
4. **BUG**: `MessageService.performAction()` marks message as "actioned" but NEVER calls `GroundAdminService.acceptInvitation()`
5. Result: Message shows as actioned, but:
   - Application status remains "pending"
   - Member `is_ground_admin` remains false
   - No notification sent to sector admins
   - Web still shows member in "Pending GA Invites" tab

### Database Evidence

```sql
-- Message shows as actioned
SELECT status FROM messages WHERE id = '74edb28d-...' → 'actioned'

-- But application is still pending
SELECT status FROM ground_admin_applications WHERE id = '8e742e13-...' → 'pending'

-- And member is not a ground admin
SELECT is_ground_admin FROM members WHERE id = '304c8733-...' → false
```

## Affected Files

### Backend (Primary Fix Location)
- `backend/src/main/kotlin/com/munserv/messages/service/MessageService.kt` - Main fix needed here
- `backend/src/test/kotlin/com/munserv/messages/service/MessageServiceTest.kt` - Add test

### Files Already Working Correctly (No Changes Needed)
- `GroundAdminService.acceptInvitation()` - Logic is correct, just not being called
- `GroundAdminController.acceptInvitation()` - Endpoint works, but mobile uses message action flow
- Mobile and Web - UI works correctly, backend is the issue

## Fix Approach

Modify `MessageService.performAction()` to handle Ground Admin invitation actions:

```kotlin
@Transactional
fun performAction(
    id: UUID,
    recipientId: UUID,
    recipientType: String,
    request: MessageActionRequest,
): MessageResult {
    // ... existing validation ...

    // Handle Ground Admin invitation actions
    if (message.type == MessageType.GROUND_ADMIN_INVITATION && message.relatedEntityType == "ground_admin_application") {
        val applicationId = GroundAdminApplicationId(message.relatedEntityId!!)
        val memberId = MemberId(recipientId)

        val result = when (request.action) {
            "accept" -> groundAdminService.acceptInvitation(memberId, applicationId)
            "decline" -> groundAdminService.declineInvitation(memberId, applicationId, request.note)
            else -> return MessageResult.ValidationError(listOf("Invalid action: ${request.action}"))
        }

        // Check if Ground Admin service call succeeded
        if (result is GroundAdminResult.Success) {
            // Also send notification to sector admins about acceptance
            // (existing acceptInvitation doesn't do this)
        } else {
            return MessageResult.ValidationError(listOf(result.errorMessage))
        }
    }

    message.markAsActioned(request.action)
    val saved = messageRepository.save(message)
    return MessageResult.Success(MessageResponse.from(saved))
}
```

### Additional Fix: Notify Sector Admins on Acceptance

`GroundAdminService.acceptInvitation()` should also notify sector admins that a member accepted. Add:

```kotlin
// In acceptInvitation(), after promoting member
val sector = sectorRepository.findById(member.sectorId)!!
notifySectorAdminsOfAcceptance(member.sectorId, memberId, member.fullName)
```

## Testing

- [ ] Unit tests for backend acceptance logic
- [ ] Integration tests for status transitions
- [ ] Manual verification on web

## Verification

1. Start mobile app and accept Ground Admin invitation
2. Open web admin portal
3. Check Messages for acceptance notification
4. Navigate to Members > Ground Admins tab
5. Verify accepted member appears in list
6. Verify Pending GA tab no longer shows the member
7. Verify revoke action is available for the member
