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
│   Mobile App (Flutter)  ←──── Backend (Spring Boot) ✓       │
│                                                              │
│   Web Admin (React)     ←──── Backend (Spring Boot) ✓       │
│                                                              │
│   Both mobile and web now connected to real backend.        │
└─────────────────────────────────────────────────────────────┘
```

**Development workflow:**
1. Start backend: `cd backend && ./gradlew bootRun` (port 8080)
2. Start web: `cd web && pnpm dev` (port 3000)
3. Start mobile: `cd mobile && flutter run` (connects to backend on 8080)

**For mobile mock API testing:**
- Start mock: `cd infrastructure/mock-api && npm start` (port 3001)
- Run mobile with: `flutter run --dart-define=API_PORT=3001`

## Contributing

**New to the project?** Start with [`CONTRIBUTING.md`](CONTRIBUTING.md) for:
- How to report bugs and request features
- Bug fix and feature development workflows
- Working with GitHub issues and Claude agent skills
- Code standards and PR guidelines

## Platform-Specific Context (IMPORTANT)

**When working on code in a subdirectory, ALWAYS read that directory's CLAUDE.md first:**

| Working On | Read First | Contains |
|------------|------------|----------|
| `mobile/lib/**` | [`mobile/CLAUDE.md`](mobile/CLAUDE.md) | Riverpod, Freezed, Result patterns, widget rules |
| `web/src/**` | [`web/CLAUDE.md`](web/CLAUDE.md) | React Query, atomic design, hooks patterns |
| `backend/src/**` | [`backend/CLAUDE.md`](backend/CLAUDE.md) | Sealed results, value objects, layer rules |
| `database/migrations/**` | [`database/CLAUDE.md`](database/CLAUDE.md) | PostGIS, naming conventions, Flyway |
| `infrastructure/**` | [`infrastructure/CLAUDE.md`](infrastructure/CLAUDE.md) | Docker, CI/CD, environments |
| `shared/**` | [`shared/CLAUDE.md`](shared/CLAUDE.md) | API contracts, shared types |

**Example:** Before creating a Flutter widget, run:
```
Read mobile/CLAUDE.md, then create a ConsumerWidget for displaying issue details.
```

## Tech Stack
| Layer | Technology | Status |
|-------|------------|--------|
| Backend | Kotlin + Spring Boot | ✅ Ready |
| Mobile | Flutter + Riverpod + Freezed | ✅ Ready |
| Web | React + TypeScript + React Query | ✅ Ready |
| Database | PostgreSQL + PostGIS | ✅ Ready |
| Storage | Local uploads (photos) | 🔄 MVP |
| Mock API | JSON Server / Express | 📦 Optional (for testing) |

## Repository Structure
```
/backend        → Kotlin/Spring Boot API
/mobile         → Flutter app
/web            → React admin portal
/database       → Migrations, seeds
/shared         → API contracts, shared types
/infrastructure → Docker, mock-api, IaC
/specs          → Documentation (see below)
/.claude        → Project-level skills
```

### Specs Structure (Concise)
```
/specs
├── requirements/      → User stories (mobile.md, web.md, backlog.md)
├── contracts/         → API contract (api.md, types.md)
├── architecture/      → Overview, patterns, decisions/
├── features/          → Feature specs per feature
└── operations/        → DevOps, environments
```

## Quick Start

```bash
# 1. Start backend (required for web)
cd backend
./gradlew bootRun            # Runs on http://localhost:8080

# 2. Start web development (new terminal)
cd web
pnpm install
pnpm dev                     # Runs on http://localhost:3000
# Login: admin@ward42.example.com / admin123

# 3. Start mobile development (new terminal)
cd infrastructure/mock-api
npm install && npm start     # Mock API on http://localhost:3001
cd ../mobile
flutter pub get
flutter run
```

## Project-Level Skills

Use these skills for cross-platform development and documentation management.

### Requirements & Features
| Skill | Purpose |
|-------|---------|
| `/add-story` | Add user story to `specs/requirements/{platform}.md` |
| `/add-feature` | Create feature spec in `specs/features/{name}/` |
| `/plan-feature` | Generate cross-platform implementation plan |

### Architecture & Contracts
| Skill | Purpose |
|-------|---------|
| `/add-adr` | Create Architecture Decision Record |
| `/add-pattern` | Add code pattern to `specs/architecture/patterns.md` |
| `/add-endpoint` | Add API endpoint to `specs/contracts/api.md` |
| `/add-type` | Add shared type to `specs/contracts/types.md` |

### Documentation
| Skill | Purpose |
|-------|---------|
| `/update-readme` | Update README with agentic workflow |
| `/sync-docs` | Validate documentation consistency |
| `/migrate-docs` | Migrate verbose docs to concise structure |

### Workflow Example
```
1. /add-story platform=mobile story="As a member, I can reset my PIN"
2. /add-endpoint method=POST path="/auth/reset-pin" response="{ otpSent }"
3. /plan-feature feature="reset-pin"
4. Hand off to platform /dev-cycle skills
```

## Documentation (Concise Structure)

### Quick Reference (SHORT and SWEET)
| Document | Purpose |
|----------|---------|
| [`specs/requirements/`](specs/requirements/) | User stories by platform |
| [`specs/contracts/api.md`](specs/contracts/api.md) | API endpoints (source of truth) |
| [`specs/contracts/types.md`](specs/contracts/types.md) | Shared data types |
| [`specs/architecture/overview.md`](specs/architecture/overview.md) | System architecture |
| [`specs/architecture/patterns.md`](specs/architecture/patterns.md) | Code patterns |
| [`specs/architecture/decisions/`](specs/architecture/decisions/) | ADRs (why we chose X) |
| [`specs/operations/`](specs/operations/) | DevOps, environments |

### Legacy Documents (Detailed Reference)
| Document | Use When |
|----------|----------|
| [`MVP_Development_Guide.md`](specs/MVP_Development_Guide.md) | Full context, mock data |
| [`Architecture_and_Design_Patterns.md`](specs/Architecture_and_Design_Patterns.md) | Detailed patterns |
| [`Domain_and_Data_Modeling.md`](specs/Domain_and_Data_Modeling.md) | Entity definitions |
| [`Coding_Standards.md`](specs/Coding_Standards.md) | Naming conventions |
| [`Testing_Strategy.md`](specs/Testing_Strategy.md) | Test patterns |

## Before Generating Code

### For Mobile (Flutter)
```
1. READ mobile/CLAUDE.md FIRST (required patterns)
2. Then if needed:
   - specs/MVP_Development_Guide.md §2.1, §3.2, §4 (scope, Dart models, API)
   - specs/Architecture_and_Design_Patterns.md §3 (Flutter patterns)
   - specs/Coding_Standards.md §3 (Dart standards)
```

### For Web (React)
```
1. READ web/CLAUDE.md FIRST (required patterns)
2. Then if needed:
   - specs/MVP_Development_Guide.md §2.2, §3.1, §4 (scope, TS types, API)
   - specs/Architecture_and_Design_Patterns.md §4 (React patterns)
   - specs/Coding_Standards.md §4 (TypeScript standards)
```

### For Backend (Kotlin)
```
1. READ backend/CLAUDE.md FIRST (required patterns)
2. Then if needed:
   - specs/MVP_Development_Guide.md §4 (API to implement)
   - specs/Architecture_and_Design_Patterns.md §2 (Kotlin patterns)
   - specs/Coding_Standards.md §2 (Kotlin standards)
   - specs/Domain_and_Data_Modeling.md
```

### For Database
```
1. READ database/CLAUDE.md FIRST (naming, PostGIS patterns)
2. Query postgres MCP for current schema before writing migrations
3. specs/Domain_and_Data_Modeling.md for entity definitions
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
See [`specs/requirements/mobile.md`](specs/requirements/mobile.md)
- M1: Register with phone + OTP
- M2: Login with PIN/biometric
- M3-M7: Issue viewing and reporting

### Web (Admin Portal)
See [`specs/requirements/web.md`](specs/requirements/web.md)
- W1: Admin login
- W2-W7: Dashboard, issue management, member management

### API Contract
See [`specs/contracts/api.md`](specs/contracts/api.md) for all endpoints.

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
