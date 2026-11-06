#!/usr/bin/env python3
"""Tests for .github/workflows/infra-review-guard.yml: run its step against a stub `gh`.

The workflow must stay inline, because it may not check out anything from the PR. This test reads
the script out of the YAML, so it tests the same text that GitHub runs.

Usage: python3 scripts/test-infra-review-guard.py
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
WORKFLOW = yaml.safe_load((ROOT / ".github" / "workflows" / "infra-review-guard.yml").read_text())
JOB = WORKFLOW["jobs"]["guard"]
SCRIPT = JOB["steps"][0]["run"]
LABEL = JOB["env"]["LABEL"]
SHA = "a" * 40
OLD_SHA = "b" * 40
WATCHER = ("scripts/watch-ci.sh", "")

STUB_GH = """#!/usr/bin/env bash
# Stub gh: answers from the fixture files in $STUB_DIR and logs every call.
printf '%s\\n' "$*" >> "$STUB_DIR/calls"
case "$*" in
  *"-X DELETE"*) exit 0 ;;
  *"/pulls/7/files"*) [ -f "$STUB_DIR/files_fail" ] && exit 1; cat "$STUB_DIR/files" ;;
  *"/pulls/7/reviews"*) cat "$STUB_DIR/reviews" ;;
  *"/pulls/7 "*) cat "$STUB_DIR/total" ;;
  *"/issues/7/labels"*) cat "$STUB_DIR/labels" ;;
  *) echo "unexpected gh call: $*" >&2; exit 9 ;;
esac
"""


def approve(sha: str = SHA) -> str:
    return f"Findings go here.\nReviewer verdict: APPROVE {sha}\n"


def changes(sha: str = SHA) -> str:
    return f"Reviewer verdict: REQUEST CHANGES {sha}\n"


def run_guard(files: list[tuple[str, str]], reviews: tuple[str, ...] = (), labels: tuple[str, ...] = (),
              action: str = "opened", total: int | None = None, files_fail: bool = False) -> tuple[int, str, str]:
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / "files").write_text("".join(f"{a}\t{b}\n" for a, b in files))
        (d / "total").write_text(f"{len(files) if total is None else total}\n")
        (d / "labels").write_text("".join(f"{x}\n" for x in labels))
        (d / "reviews").write_text("".join(reviews))
        (d / "calls").write_text("")
        if files_fail:
            (d / "files_fail").write_text("")
        gh = d / "gh"
        gh.write_text(STUB_GH)
        gh.chmod(gh.stat().st_mode | stat.S_IEXEC)
        env = {
            **os.environ,
            "PATH": f"{d}{os.pathsep}{os.environ['PATH']}",
            "STUB_DIR": str(d),
            "GITHUB_REPOSITORY": "o/r",
            "PR": "7",
            "EVENT_ACTION": action,
            "HEAD_SHA": SHA,
            "LABEL": LABEL,
        }
        r = subprocess.run(["bash", "-c", SCRIPT], capture_output=True, text=True, env=env, cwd=d)
        return r.returncode, r.stdout + r.stderr, (d / "calls").read_text()


class Paths(unittest.TestCase):
    def test_a_pr_without_infrastructure_edits_passes(self):
        code, out, _ = run_guard([("backend/a.kt", ""), ("scripts/console/x.py", "")])
        self.assertEqual(code, 0, out)

    def test_a_pr_with_no_files_passes(self):
        code, out, _ = run_guard([])
        self.assertEqual(code, 0, out)

    def test_each_listed_path_is_held(self):
        for path in ("scripts/watch-ci.sh", "scripts/factory-tick.sh", ".claude/hooks/guard-git.sh",
                     ".claude/hooks/tests/guard-git-cases.txt", ".github/workflows/ci.yml"):
            with self.subTest(path):
                code, out, _ = run_guard([(path, "")])
                self.assertEqual(code, 1, out)
                self.assertIn("Dispatch the reviewer agent", out)

    def test_a_rename_out_of_the_list_is_held(self):
        code, out, _ = run_guard([("scripts/old.sh", "scripts/watch-ci.sh")])
        self.assertEqual(code, 1, out)

    def test_names_that_only_look_alike_pass(self):
        code, out, _ = run_guard([("scripts/test-watch-ci.py", ""), ("web/.github/workflows/x.yml", ""),
                                  ("scripts/watch-ci.sh.bak", ""), ("docs/scripts/watch-ci.sh", "")])
        self.assertEqual(code, 0, out)

    def test_a_truncated_file_list_fails_closed(self):
        code, out, _ = run_guard([("backend/a.kt", "")], total=3500)
        self.assertEqual(code, 1, out)

    def test_an_api_failure_fails_closed(self):
        code, out, _ = run_guard([("backend/a.kt", "")], files_fail=True)
        self.assertNotEqual(code, 0, out)


class Verdicts(unittest.TestCase):
    def test_an_approve_on_the_head_commit_releases(self):
        code, out, _ = run_guard([WATCHER], reviews=(approve(),), labels=(LABEL,), action="labeled")
        self.assertEqual(code, 0, out)

    def test_the_verdict_releases_on_any_event(self):
        code, out, _ = run_guard([WATCHER], reviews=(approve(),), action="reopened")
        self.assertEqual(code, 0, out)

    def test_the_label_alone_releases_nothing(self):
        code, out, _ = run_guard([WATCHER], labels=(LABEL,), action="labeled")
        self.assertEqual(code, 1, out)

    def test_an_approve_on_an_older_commit_does_not_release(self):
        code, out, _ = run_guard([WATCHER], reviews=(approve(OLD_SHA),), labels=(LABEL,), action="labeled")
        self.assertEqual(code, 1, out)

    def test_request_changes_does_not_release(self):
        code, out, _ = run_guard([WATCHER], reviews=(changes(),))
        self.assertEqual(code, 1, out)

    def test_a_later_request_changes_withdraws_an_approve(self):
        code, out, _ = run_guard([WATCHER], reviews=(approve(), changes()))
        self.assertEqual(code, 1, out)

    def test_a_later_approve_replaces_request_changes(self):
        code, out, _ = run_guard([WATCHER], reviews=(changes(), approve()))
        self.assertEqual(code, 0, out)

    def test_the_verdict_must_be_alone_on_its_line(self):
        code, out, _ = run_guard([WATCHER], reviews=(f"Not a {approve().strip()} yet\n",))
        self.assertEqual(code, 1, out)

    def test_a_sha_with_more_text_does_not_release(self):
        code, out, _ = run_guard([WATCHER], reviews=(f"Reviewer verdict: APPROVE {SHA}0\n",))
        self.assertEqual(code, 1, out)

    def test_windows_line_ends_still_match(self):
        # GitHub can store a review body with CRLF line ends.
        code, out, _ = run_guard([WATCHER], reviews=(f"Done.\r\nReviewer verdict: APPROVE {SHA}\r\n",))
        self.assertEqual(code, 0, out)


class PushAfterReview(unittest.TestCase):
    def test_a_push_removes_the_label_so_the_next_review_can_add_it(self):
        code, out, calls = run_guard([WATCHER], reviews=(approve(OLD_SHA),), labels=(LABEL,), action="synchronize")
        self.assertEqual(code, 1, out)
        self.assertIn(f"-X DELETE repos/o/r/issues/7/labels/{LABEL}", calls)

    def test_a_push_with_no_label_deletes_nothing(self):
        code, out, calls = run_guard([WATCHER], action="synchronize")
        self.assertEqual(code, 1, out)
        self.assertNotIn("DELETE", calls)

    def test_a_push_that_drops_the_infrastructure_edit_passes(self):
        code, out, _ = run_guard([("backend/a.kt", "")], labels=(LABEL,), action="synchronize")
        self.assertEqual(code, 0, out)


class WorkflowShape(unittest.TestCase):
    """The rules that keep the guard honest; each one has a way to fail silently."""

    def test_runs_from_masters_copy_on_every_pr_change(self):
        # PyYAML reads the bare key `on` as the boolean True.
        trigger = WORKFLOW[True]
        self.assertEqual(list(trigger), ["pull_request_target"])
        self.assertEqual(trigger["pull_request_target"]["branches"], ["master"])
        self.assertEqual(set(trigger["pull_request_target"]["types"]),
                         {"opened", "synchronize", "reopened", "labeled", "unlabeled"})

    def test_no_path_filter(self):
        target = WORKFLOW[True]["pull_request_target"]
        self.assertFalse({"paths", "paths-ignore"} & set(target), "a required check that does not run blocks the merge")

    def test_job_cannot_be_skipped(self):
        self.assertNotIn("if", JOB, "a skipped job counts as passed")

    def test_runs_no_pr_code(self):
        steps = json.dumps(JOB["steps"])
        self.assertNotIn("checkout", steps)
        self.assertNotIn("uses", steps)
        self.assertNotIn("${{", SCRIPT, "PR text in an expression runs as shell")

    def test_job_name_matches_what_the_watcher_reads(self):
        self.assertEqual(JOB["name"], "Infra review guard")
        self.assertIn(JOB["name"], (ROOT / "scripts" / "watch-ci.sh").read_text())


if __name__ == "__main__":
    unittest.main()
