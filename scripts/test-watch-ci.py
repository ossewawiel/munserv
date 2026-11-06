#!/usr/bin/env python3
"""Tests for scripts/watch-ci.sh against a stub `gh` and a stub `sleep`.

The stub `gh` answers from a JSON fixture and applies --jq with the real jq. Each entry in a run's
`views` list answers one `gh run view --json` call that asks for status, and the last entry repeats.
`heads`, `prs` and `listings` work the same way for `gh pr view` and `gh run list`. An entry can
also be "gh-failure" (the call exits 1), "gh-hang" (the call blocks until it is killed), or
slow(entry) (the call takes real time, then answers with that entry).
The stub `sleep` returns at once, so the time limits count polls and the tests take no real time.
Only the gh-hang and slow() tests wait in real time.

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
import json, os, subprocess, sys, time
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

def next_entry(holder, key):
    index = holder.get(key + "_calls", 0)
    holder[key + "_calls"] = index + 1
    state_path.write_text(json.dumps(state))
    entry = holder[key][min(index, len(holder[key]) - 1)]
    if isinstance(entry, dict) and "gh-delay" in entry:
        time.sleep(entry["gh-delay"])
        entry = entry["then"]
    if entry == "gh-failure":
        sys.stderr.write("HTTP 502\n")
        sys.exit(1)
    if entry == "gh-hang":
        time.sleep(600)
    return entry

if args[:2] == ["pr", "view"]:
    fields = args[args.index("--json") + 1].split(",")
    if "state" in fields:
        out({"headRefOid": "abc1234567", **next_entry(state, "prs")})
    out(next_entry(state, "heads"))
if args[:2] == ["run", "list"]:
    out([{"databaseId": int(i)} for i in next_entry(state, "listings")])
if args[:2] == ["run", "view"]:
    run = state["runs"][args[2]]
    if "--log-failed" in args:
        if run["views"][-1]["status"] != "completed":
            sys.stderr.write(f"run {args[2]} is still in progress; logs will be available when it is complete\n")
            sys.exit(1)
        print(f"log tail of {args[2]}")
        sys.exit(0)
    fields = args[args.index("--json") + 1]
    if "status" not in fields:
        out(run["views"][-1])
    out(next_entry(run, "views"))
if args[:1] == ["api"] and args[1].endswith("/logs"):
    print("log of job " + args[1].split("/")[-2])
    sys.exit(0)
sys.stderr.write("unexpected gh call: " + " ".join(args) + "\n")
sys.exit(9)
"""


def job(name: str, conclusion: str = "success", status: str = "completed", job_id: int = 1) -> dict:
    return {"name": name, "status": status, "conclusion": conclusion, "databaseId": job_id}


ALL_PASSED = [job("Web (React)"), job("Smoke (master)", "skipped"), job("CI status")]
ONE_FAILED = [job("Web (React)", "failure", job_id=55), job("CI status", "failure", job_id=56)]
MERGED_PR = {"state": "MERGED", "mergeStateStatus": "CLEAN", "autoMergeRequest": None, "statusCheckRollup": []}
HEAD = {"headRefOid": "abc1234567", "headRefName": "feat/x"}
NEW_HEAD = {"headRefOid": "def7654321", "headRefName": "feat/x"}


def view(jobs: list[dict], status: str = "completed", conclusion: str = "success", event: str = "push") -> dict:
    return {"event": event, "status": status, "conclusion": conclusion, "jobs": jobs}


def stuck(jobs: list[dict], event: str = "push") -> dict:
    """What the API returned for run 42065926402 on #297: all jobs done, the run itself not."""
    return view(jobs, status="in_progress", conclusion="", event=event)


def slow(entry: object) -> dict:
    """A gh call that takes more than a second of real time, then answers with this entry."""
    return {"gh-delay": 1.1, "then": entry}


def open_pr(merge_state: str = "BLOCKED", armed: bool = True, **fields: object) -> dict:
    return {"state": "OPEN", "mergeStateStatus": merge_state, "autoMergeRequest": {"m": 1} if armed else None,
            "statusCheckRollup": [], **fields}


RUNNING = view([job("Web (React)", "", "in_progress")], status="in_progress", conclusion="")


def watch(views: list | None = None, pr: dict | None = None, *, runs: dict | None = None, heads: list | None = None,
          prs: list | None = None, listings: list | None = None, env: dict | None = None) -> tuple[int, str]:
    """Runs the watcher and returns its exit code and stdout. Every CI line belongs on stdout."""
    all_runs = runs if runs is not None else {"101": views}
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        state = {
            "heads": heads or [HEAD],
            "prs": prs or [pr or MERGED_PR],
            "listings": listings or [list(all_runs)],
            "runs": {run_id: {"views": v} for run_id, v in all_runs.items()},
        }
        (d / "state.json").write_text(json.dumps(state))
        for name, body in (("gh", STUB_GH), ("sleep", "#!/usr/bin/env bash\nexit 0\n")):
            path = d / name
            path.write_text(body)
            path.chmod(path.stat().st_mode | stat.S_IEXEC)
        full_env = {**os.environ, "PATH": f"{d}{os.pathsep}{os.environ['PATH']}", "STUB_STATE": str(d / "state.json"),
                    **(env or {})}
        r = subprocess.run([str(SCRIPT), "7"], capture_output=True, text=True, env=full_env, timeout=120)
        return r.returncode, r.stdout


def last_line(out: str) -> str:
    return out.strip().splitlines()[-1] if out.strip() else ""


class Finished(unittest.TestCase):
    def test_green_run_ends_merged(self):
        code, out = watch([view(ALL_PASSED)])
        self.assertEqual(code, 0, out)
        self.assertEqual(last_line(out), "CI: green, merged")

    def test_red_run_prints_the_log_and_exits_1(self):
        code, out = watch([view(ONE_FAILED, conclusion="failure")])
        self.assertEqual(code, 1, out)
        self.assertIn("log tail of 101", out)
        self.assertTrue(last_line(out).startswith("CI: red"), out)

    def test_cancelled_run_is_red(self):
        code, out = watch([view(ALL_PASSED, conclusion="cancelled")])
        self.assertEqual(code, 1, out)

    def test_waits_through_a_running_run(self):
        code, out = watch([RUNNING, RUNNING, view(ALL_PASSED)])
        self.assertEqual(code, 0, out)

    def test_pull_request_run_with_no_jobs_is_skipped(self):
        code, out = watch([view([], conclusion="startup_failure", event="pull_request")])
        self.assertEqual(code, 0, out)
        self.assertIn("skipped", out)


class SeveralRuns(unittest.TestCase):
    """The shape of #217: a label cancelled the pull_request run, and a newer one passed."""

    CANCELLED_PR = view(ALL_PASSED, conclusion="cancelled", event="pull_request")
    GREEN_PR = view(ALL_PASSED, event="pull_request")
    GREEN_PUSH = view(ALL_PASSED)

    def test_cancelled_run_with_a_newer_green_run_is_not_red(self):
        code, out = watch(runs={"103": [self.GREEN_PR], "102": [self.CANCELLED_PR], "101": [self.GREEN_PUSH]})
        self.assertEqual(code, 0, out)
        self.assertEqual(last_line(out), "CI: green, merged")
        self.assertIn("run 102: cancelled", out)

    def test_the_answer_does_not_depend_on_the_order_runs_are_listed(self):
        code, out = watch(runs={"101": [self.GREEN_PUSH], "102": [self.CANCELLED_PR], "103": [self.GREEN_PR]})
        self.assertEqual(code, 0, out)

    def test_the_newest_run_of_an_event_cancelled_is_red(self):
        code, out = watch(runs={"102": [self.CANCELLED_PR], "101": [self.GREEN_PUSH]})
        self.assertEqual(code, 1, out)
        self.assertTrue(last_line(out).startswith("CI: red"), out)

    def test_a_newer_run_of_another_event_does_not_excuse_a_cancelled_run(self):
        code, out = watch(runs={"102": [self.GREEN_PUSH], "101": [self.CANCELLED_PR]})
        self.assertEqual(code, 1, out)

    def test_a_push_run_cancelled_by_a_newer_dispatch_run_is_not_red(self):
        # Both events run in one concurrency group, so either can cancel the other.
        dispatch = view(ALL_PASSED, event="workflow_dispatch")
        code, out = watch(runs={"102": [dispatch], "101": [view(ALL_PASSED, conclusion="cancelled")]})
        self.assertEqual(code, 0, out)
        self.assertIn("run 101: cancelled; newer run 102", out)

    def test_a_dispatch_run_cancelled_by_a_newer_push_run_is_not_red(self):
        dispatch = view(ALL_PASSED, conclusion="cancelled", event="workflow_dispatch")
        code, out = watch(runs={"102": [self.GREEN_PUSH], "101": [dispatch]})
        self.assertEqual(code, 0, out)

    def test_the_newest_of_a_push_and_a_dispatch_cancelled_is_red(self):
        dispatch = view(ALL_PASSED, conclusion="cancelled", event="workflow_dispatch")
        code, out = watch(runs={"102": [dispatch], "101": [self.GREEN_PUSH]})
        self.assertEqual(code, 1, out)

    def test_a_failed_run_stays_red_when_a_newer_run_passes(self):
        failed = view(ONE_FAILED, conclusion="failure", event="pull_request")
        code, out = watch(runs={"102": [self.GREEN_PR], "101": [failed]})
        self.assertEqual(code, 1, out)

    def test_a_run_that_appears_late_is_still_watched(self):
        failed = view(ONE_FAILED, conclusion="failure", event="pull_request")
        code, out = watch(runs={"102": [failed], "101": [self.GREEN_PUSH]},
                          listings=[["101"], ["101"], ["102", "101"]])
        self.assertEqual(code, 1, out)

    def test_a_known_red_run_outlives_a_later_run_that_never_ends(self):
        failed = view(ONE_FAILED, conclusion="failure")
        code, out = watch(runs={"101": [failed], "102": [RUNNING]})
        self.assertEqual(code, 1, out)
        self.assertTrue(last_line(out).startswith("CI: red"), out)


class ListingFailures(unittest.TestCase):
    def test_a_failed_listing_is_not_an_empty_one(self):
        red = view(ONE_FAILED, conclusion="failure")
        code, out = watch([red], listings=[["101"], "gh-failure", ["101"]])
        self.assertEqual(code, 1, out)
        self.assertNotIn("CI: green", out)

    def test_a_failed_listing_does_not_pass_a_running_run(self):
        code, out = watch([RUNNING, view(ALL_PASSED)], listings=[["101"], "gh-failure", "gh-failure", ["101"]])
        self.assertEqual(code, 0, out)
        self.assertIn("Web (React)", out)

    def test_an_empty_listing_after_runs_appeared_does_not_pass_a_red_run(self):
        red = view(ONE_FAILED, conclusion="failure")
        code, out = watch([red], listings=[["101"], [], ["101"]])
        self.assertEqual(code, 1, out)
        self.assertNotIn("CI: green", out)

    def test_listing_failing_for_good_is_not_finished(self):
        code, out = watch([view(ALL_PASSED)], listings=[["101"], "gh-failure"])
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - cannot list"), out)

    def test_listing_failing_after_a_red_run_stays_red(self):
        red = view(ONE_FAILED, conclusion="failure")
        code, out = watch([red], listings=[["101"], ["101"], "gh-failure"])
        self.assertEqual(code, 1, out)
        self.assertTrue(last_line(out).startswith("CI: red"), out)

    def test_no_run_appearing_is_not_finished_on_stdout(self):
        code, out = watch(runs={}, listings=[[]])
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - no CI run"), out)
        self.assertNotIn("CI: red", out)

    def test_listing_failing_from_the_start_is_not_finished_on_stdout(self):
        code, out = watch(runs={}, listings=["gh-failure"])
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - cannot list CI runs"), out)

    def test_one_good_listing_with_no_runs_says_no_run(self):
        code, out = watch(runs={}, listings=["gh-failure", [], "gh-failure"])
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - no CI run"), out)


class PrFailures(unittest.TestCase):
    def test_a_failed_first_pr_read_is_retried(self):
        code, out = watch([view(ALL_PASSED)], heads=["gh-failure", HEAD])
        self.assertEqual(code, 0, out)

    def test_pr_read_failing_for_good_is_not_finished(self):
        code, out = watch([view(ALL_PASSED)], heads=["gh-failure"])
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - cannot read PR 7"), out)

    def test_a_failed_read_in_the_merge_phase_is_retried(self):
        code, out = watch([view(ALL_PASSED)], prs=["gh-failure", MERGED_PR])
        self.assertEqual(code, 0, out)
        self.assertEqual(last_line(out), "CI: green, merged")

    def test_merge_phase_reads_failing_for_good_end_with_an_exit_3_line(self):
        code, out = watch([view(ALL_PASSED)], prs=["gh-failure"])
        self.assertEqual(code, 3, out)
        self.assertTrue(last_line(out).startswith("CI: green, not merging - cannot read the PR"), out)


class HeadMoved(unittest.TestCase):
    def test_a_cancelled_run_on_a_superseded_commit_is_not_red(self):
        code, out = watch([view(ALL_PASSED, conclusion="cancelled")], heads=[HEAD, NEW_HEAD])
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - head moved to def7654"), out)
        self.assertNotIn("CI: red", out)

    def test_a_green_run_on_a_superseded_commit_is_not_green(self):
        code, out = watch([view(ALL_PASSED)], heads=[HEAD, NEW_HEAD])
        self.assertEqual(code, 2, out)
        self.assertNotIn("CI: green", out)

    def test_a_blip_on_the_head_read_does_not_change_the_answer(self):
        code, out = watch([view(ALL_PASSED)], heads=[HEAD, "gh-failure", HEAD])
        self.assertEqual(code, 0, out)

    def test_head_reads_failing_for_good_leave_the_verdict_standing(self):
        code, out = watch([view(ALL_PASSED)], heads=[HEAD, "gh-failure"])
        self.assertEqual(code, 0, out)
        self.assertEqual(last_line(out), "CI: green, merged")


class BlockedGh(unittest.TestCase):
    """A call that never returns must not stop the watcher. These wait in real time, for GH_TIMEOUT."""

    FAST = {"GH_TIMEOUT": "1", "CI_APPEAR_TIMEOUT": "1", "RUN_TIMEOUT": "1", "MERGE_TIMEOUT": "1"}

    def test_a_blocked_pr_read_ends(self):
        code, out = watch([view(ALL_PASSED)], heads=["gh-hang"], env=self.FAST)
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - cannot read PR"), out)

    def test_a_blocked_run_read_ends(self):
        code, out = watch(["gh-hang"], env=self.FAST)
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - run 101"), out)

    def test_a_blocked_read_in_the_merge_phase_ends(self):
        code, out = watch([view(ALL_PASSED)], prs=["gh-hang"], env=self.FAST)
        self.assertEqual(code, 3, out)


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

    def test_a_judged_red_run_prints_the_log_of_its_failed_jobs(self):
        # `gh run view --log-failed` refuses a run that says in_progress, so it needs the job logs.
        code, out = watch([stuck(ONE_FAILED)])
        self.assertEqual(code, 1, out)
        self.assertIn("log of job 55", out)
        self.assertIn("log of job 56", out)

    def test_a_cancelled_or_timed_out_job_is_red(self):
        for bad in ("cancelled", "timed_out"):
            with self.subTest(bad):
                code, out = watch([stuck([job("Web (React)", bad), job("CI status")])])
                self.assertEqual(code, 1, out)

    CANCELLED_JOBS = [job("Web (React)"), job("Mobile (Flutter)", "cancelled", job_id=57),
                      job("CI status", "failure", job_id=58)]

    def test_a_stuck_cancelled_run_with_a_newer_green_run_is_not_red(self):
        # `CI status` fails when a job is cancelled, so the run is cancelled and not failed.
        code, out = watch(runs={"103": [view(ALL_PASSED, event="pull_request")],
                                "102": [stuck(self.CANCELLED_JOBS, event="pull_request")],
                                "101": [view(ALL_PASSED)]})
        self.assertEqual(code, 0, out)
        self.assertIn("run 102: cancelled; newer run 103", out)

    def test_a_stuck_cancelled_run_that_is_the_newest_is_red_with_its_job_logs(self):
        code, out = watch(runs={"102": [stuck(self.CANCELLED_JOBS, event="pull_request")], "101": [view(ALL_PASSED)]})
        self.assertEqual(code, 1, out)
        self.assertIn("log of job 57", out)

    def test_a_failed_job_next_to_a_cancelled_one_stays_red(self):
        jobs = [job("Web (React)", "failure"), job("Mobile (Flutter)", "cancelled"), job("CI status", "failure")]
        code, out = watch(runs={"103": [view(ALL_PASSED, event="pull_request")],
                                "102": [stuck(jobs, event="pull_request")], "101": [view(ALL_PASSED)]})
        self.assertEqual(code, 1, out)

    def test_a_failed_gate_job_alone_stays_red(self):
        jobs = [job("Web (React)"), job("CI status", "failure")]
        code, out = watch(runs={"103": [view(ALL_PASSED, event="pull_request")],
                                "102": [stuck(jobs, event="pull_request")], "101": [view(ALL_PASSED)]})
        self.assertEqual(code, 1, out)

    def test_late_real_conclusion_wins_over_the_jobs(self):
        code, out = watch([stuck(ALL_PASSED), view(ALL_PASSED, conclusion="failure")])
        self.assertEqual(code, 1, out)
        self.assertNotIn("judging it from the jobs", out)

    def test_never_finishing_run_ends_at_the_limit_and_names_the_run(self):
        code, out = watch([RUNNING])
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
        code, out = watch([stuck(ALL_PASSED)] * 4 + [running] + [stuck(ALL_PASSED)] * 4 + [view(ALL_PASSED)])
        self.assertEqual(code, 0, out)
        self.assertNotIn("judging it from the jobs", out)

    def test_a_running_job_blocks_the_verdict(self):
        running = view([job("CI status"), job("Web (React)", "", "in_progress")], status="in_progress", conclusion="")
        code, out = watch([running] * 10 + [view(ALL_PASSED)])
        self.assertEqual(code, 0, out)
        self.assertNotIn("judging it from the jobs", out)

    def test_four_stuck_polls_are_not_yet_a_verdict(self):
        # Four polls 30 seconds apart do not pass the 120-second settle wait.
        code, out = watch([stuck(ALL_PASSED)] * 4 + [view(ALL_PASSED, conclusion="failure")])
        self.assertEqual(code, 1, out)
        self.assertNotIn("judging it from the jobs", out)

    def test_the_fifth_stuck_poll_is_the_verdict(self):
        code, out = watch([stuck(ALL_PASSED)] * 5 + [view(ALL_PASSED, conclusion="failure")])
        self.assertEqual(code, 0, out)
        self.assertIn("judging it from the jobs", out)


class TimeAccounting(unittest.TestCase):
    """A slow gh call uses up the limit. In each test the watcher sees the good answer only if it does
    not add the time the calls took. These wait in real time, about two seconds each."""

    def test_the_head_read_wait_counts_the_call(self):
        code, out = watch([view(ALL_PASSED)], heads=[slow("gh-failure"), slow("gh-failure"), HEAD],
                          env={"CI_APPEAR_TIMEOUT": "21"})
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - cannot read PR"), out)

    def test_the_appear_wait_counts_the_call(self):
        code, out = watch([view(ALL_PASSED)], listings=[slow([]), slow([]), ["101"]], env={"CI_APPEAR_TIMEOUT": "11"})
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - no CI run"), out)

    def test_the_listing_wait_counts_the_call(self):
        code, out = watch([view(ALL_PASSED)], listings=[["101"], slow("gh-failure"), slow("gh-failure"), ["101"]],
                          env={"CI_APPEAR_TIMEOUT": "21"})
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - cannot list"), out)

    def test_the_run_wait_counts_the_call(self):
        code, out = watch([slow(RUNNING), slow(RUNNING), view(ALL_PASSED)], env={"RUN_TIMEOUT": "61"})
        self.assertEqual(code, 2, out)
        self.assertTrue(last_line(out).startswith("CI: not finished - run 101"), out)

    def test_the_merge_wait_counts_a_read_of_an_open_pr(self):
        code, out = watch([view(ALL_PASSED)], prs=[slow(open_pr()), slow(open_pr()), open_pr(), MERGED_PR],
                          env={"MERGE_TIMEOUT": "11"})
        self.assertEqual(code, 3, out)
        self.assertIn("still OPEN", last_line(out))

    def test_the_merge_wait_counts_a_failed_read(self):
        code, out = watch([view(ALL_PASSED)], prs=[slow("gh-failure"), slow("gh-failure"), "gh-failure", MERGED_PR],
                          env={"MERGE_TIMEOUT": "11"})
        self.assertEqual(code, 3, out)
        self.assertIn("cannot read the PR", last_line(out))


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

    def test_an_infra_hold_names_the_reviewer_and_not_the_owner(self):
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [{"name": "Infra review guard", "conclusion": "FAILURE"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertIn("held by infra review guard; dispatch the reviewer agent", last_line(out))
        self.assertNotIn("ci-edit-approved", out)

    def test_a_baseline_hold_names_the_design_reviewer(self):
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [{"name": "Baseline guard", "conclusion": "FAILURE"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertIn("held by baseline guard; a design-reviewer APPROVE on a ui: true story, or the owner", last_line(out))

    def test_the_owner_goes_last_when_a_baseline_also_holds(self):
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [{"name": "CI edit guard", "conclusion": "FAILURE"},
                                    {"name": "Baseline guard", "conclusion": "FAILURE"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertIn("held by baseline guard", last_line(out))

    def test_the_reviewer_goes_before_the_owner_when_both_guards_hold(self):
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [{"name": "CI edit guard", "conclusion": "FAILURE"},
                                    {"name": "Infra review guard", "conclusion": "FAILURE"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertIn("held by infra review guard", last_line(out))

    def test_a_guard_still_running_does_not_shift_the_other_guard(self):
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [{"name": "CI edit guard", "conclusion": ""},
                                    {"name": "Infra review guard", "conclusion": "FAILURE"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertIn("held by infra review guard", last_line(out))

    def test_a_guard_release_listed_before_the_old_hold_is_a_release(self):
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [
                  {"name": "Infra review guard", "conclusion": "SUCCESS", "startedAt": "2026-11-06T10:05:00Z"},
                  {"name": "Infra review guard", "conclusion": "FAILURE", "startedAt": "2026-11-06T10:00:00Z"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertNotIn("held by", out)

    def test_a_queued_guard_run_is_not_read_as_the_old_hold(self):
        # gh prints the zero time for a time GitHub has not set yet.
        pr = {"state": "OPEN", "mergeStateStatus": "BLOCKED", "autoMergeRequest": {"m": 1},
              "statusCheckRollup": [
                  {"name": "Infra review guard", "conclusion": "FAILURE", "startedAt": "2026-11-06T10:00:00Z"},
                  {"name": "Infra review guard", "conclusion": "", "startedAt": "0001-01-01T00:00:00Z"}]}
        code, out = watch([view(ALL_PASSED)], pr=pr)
        self.assertEqual(code, 3, out)
        self.assertNotIn("held by", out)

    def test_conflicts_name_the_rebase(self):
        code, out = watch([view(ALL_PASSED)], pr=open_pr("DIRTY"))
        self.assertEqual(code, 3, out)
        self.assertEqual(last_line(out), "CI: green, not merging - conflicts with master; rebase onto origin/master and push")

    def test_behind_names_the_rebase(self):
        code, out = watch([view(ALL_PASSED)], pr=open_pr("BEHIND"))
        self.assertEqual(code, 3, out)
        self.assertEqual(last_line(out), "CI: green, not merging - branch is behind master; rebase onto origin/master and push")

    def test_a_closed_pr_uses_the_not_merging_form(self):
        code, out = watch([view(ALL_PASSED)], pr=open_pr("CLEAN", state="CLOSED"))
        self.assertEqual(code, 3, out)
        self.assertEqual(last_line(out), "CI: green, not merging - the PR is closed")

    def test_auto_merge_not_armed_names_the_command(self):
        code, out = watch([view(ALL_PASSED)], pr=open_pr("CLEAN", armed=False))
        self.assertEqual(code, 3, out)
        self.assertEqual(last_line(out),
                         "CI: green, not merging - auto-merge is not armed (mergeStateStatus CLEAN); arm it with gh pr merge 7 --auto --squash")

    def test_auto_merge_armed_late_is_not_a_hold(self):
        # auto-pr.yml can arm auto-merge after the watcher starts its merge phase.
        code, out = watch([view(ALL_PASSED)], prs=[open_pr("CLEAN", armed=False), MERGED_PR])
        self.assertEqual(code, 0, out)

    def test_still_open_at_the_limit_uses_the_not_merging_form(self):
        code, out = watch([view(ALL_PASSED)], pr=open_pr())
        self.assertEqual(code, 3, out)
        self.assertEqual(last_line(out),
                         "CI: green, not merging - still OPEN after 90s (mergeStateStatus BLOCKED, auto-merge armed: true)")

    def test_a_push_in_the_merge_phase_gives_no_verdict(self):
        moved = open_pr(headRefOid=NEW_HEAD["headRefOid"])
        code, out = watch([view(ALL_PASSED)], prs=[open_pr(), moved])
        self.assertEqual(code, 2, out)
        self.assertEqual(last_line(out), "CI: not finished - head moved to def7654; watch again")

    def test_a_push_is_read_before_a_guard_on_the_old_commit(self):
        moved = open_pr(headRefOid=NEW_HEAD["headRefOid"],
                        statusCheckRollup=[{"name": "CI edit guard", "conclusion": "FAILURE"}])
        code, out = watch([view(ALL_PASSED)], pr=moved)
        self.assertEqual(code, 2, out)
        self.assertNotIn("held by", out)

    def test_a_merged_pr_is_merged_whatever_its_head(self):
        code, out = watch([view(ALL_PASSED)], pr={**MERGED_PR, "headRefOid": NEW_HEAD["headRefOid"]})
        self.assertEqual(code, 0, out)
        self.assertEqual(last_line(out), "CI: green, merged")


if __name__ == "__main__":
    unittest.main()
