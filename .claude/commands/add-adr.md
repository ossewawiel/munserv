# Add Architecture Decision Record

name: "add-adr"
description: "Create Architecture Decision Record"
parameters:
  - name: "title"
    description: "Decision title (e.g., 'Use Result pattern')"
    required: true
  - name: "context"
    description: "Why this decision was needed (1-2 sentences)"
    required: true
  - name: "decision"
    description: "What was decided"
    required: true
  - name: "consequences"
    description: "Impact - pros and cons (pipe-separated)"
    required: false
  - name: "status"
    description: "Status: proposed, accepted, deprecated, superseded"
    default: "accepted"

---

## Task

Create ADR at `specs/architecture/decisions/{{num}}-{{slug}}.md`.

## Context

Read first:
1. `specs/architecture/decisions/` - Existing ADRs
2. Platform CLAUDE.md files for related decisions

## Process

### Step 1: Determine ADR Number

Count existing ADRs and assign next number:
```
ls specs/architecture/decisions/*.md | wc -l
```
Next number = count + 1, zero-padded to 3 digits (001, 002, etc.)

### Step 2: Generate Slug

Convert title to kebab-case:
- "Use Result Pattern" → "use-result-pattern"
- "Kotlin for Backend" → "kotlin-for-backend"

### Step 3: Create ADR File

Create `specs/architecture/decisions/{{num}}-{{slug}}.md`:

```markdown
# ADR-{{num}}: {{title}}

**Date:** {{current_date}}
**Status:** {{status}}

## Context
{{context}}

## Decision
{{decision}}

## Consequences
{{#each consequences}}
{{#if positive}}✅{{else}}⚠️{{/if}} {{this}}
{{/each}}
```

### Step 4: Update Index (if exists)

If `specs/architecture/decisions/README.md` exists, add entry.

## ADR Template (CONCISE)

```markdown
# ADR-004: Use Result Pattern for Error Handling

**Date:** 2026-01-13
**Status:** Accepted

## Context
Need consistent error handling across platforms without exceptions for flow control.

## Decision
Use sealed Result<T, E> types. Success returns data, Failure returns typed error.

## Consequences
✅ Type-safe error handling
✅ Explicit error paths in code
✅ Consistent across platforms
⚠️ More verbose than exceptions
⚠️ Learning curve for new developers
```

## Status Values

| Status | Meaning |
|--------|---------|
| Proposed | Under discussion |
| Accepted | Approved and active |
| Deprecated | No longer recommended |
| Superseded | Replaced by another ADR |

If superseded, add:
```markdown
**Superseded by:** ADR-XXX
```

## Common ADR Topics

- Technology choices (language, framework)
- Architectural patterns (layers, modules)
- Code patterns (error handling, state)
- Data patterns (storage, caching)
- Integration patterns (APIs, messaging)

## Quality Checklist

- [ ] Context explains WHY, not just WHAT
- [ ] Decision is clear and actionable
- [ ] Both pros (✅) and cons (⚠️) listed
- [ ] Date and status present
- [ ] Filename follows ###-slug.md pattern

## Next Steps

After creating ADR:
1. Update platform CLAUDE.md if new rules
2. Add pattern example: `/add-pattern`
3. Update architecture overview if significant
