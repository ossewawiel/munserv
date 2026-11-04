# Ground Admin & Messaging - Agent Execution Guide

## Overview

This document provides the exact execution order and handoff instructions for AI agents working on the Ground Admin & Messaging feature across the backend, web, and mobile projects.

## Execution Principles

1. **Backend leads each phase** - API must be ready before UI work begins
2. **Web and Mobile can parallelize** - After backend for each phase is complete
3. **Test at boundaries** - Verify API works before starting UI
4. **Commit at milestones** - Each completed phase = git commit

---

## Phase Execution Order

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EXECUTION TIMELINE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Week 1                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 1: Database Foundation (Backend Only)                         │    │
│  │ Agent: Backend                                                       │    │
│  │ Duration: 3-4 days                                                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  Week 2                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 2: Sector Settings     │  PHASE 3a: Messaging Backend         │    │
│  │ Agent: Backend → Web         │  Agent: Backend                      │    │
│  │ Duration: 3-4 days           │  Duration: 3 days                    │    │
│  │ (Can run in parallel)        │                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  Week 3                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 3b: Messaging UI                                              │    │
│  │ Agents: Web + Mobile (parallel)                                     │    │
│  │ Duration: 3-4 days                                                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  Week 4                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 4a: Ground Admin Backend                                      │    │
│  │ Agent: Backend                                                       │    │
│  │ Duration: 3 days                                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  Week 5                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 4b: Ground Admin UI                                           │    │
│  │ Agents: Web + Mobile (parallel)                                     │    │
│  │ Duration: 3-4 days                                                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  Week 6                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 5a: Verification Backend                                      │    │
│  │ Agent: Backend                                                       │    │
│  │ Duration: 3 days                                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  Week 7                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 5b: Verification UI                                           │    │
│  │ Agents: Web + Mobile (parallel)                                     │    │
│  │ Duration: 3-4 days                                                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  Week 8                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PHASE 6: Automation & Polish                                        │    │
│  │ Agents: Backend → Web                                               │    │
│  │ Duration: 3-4 days                                                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Handoff Instructions

### Step 1: Backend Agent - Phase 1 (Database Foundation)

**When:** Start of project
**Prerequisites:** None
**Duration:** 3-4 days

```bash
# Handoff prompt for Backend Agent:

cd /home/marsel/munserv/backend

# Read context
cat CLAUDE.md
cat ../database/CLAUDE.md
cat ../specs/features/ground-admin-messaging/spec.md
cat ../specs/features/ground-admin-messaging/data-model.md
cat ../specs/features/ground-admin-messaging/backend-phase-1.md

# Task: Create all database migrations and Kotlin enums
# 
# Deliverables:
# 1. Create 12 migration files in database/migrations/
# 2. Create/update Kotlin enum classes
# 3. Run migrations: ./gradlew flywayMigrate
# 4. Verify: ./gradlew test
# 5. Commit: "feat(db): add ground admin and messaging schema"
#
# Success criteria:
# - All migrations apply without errors
# - Existing tests still pass
# - Can query new tables via psql/MCP
```

**Completion signal:** All migrations applied, tests passing, commit made.

---

### Step 2: Backend Agent - Phase 2 (Sector Settings)

**When:** After Phase 1 complete
**Prerequisites:** Phase 1 migrations applied
**Duration:** 2 days

```bash
# Handoff prompt for Backend Agent:

cd /home/marsel/munserv/backend

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Sector Settings section
cat ../specs/features/ground-admin-messaging/data-model.md

# Task: Implement Sector Settings CRUD
#
# Deliverables:
# 1. SectorSettingsEntity.kt
# 2. SectorSettingsRepository.kt
# 3. SectorSettingsService.kt
# 4. SectorSettingsController.kt (GET/PATCH /sectors/{id}/settings)
# 5. Add Sector Chief permission checks
# 6. Unit tests
# 7. Integration tests
# 8. Commit: "feat(backend): sector settings CRUD"
#
# API to implement:
# - GET /api/v1/sectors/{id}/settings
# - PATCH /api/v1/sectors/{id}/settings
#
# Success criteria:
# - Endpoints return correct data
# - Only Sector Chief can access
# - Tests passing
```

---

### Step 3: Backend Agent - Phase 3a (Messaging Service)

**When:** After Phase 1 complete (can run parallel with Step 2)
**Prerequisites:** Phase 1 migrations applied
**Duration:** 3 days

```bash
# Handoff prompt for Backend Agent:

cd /home/marsel/munserv/backend

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Messages section
cat ../specs/features/ground-admin-messaging/data-model.md

# Task: Implement Messaging Service
#
# Deliverables:
# 1. MessageEntity.kt
# 2. MessageRepository.kt
# 3. MessageService.kt (create, list, markRead, performAction)
# 4. MessageController.kt
# 5. MessageDto.kt (request/response DTOs)
# 6. MessageFactory.kt (helper to create different message types)
# 7. Unit tests
# 8. Integration tests
# 9. Commit: "feat(backend): messaging service"
#
# API to implement:
# - GET /api/v1/messages
# - GET /api/v1/messages/{id}
# - PATCH /api/v1/messages/{id}/read
# - POST /api/v1/messages/{id}/action
#
# Success criteria:
# - Can create messages of all types
# - List/filter/paginate works
# - Mark as read updates status
# - Action endpoint works
```

---

### Step 4: Web Agent - Phase 2 (Sector Settings UI)

**When:** After Backend Phase 2 complete
**Prerequisites:** Sector Settings API available
**Duration:** 2 days

```bash
# Handoff prompt for Web Agent:

cd /home/marsel/munserv/web

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Sector Settings section
cat ../specs/features/ground-admin-messaging/web-phase.md  # Group F

# Task: Implement Sector Settings Page
#
# Deliverables:
# 1. src/types/sectorSettings.ts
# 2. src/api/sectorSettings.ts
# 3. src/hooks/useSectorSettings.ts
# 4. src/pages/SectorSettingsPage.tsx
# 5. Add route and menu item
# 6. i18n keys
# 7. Commit: "feat(web): sector settings page"
#
# Success criteria:
# - Page loads settings from API
# - Form saves successfully
# - Only visible to Sector Chief
# - Validation works
```

---

### Step 5: Web Agent - Phase 3b (Messaging UI)

**When:** After Backend Phase 3a complete
**Prerequisites:** Messaging API available
**Duration:** 3-4 days

```bash
# Handoff prompt for Web Agent:

cd /home/marsel/munserv/web

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Messages section
cat ../specs/features/ground-admin-messaging/web-phase.md  # Groups A-D

# Reference templates:
# - Notification dropdown: berry-material-react-3.7.0/.../NotificationSection
# - Inbox layout: berry-material-react-3.7.0/.../mail

# Task: Implement Messages UI
#
# Deliverables:
# 1. src/types/message.ts
# 2. src/api/messages.ts
# 3. src/hooks/useMessages.ts, useUnreadCount.ts
# 4. src/components/layout/NotificationDropdown.tsx
# 5. src/pages/MessagesPage.tsx (email-style layout)
# 6. src/components/messages/MessageList.tsx
# 7. src/components/messages/MessageDetail.tsx
# 8. Add to header and sidebar
# 9. i18n keys
# 10. Commit: "feat(web): messaging inbox and notifications"
#
# Success criteria:
# - Notification bell shows unread count
# - Dropdown shows recent messages
# - Inbox displays with list/detail layout
# - Mark as read works
# - Actions work (buttons show based on type)
```

---

### Step 6: Mobile Agent - Phase 3b (Messaging UI)

**When:** After Backend Phase 3a complete (parallel with Web Step 5)
**Prerequisites:** Messaging API available
**Duration:** 3-4 days

```bash
# Handoff prompt for Mobile Agent:

cd /home/marsel/munserv/mobile

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Messages section
cat ../specs/features/ground-admin-messaging/mobile-phase.md  # Groups A-D

# Task: Implement Messages UI
#
# Deliverables:
# 1. lib/shared/models/message.dart (Freezed)
# 2. lib/features/messages/data/messages_api.dart
# 3. lib/features/messages/providers/messages_provider.dart
# 4. lib/features/messages/presentation/pages/messages_page.dart
# 5. lib/features/messages/presentation/pages/message_detail_page.dart
# 6. lib/features/messages/presentation/widgets/message_list_tile.dart
# 7. Add Messages tab to bottom navigation with badge
# 8. i18n keys
# 9. Run: flutter pub run build_runner build
# 10. Commit: "feat(mobile): messaging tab and inbox"
#
# Success criteria:
# - Messages tab shows in bottom nav
# - Badge shows unread count
# - List displays messages
# - Detail page shows content
# - Mark as read works
# - Actions work
```

---

### Step 7: Backend Agent - Phase 4a (Ground Admin Lifecycle)

**When:** After Phase 3 complete
**Prerequisites:** Messaging service working
**Duration:** 3 days

```bash
# Handoff prompt for Backend Agent:

cd /home/marsel/munserv/backend

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Ground Admin sections
cat ../specs/features/ground-admin-messaging/data-model.md

# Task: Implement Ground Admin Lifecycle
#
# Deliverables:
# 1. GroundAdminApplicationEntity.kt
# 2. GroundAdminApplicationRepository.kt
# 3. GroundAdminService.kt (apply, invite, approve, decline, revoke, stepdown)
# 4. GroundAdminController.kt
# 5. Update MemberService for GA fields
# 6. Integrate with MessageService (send messages on state changes)
# 7. Unit tests
# 8. Integration tests
# 9. Commit: "feat(backend): ground admin lifecycle"
#
# API to implement:
# - POST /api/v1/members/me/ground-admin/apply
# - POST /api/v1/members/{id}/ground-admin/invite
# - POST /api/v1/members/{id}/ground-admin/approve
# - POST /api/v1/members/{id}/ground-admin/decline
# - POST /api/v1/members/me/ground-admin/accept
# - POST /api/v1/members/me/ground-admin/decline
# - POST /api/v1/members/{id}/ground-admin/revoke
# - POST /api/v1/members/me/ground-admin/stepdown
# - GET /api/v1/sectors/{id}/ground-admins
# - GET /api/v1/members/me/ground-admin
#
# Success criteria:
# - All lifecycle flows work
# - Messages created automatically
# - Member flags update correctly
```

---

### Step 8: Web Agent - Phase 4b (Ground Admin Management)

**When:** After Backend Phase 4a complete
**Prerequisites:** Ground Admin API available
**Duration:** 3 days

```bash
# Handoff prompt for Web Agent:

cd /home/marsel/munserv/web

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Ground Admin sections
cat ../specs/features/ground-admin-messaging/web-phase.md  # Group E

# Task: Implement Ground Admin Management UI
#
# Deliverables:
# 1. src/types/groundAdmin.ts
# 2. src/api/groundAdmin.ts
# 3. src/hooks/useGroundAdmins.ts
# 4. Update MembersPage with GA column
# 5. src/components/groundAdmin/InviteDialog.tsx
# 6. src/components/groundAdmin/ApproveDialog.tsx
# 7. src/components/groundAdmin/RevokeDialog.tsx
# 8. src/pages/GroundAdminsPage.tsx
# 9. Handle GA messages in MessageDetail
# 10. i18n keys
# 11. Commit: "feat(web): ground admin management"
#
# Success criteria:
# - Members list shows GA status/actions
# - Can invite, approve, decline, revoke
# - Ground Admins page lists all GAs
# - Message actions work for GA flows
```

---

### Step 9: Mobile Agent - Phase 4b (Ground Admin Flow)

**When:** After Backend Phase 4a complete (parallel with Web Step 8)
**Prerequisites:** Ground Admin API available
**Duration:** 3 days

```bash
# Handoff prompt for Mobile Agent:

cd /home/marsel/munserv/mobile

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Ground Admin sections
cat ../specs/features/ground-admin-messaging/mobile-phase.md  # Group E

# Task: Implement Ground Admin Flow
#
# Deliverables:
# 1. lib/shared/models/ground_admin.dart (Freezed)
# 2. lib/features/ground_admin/data/ground_admin_api.dart
# 3. lib/features/ground_admin/providers/ground_admin_provider.dart
# 4. lib/features/ground_admin/presentation/pages/apply_ground_admin_page.dart
# 5. lib/features/ground_admin/presentation/pages/invitation_response_page.dart
# 6. Update settings page with GA section
# 7. Handle GA messages in message detail
# 8. i18n keys
# 9. Run: flutter pub run build_runner build
# 10. Commit: "feat(mobile): ground admin application flow"
#
# Success criteria:
# - Can apply to become GA from settings
# - Can respond to invitations
# - Status shows in settings if GA
# - Message actions work
```

---

### Step 10: Backend Agent - Phase 5a (Verification Workflow)

**When:** After Phase 4 complete
**Prerequisites:** Ground Admin lifecycle working
**Duration:** 3 days

```bash
# Handoff prompt for Backend Agent:

cd /home/marsel/munserv/backend

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Verification section
cat ../specs/features/ground-admin-messaging/data-model.md

# Task: Implement Verification Workflow
#
# Deliverables:
# 1. IssueVerificationEntity.kt
# 2. IssueVerificationRepository.kt
# 3. VerificationService.kt
# 4. Add verification endpoints to IssueController
# 5. Implement verification triggering (per sector settings)
# 6. Create verification messages
# 7. Handle verification responses (update issue state)
# 8. Admin override capability
# 9. Unit tests
# 10. Integration tests
# 11. Commit: "feat(backend): issue verification workflow"
#
# API to implement:
# - POST /api/v1/issues/{id}/request-verification
# - POST /api/v1/issues/{id}/verify
# - GET /api/v1/issues/{id}/verifications
# - GET /api/v1/members/me/pending-verifications
#
# Success criteria:
# - Verification requests created based on sector settings
# - Messages sent to Ground Admins
# - Verification responses update issue state
# - REOPENED state works for failed fix verification
```

---

### Step 11: Web Agent - Phase 5b (Verification UI)

**When:** After Backend Phase 5a complete
**Prerequisites:** Verification API available
**Duration:** 2 days

```bash
# Handoff prompt for Web Agent:

cd /home/marsel/munserv/web

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Verification section
cat ../specs/features/ground-admin-messaging/web-phase.md  # Group G

# Task: Implement Verification UI
#
# Deliverables:
# 1. src/types/verification.ts
# 2. src/api/verification.ts
# 3. Add "Request Verification" to IssueDetailPage
# 4. src/components/verification/RequestVerificationDialog.tsx
# 5. src/components/verification/VerificationHistory.tsx
# 6. Add verification status indicators
# 7. Admin override button
# 8. i18n keys
# 9. Commit: "feat(web): issue verification UI"
#
# Success criteria:
# - Can request verification from issue detail
# - Verification history shows on issue
# - Admin can override status
```

---

### Step 12: Mobile Agent - Phase 5b (Verification UI)

**When:** After Backend Phase 5a complete (parallel with Web Step 11)
**Prerequisites:** Verification API available
**Duration:** 3-4 days

```bash
# Handoff prompt for Mobile Agent:

cd /home/marsel/munserv/mobile

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/api.md  # Verification section
cat ../specs/features/ground-admin-messaging/mobile-phase.md  # Group F

# Task: Implement Verification UI
#
# Deliverables:
# 1. lib/shared/models/verification.dart (Freezed)
# 2. lib/features/verification/data/verification_api.dart
# 3. lib/features/verification/providers/verification_provider.dart
# 4. lib/features/verification/presentation/pages/verify_issue_page.dart
# 5. Photo capture for verification evidence
# 6. "Cannot Verify" reason picker
# 7. Handle verification messages (navigate to verify page)
# 8. i18n keys
# 9. Run: flutter pub run build_runner build
# 10. Commit: "feat(mobile): issue verification flow"
#
# Success criteria:
# - Can verify issue exists with optional photo
# - Can report "cannot verify" with reason
# - Can verify fix completion
# - Message action opens verification page
```

---

### Step 13: Backend Agent - Phase 6 (Automation)

**When:** After Phase 5 complete
**Prerequisites:** All verification working
**Duration:** 2 days

```bash
# Handoff prompt for Backend Agent:

cd /home/marsel/munserv/backend

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/implementation-plan.md  # Phase 6

# Task: Implement Automation
#
# Deliverables:
# 1. IssueCloserJob.kt (scheduled: FIXED → CLOSED)
# 2. VerificationExpiryJob.kt (expire old pending verifications)
# 3. ResponseRateService.kt (calculate GA response rates)
# 4. GroundAdminActivityService.kt (flag low-activity GAs)
# 5. Add minimum GA warning notifications
# 6. Tests for scheduled jobs
# 7. Commit: "feat(backend): automation and scheduled jobs"
#
# Success criteria:
# - Fixed issues auto-close after configured days
# - Response rates calculated correctly
# - Low-activity GAs flagged
# - Warnings sent when below minimum
```

---

### Step 14: Web Agent - Phase 6 (Dashboard)

**When:** After Backend Phase 6 complete
**Prerequisites:** Automation API available
**Duration:** 2 days

```bash
# Handoff prompt for Web Agent:

cd /home/marsel/munserv/web

# Read context
cat CLAUDE.md
cat ../specs/features/ground-admin-messaging/implementation-plan.md  # Phase 6

# Task: Implement Activity Dashboard
#
# Deliverables:
# 1. Update GroundAdminsPage with activity metrics
# 2. Show response rates
# 3. Add sector warnings (low GA count)
# 4. Optional: "Suggest Ground Admin candidates" feature
# 5. Commit: "feat(web): ground admin activity dashboard"
#
# Success criteria:
# - Dashboard shows GA performance
# - Warnings visible for low counts
# - Response rates displayed
```

---

## Quick Reference: Execution Order

| Step | Agent | Phase | Duration | Dependencies |
|------|-------|-------|----------|--------------|
| 1 | Backend | Database Foundation | 3-4d | None |
| 2 | Backend | Sector Settings API | 2d | Step 1 |
| 3 | Backend | Messaging API | 3d | Step 1 |
| 4 | Web | Sector Settings UI | 2d | Step 2 |
| 5 | Web | Messaging UI | 3-4d | Step 3 |
| 6 | Mobile | Messaging UI | 3-4d | Step 3 (parallel with 5) |
| 7 | Backend | Ground Admin API | 3d | Step 3 |
| 8 | Web | Ground Admin UI | 3d | Step 7 |
| 9 | Mobile | Ground Admin UI | 3d | Step 7 (parallel with 8) |
| 10 | Backend | Verification API | 3d | Step 7 |
| 11 | Web | Verification UI | 2d | Step 10 |
| 12 | Mobile | Verification UI | 3-4d | Step 10 (parallel with 11) |
| 13 | Backend | Automation | 2d | Step 10 |
| 14 | Web | Dashboard | 2d | Step 13 |

---

## Verification Checkpoints

After each phase, verify before proceeding:

### After Phase 1 (Database)
```bash
# Check migrations applied
cd backend && ./gradlew flywayInfo

# Check tables exist
psql -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('messages', 'sector_settings', 'issue_verifications', 'ground_admin_applications');"

# Check enums
psql -c "SELECT enumlabel FROM pg_enum WHERE enumtypid = 'message_type'::regtype;"
```

### After Phase 3a (Messaging Backend)
```bash
# Test message creation
curl -X POST http://localhost:8080/api/v1/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"monthly_report","title":"Test","body":"Test body"}'

# Test message list
curl http://localhost:8080/api/v1/messages -H "Authorization: Bearer $TOKEN"
```

### After Phase 4a (Ground Admin Backend)
```bash
# Test apply
curl -X POST http://localhost:8080/api/v1/members/me/ground-admin/apply \
  -H "Authorization: Bearer $MEMBER_TOKEN"

# Test list Ground Admins
curl http://localhost:8080/api/v1/sectors/$SECTOR_ID/ground-admins \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### After Phase 5a (Verification Backend)
```bash
# Test request verification
curl -X POST http://localhost:8080/api/v1/issues/$ISSUE_ID/request-verification \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"existence"}'

# Test submit verification
curl -X POST http://localhost:8080/api/v1/issues/$ISSUE_ID/verify \
  -H "Authorization: Bearer $GA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"verificationId":"...","result":"confirmed"}'
```

---

## Git Commit Strategy

Each agent should commit at these milestones:

```
feat(db): add ground admin and messaging schema
feat(backend): sector settings CRUD
feat(backend): messaging service
feat(web): sector settings page
feat(web): messaging inbox and notifications
feat(mobile): messaging tab and inbox
feat(backend): ground admin lifecycle
feat(web): ground admin management
feat(mobile): ground admin application flow
feat(backend): issue verification workflow
feat(web): issue verification UI
feat(mobile): issue verification flow
feat(backend): automation and scheduled jobs
feat(web): ground admin activity dashboard
```

---

## Troubleshooting

### Backend API not responding
```bash
cd backend && ./gradlew bootRun --info
# Check for startup errors
```

### Migrations fail
```bash
cd backend && ./gradlew flywayRepair
# Then retry: ./gradlew flywayMigrate
```

### Web can't connect to API
```bash
# Check CORS in backend application.yml
# Verify API_URL in web .env
```

### Mobile build fails after model changes
```bash
cd mobile
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```
