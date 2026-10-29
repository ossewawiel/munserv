# Infrastructure card

## Local services
`infrastructure/docker/docker-compose.yml` runs the local dependencies:

| Service | Image | Host port | Notes |
|---|---|---|---|
| PostgreSQL + PostGIS | `postgis/postgis:18-3.6` | 5435 | Volume mounted at `/var/lib/postgresql` as the 18 image requires |
| Mailpit | `axllent/mailpit:v1.27` | 1026 SMTP, 8026 UI | Catches all mail from a backend run with `SPRING_PROFILES_ACTIVE=local,mailpit` (`application-mailpit.yml`); localhost only |
| OpenTelemetry collector | `otel/opentelemetry-collector-contrib:0.141.0` | 4318 (OTLP/HTTP) | Profile `telemetry`; localhost only; writes `infrastructure/telemetry/data/metrics.jsonl` and `logs.jsonl` (gitignored); see Cost meter below |

Ports 1025, 5432, 5433, 5434, 6379 and 8025 belong to other projects on the dev machine; do not reuse them.

`python3 scripts/dev-seed.py` adds the accounts Flyway does not seed (a second member, a ground admin, a pending verification) through the API; it needs the mailpit profile. The accounts are listed in `scripts/console/accounts.yaml`.

The user has a terminal only on this laptop, so read Mailpit through its API, not its UI:

```bash
# Subject, recipient and time of the ten newest mails
curl -s 'localhost:8026/api/v1/messages?limit=10' | python3 -c 'import json,sys; [print(m["Created"][:19], m["To"][0]["Address"], "|", m["Subject"]) for m in json.load(sys.stdin)["messages"]]'
# Text of the newest mail to one address
curl -s "localhost:8026/api/v1/message/$(curl -s 'localhost:8026/api/v1/search?query=to:thandi.nkosi@example.com' | python3 -c 'import json,sys; print(json.load(sys.stdin)["messages"][0]["ID"])')" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Text"])'
```

```bash
cd infrastructure/docker
docker compose up -d                              # start
docker compose down                               # stop
docker compose down -v && docker compose up -d    # reset (destroys data)
psql postgresql://munserv:munserv_dev@localhost:5435/munserv_dev
```
Backend tests do not use this database; they start their own PostGIS container through Testcontainers.

## Port allocations
| Service | Port |
|---|---|
| PostgreSQL (host, maps to 5432) | 5435 |
| Mailpit SMTP / UI | 1026 / 8026 |
| Backend API | 8080 |
| Mock API | 3001 |
| Web dev server | 3000 |
| Factory console | 3999 |
| Showcase backend (`demo` profile, own database `munserv_demo`) | 8090 |
| Showcase web (`vite preview`) | 4000 |

Remote eyeball exposes web 3000, backend 8080 and the console 3999 to the LAN; PostgreSQL 5435 and Storybook 6006 stay local.

## Remote eyeball

The factory console runs as a systemd user unit so a tester on another machine can eyeball PRs while the services run on this laptop. Files: `infrastructure/systemd/munserv-console.service` (installed by `scripts/install-console-service.sh`, no sudo), the `remote:` key in `scripts/console/project.yaml`, and `scripts/eyeball-up.sh <pr>`. The firewall rule is opened once by a person: the console prints the exact command (`sudo ufw allow from <subnet> to any port 3000,3999,8080 proto tcp`). Design and risks: `specs/architecture/decisions/007-remote-eyeball.md`; usage: `scripts/console/README.md`.

## Showcase stack

A second, independent run of `origin/master` for demos, beside the dev stack. It lives in a detached git worktree at `../munserv-demo` that only ever follows `origin/master`; the database `munserv_demo` is created in the same PostGIS container; the backend runs as `java -jar` from `bootJar` under `SPRING_PROFILES_ACTIVE=local,mailpit,demo` on 8090 (`application-demo.yml` sets the port and the datasource only); the web build is served by `vite preview` on 4000 and proxies `/api` to 8090. Code: `scripts/console/showcase.py`. In the TUI (`./tui.sh`): `u` update from master, `b` build (the build log opens in the log pane), `d` start, `e` stop. The first start runs `scripts/dev-seed.py --base-url http://localhost:8090`. The TUI prints the firewall command for 4000 and 8090. Update does not restart anything; build, then stop and start, to show new code.

## Environment variables (backend)
| Variable | Purpose | Default |
|---|---|---|
| `DB_URL`, `DB_USER`, `DB_PASSWORD` | Datasource | `jdbc:postgresql://localhost:5435/munserv_dev`, `munserv`, `munserv_dev` |
| `JWT_SECRET` | Token signing | dev value in `application.yml`; must be set outside local |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `EMAIL_FROM`, `EMAIL_OVERRIDE_RECIPIENT` | Mail | localhost:587; override redirects all mail in dev/test |
| `BOOTSTRAP_SUPER_USER_ENABLED`, `SUPER_USER_EMAIL`, `SUPER_USER_PASSWORD` | Bootstrap (see `domain/bootstrap.md`) | disabled |
| `R2_BUCKET`, `R2_ACCESS_KEY`, `R2_SECRET_KEY`, `R2_ENDPOINT` | Photo storage when `storage.type: r2` | local disk |
| `ADMIN_PORTAL_URL`, `APP_DOWNLOAD_URL`, `APP_NAME` | Links in emails | localhost:3000 |

## CI
`.github/workflows/ci.yml`: `domain` (language validation), `backend`, `web`, `mobile`, each path-filtered, plus the `CI status` aggregate that branch protection requires. Other workflows: `standards-check` (advisory), `validate-specs` (weekly), `generate-changelog` (on tags).

## MCP servers
Servers live in `.mcp.json`; plugins in `enabledPlugins` of `.claude/settings.json`. Web fetch is the built-in `WebFetch` and GitHub goes through `gh`, so neither has a server. `context7` is set to `false` in `enabledPlugins` (it fails OAuth `invalid_target`). Export `MUNSERV_DB_URL` (for the dev database: `postgresql://munserv:munserv_dev@localhost:5435/munserv_dev`) before you start Claude Code.

| Name | Kind | Runs | Used by | Notes |
|---|---|---|---|---|
| `postgres` | MCP server | `docker run` of `crystaldba/postgres-mcp:0.3.0`, `--access-mode=restricted`, `--init`, `--network host`, URL from `MUNSERV_DB_URL` | `investigator` (`execute_sql`, `list_objects`, `get_object_details`) | Read-only; the restricted parser rejects writes and some functions such as `postgis_full_version()`. Check PostGIS with `pg_extension`. The container takes about 19 s to answer, so `MCP_TIMEOUT=60000` in `.claude/settings.json` lifts the 30 s default; without it the server shows "timed out". `--init` lets SIGTERM stop the container, so none outlive the session. The PyPI package does not install (`pglast==7.2.0` is missing), so use the image. |
| `playwright` | MCP server | `npx -y @playwright/mcp` | web UI checks in a session | Not granted to any agent. |
| `typescript-lsp` | plugin (`claude-plugins-official`) | `typescript-language-server` on PATH | `web-implementer` (`LSP` tool) | Install once: `npm install -g typescript-language-server typescript`. |
| `dart-flutter` | plugin (marketplace `flutter/agent-plugins`) | `dart mcp-server` from the Dart SDK on PATH, plus 25 Dart and Flutter skills | `mobile-implementer` (all `dart-mcp-server` tools) | Official Dart and Flutter team plugin, v1.0.7. Adds about 2.5k tokens to every session. |

## Mock API
`infrastructure/mock-api` (Express) on port 3001 for mobile UI work without the backend: `npm start`, then `flutter run --dart-define=API_PORT=3001`.

## Deployment
Not set up yet. The target from the archived DevOps and tech-stack documents is DigitalOcean App Platform plus managed PostgreSQL and Cloudflare R2; nothing is provisioned.

## Cost meter (telemetry profile)
```bash
cd infrastructure/docker
docker compose --profile telemetry up -d otel-collector    # start; `docker compose stop otel-collector` stops it
```
The collector appends Claude Code's OTLP metrics and logs to `infrastructure/telemetry/data/*.jsonl`. The console's Cost section (`scripts/console/cost.py`) reads `metrics.jsonl`: cost and tokens per day, per `agent.name`, per model and per story. A run joins a story with `OTEL_RESOURCE_ATTRIBUTES=story.id=<id>`; a run without it counts under `none`.

Facts verified against real runs (Claude Code 2.1.312):
- **Project settings do not start telemetry.** `.claude/settings.json` carries the `env` block, but Claude Code ignored it at project scope: nothing reached the collector until the same variables were exported in the shell, passed with `--settings <file>`, or set in `~/.claude/settings.json`. Until the block is copied to user settings, export it before the run.
- The protocol must be `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`: the default is gRPC, and 4318 speaks HTTP.
- `agent.name` reads `custom` for every project-defined agent unless `OTEL_LOG_TOOL_DETAILS=1`. With it, the real names (`clerk`, `Explore`) appear. The flag also writes Bash commands, file paths and tool input to `logs.jsonl`, which is why that file is gitignored and the port is localhost only.
- Metrics export every 60 s by default; set `OTEL_METRIC_EXPORT_INTERVAL=3000` for a short run, or the process may exit first.
- The files hold the account email. Do not commit or share them. Do not truncate them while the collector runs; stop it first.
