# Feature: Ground Admin & Messaging System

**Goal:** Enable physical verification of issues through community Ground Admins with a unified messaging system for all platform communications.
**Platforms:** backend, web, mobile
**Status:** 🔴 Not Started

## Summary

Remote Sector Admins cannot physically verify if reported issues exist or if fixes are complete. Ground Admins are trusted community members who perform on-the-ground verification. This feature also introduces a generic messaging system to handle all platform notifications and action requests.

## Stories

- GA1: As a member, I can apply to become a Ground Admin
- GA2: As a Sector Admin, I can invite members to become Ground Admins
- GA3: As a member, I can accept or decline a Ground Admin invitation
- GA4: As a Sector Admin, I can approve or decline Ground Admin applications
- GA5: As a Ground Admin, I can verify that a reported issue exists
- GA6: As a Ground Admin, I can verify that a fixed issue is actually resolved
- GA7: As a Ground Admin, I can request to step down from my role
- GA8: As a Sector Admin, I can revoke a Ground Admin's status
- GA9: As a Sector Chief, I can configure how Ground Admins are notified
- GA10: As any user, I can view and act on messages in my inbox

## Core Concepts

### Ground Admin Role

Ground Admins are **members with an additional flag** (`is_ground_admin: true`), not a separate role. They:

- Physically verify that reported issues exist (REPORTED → CONFIRMED)
- Physically verify that fixed issues are actually resolved (FIXED stays or → REOPENED)
- Operate within their assigned sector only
- Can be placed "on hold" if response rate is low

### Ground Admin States

| Status | Description | Receives Requests? |
|--------|-------------|-------------------|
| `active` | Normal operation | Yes |
| `on_hold` | Low response, temporarily paused | No |
| `inactive` | Stepped down or revoked | No |

### New Issue State: CLOSED

Issues now transition from FIXED to CLOSED automatically after a configurable period:

```
REPORTED → CONFIRMED → IN_PROGRESS → FIXED → CLOSED
                                        ↓
                                    REOPENED (if verification fails)
```

CLOSED issues are excluded from active lists but available in history.

### Sector Settings (New)

| Setting | Type | Description | Default |
|---------|------|-------------|---------|
| `new_issue_verification_mode` | Enum | How Ground Admins are notified for new issues | `all_notified` |
| `fix_verification_mode` | Enum | How Ground Admins are notified for fix verification | `all_notified` |
| `days_fixed_before_closed` | Integer | Days before FIXED → CLOSED | 7 |
| `minimum_ground_admins` | Integer | Warn if below this number | 2 |

**Verification Modes:**
- `all_notified` - All Ground Admins in sector receive notification
- `admin_assigns` - Admin manually picks a Ground Admin
- `nearest_auto` - System assigns nearest Ground Admin (based on address)
- `first_come` - All notified, first to respond handles it

### Verification Responses

| Action | Required | Optional |
|--------|----------|----------|
| **Confirm Exists** | Button tap | Photo |
| **Cannot Verify** | Reason enum | Note |
| **Confirm Fixed** | Button tap | Photo |
| **Not Fixed** | Button tap | — |

**Cannot Verify Reasons:**
- `busy` - Ground Admin is unavailable
- `away` - Ground Admin is out of area
- `cannot_find` - Issue location unclear
- `wrong_location` - GPS coordinates incorrect
- `not_an_issue` - Reported item is not actually a problem

### Role Hierarchy Update

```
Pod Chief
└── Pod Admin
    └── Sector Chief        ← NEW: Setup, settings, creates admins
        └── Sector Admin    ← Existing: Day-to-day operations
            └── Ground Admin ← NEW: Flag on member
                └── Member
```

## Messaging System

A generic messaging system handles all platform communications.

### Message Types

| Type | Recipient | Trigger | Actions |
|------|-----------|---------|---------|
| `ground_admin_invitation` | Member | Admin invites | Accept / Decline |
| `ground_admin_application` | Sector Admin | Member applies | Approve / Decline |
| `ground_admin_approved` | Member | Application approved | Acknowledge |
| `ground_admin_declined` | Member | Application declined | Acknowledge |
| `ground_admin_invitation_declined` | Sector Admin | Member declined invite | Acknowledge |
| `ground_admin_revocation` | Ground Admin | Admin revokes status | Acknowledge |
| `ground_admin_stepdown_request` | Sector Admin | GA wants to step down | Approve |
| `verify_new_issue` | Ground Admin(s) | New issue needs verification | Confirm / Cannot Verify |
| `verify_fix` | Ground Admin(s) | Fixed issue needs verification | Confirm Fixed / Not Fixed |
| `member_registration` | Sector Admin | New member registered | Approve / Reject |
| `monthly_report` | All Members | System monthly summary | View |

### Message Structure

```
Message {
  id: MessageId
  type: MessageType (enum)
  recipientId: MemberId
  recipientType: 'member' | 'admin'
  title: string
  body: string
  status: 'unread' | 'read' | 'actioned' | 'dismissed'
  actionType: string? (e.g., 'accept_decline', 'approve_reject')
  relatedEntityId: UUID? (issue_id, member_id, etc.)
  relatedEntityType: string? ('issue', 'member', etc.)
  actionedAt: DateTime?
  actionResult: string? (e.g., 'accepted', 'declined')
  createdAt: DateTime
  readAt: DateTime?
}
```

### UI Locations

**Mobile:**
- Messages tab in bottom navigation (with badge count)
- User can configure push notifications vs in-app only in settings

**Web:**
- Header: Notification bell with dropdown (like Berry Material NotificationSection)
- Left menu: Messages link to full inbox
- Inbox: Email-style layout (list left, content right) per Berry Material mail example

## Dependencies

- Member registration flow complete ✅
- Issue state management complete ✅
- Sector/Admin structure exists ✅
- Push notification infrastructure (Firebase) — needed for mobile

## API Endpoints (New)

See: `specs/features/ground-admin-messaging/api.md` for full contract.

### Messages
- `GET /messages` - List messages for current user
- `GET /messages/{id}` - Get message detail
- `PATCH /messages/{id}/read` - Mark as read
- `POST /messages/{id}/action` - Perform action (accept, decline, etc.)

### Ground Admin
- `POST /members/me/ground-admin/apply` - Apply to become Ground Admin
- `POST /members/{id}/ground-admin/invite` - Invite member (admin only)
- `POST /members/{id}/ground-admin/approve` - Approve application (admin only)
- `POST /members/{id}/ground-admin/decline` - Decline application (admin only)
- `POST /members/me/ground-admin/accept` - Accept invitation
- `POST /members/me/ground-admin/decline` - Decline invitation
- `POST /members/{id}/ground-admin/revoke` - Revoke status (admin only)
- `POST /members/me/ground-admin/stepdown` - Request to step down
- `GET /sectors/{id}/ground-admins` - List Ground Admins in sector

### Sector Settings
- `GET /sectors/{id}/settings` - Get sector settings (chief only)
- `PATCH /sectors/{id}/settings` - Update sector settings (chief only)

### Issue Verification
- `POST /issues/{id}/request-verification` - Request Ground Admin verification
- `POST /issues/{id}/verify` - Submit verification result

## Notes

- Ground Admin is a **flag**, not a separate role — simplifies permissions
- Sector Chief is a new role above Sector Admin — handles setup/configuration
- Messages are generic and extensible for future message types
- Admin can always override issue states manually
- Push notifications are opt-in per member preference

## Open Questions (Resolved)

| Question | Decision |
|----------|----------|
| What to call Super Members? | **Ground Admin** |
| Separate role or flag? | **Flag on member** |
| Multi-sector Ground Admins? | **No, single sector only** |
| How are GAs notified? | **Configurable per sector** |
| Push vs in-app? | **Member preference in settings** |
| Ground Admin limits? | **No max, configurable minimum** |
| Revocation flow? | **Admin initiates, GA acknowledges, can be put on hold** |

## Related Documents

| Document | Purpose |
|----------|---------|
| [Implementation Plan](./implementation-plan.md) | Phased rollout with handoffs |
| [Data Model](./data-model.md) | Database changes |
| [API Contract](./api.md) | Endpoint specifications |
| [Backend Phase 1](./backend-phase-1.md) | Foundation: migrations, enums |
| [Backend Phase 2](./backend-phase-2.md) | Messaging service |
| [Backend Phase 3](./backend-phase-3.md) | Sector settings & roles |
| [Backend Phase 4](./backend-phase-4.md) | Ground Admin lifecycle |
| [Backend Phase 5](./backend-phase-5.md) | Verification workflow |
| [Web Phase](./web-phase.md) | Admin portal UI |
| [Mobile Phase](./mobile-phase.md) | Member app UI |
