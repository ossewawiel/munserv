# Infrastructure Context - Docker & Deployment

## Primary Reference
**See `/specs/DevOps_Strategy.md` for complete DevOps specifications.**

This file contains quick reference for infrastructure tasks. Full details in the spec.

---

## MCP Server Setup (Claude Code in WSL2)

Based on official Claude Code documentation: https://code.claude.com/docs/en/mcp

### Quick Setup

```bash
# From WSL2, navigate to project
cd /mnt/d/SourceCode/pocs/munserv

# Run setup script
chmod +x scripts/setup-mcp.sh
./scripts/setup-mcp.sh
```

### Manual Setup

No global npm install needed - `npx` downloads packages on-demand.

```bash
# Navigate to project
cd /mnt/d/SourceCode/pocs/munserv

# 1. Memory server (persists decisions across sessions)
claude mcp add --transport stdio memory -- npx -y @modelcontextprotocol/server-memory

# 2. Fetch server (HTTP requests, test endpoints)
claude mcp add --transport stdio fetch -- npx -y @modelcontextprotocol/server-fetch

# 3. Sequential thinking (complex reasoning tasks)
claude mcp add --transport stdio thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# 4. Verify
claude mcp list
```

### GitHub MCP (when needed)

```bash
# Option A: HTTP transport with token (recommended)
export GITHUB_TOKEN='ghp_your_token_here'
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer $GITHUB_TOKEN"

# Option B: Docker transport
claude mcp add --transport stdio github \
  -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here \
  -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
```

### PostgreSQL MCP (Backend Phase)

```bash
# 1. Start the database first
cd infrastructure/docker && docker-compose up -d

# 2. Add PostgreSQL MCP
claude mcp add --transport stdio postgres \
  -- npx -y @modelcontextprotocol/server-postgres \
  "postgresql://munserv:munserv_dev@localhost:5435/munserv_dev"
```

### MCP Servers for MunServ

| MCP | Purpose | When to Add |
|-----|---------|-------------|
| memory | Persist architectural decisions | Always |
| fetch | Test API endpoints | MVP phase |
| thinking | Complex multi-step reasoning | As needed |
| github | PRs, issues, branches | When using GitHub |
| postgres | Query schema, validate SQL | Backend phase |

### Managing MCP Servers

```bash
claude mcp list              # List all configured servers
claude mcp get <name>        # Get server details  
claude mcp remove <name>     # Remove a server
/mcp                         # Check status inside Claude Code
```

### MCP Scopes

| Scope | Flag | Storage | Use Case |
|-------|------|---------|----------|
| local | `--scope local` (default) | `~/.claude.json` | Personal, project-specific |
| project | `--scope project` | `.mcp.json` | Shared with team via git |
| user | `--scope user` | `~/.claude.json` | Personal, cross-project |

### Configuration Files

| File | Purpose |
|------|---------|
| `~/.claude.json` | User/local scope MCP configs |
| `.mcp.json` | Project scope (checked into git) |

---

## Docker Compose (Local Dev)

**Location:** `infrastructure/docker/docker-compose.yml`

### Quick Start

```bash
# Start services
cd infrastructure/docker
docker compose up -d

# Verify
docker compose ps
docker compose logs -f postgres

# Connect to database
psql postgresql://munserv:munserv_dev@localhost:5435/munserv_dev

# Stop services
docker compose down

# Reset database (destroys all data)
docker compose down -v && docker compose up -d
```

### Services

| Service | Image | Port |
|---------|-------|------|
| PostgreSQL + PostGIS | postgis/postgis:15-3.3 | 5435 (host) → 5432 |
| Redis | redis:7-alpine | 6380 (host) → 6379 |

### Connection Strings

```
PostgreSQL: postgresql://munserv:munserv_dev@localhost:5435/munserv_dev
Redis: redis://localhost:6380
```

---

## Port Allocations

| Service | Port |
|---------|------|
| PostgreSQL | 5435 |
| Redis | 6380 |
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

---

## CI/CD Reference

**Platform:** GitHub Actions

| Workflow | Purpose | Trigger |
|----------|---------|---------|
| `ci.yml` | Build, lint, test | Every push |
| `security.yml` | Dependency scan | PRs to main |
| `deploy.yml` | Deployment | Merge to main, tags |

See `/specs/DevOps_Strategy.md` Section 6 for full pipeline definitions.
