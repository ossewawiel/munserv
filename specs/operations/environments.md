# Environments

One environment exists: a developer machine. There is no staging and no production. See `infrastructure/CLAUDE.md`, "Deployment".

## Development

| Service | URL | Port |
|---------|-----|------|
| Backend | http://localhost:8080 | 8080 |
| Web | http://localhost:3000 | 3000 |
| Database | localhost:5435 | 5435 |
| Mock API (optional) | http://localhost:3001 | 3001 |

```bash
# Database (PostGIS 18)
cd infrastructure/docker && docker compose up -d
# Backend
cd backend && ./gradlew bootRun
# Web
cd web && pnpm dev
# Mobile
cd mobile && flutter run
```

The `showcase` stack (web on :4000, API on :8090) and the eyeball stack are described in the root `CLAUDE.md`.

## Environment variables

The backend reads them from `backend/src/main/resources/application.yml`. Every one has a development default. The full list, with the mail, bootstrap, R2 and link variables, is in `infrastructure/CLAUDE.md`.

### Backend
```
DB_URL=jdbc:postgresql://localhost:5435/munserv_dev
DB_USER=munserv
DB_PASSWORD=munserv_dev
JWT_SECRET=<dev value in application.yml; set your own outside local>
SMTP_HOST=localhost
SMTP_PORT=587
```

### Web
```
VITE_API_URL=<API base URL>   # client default in src/lib/api-client.ts: http://localhost:3001/api/v1
VITE_DEMO_ACCOUNTS=<demo accounts for quick login; never set in production>
```
The dev server (`vite.config.ts`) proxies to the backend on http://localhost:8080. The pod theme is set with `VITE_POD_PRIMARY_COLOR`, `VITE_POD_SECONDARY_COLOR` and `VITE_POD_FONT_FAMILY`.

### Mobile (`--dart-define`)
```
API_HOST=10.0.2.2   # default; the Android emulator's route to the host
API_PORT=8080       # default; 3001 for the mock API
```
