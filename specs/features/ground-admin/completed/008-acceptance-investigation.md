# Investigation: Ground Admin Acceptance not working

**Issue:** #8
**Date:** 2026-01-21
**Platforms:** Backend (primary), Web (display), Database (state)

## Problem Statement

When a member accepts an invitation to become a Ground Admin on the mobile app, this is not reflected in the Web Application. The member remains in the "Pending GA Invites" tab instead of moving to the active Ground Admins list.

### Expected Behavior
1. Member accepts invitation on Mobile application
2. Sector Admin goes to messages and sees acceptance notification
3. Member appears in Ground Admins list (not Pending GA Invites)
4. Revoke action is available for the member

### Actual Behavior
- Message shows as "actioned" in database
- Application status remains "pending"
- Member `is_ground_admin` remains false
- Web still shows member in "Pending GA Invites" tab

## Investigation Steps

1. **Traced the mobile acceptance flow:**
   - Member opens invitation message
   - Clicks "Accept" button
   - Mobile calls `POST /messages/{id}/action` with `{ "action": "accept" }`

2. **Examined MessageService.performAction():**
   - Method only marks message as "actioned"
   - Does NOT call any Ground Admin service

3. **Verified database state:**
   ```sql
   -- Message shows as actioned
   SELECT status FROM messages WHERE id = '74edb28d-...' → 'actioned'

   -- But application is still pending
   SELECT status FROM ground_admin_applications WHERE id = '8e742e13-...' → 'pending'

   -- And member is not a ground admin
   SELECT is_ground_admin FROM members WHERE id = '304c8733-...' → false
   ```

4. **Confirmed GroundAdminService.acceptInvitation() works correctly:**
   - Logic is correct when called directly
   - Updates application status to "accepted"
   - Promotes member to Ground Admin
   - Just never gets called from message flow

## Root Cause

**The `MessageService.performAction()` method only updates the message status but does NOT call `GroundAdminService.acceptInvitation()` to actually process the acceptance.**

Location: `backend/src/main/kotlin/com/munserv/messages/service/MessageService.kt:136-162`

```kotlin
@Transactional
fun performAction(...): MessageResult {
    // ... validation ...

    // BUG: Only marks message, doesn't process the actual action
    message.markAsActioned(request.action)
    val saved = messageRepository.save(message)

    return MessageResult.Success(MessageResponse.from(saved))
}
```

## Affected Components

### Backend (FIX NEEDED)
- `backend/src/main/kotlin/com/munserv/messages/service/MessageService.kt`
  - `performAction()` needs to call GroundAdminService for invitation actions

### Web (NO CHANGES NEEDED)
- Display logic is correct
- Just waiting for backend to properly update data

### Mobile (NO CHANGES NEEDED)
- API calls are correct
- Using message action flow as designed

### Database (NO CHANGES NEEDED)
- Schema is correct
- Just needs backend to update the data

## Fix Approach

1. **Inject GroundAdminService into MessageService**
2. **In performAction(), check if message is a Ground Admin invitation**
3. **Call appropriate GroundAdminService method based on action:**
   - "accept" → `acceptInvitation()`
   - "decline" → `declineInvitation()`
4. **Only mark message as actioned if service call succeeds**
5. **Add notification to sector admins on acceptance** (bonus)
