# MunServ - Municipal Service Issue Tracker

## Project
Community-based infrastructure issue reporting. Members report issues (potholes, leaks, broken lights) via mobile app with photos and GPS. Administrators manage via web portal. Each deployment is an independent "pod" with own database and infrastructure.

## Current Phase: MVP Development

**Start here:** [`specs/MVP_Development_Guide.md`](specs/MVP_Development_Guide.md)

```
┌─────────────────────────────────────────────────────────────┐
│  CURRENT FOCUS                                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Mobile App (Flutter)  ←──┐                                 │
│                            │                                 │
│   Web Admin (React)    ←───┼──── Mock API (JSON Server)     │
│                            │                                 │
│   Backend (Later)      ────┘                                 │
│                                                              │
│   Build UI first, prove the concept, then implement backend  │
└─────────────────────────────────────────────────────────────┘
```

**Development workflow:**
1. Start mock API: `cd infrastructure/mock-api && npm start`
2. Build features from MVP Development Guide
3. Both mobile and web use the same mock API contract
4. Backend implementation comes after UI is proven

## Tech Stack
| Layer | Technology | Status |
|-------|------------|--------|
| Backend | Kotlin + Spring Boot | Later |
| Mobile | Flutter + Riverpod + Freezed | 🔄 Ready |
| Web | React + TypeScript + React Query | 🔄 Ready |
| Database | PostgreSQL + PostGIS | Later |
| Storage | Cloudflare R2 (photos) | Later |
| Mock API | JSON Server / Express | 🔄 Ready |

## Repository Structure
```
/backend        → Kotlin/Spring Boot API (Phase 3)
/mobile         → Flutter app ← START HERE
/web            → React admin portal ← START HERE
/database       → Migrations, seeds (Phase 3)
/shared         → API contracts, shared types
/infrastructure → Docker, mock-api, IaC
/specs          → Specification documents
```

## Quick Start

```bash
# 1. Set up mock API
cd infrastructure/mock-api
npm install
npm start                    # Runs on http://localhost:3001

# 2. Start mobile development (new terminal)
cd mobile
flutter pub get
flutter run

# 3. Start web development (new terminal)
cd web
pnpm install
pnpm dev                     # Runs on http://localhost:3000
```

## Key Documents

### For MVP Development (Read First)
| Document | Purpose |
|----------|---------|
| [`MVP_Development_Guide.md`](specs/MVP_Development_Guide.md) | **START HERE** - Features, API contract, mock data |
| [`Specification_Roadmap.md`](specs/Specification_Roadmap.md) | Overall plan and progress tracking |

### For Code Generation
| Document | Use When |
|----------|----------|
| [`Architecture_and_Design_Patterns.md`](specs/Architecture_and_Design_Patterns.md) | Layer structure, patterns, code examples |
| [`Coding_Standards.md`](specs/Coding_Standards.md) | Naming conventions, formatting rules |
| [`Testing_Strategy.md`](specs/Testing_Strategy.md) | Test patterns, coverage targets |

### For Context
| Document | Contains |
|----------|----------|
| [`Domain_and_Data_Modeling.md`](specs/Domain_and_Data_Modeling.md) | Entities, roles, workflows, state machines |
| [`Tech_Stack_Selection.md`](specs/Tech_Stack_Selection.md) | Technology choices with rationale |
| [`DevOps_Strategy.md`](specs/DevOps_Strategy.md) | Git workflow, CI/CD, environments |

## Before Generating Code

### For Mobile (Flutter)
```
Include in context:
1. specs/MVP_Development_Guide.md §2.1, §3.2, §4 (scope, Dart models, API)
2. specs/Architecture_and_Design_Patterns.md §3 (Flutter patterns)
3. specs/Coding_Standards.md §3 (Dart standards)
4. mobile/CLAUDE.md (if exists)
```

### For Web (React)
```
Include in context:
1. specs/MVP_Development_Guide.md §2.2, §3.1, §4 (scope, TS types, API)
2. specs/Architecture_and_Design_Patterns.md §4 (React patterns)
3. specs/Coding_Standards.md §4 (TypeScript standards)
4. web/CLAUDE.md (if exists)
```

### For Backend (Later)
```
Include in context:
1. specs/MVP_Development_Guide.md §4 (API to implement)
2. specs/Architecture_and_Design_Patterns.md §2 (Kotlin patterns)
3. specs/Coding_Standards.md §2 (Kotlin standards)
4. specs/Domain_and_Data_Modeling.md
5. backend/CLAUDE.md (if exists)
```

## Critical Rules (All Platforms)
1. **Immutability** — `val`/`const`/`readonly`, mutate via copy
2. **Errors as values** — Sealed Result types, never exceptions for flow control
3. **Type-safe IDs** — Wrapper types for all entity IDs
4. **Feature folders** — Group by domain feature, not technical layer
5. **No dead code** — Delete unused code, don't comment it out

## Forbidden (All Platforms)
- `any` / `dynamic` / force-unwrap without null check
- Business logic in controllers/widgets/components
- Hardcoded secrets, URLs, or magic numbers
- Print/console debugging in committed code
- Wildcard imports

## Domain Glossary
| Term | Meaning |
|------|---------|
| Pod | Independent deployment (own DB, infrastructure) |
| Sector | Geographic area where issues are managed |
| Issue | Reported problem with photos and GPS location |
| Heat | Priority score: f(age, report count, type) |
| Member | Community resident who reports/views issues |
| State | Issue lifecycle: Reported→Confirmed→InProgress→Fixed |

## MVP Scope Summary

### Mobile (Member App)
- M1: Register with phone + OTP
- M2: Login with PIN/biometric
- M3: View issues on map
- M4: View issue list
- M5: Report new issue
- M6: View issue details
- M7: View my reports

### Web (Admin Portal)
- W1: Login with email/password
- W2: View dashboard
- W3: View issues list
- W4: View issue details
- W5: Change issue state
- W6: View heat report
- W7: View members list

**Full details in [MVP_Development_Guide.md](specs/MVP_Development_Guide.md)**

## MCPs Available
| MCP | Purpose | Use When |
|-----|---------|----------|
| postgres | Query schema, validate SQL | Before writing migrations or queries |
| memory | Persist decisions across sessions | Store/retrieve architectural decisions |
| github | Branches, PRs, issues | Creating features, code review |
| fetch | HTTP requests | Testing API endpoints |

## Memory MCP Key Convention

### Pattern: `{category}:{scope}:{topic}`

### Decision Keys (persist architectural choices)
```
decision:architecture:{topic}     → system-wide patterns
decision:backend:{topic}          → Kotlin/Spring choices
decision:mobile:{topic}           → Flutter/Dart choices
decision:web:{topic}              → React/TypeScript choices
decision:database:{topic}         → schema/query patterns
decision:api:{topic}              → endpoint/contract choices
```

### Context Keys (current working state)
```
context:current-feature           → feature being developed
context:current-module            → module being worked on
context:blockers                  → known issues blocking progress
context:next-steps                → planned next actions
```

### Memory MCP Usage
- **Before generating**: Check memory for relevant `decision:` keys
- **After deciding**: Store new decisions immediately
- **Session start**: Query `context:` keys to resume work
- **Contradiction found**: Query memory, discuss before overriding

## WSL2 Environment
- Path: `/mnt/d/SourceCode/pocs/munserv/`
- All builds run in WSL2 (gradlew, flutter, npm)
- Line endings: LF only (`git config core.autocrlf input`)
- Ensure scripts executable: `chmod +x gradlew`
