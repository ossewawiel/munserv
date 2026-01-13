# Architecture Decision Records

| # | Decision | Status | Date |
|---|----------|--------|------|
| 001 | [Kotlin for Backend](001-kotlin-backend.md) | Accepted | 2024 |
| 002 | [Flutter for Mobile](002-flutter-mobile.md) | Accepted | 2024 |
| 003 | [React for Web](003-react-web.md) | Accepted | 2024 |
| 004 | [Result Pattern](004-result-pattern.md) | Accepted | 2024 |
| 005 | [Feature-based Folders](005-feature-folders.md) | Accepted | 2024 |
| 006 | [PostGIS for Geospatial](006-postgis-database.md) | Accepted | 2024 |

## ADR Template

```markdown
# ADR-XXX: Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded

## Context
Why this decision was needed (1-2 sentences).

## Decision
What was decided.

## Consequences
✅ Positive outcome
⚠️ Trade-off or concern
```

## Adding New ADRs

Use `/add-adr` skill:
```
/add-adr title="Use Redis for Caching" context="Need fast session storage" decision="Use Redis"
```
