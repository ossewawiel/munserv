---
name: factory
description: Orchestrate MunServ story delivery - pick ready stories, dispatch platform implementers into worktrees, run the reviewer on finished branches, open PRs, and report. Run by the user from a normal session; never auto-invoked.
disable-model-invocation: true
argument-hint: "[run|status|story <id>|review <pr>|sync <pr>] [--max 3]"
allowed-tools: Bash(gh *) Bash(git *) Read Grep Glob Agent
---

# /factory

You are the orchestrator. You carry no domain knowledge and write no code. You read state from GitHub and `specs/features/`, dispatch agents, and report. Model tiering is fixed by the agent definitions: planning, investigation and review run on Opus; implementation and bookkeeping on Sonnet.

Arguments: `$ARGUMENTS` (default `run --max 3`).

## `status`
1. `gh issue list --state open --label status:ready --json number,title,labels,milestone` and the same for `status:in-progress`, `status:blocked`, `status:review`.
2. `gh pr list --state open --json number,title,headRefName,statusCheckRollup,reviewDecision`.
3. For each ready story, check whether a handoff exists: `specs/features/*/<issue>-*-<platform>.md` with `status: pending`.
Print one table: story, platform, state, handoff (yes / no), blockers (`depends_on` not yet merged), PR and CI state. Stop.

## `run [--max N]` (default 3)
1. Do `status`.
2. Select up to N stories that are `status:ready`, have a `pending` handoff, whose `depends_on` issues are closed, and whose `touches` folders do not overlap a story already in progress. Backend before web before mobile when a feature spans platforms. A ready story with no handoff is dispatched to `feature-planner` (Mode B) first and not implemented in this run.
   **Design stage.** A handoff with `ui: true` is dispatchable only when `design_approved: true`. If it has no `design_canvas`, dispatch `designer` for it (one call per feature, covering all its UI stories) and do not implement it this run. If it has a canvas but no approval, print the canvas link and stop for the user; when the user approves, set `design_approved: true` in the handoff (the one edit you may make), commit it on the story branch, and continue. "Approved with changes" means the designer re-runs with the user's notes first.
3. For each selected story, in parallel, one Agent call: `subagent_type` = `backend-implementer` / `web-implementer` / `mobile-implementer` by the handoff's `platform`; prompt = "Implement the story in `<handoff path>`." Label the issue `status:in-progress` before dispatch.
4. When an implementer returns:
   - `BLOCKED:` in its output → label `status:blocked`, comment the reason on the issue, stop that story.
   - Otherwise open the PR yourself: `gh pr create --head <branch> --title "<type>(<platform>): <story title> (#<issue>)" --body` with summary, `Closes #<issue>`, the handoff path and the commands that passed. Label the issue `status:review`.
5. Wait for CI (`gh pr checks <n> --watch`). Red → dispatch the same implementer once more with the failing job's log excerpt appended to the prompt. Red twice → label `status:blocked`, comment, stop.
6. Green → for `ui: true` stories dispatch `design-reviewer` first with the PR number and handoff path; its `REQUEST CHANGES` goes back to the implementer once like a code review. Then dispatch `reviewer` with the PR number and handoff path. `REQUEST CHANGES` → dispatch the implementer once with the review text; then review again. Second `REQUEST CHANGES` → `status:blocked`.
7. `APPROVE` → leave the PR for the user. Never merge.
8. `python3 scripts/sync-board.py` so the Project board reflects the labels you changed.
9. Report: one table (story, PR, CI, review, next action for the user) and the token-heavy step of each story if it stood out.

## `story <id|issue>`
Same as `run` for exactly that story, ignoring `--max`. If it has no handoff, run `feature-planner` Mode B first, then implement.

## `review <pr>`
Dispatch `reviewer` for that PR with its handoff path and print the verdict.

## `sync <pr>`
Dispatch `syncer` for a merged PR and print its report.

## Rules
- Never run platform builds or tests yourself; that is the implementers' job and their Stop hook enforces it.
- Never edit code, handoffs or specs yourself, except flipping `design_approved` after the user's word.
- Three concurrent implementers at most, whatever `--max` says.
- Every GitHub write you make is one of: add or remove a `status:*` label, an issue comment, `gh pr create`, and the board sync script. Nothing else.
- If `gh` is not authenticated or master is behind, say so and stop.
