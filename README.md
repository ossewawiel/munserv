# MunServ

Community-powered municipal issue tracking. Report potholes, water leaks, broken streetlights, and more — right from your phone.

## What is this?

MunServ helps communities track and report infrastructure problems to local authorities. Community members snap photos of issues, and administrators manage them through a web dashboard.

**How it works:**
1. Member sees a pothole → takes photo → reports via mobile app
2. Issue appears on map with GPS location
3. Admin reviews, confirms, and tracks progress
4. Community can see status updates

## Quick Start

### Prerequisites

- **Backend:** JDK 21+, Gradle
- **Web:** Node.js 20+, pnpm
- **Mobile:** Flutter 3.x

### 1. Start the Backend

```bash
cd backend
./gradlew bootRun
# Runs on http://localhost:8080
```

### 2. Start the Web Admin

```bash
cd web
pnpm install
pnpm dev
# Runs on http://localhost:3000
# Login: admin@ward42.example.com / admin123
```

### 3. Start the Mobile App

```bash
cd mobile
flutter pub get
flutter run
# Connects to backend on port 8080
```

**For mock API testing (mobile only):**
```bash
cd infrastructure/mock-api && npm start  # Port 3001
flutter run --dart-define=API_PORT=3001
```

## Project Structure

```
munserv/
├── backend/         # Kotlin + Spring Boot API
├── web/             # React + TypeScript admin portal
├── mobile/          # Flutter app (iOS & Android)
├── database/        # PostgreSQL migrations
├── infrastructure/  # Docker, mock API, deployment
├── domain/          # Ubiquitous language (source of truth for terms)
├── specs/           # Technical specifications
│   ├── requirements/    # User stories by platform
│   ├── contracts/       # API contract, shared types
│   ├── architecture/    # Overview, patterns, ADRs
│   ├── features/        # Feature specifications
│   └── operations/      # DevOps, environments
└── .claude/         # Claude Code skills
```

## Development with Claude Code

This project is built by an agent factory. Agents in `.claude/agents/` plan (Opus), implement (Sonnet, one story per isolated worktree, tests first), review (Opus) and sync bookkeeping (Sonnet); `/factory` orchestrates them and a human approves stories and merges PRs. `domain/` is the shared vocabulary and CI validates it against the code. See `CLAUDE.md` for the roster.

Slash commands are retired; the factory section of `CLAUDE.md` describes how work is delivered.

### Factory tick (unattended runs)

A systemd user timer runs `scripts/factory-tick.sh` every 2 hours from 07:00 to 21:00. Each tick:

1. Exits if `~/.config/munserv-factory/pause` exists, or if another tick holds the lock.
2. Fast-forwards `master` in `REPO_DIR`. It stops on another branch, uncommitted tracked changes or a failed fast-forward.
3. Sums today's `total_cost_usd` in `~/.local/state/munserv-factory/ticks.jsonl`. It exits when the sum reaches `DAILY_BUDGET_USD`.
4. Asks the clerk on Haiku, with structured output, for up to `STORIES_PER_TICK` stories it can dispatch now. A story qualifies only when it waits on no person: it is ready, has a pending handoff, its dependencies are closed, and a UI story has its design approved.
5. Runs `claude -p "/factory story <n>"` on Sonnet for each pick, with `--max-turns 150` and `--permission-mode acceptEdits`. The budget is the smaller of `RUN_BUDGET_USD` and what is left today. `OTEL_RESOURCE_ATTRIBUTES=story.id=<n>` joins the run to the cost meter. Tools outside the allow list are denied and counted in `permission_denials`. Permissions are never bypassed.
6. Appends one ledger line per Claude run, with the report's `CI:` and `Plan:` lines as its summary and any denied commands. It keeps the raw result in `~/.local/state/munserv-factory/runs/<tick>-<n>.json`, sends one `notify-send` line and comments on the pinned **Factory log** issue (#239). The comment carries each run's full report, so commands the run hands to a person reach your phone.

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

### MCP Integrations

| Server | Purpose |
|--------|---------|
| **postgres** | Query database schema |
| **memory** | Persist architectural decisions |
| **github** | Manage branches and PRs |

### Recommended Workflow

```
1. /add-story     → Define user requirement
2. /add-endpoint  → Define API contract (if needed)
3. /plan-feature  → Generate implementation plan
4. cd backend && /dev-cycle  → Implement backend
5. cd web && /dev-cycle      → Implement web
6. cd mobile && /dev-cycle   → Implement mobile
```

## Tech Stack

| Layer | Technology | Status |
|-------|------------|--------|
| Backend | Kotlin + Spring Boot 4.x | Ready |
| Web | React 18 + TypeScript + MUI v7 | Ready |
| Mobile | Flutter 3.x + Riverpod + Freezed | Ready |
| Database | PostgreSQL + PostGIS | Ready |
| Storage | Local uploads (MVP) | Ready |

## MVP Features

### Mobile App (Members)
- Phone + OTP registration
- PIN/biometric quick login
- Report issues with photos and GPS
- View issues on map
- Track reported issues with status timeline

### Web Dashboard (Admins)
- Email/password login
- Dashboard with statistics
- Manage issue states
- View heat report (priority ranking)
- Member management

## Issue Types

- Potholes / road damage
- Water pipe leaks
- Sewage leaks
- Broken traffic lights
- Broken street lights
- Illegal dumping

## Architecture

Each deployment is a **pod** — an independent instance with its own database and infrastructure. A pod serves one or more communities (wards, towns, regions).

```
┌─────────────────────────────────────────┐
│                  Pod                     │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Sector  │  │ Sector  │  │ Sector  │  │
│  │ Ward 42 │  │ Ward 43 │  │ Ward 44 │  │
│  └─────────┘  └─────────┘  └─────────┘  │
└─────────────────────────────────────────┘
```

## Documentation

### Quick Reference
| Document | Description |
|----------|-------------|
| [Requirements](specs/requirements/) | User stories by platform |
| [API Contract](specs/contracts/api.md) | API endpoints (source of truth) |
| [Shared Types](specs/contracts/types.md) | Data type definitions |
| [Architecture](specs/architecture/overview.md) | System architecture |
| [Patterns](specs/architecture/patterns.md) | Code patterns |

### Design system
| Where | What |
|---|---|
| https://ossewawiel.github.io/munserv/ | Landing page for the published design catalogues (rebuilt on every merge to `master`) |
| https://ossewawiel.github.io/munserv/storybook/ | Web components (Storybook), light and dark, with the token swatches |
| https://ossewawiel.github.io/munserv/widgetbook/ | Mobile widgets (Widgetbook) on device frames |
| [`design/`](design/README.md) | Tokens (the single source of colour and size), the component registries agents read, and the per-feature design canvases |

### Domain language
[`domain/`](domain/README.md) defines every term MunServ uses, with its states and its code names on each platform. `scripts/validate-domain-language.py` checks it against the code in CI.

### Archived guides
The discovery and MVP-era guides live in [`specs/archive/`](specs/archive/README.md). They explain history and are not maintained.

### Platform Guides
| Platform | CLAUDE.md | README |
|----------|-----------|--------|
| Backend | [backend/CLAUDE.md](backend/CLAUDE.md) | [backend/README.md](backend/README.md) |
| Web | [web/CLAUDE.md](web/CLAUDE.md) | [web/README.md](web/README.md) |
| Mobile | [mobile/CLAUDE.md](mobile/CLAUDE.md) | [mobile/README.md](mobile/README.md) |

## Contributing

This is an open source project. Communities should only pay for hosting costs — no licensing fees.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/awesome`)
3. Commit your changes
4. Push and open a PR

## License

MIT

---

*Built for communities, by communities.*
