# DevOps Strategy

**Project:** MunServ | **Version:** 1.0 | **Status:** Approved

---

## 1. Repository Structure

**Model:** Monorepo

```
munserv/
├── backend/          # Kotlin/Spring Boot
├── mobile/           # Flutter
├── web/              # React
├── database/         # Migrations, seeds
├── shared/           # API contracts, types
├── infrastructure/   # Docker, IaC
├── scripts/          # Dev utilities
├── specs/            # Documentation
└── CLAUDE.md         # Root context
```

---

## 2. Git Workflow

### Branching Model: GitHub Flow (Simplified)

```
main (production-ready)
  │
  ├── feature/issue-reporting
  ├── feature/member-auth
  ├── fix/photo-upload-crash
  └── chore/update-dependencies
```

| Branch | Purpose | Merges To | Protection |
|--------|---------|-----------|------------|
| `main` | Production-ready code | — | Protected, requires PR |
| `feature/*` | New functionality | main | — |
| `fix/*` | Bug fixes | main | — |
| `chore/*` | Maintenance, deps, docs | main | — |
| `refactor/*` | Code improvements | main | — |

### Branch Naming

```
{type}/{short-description}

feature/issue-reporting
feature/heat-calculation
fix/photo-gps-extraction
chore/upgrade-spring-boot
refactor/issue-service-cleanup
```

**Rules:**
- Lowercase only
- Hyphens for spaces
- Max 50 characters
- No issue numbers in branch name (use commits)

---

## 3. Commit Messages

### Format: Conventional Commits

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code change, no feature/fix |
| `test` | Adding/updating tests |
| `chore` | Build, deps, config |

### Scopes

| Scope | Area |
|-------|------|
| `backend` | Kotlin/Spring Boot |
| `mobile` | Flutter |
| `web` | React |
| `db` | Database, migrations |
| `api` | API contracts |
| `infra` | Docker, deployment |

### Examples

```
feat(backend): add issue state transition validation

fix(mobile): prevent duplicate photo uploads

docs(api): add authentication endpoint specs

chore(deps): upgrade Spring Boot to 3.2.0

refactor(backend): extract heat calculation to domain service

Closes #42
```

### Rules
- Subject: imperative mood, no period, max 72 chars
- Body: wrap at 72 chars, explain what and why
- Footer: reference issues with `Closes #n` or `Refs #n`

---

## 4. Pull Requests

### PR Title
Same format as commit message:
```
feat(backend): add issue reporting endpoint
```

### PR Template

```markdown
## Summary
Brief description of changes.

## Type
- [ ] Feature
- [ ] Fix
- [ ] Refactor
- [ ] Chore

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing done

## Checklist
- [ ] Code follows project standards
- [ ] Self-reviewed
- [ ] No console.log/print statements
- [ ] Documentation updated if needed
```

### Merge Strategy
- **Squash and merge** for feature/fix branches
- Single clean commit on main
- PR title becomes commit message

### Requirements Before Merge
- [ ] All CI checks pass
- [ ] At least 1 approval (when team exists)
- [ ] No unresolved comments
- [ ] Branch up to date with main

---

## 5. Local Development Environment

### Prerequisites (WSL2)

```bash
# Required
- Docker Desktop (WSL2 backend)
- JDK 21+
- Flutter SDK
- Node.js 20+
- pnpm (preferred) or npm

# Recommended
- IntelliJ IDEA or VS Code
- DBeaver or pgAdmin
- Postman or Insomnia
```

### Docker Compose Services

```yaml
# infrastructure/docker/docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgis/postgis:15-3.3
    container_name: munserv-db
    environment:
      POSTGRES_USER: munserv
      POSTGRES_PASSWORD: munserv_dev
      POSTGRES_DB: munserv_dev
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U munserv"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: munserv-redis
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data

volumes:
  pgdata:
  redisdata:
```

### Dev Commands

```bash
# Start services
docker compose -f infrastructure/docker/docker-compose.yml up -d

# Stop services
docker compose -f infrastructure/docker/docker-compose.yml down

# View logs
docker compose -f infrastructure/docker/docker-compose.yml logs -f postgres

# Reset database
docker compose -f infrastructure/docker/docker-compose.yml down -v
docker compose -f infrastructure/docker/docker-compose.yml up -d
```

### Makefile (Project Root)

```makefile
.PHONY: dev-up dev-down dev-logs db-reset backend-run backend-test web-dev mobile-run

# Infrastructure
dev-up:
	docker compose -f infrastructure/docker/docker-compose.yml up -d

dev-down:
	docker compose -f infrastructure/docker/docker-compose.yml down

dev-logs:
	docker compose -f infrastructure/docker/docker-compose.yml logs -f

db-reset:
	docker compose -f infrastructure/docker/docker-compose.yml down -v
	docker compose -f infrastructure/docker/docker-compose.yml up -d

# Backend
backend-run:
	cd backend && ./gradlew bootRun

backend-test:
	cd backend && ./gradlew test

backend-lint:
	cd backend && ./gradlew ktlintCheck

# Web
web-dev:
	cd web && pnpm dev

web-test:
	cd web && pnpm test

web-lint:
	cd web && pnpm lint

# Mobile
mobile-run:
	cd mobile && flutter run

mobile-test:
	cd mobile && flutter test

# All
lint-all: backend-lint web-lint
	cd mobile && flutter analyze

test-all: backend-test web-test mobile-test
```

---

## 6. CI/CD Pipeline

### Platform: GitHub Actions

### Pipeline Stages

```
Push/PR → Build → Lint → Test → [Security] → [Deploy]
```

| Stage | Trigger | Actions |
|-------|---------|---------|
| Build | Every push | Compile all projects |
| Lint | Every push | ktlint, eslint, flutter analyze |
| Test | Every push | Unit + integration tests |
| Security | PRs to main | Dependency scan |
| Deploy Dev | Merge to main | Auto-deploy to dev |
| Deploy Prod | Release tag | Manual approval → deploy |

### Workflow Structure

```
.github/
└── workflows/
    ├── ci.yml           # Build, lint, test (all pushes)
    ├── security.yml     # Dependency scanning (PRs)
    └── deploy.yml       # Deployment (main, tags)
```

### CI Workflow (ci.yml)

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:15-3.3
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
      - name: Build & Test
        working-directory: backend
        run: ./gradlew build

  web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
          cache-dependency-path: web/pnpm-lock.yaml
      - name: Install & Test
        working-directory: web
        run: |
          pnpm install
          pnpm lint
          pnpm test
          pnpm build

  mobile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - name: Analyze & Test
        working-directory: mobile
        run: |
          flutter pub get
          flutter analyze
          flutter test
```

---

## 7. Environment Strategy

### Environments

| Environment | Purpose | Database | Deployment |
|-------------|---------|----------|------------|
| Local | Development | Docker PostgreSQL | Manual |
| Dev | Integration testing | Managed PostgreSQL | Auto on merge |
| Staging | Pre-production | Managed PostgreSQL | Manual |
| Production | Live | Managed PostgreSQL | Manual + approval |

### Configuration

```
backend/src/main/resources/
├── application.yml              # Shared defaults
├── application-local.yml        # Local overrides
├── application-dev.yml          # Dev environment
├── application-staging.yml      # Staging
└── application-prod.yml         # Production
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_URL` | Database connection | `jdbc:postgresql://localhost:5432/munserv` |
| `DB_USER` | Database user | `munserv` |
| `DB_PASSWORD` | Database password | (secret) |
| `R2_BUCKET` | Cloudflare R2 bucket | `munserv-photos-dev` |
| `R2_ACCESS_KEY` | R2 access key | (secret) |
| `R2_SECRET_KEY` | R2 secret key | (secret) |
| `JWT_SECRET` | JWT signing key | (secret) |
| `SMS_API_KEY` | SMS provider key | (secret) |

### Secrets Management

| Environment | Method |
|-------------|--------|
| Local | `.env` file (git-ignored) |
| CI/CD | GitHub Secrets |
| Production | Cloud provider secrets (DO, AWS) |

---

## 8. Docker Standards

### Base Images

| Project | Base Image |
|---------|------------|
| Backend | `eclipse-temurin:21-jre-alpine` |
| Web | `node:20-alpine` (build) → `nginx:alpine` (serve) |

### Dockerfile Pattern (Backend)

```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY gradle gradle
COPY gradlew build.gradle.kts settings.gradle.kts ./
RUN ./gradlew dependencies --no-daemon
COPY src src
RUN ./gradlew bootJar --no-daemon

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Image Naming

```
munserv/{component}:{version}

munserv/backend:1.0.0
munserv/backend:latest
munserv/web:1.0.0
```

---

## 9. Database Migrations

### Tool: Flyway (integrated with Spring Boot)

### Migration Location
```
database/migrations/
├── V001__create_enums.sql
├── V002__create_pods_table.sql
├── V003__create_sectors_table.sql
└── ...
```

### Naming Convention
```
V{version}__{description}.sql

V001__create_enums.sql
V002__create_pods_table.sql
V010__add_heat_index.sql
```

### Rules
- Migrations are immutable once in main
- Use 3-digit version numbers (allows inserts: V001, V002, V005)
- Each migration is a single transaction
- Include rollback comments (not auto-executed)

### Commands
```bash
# Run migrations (via Spring Boot)
./gradlew bootRun  # Auto-runs on startup

# Or standalone Flyway
flyway -url=jdbc:postgresql://localhost:5432/munserv_dev migrate
```

---

## 10. Quick Reference

### Daily Workflow

```bash
# 1. Start services
make dev-up

# 2. Create feature branch
git checkout -b feature/issue-reporting

# 3. Develop with hot reload
make backend-run   # Terminal 1
make web-dev       # Terminal 2

# 4. Test
make test-all

# 5. Commit
git add .
git commit -m "feat(backend): add issue reporting endpoint"

# 6. Push and create PR
git push -u origin feature/issue-reporting
# Create PR on GitHub

# 7. After merge, clean up
git checkout main
git pull
git branch -d feature/issue-reporting
```

### Port Allocations

| Service | Port |
|---------|------|
| PostgreSQL | 5432 |
| Redis | 6379 |
| Backend API | 8080 |
| Web Dev Server | 3000 |
| Mobile (varies) | — |

---

*Document optimized for LLM context. Include when working on infrastructure, CI/CD, or deployment tasks.*
