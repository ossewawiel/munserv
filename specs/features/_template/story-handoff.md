---
issue: 0
story: W00
title: ""
platform: backend | web | mobile
status: pending
depends_on: []          # other story ids or issue numbers that must be merged first
touches: []             # feature folders this story edits; the orchestrator serialises overlaps
created_by: feature-planner
created_at: ""
files_changed: []
tests_added: []
---

# W00 · Title (Platform)

Read `domain/README.md` for every term used below. This handoff is complete on its own; do not read the feature spec or other platforms' handoffs unless a step says so.

## Outcome
One sentence: what a user or caller can do after this story that they could not before.

## Acceptance criteria
- [ ] AC1 (copied verbatim from the GitHub issue)
- [ ] AC2

## Contract
API or type changes this story depends on, quoted from `specs/contracts/api.md` / `types.md`. "None" if none.

## Steps
Numbered, imperative, one file per step where possible. Each step names the file path, what to add or change, and the test that proves it.

1. `path/to/File.kt`: add `X`. Test: `path/to/FileTest.kt` `should ... when ...`.
2. ...

## Do not
- Things that look reasonable but are wrong for this story (other platforms, renames, refactors outside the listed files).

## Done when
```bash
# every command must exit 0 before you finish
cd backend && ./gradlew ktlintCheck test
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a summary of changes. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.
