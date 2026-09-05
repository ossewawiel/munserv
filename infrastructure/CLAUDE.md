# Infrastructure card

## Local services
`infrastructure/docker/docker-compose.yml` runs the only local dependency:

| Service | Image | Host port | Notes |
|---|---|---|---|
| PostgreSQL + PostGIS | `postgis/postgis:18-3.6` | 5435 | Volume mounted at `/var/lib/postgresql` as the 18 image requires |

Ports 5432, 5433, 5434 and 6379 belong to other projects on the dev machine; do not reuse them.

```bash
cd infrastructure/docker
docker compose up -d                 # start
docker compose down -v && docker compose up -d   # reset (destroys data)
psql postgresql://munserv:munserv_dev@localhost:5435/munserv_dev

# Stop services
docker compose down

# Reset database (destroys all data)
docker compose down -v && docker compose up -d
```

### Services

| Service | Image | Port |
|---------|-------|------|
| PostgreSQL + PostGIS | postgis/postgis:18-3.6 | 5435 (host) → 5432 |

### Connection Strings

```
PostgreSQL: postgresql://munserv:munserv_dev@localhost:5435/munserv_dev
```

---

## Port Allocations

| Service | Port |
|---------|------|
| PostgreSQL | 5435 |
| Backend API | 8080 |
| Mock API | 3001 |
| Web Dev Server | 3000 |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DB_URL` | Database JDBC URL |
| `DB_USER` | Database user |
| `DB_PASSWORD` | Database password |
| `R2_BUCKET` | Cloudflare R2 bucket |
| `R2_ACCESS_KEY` | R2 access key |
| `R2_SECRET_KEY` | R2 secret key |
| `JWT_SECRET` | JWT signing key |
| `SMS_API_KEY` | SMS provider key |
| `GITHUB_TOKEN` | GitHub PAT for MCP |

---

## Folder Structure

```
infrastructure/
├── CLAUDE.md                    # This file
├── claude_desktop_config.example.json  # Example for Claude Desktop
├── docker/
│   ├── docker-compose.yml       # Local dev services
│   └── init/
│       └── 01-extensions.sql    # PostGIS setup
├── mock-api/                    # JSON Server mock API
│   ├── server.js
│   ├── package.json
│   └── data/
└── scripts/                     # Utility scripts
```
Backend tests do not use this database; they start their own PostGIS container through Testcontainers.

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
Declared in `.mcp.json`: `memory`, `fetch`, `postgres` (points at 5435). Set `GITHUB_TOKEN` to enable the GitHub server declared in `.claude/settings.json`; `gh` works without it.

## Mock API
`infrastructure/mock-api` (Express) on port 3001 for mobile UI work without the backend: `npm start`, then `flutter run --dart-define=API_PORT=3001`.

## Deployment
Not set up yet. The target from the archived DevOps and tech-stack documents is DigitalOcean App Platform plus managed PostgreSQL and Cloudflare R2; nothing is provisioned.
