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
`.github/workflows/ci.yml`: `domain` (language validation), `backend`, `web`, `mobile`, each path-filtered, plus the `CI status` aggregate that branch protection requires. Other workflows: `standards-check` (advisory), `sync-issue-status`, `validate-specs` (weekly), `generate-changelog` (on tags).

## MCP servers
Declared in `.mcp.json`: `memory`, `fetch`, `postgres` (points at 5435). Set `GITHUB_TOKEN` to enable the GitHub server declared in `.claude/settings.json`; `gh` works without it.

## Mock API
`infrastructure/mock-api` (Express) on port 3001 for mobile UI work without the backend: `npm start`, then `flutter run --dart-define=API_PORT=3001`.

## Deployment
Not set up yet. The target from the archived DevOps and tech-stack documents is DigitalOcean App Platform plus managed PostgreSQL and Cloudflare R2; nothing is provisioned.
