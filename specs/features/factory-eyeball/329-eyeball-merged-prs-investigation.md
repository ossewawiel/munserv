# Investigation: the console never offers a factory PR for eyeball

Issue: #329 · Investigated 2026-11-20 · Platform: infra · Fix handoff: `329-FIX329-eyeball-merged-prs-infra.md`

## Problem
The Eyeball section of the factory console (web and TUI) lists only open PRs that carry a `story:` label. No factory PR has had that label since `auto-pr.yml` started opening PRs on 2026-10-28. Auto-merge also lands each PR minutes after green CI, and the list drops a PR once it merges. So the console has had no way to record an eyeball for any `ui` or `user_facing` story for three weeks.

On 2026-11-20 the owner set up PR #328 with `scripts/eyeball-up.sh`. The script checked out master, because the PR had merged. The console list then showed two rows: PR #235 (a fixture from 2026-11-02) and the smoke checklist. Neither #325 nor #328 was there to tick or submit.

## Evidence

### What the owner's submit hit
The submit never reached the console. Every route to a submit writes a results file first, and no such file exists.
- The web section saves on every Pass or Fail click (`ui/sections/eyeball.js:99-106`, `/api/eyeball/save`). The TUI saves on every mark and again before submit (`scripts/tui/eyeball.py:285-296`, `:340-345`).
- `/api/eyeball/save` (`server.py:321-324`) writes `<checkout>/.console/results/<id>.json` for any valid id. It does not check that the candidate exists.
- The running console (systemd unit `munserv-console`, PID started 2026-11-19 14:41) tests the checkout `/home/ossewawiel/Work/munserv-console`. Its newest results file is `pr-235.json`, written 2026-11-02. No `.console/results/*.json` newer than 2026-11-19 exists anywhere under the home directory.
- `curl localhost:3999/api/eyeball/candidates` today returns `pr-235` and `smoke` only.
- The checkout `munserv-console` sits detached at `e42c573`, the merge commit of #328. That matches `ensure.pr_branch` (`ensure.py:118-126`), which resolves a merged PR to its base branch (#161).
- The `eyeball:pass` labels and comments now on #325 and #328 came from the owner's login at 13:49Z, by hand: "Eyeball: pass (E1, E2), run by the owner; the console could not list this PR because it had already merged". The console did not write them.

### Timeline

| PR | Opened | Auto-merge armed | Merged | Reviewer verdict | Labels while open |
|---|---|---|---|---|---|
| #325 (#55, B14) | 13:04:25Z | 13:04:28Z | 13:14:14Z | 13:17:20Z | none |
| #328 (#327, FIX327) | 13:38:14Z | 13:38:16Z | 13:43:00Z | 13:44:25Z | none |

Issue #55 has `story:B14`. Issue #327 has no `story:` label at all: the investigator's Mode B handoff does not create one.

### Scope since 2026-10-28
116 PRs merged after `auto-pr.yml` landed (#158). None carries a `story:` label. Only #235 has one, added by hand. These merged PRs close an issue whose handoff has `ui: true` or `user_facing: true`, and none has an `eyeball:*` label from the console: #219 (M8), #220 (W31), #226 (W32), #252 and #259 (#169), #264 and #268 (#253), #325 (B14), #328 (FIX327).

## Steps taken
1. Read the issue, `scripts/console/eyeball.py`, `server.py`, `ensure.py`, `pipeline.py`, `inbox.py`, the web section `ui/sections/eyeball.js`, and the TUI `scripts/tui/eyeball.py` and `api.py`.
2. Read `.github/workflows/auto-pr.yml`, `hold-guard.yml`, the factory skill and root `CLAUDE.md` "The factory".
3. Read the PR timelines of #325 and #328 through the GitHub API, and the labels of issues #55 and #327.
4. Listed results files in every worktree and searched the home directory for recent ones.
5. Read the running console's unit, working directory and current candidate list (read-only GET).
6. Matched every `ui`/`user_facing` handoff to the PRs that name its issue.

## Root cause

### 1. Candidates need a label nobody applies
`build_candidates` (`scripts/console/eyeball.py:118-128`) lists `gh pr list --state open` and skips every PR without a `story:` label. The handoff lookup `find_handoff_path` (`:101-106`) also needs that story id. Before 2026-10-28 the factory opened PRs with labels. Now `auto-pr.yml:42-51` opens the PR on push with no labels, and nothing adds them later. The factory skill step 4 (`.claude/skills/factory/SKILL.md:32`) still says the orchestrator opens the PR, but the PR already exists by then. A PR that stays open is still invisible.

### 2. The list forgets a PR at merge
`auto-pr.yml:62` arms `--auto --squash --delete-branch` on every push. The required checks (`CI status`, `CI edit guard`, `Infra review guard`, `Baseline guard`, `Hold guard`) do not read the eyeball, so GitHub merges at green CI. `build_candidates` asks for `--state open` only, and reads the handoff from `origin/<head branch>`, which merge deletes. `ensure.pr_branch` was taught about merged PRs on the same day (#161), but the candidate list was not. The Inbox (`inbox.py:78`) and factory `status` (`SKILL.md:19`) also look at open PRs only, so nobody is told an eyeball is owed.

### Secondary: submit can report a label it did not apply
`submit` (`eyeball.py:377-383`) runs `gh pr comment` and `gh pr edit` with `check=False`. It records `last_submission.label` even when `gh` failed, and the dialog shows that label. This did not cause #329, because no submit ran. It would hide the next failure of the same kind.

## Affected components
- infra: `scripts/console/eyeball.py`, `scripts/console/config.py`, `scripts/console/ui/sections/eyeball.model.mjs`, `scripts/tui/eyeball.py`, `scripts/test-console.py`, `scripts/test-tui.py`, `.claude/skills/factory/SKILL.md`, root `CLAUDE.md`, `scripts/console/README.md`.
- backend, web, mobile: none.

## Options

### Option 1: list merged PRs
The console also lists PRs merged in the last N days whose handoff is `ui` or `user_facing` and that have no `eyeball:*` label. The eyeball runs against master, which `ensure` already checks out. Submit comments and labels the merged PR, and a failed check files a `source:eyeball` bug, as today.
- Pros: matches the accepted post-merge pattern for review (`SKILL.md:35`, `source:review`). Touches no guarded file. The factory tick keeps flowing.
- Cons: the eyeball audits; it does not block. A bad change reaches master and the showcase first.
- Afterwards you would notice: #325-style rows marked "Merged, awaiting eyeball", and failures arriving as `source:eyeball` bugs in the queue.

### Option 2: an eyeball guard
A new required check, like `hold-guard.yml`, fails while a PR's handoff is `ui` or `user_facing` and the PR has no `eyeball:pass`.
- Pros: the gate gates. The reviewer verdict also lands before merge for those PRs.
- Cons: changes `.github/workflows/` and `ci.yml` (for its test), so it needs an infra reviewer `APPROVE` and the owner's `ci-edit-approved`. The owner must add the check to branch protection; `guard-git.sh` stops agents doing that. Unattended ticks stack open PRs that wait for a person and drift behind master. A rebase push needs a rule on whether `eyeball:pass` survives. It does not fix the console: without option 3 the held PR is still not listed.
- Afterwards you would notice: user-facing PRs open for hours or days with `Eyeball guard` red.

### Option 3: find candidates by handoff
Resolve the handoff from the PR's closing issue (`closingIssuesReferences`, file names start with the zero-padded issue number), with the `story:` label as a fallback.
- This is not an alternative. Options 1 and 2 both need it, because no PR carries the label.

## Recommended fix
Options 1 and 3 together, in one infra story. It repairs the observed failure end to end, needs no guarded file, and keeps the post-merge model the factory already runs for review. Add the secondary submit fix, because it is three lines and it is the "records nothing" symptom. Option 2 stays an owner decision; if chosen, it becomes a second infra handoff that depends on this one.

## Risk
- `scripts/test-console.py` and `eyeball.model.test.mjs` do not run in CI. Only `scripts/test-tui.py` does. The handoff's Done when runs all three.
- An investigation record also starts with `<issue>-`. The lookup must take only files that end in `-<platform>.md`.
- One issue can have several platform handoffs. The lookup takes the first, by name, with `ui` or `user_facing` true.
- The console runs from the master checkout and loads code at start. After merge, `systemctl --user restart munserv-console` is needed.
- A window longer than 16 days surfaces the seven older PRs listed under "Scope". That is the owner's call.
- `.claude/skills/factory/SKILL.md` is under `.claude/`, which a headless run cannot write. The main session implements this story.
- Rewording root `CLAUDE.md` "Human gates" may change what plan steps say; the plan-upkeep rule then applies.
