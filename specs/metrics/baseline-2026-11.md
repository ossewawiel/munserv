# Factory baseline, 2026-11

Taken 2026-10-29 on master (39d908d). Bytes are file sizes; tokens are roughly bytes / 4.

## /skill-doctor

Output of `claude -p "/skill-doctor"`, skills loaded this session. Context is the one-line listing cost in tokens.

| Skill | Source | Context (tokens) | 7d tokens | Uses | Last used |
|---|---|---|---|---|---|
| backend-patterns | projectSettings | ~110 | - | 0 | never |
| database-patterns | projectSettings | ~100 | - | 0 | never |
| factory | projectSettings | - | - | 0 | never |
| mobile-design-system | projectSettings | ~120 | - | 0 | never |
| mobile-patterns | projectSettings | ~130 | - | 0 | never |
| web-data-table | projectSettings | ~80 | - | 0 | never |
| web-patterns | projectSettings | ~120 | - | 0 | never |
| add-adr | projectSettings | < 20 | - | 0 | never |
| add-endpoint | projectSettings | < 20 | - | 0 | never |
| add-feature | projectSettings | < 20 | - | 0 | never |
| add-pattern | projectSettings | < 20 | - | 0 | never |
| add-story | projectSettings | < 20 | - | 0 | never |
| add-type | projectSettings | < 20 | - | 0 | never |
| close-handoff | projectSettings | < 20 | - | 0 | never |
| create-feature | projectSettings | < 20 | - | 0 | never |
| create-issue | projectSettings | < 20 | - | 0 | never |
| generate-types | projectSettings | < 20 | - | 0 | never |
| plan-feature | projectSettings | < 20 | - | 0 | never |
| sync-docs | projectSettings | < 20 | - | 0 | never |
| sync-github | projectSettings | < 20 | - | 0 | never |
| update-readme | projectSettings | < 20 | - | 0 | never |
| work-issue | projectSettings | < 20 | - | 0 | never |
| work-story | projectSettings | < 20 | - | 0 | never |
| frontend-design:frontend-design | frontend-design | ~80 | - | 0 | never |
| anthropic-skills:akademia-sessie | claude.ai sync | ~70 | - | 0 | never |
| anthropic-skills:akademia-skryfhulp | claude.ai sync | ~60 | - | 0 | never |
| anthropic-skills:akademia-spensoudit | claude.ai sync | ~70 | - | 0 | never |
| anthropic-skills:akademia-vraestelbouer | claude.ai sync | ~60 | - | 0 | never |
| anthropic-skills:built-in-browser | claude.ai sync | ~290 | - | 0 | never |
| anthropic-skills:chrome-browser | claude.ai sync | ~260 | - | 0 | never |
| anthropic-skills:computer-use | claude.ai sync | ~320 | - | 0 | never |
| anthropic-skills:deep-research | claude.ai sync | ~200 | - | 0 | never |
| anthropic-skills:docs | claude.ai sync | ~340 | - | 0 | never |
| anthropic-skills:docx | claude.ai sync | ~320 | - | 0 | never |
| anthropic-skills:google-workspace | claude.ai sync | ~330 | - | 0 | never |
| anthropic-skills:import-memory | claude.ai sync | ~60 | - | 0 | never |
| anthropic-skills:morning | claude.ai sync | ~120 | - | 0 | never |
| anthropic-skills:pdf | claude.ai sync | ~150 | - | 0 | never |
| anthropic-skills:pptx | claude.ai sync | ~330 | - | 0 | never |
| anthropic-skills:skill-creator | claude.ai sync | ~120 | - | 0 | never |
| anthropic-skills:xlsx | claude.ai sync | ~320 | - | 0 | never |
| omarchy | userSettings | ~200 | - | 3 | 48 days |
| investigation-time | userSettings | ~250 | - | 6 | 30 days |
| interrogation-time | userSettings | ~110 | - | 2 | 30 days |
| diagnose-crash | userSettings | ~160 | 1.6m | 7 | 1 day |
| system-critique | userSettings | ~320 | 17m | 4 | 1 day |

| Finding | Count |
|---|---|
| Skills loaded, never invoked | 22 |
| claude.ai synced skills loaded, never invoked | 17 |
| Plugin skills loaded, never invoked (frontend-design) | 1 |
| Plugins unused: context7 (48 days), frontend-design (40 days), typescript-lsp (19 days) | 3 |
| `.claude/settings.json` allow rules ignored (`Write(path)` must be `Edit(path)`): backend, web, mobile, specs, domain | 5 |

## Bytes each agent loads at start

| Agent | Root CLAUDE.md | Agent body | Preloaded skills | Cards read | Total bytes | Cards read: files | After: total | After: vs baseline | After: vs master before this PR |
|---|---|---|---|---|---|---|---|---|---|
| backend-implementer | 7,271 | 2,106 | 13,007 | 15,258 | 37,642 | domain/README.md + backend/CLAUDE.md | 31,247 | -6,395 | -8,335 |
| web-implementer | 7,271 | 2,302 | 15,596 | 6,132 | 31,301 | domain/README.md + web/CLAUDE.md | 33,448 | +2,147 | +207 |
| mobile-implementer | 7,271 | 2,374 | 19,848 | 6,884 | 36,377 | domain/README.md + mobile/CLAUDE.md | 38,499 | +2,122 | +182 |
| feature-planner | 7,271 | 3,812 | 0 | 22,280 | 33,363 | domain/README.md + backend, web, mobile cards | 26,968 | -6,395 | -8,335 |
| investigator | 7,271 | 1,493 | 0 | 22,280 | 31,044 | domain/README.md + all three platform cards (upper bound) | 24,649 | -6,395 | -8,335 |
| reviewer | 7,271 | 2,215 | 0 | 15,258 | 24,744 | domain/README.md + largest platform card (backend) | 18,517 | -6,227 | -8,167 |
| designer | 7,271 | 2,915 | 0 | 15,640 | 25,826 | domain/README.md + design/README.md + design/registry/web.md + mobile.md | 27,973 | +2,147 | +207 |
| design-reviewer | 7,271 | 2,088 | 0 | 10,794 | 20,153 | design/registry/web.md + mobile.md (tokens not counted) | 22,300 | +2,147 | +207 |
| syncer | 7,271 | 1,206 | 0 | 0 | 8,477 | none named | 10,624 | +2,147 | +207 |

After column: remeasured 2026-10-29 on branch `chore/context-diet-v2` with the same method (the method reproduces the baseline numbers exactly on 39d908d). Root `CLAUDE.md` grew from 7,271 to 9,211 bytes on master between the baseline and this PR (#175, #176, #178, #179); this PR adds 207 bytes to it (design and visual-web jobs in the Quality gate). "vs master before this PR" isolates this PR's effect.

| File | Baseline bytes | Master before this PR | After |
|---|---|---|---|
| `backend/CLAUDE.md` (351 lines) | 12,261 | 12,261 | 3,719 (38 lines) |
| `shared/CLAUDE.md` (333 lines) | 7,575 | 7,575 | deleted |
| `infrastructure/CLAUDE.md` (127 lines) | 5,810 | 5,810 | 5,125 (89 lines) |

## MCP servers that fail at session start

| Server | Error |
|---|---|
| fetch | CONNECTION_CLOSED: Connection closed |
| plugin:context7:context7 | invalid_target: OAuthError dialing https://mcp.context7.com/mcp |

## Open PRs

| Open PRs | Oldest age | Median age |
|---|---|---|
| 0 | - | - |

## Merges per week

Count of first-parent commits on master, ISO weeks, last 8 weeks to 2026-10-29.

| ISO week | Merges |
|---|---|
| 2026-W37 | 5 |
| 2026-W38 | 0 |
| 2026-W39 | 0 |
| 2026-W40 | 0 |
| 2026-W41 | 0 |
| 2026-W42 | 0 |
| 2026-W43 | 0 |
| 2026-W44 | 19 |
| Total | 24 |

## After: remeasured 2026-10-29

| Measure | Baseline | After |
|---|---|---|
| Skills loaded, never invoked | 22 | 22 (no change; out of scope) |
| claude.ai synced skills never invoked | 17 | 17 |
| Plugin skills never invoked | 1 | 1 |
| Plugins unused | 3 | 3 |
| `.claude/settings.json` ignored `Write(path)` rules | 5 | 5 |
| MCP servers failing at start | fetch, context7 | fetch, context7 |
| Open PRs | 0 | 1 (#182, not this branch) |
| Merges, ISO week 2026-W44 | 19 | 27 (master moved on; weeks W38-W43 still 0) |

Skills, MCP and PR rows are unchanged by design: this PR touches cards and one skill example file only.

## After follow-up (chore/context-diet-v3)

The done check for S08 needs a backend dispatch at least 9 KB lighter than baseline and no card over 80 lines. The first PR (#183) fell short on both: 31,247 bytes and `infrastructure/CLAUDE.md` at 88 lines.

| Measure | Baseline | After #183 | After this PR |
|---|---|---|---|
| backend-implementer start bytes | 37,642 | 31,247 | 28,599 (-9,043 vs baseline) |
| `backend-patterns` skill bytes | 13,007 | 13,007 | 10,359 |
| `infrastructure/CLAUDE.md` lines | 127 | 88 | 69 |
| Longest card in lines | 351 (backend) | 88 (infrastructure) | 80 (root `CLAUDE.md`) |

Removed from the skill because a card or generic Kotlin already says it: Null Handling, Cross-Module Communication, the annotation table, the framework list, the Testcontainers prose and Boot 4 package names, Kotest and MockK snippets, the Swagger URL block, the test commands. Removed from the infrastructure card: the folder tree (`ls` shows it).
