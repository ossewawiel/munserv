# MunServ Specification Roadmap

**Project:** Municipal Service Issue Tracker (MunServ)  
**Version:** 2.0  
**Last Updated:** December 2025  
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
| 8 | Mobile App Implementation | 🔄 Ready to Start | Build against mock API |
| 9 | Web Admin Implementation | 🔄 Ready to Start | Build against mock API |

### Phase 3: Backend & Integration (LATER)

| # | Document | Status | Purpose |
|---|----------|--------|---------|
| 10 | Entity-Relationship Model (MVP) | ⏳ Not Started | Database schema for MVP features |
| 11 | Backend Implementation | ⏳ Not Started | Spring Boot API |
| 12 | Integration & Testing | ⏳ Not Started | Connect frontend to real backend |

### Phase 4: Expansion (FUTURE)

| # | Document | Status | Purpose |
|---|----------|--------|---------|
| 13 | Entity-Relationship Model (Full) | ⏳ Not Started | Complete schema with all features |
| 14 | API Specification (Full) | ⏳ Not Started | All endpoints, not just MVP |
| 15 | AI Integration Spec | ⏳ Not Started | Photo analysis, duplicate detection |
| 16 | Offline Mode Spec | ⏳ Not Started | Sync strategy, conflict resolution |

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

**Mobile (Member):**
- Register with phone + OTP
- Login with PIN
- View issues on map
- Report issue with photo
- View issue details
- View my reports

**Web (Admin):**
- Login with email/password
- Dashboard with stats
- Issues list with filters
- Change issue state
- Heat report
- Members list (view only)

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
| Naming conventions | [Coding Standards](Coding_Standards.md) §4 |
| Testing approach | [Testing Strategy](Testing_Strategy.md) §8 |

### For Backend Development (When Ready)

| Need | Document |
|------|----------|
| API to implement | [MVP Development Guide](MVP_Development_Guide.md) §4 |
| Code patterns | [Architecture & Design Patterns](Architecture_and_Design_Patterns.md) §2 |
| Naming conventions | [Coding Standards](Coding_Standards.md) §2 |
| Testing approach | [Testing Strategy](Testing_Strategy.md) §6 |
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
2. Architecture_and_Design_Patterns.md §4 (React patterns)
3. Coding_Standards.md §4 (TypeScript standards)
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

---

## 9. Next Actions

### Immediate (This Week)

1. ✅ Create MVP Development Guide
2. ⬜ Set up mock API server with test data
3. ⬜ Initialize mobile app with folder structure
4. ⬜ Initialize web app with folder structure
5. ⬜ Build first mobile screen (login flow)
6. ⬜ Build first web screen (login + dashboard)

### Soon (Next 2 Weeks)

- ⬜ Complete mobile MVP screens
- ⬜ Complete web admin MVP screens
- ⬜ Refine mock API as needed
- ⬜ Review and iterate on UX

### Later (When UI Proven)

- ⬜ Create ER Model (MVP scope)
- ⬜ Implement backend
- ⬜ Integrate and test
- ⬜ Deploy to staging

---

*This roadmap is a living document. Update as you progress.*
