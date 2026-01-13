# Issue Creation - Implementation Plan

## Status: Complete ✅

**Completed:** January 2026

## Executive Summary

The issue creation feature is **100% complete** and has been verified working end-to-end.

| Platform | Status | Notes |
|----------|--------|-------|
| Mobile | ✅ Complete | All bugs fixed |
| Backend | ✅ Verified | Working correctly |
| Web | ✅ Verified | Issues and photos display |

### Bugs Fixed

1. ~~**Mobile: Hardcoded GPS location**~~ → Integrated real LocationService
2. ~~**Mobile: Missing sectorId**~~ → Read from member profile auth state
3. ~~**Mobile: No image validation**~~ → Added size/format checks

---

## Implementation Order

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IMPLEMENTATION SEQUENCE                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  PHASE 1: MOBILE FIXES (P0 - Critical)                              │
│  ├── 1.1 Add sectorId to domain model                               │
│  ├── 1.2 Read sectorId from auth state                              │
│  ├── 1.3 Integrate real GPS location service                        │
│  └── 1.4 Add image validation before upload                         │
│                                                                     │
│  PHASE 2: BACKEND VERIFICATION (P1 - High)                          │
│  ├── 2.1 Verify POST /issues works                                  │
│  ├── 2.2 Verify photo upload works                                  │
│  └── 2.3 Run integration tests                                      │
│                                                                     │
│  PHASE 3: WEB VERIFICATION (P1 - High)                              │
│  ├── 3.1 Verify new issues appear in list                           │
│  ├── 3.2 Verify photos display correctly                            │
│  └── 3.3 Verify filtering works                                     │
│                                                                     │
│  PHASE 4: ENHANCEMENTS (P2 - Medium)                                │
│  ├── 4.1 [Mobile] Map preview with flutter_map                      │
│  ├── 4.2 [Backend] Actual thumbnail generation                      │
│  └── 4.3 [Web] Auto-refresh for new issues                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Phase Details

### Phase 1: Mobile Fixes

**Estimated Scope**: 4-6 files, ~200 lines of code changes

| Task | File | Change Type |
|------|------|-------------|
| 1.1 Add sectorId | `domain/report_issue_request.dart` | Edit model |
| 1.1 Add sectorId | `data/issue_api.dart` | Edit API call |
| 1.2 Get sectorId | `presentation/pages/report_issue_page.dart` | Edit submit |
| 1.3 Real GPS | `presentation/widgets/location_step.dart` | Major rewrite |
| 1.4 Validation | `presentation/pages/report_issue_page.dart` | Add validation |
| 1.5 i18n | `l10n/app_en.arb` | Add keys |

**Run After**:
```bash
cd mobile && flutter pub run build_runner build --delete-conflicting-outputs
```

### Phase 2: Backend Verification

**No code changes required** - verification only.

| Task | Command |
|------|---------|
| 2.1 Test issue creation | `curl POST /issues` |
| 2.2 Test photo upload | `curl POST /issues/{id}/photos` |
| 2.3 Integration tests | `./gradlew test --tests "*Scenario*"` |

### Phase 3: Web Verification

**No code changes required** - verification only.

| Task | Method |
|------|--------|
| 3.1 View issues | Manual: navigate to /issues |
| 3.2 View photos | Manual: click issue, check gallery |
| 3.3 Test filters | Manual: use state/type dropdowns |

### Phase 4: Enhancements

**Optional improvements** for better UX.

| Task | Platform | Scope |
|------|----------|-------|
| 4.1 Map preview | Mobile | ~50 lines |
| 4.2 Thumbnails | Backend | ~30 lines |
| 4.3 Auto-refresh | Web | ~10 lines |

---

## Agent Handoff Commands

### For Mobile Agent
```bash
# Navigate to mobile directory
cd /home/marsel/munserv/mobile

# Read required context
cat CLAUDE.md
cat ../specs/features/issue-creation/mobile-phase.md

# Execute tasks in order:
# 1. Edit domain/report_issue_request.dart (add sectorId)
# 2. Edit data/issue_api.dart (include sectorId in payload)
# 3. Edit presentation/pages/report_issue_page.dart (get sectorId from auth)
# 4. Edit presentation/widgets/location_step.dart (integrate LocationService)
# 5. Edit presentation/pages/report_issue_page.dart (add validation)
# 6. Edit l10n/app_en.arb (add i18n keys)
# 7. Run: flutter pub run build_runner build --delete-conflicting-outputs
# 8. Run: flutter test test/features/issues/
```

### For Backend Agent
```bash
# Navigate to backend directory
cd /home/marsel/munserv/backend

# Read required context
cat CLAUDE.md
cat ../specs/features/issue-creation/backend-phase.md

# Verification tasks:
# 1. Start server: ./gradlew bootRun
# 2. Test POST /issues with curl
# 3. Test POST /issues/{id}/photos with curl
# 4. Run: ./gradlew test --tests "*Issue*"
```

### For Web Agent
```bash
# Navigate to web directory
cd /home/marsel/munserv/web

# Read required context
cat CLAUDE.md
cat ../specs/features/issue-creation/web-phase.md

# Verification tasks:
# 1. Start server: pnpm dev
# 2. Login as admin
# 3. Verify issues list shows data
# 4. Verify photos display in detail view
# 5. Run: pnpm test
```

---

## Testing Strategy

### Integration Test Flow
```
1. [Backend] Start backend on :8080
2. [Mobile] Start app, login as member
3. [Mobile] Create issue with 2 photos
4. [Mobile] Verify success confirmation
5. [Mobile] Check issue in "My Issues"
6. [Web] Start portal on :3000
7. [Web] Login as admin
8. [Web] Verify issue in list
9. [Web] Verify photos in detail
10. [Web] Change state to "confirmed"
11. [Mobile] Verify state change visible
```

### Smoke Test Commands
```bash
# Backend health
curl http://localhost:8080/actuator/health

# Issue creation
curl -X POST http://localhost:8080/api/v1/issues \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"pothole","sectorId":"...","latitude":-26.13,"longitude":27.98}'

# Photo upload
curl -X POST http://localhost:8080/api/v1/issues/$ID/photos \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@photo.jpg"
```

---

## Dependencies Graph

```
┌──────────────────────────────────────────────────────────────┐
│                     DEPENDENCY ORDER                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  [Backend Ready] ←──────────────────────────────────┐        │
│       ↑                                             │        │
│       │                                             │        │
│  [Mobile Phase 1]                                   │        │
│       │                                             │        │
│       ├── 1.1 sectorId model ───→ 1.2 auth read ───┤        │
│       │                                             │        │
│       └── 1.3 location ─────────────────────────────┤        │
│       │                                             │        │
│       └── 1.4 validation ───────────────────────────┤        │
│                                                     │        │
│  [Web Verification] ←───────────────────────────────┘        │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

- Mobile 1.1 → 1.2 (sequential dependency)
- Mobile 1.3 and 1.4 (parallel, independent)
- Web verification requires mobile fixes complete

---

## Definition of Done

### Minimum Viable (MVP Complete) ✅
- [x] Member can create issue with real GPS location
- [x] Photos uploaded successfully
- [x] Issue visible in web admin portal
- [x] Photos display in web detail view

### Future Enhancements (Post-MVP)
- [ ] Map preview shows location
- [ ] Thumbnails generated server-side
- [ ] Auto-refresh shows new issues

---

## Tracking Todos

```
[x] [mobile] Add sectorId to ReportIssueRequest model
[x] [mobile] Read sectorId from auth state in submit
[x] [mobile] Integrate LocationService in LocationStep
[x] [mobile] Add image validation before upload
[x] [mobile] Add i18n keys for error messages
[x] [mobile] Run build_runner and verify no errors
[x] [backend] Verify POST /issues endpoint works
[x] [backend] Verify photo upload endpoint works
[x] [backend] Run integration tests
[x] [web] Verify new issues appear in list
[x] [web] Verify photos display in detail view
[x] [web] Verify filtering works correctly
```

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [Feature Spec](./spec.md) | Overview and scope |
| [Mobile Phase](./mobile-phase.md) | Detailed mobile tasks |
| [Backend Phase](./backend-phase.md) | Backend verification |
| [Web Phase](./web-phase.md) | Web verification |
| [API Contract](../../contracts/api.md) | Endpoint specifications |
