# Archived specifications

These documents are historical. They were written during discovery and the MVP build (December 2025 to January 2026) and are kept because they explain why things are the way they are. They are not maintained, they are not read by agents by default, and where they disagree with the current sources of truth, the current sources win.

Current sources of truth:

| For | Read |
|---|---|
| Vocabulary, entities, states | [`domain/`](../../domain/README.md) |
| What to build | GitHub issues and [`specs/requirements/`](../requirements/) |
| API and shared types | [`specs/contracts/`](../contracts/) |
| Architecture and decisions | [`specs/architecture/`](../architecture/) |
| Platform rules | `backend/CLAUDE.md`, `web/CLAUDE.md`, `mobile/CLAUDE.md` and the skills under `.claude/skills/` |
| Environments and CI | [`specs/operations/`](../operations/) |

## Contents

| Document | What it was |
|---|---|
| `application-specification-beta.md` | The original one-page idea |
| `Domain_and_Data_Modeling.md` | Discovery-phase domain model; superseded by `domain/` |
| `Tech_Stack_Selection.md` | Stack rationale (Flutter, React, Kotlin, PostGIS, R2, DigitalOcean) |
| `Architecture_and_Design_Patterns.md` | Long-form pattern catalogue; distilled into the platform skills |
| `Coding_Standards.md` | Naming and formatting rules; distilled into platform CLAUDE.md files |
| `Testing_Strategy.md` | Test pyramid and coverage targets |
| `DevOps_Strategy.md` | Git workflow, CI and deployment plan; the CI that exists is `.github/workflows/ci.yml` |
| `MVP_Development_Guide.md` | MVP scope, mock data and screen inventory |
| `Backend_Development_Guide.md` | Phased backend implementation plan, completed January 2026 |
| `Web_Backend_Migration_Guide.md` | Moving the web app from the mock API to the real backend |
| `Specification_Roadmap.md` | Document status tracker from the MVP phase |
| `phases/` | Web registration phase handoffs |
| Images and the `.docx` | Early theme references and a map-view note |
