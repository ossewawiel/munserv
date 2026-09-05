# MunServ

Community infrastructure issue tracker. Members report potholes, leaks and broken lights from a Flutter app with photos and GPS; administrators manage them in a React portal; a Kotlin backend on PostgreSQL/PostGIS serves both. Each deployment is an independent **pod**.

## Read in this order
1. `domain/README.md` - the vocabulary. Every term used in code, issues and UI is defined there. A term that is not there does not exist yet.
2. The platform card for the code you are touching: `backend/CLAUDE.md`, `web/CLAUDE.md`, `mobile/CLAUDE.md`, `database/CLAUDE.md`, `infrastructure/CLAUDE.md`.
3. Only what the task needs from `specs/`: `requirements/` (stories, status), `contracts/api.md` and `contracts/types.md` (wire contract), `architecture/decisions/` (ADRs), `features/<name>/` (spec, plan, handoffs).

Skills under `.claude/skills/` hold the worked-example catalogues (`backend-patterns`, `web-patterns`, `web-data-table`, `mobile-patterns`, `mobile-design-system`). Load one when the card is not enough. `specs/archive/` is history; do not read it unless asked why something is the way it is.

## Critical rules, all platforms
1. Immutability: `val` / `const` / `readonly`, change by copy.
2. Errors are values: sealed Result types, never exceptions for control flow.
3. Type-safe ids: wrapper types for every entity id.
4. Feature folders: group by domain feature, not by technical layer.
5. No dead code and no TODOs: delete it, or open an issue and reference it.
6. Wire values are `snake_case`; `state` is for issues, `status` for everything else (see `domain/README.md`).

## Forbidden, all platforms
`any` / `dynamic`; force-unwrap without a null check; business logic in controllers, widgets or components; hardcoded secrets, URLs or magic numbers; print/console debugging in committed code; wildcard imports.

## Running things
| What | Command | Where |
|---|---|---|
| Dev database (PostGIS 18) | `cd infrastructure/docker && docker compose up -d` | localhost:5435 |
| Backend | `cd backend && ./gradlew bootRun` | http://localhost:8080 (Swagger at `/swagger-ui.html`) |
| Web | `cd web && pnpm dev` | http://localhost:3000, login `admin@ward42.example.com` / `admin123` |
| Mobile | `cd mobile && flutter run` | emulator reaches the backend on 10.0.2.2:8080 |
| Mock API (optional) | `cd infrastructure/mock-api && npm start` | localhost:3001, `flutter run --dart-define=API_PORT=3001` |

## Quality gate
CI (`.github/workflows/ci.yml`) is required on `master`: domain-language validation, backend ktlint + tests (Testcontainers) + build, web lint + `tsc -b` + Vitest + build, mobile format + analyze (infos fatal) + tests + debug APK. Run the same commands locally before opening a PR. Squash-merge; conventional commit titles (`feat(web): ...`, scopes: backend, web, mobile, db, api, infra, specs, ci).

## The factory
Delivery runs through agents defined in `.claude/agents/` and orchestrated by `/factory`:

| Agent | Model | Does |
|---|---|---|
| `feature-planner` | Opus | Paragraph → stories (you approve) → issues, milestone, spec, one handoff per story per platform |
| `investigator` | Opus | Bug → root cause → investigation record + fix handoffs |
| `backend-implementer`, `web-implementer`, `mobile-implementer` | Sonnet | One handoff → branch in an isolated worktree, tests first, cannot finish while the platform gate is red |
| `reviewer` | Opus | PR against handoff and domain: verdict per acceptance criterion |
| `syncer` | Sonnet | After merge: specs status, issue labels, handoff archive |

Handoffs are written from `specs/features/_template/story-handoff.md` and live under `specs/features/<feature>/`. Human gates: story approval and PR merge. `/factory status` shows the queue; `/factory run` dispatches up to three stories.

## Working with GitHub
`gh` is the tool. Labels: `type:*`, `platform:*`, `status:*` (`ready` → `in-progress` → `review` → `done`, or `blocked`), `priority:*`, `story:<id>`. Stories are `M*` (mobile), `W*` (web), `B*` (backend). Legacy workflow commands stay in `.claude/commands/`. `.claude/hooks/guard-git.sh` blocks force pushes, pushes to master and history rewrites in every session.
