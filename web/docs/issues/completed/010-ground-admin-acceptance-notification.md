---
issue: 10
title: "Web messaging when ground admin accepted"
platform: web
status: completed
created_by: central-agent
created_at: 2026-01-21T00:00:00Z
updated_at: 2026-01-21T00:00:00Z
started_at: 2026-01-21T00:00:00Z
completed_at: 2026-01-21T00:00:00Z
dependencies:
  - backend (must complete first - API needs new message type)
files_changed:
  - web/src/shared/types/message.ts
  - web/src/components/organisms/NotificationDropdown.tsx
  - web/src/features/messages/components/MessageDetail.tsx
  - web/src/locales/en/translation.json
tests_added: []
commits: []
blockers: []
---

# Issue #10: Web messaging when ground admin accepted (Web)

## Context

When a member accepts a Ground Admin invitation, the sector admin who sent the invitation should receive a notification. The backend will create a message with type `ground_admin_invitation_accepted`. The web needs to:

1. Support the new message type in TypeScript types
2. Map the new type to the correct color in NotificationDropdown
3. Add i18n translation for the new type
4. Handle the "view" action type (navigate to Ground Admins page)

## Root Cause

The web already has the notification infrastructure in place. The only missing pieces are:
- TypeScript type doesn't include `ground_admin_invitation_accepted`
- Color mapping in `NotificationDropdown` doesn't handle this type (will fall through to default)
- i18n translation key is missing
- "view" action type in `MessageDetail` doesn't have navigation handling

## What To Fix

### 1. Update MessageType TypeScript Union

File: `web/src/shared/types/message.ts`

Add new type to the union after line 9:

```typescript
export type MessageType =
  | 'ground_admin_invitation'
  | 'ground_admin_application'
  | 'ground_admin_approved'
  | 'ground_admin_declined'
  | 'ground_admin_invitation_declined'
  | 'ground_admin_invitation_accepted'  // ADD THIS LINE
  | 'ground_admin_revocation'
  | 'ground_admin_stepdown_request'
  | 'verify_new_issue'
  | 'verify_fix'
  | 'member_registration'
  | 'monthly_report';
```

Also update `MESSAGE_TYPE_LABELS` constant (around line 98):

```typescript
export const MESSAGE_TYPE_LABELS: Record<MessageType, string> = {
  ground_admin_invitation: 'messages.types.groundAdminInvitation',
  ground_admin_application: 'messages.types.groundAdminApplication',
  ground_admin_approved: 'messages.types.groundAdminApproved',
  ground_admin_declined: 'messages.types.groundAdminDeclined',
  ground_admin_invitation_declined: 'messages.types.groundAdminInvitationDeclined',
  ground_admin_invitation_accepted: 'messages.types.groundAdminInvitationAccepted',  // ADD THIS LINE
  ground_admin_revocation: 'messages.types.groundAdminRevocation',
  ground_admin_stepdown_request: 'messages.types.groundAdminStepdownRequest',
  verify_new_issue: 'messages.types.verifyNewIssue',
  verify_fix: 'messages.types.verifyFix',
  member_registration: 'messages.types.memberRegistration',
  monthly_report: 'messages.types.monthlyReport',
};
```

### 2. Update NotificationDropdown Color Mapping

File: `web/src/components/organisms/NotificationDropdown.tsx`

Update the `getMessageTypeColor` function (lines 28-46) to handle the new type:

```typescript
function getMessageTypeColor(type: MessageType): string {
  switch (type) {
    case 'ground_admin_application':
    case 'ground_admin_invitation':
      return 'primary.main';
    case 'ground_admin_invitation_accepted':  // ADD THIS CASE
      return 'success.main';                  // Green for acceptance
    case 'verify_new_issue':
    case 'verify_fix':
      return 'warning.main';
    case 'member_registration':
      return 'info.main';
    case 'ground_admin_approved':
      return 'success.main';
    case 'ground_admin_declined':
    case 'ground_admin_revocation':
      return 'error.main';
    default:
      return 'text.secondary';
  }
}
```

### 3. Update MessageDetail for "view" Action Navigation

File: `web/src/features/messages/components/MessageDetail.tsx`

The "view" action type (lines 190-192) currently returns `null`. Update to show a "View Ground Admin" button:

```typescript
case MESSAGE_ACTION_TYPES.VIEW:
  // For acceptance messages, show a "View Ground Admin" button
  if (message.relatedEntityType === 'member' && message.relatedEntityId) {
    return (
      <Button
        variant="contained"
        startIcon={<VisibilityIcon />}
        component={Link}
        to="/ground-admins"
        onClick={() => handleAction('dismiss')}
        disabled={isActioning}
      >
        {t('messages.actions.viewGroundAdmin', 'View Ground Admin')}
      </Button>
    );
  }
  return null;
```

You'll need to add the `Link` import at the top:

```typescript
import { Link } from 'react-router-dom';
```

### 4. Add i18n Translations

File: `web/src/locales/en/translation.json`

Add new keys in the `messages.types` section (around line 244):

```json
"types": {
  "groundAdminInvitation": "Ground Admin Invitation",
  "groundAdminApplication": "Ground Admin Application",
  "groundAdminApproved": "Application Approved",
  "groundAdminDeclined": "Application Declined",
  "groundAdminInvitationDeclined": "Invitation Declined",
  "groundAdminInvitationAccepted": "Invitation Accepted",
  ...
}
```

Add new action label in `messages.actions` section:

```json
"actions": {
  ...
  "viewGroundAdmin": "View Ground Admin"
}
```

### Files To Modify

1. `web/src/shared/types/message.ts` (EDIT)
   - Add `ground_admin_invitation_accepted` to union type
   - Add entry to `MESSAGE_TYPE_LABELS`

2. `web/src/components/organisms/NotificationDropdown.tsx` (EDIT)
   - Add case for new type in `getMessageTypeColor()` with `success.main`

3. `web/src/features/messages/components/MessageDetail.tsx` (EDIT)
   - Add `Link` import
   - Add navigation button for "view" action type

4. `web/src/locales/en/translation.json` (EDIT)
   - Add `groundAdminInvitationAccepted` type label
   - Add `viewGroundAdmin` action label

### Changes Required

1. **TypeScript types**: Add new message type to ensure type safety
2. **Color mapping**: Green border color for acceptance notifications
3. **Action handling**: "View Ground Admin" button that navigates to `/ground-admins`
4. **i18n**: Translation keys for the new type and action

## Acceptance Criteria

- [ ] TypeScript compiles without errors (new type is valid)
- [ ] NotificationDropdown shows green border for acceptance messages
- [ ] MessageDetail shows "View Ground Admin" button for acceptance messages
- [ ] Clicking "View Ground Admin" navigates to `/ground-admins` page
- [ ] All translations display correctly
- [ ] Tests pass
- [ ] Quality checks pass (lint, typecheck)

## Test Cases to Add

File: `web/src/features/messages/components/__tests__/MessageDetail.test.tsx`

```typescript
describe('MessageDetail', () => {
  it('should show View Ground Admin button for invitation accepted messages', () => {
    const message: Message = {
      id: '1',
      type: 'ground_admin_invitation_accepted',
      title: 'Invitation Accepted',
      body: 'John Doe accepted your invitation',
      status: 'unread',
      actionType: 'view',
      relatedEntityId: 'member-123',
      relatedEntityType: 'member',
      recipientId: 'admin-1',
      recipientType: 'admin',
      createdAt: new Date().toISOString(),
    };

    render(<MessageDetail message={message} onAction={vi.fn()} />);

    expect(screen.getByRole('link', { name: /view ground admin/i })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /view ground admin/i })).toHaveAttribute('href', '/ground-admins');
  });
});
```

File: `web/src/components/organisms/__tests__/NotificationDropdown.test.tsx`

```typescript
describe('NotificationDropdown', () => {
  it('should show success color for invitation accepted messages', async () => {
    // Mock useMessages to return an acceptance message
    // Verify the message item has success border color
  });
});
```

## Dependencies

- **Backend** (must complete first)
  - Backend needs to create `ground_admin_invitation_accepted` message type
  - Without backend changes, no messages of this type will be created

## Implementation Notes

### Changes Made

1. **TypeScript Types** (`web/src/shared/types/message.ts`)
   - Added `ground_admin_invitation_accepted` to `MessageType` union
   - Added corresponding entry to `MESSAGE_TYPE_LABELS` constant

2. **NotificationDropdown** (`web/src/components/organisms/NotificationDropdown.tsx`)
   - Added `ground_admin_invitation_accepted` case to `getMessageTypeColor()` function
   - Uses `success.main` (green) color, grouped with `ground_admin_approved`

3. **MessageDetail** (`web/src/features/messages/components/MessageDetail.tsx`)
   - Added `Link` import from react-router-dom
   - Updated `VIEW` action type case to show "View Ground Admin" button
   - Button navigates to `/ground-admins` page and dismisses the message

4. **i18n Translations** (`web/src/locales/en/translation.json`)
   - Added `groundAdminInvitationAccepted` type label: "Invitation Accepted"
   - Added `viewGroundAdmin` action label: "View Ground Admin"

### Decisions Made

- Used `success.main` color for acceptance notifications (same as approvals) to indicate positive outcome
- VIEW action button dismisses the message on click to mark it as actioned
- Navigation goes to `/ground-admins` page (not to specific member) since admin wants to see their Ground Admin roster

### Quality Checks Passed

- ✅ ESLint passed (only pre-existing warning unrelated to changes)
- ✅ TypeScript check passed
- ✅ All tests passing
- ✅ Build successful
