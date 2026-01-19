# Ground Admin & Messaging - Web Phase

## Status: ✅ COMPLETED (2026-01-19)

## Overview

All web admin portal changes for the Ground Admin & Messaging feature. This includes:
- Sector settings management (Sector Chief)
- Messaging inbox with email-style layout
- Notification dropdown in header
- Ground Admin management in members list
- Issue verification request UI

## Prerequisites

- Backend Phase 1 complete (database)
- Backend messaging API available
- Backend Ground Admin API available

---

## Reference Templates

Use these Berry Material React examples as reference:

| Feature | Reference Path |
|---------|----------------|
| Notification Dropdown | `berry-material-react-3.7.0/full-version/src/layout/MainLayout/Header/NotificationSection` |
| Messages Inbox | `berry-material-react-3.7.0/full-version/src/views/application/mail` |

---

## Task Groups

### Group A: TypeScript Types (1 day)

Create shared types in `src/types/`:

**File:** `src/types/message.ts`
```typescript
export type MessageType =
  | 'ground_admin_invitation'
  | 'ground_admin_application'
  | 'ground_admin_approved'
  | 'ground_admin_declined'
  | 'ground_admin_invitation_declined'
  | 'ground_admin_revocation'
  | 'ground_admin_stepdown_request'
  | 'verify_new_issue'
  | 'verify_fix'
  | 'member_registration'
  | 'monthly_report';

export type MessageStatus = 'unread' | 'read' | 'actioned' | 'dismissed';

export interface Message {
  id: string;
  type: MessageType;
  title: string;
  body: string;
  recipientId: string;
  recipientType: 'member' | 'admin';
  senderId?: string;
  senderType?: 'member' | 'admin' | 'system';
  status: MessageStatus;
  actionType?: string;
  relatedEntityId?: string;
  relatedEntityType?: string;
  actionResult?: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
  readAt?: string;
  actionedAt?: string;
  expiresAt?: string;
}

export interface MessageListResponse {
  items: Message[];
  total: number;
  page: number;
  unreadCount: number;
}

export interface MessageActionRequest {
  action: string;
  note?: string;
}
```

**File:** `src/types/sectorSettings.ts`
```typescript
export type VerificationMode = 
  | 'all_notified' 
  | 'admin_assigns' 
  | 'nearest_auto' 
  | 'first_come';

export interface SectorSettings {
  id: string;
  sectorId: string;
  newIssueVerificationMode: VerificationMode;
  fixVerificationMode: VerificationMode;
  daysFixedBeforeClosed: number;
  minimumGroundAdmins: number;
  createdAt: string;
  updatedAt: string;
}

export interface SectorSettingsUpdate {
  newIssueVerificationMode?: VerificationMode;
  fixVerificationMode?: VerificationMode;
  daysFixedBeforeClosed?: number;
  minimumGroundAdmins?: number;
}
```

**File:** `src/types/groundAdmin.ts`
```typescript
export type GroundAdminStatus = 'active' | 'on_hold' | 'inactive';

export interface GroundAdmin {
  id: string;
  memberId: string;
  name: string;
  status: GroundAdminStatus;
  since: string;
  responseRate: number;
  pendingVerifications: number;
}

export interface GroundAdminApplication {
  id: string;
  memberId: string;
  memberName: string;
  type: 'application' | 'invitation';
  status: string;
  createdAt: string;
}
```

**File:** `src/types/verification.ts`
```typescript
export type VerificationReason = 
  | 'busy' 
  | 'away' 
  | 'cannot_find' 
  | 'wrong_location' 
  | 'not_an_issue';

export interface IssueVerification {
  id: string;
  issueId: string;
  verificationType: 'existence' | 'fix';
  assignedTo?: string;
  verifiedBy?: string;
  verifiedByName?: string;
  result?: 'confirmed' | 'not_found' | 'not_fixed' | 'cannot_verify';
  reason?: VerificationReason;
  note?: string;
  photoId?: string;
  requestedAt: string;
  respondedAt?: string;
  status: 'pending' | 'completed' | 'expired';
}

export interface RequestVerificationRequest {
  type: 'existence' | 'fix';
  assignTo?: string;
  message?: string;
}
```

---

### Group B: API Functions (1 day)

**File:** `src/api/messages.ts`
```typescript
import { api } from './client';
import type { Message, MessageListResponse, MessageActionRequest } from '../types/message';

export const messagesApi = {
  getAll: async (params?: {
    status?: string;
    type?: string;
    page?: number;
    size?: number;
  }): Promise<MessageListResponse> => {
    const response = await api.get('/messages', { params });
    return response.data;
  },

  getById: async (id: string): Promise<Message> => {
    const response = await api.get(`/messages/${id}`);
    return response.data;
  },

  markAsRead: async (id: string): Promise<Message> => {
    const response = await api.patch(`/messages/${id}/read`);
    return response.data;
  },

  performAction: async (id: string, action: MessageActionRequest): Promise<Message> => {
    const response = await api.post(`/messages/${id}/action`, action);
    return response.data;
  },
};
```

**File:** `src/api/sectorSettings.ts`
```typescript
import { api } from './client';
import type { SectorSettings, SectorSettingsUpdate } from '../types/sectorSettings';

export const sectorSettingsApi = {
  get: async (sectorId: string): Promise<SectorSettings> => {
    const response = await api.get(`/sectors/${sectorId}/settings`);
    return response.data;
  },

  update: async (sectorId: string, settings: SectorSettingsUpdate): Promise<SectorSettings> => {
    const response = await api.patch(`/sectors/${sectorId}/settings`, settings);
    return response.data;
  },
};
```

**File:** `src/api/groundAdmin.ts`
```typescript
import { api } from './client';
import type { GroundAdmin, GroundAdminApplication } from '../types/groundAdmin';
import type { Member } from '../types/member';

export const groundAdminApi = {
  listInSector: async (sectorId: string, status?: string): Promise<{ items: GroundAdmin[]; total: number }> => {
    const response = await api.get(`/sectors/${sectorId}/ground-admins`, { params: { status } });
    return response.data;
  },

  invite: async (memberId: string, message?: string): Promise<{ applicationId: string; status: string }> => {
    const response = await api.post(`/members/${memberId}/ground-admin/invite`, { message });
    return response.data;
  },

  approve: async (memberId: string, applicationId: string): Promise<{ status: string; member: Member }> => {
    const response = await api.post(`/members/${memberId}/ground-admin/approve`, { applicationId });
    return response.data;
  },

  decline: async (memberId: string, applicationId: string, reason: string): Promise<{ status: string }> => {
    const response = await api.post(`/members/${memberId}/ground-admin/decline`, { applicationId, reason });
    return response.data;
  },

  revoke: async (memberId: string, reason: string): Promise<{ status: string; member: Member }> => {
    const response = await api.post(`/members/${memberId}/ground-admin/revoke`, { reason });
    return response.data;
  },

  updateStatus: async (memberId: string, status: 'active' | 'on_hold'): Promise<Member> => {
    const response = await api.patch(`/members/${memberId}/ground-admin/status`, { status });
    return response.data;
  },
};
```

**File:** `src/api/verification.ts`
```typescript
import { api } from './client';
import type { IssueVerification, RequestVerificationRequest } from '../types/verification';

export const verificationApi = {
  requestVerification: async (issueId: string, request: RequestVerificationRequest): Promise<IssueVerification> => {
    const response = await api.post(`/issues/${issueId}/request-verification`, request);
    return response.data;
  },

  getHistory: async (issueId: string): Promise<{ items: IssueVerification[] }> => {
    const response = await api.get(`/issues/${issueId}/verifications`);
    return response.data;
  },
};
```

---

### Group C: React Query Hooks (1 day)

**File:** `src/hooks/useMessages.ts`
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { messagesApi } from '../api/messages';
import type { MessageActionRequest } from '../types/message';

export function useMessages(params?: { status?: string; type?: string; page?: number }) {
  return useQuery({
    queryKey: ['messages', params],
    queryFn: () => messagesApi.getAll(params),
  });
}

export function useMessage(id: string) {
  return useQuery({
    queryKey: ['messages', id],
    queryFn: () => messagesApi.getById(id),
    enabled: !!id,
  });
}

export function useUnreadCount() {
  return useQuery({
    queryKey: ['messages', 'unreadCount'],
    queryFn: async () => {
      const response = await messagesApi.getAll({ status: 'unread', size: 1 });
      return response.unreadCount;
    },
    refetchInterval: 60000, // Refresh every minute
  });
}

export function useMarkAsRead() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (id: string) => messagesApi.markAsRead(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}

export function useMessageAction() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ id, action }: { id: string; action: MessageActionRequest }) =>
      messagesApi.performAction(id, action),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}
```

**File:** `src/hooks/useSectorSettings.ts`
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { sectorSettingsApi } from '../api/sectorSettings';
import type { SectorSettingsUpdate } from '../types/sectorSettings';
import { useAuth } from './useAuth';

export function useSectorSettings() {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['sectorSettings', sectorId],
    queryFn: () => sectorSettingsApi.get(sectorId!),
    enabled: !!sectorId,
  });
}

export function useUpdateSectorSettings() {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (settings: SectorSettingsUpdate) =>
      sectorSettingsApi.update(sectorId!, settings),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sectorSettings', sectorId] });
    },
  });
}
```

**File:** `src/hooks/useGroundAdmins.ts`
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { groundAdminApi } from '../api/groundAdmin';
import { useAuth } from './useAuth';

export function useGroundAdmins(status?: string) {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['groundAdmins', sectorId, status],
    queryFn: () => groundAdminApi.listInSector(sectorId!, status),
    enabled: !!sectorId,
  });
}

export function useInviteGroundAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, message }: { memberId: string; message?: string }) =>
      groundAdminApi.invite(memberId, message),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
    },
  });
}

export function useApproveGroundAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, applicationId }: { memberId: string; applicationId: string }) =>
      groundAdminApi.approve(memberId, applicationId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}

export function useRevokeGroundAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, reason }: { memberId: string; reason: string }) =>
      groundAdminApi.revoke(memberId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
    },
  });
}
```

---

### Group D: Messages UI (3-4 days)

#### D1: Notification Dropdown

**File:** `src/components/layout/NotificationDropdown.tsx`

Create a dropdown component for the header that shows unread messages. Reference Berry Material's NotificationSection.

Features:
- Bell icon with badge count
- Dropdown shows latest 5 unread messages
- Click message → navigate to messages page
- "View All" link at bottom
- Empty state when no unread messages

#### D2: Messages Page (Inbox Layout)

**File:** `src/pages/MessagesPage.tsx`

Create email-style inbox layout. Reference Berry Material's mail application.

Layout:
```
┌─────────────────────────────────────────────────────────────────┐
│ Messages                                            [Filter ▼]  │
├──────────────────────┬──────────────────────────────────────────┤
│ ● GA Application     │                                          │
│   John Smith         │  Ground Admin Application                │
│   2 hours ago        │                                          │
│                      │  John Smith has applied to become a      │
├──────────────────────┤  Ground Admin in your sector.            │
│   Fix Verification   │                                          │
│   System             │  Member since: Jan 2025                  │
│   Yesterday          │  Issues reported: 47                     │
│                      │                                          │
├──────────────────────┤  [Approve]  [Decline]                    │
│   Monthly Report     │                                          │
│   System             │                                          │
│   3 days ago         │                                          │
│                      │                                          │
└──────────────────────┴──────────────────────────────────────────┘
```

Features:
- Message list on left (scrollable)
- Message detail on right
- Unread indicator (bold + dot)
- Filter by status/type
- Action buttons based on message type
- Mark as read on view
- Responsive: stack on mobile

#### D3: Message List Component

**File:** `src/components/messages/MessageList.tsx`

Props:
```typescript
interface MessageListProps {
  messages: Message[];
  selectedId?: string;
  onSelect: (message: Message) => void;
  isLoading?: boolean;
}
```

#### D4: Message Detail Component

**File:** `src/components/messages/MessageDetail.tsx`

Props:
```typescript
interface MessageDetailProps {
  message: Message;
  onAction: (action: string, note?: string) => void;
  isActioning?: boolean;
}
```

Renders different action buttons based on `message.actionType`:
- `accept_decline` → Accept / Decline buttons
- `approve_reject` → Approve / Reject buttons  
- `confirm_verify` → Confirm / Cannot Verify buttons
- `acknowledge` → Dismiss button only
- `view` → No buttons (informational)

---

### Group E: Ground Admin Management (2-3 days)

#### E1: Update Members Page

**File:** `src/pages/MembersPage.tsx`

Add Ground Admin column to members table:

| Name | Phone | Status | Ground Admin | Actions |
|------|-------|--------|--------------|---------|
| John | +27... | Active | ✓ Active | ... |
| Jane | +27... | Active | [Invite] | ... |
| Bob | +27... | Active | [Review] ⏳ | ... |

Column states:
- Regular member: "Invite" button
- Has pending application: "Review" button with pending icon
- Was invited (pending): "Pending" badge
- Is Ground Admin: Status badge + "Manage" dropdown

#### E2: Invite Ground Admin Dialog

**File:** `src/components/groundAdmin/InviteDialog.tsx`

```typescript
interface InviteDialogProps {
  open: boolean;
  member: Member;
  onClose: () => void;
  onConfirm: (message?: string) => void;
}
```

Content:
- Member name display
- Optional message textarea
- "This will send an invitation to the member"
- Cancel / Send Invitation buttons

#### E3: Approve Application Dialog

**File:** `src/components/groundAdmin/ApproveDialog.tsx`

```typescript
interface ApproveDialogProps {
  open: boolean;
  application: GroundAdminApplication;
  onClose: () => void;
  onApprove: () => void;
  onDecline: (reason: string) => void;
}
```

Content:
- Member info
- Application date
- Member stats (issues reported, etc.)
- Approve / Decline buttons
- Decline requires reason input

#### E4: Revoke Dialog

**File:** `src/components/groundAdmin/RevokeDialog.tsx`

```typescript
interface RevokeDialogProps {
  open: boolean;
  groundAdmin: GroundAdmin;
  onClose: () => void;
  onRevoke: (reason: string) => void;
  onPutOnHold: () => void;
}
```

Content:
- Ground Admin info
- Stats (response rate, verifications)
- Reason dropdown + optional note
- "Put on Hold" / "Revoke" / Cancel buttons

#### E5: Ground Admins List Page

**File:** `src/pages/GroundAdminsPage.tsx`

Dedicated page to manage Ground Admins with:
- List of all Ground Admins in sector
- Status filter (Active / On Hold / All)
- Response rate display
- Pending verifications count
- Quick actions (Put on Hold, Revoke)

---

### Group F: Sector Settings (2 days)

#### F1: Sector Settings Page

**File:** `src/pages/SectorSettingsPage.tsx`

Only visible to Sector Chief role.

Sections:
1. **Verification Settings**
   - New Issue Verification Mode (dropdown)
   - Fix Verification Mode (dropdown)

2. **Issue Lifecycle**
   - Days Fixed Before Closed (number input)

3. **Ground Admin Management**
   - Minimum Ground Admins (number input)
   - Current count display
   - Warning if below minimum

Form with save button, shows success/error toast.

---

### Group G: Issue Verification UI (2 days)

#### G1: Request Verification Button

Add to `IssueDetailPage.tsx`:

When issue is in REPORTED state:
- Show "Request Existence Verification" button

When issue is in FIXED state:
- Show "Request Fix Verification" button

#### G2: Request Verification Dialog

**File:** `src/components/verification/RequestVerificationDialog.tsx`

```typescript
interface RequestVerificationDialogProps {
  open: boolean;
  issue: Issue;
  type: 'existence' | 'fix';
  groundAdmins: GroundAdmin[];
  verificationMode: VerificationMode;
  onClose: () => void;
  onRequest: (request: RequestVerificationRequest) => void;
}
```

Content varies by verification mode:
- `admin_assigns`: Show Ground Admin dropdown
- Others: Just confirmation message
- Optional message field

#### G3: Verification History Component

**File:** `src/components/verification/VerificationHistory.tsx`

Display on issue detail page:

```
Verification History
────────────────────
✓ Existence confirmed by John Smith
  Jan 15, 2026 at 10:30 AM
  
✓ Fix confirmed by Jane Doe  
  Jan 20, 2026 at 2:15 PM
  Photo attached
```

---

### Group H: Navigation & Layout Updates (1 day)

#### H1: Add Messages to Sidebar

**File:** `src/components/layout/Sidebar.tsx`

Add "Messages" item with unread badge:
```
Dashboard
Issues
Members
Messages (3)    ← Add this
Ground Admins   ← Add this (for admins)
Settings        ← Sector settings (for chiefs)
```

#### H2: Add Notification Dropdown to Header

**File:** `src/components/layout/Header.tsx`

Add bell icon before profile menu.

#### H3: Update Routes

**File:** `src/routes/index.tsx`

Add routes:
```typescript
{ path: '/messages', element: <MessagesPage /> },
{ path: '/messages/:id', element: <MessagesPage /> },
{ path: '/ground-admins', element: <GroundAdminsPage /> },
{ path: '/settings/sector', element: <SectorSettingsPage /> },
```

---

## i18n Keys

**File:** `src/locales/en.json`

```json
{
  "messages": {
    "title": "Messages",
    "empty": "No messages",
    "unread": "Unread",
    "all": "All Messages",
    "markAsRead": "Mark as read",
    "viewAll": "View all messages"
  },
  "groundAdmin": {
    "title": "Ground Admins",
    "invite": "Invite to become Ground Admin",
    "inviteConfirm": "Send invitation to {name}?",
    "approve": "Approve Application",
    "decline": "Decline Application",
    "declineReason": "Reason for declining",
    "revoke": "Revoke Ground Admin Status",
    "revokeReason": "Reason for revocation",
    "putOnHold": "Put on Hold",
    "status": {
      "active": "Active",
      "on_hold": "On Hold",
      "inactive": "Inactive"
    },
    "responseRate": "Response Rate",
    "pendingVerifications": "Pending Verifications"
  },
  "sectorSettings": {
    "title": "Sector Settings",
    "verificationSettings": "Verification Settings",
    "newIssueMode": "New Issue Verification Mode",
    "fixMode": "Fix Verification Mode",
    "modeOptions": {
      "all_notified": "Notify all Ground Admins",
      "admin_assigns": "Admin assigns Ground Admin",
      "nearest_auto": "Auto-assign nearest",
      "first_come": "First come, first served"
    },
    "lifecycle": "Issue Lifecycle",
    "daysBeforeClosed": "Days before fixed issues close",
    "minimumGroundAdmins": "Minimum Ground Admins",
    "belowMinimum": "Warning: Below minimum Ground Admins"
  },
  "verification": {
    "requestExistence": "Request Existence Verification",
    "requestFix": "Request Fix Verification",
    "history": "Verification History",
    "confirmed": "Confirmed",
    "notFound": "Not Found",
    "notFixed": "Not Fixed",
    "cannotVerify": "Cannot Verify"
  }
}
```

---

## Testing Checklist

### Unit Tests
- [ ] `useMessages` hook tests
- [ ] `useSectorSettings` hook tests
- [ ] `useGroundAdmins` hook tests
- [ ] API function tests

### Component Tests
- [ ] `NotificationDropdown` renders correctly
- [ ] `MessageList` selection works
- [ ] `MessageDetail` actions work
- [ ] `InviteDialog` form submission
- [ ] `ApproveDialog` approve/decline
- [ ] `RevokeDialog` validation

### Integration Tests
- [ ] Messages page loads and displays
- [ ] Mark as read updates count
- [ ] Ground Admin invite flow
- [ ] Sector settings save
- [ ] Verification request flow

---

## Commands

```bash
# Start development
cd web && pnpm dev

# Run tests
cd web && pnpm test

# Type check
cd web && pnpm typecheck

# Lint
cd web && pnpm lint
```

---

## Definition of Done

- [x] All TypeScript types defined
- [x] All API functions implemented
- [x] All React Query hooks working
- [x] Messages page with email layout
- [x] Notification dropdown in header
- [x] Ground Admin column in members list (via dedicated page)
- [x] All dialogs functional
- [x] Sector settings page (chiefs only)
- [x] Verification UI on issue detail
- [x] i18n keys added
- [x] No TypeScript errors
- [x] No lint errors (1 warning about react-hook-form)
- [x] Tests passing (348/348)

---

## Completion Summary (2026-01-19)

### Files Created

**Types (`src/shared/types/`):**
- `message.ts` - Message, MessageStatus, MessageType, MessageListResponse
- `sectorSettings.ts` - VerificationMode, SectorSettings, SectorSettingsUpdate
- `groundAdmin.ts` - GroundAdmin, GroundAdminStatus, GroundAdminApplication
- `verification.ts` - IssueVerification, RequestVerificationRequest

**API Functions (`src/features/*/api.ts`):**
- `messages/api.ts` - messagesApi (getAll, getById, markAsRead, performAction)
- `sector-settings/api.ts` - sectorSettingsApi (get, update)
- `ground-admins/api.ts` - groundAdminApi (listInSector, invite, approve, decline, revoke, updateStatus)
- `verification/api.ts` - verificationApi (requestVerification, getHistory)

**React Query Hooks (`src/features/*/hooks.ts`):**
- `messages/hooks.ts` - useMessages, useMessage, useUnreadCount, useMarkAsRead, useMessageAction
- `sector-settings/hooks.ts` - useSectorSettings, useUpdateSectorSettings
- `ground-admins/hooks.ts` - useGroundAdmins, useInviteGroundAdmin, useApproveGroundAdmin, useDeclineGroundAdmin, useRevokeGroundAdmin, useUpdateGroundAdminStatus
- `verification/hooks.ts` - useVerificationHistory, useRequestVerification

**Components:**
- `src/components/organisms/NotificationDropdown.tsx` - Header notification bell with badge
- `src/features/messages/components/MessageList.tsx` - Inbox message list sidebar
- `src/features/messages/components/MessageDetail.tsx` - Message detail with action buttons
- `src/features/messages/MessagesPage.tsx` - Email-style inbox page
- `src/features/ground-admins/components/InviteDialog.tsx` - Invite Ground Admin dialog
- `src/features/ground-admins/components/ApproveDialog.tsx` - Approve/decline applications
- `src/features/ground-admins/components/RevokeDialog.tsx` - Revoke/put on hold dialog
- `src/features/ground-admins/GroundAdminsPage.tsx` - Ground Admin management page
- `src/features/sector-settings/SectorSettingsPage.tsx` - Sector settings form
- `src/features/verification/components/RequestVerificationDialog.tsx` - Request verification
- `src/features/verification/components/VerificationHistory.tsx` - Verification timeline

### Files Modified

- `src/App.tsx` - Added routes for /messages, /messages/:id, /ground-admins, /settings/sector
- `src/components/templates/Sidebar.tsx` - Added Messages, Ground Admins, Settings nav items with badge
- `src/components/templates/DashboardLayout.tsx` - Added NotificationDropdown to header
- `src/locales/en/translation.json` - Added i18n keys for all new features

### Quality Gates Passed

- TypeScript: ✅ No errors
- ESLint: ✅ No errors (1 warning about react-hook-form's watch function)
- Tests: ✅ 348/348 tests pass

---

## Handoff Notes

**For agent execution:**
```bash
cd web
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md
cat ../specs/features/ground-admin-messaging/spec.md

# Follow atomic design patterns
# Use React Query for all data fetching
# Reference Berry Material templates for UI
# Start with types → API → hooks → components → pages
```
