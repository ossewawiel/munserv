# Mobile Handoff: Verify Ground Admin Invitation Messages

**Priority**: Medium (depends on backend fix)
**Estimated Effort**: 30 minutes - 1 hour
**Related Bug**: `bug-fix-invitation-flow.md`

## Current Status

The mobile app code appears **correct** for receiving and displaying Ground Admin invitation messages. The message flow is:

1. Backend creates `Message` record with `type = 'ground_admin_invitation'`
2. Mobile fetches messages via `GET /api/v1/me/messages`
3. Messages displayed in Messages tab
4. User can Accept/Decline via action buttons

The bug is that **no invitation was being created** due to the backend status query bug. Once fixed, the mobile should work.

## Verification Checklist

After backend fix is deployed:

### 1. Message Appears in Inbox

- [ ] Login as the invited member
- [ ] Go to Messages tab
- [ ] Verify invitation message appears with:
  - Blue "Invitation" badge
  - Title: "Ground Admin Invitation"
  - Body: "{Admin Name} has invited you to become a Ground Admin for {Sector Name}: {Optional message}"
  - Unread status indicator

### 2. Message Detail

- [ ] Tap on the invitation message
- [ ] Verify message detail shows:
  - Type badge (blue "Invitation")
  - Title and timestamp
  - Full message body
  - Accept/Decline buttons visible

### 3. Accept Action

- [ ] Tap "Accept" button
- [ ] Verify:
  - Loading state shows
  - Success snackbar appears
  - Navigate back to messages list
  - Message status changes to "actioned" with "accepted" result

### 4. Decline Action (test with different invitation)

- [ ] Tap "Decline" button
- [ ] Verify:
  - Loading state shows
  - Success snackbar appears
  - Navigate back to messages list
  - Message status changes to "actioned" with "declined" result

### 5. Ground Admin Status

After accepting:
- [ ] Navigate to Profile page
- [ ] Verify Ground Admin badge/status appears (if implemented)
- [ ] Verify home page shows GA-specific options (if implemented)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  MessageDetailPage                                           │
│  └── MessageActionButtons (Accept/Decline)                  │
│        └── onAction → messageActionProvider.performAction() │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  MessageActionNotifier                                       │
│  └── performAction(messageId, action)                       │
│        └── repository.performAction(...)                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  MessagesRepository                                          │
│  └── POST /api/v1/me/messages/{id}/action                   │
│        { action: "accept" | "decline", note?: string }      │
└─────────────────────────────────────────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `messages_page.dart` | Messages list with inbox display |
| `message_detail_page.dart` | Message detail with action buttons |
| `message_action_buttons.dart` | Accept/Decline buttons based on `actionType` |
| `messages_providers.dart` | State management for messages |
| `messages_repository.dart` | API calls for messages |
| `shared/models/message.dart` | Message model with `MessageType` enum |

## Action Types Mapping

The `actionType` field determines which buttons appear:

| actionType | Buttons | Used For |
|------------|---------|----------|
| `accept_decline` | Accept, Decline | GA Invitations |
| `approve_reject` | Approve, Reject | GA Applications, Step-down requests |
| `confirm_verify` | Confirm, Cannot Verify | Issue verification |
| `acknowledge` | Dismiss | Info messages |

## Message Types Reference

```dart
enum MessageType {
  groundAdminInvitation,      // ← This is the invitation to member
  groundAdminApplication,     // Application from member to admin
  verifyNewIssue,
  verifyFix,
  groundAdminApproved,
  groundAdminDeclined,
  groundAdminRevocation,
  groundAdminInvitationDeclined,
  groundAdminStepdownRequest,
  memberRegistration,
  monthlyReport,
}
```

## Potential Enhancements

### 1. Refresh Messages on Tab Focus

Currently messages are fetched once on page load. Consider refreshing when the tab becomes active:

```dart
// In messages_page.dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Check if returning to this tab
  ref.invalidate(messagesProvider);
}
```

### 2. Push Notification Support (Future)

When push notifications are implemented:
- Register device token with backend
- Handle notification tap to navigate to message detail
- Update unread count badge in real-time

### 3. Confirmation Dialog for Decline

Currently decline happens immediately. Consider adding a confirmation:

```dart
// In message_detail_page.dart
Future<void> _handleDecline(Message message) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.declineInvitation),
      content: Text(l10n.declineConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.decline),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    _handleAction(message, 'decline', null);
  }
}
```

## Test Scenarios

### Manual Testing with Backend

1. **Create invitation via web**:
   - Login as admin on web
   - Go to Members, invite a member
   - Note the member's phone number

2. **Check mobile**:
   - Login as the invited member on mobile
   - Check Messages tab
   - Should see invitation

3. **Accept invitation**:
   - Open message detail
   - Tap Accept
   - Verify success

4. **Verify status changed**:
   - Refresh messages
   - Message should show "Accepted" status
   - Member should now have Ground Admin status

### Unit Test Coverage

Existing tests should cover:
- `MessagesRepository.performAction()` - API call
- `MessageActionNotifier.performAction()` - State management
- `MessageActionButtons` - Button display based on `actionType`

Add test for accept/decline flow:

```dart
// In messages_providers_test.dart
test('performAction accept updates message status', () async {
  // Arrange
  when(() => mockRepository.performAction('msg-1', 'accept'))
      .thenAnswer((_) async => Result.success(acceptedMessage));

  // Act
  final result = await container
      .read(messageActionProvider.notifier)
      .performAction('msg-1', 'accept');

  // Assert
  expect(result.isSuccess, true);
  verify(() => mockRepository.performAction('msg-1', 'accept')).called(1);
});
```

## Definition of Done

- [ ] Backend fix is deployed
- [ ] Invitation message appears in member's inbox
- [ ] Message detail shows correct info and buttons
- [ ] Accept action works and updates status
- [ ] Decline action works and updates status
- [ ] Unread count updates correctly
- [ ] No console errors during flow

## Dependencies

This task depends on:
1. **Backend fix** (`backend-fix-handoff.md`) - Must be completed first
2. Backend endpoint `POST /api/v1/me/messages/{id}/action` exists and works
