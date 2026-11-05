# MunServ

Community infrastructure issue tracker. Members report potholes, leaks and broken lights from a mobile app with photos and GPS. Administrators manage the issues in a web portal. A backend serves both.

## What it is

Each deployment is a **pod**: one independent instance with its own database. A pod serves one or more communities, split into sectors (and optionally wards).

1. A member photographs a problem and reports it from the Flutter app. The app attaches the GPS position.
2. The issue appears on the map for its sector.
3. A ground admin verifies it on site. Administrators move it through its states in the web portal.
4. The member sees each state change.

Issue types: pothole, water leak, sewage leak, broken traffic light, broken street light, illegal dumping, other. [`domain/`](domain/README.md) defines every term, its states and its code names on each platform. Read it before you read any code.

```
┌─────────────────────────────────────────┐
│                  Pod                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Sector  │  │ Sector  │  │ Sector  │  │
│  │ Ward 42 │  │ Ward 43 │  │ Ward 44 │  │
│  └─────────┘  └─────────┘  └─────────┘  │
└─────────────────────────────────────────┘
```

## Stack

Versions come from the build files.

| Layer | Technology | Version | Source |
|---|---|---|---|
| Backend | Kotlin, Spring Boot, Hibernate Spatial, Flyway | Kotlin 2.3.21, Spring Boot 4.1.1, JDK 21, Gradle 9.7.1 | `backend/build.gradle.kts` |
| Web | React, TypeScript, MUI, React Query, Vite, Vitest | React 19.2, TypeScript 6.0, MUI 9.4, React Query 5, Vite 8, Vitest 5 | `web/package.json` |
| Mobile | Flutter, Riverpod, Freezed | Flutter 3.47.2 (CI), Dart SDK ^3.10.4, Riverpod 3.4, Freezed 4 | `mobile/pubspec.yaml`, `.github/workflows/ci.yml` |
| Database | PostgreSQL with PostGIS | PostgreSQL 18, PostGIS 3.6 (`postgis/postgis:18-3.6`) | `infrastructure/docker/docker-compose.yml` |
| Tooling | Node, pnpm | Node 24, pnpm 10 | `mise.local.toml`, CI |

Flyway migrations live in `backend/src/main/resources/db/migration/`. Photos go to local disk; Cloudflare R2 is wired but off (`storage.type`). Nothing is deployed anywhere yet: see `infrastructure/CLAUDE.md`.

## Run it

Prerequisites: JDK 21, Node 24 with pnpm 10, Flutter, Docker. `mise.local.toml` pins them for [mise](https://mise.jdx.dev).

```bash
# Dev database (PostGIS 18) on localhost:5435
cd infrastructure/docker && docker compose up -d
# Backend on http://localhost:8080 (Swagger at /swagger-ui.html)
cd backend && ./gradlew bootRun
# Web portal on http://localhost:3000, login admin@ward42.example.com / admin123
cd web && pnpm install && pnpm dev
# Mobile app; the Android emulator reaches the backend on 10.0.2.2:8080 (API_HOST, API_PORT)
cd mobile && flutter pub get && flutter run
```

Extra accounts (a second member, a ground admin, a pending verification): `python3 scripts/dev-seed.py`. Mail goes to Mailpit with `SPRING_PROFILES_ACTIVE=local,mailpit`. To work on mobile without the backend, run the mock API (`cd infrastructure/mock-api && npm start`, port 3001) and `flutter run --dart-define=API_PORT=3001`.

The full table of run commands is in [`CLAUDE.md`](CLAUDE.md). The factory console (`./dashboard.sh`) and the operator TUI (`./tui.sh`) show services, PRs and eyeball checks.

## Repository layout

```
munserv/
├── backend/         # Kotlin + Spring Boot API, Flyway migrations
├── web/             # React admin portal
├── mobile/          # Flutter app
├── database/        # Database card (naming and migration rules)
├── infrastructure/  # Docker compose, mock API, systemd units, telemetry
├── domain/          # Ubiquitous language: the source of truth for terms
├── design/          # Tokens, component registries, design canvases
├── specs/           # Requirements, contracts, architecture, features, archive
├── scripts/         # Factory console, TUI, tick, validators, CI helpers
├── site/            # GitHub Pages landing page and dashboard
└── .claude/         # Agents, skills, hooks
```

## How the factory works

Agents in `.claude/agents/` deliver the work. `/factory` orchestrates them.

| Agent | Model | Does |
|---|---|---|
| `feature-planner` | Opus | Turns a paragraph into stories, issues, a spec and one handoff per story per platform |
| `investigator` | Opus | Takes a bug to its root cause, writes the investigation and the fix handoffs |
| `designer`, `design-reviewer` | Opus | Draw the canvas for a UI story; compare the build against it |
| `backend-implementer`, `web-implementer`, `mobile-implementer` | Sonnet | Build one handoff in an isolated worktree, tests first |
| `reviewer` | Opus | Gives a verdict per acceptance criterion |
| `clerk`, `syncer` | Haiku | Status tables, labels and boards; spec and issue bookkeeping after a merge |

The path of one story:

1. A person approves the stories (and the canvas, for a UI story).
2. An implementer builds the handoff on a branch and cannot finish while its platform gate is red.
3. Pushing the branch opens a PR (`auto-pr.yml`) and arms auto-merge.
4. CI runs. The reviewer checks the PR against the handoff.
5. UI and user-facing stories wait for an eyeball pass: a person runs the handoff's Eyeball block against the PR (`scripts/eyeball-up.sh <pr>` prints the links).
6. GitHub squash-merges when `CI status` is green. The syncer updates specs and labels.

Progress is public on the [dashboard](https://ossewawiel.github.io/munserv/dashboard/) and the [project board](https://github.com/users/ossewawiel/projects/5). The design catalogues are on [Pages](https://ossewawiel.github.io/munserv/): [Storybook](https://ossewawiel.github.io/munserv/storybook/) for web, [Widgetbook](https://ossewawiel.github.io/munserv/widgetbook/) for mobile.

### Factory tick (unattended runs)

A systemd user timer runs `scripts/factory-tick.sh` every 2 hours from 07:00 to 21:00. Each tick:

1. Exits if `~/.config/munserv-factory/pause` exists, or if another tick holds the lock.
2. Fast-forwards `master` in `REPO_DIR`. It stops on another branch, uncommitted tracked changes or a failed fast-forward.
3. Sums today's `total_cost_usd` in `~/.local/state/munserv-factory/ticks.jsonl`. It exits when the sum reaches `DAILY_BUDGET_USD`.
4. Asks the clerk on Haiku, with structured output, for up to `STORIES_PER_TICK` stories it can dispatch now. A story qualifies only when it waits on no person: it is ready, has a pending handoff, its dependencies are closed, and a UI story has its design approved.
5. Runs `claude -p "/factory story <n>"` on Sonnet for each pick, with `--max-turns 150` and `--permission-mode acceptEdits`. The budget is the smaller of `RUN_BUDGET_USD` and what is left today. `OTEL_RESOURCE_ATTRIBUTES=story.id=<n>` joins the run to the cost meter. `acceptEdits` accepts edits anywhere in the worktree except under `.claude/`, so `Edit` rules do not limit a tick. Shell commands outside the allow list are denied. `permission_denials` counts only the top-level run, so a denial inside an implementer does not appear in it. Permissions are never bypassed.
6. Appends one ledger line per Claude run, with the report's `CI:` and `Plan:` lines as its summary and any denied commands. It keeps the raw result in `~/.local/state/munserv-factory/runs/<tick>-<n>.json`, sends one `notify-send` line and comments on the pinned **Factory log** issue (#239). The comment carries each run's full report, so commands the run hands to a person reach your phone.

**Requirement rows.** After the fast-forward, each tick runs `scripts/render-requirements.py --check`. When a row has drifted from GitHub, it pushes a `chore/sync-requirements-<tick>` branch from a throwaway worktree, and `auto-pr.yml` opens and merges it. No Claude run is involved. It waits while such a PR is open, and a failure never stops the tick. CI checks only the rows a PR changes, so an issue closing elsewhere never turns an unrelated PR red.

**Weekly retro.** On Mondays (`RETRO_WEEKDAY`), the day's first tick runs `claude -p "/factory-retro"` on Opus before the clerk, capped at `RETRO_BUDGET_USD` ($5). It runs once a day: a `retro` line in today's ledger or a `specs/metrics/last-retro` of today skips it, and a failed retro never stops the tick. The skill (`.claude/skills/factory-retro/SKILL.md`) reads the evidence since `last-retro` through `scripts/retro-gather.py`. The evidence is reviewer and design-reviewer verdicts on merged PRs, `source:eyeball`, `source:review` and `source:smoke` issues, red CI logs, `BLOCKED:` reasons, the ledger and the cost meter. It clusters the findings and names the earliest check that missed each cluster. It lands one fix per cluster, choosing in this order: hook or lint rule, skill line, card line, accept. It writes `specs/metrics/retro-<date>.md` with card and skill sizes and opens one PR. Unattended runs cannot write under `.claude/`, so a skill, agent or hook fix arrives as a proposal in the PR body for you to land. Run it by hand with `/factory-retro` in a session, or preview the evidence with `python3 scripts/retro-gather.py`.

All settings live in `~/.config/munserv-factory/tick.env`. The template is `infrastructure/systemd/tick.env.example`. A later move to a server or to GitHub Actions changes that file only.

```bash
# Install: writes tick.env once (never overwrites it), installs both units and enables the timer
scripts/install-factory-tick.sh
# Keep the timer running after you log out
loginctl enable-linger "$USER"
# See the picks without dispatching anything (one Haiku call, about $0.01)
scripts/factory-tick.sh --dry-run
# Run one tick now
systemctl --user start munserv-factory.service
# Follow a tick's output
journalctl --user -u munserv-factory -f
# Pause: every tick exits at once while the file exists
touch ~/.config/munserv-factory/pause
# Resume
rm ~/.config/munserv-factory/pause
# Stop the timer altogether
systemctl --user disable --now munserv-factory.timer
# Today's spend in dollars
jq -nR --arg d "$(date +%F)" '[inputs | fromjson? | select(.date == $d) | .total_cost_usd] | add // 0' ~/.local/state/munserv-factory/ticks.jsonl
```

**Budget.** The defaults are $10 a day and $5 per story run (decision D6). The clerk's call costs about $0.01 and counts toward the day. To change the caps, edit `DAILY_BUDGET_USD` and `RUN_BUDGET_USD` in `tick.env`; the next tick reads the new values. To change the hours, edit `TICK_FIRST_HOUR`, `TICK_LAST_HOUR` and `TICK_EVERY_HOURS`, then rerun the installer, which rewrites the timer. A run that hits its cap ends with subtype `error_max_budget_usd` in the ledger. Its PR or branch stays as it was.

## Documentation

| Where | What |
|---|---|
| [`domain/`](domain/README.md) | The vocabulary; `scripts/validate-domain-language.py` checks it against the code in CI |
| [`specs/`](specs/README.md) | Requirements, API contract, shared types, architecture decisions, feature specs and handoffs |
| [`design/`](design/README.md) | Tokens, component registries, design canvases |
| [`backend/CLAUDE.md`](backend/CLAUDE.md), [`web/CLAUDE.md`](web/CLAUDE.md), [`mobile/CLAUDE.md`](mobile/CLAUDE.md), [`database/CLAUDE.md`](database/CLAUDE.md), [`infrastructure/CLAUDE.md`](infrastructure/CLAUDE.md) | The rules for each platform |
| [`backend/README.md`](backend/README.md), [`web/README.md`](web/README.md), [`mobile/README.md`](mobile/README.md) | Platform setup |
| [`specs/archive/`](specs/archive/README.md) | History from discovery and the MVP build; not maintained |

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).
