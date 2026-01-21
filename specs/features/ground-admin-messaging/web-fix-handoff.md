# Web Handoff: Verify Ground Admin Invitation Flow

**Priority**: Medium (depends on backend fix)
**Estimated Effort**: 30 minutes - 1 hour
**Related Bug**: `bug-fix-invitation-flow.md`

## Current Status

The web UI code appears **correct**. The issue is in the backend returning empty results due to case mismatch in the status query.

After the backend fix is applied, the web UI should work correctly. This handoff is for **verification and potential enhancements**.

## Verification Checklist

After backend fix is deployed:

### 1. Invite Flow

- [ ] Go to Members page (`/members`)
- [ ] Select "All" tab
- [ ] Find a member who is NOT a Ground Admin
- [ ] Click the invite icon (person with + badge)
- [ ] Enter optional message
- [ ] Click "Send Invitation"
- [ ] Dialog should close
- [ ] Toast/notification should appear (if implemented)

### 2. Pending Invites Tab

- [ ] Click "Pending GA Invites" tab
- [ ] Verify invited member appears in list
- [ ] Verify member shows `hasInvitationPending: true` badge
- [ ] Verify "Revoke" action is available

### 3. Revoke Flow

- [ ] Click revoke icon on invited member
- [ ] Confirm revocation in dialog
- [ ] Verify member is removed from "Pending GA Invites" tab
- [ ] Verify member reappears in "All" tab without pending status

## Potential Enhancement: Success Feedback

Currently the invite flow closes the dialog on success but doesn't provide explicit feedback. Consider adding a toast notification.

**File**: `web/src/features/members/MembersPage.tsx`

```typescript
// In handleInviteConfirm callback (around line 193-214)
const handleInviteConfirm = useCallback(
  (message?: string) => {
    if (!inviteDialog.member) return;

    inviteMutation.mutate(
      { memberId: inviteDialog.member.id, message },
      {
        onSuccess: () => {
          setInviteDialog({ open: false, member: null });
          refetch();
          // TODO: Add success toast
          // enqueueSnackbar(t('members.inviteSent'), { variant: 'success' });
        },
        onError: (error) => {
          console.error('Failed to send Ground Admin invitation:', error);
          setInviteDialog({ open: false, member: null });
          // TODO: Add error toast
          // enqueueSnackbar(t('errors.inviteFailed'), { variant: 'error' });
        },
      }
    );
  },
  [inviteDialog.member, inviteMutation, refetch, setInviteDialog]
);
```

**Add translations** in `web/src/locales/en/translation.json`:
```json
{
  "members": {
    "inviteSent": "Ground Admin invitation sent successfully",
    "inviteRevoked": "Invitation revoked"
  },
  "errors": {
    "inviteFailed": "Failed to send invitation. Please try again."
  }
}
```

## Add Test Coverage

**File**: `web/src/features/ground-admins/hooks.test.tsx`

Add test for invite mutation:

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { useInviteGroundAdmin } from './hooks';
import { wrapper } from '@/test/test-utils';

describe('useInviteGroundAdmin', () => {
  it('should send invitation and invalidate queries on success', async () => {
    const memberId = 'member-123';
    const message = 'Welcome to the team!';

    server.use(
      http.post(`/api/v1/members/${memberId}/ground-admin/invite`, () =>
        HttpResponse.json({
          applicationId: 'app-456',
          status: 'pending',
        })
      )
    );

    const { result } = renderHook(() => useInviteGroundAdmin(), { wrapper });

    await result.current.mutateAsync({ memberId, message });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data).toEqual({
      applicationId: 'app-456',
      status: 'pending',
    });
  });

  it('should handle invitation error', async () => {
    const memberId = 'member-123';

    server.use(
      http.post(`/api/v1/members/${memberId}/ground-admin/invite`, () =>
        HttpResponse.json(
          { code: 'conflict', message: 'Already invited' },
          { status: 409 }
        )
      )
    );

    const { result } = renderHook(() => useInviteGroundAdmin(), { wrapper });

    await expect(
      result.current.mutateAsync({ memberId })
    ).rejects.toThrow();
  });
});
```

**File**: `web/src/features/members/MembersPage.test.tsx`

Add E2E-style test for invite flow:

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { MembersPage } from './MembersPage';
import { wrapper } from '@/test/test-utils';

describe('MembersPage - Invite Flow', () => {
  it('should show invited member in Pending GA Invites tab after invite', async () => {
    // Setup mock data
    const member = {
      id: 'member-1',
      firstName: 'John',
      surname: 'Doe',
      // ... other fields
      hasInvitationPending: false,
    };

    const invitedMember = {
      ...member,
      hasInvitationPending: true,
      pendingApplicationId: 'app-123',
    };

    let inviteSent = false;

    server.use(
      http.get('/api/v1/admin/members', ({ request }) => {
        const url = new URL(request.url);
        const hasInvitationPending = url.searchParams.get('hasInvitationPending');

        if (hasInvitationPending === 'true') {
          return HttpResponse.json({
            items: inviteSent ? [invitedMember] : [],
            pagination: { page: 1, limit: 10, totalItems: inviteSent ? 1 : 0, totalPages: 1 },
          });
        }

        return HttpResponse.json({
          items: [inviteSent ? invitedMember : member],
          pagination: { page: 1, limit: 10, totalItems: 1, totalPages: 1 },
        });
      }),
      http.post('/api/v1/members/member-1/ground-admin/invite', () => {
        inviteSent = true;
        return HttpResponse.json({ applicationId: 'app-123', status: 'pending' });
      })
    );

    render(<MembersPage />, { wrapper });

    // Wait for initial load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    // Click invite button
    const inviteButton = screen.getByRole('button', { name: /invite/i });
    fireEvent.click(inviteButton);

    // Fill dialog and submit
    const sendButton = screen.getByRole('button', { name: /send invitation/i });
    fireEvent.click(sendButton);

    // Switch to Pending GA Invites tab
    const pendingTab = screen.getByRole('tab', { name: /pending ga invites/i });
    fireEvent.click(pendingTab);

    // Verify member appears
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
  });
});
```

## Files Reference

| File | Purpose | Changes Needed |
|------|---------|----------------|
| `MembersPage.tsx` | Page component | Optional: Add toast notifications |
| `hooks.ts` | React Query hooks | No changes (correct) |
| `api.ts` | API calls | No changes (correct) |
| `InviteDialog.tsx` | Invite modal | No changes (correct) |
| `hooks.test.tsx` | Hook tests | Add invite mutation test |
| `translation.json` | i18n | Add success/error messages |

## Definition of Done

- [ ] Backend fix is deployed
- [ ] Manual verification passes all checkpoints
- [ ] (Optional) Toast notifications added for better UX
- [ ] Tests added for invite flow
- [ ] All existing tests pass

## Dependencies

This task depends on:
1. **Backend fix** (`backend-fix-handoff.md`) - Must be completed first
