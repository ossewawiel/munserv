# Specs

Living documents only. History lives in [`archive/`](archive/README.md) and is not read by default.

| Document | Purpose |
|---|---|
| [`../domain/`](../domain/README.md) | The vocabulary: every concept, its states, and its code names on each platform |
| [requirements/mobile.md](requirements/mobile.md), [requirements/web.md](requirements/web.md), [requirements/backend.md](requirements/backend.md) | Stories with status; mirrored by GitHub issues |
| [requirements/backlog.md](requirements/backlog.md) | Deferred features and success criteria |
| [contracts/api.md](contracts/api.md) | API endpoints (source of truth for the wire contract) |
| [contracts/types.md](contracts/types.md) | Shared types and enums with generation annotations |
| [architecture/overview.md](architecture/overview.md) | System shape |
| [architecture/patterns.md](architecture/patterns.md) | Short pattern index; the full catalogues are the `.claude/skills/*-patterns` skills |
| [architecture/decisions/](architecture/decisions/) | ADRs |
| [architecture/standards-registry.md](architecture/standards-registry.md) | Coding standards and how each is enforced |
| [features/](features/) | One folder per feature: spec, implementation plan, platform handoffs, completed/ |
| [operations/devops.md](operations/devops.md), [operations/environments.md](operations/environments.md) | Git workflow, CI jobs, the one (development) environment, ports, environment variables |
| [Web_Theming_Guide.md](Web_Theming_Guide.md), [Mobile_Theming_Guide.md](Mobile_Theming_Guide.md) | Theme systems; move into the design-system tokens and skills when that PR lands |

## Adding content
- New term: add a file under `domain/` and an entry in `domain/language.yaml` first.
- New feature or story: describe it to `/factory` (the `feature-planner` writes the stories, issues, spec and handoffs). Bugs go through the `investigator`. See the factory section of the root `CLAUDE.md`.
- New decision: add an ADR under `architecture/decisions/`.
- New endpoint or type: edit `contracts/api.md` or `contracts/types.md` in the same PR as the code.
