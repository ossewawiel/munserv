---
issue: 329
story: FIX329
title: "Eyeball lists merged user-facing PRs and finds their handoff by issue"
platform: infra
status: completed
depends_on: []
touches:
  - scripts/console
  - scripts/tui
  - scripts/test-console.py
  - scripts/test-tui.py
  - .claude/skills/factory
ui: false
user_facing: false
eyeball_exempt: []
design_canvas: ""
design_artboards: []
design_approved: false
created_by: investigator
created_at: "2026-11-20"
files_changed: [scripts/console/eyeball.py, scripts/console/config.py, scripts/console/project.yaml, scripts/console/README.md, scripts/console/ui/sections/eyeball.model.mjs, scripts/tui/eyeball.py, .claude/skills/factory/SKILL.md, CLAUDE.md]
tests_added: [scripts/test-console.py (ConfigDefaultsTests, IssueHandoffLookupTests, BuildCandidatesTests, SubmitGhFailureTests), scripts/test-tui.py (merged candidate), scripts/console/ui/sections/eyeball.model.test.mjs (merged stage)]
---

# FIX329 · Eyeball lists merged user-facing PRs and finds their handoff by issue (Infra)

Read `domain/README.md`. The main session implements this story: it edits `.claude/skills/`, which a headless run cannot write. Evidence: `329-eyeball-merged-prs-investigation.md` in this folder. No guarded file changes, so no `ci-edit-approved` is needed.

## Outcome
The owner can eyeball a `ui` or `user_facing` PR in the console after auto-merge has landed it, and the submit labels and comments on the merged PR.

## Acceptance criteria
- [ ] AC1 An open PR is a candidate when its closing issue has a `ui` or `user_facing` handoff, with or without a `story:` label. An open PR with a `story:` label stays a candidate, as today.
- [ ] AC2 A PR merged within `eyeball_merged_days` (project.yaml, default 14) is a candidate with stage `merged` when its handoff at the merge commit is `ui` or `user_facing` and the PR has no `eyeball:*` label. Its `branch` is the base branch, and its checks come from the handoff at the merge commit.
- [ ] AC3 The lookup takes only files named `<issue>-…-<platform>.md` (issue number with or without zero padding). An `-investigation.md` file never matches. With several, the first by name with `ui` or `user_facing` true wins.
- [ ] AC4 Submit on a merged candidate comments on and labels the merged PR, and files `source:eyeball` issues for failed checks. A merged PR leaves the list once it has an `eyeball:*` label.
- [ ] AC5 When `gh pr comment` or `gh pr edit` fails, submit answers 502 with the `gh` error text. The result never names a label that was not applied.
- [ ] AC6 Stage `merged` shows as "Merged, awaiting eyeball" in the web section and as "merged" in the TUI.
- [ ] AC7 The factory skill and root `CLAUDE.md` say that the eyeball of a merged PR runs from the console and records on the merged PR.

## Contract
Console API only. `GET /api/eyeball/candidates` keeps its shape. A PR candidate gains `"merged": bool`, and `stage` may be `"merged"`. A submit failure uses the existing `{"ok": false, "error": "<text>"}` from `ApiError`.

## Steps
1. `scripts/console/config.py`: add property `eyeball_merged_days` (int, default 14). Add `eyeball_merged_days: 14` to `scripts/console/project.yaml` and a row to the key table in `scripts/console/README.md`. Test: `test_eyeball_merged_days_defaults_to_14`.
2. `scripts/console/eyeball.py`: add the pure function `issue_handoff_names(names, issue) -> list[str]`. It keeps names whose base name matches `^0*<issue>-.+-(backend|web|mobile|infra)\.md$`, sorted. Add `find_handoff(ref, issues, story) -> tuple[str, str] | None`. It lists `git ls-tree -r --name-only <ref> -- <handoff_glob>` and tries each issue in turn. It returns the first name whose front matter has `ui` or `user_facing` true, with its text from `git show <ref>:<path>`. When no issue matches, it falls back to `match_handoff(names, story)`. Tests: `test_issue_lookup_ignores_investigation_records`, `test_issue_lookup_accepts_zero_padding`, `test_issue_lookup_skips_a_handoff_with_neither_flag`, `test_lookup_falls_back_to_story_label`.
3. `scripts/console/eyeball.py`, `build_candidates`: add `closingIssuesReferences` to the open-PR query. Move the dict built at lines 150-156 into `pr_candidate(pr, ref, branch, story, stage, merged)`. Open PR: ref `origin/<headRefName>`, kept when it has a `story:` label or `find_handoff` returns a flagged handoff. Then add one query: `gh pr list --state merged --search "merged:>=<today minus eyeball_merged_days>" --limit 100 --json number,title,baseRefName,labels,url,mergeCommit,closingIssuesReferences`. Skip a PR with an `eyeball:*` label. Use ref `mergeCommit.oid` and branch `baseRefName`, set `stage="merged"`, and take `story` from the handoff front matter. Keep a merged PR only when its handoff is flagged. Tests: `test_open_pr_without_story_label_is_found_by_closing_issue`, `test_merged_user_facing_pr_is_a_candidate`, `test_merged_pr_with_eyeball_label_is_not_listed`, `test_merged_pr_without_flag_is_not_listed`, `test_story_labelled_open_pr_is_still_listed`. Patch `eyeball.gh_json` and `eyeball.gh_run`.
4. `scripts/console/eyeball.py`, `submit` lines 376-383: read `returncode` from both `run_captured` calls. On a failure, raise `ApiError(f"gh pr {comment|edit} failed: {stderr}", 502)` before `last_submission` is written. Tests: `test_submit_raises_502_when_label_edit_fails`, `test_submit_raises_502_when_comment_fails`.
5. `scripts/console/ui/sections/eyeball.model.mjs`: add `merged: 'Merged, awaiting eyeball'` to `STAGE_LABELS` and `merged: 'accent'` to `STAGE_CLASSES`. Test in `eyeball.model.test.mjs`: `stageLabel('merged')`.
6. `scripts/tui/eyeball.py`: add `"merged": "merged"` to `STAGE_WORDS`. Test in `scripts/test-tui.py`: a stub candidate with `stage: "merged"` renders `merged` in the candidate list.
7. `.claude/skills/factory/SKILL.md`: in status step 2, a merged PR with a flagged handoff and no `eyeball:*` label is "awaiting eyeball"; read it from `GET /api/eyeball/candidates`. In run step 7, say that `scripts/eyeball-up.sh` works on a merged PR and the console lists it. In run step 4, say `auto-pr.yml` has already opened the PR: edit its title and body with `gh pr edit`.
8. Root `CLAUDE.md`, "The factory": change "eyeball pass" in the human-gates sentence so it says the eyeball records on the PR, after merge when auto-merge lands first. Add no new line.

## Do not
- Do not touch `.github/workflows/`, `.claude/hooks/` or `scripts/watch-ci.sh`. The eyeball guard (option 2 in the record) is a separate owner decision.
- Do not add `story:` labels in `auto-pr.yml`, and do not backfill labels on old PRs.
- Do not change `ensure.pr_branch`; it already checks out the base branch of a merged PR.
- Do not list merged PRs in the Inbox in this story.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
python3 scripts/test-console.py && python3 scripts/test-tui.py \
  && node --test scripts/console/ui/sections/eyeball.model.test.mjs \
  && python3 scripts/lint-handoffs.py --cards
```
After merge, restart the console on master: `systemctl --user restart munserv-console`. Then `curl -s localhost:3999/api/eyeball/candidates` answers without an error. Update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and summarise. If blocked, set `status: blocked` and end with `BLOCKED: <reason>`.
