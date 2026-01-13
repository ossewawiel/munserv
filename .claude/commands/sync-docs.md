# Sync Documentation

name: "sync-docs"
description: "Validate documentation consistency"
parameters:
  - name: "scope"
    description: "Scope: all, requirements, contracts, features, readmes"
    default: "all"
  - name: "fix"
    description: "Auto-fix issues: true, false"
    default: "false"

---

## Task

Validate documentation consistency and optionally fix issues.

## Context

Check these documentation areas:
- `specs/requirements/` - User stories
- `specs/contracts/` - API contract and types
- `specs/features/` - Feature specifications
- `specs/architecture/` - ADRs and patterns
- `*/README.md` - README files
- `*/CLAUDE.md` - Claude guidance files

## Process

### Step 1: Cross-Reference Validation

**Stories ↔ Features:**
- Every story in requirements should be referenced in a feature
- Every story in features should exist in requirements

**API ↔ Implementation:**
- Endpoints in contract should exist in backend controllers
- Request/response types should match

**Types ↔ Usage:**
- Types defined should be used somewhere
- Types used should be defined

### Step 2: Consistency Checks

**Status Indicators:**
- Same emoji system across all docs
- 🟢 Done, 🟡 In Progress, 🔴 Pending

**Naming Conventions:**
- Story IDs: M1, M2, W1, W2, S1
- Feature names: kebab-case
- ADR numbers: 001, 002, 003

**Date Formats:**
- ISO 8601 or YYYY-MM-DD consistently

### Step 3: Link Validation

Check all internal links:
- `specs/` references
- Cross-document links
- README links

### Step 4: Generate Report

## Validation Report Format

```markdown
# Documentation Validation Report

Generated: {{date}}

## Summary
| Category | Items | Issues | Fixed |
|----------|-------|--------|-------|
| Stories | 15 | 2 | 0 |
| Contracts | 20 | 1 | 1 |
| Features | 5 | 0 | 0 |
| Links | 45 | 3 | 0 |

## Critical Issues
| Location | Issue | Fix |
|----------|-------|-----|
| M8 in mobile.md | Missing in features | Add to auth feature |

## Warnings
| Location | Issue | Recommendation |
|----------|-------|----------------|
| api.md | Endpoint not implemented | Implement or remove |

## Info
- 3 stories marked complete
- 2 new types added since last sync
```

## Validation Rules

### Requirements
- [ ] Story IDs are sequential
- [ ] Each story has acceptance criteria
- [ ] Status is valid emoji

### Contracts
- [ ] All endpoints have request/response
- [ ] All types are used
- [ ] Error codes are documented

### Features
- [ ] Each feature has spec.md
- [ ] Stories referenced exist
- [ ] Status is current

### Architecture
- [ ] ADRs are numbered sequentially
- [ ] Patterns have code examples
- [ ] Decisions have consequences

### READMEs
- [ ] Setup instructions present
- [ ] Commands are current
- [ ] Links work

## Auto-Fix Capabilities

When `fix=true`:
- Fix status emoji consistency
- Update story references
- Remove orphaned entries
- Normalize formatting

**Cannot auto-fix:**
- Missing implementations
- Incorrect types
- Broken external links

## Quality Checklist

- [ ] All scopes checked
- [ ] Issues categorized correctly
- [ ] Fix suggestions actionable
- [ ] No false positives

## Next Steps

After validation:
1. Fix critical issues manually
2. Re-run with `fix=true` for auto-fixable
3. Update feature specs as needed
