# Factory retro 2026-11-19: the bob-core cutover

A one-change retro for PR #312, which handed the implementers' stop gate from `.claude/hooks/verify-platform.sh` to bob-core (prject-bob ADR-0029). Window: the PR's life, 2026-11-17 13:22 to 2026-11-19 14:27 UTC. Run on demand in a session. This note does not move `specs/metrics/last-retro`, so the Monday retro still covers everything since 2026-11-09, this PR included.

## What changed
- The three implementer cards lost their frontmatter `Stop` hook. bob-core's `SubagentStop` hook now holds them, configured in `.bob/factory.json`: an `agents` map to pack names, one gate per pack (a `command` for Linux and macOS and a `commandWindows` for cmd.exe), and the `BLOCKED:` hand-back marker.
- `scripts/factory-tick.sh` refreshes and updates bob-core before each tick and records its version (`kind: bob`). It stops when bob-core is missing, disabled or below `BOB_MIN_VERSION` (0.3.0), or when `node` is not on PATH.
- `/factory` checks the same before its first implementer dispatch (`.claude/skills/factory/SKILL.md` step 3).
- `.claude/settings.json` denies `Edit` and `Write` on `**/.bob/**/*.json`.
- `verify-platform.sh` and its CI cases stay for rollback. They go after the canary verdict.

## Evidence

| Section | Count |
|---|---|
| Commits | 3: 9e0a8b6 (the cutover), 70e29e8 (tick tests), 11230cc (review fixes) |
| Reviewer verdicts | 2: REQUEST CHANGES on 70e29e8 (5 blocking, 1 should-fix), APPROVE on 11230cc |
| Red CI runs | 2 on 9e0a8b6: CI run 44092116062 (tick tests 10/21), Auto PR run 44092103108 (draft PR) |
| Guard holds | 3 Infra review guard holds, one per head, by design |
| Merge | 0d10d91, 23 s after the APPROVE review (14:26:37 to 14:27:00) |

## Clusters

**1. The gate moved into a plugin, and nothing checked that the plugin runs (3 findings: B2, B3, B5).**
- Findings:
  - B2: with no `node` on the systemd unit's PATH, bob-core's hook exits 127. Claude Code treats that as a non-blocking error, so every implementer finishes ungated, with no log line.
  - B3: bob-core 0.2.0 ignores `handback`, so every `BLOCKED:` hand-back would be gated as red.
  - B5: only the tick checked for bob-core. `/factory run` in a plain session on a machine without it dispatches ungated implementers. The Windows dev machine was one.
- Earliest check: the PR's design, against ADR-0028 Decision 6 (fail closed).
- Why it missed: fail-closed was designed inside the hook, for errors the hook can see. A hook that never starts sees nothing. The old gate came with the repo, so its presence never needed a check; bob-core is a separate install that can be missing, old or unable to start.
- Fix, tier 1 (script), landed in `scripts/factory-tick.sh`: stop on no `node` and below `BOB_MIN_VERSION`, compared with `sort -V`. Three cases in `scripts/test-factory-tick.py`: 0.2.0 stops the tick, 0.10.0 passes, no `node` stops the tick. The sandbox now carries a `node` stub, so the cases do not depend on the runner's own node.
- Fix, tier 3 (skill), landed in `.claude/skills/factory/SKILL.md` step 3: `claude plugin list --json` and `node --version` before the first implementer dispatch. Both exact commands are allowlisted, with the owner's approval, so headless tick runs can make the check.
- Gap: an implementer dispatched outside `/factory` and the tick still runs ungated on a machine without bob-core. See proposals.

**2. The gate's config left the write-protected folder (1 finding: B4).**
- Finding: bob-core reads `.bob/factory.json` from the agent's own worktree. The tick runs `--permission-mode acceptEdits`, which allows edits anywhere outside `.claude/`. An implementer stuck on red could set its gate to `true` and finish.
- Earliest check: the PR's design.
- Why it missed: the old gate lived under `.claude/hooks/`, which Claude Code refuses to write in headless runs. Moving the config to `.bob/` dropped that protection silently.
- Fix, tier 1 (permission rule), landed in `.claude/settings.json`: deny `Edit(**/.bob/**/*.json)` and `Write(**/.bob/**/*.json)`. Probed in a session: the rule refused writes to `.bob/factory.json` at the root and in a nested `.bob/`, as in an implementer's worktree. `.bob/README.md` stays editable.

**3. The gate commands were POSIX-only (1 finding: S1).**
- Finding: on win32, Node runs the gate through cmd.exe, so each stop gave one false red and then a let-go. `.bob/README.md` said the gates always run through `/bin/sh`.
- Earliest check: the PR's local check.
- Why it missed: it ran on Linux shapes only. bob-core 0.3.0 already supported `commandWindows`, but the manifest did not use it.
- Fix, tier 1 (config), landed in `.bob/factory.json`: one `commandWindows` per gate. The Windows web probe checks `pnpm`, not `mise`. Tested with Node `spawnSync(…, {shell: true})` on Windows:
  - a failed probe prints the BLOCKED line and exits 1;
  - `if not exist node_modules call …` skips or passes on the exit code;
  - a `&&` chain stops at the first failure;
  - the backend form reached `gradlew.bat`.

**4. A tick change was pushed with its tests red, and stayed red for two days (11 failing cases).**
- Source: CI run 44092116062 on 9e0a8b6 (2026-11-17), `test-factory-tick.py` 10/21. The stub `claude` did not know `claude plugin`. 70e29e8 fixed it on 2026-11-19.
- Earliest check: `python3 scripts/test-factory-tick.py` before the push. The PR body lists only `bash -n`.
- Why it missed: the tests need Linux (`flock`, `python3`, `jq`), and the Windows checkout runs none of them. The review-fix session found a way: a `python:3.12-slim` container with `jq git util-linux`, and `scripts/` plus `.claude/agents/` mounted read-only. It ran 28/28 in about a minute. Copying the whole checkout into the container stalled on `node_modules`.
- Fix, tier 1 (script), proposed: `scripts/test-in-container.sh <test script>`, wrapping that one-liner, and one line in `infrastructure/CLAUDE.md`.

**5. A PR cannot be held from merging (3 findings: B1, Auto PR run 44092103108, the body race).**
- Findings:
  - The body promised "Draft on purpose, auto-merge off". `auto-pr.yml` refused to arm the draft (run 44092103108, `Pull request is a draft (enablePullRequestAutoMerge)`): the 2026-11-09 retro's cluster 3, again. Once the PR was marked ready (2026-11-19 13:29:42), the next push armed auto-merge.
  - The APPROVE merged the PR 23 s later. The PR body was edited after the merge.
  - The merge came before the attended run that ADR-0029 Decision 7 puts ahead of the timer.
- Earliest check: the required checks on `master`.
- Why it missed: only the guards can hold a PR, and none holds on intent. A draft does not hold either: it breaks Auto PR.
- Fix, tier 1, proposed (it changes `.github/workflows/`, so it waits for the owner through CI edit guard):
  - a `hold` label that a required check honours, as Baseline guard does with `design-approved`;
  - `auto-pr.yml` skips arming a draft, instead of failing on it.
- Process rule until then: edit the PR body before dispatching a reviewer whose APPROVE releases the PR.

## Proposals not landed
- **A repo-local lock on ungated dispatch (cluster 1).** A `PreToolUse` hook on `Agent` that refuses an implementer dispatch when bob-core is not enabled at 0.3.0 or later. This closes the gap that the skill line leaves. It lands in `.claude/hooks/`, so it needs a reviewer pass.
- **`scripts/test-in-container.sh` (cluster 4).**
- **A `hold` label and a draft-safe Auto PR (cluster 5).**
- **A CI check that every agent name in `.bob/factory.json` has a file in `.claude/agents/`.** The reviewer noted it on both passes.
- **A strict version floor.** `sort -V` lets `0.3.0-rc1` pass 0.3.0. Harmless while bob-core uses plain semver.

## Accepted
- **B4 residual.** An allowlisted Bash command can still escape the gate:
  - `git switch --detach` to a pre-manifest commit leaves a worktree with no manifest;
  - `pnpm exec node -e …` or a gradle task can write the file.

  This is the same exposure `verify-platform.sh` had: an implementer could edit the `package.json` scripts or `build.gradle.kts` that the gate runs. CI and the reviewer stay the backstop.
- **A stale reviewer brief.** The first brief cited ADR-0028's name-only matcher. ADR-0029 had replaced it in bob-core 0.2.0. The reviewer read prject-bob and corrected the brief. The reviewer reads the source, so no rule is needed.
- **`scripts/watch-ci.sh` from Git Bash on Windows.** It ended `CI: not finished - gh is not installed`, because `gh` is on the PowerShell PATH only. That is the correct exit. Prefixing the GitHub CLI folder to PATH ran it.
- **`--dry-run` updates bob-core and writes a `bob` ledger line.** It changes nothing the gate depends on.

## Still open
- **Is bob-core 0.3.0 or later, with `node`, on the tick's machine?** Not checked from here. Without them, every tick now stops, with the reason in the ledger.
- **None of the ADR-0029 Decision 7 test plan has run:**
  - one attended story each on backend, web and mobile;
  - a hand-back that stops at once;
  - a `bob` line in the ledger.

  No munserv implementer has yet been gated by bob-core. The evidence so far is bob-core's own proof suite (prject-bob `tests/bob-core/`) and the resolution checks on this manifest.
- **The timer.** Unless it is paused (`touch ~/.config/munserv-factory/pause`), the next tick on a machine with bob-core runs the new gate unattended, before the attended run.
- **The rollback copy.** `verify-platform.sh` and `.claude/hooks/tests/verify-platform-cases.sh` (still in CI) come out after the canary verdict.

## Spend
- Tick ledger: not read. It lives on the tick's machine (`~/.local/state/munserv-factory/ticks.jsonl`), not in this Windows session. The Monday retro picks it up.
- Two reviewer passes on Opus:
  - first pass: 123k tokens, 9.5 min;
  - second pass: 91k tokens, 10.7 min.
- The implementing session's own spend was not metered.

## Sizes

The delta is against `retro-2026-11-09.md`.

| File | Lines | Bytes | Delta bytes |
|---|---|---|---|
| `CLAUDE.md` | 79 | 15,777 | 0 |
| `backend/CLAUDE.md` | 37 | 4,348 | 0 |
| `database/CLAUDE.md` | 30 | 2,281 | 0 |
| `infrastructure/CLAUDE.md` | 79 | 6,054 | 0 |
| `mobile/CLAUDE.md` | 32 | 3,688 | 0 |
| `web/CLAUDE.md` | 30 | 3,720 | 0 |
| `.claude/agents/backend-implementer.md` | 38 | 3,076 | -159 |
| `.claude/agents/clerk.md` | 22 | 1,099 | 0 |
| `.claude/agents/design-reviewer.md` | 25 | 3,054 | 0 |
| `.claude/agents/designer.md` | 32 | 3,475 | 0 |
| `.claude/agents/feature-planner.md` | 47 | 6,033 | 0 |
| `.claude/agents/investigator.md` | 25 | 2,180 | 0 |
| `.claude/agents/mobile-implementer.md` | 39 | 3,589 | -158 |
| `.claude/agents/reviewer.md` | 35 | 3,683 | 0 |
| `.claude/agents/syncer.md` | 28 | 1,658 | 0 |
| `.claude/agents/web-implementer.md` | 40 | 3,300 | -155 |
| `.claude/skills/backend-patterns/SKILL.md` | 361 | 10,359 | 0 |
| `.claude/skills/database-patterns/SKILL.md` | 134 | 3,369 | 0 |
| `.claude/skills/factory/SKILL.md` | 67 | 12,620 | +936 (grew) |
| `.claude/skills/factory-retro/SKILL.md` | 63 | 6,702 | +43 (grew) |
| `.claude/skills/figure-it-out/SKILL.md` | 106 | 6,462 | new (#311, before this PR) |
| `.claude/skills/mobile-design-system/SKILL.md` | 295 | 9,619 | 0 |
| `.claude/skills/mobile-patterns/SKILL.md` | 409 | 10,204 | 0 |
| `.claude/skills/web-data-table/SKILL.md` | 117 | 3,534 | 0 |
| `.claude/skills/web-patterns/SKILL.md` | 473 | 12,062 | 0 |

The cutover took about 155 bytes out of each implementer card (their `Stop` hook block). `factory/SKILL.md` grew 8%, almost all of it the gate check in step 3. At 12,620 bytes it is now the largest skill, ahead of `web-patterns` (12,062), and the largest file the orchestrator loads after the root card.
