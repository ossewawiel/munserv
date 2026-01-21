# Investigation: Web messaging when ground admin accepted

**Issue:** #10
**Date:** 2026-01-21
**Platforms:** Backend, Web, Database

## Problem Statement

When a member accepts an invitation to become a ground admin, the sector admin should receive a notification in the web admin portal. Currently:
- The invitation acceptance is processed correctly (member becomes ground admin)
- However, **no message is sent to the sector admin** when the member accepts the invitation
- The web already has the notification infrastructure (NotificationDropdown, badge, Messages page)

## Investigation Steps

1. **Reviewed GroundAdminService.acceptInvitation()** (`backend/.../groundadmin/service/GroundAdminService.kt:78-108`)
   - Accepts the invitation and promotes the member
   - **Does NOT create any notification message for the admin who sent the invitation**

2. **Compared with GroundAdminService.declineInvitation()** (`backend/.../groundadmin/service/GroundAdminService.kt:114-153`)
   - When member DECLINES, a `GROUND_ADMIN_INVITATION_DECLINED` message IS sent to the inviter
   - Shows the pattern that should be followed for acceptance

3. **Reviewed MessageType enum** (`backend/.../shared/enums/MessageType.kt`)
   - Has `GROUND_ADMIN_APPROVED` but this is for member-initiated applications
   - **Missing a `GROUND_ADMIN_INVITATION_ACCEPTED` type** for admin-initiated invitations

4. **Reviewed Web notification infrastructure**
   - `NotificationDropdown.tsx` - Shows badge with unread count, dropdown with recent messages
   - `MessagesPage.tsx` - Email-style interface with list and detail view
   - `hooks.ts` - `useUnreadCount()` polls every 60 seconds
   - All infrastructure exists, just needs the backend to create the message

5. **Reviewed message type color mapping in NotificationDropdown**
   - `ground_admin_*` types map to `primary` color
   - Need to ensure new type also maps correctly

## Root Cause

**Missing notification creation in `GroundAdminService.acceptInvitation()`**

When a member accepts a Ground Admin invitation:
1. The invitation status is updated to ACCEPTED
2. The member is promoted to Ground Admin
3. **No message is created to notify the admin who sent the invitation**

The asymmetry is clear:
- `declineInvitation()` → Creates `GROUND_ADMIN_INVITATION_DECLINED` message to inviter
- `acceptInvitation()` → Creates nothing (BUG)

## Affected Components

### Backend
- `GroundAdminService.kt` - Add notification creation in `acceptInvitation()`
- `MessageType.kt` - Add new `GROUND_ADMIN_INVITATION_ACCEPTED` enum value
- Database migration - Add new message type to `message_type` enum

### Web
- `NotificationDropdown.tsx` - Add color mapping for new message type (may already work with `ground_admin_*` pattern)
- `message.ts` - Add new type to TypeScript union
- Translation file - Add i18n key for new message type

### Database
- Add `ground_admin_invitation_accepted` to `message_type` enum

## Fix Approach

### Phase 1: Database (must complete first)
Add new enum value to `message_type` PostgreSQL enum

### Phase 2: Backend (after database)
1. Add `GROUND_ADMIN_INVITATION_ACCEPTED` to `MessageType` enum
2. In `GroundAdminService.acceptInvitation()`, after successful acceptance:
   - Look up the inviter from `application.invitedBy`
   - Create message with type `GROUND_ADMIN_INVITATION_ACCEPTED`
   - Message should include: member name who accepted, link to ground admins page

### Phase 3: Web (after backend)
1. Add `ground_admin_invitation_accepted` to TypeScript `MessageType` union
2. Verify color mapping works (should inherit from `ground_admin_*` pattern)
3. Add i18n translation key
4. Verify "View Ground Admin" action button works with the new message type

## Message Format (Proposed)

```kotlin
MessageEntity(
    type = MessageType.GROUND_ADMIN_INVITATION_ACCEPTED,
    title = "Ground Admin Invitation Accepted",
    body = "${member.fullName} has accepted your invitation to become a Ground Admin.",
    recipientId = inviterId.value,
    recipientType = "admin",  // Goes to sector admin
    senderId = memberId.value,
    senderType = "member",
    relatedEntityId = memberId.value,  // Link to the new ground admin
    relatedEntityType = "member",
    actionType = "view",  // Can click to view ground admins page
)
```

## Acceptance Criteria Mapping

| Acceptance Criteria | Implementation |
|---------------------|----------------|
| Message count bubble next to Messages icon | Already implemented - backend just needs to create message |
| See unread message when clicking message icon | Already implemented - NotificationDropdown shows recent unread |
| Taken to messages screen when clicking message | Already implemented - dropdown links to /messages |
| Message open with details visible | Already implemented - MessageDetail component |
| Message flagged as read on click | Already implemented - `useMarkAsRead()` hook |
| Button to navigate to ground admins screen | Web needs to add action handling for new type |

## Dependencies

```
Database migration (Phase 1)
    ↓
Backend changes (Phase 2) - depends on database
    ↓
Web changes (Phase 3) - depends on backend API
```

## Related Code Locations

| File | Line | Purpose |
|------|------|---------|
| `GroundAdminService.kt` | 78-108 | `acceptInvitation()` - add notification |
| `GroundAdminService.kt` | 114-153 | `declineInvitation()` - reference pattern |
| `MessageType.kt` | 10-24 | Add new enum value |
| `NotificationDropdown.tsx` | 42-55 | Color mapping (verify) |
| `message.ts` | 15-30 | TypeScript types |
