# Update README

name: "update-readme"
description: "Update README with agentic workflow"
parameters:
  - name: "target"
    description: "root, web, backend, or mobile"
    required: true
  - name: "section"
    description: "Section to update: all, setup, skills, workflow"
    default: "all"

---

## Task

Update README for {{target}} with current state and agentic workflow.

## Context

Read first:
1. Target README file
2. Corresponding CLAUDE.md
3. Package files (package.json, build.gradle, pubspec.yaml)

## Target Mapping

| Target | README Path | CLAUDE.md |
|--------|-------------|-----------|
| root | /README.md | /CLAUDE.md |
| web | /web/README.md | /web/CLAUDE.md |
| backend | /backend/README.md | /backend/CLAUDE.md |
| mobile | /mobile/README.md | /mobile/CLAUDE.md |

## Process

### Step 1: Audit Current State

Compare README against:
- Actual folder structure
- Package dependencies
- Available commands
- CLAUDE.md content

### Step 2: Update Sections

#### Setup Section
```markdown
## Setup

### Prerequisites
- Node.js 20+ / JDK 21 / Flutter 3.x
- pnpm / Gradle / pub

### Installation
\`\`\`bash
[platform-specific commands]
\`\`\`

### Environment
Copy `.env.example` to `.env` and configure.
```

#### Skills Section (Agentic Workflow)
```markdown
## Development with Claude Code

### Available Skills

| Skill | Purpose |
|-------|---------|
| `/add-story` | Add user story |
| `/plan-feature` | Plan cross-platform feature |
| `/dev-cycle` | TDD development workflow |
| `/test` | Run tests |
| `/review` | Code review |

### MCP Integrations
- **postgres** - Query database schema
- **memory** - Persist decisions
- **github** - Manage PRs

### Workflow
1. `/add-story` → Define requirement
2. `/plan-feature` → Generate plan
3. `/dev-cycle` → Implement with TDD
4. `/test` → Verify
5. `/review` → Quality check
```

#### Commands Section
```markdown
## Commands

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start development server |
| `pnpm build` | Build for production |
| `pnpm test` | Run tests |
| `pnpm lint` | Lint code |
```

### Step 3: Verify Links

Ensure all internal links work:
- Links to CLAUDE.md
- Links to specs/
- Links to other READMEs

## README Templates

### Root README
```markdown
# MunServ

Municipal service issue tracker.

## Quick Start

1. Backend: `cd backend && ./gradlew bootRun`
2. Web: `cd web && pnpm dev`
3. Mobile: `cd mobile && flutter run`

## Development with Claude Code

This project uses Claude Code for agentic development.

### Project-Level Skills
| Skill | Purpose |
|-------|---------|
| `/add-story` | Add user story |
| `/add-feature` | Create feature spec |
| `/plan-feature` | Cross-platform plan |

### Platform Skills
- Backend: `/backend/dev-cycle`
- Web: `/web/dev-cycle`
- Mobile: `/mobile/dev-cycle`

## Documentation

- [Requirements](specs/requirements/)
- [API Contract](specs/contracts/api.md)
- [Architecture](specs/architecture/)
```

### Platform README
```markdown
# MunServ {{Platform}}

## Setup

\`\`\`bash
[install commands]
\`\`\`

## Commands

| Command | Description |
|---------|-------------|
| ... | ... |

## Development with Claude Code

### Available Skills
| Skill | Purpose |
|-------|---------|
| `/dev-cycle` | TDD workflow |
| `/test` | Run tests |

### Workflow
See [CLAUDE.md](CLAUDE.md) for patterns and conventions.
```

## Quality Checklist

- [ ] Setup instructions are current
- [ ] Commands match package scripts
- [ ] Skills section included
- [ ] Links are valid
- [ ] No placeholder text

## Next Steps

After updating README:
1. Sync other READMEs: `/sync-docs`
2. Verify with fresh clone test
