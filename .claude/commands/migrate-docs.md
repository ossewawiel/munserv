# Migrate Documentation

name: "migrate-docs"
description: "Migrate from current to target doc structure"
parameters:
  - name: "dry-run"
    description: "Preview changes only: true, false"
    default: "true"
  - name: "scope"
    description: "What to migrate: all, requirements, contracts, architecture"
    default: "all"

---

## Task

Migrate documentation from verbose current structure to concise target structure.

## Context

### Current Structure (Verbose)
```
specs/
├── MVP_Development_Guide.md      # 27KB - stories + API + mock data
├── Architecture_and_Design_Patterns.md  # 19KB
├── Coding_Standards.md
├── Testing_Strategy.md
├── DevOps_Strategy.md
├── phases/                       # Phase docs
└── [other docs]
```

### Target Structure (Concise)
```
specs/
├── requirements/
│   ├── mobile.md
│   ├── web.md
│   └── backlog.md
├── architecture/
│   ├── overview.md
│   ├── decisions/
│   └── patterns.md
├── contracts/
│   ├── api.md
│   └── types.md
├── features/
│   └── {feature}/
└── operations/
    ├── devops.md
    └── environments.md
```

## Process

### Step 1: Create New Structure

```bash
mkdir -p specs/requirements
mkdir -p specs/architecture/decisions
mkdir -p specs/contracts
mkdir -p specs/features
mkdir -p specs/operations
```

### Step 2: Extract Requirements

From `MVP_Development_Guide.md` Section 2:

**Mobile Stories → `specs/requirements/mobile.md`:**
```markdown
# Mobile Requirements

| ID | Story | Criteria | Status |
|----|-------|----------|--------|
| M1 | Register with phone + OTP | Phone validated, OTP verified | 🟢 Done |
| M2 | Login with PIN/biometric | Auth successful, token stored | 🟢 Done |
...
```

**Web Stories → `specs/requirements/web.md`:**
```markdown
# Web Requirements

| ID | Story | Criteria | Status |
|----|-------|----------|--------|
| W1 | Admin login | Email/password auth | 🟢 Done |
| W2 | View dashboard | Stats displayed | 🟢 Done |
...
```

### Step 3: Extract API Contract

From `MVP_Development_Guide.md` Section 4:

**→ `specs/contracts/api.md`:**
```markdown
# API Contract

## Auth
### POST /auth/register
**Request:** `{ phone }`
**Response:** `{ otpSent, expiresIn }`

### POST /auth/verify
**Request:** `{ phone, otp }`
**Response:** `{ accessToken, refreshToken, member }`
...
```

**→ `specs/contracts/types.md`:**
```markdown
# Shared Types

## Member
| Field | Type | Notes |
|-------|------|-------|
| id | MemberId | UUID |
| phone | string | E.164 format |
| name | string | Display name |
...
```

### Step 4: Extract Architecture

From `Architecture_and_Design_Patterns.md`:

**→ `specs/architecture/overview.md`:**
```markdown
# System Architecture

## Layers
- Backend: Kotlin + Spring Boot
- Mobile: Flutter + Riverpod
- Web: React + TypeScript

## Key Principles
- Result pattern for errors
- Feature-based folders
- Contract-first API
```

**→ `specs/architecture/patterns.md`:**
```markdown
# Code Patterns

## Backend Patterns
### Sealed Result
[concise example]

## Mobile Patterns
### AsyncValue
[concise example]
...
```

### Step 5: Create ADRs

Extract decisions into individual ADRs:

```
specs/architecture/decisions/
├── 001-kotlin-backend.md
├── 002-flutter-mobile.md
├── 003-react-web.md
├── 004-result-pattern.md
├── 005-feature-folders.md
└── 006-postgis-database.md
```

### Step 6: Migrate Operations

**→ `specs/operations/devops.md`:**
Extract from DevOps_Strategy.md (condensed)

**→ `specs/operations/environments.md`:**
Environment configuration summary

## Dry Run Output

When `dry-run=true`, output:

```markdown
# Migration Preview

## Files to Create
- specs/requirements/mobile.md (15 stories)
- specs/requirements/web.md (9 stories)
- specs/contracts/api.md (20 endpoints)
- specs/contracts/types.md (8 types)
- specs/architecture/overview.md
- specs/architecture/patterns.md (12 patterns)
- specs/architecture/decisions/001-*.md (6 ADRs)

## Content Summary
| Source | Target | Items |
|--------|--------|-------|
| MVP_Development_Guide §2.1 | requirements/mobile.md | 7 stories |
| MVP_Development_Guide §2.2 | requirements/web.md | 9 stories |
| MVP_Development_Guide §4 | contracts/api.md | 20 endpoints |
| Architecture_and_Design §2-4 | architecture/patterns.md | 12 patterns |

## Original Files
Will be preserved with `_archive` suffix after migration.
```

## Quality Checklist

- [ ] All stories extracted
- [ ] All endpoints captured
- [ ] ADRs created for key decisions
- [ ] Links updated
- [ ] Original files preserved

## Post-Migration

After migration:
1. Run `/sync-docs` to validate
2. Update CLAUDE.md references
3. Update README references
4. Archive original files when verified
