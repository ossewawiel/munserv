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
| Backend | `cd backend && ./gradlew bootRun` | http://localhost:8080 (Swagger at `/swagger-ui.html`); add `SPRING_PROFILES_ACTIVE=local,mailpit` to send mail to Mailpit (read it with the `curl` commands in `infrastructure/CLAUDE.md`) |
| Dev accounts | `python3 scripts/dev-seed.py` | second member, ground admin and a pending verification, listed in `scripts/console/accounts.yaml` |
| Web | `cd web && pnpm dev` | http://localhost:3000, login `admin@ward42.example.com` / `admin123` |
| Mobile | `cd mobile && flutter run` | emulator reaches the backend on 10.0.2.2:8080 |
| Mock API (optional) | `cd infrastructure/mock-api && npm start` | localhost:3001, `flutter run --dart-define=API_PORT=3001` |
| Factory console | `./dashboard.sh` (or `python3 -m scripts.console`) | http://localhost:3999 |
| Operator TUI | `./tui.sh` | in your SSH terminal: services, logs and LAN links over the console API (`scripts/tui/`) |
| Remote eyeball | `scripts/eyeball-up.sh <pr>` | prints web, Swagger and console links for another machine on the LAN |

## Quality gate
CI (`.github/workflows/ci.yml`) is required on `master`: domain-language validation, backend ktlint + tests (Testcontainers) + build, web lint + `tsc -b` + Vitest + build, mobile format + analyze (infos fatal) + tests + debug APK. Run the same commands locally before opening a PR. Squash-merge; conventional commit titles (`feat(web): ...`, scopes: backend, web, mobile, db, api, infra, specs, ci).

**Watch CI on every PR you open or push to.** The user does not watch CI and will not know it is red. In the same turn as `gh pr create` or the push, start `scripts/watch-ci.sh <n>` in the background (not `gh pr checks --watch`, which exits green while the new runs are still pending). Do not call the work done while it runs. When it ends, report its result. A red job: the script prints the failed log tail; fix it on the same branch when the fix is in scope, push and watch again; otherwise report the failing job, step and error line. Every message that names a PR ends its status with one CI line: `CI: watching`, `CI: green`, or `CI: red - <job>: <error>`.

## When a person must act
The user reaches this laptop through a terminal only: no desktop and no browser on it. Do every step you can yourself. When a step needs the user (sudo, a secret, an interactive login, a judgement), end your message with the exact commands in one fenced `bash` block, in the order to run them, each preceded by a one-line `#` comment saying what it does. Never point the user at a `localhost` URL or a desktop app on the laptop: give a `curl` command instead, or a LAN link that `scripts/eyeball-up.sh` prints. Links on github.com and claude.ai are fine; they open on the user's own machine. Plan steps, factory reports and handoff Eyeball blocks follow the same rule.

## Plan upkeep
The Operation V1 plan artifact (https://claude.ai/artifact/3y9tTBbG7o2a7NLm8MnVut) is the source of truth for where the work stands. Read its store (`ArtifactData` `list` on `steps` and `decisions`) before starting a plan step. When steps are added or rewritten, republish the page from `.critique/2026-10-28-factory-road-to-v1/plan.html` to the same URL. Its "Where we are" map redraws from the store.

**Keep the store current without being asked.** The user does not remind you; a stale step is a defect.
- Before you open a PR, find its step in the store and in `plan.html`. Put `Plan step: S<nn>` (or `Plan step: none`) in the PR body.
- When you open the PR, write the step `running` with the PR number in its `note`.
- When `scripts/watch-ci.sh` ends, and whenever `gh pr view` shows the PR merged (the user merges without saying so), write the step's `status` and `note` in that same turn: `done` when its "Done when" check passed, `running` with what is left when the check needs the user, `blocked` with the reason.
- A note says what merged (PR, commit), what the done check showed, and what was not run.
- Every message that names a PR ends with a `Plan:` line under the CI line: `Plan: S06 done`, `Plan: S42 running - waits on your SSH run`, or `Plan: no step`.

## The factory
Delivery runs through agents defined in `.claude/agents/` and orchestrated by `/factory`:

| Agent | Model | Does |
|---|---|---|
| `feature-planner` | Opus | Paragraph → stories (you approve) → issues, milestone, spec, one handoff per story per platform |
| `investigator` | Opus | Bug → root cause → investigation record + fix handoffs |
| `backend-implementer`, `web-implementer`, `mobile-implementer` | Sonnet | One handoff → branch in an isolated worktree, tests first, cannot finish while the platform gate is red |
| `designer` | Opus | UI story → canvas from tokens and registry, one artboard per screen and state; you approve it before implementation |
| `design-reviewer` | Opus | Screenshots and goldens of the build against the approved canvas and the registry |
| `reviewer` | Opus | PR against handoff and domain: verdict per acceptance criterion |
| `syncer` | Sonnet | After merge: specs status, issue labels, handoff archive |

Handoffs are written from `specs/features/_template/story-handoff.md` and live under `specs/features/<feature>/`. Human gates: story approval, canvas approval for UI stories, eyeball pass, and PR merge. Eyeball is a human running the Eyeball section of the factory console (`./dashboard.sh`) against the handoff's `Eyeball` block after the reviewer approves; it labels the PR `eyeball:pass` or `eyeball:fail` and files a `source:eyeball` bug for every failed check. Eyeball is run remotely: after the reviewer approves, `scripts/eyeball-up.sh <pr>` checks the PR out, restarts only the services that changed and prints the links, which the user opens from another machine (`specs/architecture/decisions/007-remote-eyeball.md`). The console (`scripts/console/`, see `scripts/console/README.md`) also surfaces milestones, the PR pipeline, the domain language and requirements, and design canvases and registry - it replaces the old `scripts/eyeball.py` dashboard. `/factory status` shows the queue; `/factory run` dispatches up to three stories. Progress is public at https://ossewawiel.github.io/munserv/dashboard/ and on the board https://github.com/users/ossewawiel/projects/5 (`scripts/sync-board.py` mirrors labels onto it).

## Working with GitHub
`gh` is the tool. Labels: `type:*`, `platform:*`, `status:*` (`ready` → `in-progress` → `review` → `done`, or `blocked`), `priority:*`, `story:<id>`. Stories are `M*` (mobile), `W*` (web), `B*` (backend). Legacy workflow commands stay in `.claude/commands/`. `.claude/hooks/guard-git.sh` blocks force pushes, pushes to master and history rewrites in every session.
