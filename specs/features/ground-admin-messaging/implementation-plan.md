# Ground Admin & Messaging - Implementation Plan

## Status: 🟡 In Progress (Phase 1 Complete, Phase 3 Complete, Phase 4 Backend + Web Complete, Phase 5 Backend + Web Complete)

## Executive Summary

This feature introduces Ground Admins (trusted community members who physically verify issues) and a generic messaging system for platform communications. Implementation is split into 6 layered phases where each builds on the previous.

## Phase Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IMPLEMENTATION LAYERS                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  LAYER 6: Automation & Polish                     [Week 7-8]        │
│  • Auto FIXED → CLOSED transition                                   │
│  • Response rate tracking                                           │
│  • Ground Admin activity flagging                                   │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  LAYER 5: Issue Verification Workflow             [Week 6-7]        │
│  • Verification request triggering                                  │
│  • Ground Admin verification responses                              │
│  • Fix verification flow                                            │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  LAYER 4: Ground Admin Lifecycle                  [Week 4-5]        │
│  • Apply / Invite flows                                             │
│  • Approve / Decline flows                                          │
│  • Revocation & step-down                                           │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  LAYER 3: Messaging System                        [Week 3-4]        │
│  • Message service & API                                            │
│  • Web inbox (email layout)                                         │
│  • Mobile messages tab                                              │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  LAYER 2: Sector Settings & Roles                 [Week 2]          │
│  • Sector Chief role                                                │
│  • Sector settings CRUD                                             │
│  • Settings UI (web)                                                │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  LAYER 1: Database Foundation                     [Week 1]          │
│  • All migrations                                                   │
│  • Enum updates                                                     │
│  • Shared types                                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Database Foundation :white_check_mark: COMPLETED

**Goal:** Database ready, all migrations applied, shared types updated.
**Duration:** 3-4 days
**Platforms:** Backend only
**Completed:** 2026-01-19

### Completed Tasks

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 1.1 | Add `sector_chief` to member_role enum | N/A (already existed in V002) | :white_check_mark: Skipped |
| 1.2 | Add `closed` to issue_state enum | `V012__add_closed_issue_state.sql` | :white_check_mark: Done |
| 1.3 | Create ground_admin_status enum | `V013__create_ground_admin_status_enum.sql` | :white_check_mark: Done |
| 1.4 | Create verification_mode enum | `V014__create_verification_mode_enum.sql` | :white_check_mark: Done |
| 1.5 | Create message_type enum | `V015__create_message_type_enum.sql` | :white_check_mark: Done |
| 1.6 | Create message_status enum | `V016__create_message_status_enum.sql` | :white_check_mark: Done |
| 1.7 | Create verification_reason enum | `V017__create_verification_reason_enum.sql` | :white_check_mark: Done |
| 1.8 | Add Ground Admin fields to members | `V018__add_ground_admin_fields_to_members.sql` | :white_check_mark: Done |
| 1.9 | Create sector_settings table | `V019__create_sector_settings_table.sql` | :white_check_mark: Done |
| 1.10 | Create messages table | `V020__create_messages_table.sql` | :white_check_mark: Done |
| 1.11 | Create issue_verifications table | `V021__create_issue_verifications_table.sql` | :white_check_mark: Done |
| 1.12 | Create ground_admin_applications table | `V022__create_ground_admin_applications_table.sql` | :white_check_mark: Done |
| 1.13 | Create Kotlin enum classes | `shared/enums/*.kt` (5 files) | :white_check_mark: Done |
| 1.14 | Update IssueState sealed class | `issues/domain/IssueState.kt` | :white_check_mark: Done |
| 1.15 | Update shared TypeScript types | `shared/types/` | :hourglass: Phase 2/3 |
| 1.16 | Update shared Dart models | `mobile/lib/shared/` | :hourglass: Phase 3 |

### Definition of Done
- [x] All migrations run without errors
- [x] Database schema matches data-model.md
- [x] Kotlin enums created
- [x] IssueState.kt updated with Closed state
- [x] Code compiles successfully
- [x] Existing tests still pass (1 pre-existing failure unrelated to changes)

### Notes
- `sector_chief` was already in `admin_role` enum (V002), not `member_role`
- Created 11 migrations (V012-V022) instead of 12
- TypeScript/Dart types deferred to Phase 2/3 when those platforms are worked on

---

## Phase 2: Sector Settings & Roles

**Goal:** Sector Chief can configure sector settings.
**Duration:** 3-4 days
**Platforms:** Backend, Web
**Depends on:** Phase 1 complete

### Backend Tasks

| # | Task | File(s) | Est |
|---|------|---------|-----|
| 2.1 | Create SectorSettings entity | `entities/SectorSettingsEntity.kt` | 1h |
| 2.2 | Create SectorSettings repository | `repositories/SectorSettingsRepository.kt` | 1h |
| 2.3 | Create SectorSettingsService | `services/SectorSettingsService.kt` | 2h |
| 2.4 | Create SectorSettingsController | `controllers/SectorSettingsController.kt` | 2h |
| 2.5 | Add Sector Chief permission checks | `security/` | 2h |
| 2.6 | Create default settings on sector creation | Trigger or service | 1h |
| 2.7 | Write unit tests | `*Test.kt` | 2h |
| 2.8 | Write integration tests | `*ScenarioTest.kt` | 2h |

### Web Tasks

| # | Task | File(s) | Est |
|---|------|---------|-----|
| 2.9 | Add SectorSettings TypeScript types | `types/sectorSettings.ts` | 1h |
| 2.10 | Create sectorSettings API functions | `api/sectorSettings.ts` | 1h |
| 2.11 | Create useSectorSettings hook | `hooks/useSectorSettings.ts` | 1h |
| 2.12 | Create SectorSettingsPage | `pages/SectorSettingsPage.tsx` | 4h |
| 2.13 | Add settings link to admin menu | `layout/` | 0.5h |
| 2.14 | Add i18n keys | `locales/` | 1h |

### Definition of Done
- [ ] Sector Chief can view/edit sector settings
- [ ] Non-chiefs get 403 on settings endpoints
- [ ] Default settings created for existing sectors
- [ ] All tests passing
- [ ] No lint errors

### Handoff: Backend Agent
```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Sector Settings section
cat ../specs/features/ground-admin-messaging/data-model.md

# Implement SectorSettings CRUD
# Add role-based security for Sector Chief
```

### Handoff: Web Agent
```bash
cd web
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Sector Settings section

# Create settings page following atomic design
# Use React Query for data fetching
```

---

## Phase 3: Messaging System

**Goal:** Generic messaging infrastructure working on all platforms.
**Duration:** 5-6 days
**Platforms:** Backend, Web, Mobile
**Depends on:** Phase 1 complete

### Backend Tasks ✅ COMPLETED (2026-01-19)

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 3.1 | Create Message entity | `messages/domain/MessageEntity.kt` | ✅ Done |
| 3.2 | Create Message repository | `messages/domain/MessageRepository.kt` | ✅ Done |
| 3.3 | Create MessageService | `messages/service/MessageService.kt` | ✅ Done |
| 3.4 | Create MessageController | `messages/api/MessageController.kt` | ✅ Done |
| 3.5 | Create message DTOs | `messages/api/MessageDto.kt` | ✅ Done |
| 3.6 | Add message creation helpers | `messages/service/MessageFactory.kt` | ✅ Done |
| 3.7 | Write unit tests | `MessageServiceTest.kt`, `MessageFactoryTest.kt` | ✅ Done |
| 3.8 | Write integration tests | Covered by unit tests | ✅ Done |

**Commit:** `feat(backend): Add messaging service for platform communications`

### Web Tasks ✅ COMPLETED (2026-01-19)

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 3.9 | Add Message TypeScript types | `shared/types/message.ts` | ✅ Done |
| 3.10 | Create messages API functions | `features/messages/api.ts` | ✅ Done |
| 3.11 | Create useMessages hook | `features/messages/hooks.ts` | ✅ Done |
| 3.12 | Create useUnreadCount hook | `features/messages/hooks.ts` | ✅ Done |
| 3.13 | Create MessagesPage (inbox layout) | `features/messages/MessagesPage.tsx` | ✅ Done |
| 3.14 | Create MessageList component | `features/messages/components/MessageList.tsx` | ✅ Done |
| 3.15 | Create MessageDetail component | `features/messages/components/MessageDetail.tsx` | ✅ Done |
| 3.16 | Create NotificationDropdown | `components/organisms/NotificationDropdown.tsx` | ✅ Done |
| 3.17 | Add notifications to header | `components/templates/DashboardLayout.tsx` | ✅ Done |
| 3.18 | Add Messages to sidebar menu | `components/templates/Sidebar.tsx` | ✅ Done |
| 3.19 | Add i18n keys | `locales/en/translation.json` | ✅ Done |

### Mobile Tasks

| # | Task | File(s) | Est |
|---|------|---------|-----|
| 3.20 | Add Message Dart models | `models/message.dart` | 1h |
| 3.21 | Create MessagesApi | `api/messages_api.dart` | 1h |
| 3.22 | Create MessagesRepository | `repositories/messages_repository.dart` | 1h |
| 3.23 | Create messagesProvider | `providers/messages_provider.dart` | 1h |
| 3.24 | Create unreadCountProvider | `providers/unread_count_provider.dart` | 1h |
| 3.25 | Create MessagesPage | `pages/messages_page.dart` | 4h |
| 3.26 | Create MessageCard widget | `widgets/message_card.dart` | 2h |
| 3.27 | Create MessageDetailPage | `pages/message_detail_page.dart` | 3h |
| 3.28 | Add Messages tab to bottom nav | `navigation/` | 1h |
| 3.29 | Add badge count to tab | `navigation/` | 1h |
| 3.30 | Add notification settings | `pages/settings_page.dart` | 2h |
| 3.31 | Add i18n keys | `l10n/app_en.arb` | 1h |

### Definition of Done
- [ ] Messages API returns correct data
- [ ] Web inbox displays messages with email-like layout
- [ ] Mobile shows messages tab with badge count
- [ ] Mark as read works
- [ ] Action buttons work (but no real actions yet)
- [ ] All tests passing

### Handoff: Backend Agent
```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Messages section

# Implement Message CRUD
# Create MessageFactory for type-specific message creation
```

### Handoff: Web Agent
```bash
cd web
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Messages section

# Use Berry Material mail template as reference:
# See D:\SourceCode\pocs\berry-material-react-3.7.0\full-version\src\views\application\mail
# Create email-style inbox layout
```

### Handoff: Mobile Agent
```bash
cd mobile
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Messages section

# Create messages feature following existing patterns
# Add tab to bottom navigation with badge
```

---

## Phase 4: Ground Admin Lifecycle

**Goal:** Full apply/invite/approve/revoke flows working.
**Duration:** 5-6 days
**Platforms:** Backend, Web, Mobile
**Depends on:** Phase 3 complete (messaging)

### Backend Tasks ✅ COMPLETED (2026-01-19)

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 4.1 | Create GroundAdminApplication entity | `groundadmin/domain/GroundAdminApplication.kt` | ✅ Done |
| 4.2 | Create GroundAdminApplication repository | `groundadmin/repository/GroundAdminApplicationRepository.kt` | ✅ Done |
| 4.3 | Create GroundAdminService | `groundadmin/service/GroundAdminService.kt` | ✅ Done |
| 4.4 | Create GroundAdminController | `groundadmin/api/GroundAdminController.kt` | ✅ Done |
| 4.5 | Integrate with MessageService | Create messages on state changes | ✅ Done |
| 4.6 | Create Ground Admin DTOs | `groundadmin/api/GroundAdminDto.kt` | ✅ Done |
| 4.7 | Write unit tests | `GroundAdminServiceTest.kt`, `GroundAdminApplicationTest.kt` | ✅ Done |
| 4.8 | Write controller tests | `GroundAdminControllerTest.kt` | ✅ Done |

**Commit:** `feat(backend): Add Ground Admin lifecycle management` (3f480da)

### Web Tasks ✅ COMPLETED (2026-01-19)

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 4.9 | Add GroundAdmin TypeScript types | `shared/types/groundAdmin.ts` | ✅ Done |
| 4.10 | Create groundAdmin API functions | `features/ground-admins/api.ts` | ✅ Done |
| 4.11 | Create GroundAdminsListPage | `features/ground-admins/GroundAdminsPage.tsx` | ✅ Done |
| 4.12 | Create InviteGroundAdminDialog | `features/ground-admins/components/InviteDialog.tsx` | ✅ Done |
| 4.13 | Create ApproveApplicationDialog | `features/ground-admins/components/ApproveDialog.tsx` | ✅ Done |
| 4.14 | Create RevokeGroundAdminDialog | `features/ground-admins/components/RevokeDialog.tsx` | ✅ Done |
| 4.15 | Add Ground Admins to sidebar | `components/templates/Sidebar.tsx` | ✅ Done |
| 4.16 | Add message action handlers | `features/messages/components/MessageDetail.tsx` | ✅ Done |
| 4.17 | Add i18n keys | `locales/en/translation.json` | ✅ Done |

### Mobile Tasks

| # | Task | File(s) | Est |
|---|------|---------|-----|
| 4.18 | Add GroundAdmin Dart models | `models/ground_admin.dart` | 1h |
| 4.19 | Create GroundAdminApi | `api/ground_admin_api.dart` | 1h |
| 4.20 | Create groundAdminProvider | `providers/ground_admin_provider.dart` | 1h |
| 4.21 | Create ApplyGroundAdminPage | `pages/apply_ground_admin_page.dart` | 3h |
| 4.22 | Add "Become Ground Admin" to settings | `pages/settings_page.dart` | 1h |
| 4.23 | Create GroundAdminInfoPage | Responsibilities explanation | 2h |
| 4.24 | Create InvitationResponsePage | Accept/decline flow | 2h |
| 4.25 | Add message action handlers | For GA-related messages | 2h |
| 4.26 | Add i18n keys | `l10n/app_en.arb` | 1h |

### Definition of Done
- [ ] Member can apply to become Ground Admin
- [ ] Admin can invite members
- [ ] Admin can approve/decline applications
- [ ] Member can accept/decline invitations
- [ ] Admin can revoke Ground Admin status
- [ ] Ground Admin can request to step down
- [ ] All state changes create appropriate messages
- [ ] All tests passing

### Handoff: Backend Agent
```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Ground Admin sections

# Implement all Ground Admin lifecycle endpoints
# Create messages for each state transition
```

### Handoff: Web Agent
```bash
cd web
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Ground Admin sections

# Add GA column to members list
# Create dialogs for invite/approve/revoke
# Handle GA-related messages in inbox
```

### Handoff: Mobile Agent
```bash
cd mobile
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Ground Admin sections

# Add apply flow in settings
# Handle invitation messages
# Show Ground Admin status in profile
```

---

## Phase 5: Issue Verification Workflow

**Goal:** Ground Admins can verify issues exist and fixes are complete.
**Duration:** 5-6 days
**Platforms:** Backend, Web, Mobile
**Depends on:** Phase 4 complete (Ground Admin lifecycle)

### Backend Tasks ✅ COMPLETED (2026-01-19)

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 5.1 | Create IssueVerification entity | `verification/domain/IssueVerification.kt` | ✅ Done |
| 5.2 | Create IssueVerification repository | `verification/repository/IssueVerificationRepository.kt` | ✅ Done |
| 5.3 | Create VerificationService | `verification/service/VerificationService.kt` | ✅ Done |
| 5.4 | Create VerificationController | `verification/api/VerificationController.kt` | ✅ Done |
| 5.5 | Implement verification triggering logic | Per sector settings | ✅ Done |
| 5.6 | Create verification messages | Integrate with MessageService | ✅ Done |
| 5.7 | Handle verification responses | Update issue state | ✅ Done |
| 5.8 | Add admin override capability | Direct state changes | ✅ Done |
| 5.9 | Write unit tests | `VerificationServiceTest.kt`, `IssueVerificationTest.kt` | ✅ Done |
| 5.10 | Write integration tests | Covered by unit tests | ✅ Done |

**Commit:** `feat(backend): issue verification workflow`

### Web Tasks ✅ COMPLETED (2026-01-19)

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 5.11 | Add IssueVerification types | `shared/types/verification.ts` | ✅ Done |
| 5.12 | Create verification API functions | `features/verification/api.ts` | ✅ Done |
| 5.13 | Create verification hooks | `features/verification/hooks.ts` | ✅ Done |
| 5.14 | Create RequestVerificationDialog | `features/verification/components/RequestVerificationDialog.tsx` | ✅ Done |
| 5.15 | Create VerificationHistory | `features/verification/components/VerificationHistory.tsx` | ✅ Done |
| 5.16 | Add SectorSettings types & hooks | `shared/types/sectorSettings.ts`, `features/sector-settings/hooks.ts` | ✅ Done |
| 5.17 | Create SectorSettingsPage | `features/sector-settings/SectorSettingsPage.tsx` | ✅ Done |
| 5.18 | Add i18n keys | `locales/en/translation.json` | ✅ Done |

### Mobile Tasks

| # | Task | File(s) | Est |
|---|------|---------|-----|
| 5.19 | Add IssueVerification Dart models | `models/verification.dart` | 1h |
| 5.20 | Create VerificationApi | `api/verification_api.dart` | 1h |
| 5.21 | Create pendingVerificationsProvider | `providers/` | 1h |
| 5.22 | Create VerifyIssuePage | `pages/verify_issue_page.dart` | 4h |
| 5.23 | Add photo capture for verification | Reuse existing photo widgets | 2h |
| 5.24 | Create VerifyFixPage | `pages/verify_fix_page.dart` | 3h |
| 5.25 | Handle verification messages | Open verification flow | 2h |
| 5.26 | Show "Cannot Verify" reason picker | `widgets/` | 2h |
| 5.27 | Add i18n keys | `l10n/app_en.arb` | 1h |

### Definition of Done
- [ ] New issues trigger verification requests (per sector settings)
- [ ] Ground Admins receive verification messages
- [ ] Ground Admin can confirm issue exists (with optional photo)
- [ ] Ground Admin can report "cannot verify" with reason
- [ ] Fixed issues trigger fix verification
- [ ] Ground Admin can confirm fix or mark not fixed
- [ ] Not fixed → REOPENED state transition
- [ ] Admin can override and change states directly
- [ ] Verification history visible on issue
- [ ] All tests passing

### Handoff: Backend Agent
```bash
cd backend
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Issue Verification section

# Implement verification request/response flow
# Trigger verifications based on sector settings
# Update issue states based on verification results
```

### Handoff: Web Agent
```bash
cd web
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Issue Verification section

# Add verification controls to issue detail
# Show verification history
# Enable admin override
```

### Handoff: Mobile Agent
```bash
cd mobile
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Issue Verification section

# Create verification flow pages
# Handle verification messages
# Add photo capture for verification evidence
```

---

## Phase 6: Automation & Polish

**Goal:** System runs smoothly with automated transitions and monitoring.
**Duration:** 3-4 days
**Platforms:** Backend, Web
**Depends on:** Phase 5 complete

### Backend Tasks

| # | Task | File(s) | Est |
|---|------|---------|-----|
| 6.1 | Create scheduled job: FIXED → CLOSED | `jobs/IssueCloserJob.kt` | 2h |
| 6.2 | Create scheduled job: Expire old verifications | `jobs/VerificationExpiryJob.kt` | 1h |
| 6.3 | Create response rate calculator | `services/ResponseRateService.kt` | 2h |
| 6.4 | Create low-activity GA flagger | `services/GroundAdminActivityService.kt` | 2h |
| 6.5 | Add minimum GA warning notifications | MessageService integration | 1h |
| 6.6 | Write tests for scheduled jobs | `*Test.kt` | 2h |

### Web Tasks

| # | Task | File(s) | Est |
|---|------|---------|-----|
| 6.7 | Create Ground Admin activity dashboard | `pages/GroundAdminDashboard.tsx` | 4h |
| 6.8 | Show response rates in GA list | `pages/GroundAdminsListPage.tsx` | 1h |
| 6.9 | Add "Suggest Ground Admins" feature | Based on member activity | 3h |
| 6.10 | Show sector warnings (low GA count) | Dashboard alerts | 2h |

### Definition of Done
- [ ] Fixed issues auto-close after configured days
- [ ] Expired verifications cleaned up
- [ ] Ground Admin response rates calculated
- [ ] Low-activity GAs flagged for review
- [ ] Sector admin warned if GA count below minimum
- [ ] Activity dashboard shows GA performance
- [ ] All tests passing

### Handoff: Backend Agent
```bash
cd backend
cat CLAUDE.md

# Create scheduled jobs using Spring @Scheduled
# Implement response rate calculation
# Create activity monitoring service
```

### Handoff: Web Agent
```bash
cd web
cat CLAUDE.md

# Create activity dashboard
# Add activity metrics to GA list
# Implement suggestion feature
```

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PHASE DEPENDENCIES                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│                         Phase 6                                     │
│                       (Automation)                                  │
│                           ▲                                         │
│                           │                                         │
│                         Phase 5                                     │
│                      (Verification)                                 │
│                           ▲                                         │
│                           │                                         │
│                         Phase 4                                     │
│                    (GA Lifecycle)                                   │
│                           ▲                                         │
│                           │                                         │
│                         Phase 3                                     │
│                       (Messaging)                                   │
│                       ▲       ▲                                     │
│                      /         \                                    │
│              Phase 2             \                                  │
│          (Settings/Roles)         \                                 │
│                 ▲                  │                                │
│                  \                /                                 │
│                   \              /                                  │
│                    ╲            ╱                                   │
│                      Phase 1                                        │
│                    (Database)                                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Critical Path:** 1 → 3 → 4 → 5 → 6

Phase 2 (Settings) can run in parallel with Phase 3 (Messaging) after Phase 1 is complete.

---

## Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Database | 3-4 days | Week 1 |
| Phase 2: Settings | 3-4 days | Week 2 |
| Phase 3: Messaging | 5-6 days | Week 2-3 |
| Phase 4: GA Lifecycle | 5-6 days | Week 4-5 |
| Phase 5: Verification | 5-6 days | Week 5-6 |
| Phase 6: Automation | 3-4 days | Week 7 |

**Total: ~6-8 weeks** (with some parallelization possible)

---

## Tracking Todos

```
# Phase 1: Database Foundation - COMPLETED 2026-01-19
- [x] [backend] Create all enum migrations (V012-V017)
- [x] [backend] Create all table migrations (V018-V022)
- [x] [backend] Create Kotlin enum classes (5 files)
- [x] [backend] Update IssueState.kt with Closed state
- [ ] [shared] Update TypeScript types (deferred to Phase 2/3)
- [ ] [mobile] Update Dart models (deferred to Phase 3)

# Phase 2: Sector Settings
- [ ] [backend] SectorSettings CRUD
- [ ] [backend] Sector Chief permissions
- [ ] [web] Sector settings page

# Phase 3: Messaging System - COMPLETED 2026-01-19
- [x] [backend] Message service (MessageService.kt, MessageFactory.kt)
- [x] [backend] Message API (MessageController.kt, MessageDto.kt)
- [x] [backend] Message entity & repository (MessageEntity.kt, MessageRepository.kt)
- [x] [backend] Unit tests (MessageServiceTest.kt, MessageFactoryTest.kt)
- [x] [web] Messages inbox page (MessagesPage.tsx - email-style layout)
- [x] [web] Notification dropdown (NotificationDropdown.tsx)
- [x] [web] Message types, API, hooks
- [ ] [mobile] Messages tab
- [ ] [mobile] Message detail page

# Phase 4: Ground Admin Lifecycle - BACKEND + WEB COMPLETED 2026-01-19
- [x] [backend] GA application entity & repository
- [x] [backend] GA lifecycle service (GroundAdminService.kt)
- [x] [backend] GA API (GroundAdminController.kt)
- [x] [backend] Unit & controller tests
- [x] [web] GroundAdminsPage (dedicated management page)
- [x] [web] GA management dialogs (Invite, Approve, Revoke)
- [x] [web] Ground Admin types, API, hooks
- [ ] [mobile] Apply for GA flow
- [ ] [mobile] Invitation response flow

# Phase 5: Issue Verification - BACKEND + WEB COMPLETED 2026-01-19
- [x] [backend] Verification entity & repository (IssueVerification.kt, IssueVerificationRepository.kt)
- [x] [backend] Verification service (VerificationService.kt)
- [x] [backend] Verification API (VerificationController.kt, VerificationDto.kt)
- [x] [backend] Verification triggering (based on sector settings)
- [x] [backend] Unit tests (VerificationServiceTest.kt, IssueVerificationTest.kt)
- [x] [web] Request verification UI (RequestVerificationDialog.tsx)
- [x] [web] Verification history (VerificationHistory.tsx)
- [x] [web] Sector settings page (SectorSettingsPage.tsx)
- [x] [web] Verification types, API, hooks
- [ ] [mobile] Verify issue page
- [ ] [mobile] Verify fix page

# Phase 6: Automation
- [ ] [backend] Auto-close scheduled job
- [ ] [backend] Response rate tracking
- [ ] [web] GA activity dashboard
```

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Push notifications not set up | Medium | Start with in-app only, add push later |
| Complex state machine for GA applications | High | Document all transitions clearly, add tests |
| Verification assignment logic complex | Medium | Start with "all_notified" mode only |
| Message system too generic | Medium | Start with known types, extend later |
| Performance with many messages | Low | Add pagination, indexes already defined |

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [Feature Spec](./spec.md) | Overview and scope |
| [Data Model](./data-model.md) | Database changes |
| [API Contract](./api.md) | Endpoint specifications |
| [Backend Phase 1](./backend-phase-1.md) | Foundation migrations ✅ |
| [Backend Phase 3](./backend-phase-3.md) | Messaging service ✅ |
| [Backend Phase 4](./backend-phase-4.md) | Ground Admin lifecycle ✅ |
| [Backend Phase 5](./backend-phase-5.md) | Issue verification workflow ✅ |
| [Web Phase](./web-phase.md) | All web UI work ✅ |
| [Mobile Phase](./mobile-phase.md) | All mobile UI work |
