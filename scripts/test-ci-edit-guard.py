#!/usr/bin/env python3
"""Tests for .github/workflows/ci-edit-guard.yml: run its step against a stub `gh`.

The workflow must stay inline, because it may not check out anything from the PR. This test reads
the script out of the YAML, so it tests the same text that GitHub runs.

Usage: python3 scripts/test-ci-edit-guard.py
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
WORKFLOW = yaml.safe_load((ROOT / ".github" / "workflows" / "ci-edit-guard.yml").read_text())
JOB = WORKFLOW["jobs"]["guard"]
SCRIPT = JOB["steps"][0]["run"]
LABEL = JOB["env"]["LABEL"]

STUB_GH = """#!/usr/bin/env bash
# Stub gh: answers from the fixture files in $STUB_DIR and logs every call.
printf '%s\\n' "$*" >> "$STUB_DIR/calls"
case "$*" in
  *"-X DELETE"*) exit 0 ;;
  *"/pulls/7/files"*) [ -f "$STUB_DIR/files_fail" ] && exit 1; cat "$STUB_DIR/files" ;;
  *"/pulls/7 "*) cat "$STUB_DIR/total" ;;
  *"/issues/7/labels"*) cat "$STUB_DIR/labels" ;;
  *) echo "unexpected gh call: $*" >&2; exit 9 ;;
esac
"""


def run_guard(files: list[tuple[str, str]], labels: tuple[str, ...] = (), action: str = "opened",
              total: int | None = None, files_fail: bool = False) -> tuple[int, str, str]:
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / "files").write_text("".join(f"{a}\t{b}\n" for a, b in files))
        (d / "total").write_text(f"{len(files) if total is None else total}\n")
        (d / "labels").write_text("".join(f"{x}\n" for x in labels))
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
            "LABEL": LABEL,
        }
        r = subprocess.run(["bash", "-c", SCRIPT], capture_output=True, text=True, env=env, cwd=d)
        return r.returncode, r.stdout + r.stderr, (d / "calls").read_text()


class GuardScript(unittest.TestCase):
    def test_pr_without_ci_edits_passes(self):
        code, out, _ = run_guard([("backend/a.kt", ""), ("scripts/x.py", "")])
        self.assertEqual(code, 0, out)

    def test_pr_with_no_files_passes(self):
        code, out, _ = run_guard([])
        self.assertEqual(code, 0, out)

    def test_workflow_edit_is_held_and_names_the_release_command(self):
        code, out, _ = run_guard([(".github/workflows/ci.yml", "")])
        self.assertEqual(code, 1, out)
        self.assertIn(f"gh pr edit 7 --add-label {LABEL}", out)

    def test_composite_action_edit_is_held(self):
        code, out, _ = run_guard([(".github/actions/setup/action.yml", "")])
        self.assertEqual(code, 1, out)

    def test_deleting_the_guard_is_held(self):
        code, out, _ = run_guard([(".github/workflows/ci-edit-guard.yml", "")])
        self.assertEqual(code, 1, out)

    def test_rename_out_of_the_folder_is_held(self):
        code, out, _ = run_guard([("docs/old-ci.yml", ".github/workflows/ci.yml")])
        self.assertEqual(code, 1, out)

    def test_other_github_files_pass(self):
        code, out, _ = run_guard([(".github/labels.yml", ""), ("web/.github/workflows/x.yml", "")])
        self.assertEqual(code, 0, out)

    def test_label_releases_on_the_labeled_event(self):
        code, out, calls = run_guard([(".github/workflows/ci.yml", "")], labels=(LABEL,), action="labeled")
        self.assertEqual(code, 0, out)
        self.assertNotIn("DELETE", calls)

    def test_a_label_with_a_longer_name_does_not_release(self):
        code, out, _ = run_guard([(".github/workflows/ci.yml", "")], labels=(f"not-{LABEL}",), action="labeled")
        self.assertEqual(code, 1, out)

    def test_push_after_release_removes_the_label_and_holds(self):
        code, out, calls = run_guard([(".github/workflows/ci.yml", "")], labels=(LABEL,), action="synchronize")
        self.assertEqual(code, 1, out)
        self.assertIn(f"-X DELETE repos/o/r/issues/7/labels/{LABEL}", calls)

    def test_push_that_drops_the_ci_edit_passes_and_keeps_the_label(self):
        code, out, calls = run_guard([("backend/a.kt", "")], labels=(LABEL,), action="synchronize")
        self.assertEqual(code, 0, out)
        self.assertNotIn("DELETE", calls)

    def test_truncated_file_list_fails_closed(self):
        code, out, _ = run_guard([("backend/a.kt", "")], total=3500)
        self.assertEqual(code, 1, out)

    def test_api_failure_fails_closed(self):
        code, out, _ = run_guard([("backend/a.kt", "")], files_fail=True)
        self.assertNotEqual(code, 0, out)


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

    def test_job_name_matches_the_required_check(self):
        self.assertEqual(JOB["name"], "CI edit guard")


if __name__ == "__main__":
    unittest.main()
