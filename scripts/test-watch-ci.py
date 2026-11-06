#!/usr/bin/env python3
"""Tests for scripts/watch-ci.sh against a stub `gh` and a stub `sleep`.

The stub `gh` answers from a JSON fixture and applies --jq with the real jq. Each entry in a run's
`views` list answers one `gh run view --json` call that asks for status, and the last entry repeats.
The stub `sleep` returns at once, so the time limits count polls and the tests take no real time.

Usage: python3 scripts/test-watch-ci.py
"""
from __future__ import annotations

import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts" / "watch-ci.sh"

STUB_GH = r"""#!/usr/bin/env python3
import json, os, subprocess, sys
from pathlib import Path

state_path = Path(os.environ["STUB_STATE"])
state = json.loads(state_path.read_text())
args = sys.argv[1:]

def out(value):
    if "--jq" in args:
        expr = args[args.index("--jq") + 1]
        result = subprocess.run(["jq", "-r", expr], input=json.dumps(value), capture_output=True, text=True)
        sys.stdout.write(result.stdout)
        sys.exit(result.returncode)
    sys.stdout.write(json.dumps(value))
    sys.exit(0)

if args[:2] == ["pr", "view"]:
    fields = args[args.index("--json") + 1]
    out(state["head"] if "headRefOid" in fields else state["pr"])
if args[:2] == ["run", "list"]:
    out([{"databaseId": int(i)} for i in state["runs"]])
if args[:2] == ["run", "view"]:
    run = state["runs"][args[2]]
    if "--log-failed" in args:
        print(f"log tail of {args[2]}")
        sys.exit(0)
    fields = args[args.index("--json") + 1]
    if "status" not in fields:
        out(run["views"][-1])
    index = run.get("calls", 0)
    run["calls"] = index + 1
    state_path.write_text(json.dumps(state))
    view = run["views"][min(index, len(run["views"]) - 1)]
    if view == "gh-failure":
        sys.exit(1)
    out(view)
sys.stderr.write("unexpected gh call: " + " ".join(args) + "\n")
sys.exit(9)
"""


def job(name: str, conclusion: str = "success", status: str = "completed") -> dict:
    return {"name": name, "status": status, "conclusion": conclusion}


ALL_PASSED = [job("Web (React)"), job("Smoke (master)", "skipped"), job("CI status")]
ONE_FAILED = [job("Web (React)", "failure"), job("CI status", "failure")]
MERGED_PR = {"state": "MERGED", "mergeStateStatus": "CLEAN", "autoMergeRequest": None, "statusCheckRollup": []}


def view(jobs: list[dict], status: str = "completed", conclusion: str = "success", event: str = "push") -> dict:
    return {"event": event, "status": status, "conclusion": conclusion, "jobs": jobs}


def stuck(jobs: list[dict]) -> dict:
    """What the API returned for run 42065926402 on #297: all jobs done, the run itself not."""
    return view(jobs, status="in_progress", conclusion="")


def watch(views: list, pr: dict | None = None) -> tuple[int, str]:
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        state = {
            "head": {"headRefOid": "abc1234567", "headRefName": "feat/x"},
            "pr": pr or MERGED_PR,
            "runs": {"101": {"views": views}},
        }
        (d / "state.json").write_text(json.dumps(state))
        for name, body in (("gh", STUB_GH), ("sleep", "#!/usr/bin/env bash\nexit 0\n")):
            path = d / name
            path.write_text(body)
            path.chmod(path.stat().st_mode | stat.S_IEXEC)
        env = {**os.environ, "PATH": f"{d}{os.pathsep}{os.environ['PATH']}", "STUB_STATE": str(d / "state.json")}
        r = subprocess.run([str(SCRIPT), "7"], capture_output=True, text=True, env=env, timeout=120)
        return r.returncode, r.stdout + r.stderr


class Finished(unittest.TestCase):
    def test_green_run_ends_merged(self):
        code, out = watch([view(ALL_PASSED)])
        self.assertEqual(code, 0, out)
        self.assertIn("CI: green, merged", out)

    def test_red_run_prints_the_log_and_exits_1(self):
        code, out = watch([view(ONE_FAILED, conclusion="failure")])
        self.assertEqual(code, 1, out)
        self.assertIn("log tail of 101", out)
        self.assertIn("CI: red", out)

    def test_cancelled_run_is_red(self):
        code, out = watch([view(ALL_PASSED, conclusion="cancelled")])
        self.assertEqual(code, 1, out)

    def test_waits_through_a_running_run(self):
        running = view([job("Web (React)", "", "in_progress")], status="in_progress", conclusion="")
        code, out = watch([running, running, view(ALL_PASSED)])
        self.assertEqual(code, 0, out)

    def test_pull_request_run_with_no_jobs_is_skipped(self):
        code, out = watch([view([], conclusion="startup_failure", event="pull_request")])
        self.assertEqual(code, 0, out)
        self.assertIn("skipped", out)


class StuckRun(unittest.TestCase):
    def test_all_jobs_passed_is_not_red(self):
        code, out = watch([stuck(ALL_PASSED)])
        self.assertEqual(code, 0, out)
        self.assertNotIn("CI: red", out)
        self.assertIn("judging it from the jobs", out)

    def test_a_failed_job_is_red(self):
        code, out = watch([stuck(ONE_FAILED)])
        self.assertEqual(code, 1, out)
        self.assertIn("CI: red", out)

    def test_a_cancelled_or_timed_out_job_is_red(self):
        for bad in ("cancelled", "timed_out"):
            with self.subTest(bad):
                code, out = watch([stuck([job("Web (React)", bad), job("CI status")])])
                self.assertEqual(code, 1, out)

    def test_late_real_conclusion_wins_over_the_jobs(self):
        code, out = watch([stuck(ALL_PASSED), view(ALL_PASSED, conclusion="failure")])
        self.assertEqual(code, 1, out)
        self.assertNotIn("judging it from the jobs", out)

    def test_never_finishing_run_ends_at_the_limit_and_names_the_run(self):
        running = view([job("Web (React)", "", "in_progress")], status="in_progress", conclusion="")
        code, out = watch([running])
        self.assertEqual(code, 2, out)
        self.assertIn("CI: not finished - run 101", out)
        self.assertNotIn("CI: red", out)

    def test_finished_jobs_without_the_gate_job_are_not_a_verdict(self):
        # Between phases of a run, every job GitHub lists has finished, but `CI status` is not listed yet.
        early = stuck([job("Detect changes")])
        code, out = watch([early])
        self.assertEqual(code, 2, out)
        self.assertNotIn("CI: green", out)

    def test_a_job_that_starts_later_resets_the_settle_wait(self):
        running = view([job("CI status"), job("Web (React)", "", "in_progress")], status="in_progress", conclusion="")
        code, out = watch([stuck(ALL_PASSED), running, stuck(ALL_PASSED), view(ALL_PASSED)])
        self.assertEqual(code, 0, out)
        self.assertNotIn("judging it from the jobs", out)


class GhFailures(unittest.TestCase):
    def test_a_failed_gh_call_does_not_end_the_watch(self):
        code, out = watch(["gh-failure", "gh-failure", view(ALL_PASSED)])
        self.assertEqual(code, 0, out)

    def test_gh_failing_for_good_ends_at_the_limit(self):
        code, out = watch(["gh-failure"])
        self.assertEqual(code, 2, out)
        self.assertIn("CI: not finished", out)


class MergePhase(unittest.TestCase):
    def test_a_held_pr_is_not_red(self):
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [{"name": "CI edit guard", "conclusion": "FAILURE"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertIn("held by CI edit guard", out)

    def test_a_release_after_a_hold_reads_the_newest_guard_run(self):
        pr = {"state": "MERGED", "mergeStateStatus": "CLEAN", "autoMergeRequest": None,
              "statusCheckRollup": [{"name": "CI edit guard", "conclusion": "FAILURE"},
                                    {"name": "CI edit guard", "conclusion": "SUCCESS"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 0, out)


if __name__ == "__main__":
    unittest.main()
