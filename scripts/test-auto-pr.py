#!/usr/bin/env python3
"""Tests for .github/workflows/auto-pr.yml: run its step against stub `gh` and `git`.

The test reads the script out of the YAML, so it tests the same text that GitHub runs. The case it
exists for: a draft PR must stay unarmed and the run must pass (retro 2026-11-19, cluster 5), and
marking the draft ready must arm it.

Usage: python3 scripts/test-auto-pr.py
"""
from __future__ import annotations

import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
WORKFLOW = yaml.safe_load((ROOT / ".github" / "workflows" / "auto-pr.yml").read_text())
JOB = WORKFLOW["jobs"]["open-pr"]
STEP = next(s for s in JOB["steps"] if "run" in s)
SCRIPT = STEP["run"]

# Each gh call is logged to $STUB_DIR/calls, one line per call.
STUB_GH = """#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls"
case "$1 $2" in
  # The real jq applies the workflow's own --jq filter to the fixture list.
  "pr list") jq_expr=""; while [ $# -gt 0 ]; do [ "$1" = "--jq" ] && jq_expr="$2"; shift; done
             jq -r "$jq_expr" "$STUB_DIR/prs" ;;
  "pr create") echo "https://github.com/o/r/pull/12" ;;
  "pr view") [ -f "$STUB_DIR/view_fail" ] && exit 1; cat "$STUB_DIR/draft" ;;
  "pr merge") [ -f "$STUB_DIR/merge_fail" ] && { echo "Pull request is a draft" >&2; exit 1; }; exit 0 ;;
  *) echo "unexpected gh call: $*" >&2; exit 9 ;;
esac
"""
STUB_GIT = """#!/usr/bin/env bash
case "$*" in
  "log -1 --format=%s") echo "chore(infra): a title" ;;
  log*) echo "- chore(infra): a title" ;;
  *) echo "unexpected git call: $*" >&2; exit 9 ;;
esac
"""


def own(n: int) -> dict:
    return {"number": n, "isCrossRepository": False}


def fork(n: int) -> dict:
    return {"number": n, "isCrossRepository": True}


def run_step(prs: list[dict] | None = None, draft: bool = False, view_fail: bool = False,
             merge_fail: bool = False) -> tuple[int, str, list[str]]:
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / "prs").write_text(json.dumps(prs or []))
        (d / "draft").write_text("true\n" if draft else "false\n")
        (d / "calls").write_text("")
        if view_fail:
            (d / "view_fail").write_text("")
        if merge_fail:
            (d / "merge_fail").write_text("")
        for name, body in (("gh", STUB_GH), ("git", STUB_GIT)):
            p = d / name
            p.write_text(body)
            p.chmod(p.stat().st_mode | stat.S_IEXEC)
        env = {**os.environ, "PATH": f"{d}{os.pathsep}{os.environ['PATH']}", "STUB_DIR": str(d),
               "BRANCH": "chore/x", "GH_TOKEN": "t"}
        r = subprocess.run(["bash", "-c", SCRIPT], capture_output=True, text=True, env=env, cwd=d)
        calls = [c for c in (d / "calls").read_text().splitlines() if c]
        return r.returncode, r.stdout + r.stderr, calls


def merges(calls: list[str]) -> list[str]:
    return [c for c in calls if c.startswith("pr merge")]


class Step(unittest.TestCase):
    def test_a_new_branch_gets_a_pr_and_auto_merge(self):
        code, out, calls = run_step()
        self.assertEqual(code, 0, out)
        self.assertTrue(any(c.startswith("pr create") for c in calls), calls)
        self.assertEqual(merges(calls), ["pr merge 12 --auto --squash --delete-branch"])

    def test_an_open_pr_is_armed_again(self):
        code, out, calls = run_step([own(5)])
        self.assertEqual(code, 0, out)
        self.assertFalse(any(c.startswith("pr create") for c in calls), calls)
        self.assertEqual(merges(calls), ["pr merge 5 --auto --squash --delete-branch"])

    def test_a_draft_stays_unarmed_and_the_run_passes(self):
        code, out, calls = run_step([own(5)], draft=True)
        self.assertEqual(code, 0, out)
        self.assertEqual(merges(calls), [], calls)
        self.assertIn("draft", out)
        self.assertIn("ready", out)

    def test_the_draft_check_comes_before_any_merge_call(self):
        # The #312 failure: gh refused to arm the draft and the run went red.
        code, out, calls = run_step([own(5)], draft=True, merge_fail=True)
        self.assertEqual(code, 0, out)

    def test_an_unreadable_draft_flag_fails_the_run(self):
        code, out, calls = run_step([own(5)], view_fail=True)
        self.assertNotEqual(code, 0, out)
        self.assertEqual(merges(calls), [], calls)

    def test_a_failed_arm_still_fails_the_run(self):
        code, out, calls = run_step([own(5)], merge_fail=True)
        self.assertNotEqual(code, 0, out)

    def test_a_fork_pr_with_the_same_branch_name_is_never_armed(self):
        # PR #315 review B1: --head matches the branch name alone, newest first.
        code, out, calls = run_step([fork(9), own(5)])
        self.assertEqual(code, 0, out)
        self.assertEqual(merges(calls), ["pr merge 5 --auto --squash --delete-branch"])

    def test_only_a_fork_pr_open_means_this_branch_gets_its_own(self):
        code, out, calls = run_step([fork(9)])
        self.assertEqual(code, 0, out)
        self.assertTrue(any(c.startswith("pr create") for c in calls), calls)
        self.assertEqual(merges(calls), ["pr merge 12 --auto --squash --delete-branch"])


class WorkflowShape(unittest.TestCase):
    def test_marking_a_draft_ready_runs_it(self):
        trigger = WORKFLOW[True]  # PyYAML reads the bare key `on` as True.
        self.assertEqual(trigger["pull_request"], {"types": ["ready_for_review"]})
        self.assertIn("master", trigger["push"]["branches-ignore"])

    def test_the_branch_comes_from_the_pr_on_a_pr_event(self):
        # On a pull_request event github.ref_name is "<n>/merge", not the branch.
        self.assertEqual(STEP["env"]["BRANCH"], "${{ github.head_ref || github.ref_name }}")
        self.assertIn("github.head_ref", WORKFLOW["concurrency"]["group"])

    def test_a_fork_pr_is_never_armed(self):
        self.assertIn("github.event.pull_request.head.repo.full_name == github.repository", JOB["if"])
        self.assertIn("github.event_name == 'push'", JOB["if"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
