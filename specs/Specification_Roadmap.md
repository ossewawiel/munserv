# MunServ Specification Roadmap

**Project:** Municipal Service Issue Tracker (MunServ)
**Version:** 2.1
**Last Updated:** January 2026
**Purpose:** Master index of all specification documents and development approach

---

## 1. Development Philosophy

**Agile, MVP-First Approach**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Traditional (Waterfall)          │  Our Approach (Agile)              │
│  ─────────────────────            │  ─────────────────────             │
│  Full ER Model                    │  MVP Scope Definition              │
│       ↓                           │       ↓                            │
│  Full API Spec                    │  API Contract (MVP only)           │
│       ↓                           │       ↓                            │
│  Backend Implementation           │  Mock API + UI Development         │
│       ↓                           │       ↓                            │
│  Frontend Development             │  Learn from building               │
│       ↓                           │       ↓                            │
│  Discover problems late           │  Backend when UI is proven         │
│       ↓                           │       ↓                            │
│  Expensive changes                │  Iterate with real feedback        │
└─────────────────────────────────────────────────────────────────────────┘
```

**Why this approach:**
- See working software faster
- Discover UX issues early (cheap to fix)
- Parallel development possible
- Validate concepts before infrastructure investment
- Learn what data you *actually* need

---

## 2. Document Status Tracker

### Phase 1: Foundation (COMPLETE ✅)

| # | Document | Status | Purpose |
|---|----------|--------|---------|
| 1 | [Domain & Data Modeling](Domain_and_Data_Modeling.md) | ✅ Complete | Conceptual model, roles, workflows |
| 2 | [Tech Stack Selection](Tech_Stack_Selection.md) | ✅ Complete | Languages, frameworks, infrastructure |
| 3 | [Architecture & Design Patterns](Architecture_and_Design_Patterns.md) | ✅ Complete | Code structure, patterns, layers |
| 4 | [Coding Standards](Coding_Standards.md) | ✅ Complete | Naming, formatting, idioms |
| 5 | [Testing Strategy](Testing_Strategy.md) | ✅ Complete | TDD approach, coverage, tools |
| 6 | [DevOps Strategy](DevOps_Strategy.md) | ✅ Complete | Git workflow, CI/CD, environments |

### Phase 2: MVP Development (CURRENT 🔄)

| # | Document | Status | Purpose |
|---|----------|--------|---------|
| 7 | [MVP Development Guide](MVP_Development_Guide.md) | ✅ Complete | Scope, API contract, mock data |
| 8 | Mobile App Implementation | ✅ **Near Complete** | M2-M7 done, M1 partial |
| 9 | Web Admin Implementation | ✅ **Complete** | All W1-W7 features implemented |
| 10 | [Mobile Theming Guide](Mobile_Theming_Guide.md) | ✅ **Complete** | M3 color system, components |
| 11 | [Web Theming Guide](Web_Theming_Guide.md) | ✅ **Complete** | MUI v7 theming, pod configuration |

### Phase 3: Backend & Integration (COMPLETE ✅)

| # | Document | Status | Purpose |
|---|----------|--------|---------|
| 12 | [Backend Development Guide](Backend_Development_Guide.md) | ✅ Complete | Phased TDD implementation plan |
| 13 | Database Migrations | ✅ Complete | PostgreSQL + PostGIS schema (V001-V010) |
| 14 | Backend Implementation | ✅ Complete | Kotlin/Spring Boot API (all phases) |
| 15 | Web Integration | ✅ Complete | Web admin connected to real backend |
| 16 | Mobile Integration | ✅ Complete | Mobile app connected to real backend |

### Phase 4: Expansion (FUTURE)

| # | Document | Status | Purpose |
|---|----------|--------|---------|
| 16 | Entity-Relationship Model (Full) | ⏳ Not Started | Complete schema with all features |
| 17 | API Specification (Full) | ⏳ Not Started | All endpoints, not just MVP |
| 18 | AI Integration Spec | ⏳ Not Started | Photo analysis, duplicate detection |
| 19 | Offline Mode Spec | ⏳ Not Started | Sync strategy, conflict resolution |

**Status Key:** ✅ Complete | 🔄 In Progress / Ready | ⏳ Not Started

---

## 3. Current Focus: MVP Development

### What to Build Now

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MVP DEVELOPMENT                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────┐         ┌─────────────────┐                       │
│   │   Mobile App    │         │   Web Admin     │                       │
│   │   (Flutter)     │         │   (React)       │                       │
│   └────────┬────────┘         └────────┬────────┘                       │
│            │                           │                                 │
│            └───────────┬───────────────┘                                 │
│                        │                                                 │
│                        ▼                                                 │
│              ┌─────────────────┐                                         │
│              │    Mock API     │                                         │
│              │  (JSON Server)  │                                         │
│              └─────────────────┘                                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Start Here

1. **Read:** [MVP Development Guide](MVP_Development_Guide.md)
2. **Set up:** Mock API server
3. **Build:** Mobile and Web apps in parallel
4. **Iterate:** Update mock data/endpoints as needed

### MVP Features Summary

**Mobile (Member):** ✅ **Near Complete** (January 2026)
- ✅ Login with PIN/biometric
- ✅ View issues on map (flutter_map + GPS)
- ✅ View issue list with filters
- ✅ Report issue with photo
- ✅ View issue details
- ✅ View my reports
- ✅ Material Design 3 theming
- 🔄 Register with phone + OTP (partial)

**Web (Admin):** ✅ **COMPLETE** (January 2026)
- ✅ Login with email/password
- ✅ Dashboard with stats + charts
- ✅ Issues list with filters + pagination
- ✅ Issue detail with photos + state history
- ✅ Change issue state with modal
- ✅ Heat report (ranked by heat score)
- ✅ Members list with pagination
- ✅ Logout + responsive mobile navigation

**See [MVP_Development_Guide.md](MVP_Development_Guide.md) for full details, API contracts, and mock data.**

---

## 4. Document Quick Reference

### For Mobile Development

| Need | Document |
|------|----------|
| What features to build | [MVP Development Guide](MVP_Development_Guide.md) §2.1 |
| API endpoints to call | [MVP Development Guide](MVP_Development_Guide.md) §4 |
| Data models (Dart) | [MVP Development Guide](MVP_Development_Guide.md) §3.2 |
| Code patterns | [Architecture & Design Patterns](Architecture_and_Design_Patterns.md) §3 |
| Naming conventions | [Coding Standards](Coding_Standards.md) §3 |
| Testing approach | [Testing Strategy](Testing_Strategy.md) §7 |

### For Web Development

| Need | Document |
|------|----------|
| What features to build | [MVP Development Guide](MVP_Development_Guide.md) §2.2 |
| API endpoints to call | [MVP Development Guide](MVP_Development_Guide.md) §4 |
| Data models (TypeScript) | [MVP Development Guide](MVP_Development_Guide.md) §3.1 |
| Code patterns | [Architecture & Design Patterns](Architecture_and_Design_Patterns.md) §4 |
| MUI theming patterns | [Architecture & Design Patterns](Architecture_and_Design_Patterns.md) §4.4 |
| Theming & colors | [Web Theming Guide](Web_Theming_Guide.md) |
| Naming conventions | [Coding Standards](Coding_Standards.md) §4 |
| Testing approach | [Testing Strategy](Testing_Strategy.md) §8 |

### For Backend Development (READY)

| Need | Document |
|------|----------|
| **START HERE** | [Backend Development Guide](Backend_Development_Guide.md) |
| Implementation phases | [Backend Development Guide](Backend_Development_Guide.md) §7 |
| Database migrations | [Backend Development Guide](Backend_Development_Guide.md) §4 |
| API contract | [Backend Development Guide](Backend_Development_Guide.md) §5 |
| Kotlin data shapes | [Backend Development Guide](Backend_Development_Guide.md) §6 |
| Testing patterns | [Backend Development Guide](Backend_Development_Guide.md) §8 |
| Code patterns | [Architecture & Design Patterns](Architecture_and_Design_Patterns.md) §2 |
| Naming conventions | [Coding Standards](Coding_Standards.md) §2 |
| Domain concepts | [Domain & Data Modeling](Domain_and_Data_Modeling.md) |

---

## 5. Development Workflow

### Daily Development

```bash
# 1. Start mock API
cd infrastructure/mock-api && npm start

# 2. Start your app
cd mobile && flutter run     # OR
cd web && pnpm dev

# 3. Build features from MVP guide
# 4. Test against mock
# 5. Commit with conventional commits
```

### When You Need Something Not in Mock

1. Add to mock data in `infrastructure/mock-api/`
2. Add endpoint if needed
3. Update [MVP Development Guide](MVP_Development_Guide.md) §4-5
4. Continue building

### When MVP UI is Complete

1. Create Entity-Relationship Model (MVP scope only)
2. Implement backend against same API contract
3. Swap mock URL for real backend
4. Integration testing

---

## 6. LLM Development Context

When using AI to generate code, include these documents:

### For Mobile Feature

```
Include in prompt:
1. MVP_Development_Guide.md (relevant sections)
2. Architecture_and_Design_Patterns.md §3 (Flutter patterns)
3. Coding_Standards.md §3 (Dart standards)
```

### For Web Feature

```
Include in prompt:
1. MVP_Development_Guide.md (relevant sections)
2. Architecture_and_Design_Patterns.md §4 (React + MUI patterns)
3. Web_Theming_Guide.md (colors, styling)
4. Coding_Standards.md §4 (TypeScript standards)
```

### For Backend Feature

```
Include in prompt:
1. MVP_Development_Guide.md §4 (API contract)
2. Architecture_and_Design_Patterns.md §2 (Kotlin patterns)
3. Coding_Standards.md §2 (Kotlin standards)
4. Domain_and_Data_Modeling.md (relevant sections)
```

---

## 7. Definition of Done

### MVP Feature Complete

- [ ] Works against mock API
- [ ] Handles loading states
- [ ] Handles error states
- [ ] Follows coding standards
- [ ] Basic tests written (if applicable)
- [ ] Reviewed (self or peer)

### MVP Phase Complete

- [ ] All mobile user stories M1-M7 working
- [ ] All web user stories W1-W7 working
- [ ] Both apps use same mock API
- [ ] Error handling consistent
- [ ] Ready to swap for real backend

### Ready for Production

- [ ] Backend implemented
- [ ] Real database with migrations
- [ ] Authentication working
- [ ] Photo upload working
- [ ] Deployed to staging
- [ ] E2E tests passing
- [ ] Security review done

---

## 8. Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | December 2025 | Initial roadmap with waterfall approach |
| 2.0 | December 2025 | Revised for agile MVP-first approach |
| 2.1 | January 2026 | Backend Phases 0-3 complete (scaffold, auth, issues domain) |
| 2.2 | January 2026 | Backend Phase 4 complete (admin endpoints: dashboard, heat report, members) |
| 2.3 | January 2026 | Backend Phase 5 complete (photo upload: local storage, validation, REST endpoints) |

---

## 9. Next Actions

### Completed ✅

1. ✅ Create MVP Development Guide
2. ✅ Set up mock API server with test data (Express + JSON Server)
3. ✅ Initialize mobile app with folder structure (Flutter + Riverpod)
4. ✅ Initialize web app with folder structure (React 19 + Vite 7)
5. ✅ Build first mobile screen (login flow with biometrics)
6. ✅ **Complete web admin MVP** (All W1-W7 features)
   - W1: Login with email/password
   - W2: Dashboard with stats and charts
   - W3: Issues list with filters and pagination
   - W4: Issue detail with photos and history
   - W5: Change issue state with modal
   - W6: Heat report ranked list
   - W7: Members list with pagination
   - Bonus: Logout, responsive mobile navigation
7. ✅ **Complete mobile MVP** (M2-M7 features)
   - M2: Login with PIN + biometric authentication
   - M3: View issues on map (flutter_map + GPS location)
   - M4: View issue list with type/state filters
   - M5: Report new issue with camera + location
   - M6: View issue details with photos + history
   - M7: View my reports with status
   - Material Design 3 theming with tonal palettes
   - Theme showcase page (debug builds)
   - Mobile theming documentation

### Current Focus (Parallel Tracks)

**Track A: Mobile App (M1 Registration)**
- 🔄 Complete M1: Register with phone + OTP
  - ⬜ Phone entry page with validation
  - ⬜ OTP verification flow
  - ⬜ Profile creation with GPS address
  - ⬜ Sector auto-assignment from location

**Track B: Backend Development (Phase 6 Next)**
- ✅ Create Backend Development Guide
- ✅ Phase 0: Project scaffold (build.gradle.kts, application.yml)
- ✅ Phase 1: Database foundation (migrations V001-V003, sectors API)
- ✅ Phase 2: Authentication (members, JWT, auth endpoints)
- ✅ Phase 3: Issues domain (CRUD, state machine, heat calculation)
- ✅ Phase 4: Admin endpoints (dashboard, heat report, members list)
- ✅ Phase 5: Photo upload (local storage, validation, REST endpoints)
- 🔄 Phase 6: Integration testing
- ⬜ Phase 7: Hardening

### Later

- ⬜ Replace mock API with real backend
- ⬜ Deploy to staging
- ⬜ E2E testing with real apps

---

*This roadmap is a living document. Update as you progress.*
