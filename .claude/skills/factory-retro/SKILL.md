---
name: factory-retro
description: Weekly factory retro - read what the gates caught since the last retro, cluster the findings, ask why the earliest check missed each cluster, and land one rule change per cluster in a single PR. Run by the Monday tick or by the user; never auto-invoked.
disable-model-invocation: true
argument-hint: "[--since YYYY-MM-DD] [--dry-run]"
model: opus
effort: high
context: fork
allowed-tools: Bash(python3 scripts/retro-gather.py*) Bash(git *) Bash(gh *) Bash(scripts/watch-ci.sh *) Bash(wc *) Read Grep Glob Edit Write
---

# /factory-retro

You turn defects that a late gate caught into rules that an earlier gate enforces. A defect caught once should be refused by a rule the next time. You change factory rules only: hooks, lint and check scripts, skills, cards and agent definitions. Never product code under `backend/`, `web/src/`, `mobile/lib/` or `database/`.

Arguments: `$ARGUMENTS`. `--since` overrides `specs/metrics/last-retro`. `--dry-run` writes the report to stdout and opens nothing.

## 1. Gather
Run `python3 scripts/retro-gather.py [--since <date>]` in the checkout you started in, before you create the worktree: the tick ledger and cost meter data are not in git. It prints one Markdown document with these sections:
- reviewer and design-reviewer verdicts on merged PRs
- issues labelled `source:eyeball`, `source:review` and `source:smoke`
- red CI runs with their failed-log tails
- `BLOCKED:` reasons
- spend from the tick ledger and the cost meter
- card, agent and skill sizes

Read all of it. If it has no review finding, gate issue, red run or BLOCKED line, write the report with "No findings" and skip to step 5.

## 2. Cluster
A finding is one defect: a `REQUEST CHANGES` item, a non-blocking note a reviewer flagged as a pattern, a failed eyeball check, a red job that a local command would have caught, a BLOCKED reason. Ignore findings already fixed by a rule merged since (check `git log --since=<date> -- .claude scripts '*CLAUDE.md'`).

Group findings that share one cause, not one symptom. "Hardcoded colour in two web components" and "magic number in a Kotlin service" are one cluster if both slipped past the same missing lint. Name each cluster in one line, count its findings, and list the PRs, issues or run ids it came from. A cluster of one is fine when the defect is severe or cheap to prevent.

## 3. Ask why the earliest check missed it
The checks, earliest first: the agent's card and preloaded skill, the handoff, the PreToolUse hooks in `.claude/hooks/`, the stop gate (platform lint and tests before an implementer may finish), CI, the design-reviewer, the reviewer, the eyeball. For each cluster, name the earliest check that could have caught it and say in one sentence why it did not: the rule was missing, the rule existed but the agent never loaded it, the rule was too vague to apply, or the check cannot see that class of defect.

## 4. Propose one fix per cluster
Take the first option that works, in this order:
1. **Hook or lint rule.** A pattern a machine can match: an ESLint, ktlint, Detekt or analyzer rule; a check in `scripts/`; a case in a `.claude/hooks/` script with a test case in `scripts/test-hooks.py`. It refuses the defect whether or not an agent reads anything.
2. **Skill line.** A worked example in the platform skill the implementer preloads (`.claude/skills/*-patterns`, `mobile-design-system`, `web-data-table`).
3. **Card line.** One sentence in a platform card (`backend/CLAUDE.md` and siblings) or an agent definition in `.claude/agents/`, when every task on that platform needs it.
4. **Accept.** Too rare or too costly to prevent. Say why.

A line added to a skill or card replaces or tightens an existing line where it can. Do not restate what the code, a lint rule or a type already enforces. Land at most five changes per retro, the biggest clusters first; record the rest as proposals in the report.

## 5. Write and open one PR
1. Work in a worktree off the latest master, never in the starting checkout (the tick needs it on master):
   `git fetch origin && git worktree add .claude/worktrees/retro-<date> -b chore/factory-retro-<date> origin/master`.
   Make every edit inside that worktree.
   The tick runs you unattended, so a command outside `allowed-tools` is denied, not asked. Write paths relative to the starting checkout (`.claude/worktrees/retro-<date>/...`). Run commands in the worktree as `cd .claude/worktrees/retro-<date> && <command>`, with no absolute paths, no `git -C` and no `/tmp` files. Unattended, Claude Code refuses every write under the worktree's `.claude/`, and no rule or hook lifts that. Choose the tier as usual. A fix that lands in `.claude/skills`, `.claude/agents` or `.claude/hooks` goes in the PR body under "Proposals for a person", with the exact old and new lines. Lint, CI checks, `scripts/` and the platform cards land in the PR. Run by a person in a session, you may make the `.claude/` edits yourself.
2. Make the rule changes. Run the test or lint each one touches (`python3 scripts/test-hooks.py`, the platform lint) and fix it until it passes.
3. Write `specs/metrics/retro-<date>.md`:
   - the window (`since` to today) and the evidence counts per section
   - one block per cluster: name, count, sources, earliest check and why it missed, the fix and its tier, the file changed
   - proposals not landed, and accepted clusters with the reason
   - spend: ledger total, per story, runs that hit a cap, cost meter by agent and model
   - sizes: the table from the gather output, with a delta column against the previous `retro-*.md` (or `baseline-2026-11.md` the first time). Flag every card or skill that grew, and by how much.
4. Write today's date to `specs/metrics/last-retro`.
5. Commit with the title `chore(infra): factory retro <date>`. Push. `auto-pr.yml` opens the PR within a minute. Find it with `gh pr list --head chore/factory-retro-<date>` and set its title and body with `gh pr edit`. Use `gh pr create` only when no PR appears. The body lists the clusters, each with its fix, and ends with `Plan step: none`. Run `scripts/watch-ci.sh <n>` in the foreground with a 10-minute timeout. Never run it in the background or tail its output. Report its last line, and fix a red job on the same branch. When that line says the PR is held by CI edit guard, the PR changes CI files and waits for the owner: report the release command it prints and carry on with the next step.
6. Remove the worktree by its path: `git worktree remove .claude/worktrees/retro-<date>`.

## Report
Clusters found, fixes landed by tier, proposals left, sizes that grew, the PR link and the CI line.
