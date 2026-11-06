#!/usr/bin/env python3
"""Tests for the `CI status` job in .github/workflows/ci.yml: run its step with each job result.

This test reads the script out of the YAML and fills in the `needs` results as GitHub does, so it
tests the same text that GitHub runs. `CI status` is the required check, so a job it does not read
can fail with the check still green (#306).

Usage: python3 scripts/test-ci-status.py
"""
from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CI = yaml.safe_load((ROOT / ".github" / "workflows" / "ci.yml").read_text())
JOB = CI["jobs"]["ci-status"]
SCRIPT = JOB["steps"][0]["run"]
NEEDS = JOB["needs"]
RESULT = re.compile(r"\$\{\{\s*needs\.([\w-]+)\.result\s*\}\}")
# These need `changes`, so GitHub skips them when it fails or when the paths did not change.
PLATFORMS = ("backend", "web", "visual-web", "mobile")


def evaluate(**results: str) -> tuple[int, str]:
    """Run the step with every job at success, except the results given (visual_web for visual-web)."""
    given = {k.replace("_", "-"): v for k, v in results.items()}
    unknown = set(given) - set(NEEDS)
    if unknown:
        raise ValueError(f"not in needs: {unknown}")
    script = RESULT.sub(lambda m: given.get(m.group(1), "success"), SCRIPT)
    if "${{" in script:
        raise ValueError(f"an expression this test cannot fill in: {script}")
    # GitHub runs a step with `bash -e`.
    r = subprocess.run(["bash", "-e", "-c", script], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


class Evaluate(unittest.TestCase):
    def test_every_job_passing_passes(self):
        code, out = evaluate()
        self.assertEqual(code, 0, out)

    def test_platform_jobs_skipped_on_a_docs_change_pass(self):
        code, out = evaluate(**{p.replace("-", "_"): "skipped" for p in PLATFORMS})
        self.assertEqual(code, 0, out)

    def test_detect_changes_failing_fails_with_every_platform_job_skipped(self):
        # The #306 shape, from run 42208370538 on #305.
        code, out = evaluate(changes="failure", **{p.replace("-", "_"): "skipped" for p in PLATFORMS})
        self.assertEqual(code, 1, out)
        self.assertIn("Detect changes", out)

    def test_detect_changes_must_be_success(self):
        for result in ("cancelled", "skipped", ""):
            with self.subTest(result):
                code, out = evaluate(changes=result)
                self.assertEqual(code, 1, out)

    def test_each_job_in_needs_failing_fails(self):
        for job in NEEDS:
            for result in ("failure", "cancelled"):
                with self.subTest(job=job, result=result):
                    code, out = evaluate(**{job.replace("-", "_"): result})
                    self.assertEqual(code, 1, out)


class JobShape(unittest.TestCase):
    def test_every_job_is_in_needs_except_smoke(self):
        # Smoke runs after the merge on master and never gates a PR.
        self.assertEqual(set(NEEDS), set(CI["jobs"]) - {"ci-status", "smoke"})

    def test_runs_when_a_job_it_needs_fails(self):
        # Without always(), a failed job skips this one, and a skipped job counts as passed.
        self.assertEqual(JOB["if"], "always()")

    def test_name_is_the_required_check(self):
        self.assertEqual(JOB["name"], "CI status")


if __name__ == "__main__":
    unittest.main()
