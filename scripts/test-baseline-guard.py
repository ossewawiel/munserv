#!/usr/bin/env python3
"""Tests for .github/workflows/baseline-guard.yml: run its step against a stub `gh`.

The workflow must stay inline, because it may not check out anything from the PR. This test reads
the script out of the YAML, so it tests the same text that GitHub runs. It also pins the parts of
ci.yml that would bring the #301 gap back.

Usage: python3 scripts/test-baseline-guard.py
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
WORKFLOW = yaml.safe_load((ROOT / ".github" / "workflows" / "baseline-guard.yml").read_text())
JOB = WORKFLOW["jobs"]["guard"]
SCRIPT = JOB["steps"][0]["run"]
LABEL = JOB["env"]["LABEL"]
CI_TEXT = (ROOT / ".github" / "workflows" / "ci.yml").read_text()
CI = yaml.safe_load(CI_TEXT)
WEB = ("web/e2e/visual/__screenshots__/button.png", "")
MOBILE = ("mobile/test/goldens/card_light.png", "")

STUB_GH = """#!/usr/bin/env bash
# Stub gh: answers from the fixture files in $STUB_DIR.
case "$*" in
  *"/pulls/7/files"*) [ -f "$STUB_DIR/files_fail" ] && exit 1; cat "$STUB_DIR/files" ;;
  *"/pulls/7 "*) cat "$STUB_DIR/total" ;;
  *"/issues/7/labels"*) cat "$STUB_DIR/labels" ;;
  *) echo "unexpected gh call: $*" >&2; exit 9 ;;
esac
"""


def run_guard(files: list[tuple[str, str]], labels: tuple[str, ...] = (), total: int | None = None,
              files_fail: bool = False) -> tuple[int, str]:
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / "files").write_text("".join(f"{a}\t{b}\n" for a, b in files))
        (d / "total").write_text(f"{len(files) if total is None else total}\n")
        (d / "labels").write_text("".join(f"{x}\n" for x in labels))
        if files_fail:
            (d / "files_fail").write_text("")
        gh = d / "gh"
        gh.write_text(STUB_GH)
        gh.chmod(gh.stat().st_mode | stat.S_IEXEC)
        env = {**os.environ, "PATH": f"{d}{os.pathsep}{os.environ['PATH']}", "STUB_DIR": str(d),
               "GITHUB_REPOSITORY": "o/r", "PR": "7", "LABEL": LABEL}
        r = subprocess.run(["bash", "-c", SCRIPT], capture_output=True, text=True, env=env, cwd=d)
        return r.returncode, r.stdout + r.stderr


class GuardScript(unittest.TestCase):
    def test_a_pr_without_baselines_passes(self):
        code, out = run_guard([("web/src/a.tsx", ""), ("mobile/lib/a.dart", "")])
        self.assertEqual(code, 0, out)

    def test_a_pr_with_no_files_passes(self):
        code, out = run_guard([])
        self.assertEqual(code, 0, out)

    def test_a_web_baseline_is_held_and_names_the_next_step(self):
        code, out = run_guard([WEB])
        self.assertEqual(code, 1, out)
        self.assertIn(f"gh pr edit 7 --add-label {LABEL}", out)

    def test_a_mobile_golden_is_held(self):
        code, out = run_guard([MOBILE])
        self.assertEqual(code, 1, out)

    def test_a_nested_mobile_golden_is_held(self):
        code, out = run_guard([("mobile/test/goldens/widgets/card.png", "")])
        self.assertEqual(code, 1, out)

    def test_the_label_approves_either_kind(self):
        for baseline in (WEB, MOBILE):
            with self.subTest(baseline[0]):
                code, out = run_guard([baseline], labels=(LABEL,))
                self.assertEqual(code, 0, out)

    def test_another_label_does_not_approve(self):
        # The #235 shape: a story label lands on the PR, and nothing approves the baseline.
        code, out = run_guard([WEB], labels=("story:S15", f"not-{LABEL}"))
        self.assertEqual(code, 1, out)

    def test_a_baseline_moved_away_is_held(self):
        code, out = run_guard([("web/old/button.png", WEB[0])])
        self.assertEqual(code, 1, out)

    def test_names_that_only_look_alike_pass(self):
        code, out = run_guard([("web/src/__screenshots__/a.png", ""), ("mobile/test/goldens/README.md", ""),
                               ("docs/web/e2e/visual/__screenshots__/a.png", "")])
        self.assertEqual(code, 0, out)

    def test_a_truncated_file_list_fails_closed(self):
        code, out = run_guard([("web/src/a.tsx", "")], total=3500)
        self.assertEqual(code, 1, out)

    def test_an_api_failure_fails_closed(self):
        code, out = run_guard([("web/src/a.tsx", "")], files_fail=True)
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

    def test_job_name_matches_what_the_watcher_reads(self):
        self.assertEqual(JOB["name"], "Baseline guard")
        self.assertIn(JOB["name"], (ROOT / "scripts" / "watch-ci.sh").read_text())


class CiStaysOutOfIt(unittest.TestCase):
    """What would bring the #301 gap back."""

    def test_a_label_starts_no_ci_run(self):
        # A label run cancels the running pull_request run through the concurrency group.
        self.assertNotIn("labeled", CI[True]["pull_request"]["types"])

    def test_ci_holds_no_label_gate(self):
        # A push run also reports `CI status`, has no such gate, and is enough for auto-merge.
        self.assertNotIn(LABEL, CI_TEXT)

    def test_the_visual_job_runs_whatever_the_event(self):
        self.assertEqual(CI["jobs"]["visual-web"]["if"], "needs.changes.outputs.web == 'true'")


if __name__ == "__main__":
    unittest.main()
