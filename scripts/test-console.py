#!/usr/bin/env python3
"""Unit tests for scripts/console/*.py.

No network, no `gh`, no server: exercises the pure functions directly. Extends (does not replace)
the old scripts/test-eyeball.py test list -- the handoff-matching, request-safety and detached-
worktree tests carry over unchanged in spirit, now against the console package, plus new tests for
config defaults, service prepare detection and knowledge parsing.

Usage: python3 scripts/test-console.py
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from console import cost, ensure, eyeball, gitops, knowledge, mobile, network, remote, services, showcase  # noqa: E402
from console.config import Config  # noqa: E402
from console.pipeline import classify_pr  # noqa: E402
from console.server import Handler  # noqa: E402


def head_feature_names() -> list[str]:
    out = subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-tree", "-r", "--name-only", "HEAD", "--", "specs/features"],
        text=True,
    )
    return out.splitlines()


class MatchHandoffTests(unittest.TestCase):
    def test_finds_w29_in_the_real_tree(self):
        names = head_feature_names()
        path = eyeball.match_handoff(names, "W29")
        self.assertIsNotNone(path)
        self.assertTrue(path.endswith("044-W29-support-grant-login-web.md"), path)

    def test_finds_b9_in_the_real_tree(self):
        names = head_feature_names()
        path = eyeball.match_handoff(names, "B9")
        self.assertIsNotNone(path)
        self.assertTrue(path.endswith("068-B9-support-grant-login-backend.md"), path)

    def test_finds_a_mobile_story_by_the_same_convention(self):
        names = [
            "specs/features/pod-chief-bootstrap/completed/044-W29-support-grant-login-web.md",
            "specs/features/onboarding/003-M1-login-mobile.md",
            "specs/features/onboarding/002-M10-other-mobile.md",  # must not falsely match M1
        ]
        path = eyeball.match_handoff(names, "M1")
        self.assertEqual(path, "specs/features/onboarding/003-M1-login-mobile.md")

    def test_does_not_match_a_longer_story_id_as_a_prefix(self):
        names = ["specs/features/x/001-B10-admin-welcome-message-backend.md"]
        self.assertIsNone(eyeball.match_handoff(names, "B1"))

    def test_matches_legacy_naming_with_no_numeric_prefix(self):
        names = ["specs/features/pod-chief-bootstrap/completed/W25-backend-handoff.md"]
        self.assertEqual(eyeball.match_handoff(names, "W25"),
                          "specs/features/pod-chief-bootstrap/completed/W25-backend-handoff.md")

    def test_returns_none_when_nothing_matches(self):
        names = head_feature_names()
        self.assertIsNone(eyeball.match_handoff(names, "W9999"))


class EyeballBlockTests(unittest.TestCase):
    def test_parses_the_worked_example(self):
        text = Path(ROOT / "specs/features/pod-chief-bootstrap/completed/044-W29-support-grant-login-web.md").read_text()
        fm, body = eyeball.frontmatter_and_body(text)
        self.assertEqual(fm.get("story"), "W29")
        checks = eyeball.eyeball_block(body)
        ids = [c["id"] for c in checks]
        self.assertEqual(ids, ["E1", "E2", "E3"])

    def test_raises_on_malformed_yaml_rather_than_dropping_silently(self):
        body = "## Eyeball\n```yaml\nid: [this is not a list of checks\n```\n"
        with self.assertRaises(eyeball.EyeballParseError):
            eyeball.eyeball_block(body)

    def test_raises_when_block_is_not_a_list_of_dicts_with_id(self):
        body = "## Eyeball\n```yaml\n- not_an_id: oops\n```\n"
        with self.assertRaises(eyeball.EyeballParseError):
            eyeball.eyeball_block(body)

    def test_missing_block_returns_empty_list_not_an_error(self):
        self.assertEqual(eyeball.eyeball_block("no eyeball section here"), [])


class ValidateNameTests(unittest.TestCase):
    def test_accepts_a_pr_candidate_id(self):
        self.assertEqual(gitops.validate_name("pr-100", "candidate"), "pr-100")

    def test_accepts_the_smoke_candidate_id(self):
        self.assertEqual(gitops.validate_name("smoke", "candidate"), "smoke")

    def test_rejects_a_path_traversal_attempt(self):
        with self.assertRaises(gitops.ApiError):
            gitops.validate_name("../../etc/passwd", "candidate")

    def test_rejects_a_slash(self):
        with self.assertRaises(gitops.ApiError):
            gitops.validate_name("a/b", "service name")

    def test_rejects_empty(self):
        with self.assertRaises(gitops.ApiError):
            gitops.validate_name("", "candidate")

    def test_validate_branch_allows_slashes(self):
        self.assertEqual(gitops.validate_branch("feat/console-testing"), "feat/console-testing")

    def test_validate_branch_rejects_leading_dash(self):
        with self.assertRaises(gitops.ApiError):
            gitops.validate_branch("--upload-pack=evil")


class SubmitGuardTests(unittest.TestCase):
    def test_submit_refuses_when_nothing_is_ticked(self):
        candidate = {
            "id": "smoke", "kind": "smoke", "number": None, "story": "SMOKE", "platform": "web",
            "url": "", "checks": [{"id": "S1", "title": "t", "as": "none", "services": [],
                                    "url": "", "steps": [], "expect": "e"}],
        }
        data = {"candidate": "smoke", "checks": {}, "observations": []}
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(gitops.ApiError):
                eyeball.submit(candidate, data, Path(d))


class SubmitImprovementTests(unittest.TestCase):
    """A check ticked Pass, with a note, and "File as improvement" checked must file a
    `type:feature` issue on submit -- same title format and body shape as a failed check's
    `type:bug` issue, and the submission's per-check result and PR comment table must both carry
    an "improvement" marker."""

    def test_a_passing_check_marked_improvement_files_a_type_feature_issue(self):
        candidate = {
            "id": "smoke", "kind": "smoke", "number": None, "story": "SMOKE", "platform": "web",
            "url": "", "checks": [{"id": "S1", "title": "Some check", "as": "none", "services": [],
                                    "url": "", "steps": [], "expect": "e"}],
        }
        data = {
            "candidate": "smoke",
            "checks": {"S1": {"result": "pass", "note": "would make a nice shortcut",
                               "file_as_improvement": True, "issue_url": None}},
            "observations": [],
        }
        original_ensure_labels = eyeball.ensure_labels
        original_search = eyeball.search_open_issues
        original_run_captured = eyeball.run_captured
        eyeball.ensure_labels = lambda: None
        eyeball.search_open_issues = lambda prefix: []
        captured = {}

        class FakeResult:
            stdout = "https://github.com/x/y/issues/42\n"

        def fake_run_captured(args, cwd=None, check=True):
            captured["args"] = args
            return FakeResult()

        eyeball.run_captured = fake_run_captured
        try:
            with tempfile.TemporaryDirectory() as d:
                result = eyeball.submit(candidate, data, Path(d))
        finally:
            eyeball.ensure_labels = original_ensure_labels
            eyeball.search_open_issues = original_search
            eyeball.run_captured = original_run_captured

        self.assertEqual(result["checks"]["S1"]["issue_url"], "https://github.com/x/y/issues/42")
        self.assertFalse(result["checks"]["S1"]["issue_reused"])
        args = captured["args"]
        title = args[args.index("--title") + 1]
        self.assertEqual(title, "[Eyeball] SMOKE S1: Some check")
        body = args[args.index("--body") + 1]
        self.assertIn("would make a nice shortcut", body)
        self.assertTrue(any("type:feature" in a for a in args))
        self.assertFalse(any(a.startswith("type:bug") or ",type:bug" in a for a in args))

    def test_a_passing_check_without_the_improvement_flag_files_no_issue(self):
        candidate = {
            "id": "smoke", "kind": "smoke", "number": None, "story": "SMOKE", "platform": "web",
            "url": "", "checks": [{"id": "S1", "title": "Some check", "as": "none", "services": [],
                                    "url": "", "steps": [], "expect": "e"}],
        }
        data = {
            "candidate": "smoke",
            "checks": {"S1": {"result": "pass", "note": "worked fine", "issue_url": None}},
            "observations": [],
        }
        original_ensure_labels = eyeball.ensure_labels
        eyeball.ensure_labels = lambda: None
        try:
            with tempfile.TemporaryDirectory() as d:
                result = eyeball.submit(candidate, data, Path(d))
        finally:
            eyeball.ensure_labels = original_ensure_labels
        self.assertIsNone(result["checks"]["S1"].get("issue_url"))


class StartServiceGuardTests(unittest.TestCase):
    """Starting a service before anything has been checked out must fail with a 409 ApiError, not
    a raw FileNotFoundError from Popen."""

    def test_missing_checkout_dir_raises_409_not_a_traceback(self):
        original = services.services_config
        services.services_config = lambda: {
            "db": {"cwd": "infrastructure/docker", "start": "true", "health": "tcp:1"}
        }
        try:
            with tempfile.TemporaryDirectory() as d:
                checkout = Path(d) / "not-checked-out-yet"
                checkout.mkdir()
                with self.assertRaises(gitops.ApiError) as ctx:
                    services.start_service("db", checkout)
                self.assertEqual(ctx.exception.status, 409)
        finally:
            services.services_config = original

    def test_existing_cwd_is_not_blocked(self):
        original = services.services_config
        services.services_config = lambda: {"ok": {"cwd": ".", "start": "true", "health": "tcp:1"}}
        try:
            with tempfile.TemporaryDirectory() as d:
                checkout = Path(d)
                msg = services.start_service("ok", checkout)
                self.assertIn("starting", msg)
                services._processes["ok"].wait(timeout=5)
                services.stop_service("ok", checkout)
        finally:
            services.services_config = original


class PrepareTests(unittest.TestCase):
    def test_needed_when_marker_missing(self):
        original = services.services_config
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d)
            (checkout / "web").mkdir()
            services.services_config = lambda: {
                "web": {"cwd": "web", "start": "true", "health": "tcp:1",
                        "prepare": {"marker": "node_modules", "command": "true"}}
            }
            try:
                self.assertTrue(services.prepare_needed("web", checkout))
                (checkout / "web" / "node_modules").mkdir()
                self.assertFalse(services.prepare_needed("web", checkout))
            finally:
                services.services_config = original

    def test_needed_when_lockfile_newer_than_marker(self):
        original = services.services_config
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d)
            web = checkout / "web"
            web.mkdir()
            (web / "node_modules").mkdir()
            (web / "pnpm-lock.yaml").write_text("x", encoding="utf-8")
            import os
            import time as time_mod
            os.utime(web / "node_modules", (time_mod.time() - 100, time_mod.time() - 100))
            services.services_config = lambda: {
                "web": {"cwd": "web", "start": "true", "health": "tcp:1",
                        "prepare": {"marker": "node_modules", "newer_than": "pnpm-lock.yaml", "command": "true"}}
            }
            try:
                self.assertTrue(services.prepare_needed("web", checkout))
            finally:
                services.services_config = original

    def test_not_needed_without_a_prepare_block(self):
        original = services.services_config
        services.services_config = lambda: {"db": {"cwd": ".", "start": "true", "health": "tcp:1"}}
        try:
            with tempfile.TemporaryDirectory() as d:
                self.assertFalse(services.prepare_needed("db", Path(d)))
        finally:
            services.services_config = original

    def test_run_prepare_job_reaches_success(self):
        original = services.services_config
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d)
            (checkout / "svc").mkdir()
            services.services_config = lambda: {
                "svc": {"cwd": "svc", "start": "true", "health": "tcp:1", "prepare": {"command": "true"}}
            }
            try:
                job = services.start_prepare("svc", checkout)
                for _ in range(50):
                    jobs = {j["id"]: j for j in services.jobs_snapshot()}
                    if jobs[job["id"]]["status"] != "running":
                        break
                    import time as time_mod
                    time_mod.sleep(0.05)
                jobs = {j["id"]: j for j in services.jobs_snapshot()}
                self.assertEqual(jobs[job["id"]]["status"], "success")
            finally:
                services.services_config = original


class DetachedWorktreeTests(unittest.TestCase):
    """The console checkout must never claim a branch name: factory agents hold feature branches
    checked out in their own worktrees, so `git worktree add <dir> <branch>` (or `-B`) fails with
    "already used by worktree". Adding and switching detached against `origin/<branch>` never
    touches that ref."""

    def test_worktree_add_is_detached_against_origin_never_claims_the_branch(self):
        args = gitops.worktree_add_args(Path("/tmp/checkout"), "feat/console-testing")
        self.assertIn("--detach", args)
        self.assertIn("origin/feat/console-testing", args)
        self.assertNotIn("-B", args)
        self.assertNotIn("feat/console-testing", args[:-1])

    def test_worktree_switch_is_detached_against_origin(self):
        fetch, switch = gitops.worktree_switch_args(Path("/tmp/checkout"), "W29")
        self.assertEqual(fetch, ["git", "-C", "/tmp/checkout", "fetch", "origin", "W29"])
        self.assertIn("--detach", switch)
        self.assertIn("origin/W29", switch)
        self.assertNotIn("-B", switch)

    def test_branch_state_file_round_trips_the_requested_branch(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d)
            self.assertEqual(gitops.current_branch(checkout), "")
            gitops.branch_state_file(checkout).parent.mkdir(parents=True, exist_ok=True)
            gitops.branch_state_file(checkout).write_text("W29", encoding="utf-8")
            self.assertEqual(gitops.current_branch(checkout), "W29")

    def test_current_sha_is_empty_when_not_a_worktree(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(gitops.current_sha(Path(d)), "")

    def test_preserves_and_restores_state_around_worktree_add(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "checkout"
            (checkout / ".console" / "results").mkdir(parents=True)
            (checkout / ".console" / "results" / "pr-1.json").write_text("{}", encoding="utf-8")

            tmp = gitops._preserve_state(checkout)
            self.assertIsNotNone(tmp)
            self.assertFalse((checkout / ".console").exists())
            self.assertTrue((tmp / "results" / "pr-1.json").exists())

            checkout.rmdir()
            checkout.mkdir()

            gitops._restore_state(checkout, tmp)
            self.assertTrue((checkout / ".console" / "results" / "pr-1.json").exists())

    def test_no_preserved_state_when_directory_has_other_content(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "checkout"
            (checkout / ".console").mkdir(parents=True)
            (checkout / "something-else.txt").write_text("x", encoding="utf-8")
            self.assertIsNone(gitops._preserve_state(checkout))


class ResolveCheckoutDirTests(unittest.TestCase):
    """A configured checkout_dir rename must not orphan an existing checkout: if the configured
    directory is not yet a real worktree but a pre-rename legacy directory already is, the legacy
    one is reused instead of starting a second checkout alongside it."""

    def _make_worktree_like(self, path: Path) -> None:
        path.mkdir(parents=True, exist_ok=True)
        (path / ".git").write_text("gitdir: /somewhere", encoding="utf-8")

    def test_uses_preferred_when_it_is_already_a_worktree(self):
        with tempfile.TemporaryDirectory() as d:
            preferred = Path(d) / "munserv-console"
            self._make_worktree_like(preferred)
            resolved, notice = gitops.resolve_checkout_dir(preferred)
            self.assertEqual(resolved, preferred)
            self.assertIsNone(notice)

    def test_falls_back_to_legacy_when_preferred_is_not_yet_a_worktree(self):
        original = gitops.CONFIG
        with tempfile.TemporaryDirectory() as d:
            legacy = Path(d) / "munserv-eyeball"
            self._make_worktree_like(legacy)
            preferred = Path(d) / "munserv-console"  # not a worktree: never checked out

            class _Cfg:
                legacy_checkout_dir = legacy

            gitops.CONFIG = _Cfg()
            try:
                resolved, notice = gitops.resolve_checkout_dir(preferred)
                self.assertEqual(resolved, legacy)
                self.assertIsNotNone(notice)
                self.assertIn(str(legacy), notice)
            finally:
                gitops.CONFIG = original

    def test_uses_preferred_when_neither_is_a_worktree(self):
        original = gitops.CONFIG
        with tempfile.TemporaryDirectory() as d:
            legacy = Path(d) / "munserv-eyeball"
            preferred = Path(d) / "munserv-console"

            class _Cfg:
                legacy_checkout_dir = legacy

            gitops.CONFIG = _Cfg()
            try:
                resolved, notice = gitops.resolve_checkout_dir(preferred)
                self.assertEqual(resolved, preferred)
                self.assertIsNone(notice)
            finally:
                gitops.CONFIG = original


class EnsureCheckedOutTests(unittest.TestCase):
    def test_skips_the_checkout_when_already_on_the_requested_branch(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "checkout"
            checkout.mkdir()
            (checkout / ".git").write_text("gitdir: /somewhere", encoding="utf-8")
            gitops.branch_state_file(checkout).parent.mkdir(parents=True, exist_ok=True)
            gitops.branch_state_file(checkout).write_text("master", encoding="utf-8")

            original = gitops.checkout_branch
            gitops.checkout_branch = lambda *a, **k: self.fail("must not re-run checkout")
            try:
                self.assertEqual(gitops.ensure_checked_out(checkout, "master"), "master")
            finally:
                gitops.checkout_branch = original

    def test_runs_the_checkout_when_the_folder_does_not_exist_yet(self):
        # The exact regression: pressing Start (or Prepare) directly, with nothing ever checked
        # out, must trigger a real checkout rather than raising "Check out a branch first".
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "not-yet-checked-out"
            calls = []
            original = gitops.checkout_branch
            gitops.checkout_branch = lambda co, branch: calls.append((co, branch)) or branch
            try:
                result = gitops.ensure_checked_out(checkout, "master")
                self.assertEqual(result, "master")
                self.assertEqual(calls, [(checkout, "master")])
            finally:
                gitops.checkout_branch = original

    def test_runs_the_checkout_when_on_a_different_branch(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "checkout"
            checkout.mkdir()
            (checkout / ".git").write_text("gitdir: /somewhere", encoding="utf-8")
            gitops.branch_state_file(checkout).parent.mkdir(parents=True, exist_ok=True)
            gitops.branch_state_file(checkout).write_text("feat/other", encoding="utf-8")

            calls = []
            original = gitops.checkout_branch
            gitops.checkout_branch = lambda co, branch: calls.append((co, branch)) or branch
            try:
                result = gitops.ensure_checked_out(checkout, "master")
                self.assertEqual(result, "master")
                self.assertEqual(calls, [(checkout, "master")])
            finally:
                gitops.checkout_branch = original

    def test_wraps_a_failed_checkout_as_a_409_with_the_git_error_text(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "not-yet-checked-out"
            original = gitops.checkout_branch

            def _boom(co, branch):
                raise gitops.CommandError("fatal: couldn't find remote ref origin/nope")

            gitops.checkout_branch = _boom
            try:
                with self.assertRaises(gitops.ApiError) as ctx:
                    gitops.ensure_checked_out(checkout, "nope")
                self.assertEqual(ctx.exception.status, 409)
                self.assertIn("couldn't find remote ref", str(ctx.exception))
            finally:
                gitops.checkout_branch = original


class _FakeServer:
    def __init__(self, port):
        self.server_address = ("localhost", port)


class _FakeHandler:
    _allowed_origins = Handler._allowed_origins
    _reject_cross_origin = Handler._reject_cross_origin
    _require_json_content_type = Handler._require_json_content_type

    def __init__(self, headers, port=3999):
        self.headers = headers
        self.server = _FakeServer(port)


class RequestSafetyTests(unittest.TestCase):
    def test_rejects_a_foreign_origin(self):
        handler = _FakeHandler({"Origin": "https://evil.example"})
        with self.assertRaises(gitops.ApiError) as ctx:
            handler._reject_cross_origin()
        self.assertEqual(ctx.exception.status, 403)

    def test_allows_no_origin_header(self):
        _FakeHandler({})._reject_cross_origin()

    def test_allows_localhost_on_the_serving_port(self):
        _FakeHandler({"Origin": "http://localhost:3999"}, port=3999)._reject_cross_origin()

    def test_allows_127_0_0_1_on_the_serving_port(self):
        _FakeHandler({"Origin": "http://127.0.0.1:3999"}, port=3999)._reject_cross_origin()

    def test_rejects_localhost_on_a_different_port(self):
        handler = _FakeHandler({"Origin": "http://localhost:4000"}, port=3999)
        with self.assertRaises(gitops.ApiError):
            handler._reject_cross_origin()

    def test_rejects_a_non_json_content_type(self):
        handler = _FakeHandler({"Content-Type": "text/plain"})
        with self.assertRaises(gitops.ApiError) as ctx:
            handler._require_json_content_type()
        self.assertEqual(ctx.exception.status, 403)

    def test_rejects_a_missing_content_type(self):
        with self.assertRaises(gitops.ApiError):
            _FakeHandler({})._require_json_content_type()

    def test_allows_json_content_type_with_charset_suffix(self):
        _FakeHandler({"Content-Type": "application/json; charset=utf-8"})._require_json_content_type()


class ConfigDefaultsTests(unittest.TestCase):
    def test_defaults_apply_when_project_yaml_is_missing(self):
        with tempfile.TemporaryDirectory() as d:
            cfg = Config(console_dir=Path(d), root=Path(d))
            self.assertEqual(cfg.port, 3999)
            self.assertEqual(cfg.story_label_prefix, "story:")
            self.assertEqual(cfg.sections, {})
            self.assertTrue(cfg.section_enabled("overview"))

    def test_section_can_be_disabled(self):
        with tempfile.TemporaryDirectory() as d:
            console_dir = Path(d)
            (console_dir / "project.yaml").write_text("sections:\n  release: false\n", encoding="utf-8")
            cfg = Config(console_dir=console_dir, root=console_dir)
            self.assertFalse(cfg.section_enabled("release"))
            self.assertTrue(cfg.section_enabled("overview"))

    def test_real_project_yaml_loads(self):
        cfg = Config()
        self.assertEqual(cfg.name, "munserv")
        self.assertTrue(cfg.section_enabled("eyeball"))


class KnowledgeTests(unittest.TestCase):
    def test_domain_concepts_parses_the_real_file(self):
        concepts = knowledge.domain_concepts()
        names = {c["name"] for c in concepts}
        self.assertIn("pod", names)
        self.assertIn("member", names)

    def test_requirements_summary_counts_the_real_web_table(self):
        summaries = {s["file"]: s for s in knowledge.requirements_summary()}
        self.assertIn("web.md", summaries)
        counts = summaries["web.md"]["counts"]
        self.assertGreater(counts["done"], 0)
        self.assertGreater(counts["pending"], 0)

    def test_adr_list_finds_real_decisions(self):
        titles = [a["file"] for a in knowledge.adr_list()]
        self.assertIn("001-kotlin-backend.md", titles)

    def test_missing_files_return_empty_not_an_error(self):
        cfg = Config(console_dir=Path("/nonexistent"), root=Path("/nonexistent"))
        import console.knowledge as k
        original_cfg = k.CONFIG
        k.CONFIG = cfg
        try:
            self.assertEqual(k.domain_concepts(), [])
            self.assertEqual(k.requirements_summary(), [])
            self.assertEqual(k.adr_list(), [])
            self.assertEqual(k.registry_pages(), [])
            self.assertEqual(k.color_tokens(), {})
        finally:
            k.CONFIG = original_cfg


class ClassifyPrTests(unittest.TestCase):
    """MunServ's reviewer/design-reviewer agents post their verdict with `gh pr review --comment`
    -- a PR *review*, not a plain issue comment, and never a real GitHub approval -- so
    `reviewDecision` must never be consulted. Fixtures below mirror the real shape found on PR
    #100: the verdict line is bold markdown and can carry a trailing parenthetical."""

    def test_no_labels_no_comments_is_in_progress(self):
        self.assertEqual(classify_pr(set(), []), "in_progress")

    def test_eyeball_pass_label_wins_outright(self):
        self.assertEqual(classify_pr({"eyeball:pass", "status:review"}, []), "ready_to_merge")

    def test_status_review_label_alone_is_in_review(self):
        self.assertEqual(classify_pr({"status:review"}, []), "in_review")

    def test_latest_approve_review_is_awaiting_eyeball(self):
        comments = [{"body": "Looks close.\n\n**REQUEST CHANGES**"}, {"body": "Fixed.\n\n**APPROVE**"}]
        self.assertEqual(classify_pr(set(), comments), "awaiting_eyeball")

    def test_only_the_latest_verdict_counts(self):
        comments = [{"body": "**APPROVE**"}, {"body": "**REQUEST CHANGES**"}]
        self.assertEqual(classify_pr(set(), comments), "in_review")

    def test_approve_with_eyeball_fail_label_is_not_awaiting_eyeball(self):
        comments = [{"body": "**APPROVE**"}]
        self.assertEqual(classify_pr({"eyeball:fail"}, comments), "in_progress")

    def test_approve_but_design_review_requests_changes_is_not_awaiting_eyeball(self):
        comments = [{"body": "**APPROVE**"}, {"body": "Design review: spacing is off.\n\n**REQUEST CHANGES**"}]
        self.assertEqual(classify_pr(set(), comments), "in_review")

    def test_approve_with_design_review_approve_is_awaiting_eyeball(self):
        comments = [{"body": "Design review: matches the canvas.\n\n**APPROVE**"}, {"body": "**APPROVE**"}]
        self.assertEqual(classify_pr(set(), comments), "awaiting_eyeball")

    def test_request_changes_alone_is_in_review(self):
        comments = [{"body": "Needs another pass.\n\n**REQUEST CHANGES**"}]
        self.assertEqual(classify_pr(set(), comments), "in_review")

    def test_unrelated_comments_do_not_count_as_a_verdict(self):
        comments = [{"body": "This looks great, nice work!"}]
        self.assertEqual(classify_pr(set(), comments), "in_progress")

    def test_request_changes_with_a_trailing_parenthetical_note_still_counts(self):
        # The real shape from PR #100's first review: the verdict line names the blockers too.
        comments = [{"body": "## Reviewer verdict\n\nSome findings.\n\n**REQUEST CHANGES** (B1 rebase, B2 wording)."}]
        self.assertEqual(classify_pr(set(), comments), "in_review")

    def test_approve_bold_markdown_alone_on_its_own_line_is_awaiting_eyeball(self):
        # The real shape from PR #100's second (re-verify) review.
        comments = [{"body": "## Reviewer verdict (re-verify)\n\nEverything checks out.\n\n**APPROVE**\n"}]
        self.assertEqual(classify_pr(set(), comments), "awaiting_eyeball")

    def test_re_review_after_request_changes_supersedes_it(self):
        comments = [
            {"body": "## Reviewer verdict\n\n**REQUEST CHANGES** (B1 rebase, B2 wording)."},
            {"body": "## Reviewer verdict (re-verify)\n\n**APPROVE**"},
        ]
        self.assertEqual(classify_pr(set(), comments), "awaiting_eyeball")

    def test_verdict_named_at_the_end_of_a_heading_line_counts(self):
        # The real shape from PR #102: the verdict word is the last word of a markdown heading,
        # not the start of a line, and the body's actual last line ("No findings. Merging remains
        # the maintainer's call.") names no verdict at all.
        comments = [{"body": "## Reviewer verdict: APPROVE\n\nRe-reviewed; the one finding is resolved.\n\n"
                              "No findings. Merging remains the maintainer's call.\n"}]
        self.assertEqual(classify_pr(set(), comments), "awaiting_eyeball")

    def test_verdict_followed_by_a_dash_aside_counts(self):
        # The real shape from PR #106: not wrapped in bold, and followed by an em-dash aside.
        comments = [{"body": "Nothing else moved since the last pass.\n\nAPPROVE — merging is the user's call.\n"}]
        self.assertEqual(classify_pr(set(), comments), "awaiting_eyeball")

    def test_a_bot_comment_with_no_verdict_line_posted_after_the_review_is_ignored(self):
        # The real shape from PR #102: a lint bot comments after the reviewer's APPROVE. It must
        # not be treated as "the latest body, which happens to have no verdict" -- it is not a
        # verdict source at all, so the reviewer's APPROVE still stands.
        comments = [
            {"body": "## Reviewer verdict: APPROVE\n\nAll good.\n"},
            {"body": "Style nit found by the linter.\n\n*This is a warning only - not blocked.*\n"},
        ]
        self.assertEqual(classify_pr(set(), comments), "awaiting_eyeball")

    def test_heading_request_changes_then_bot_comment_stays_in_review(self):
        comments = [
            {"body": "## Reviewer verdict: REQUEST CHANGES\n\nOne finding.\n"},
            {"body": "Style nit found by the linter.\n\n*This is a warning only - not blocked.*\n"},
        ]
        self.assertEqual(classify_pr(set(), comments), "in_review")


class ChecklistModelTests(unittest.TestCase):
    """The JS checklist view-model builder is pure and DOM-independent (see
    scripts/console/ui/sections/eyeball.model.mjs); run it under Node so its own tests execute
    alongside the Python suite."""

    def test_node_model_tests_pass(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("node not on PATH")
        result = subprocess.run(
            [node, "--test", str(ROOT / "scripts/console/ui/sections/eyeball.model.test.mjs")],
            capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)




class MobileDeviceParsingTests(unittest.TestCase):
    def test_parses_a_normal_device(self):
        output = ("List of devices attached\n"
                   "R58N30ABCDE    device usb:1-1 product:foo model:Galaxy_S21 device:foo transport_id:3\n")
        self.assertEqual(mobile.parse_devices(output),
                          [{"id": "R58N30ABCDE", "state": "device", "model": "Galaxy_S21"}])

    def test_parses_an_unauthorized_device_with_no_model_token(self):
        output = "List of devices attached\n192.168.1.20:5555    unauthorized transport_id:5\n"
        self.assertEqual(mobile.parse_devices(output),
                          [{"id": "192.168.1.20:5555", "state": "unauthorized", "model": None}])

    def test_parses_an_emulator(self):
        output = ("List of devices attached\n"
                   "emulator-5554  device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64 "
                   "device:emu64a transport_id:1\n")
        self.assertEqual(mobile.parse_devices(output),
                          [{"id": "emulator-5554", "state": "device", "model": "sdk_gphone64_x86_64"}])

    def test_header_only_output_is_no_devices(self):
        self.assertEqual(mobile.parse_devices("List of devices attached\n"), [])

    def test_no_adb_on_path_returns_empty_list_not_an_error(self):
        with patch("console.mobile.shutil.which", return_value=None):
            self.assertEqual(mobile.devices(), [])

    def test_adb_present_but_failing_returns_empty_list(self):
        with patch("console.mobile.shutil.which", return_value="/usr/bin/adb"), \
                patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=1, stdout="")
            self.assertEqual(mobile.devices(), [])


class MobileLanIpTests(unittest.TestCase):
    def test_uses_the_ip_command_first(self):
        ip_output = "2: eth0    inet 192.168.1.42/24 brd 192.168.1.255 scope global eth0\n"
        with patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=0, stdout=ip_output)
            self.assertEqual(network.lan_ip(), "192.168.1.42")

    def test_falls_back_to_hostname_when_the_ip_command_is_unavailable(self):
        def fake_run(cmd, **kwargs):
            if cmd[0] == "ip":
                raise FileNotFoundError("no ip command")
            return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="192.168.1.7 172.17.0.1\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(network.lan_ip(), "192.168.1.7")

    def test_falls_back_to_hostname_when_the_ip_command_finds_nothing(self):
        def fake_run(cmd, **kwargs):
            if cmd[0] == "ip":
                return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")
            return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="10.0.0.5\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(network.lan_ip(), "10.0.0.5")

    def test_returns_none_when_neither_source_has_an_address(self):
        with patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=1, stdout="")
            self.assertIsNone(network.lan_ip())


class MobileRequestValidationTests(unittest.TestCase):
    def test_rejects_an_invalid_device_id(self):
        with self.assertRaises(gitops.ApiError) as ctx:
            mobile.validate_device_id("not a device id!")
        self.assertEqual(ctx.exception.status, 400)

    def test_rejects_an_empty_device_id(self):
        with self.assertRaises(gitops.ApiError):
            mobile.validate_device_id("")

    def test_accepts_a_usb_serial_and_a_wireless_address(self):
        self.assertEqual(mobile.validate_device_id("R58N30ABCDE"), "R58N30ABCDE")
        self.assertEqual(mobile.validate_device_id("192.168.1.20:5555"), "192.168.1.20:5555")

    def test_install_requires_a_checkout_with_a_mobile_directory(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "not-checked-out-yet"
            checkout.mkdir()
            with self.assertRaises(gitops.ApiError) as ctx:
                mobile.start_install("emulator-5554", checkout)
            self.assertEqual(ctx.exception.status, 409)

    def test_run_requires_a_checkout_with_a_mobile_directory(self):
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d) / "not-checked-out-yet"
            checkout.mkdir()
            with self.assertRaises(gitops.ApiError) as ctx:
                mobile.start_run("emulator-5554", checkout)
            self.assertEqual(ctx.exception.status, 409)


def _adb_result(stdout: str = "", returncode: int = 0, stderr: str = "") -> subprocess.CompletedProcess:
    return subprocess.CompletedProcess(args=[], returncode=returncode, stdout=stdout, stderr=stderr)


class MobileWirelessDebuggingTests(unittest.TestCase):
    def setUp(self):
        which = patch("console.mobile.shutil.which", return_value="/usr/bin/adb")
        which.start()
        self.addCleanup(which.stop)
        mobile._android_versions.clear()

    def test_pair_passes_the_address_and_code_to_adb(self):
        with patch("console.mobile.subprocess.run",
                   return_value=_adb_result("Successfully paired to 192.168.1.20:37099 [guid=x]\n")) as run:
            message = mobile.pair("192.168.1.20:37099", "123456")
        self.assertEqual(run.call_args.args[0], ["adb", "pair", "192.168.1.20:37099", "123456"])
        self.assertIn("Successfully paired", message)

    def test_pair_reports_adb_text_when_the_code_is_wrong(self):
        with patch("console.mobile.subprocess.run", return_value=_adb_result("Failed: Wrong password\n")):
            with self.assertRaises(gitops.ApiError) as ctx:
                mobile.pair("192.168.1.20:37099", "000000")
        self.assertEqual(ctx.exception.status, 409)
        self.assertIn("Wrong password", str(ctx.exception))

    def test_pair_and_connect_reject_malformed_input_before_running_adb(self):
        with patch("console.mobile.subprocess.run") as run:
            for call in (lambda: mobile.pair("not-an-address", "123456"),
                         lambda: mobile.pair("192.168.1.20:37099", "12345"),
                         lambda: mobile.connect("192.168.1.20; rm -rf /")):
                with self.assertRaises(gitops.ApiError) as ctx:
                    call()
                self.assertEqual(ctx.exception.status, 400)
        run.assert_not_called()

    def test_connect_succeeds_on_connected_and_already_connected(self):
        for text in ("connected to 192.168.1.20:41233\n", "already connected to 192.168.1.20:41233\n"):
            with patch("console.mobile.subprocess.run", return_value=_adb_result(text)):
                self.assertEqual(mobile.connect("192.168.1.20:41233"), text.strip())

    def test_connect_fails_on_adb_text_even_with_exit_code_zero(self):
        text = "failed to connect to '192.168.1.20:41233': Connection refused\n"
        with patch("console.mobile.subprocess.run", return_value=_adb_result(text)):
            with self.assertRaises(gitops.ApiError):
                mobile.connect("192.168.1.20:41233")

    def test_android_version_is_read_once_and_cached(self):
        with patch("console.mobile.subprocess.run", return_value=_adb_result("14\n34\n")) as run:
            self.assertEqual(mobile.android_version("R58N30ABCDE"), {"release": "14", "sdk": 34})
            self.assertEqual(mobile.android_version("R58N30ABCDE"), {"release": "14", "sdk": 34})
        self.assertEqual(run.call_count, 1)

    def test_android_version_is_none_while_the_phone_does_not_answer(self):
        with patch("console.mobile.subprocess.run", return_value=_adb_result("", 1, "error: device unauthorized")):
            self.assertIsNone(mobile.android_version("R58N30ABCDE"))

    def test_describe_devices_skips_phones_that_are_not_authorised(self):
        rows = [{"id": "a", "state": "unauthorized", "model": None}]
        with patch("console.mobile.subprocess.run") as run:
            self.assertEqual(mobile.describe_devices(rows), [{**rows[0], "android": None}])
        run.assert_not_called()

    def test_launch_opens_the_app_by_its_application_id(self):
        with patch("console.mobile.subprocess.run", return_value=_adb_result("Events injected: 1\n")) as run:
            mobile.launch_app("R58N30ABCDE")
        self.assertIn(mobile.APP_ID, run.call_args.args[0])

    def test_launch_fails_when_the_app_is_not_installed(self):
        with patch("console.mobile.subprocess.run",
                   return_value=_adb_result("** No activities found to run, monkey aborted.\n")):
            with self.assertRaises(gitops.ApiError):
                mobile.launch_app("R58N30ABCDE")

    def test_logcat_needs_the_app_running(self):
        with tempfile.TemporaryDirectory() as d, \
                patch("console.mobile.subprocess.run", return_value=_adb_result("\n", 1)):
            with self.assertRaises(gitops.ApiError) as ctx:
                mobile.start_logcat("R58N30ABCDE", Path(d))
        self.assertEqual(ctx.exception.status, 409)

    def test_logcat_filters_to_the_apps_pid_and_starts_a_tracked_process(self):
        with tempfile.TemporaryDirectory() as d, \
                patch("console.mobile.subprocess.run", return_value=_adb_result("4242\n")), \
                patch("console.mobile.services_mod.stop_service"), \
                patch("console.mobile.services_mod.start_tracked_process", return_value="started") as start:
            mobile.start_logcat("R58N30ABCDE", Path(d))
        self.assertEqual(start.call_args.args[0], mobile.LOGCAT_PROCESS)
        self.assertEqual(start.call_args.args[2], "adb -s R58N30ABCDE logcat -v time --pid=4242")

    def test_install_job_logs_under_the_log_root_and_uses_the_given_port(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            build, logs = root / "demo", root / "main"
            (build / "mobile" / ".dart_tool").mkdir(parents=True)
            logs.mkdir()
            commands = []
            def fake_run(cmd, **kwargs):
                commands.append(cmd)
                return _adb_result("")
            with patch("console.mobile.subprocess.run", side_effect=fake_run), \
                    patch("console.mobile.lan_ip", return_value="192.168.1.5"), \
                    patch("console.mobile.is_worktree", return_value=False), \
                    patch("console.mobile.launch_app", return_value="opened"):
                job = mobile.start_install("R58N30ABCDE", build, 8090, logs)
                for _ in range(100):
                    if services.running_job("mobile", "install") is None:
                        break
                    threading.Event().wait(0.05)
            self.assertIn("--dart-define=API_PORT=8090", commands[0])
            self.assertIn("--dart-define=API_HOST=192.168.1.5", commands[0])
            self.assertTrue(services.log_path(logs, mobile.INSTALL_LOG).exists())
            self.assertFalse(services.log_path(build, mobile.INSTALL_LOG).exists())
            self.assertEqual(services.jobs_snapshot()[-1]["id"], job["id"])
            self.assertEqual(services.jobs_snapshot()[-1]["status"], "success")


class LocalFilesTests(unittest.TestCase):
    """gitops.copy_local_files against a real (temporary) git repo, so "never copies a tracked
    file" is exercised against real `git ls-files`, not a mock."""

    def _init_repo(self, root: Path) -> None:
        root.mkdir()
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        (root / "tracked.txt").write_text("tracked", encoding="utf-8")
        subprocess.run(["git", "add", "tracked.txt"], cwd=root, check=True)
        subprocess.run(["git", "-c", "user.email=test@example.com", "-c", "user.name=Test",
                         "commit", "-q", "-m", "init"], cwd=root, check=True)

    def test_copies_a_missing_untracked_file_but_not_a_tracked_or_absent_one(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / "repo"
            self._init_repo(root)
            (root / "mise.local.toml").write_text("x", encoding="utf-8")
            checkout = Path(d) / "checkout"
            checkout.mkdir()
            copied = gitops.copy_local_files(
                checkout, root=root, file_list=["mise.local.toml", "tracked.txt", "missing.file"])
            self.assertEqual(copied, ["mise.local.toml"])
            self.assertTrue((checkout / "mise.local.toml").exists())
            self.assertFalse((checkout / "tracked.txt").exists())
            self.assertFalse((checkout / "missing.file").exists())

    def test_never_overwrites_an_existing_copy(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / "repo"
            self._init_repo(root)
            (root / "mise.local.toml").write_text("from repo", encoding="utf-8")
            checkout = Path(d) / "checkout"
            checkout.mkdir()
            (checkout / "mise.local.toml").write_text("edited by tester", encoding="utf-8")
            copied = gitops.copy_local_files(checkout, root=root, file_list=["mise.local.toml"])
            self.assertEqual(copied, [])
            self.assertEqual((checkout / "mise.local.toml").read_text(encoding="utf-8"), "edited by tester")

    def test_records_the_running_total_across_calls(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / "repo"
            self._init_repo(root)
            (root / "a.toml").write_text("a", encoding="utf-8")
            (root / "b.toml").write_text("b", encoding="utf-8")
            checkout = Path(d) / "checkout"
            checkout.mkdir()
            gitops.copy_local_files(checkout, root=root, file_list=["a.toml"])
            gitops.copy_local_files(checkout, root=root, file_list=["b.toml"])
            self.assertEqual(gitops.local_files_copied(checkout), ["a.toml", "b.toml"])

    def test_a_checkout_with_no_copies_yet_reports_an_empty_list(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(gitops.local_files_copied(Path(d)), [])


class IssueReuseTests(unittest.TestCase):
    """The double-submit guard's other half: before filing a new issue for a failed check or an
    observation, reuse an already-open one from a title search rather than filing a duplicate --
    this is what would have prevented #122 being filed as a duplicate of #123."""

    def test_pick_reusable_issue_matches_an_exact_prefix(self):
        issues = [{"number": 1, "url": "https://x/1", "title": "[Eyeball] B10 E1: something else"}]
        found = eyeball.pick_reusable_issue(issues, "[Eyeball] B10 E1:")
        self.assertEqual(found["url"], "https://x/1")

    def test_pick_reusable_issue_ignores_a_title_that_merely_contains_the_prefix(self):
        # gh's `in:title` search is loose (substring/fuzzy); a title that mentions the prefix
        # somewhere other than at the start must not count as a match.
        issues = [{"number": 2, "url": "https://x/2", "title": "Unrelated bug mentioning [Eyeball] B10 E1: in passing"}]
        self.assertIsNone(eyeball.pick_reusable_issue(issues, "[Eyeball] B10 E1:"))

    def test_pick_reusable_issue_returns_none_for_a_different_check_id(self):
        issues = [{"number": 3, "url": "https://x/3", "title": "[Eyeball] B10 E2: other check"}]
        self.assertIsNone(eyeball.pick_reusable_issue(issues, "[Eyeball] B10 E1:"))

    def test_pick_reusable_issue_returns_none_on_an_empty_result(self):
        self.assertIsNone(eyeball.pick_reusable_issue([], "[Eyeball] B10 E1:"))

    def test_pick_reusable_issue_returns_the_first_match(self):
        issues = [
            {"number": 4, "url": "https://x/4", "title": "[Eyeball] B10 E1: first"},
            {"number": 5, "url": "https://x/5", "title": "[Eyeball] B10 E1: second"},
        ]
        found = eyeball.pick_reusable_issue(issues, "[Eyeball] B10 E1:")
        self.assertEqual(found["url"], "https://x/4")

    def test_search_open_issues_returns_empty_list_when_gh_fails(self):
        original = eyeball.gh_json
        eyeball.gh_json = lambda *a: (_ for _ in ()).throw(eyeball.CommandError("boom"))
        try:
            self.assertEqual(eyeball.search_open_issues("[Eyeball] B10 E1:"), [])
        finally:
            eyeball.gh_json = original

    def test_search_open_issues_parses_the_gh_json_shape(self):
        original = eyeball.gh_json
        captured = {}

        def fake_gh_json(*args):
            captured["args"] = args
            return [{"number": 9, "url": "https://x/9", "title": "[Eyeball] B10 E1: dup"}]

        eyeball.gh_json = fake_gh_json
        try:
            result = eyeball.search_open_issues("[Eyeball] B10 E1:")
            self.assertEqual(result, [{"number": 9, "url": "https://x/9", "title": "[Eyeball] B10 E1: dup"}])
            self.assertIn("--search", captured["args"])
            self.assertIn('in:title "[Eyeball] B10 E1:"', captured["args"])
            self.assertIn("--state", captured["args"])
            self.assertIn("open", captured["args"])
        finally:
            eyeball.gh_json = original

    def test_find_or_create_issue_reuses_a_match_without_calling_create(self):
        original = eyeball.search_open_issues
        eyeball.search_open_issues = lambda prefix: [{"number": 1, "url": "https://x/1", "title": prefix + " dup"}]
        try:
            def boom():
                self.fail("must not create a new issue when one can be reused")
            result = eyeball.find_or_create_issue("[Eyeball] B10 E1:", boom)
            self.assertEqual(result, {"url": "https://x/1", "reused": True})
        finally:
            eyeball.search_open_issues = original

    def test_find_or_create_issue_creates_when_nothing_matches(self):
        original = eyeball.search_open_issues
        eyeball.search_open_issues = lambda prefix: []
        try:
            result = eyeball.find_or_create_issue("[Eyeball] B10 E1:", lambda: "https://x/new")
            self.assertEqual(result, {"url": "https://x/new", "reused": False})
        finally:
            eyeball.search_open_issues = original


class SubmitDoubleGuardTests(unittest.TestCase):
    """/api/eyeball/submit must refuse a second concurrent submit for the same candidate with a
    409 -- the exact scenario that let a click-again on PR #100 file issue #122 as a duplicate of
    #123 while the first submit was still running."""

    def tearDown(self) -> None:
        eyeball._submitting_candidates.clear()

    def test_begin_submit_raises_409_while_already_running(self):
        eyeball.begin_submit("pr-100")
        with self.assertRaises(gitops.ApiError) as ctx:
            eyeball.begin_submit("pr-100")
        self.assertEqual(ctx.exception.status, 409)

    def test_begin_submit_allows_a_different_candidate_concurrently(self):
        eyeball.begin_submit("pr-100")
        eyeball.begin_submit("pr-101")  # must not raise

    def test_end_submit_clears_the_guard_so_a_later_submit_can_run(self):
        eyeball.begin_submit("pr-100")
        eyeball.end_submit("pr-100")
        eyeball.begin_submit("pr-100")  # must not raise


class MobileFirewallRemedyTests(unittest.TestCase):
    """The exact scenario from live use: ufw blocked the backend port from a phone on the LAN.
    The remedy line must name the actual command for whichever firewall systemd reports active."""

    def test_ufw_active_gives_the_ufw_allow_command(self):
        remedy = network.firewall_remedy("ufw", 8080, "192.168.1.0/24")
        self.assertEqual(remedy, "sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp")

    def test_firewalld_active_gives_the_firewall_cmd_command(self):
        remedy = network.firewall_remedy("firewalld", 8080, "192.168.1.0/24")
        self.assertEqual(remedy, "sudo firewall-cmd --add-port=8080/tcp")

    def test_no_known_firewall_gives_a_generic_hint(self):
        remedy = network.firewall_remedy(None, 3000, "192.168.1.0/24")
        self.assertIn("3000", remedy)
        self.assertNotIn("ufw", remedy)
        self.assertNotIn("firewall-cmd", remedy)

    def test_lan_subnet_derives_the_slash_24(self):
        self.assertEqual(network.lan_subnet("192.168.1.42"), "192.168.1.0/24")

    def test_lan_subnet_returns_input_unchanged_when_not_ipv4(self):
        self.assertEqual(network.lan_subnet("not-an-ip"), "not-an-ip")

    def test_detect_active_firewall_prefers_ufw_when_both_checked(self):
        def fake_run(cmd, **kwargs):
            active = "ufw" in cmd
            return subprocess.CompletedProcess(args=cmd, returncode=0 if active else 3,
                                                stdout="active\n" if active else "inactive\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(network.detect_active_firewall(), "ufw")

    def test_detect_active_firewall_falls_back_to_firewalld(self):
        def fake_run(cmd, **kwargs):
            active = "firewalld" in cmd
            return subprocess.CompletedProcess(args=cmd, returncode=0 if active else 3,
                                                stdout="active\n" if active else "inactive\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(network.detect_active_firewall(), "firewalld")

    def test_detect_active_firewall_returns_none_when_neither_is_active(self):
        with patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=3, stdout="inactive\n")
            self.assertIsNone(network.detect_active_firewall())

    def test_detect_active_firewall_returns_none_when_systemctl_is_unavailable(self):
        with patch("console.mobile.subprocess.run", side_effect=FileNotFoundError()):
            self.assertIsNone(network.detect_active_firewall())


class MobileReachabilitySnapshotTests(unittest.TestCase):
    def setUp(self) -> None:
        mobile._reachability.clear()
        mobile._reachability_threads.clear()

    def test_returns_empty_dict_without_a_lan_address(self):
        self.assertEqual(mobile.reachability_snapshot([{"id": "d1", "state": "device"}], None, 8080, False), {})

    def test_skips_unauthorized_devices(self):
        with patch("console.mobile.ensure_reachability_watch") as ensure:
            result = mobile.reachability_snapshot([{"id": "d1", "state": "unauthorized"}], "192.168.1.5", 8080, False)
            self.assertEqual(result, {})
            ensure.assert_not_called()

    def test_web_entry_is_none_when_web_is_not_up(self):
        with patch("console.mobile.ensure_reachability_watch"):
            result = mobile.reachability_snapshot([{"id": "d1", "state": "device"}], "192.168.1.5", 8080, False)
            self.assertIsNone(result["d1"]["web"])

    def test_reports_an_unreachable_backend_with_a_remedy(self):
        mobile._reachability["d1:8080"] = {"reachable": False, "checked_at": 123.0}
        with patch("console.mobile.ensure_reachability_watch"), \
                patch("console.mobile.detect_active_firewall", return_value="ufw"):
            result = mobile.reachability_snapshot([{"id": "d1", "state": "device"}], "192.168.1.5", 8080, False)
            self.assertFalse(result["d1"]["backend"]["reachable"])
            self.assertIn("ufw allow", result["d1"]["backend"]["remedy"])

    def test_reports_a_reachable_backend_with_no_remedy(self):
        mobile._reachability["d1:8080"] = {"reachable": True, "checked_at": 123.0}
        with patch("console.mobile.ensure_reachability_watch"):
            result = mobile.reachability_snapshot([{"id": "d1", "state": "device"}], "192.168.1.5", 8080, False)
            self.assertTrue(result["d1"]["backend"]["reachable"])
            self.assertIsNone(result["d1"]["backend"]["remedy"])


class MobileProbeReachableTests(unittest.TestCase):
    def test_runs_toybox_nc_with_stdin_closed(self):
        with patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=0)
            self.assertTrue(mobile.probe_reachable("d1", "192.168.1.5", 8080))
            args, kwargs = run.call_args
            self.assertEqual(args[0], ["adb", "-s", "d1", "shell", "toybox", "nc", "-w", "3", "192.168.1.5", "8080"])
            self.assertEqual(kwargs.get("stdin"), subprocess.DEVNULL)

    def test_nonzero_exit_is_unreachable(self):
        with patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=1)
            self.assertFalse(mobile.probe_reachable("d1", "192.168.1.5", 8080))

    def test_timeout_is_unreachable_not_an_error(self):
        with patch("console.mobile.subprocess.run", side_effect=subprocess.TimeoutExpired(cmd="adb", timeout=8)):
            self.assertFalse(mobile.probe_reachable("d1", "192.168.1.5", 8080))


class HealthDebounceTests(unittest.TestCase):
    def setUp(self) -> None:
        services._health_misses.clear()
        services._health_seen_up.clear()

    def test_one_slow_probe_does_not_flip_a_running_service_down(self) -> None:
        seq = [True, False, True, False, False, True]
        got = [services.debounced_up("backend", ok) for ok in seq]
        self.assertEqual(got, [True, True, True, True, False, True])

    def test_a_service_never_seen_up_is_down_at_once(self) -> None:
        self.assertFalse(services.debounced_up("web", False))


class HandoffLookupCaseTests(unittest.TestCase):
    def test_label_id_matches_lower_case_and_hyphenated_file_names(self) -> None:
        files = [
            "specs/features/x/077-fix-114-pod-admin-web.md",
            "specs/features/x/078-FIX123-dialog-web.md",
            "specs/features/x/044-W29-support-grant-login-web.md",
        ]
        self.assertEqual(eyeball.match_handoff(files, "FIX114"), files[0])
        self.assertEqual(eyeball.match_handoff(files, "fix123"), files[1])
        self.assertEqual(eyeball.match_handoff(files, "W29"), files[2])
        self.assertIsNone(eyeball.match_handoff(files, "W2"))


# --- remote eyeball -----------------------------------------------------------

class _RemoteTestCase(unittest.TestCase):
    """Runs against a throwaway project.yaml (token file in a temp dir) with remote mode forced on
    or off, a fixed LAN address and hostname, and no real firewall lookups."""
    remote_on = True

    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, True)
        (self.tmp / "project.yaml").write_text(
            f"name: demo\nport: 3999\nremote:\n  enabled: false\n  token_file: {self.tmp / 'state' / 'token'}\n"
            "  ports: {web: 3000, backend: 8080, console: 3999}\n", encoding="utf-8")
        patchers = [
            patch("console.remote.CONFIG", Config(self.tmp, self.tmp)),
            patch("console.network.lan_ip", return_value="192.168.1.42"),
            patch("console.remote.socket.gethostname", return_value="sagan"),
            patch("console.network.detect_active_firewall", return_value="ufw"),
        ]
        for patcher in patchers:
            patcher.start()
            self.addCleanup(patcher.stop)
        remote._host_cache.update(value="", at=None)
        remote.set_mode(self.remote_on)
        self.addCleanup(remote.set_mode, None)


class RemoteTokenTests(_RemoteTestCase):
    def test_token_is_created_private_and_stable(self) -> None:
        first = remote.token()
        path = self.tmp / "state" / "token"
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(remote.token(), first)
        self.assertGreaterEqual(len(first), 32)

    def test_loopback_needs_no_token(self) -> None:
        self.assertEqual(remote.granted_by("127.0.0.1", {}, {}), "open")
        self.assertEqual(remote.granted_by("::1", {}, {}), "open")

    def test_other_addresses_without_a_token_are_refused(self) -> None:
        self.assertIsNone(remote.granted_by("192.168.1.9", {}, {}))

    def test_token_accepted_from_cookie_header_or_query(self) -> None:
        token = remote.token()
        self.assertEqual(remote.granted_by("192.168.1.9", {"Cookie": f"console_token={token}"}, {}), "cookie")
        self.assertEqual(remote.granted_by("192.168.1.9", {"X-Console-Token": token}, {}), "header")
        self.assertEqual(remote.granted_by("192.168.1.9", {}, {"token": [token]}), "query")

    def test_a_wrong_token_is_refused_everywhere(self) -> None:
        remote.token()
        self.assertIsNone(remote.granted_by("192.168.1.9", {"Cookie": "console_token=nope"}, {}))
        self.assertIsNone(remote.granted_by("192.168.1.9", {"X-Console-Token": "nope"}, {}))
        self.assertIsNone(remote.granted_by("192.168.1.9", {}, {"token": ["nope"]}))

    def test_malformed_cookie_header_counts_as_no_token(self) -> None:
        self.assertIsNone(remote.cookie_token("garbage;;="))

    def test_cookie_is_http_only_strict_and_site_wide(self) -> None:
        header = remote.cookie_header("abc")
        for part in ("console_token=abc", "HttpOnly", "SameSite=Strict", "Path=/"):
            self.assertIn(part, header)


class RemoteLocalModeTests(_RemoteTestCase):
    remote_on = False

    def test_local_mode_needs_no_token_from_anyone(self) -> None:
        self.assertEqual(remote.granted_by("192.168.1.9", {}, {}), "open")

    def test_local_mode_binds_localhost_and_allows_only_local_origins(self) -> None:
        self.assertEqual(remote.listen_address(), "localhost")
        self.assertEqual(remote.allowed_origins(3999), {"http://localhost:3999", "http://127.0.0.1:3999"})

    def test_snapshot_reports_disabled(self) -> None:
        self.assertEqual(remote.snapshot(3999, True), {"enabled": False})


class RemoteModeTests(_RemoteTestCase):
    def test_binds_the_configured_address(self) -> None:
        self.assertEqual(remote.listen_address(), "0.0.0.0")

    def test_origin_allow_list_gains_lan_address_and_hostname(self) -> None:
        self.assertEqual(remote.allowed_origins(3999), {
            "http://localhost:3999", "http://127.0.0.1:3999",
            "http://192.168.1.42:3999", "http://sagan:3999"})

    def test_a_foreign_origin_is_still_rejected(self) -> None:
        handler = _FakeHandler({"Origin": "http://evil.example:3999"})
        with self.assertRaises(gitops.ApiError):
            handler._reject_cross_origin()

    def test_the_lan_origin_is_accepted(self) -> None:
        _FakeHandler({"Origin": "http://192.168.1.42:3999"})._reject_cross_origin()

    def test_urls_use_the_lan_address(self) -> None:
        self.assertEqual(remote.urls(3999), {
            "web": "http://192.168.1.42:3000", "swagger": "http://192.168.1.42:8080/swagger-ui.html",
            "console": "http://192.168.1.42:3999"})

    def test_firewall_command_opens_all_three_ports_in_one_ufw_rule(self) -> None:
        fw = remote.firewall(3999)
        self.assertEqual(fw["command"], "sudo ufw allow from 192.168.1.0/24 to any port 3000,3999,8080 proto tcp")
        self.assertEqual((fw["active"], fw["subnet"]), ("ufw", "192.168.1.0/24"))

    def test_firewalld_command_lists_each_port(self) -> None:
        self.assertEqual(network.firewall_remedy_for_ports("firewalld", [8080, 3000], "10.0.0.0/24"),
                         "sudo firewall-cmd --add-port=3000/tcp --add-port=8080/tcp")

    def test_snapshot_hides_the_token_from_remote_users(self) -> None:
        shown = remote.snapshot(3999, loopback=False)
        self.assertNotIn("console_with_token", shown["urls"])
        self.assertNotIn(remote.token(), repr(shown))
        local = remote.snapshot(3999, loopback=True)
        self.assertEqual(local["urls"]["console_with_token"], f"http://192.168.1.42:3999/?token={remote.token()}")
        self.assertEqual(local["ports"], {"web": 3000, "backend": 8080, "console": 3999})


class ServiceTemplateTests(_RemoteTestCase):
    def test_expand_fills_every_placeholder_and_leaves_other_braces(self) -> None:
        self.assertEqual(remote.expand("{bind} {host} {hostname} [{api_base}] ${HOME} {x}"),
                         "0.0.0.0 192.168.1.42 sagan [] ${HOME} {x}")

    def test_remote_web_start_uses_a_relative_api_and_binds_the_lan(self) -> None:
        start = services.services_config()["web"]["start"]
        self.assertIn("VITE_API_URL=/api/v1 ", start)
        self.assertIn("__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS=sagan", start)
        self.assertTrue(start.endswith("--host 0.0.0.0"))

    def test_remote_backend_start_points_emailed_links_at_the_public_web_url(self) -> None:
        start = services.services_config()["backend"]["start"]
        self.assertIn("MUNSERV_APP_ADMIN_PORTAL_URL=http://192.168.1.42:3000", start)

    def test_health_checks_keep_probing_localhost(self) -> None:
        cfg = services.services_config()
        self.assertEqual(cfg["web"]["health"], "http://localhost:3000")
        self.assertEqual(cfg["web"]["url"], "http://192.168.1.42:3000")

    def test_local_mode_keeps_todays_commands(self) -> None:
        remote.set_mode(False)
        web = services.services_config()["web"]
        self.assertIn("VITE_API_URL=http://localhost:8080/api/v1 ", web["start"])
        self.assertTrue(web["start"].endswith("--host localhost"))
        self.assertEqual(web["url"], "http://localhost:3000")


class _ServerTestCase(_RemoteTestCase):
    """A real console server on an ephemeral port. Every request is treated as non-loopback unless
    a test says otherwise, because the test client is itself on loopback."""

    def setUp(self) -> None:
        super().setUp()
        from http.server import ThreadingHTTPServer
        self.is_loopback = patch("console.remote.is_loopback", return_value=False)
        self.is_loopback.start()
        self.addCleanup(self.is_loopback.stop)
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.port = self.server.server_address[1]
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)

    def request(self, path, headers=None, method="GET", body=None):
        import http.client
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        conn.request(method, path, body=body, headers=headers or {})
        response = conn.getresponse()
        response.read()
        conn.close()
        return response


class ConsoleAuthHttpTests(_ServerTestCase):
    def test_static_files_and_api_are_refused_without_a_token(self) -> None:
        self.assertEqual(self.request("/").status, 403)
        self.assertEqual(self.request("/app.css").status, 403)
        self.assertEqual(self.request("/api/remote").status, 403)

    def test_post_is_refused_without_a_token_and_reaches_routing_with_one(self) -> None:
        json_headers = {"Content-Type": "application/json"}
        self.assertEqual(self.request("/api/nope", json_headers, "POST", "{}").status, 403)
        with_token = {**json_headers, "X-Console-Token": remote.token()}
        self.assertEqual(self.request("/api/nope", with_token, "POST", "{}").status, 404)

    def test_header_token_is_accepted(self) -> None:
        self.assertEqual(self.request("/app.css", {"X-Console-Token": remote.token()}).status, 200)

    def test_wrong_token_is_refused(self) -> None:
        self.assertEqual(self.request("/?token=wrong").status, 403)

    def test_query_token_sets_the_cookie_and_redirects_without_the_token(self) -> None:
        response = self.request(f"/?token={remote.token()}")
        self.assertEqual(response.status, 302)
        self.assertEqual(response.getheader("Location"), "/")
        self.assertIn(f"console_token={remote.token()}", response.getheader("Set-Cookie"))

    def test_cookie_then_opens_the_page(self) -> None:
        self.assertEqual(self.request("/", {"Cookie": f"console_token={remote.token()}"}).status, 200)

    def test_loopback_is_exempt(self) -> None:
        self.is_loopback.stop()
        self.addCleanup(self.is_loopback.start)
        self.assertEqual(self.request("/").status, 200)

    def test_local_mode_serves_everyone_without_a_token(self) -> None:
        remote.set_mode(False)
        self.assertEqual(self.request("/").status, 200)


class RestartReasonTests(unittest.TestCase):
    base = dict(detached=False, tracked_running=True, healthy=True, recorded_sha="abc1234", head_sha="abc1234")

    def reason(self, **overrides):
        return ensure.restart_reason(**{**self.base, **overrides})

    def test_unchanged_healthy_service_is_left_alone(self) -> None:
        self.assertIsNone(self.reason())

    def test_exited_process_restarts(self) -> None:
        self.assertEqual(self.reason(tracked_running=False), "process exited")

    def test_never_started_service_starts(self) -> None:
        self.assertEqual(self.reason(tracked_running=False, recorded_sha=None), "not running")

    def test_moved_checkout_restarts(self) -> None:
        self.assertIn("abc1234 -> def5678", self.reason(head_sha="def5678"))

    def test_unhealthy_service_restarts(self) -> None:
        self.assertEqual(self.reason(healthy=False), "unhealthy")

    def test_detached_service_is_kept_while_healthy_even_if_the_checkout_moved(self) -> None:
        self.assertIsNone(self.reason(detached=True, tracked_running=False, head_sha="def5678"))

    def test_detached_service_starts_when_down(self) -> None:
        self.assertEqual(self.reason(detached=True, tracked_running=False, healthy=False), "not running")


class EnsureFlowTests(_RemoteTestCase):
    """ensure() with git, gh and the service processes mocked: what it starts, what it keeps."""
    CFG = {"db": {"health": "tcp:1", "detached": True}, "backend": {"health": "http://h/b"},
           "web": {"health": "http://h/w"}}
    HEALTH_OWNER = {"tcp:1": "db", "http://h/b": "backend", "http://h/w": "web"}

    def setUp(self) -> None:
        super().setUp()
        self.up, self.running, self.shas = set(), set(), {}
        self.head = "aaa1111"
        self.stopped, self.started = [], []

        def start(name, checkout):
            self.started.append(name)
            self.running.add(name)
            self.up.add(name)
            self.shas[name] = self.head

        def stop(name, checkout):
            self.stopped.append(name)
            self.running.discard(name)
            self.up.discard(name)

        patchers = [
            patch.object(ensure, "pr_branch", return_value="feat/x"),
            patch.object(ensure, "checkout_branch"),
            patch.object(ensure, "current_sha", side_effect=lambda c: self.head),
            patch.object(ensure, "story_accounts", return_value={"admin": {"email": "a@b", "password": "pw"}}),
            patch.object(ensure, "HEALTH_POLL_SECONDS", 0),
            patch.object(ensure, "STOP_TIMEOUT_SECONDS", 0),
            patch.object(services, "services_config", return_value=self.CFG),
            patch.object(services, "prepare_needed", return_value=False),
            patch.object(services, "process_status",
                         side_effect=lambda n: {"running": n in self.running, "exit_code": None}),
            patch.object(services, "health_ok", side_effect=lambda h: self.HEALTH_OWNER[h] in self.up),
            patch.object(services, "recorded_shas", side_effect=lambda c: dict(self.shas)),
            patch.object(services, "start_service", side_effect=start),
            patch.object(services, "stop_service", side_effect=stop),
            patch.object(services, "latest_otp", return_value="123456 (for 0821234567)"),
        ]
        for patcher in patchers:
            patcher.start()
            self.addCleanup(patcher.stop)
        self.checkout = self.tmp / "checkout"

    def run_ensure(self):
        return ensure.ensure(42, self.checkout, 3999)

    def test_result_shape(self) -> None:
        result = self.run_ensure()
        self.assertEqual(result["pr"], 42)
        self.assertEqual(result["sha"], "aaa1111")
        self.assertEqual(set(result["services"]), {"db", "backend", "web"})
        self.assertEqual(result["urls"]["web"], "http://192.168.1.42:3000")
        self.assertEqual(result["urls"]["console"], f"http://192.168.1.42:3999/?token={remote.token()}")
        self.assertEqual(result["accounts"]["admin"]["password"], "pw")
        self.assertEqual(result["otp"], "123456 (for 0821234567)")
        self.assertIn("ufw allow from 192.168.1.0/24", result["firewall_command"])

    def test_first_run_starts_everything_without_calling_it_a_restart(self) -> None:
        result = self.run_ensure()
        self.assertEqual(self.started, ["db", "backend", "web"])
        self.assertTrue(all(not s["restarted"] and s["state"] == "up" for s in result["services"].values()))

    def test_second_run_with_nothing_changed_starts_nothing(self) -> None:
        self.run_ensure()
        self.started.clear()
        result = self.run_ensure()
        self.assertEqual((self.started, self.stopped), ([], []))
        self.assertTrue(all(not s["restarted"] for s in result["services"].values()))

    def test_a_moved_checkout_restarts_the_app_services_but_not_the_database(self) -> None:
        self.run_ensure()
        self.started.clear()
        self.head = "bbb2222"
        result = self.run_ensure()
        self.assertEqual(sorted(self.stopped), ["backend", "web"])
        self.assertTrue(result["services"]["web"]["restarted"])
        self.assertFalse(result["services"]["db"]["restarted"])
        self.assertEqual(self.shas["web"], "bbb2222")

    def test_an_exited_service_is_started_again(self) -> None:
        self.run_ensure()
        self.running.discard("web")
        self.up.discard("web")
        self.started.clear()
        self.run_ensure()
        self.assertEqual(self.started, ["web"])


class RunningShaTests(unittest.TestCase):
    def test_the_sha_a_service_started_from_is_recorded_per_service(self) -> None:
        with tempfile.TemporaryDirectory() as d, patch.object(services, "current_sha", side_effect=["aaa1111", "bbb2222"]):
            checkout = Path(d)
            self.assertEqual(services.recorded_shas(checkout), {})
            services.record_running_sha(checkout, "web")
            services.record_running_sha(checkout, "backend")
            self.assertEqual(services.recorded_shas(checkout), {"web": "aaa1111", "backend": "bbb2222"})
            self.assertTrue((checkout / ".console" / "running-sha").is_file())


class EnsurePrBranchTests(unittest.TestCase):
    def pr_info(self, state: str) -> str:
        return json.dumps({"headRefName": "feat/x", "baseRefName": "master", "state": state})

    def test_an_open_pr_checks_out_its_head_branch(self) -> None:
        with patch.object(ensure, "gh", return_value=self.pr_info("OPEN")), patch.object(ensure, "repo", return_value="o/r"):
            self.assertEqual(ensure.pr_branch(1), "feat/x")

    def test_a_merged_pr_checks_out_the_branch_it_merged_into(self) -> None:
        with patch.object(ensure, "gh", return_value=self.pr_info("MERGED")), patch.object(ensure, "repo", return_value="o/r"):
            self.assertEqual(ensure.pr_branch(1), "master")


class EnsureFailureTests(unittest.TestCase):
    def test_timeout_reports_the_last_log_line(self) -> None:
        with tempfile.TemporaryDirectory() as d:
            checkout = Path(d)
            services.log_path(checkout, "backend").write_text(
                "starting\nPort 8080 was already in use.\n", encoding="utf-8")
            with patch.object(services, "health_ok", return_value=False), \
                    patch.object(services, "process_status", return_value={"running": True, "exit_code": None}):
                with self.assertRaises(gitops.ApiError) as ctx:
                    ensure._wait_healthy("backend", {"health": "http://h/b"}, checkout, timeout=0)
            self.assertEqual(ctx.exception.status, 504)
            self.assertIn("Port 8080 was already in use.", str(ctx.exception))

    def test_an_exited_process_fails_at_once(self) -> None:
        with tempfile.TemporaryDirectory() as d:
            with patch.object(services, "health_ok", return_value=False), \
                    patch.object(services, "process_status", return_value={"running": False, "exit_code": 1}):
                with self.assertRaises(gitops.ApiError) as ctx:
                    ensure._wait_healthy("web", {"health": "http://h/w"}, Path(d), timeout=60)
            self.assertIn("exited with code 1", str(ctx.exception))


class EnsureReportTests(unittest.TestCase):
    RESULT = {
        "pr": 42, "sha": "aaa1111", "branch": "feat/x",
        "services": {"db": {"state": "up", "restarted": False, "reason": "unchanged"},
                     "web": {"state": "up", "restarted": True, "reason": "checkout moved (a -> b)"}},
        "urls": {"web": "http://h:3000", "swagger": "http://h:8080/swagger-ui.html",
                 "console": "http://h:3999/?token=t"},
        "accounts": {"admin": {"email": "a@b", "password": "pw"}}, "otp": None,
        "firewall_command": "sudo ufw allow from 10.0.0.0/24 to any port 3000,3999,8080 proto tcp",
    }

    def test_report_lists_links_accounts_and_the_firewall_command(self) -> None:
        text = ensure.format_report(self.RESULT)
        for expected in ("PR #42 at aaa1111", "web: up (restarted: checkout moved (a -> b))",
                         "Web:     http://h:3000", "Swagger: http://h:8080/swagger-ui.html",
                         "Console: http://h:3999/?token=t", "admin: a@b / pw", "sudo ufw allow from 10.0.0.0/24"):
            self.assertIn(expected, text)
        self.assertNotIn("OTP", text)

    def test_report_omits_the_firewall_block_in_local_mode(self) -> None:
        self.assertNotIn("First time", ensure.format_report({**self.RESULT, "firewall_command": None}))


class CostAggregateTests(unittest.TestCase):
    @staticmethod
    def _point(value, nanos, **attrs):
        return {"asDouble": value, "timeUnixNano": str(nanos),
                "attributes": [{"key": k, "value": {"stringValue": v}} for k, v in attrs.items()]}

    def _doc(self, metric, points, story=None):
        resource = [{"key": "story.id", "value": {"stringValue": story}}] if story else []
        return json.dumps({"resourceMetrics": [{"resource": {"attributes": resource},
                           "scopeMetrics": [{"metrics": [{"name": metric, "sum": {"dataPoints": points}}]}]}]})

    def _aggregate(self, lines: list[str]) -> dict:
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "metrics.jsonl"
            path.write_bytes("\n".join(lines).encode())
            return cost.aggregate(path)

    def test_groups_cost_and_tokens_by_day_agent_model_and_story(self) -> None:
        day1, day2 = 1_793_293_476_000_000_000, 1_793_293_476_000_000_000 + 2 * 86_400 * 10**9
        result = self._aggregate([
            self._doc(cost.COST_METRIC, [self._point(0.5, day1, model="opus"),
                                         self._point(0.25, day2, model="haiku", **{"agent.name": "clerk"})], story="W1"),
            self._doc(cost.TOKEN_METRIC, [self._point(100, day1, model="opus", type="output"),
                                          self._point(7, day2, model="haiku", type="cacheRead",
                                                      **{"agent.name": "clerk"})], story="W1"),
        ])
        self.assertAlmostEqual(result["total"]["cost"], 0.75)
        by = lambda dim: {r["key"]: r for r in result[dim]}  # noqa: E731
        self.assertEqual(set(by("agent")), {"main", "clerk"})
        self.assertAlmostEqual(by("agent")["clerk"]["cost"], 0.25)
        self.assertEqual(by("agent")["clerk"]["tokens"]["cacheRead"], 7)
        self.assertEqual(by("model")["opus"]["tokens"]["output"], 100)
        self.assertEqual(set(by("story")), {"W1"})
        self.assertEqual(len(result["day"]), 2)
        self.assertGreater(result["day"][0]["key"], result["day"][1]["key"])  # newest day first

    def test_a_run_without_a_story_lands_under_none(self) -> None:
        result = self._aggregate([self._doc(cost.COST_METRIC, [self._point(1.0, 10**18, model="m")])])
        self.assertEqual([r["key"] for r in result["story"]], [cost.NO_STORY])

    def test_ignores_other_metrics_blank_nul_padded_and_truncated_lines(self) -> None:
        good = self._doc(cost.COST_METRIC, [self._point(2.0, 10**18, model="m")])
        result = self._aggregate(["\0\0\0" + good, "", '{"resourceMetrics": [{"trunc',
                                  self._doc("claude_code.session.count", [self._point(1, 10**18)])])
        self.assertAlmostEqual(result["total"]["cost"], 2.0)

    def test_a_missing_file_reports_unavailable_not_an_error(self) -> None:
        with tempfile.TemporaryDirectory() as d, patch.object(cost.CONFIG, "_raw",
                                                              return_value={"telemetry_dir": d + "/none"}):
            cost._cache["key"] = None
            snapshot = cost.get_snapshot()
        self.assertFalse(snapshot["available"])
        self.assertEqual(snapshot["agent"], [])


class ShowcaseTests(unittest.TestCase):
    def test_config_defaults_place_the_worktree_beside_the_repo(self):
        settings = showcase.cfg()
        self.assertEqual(settings["checkout_dir"], ROOT.parent / "munserv-demo")
        self.assertEqual((settings["backend_port"], settings["web_port"], settings["database"]), (8090, 4000, "munserv_demo"))

    def test_demo_services_exist_with_the_showcase_ports(self):
        cfg = services.services_config()
        self.assertIn(":8090/", cfg["demo-backend"]["health"])
        self.assertTrue(cfg["demo-web"]["health"].endswith(":4000"))
        self.assertTrue(cfg["demo-build"]["manual"])
        self.assertTrue(all(cfg[name].get("showcase") for name in ("demo-backend", "demo-web", "demo-build")))

    def test_database_commands_create_only_the_showcase_database(self):
        probe, create, extensions = showcase.database_commands(showcase.cfg())
        self.assertIn("datname = 'munserv_demo'", probe[-1])
        self.assertEqual(create[-1], "CREATE DATABASE munserv_demo")
        self.assertIn("munserv_demo", extensions)
        self.assertIn("postgis", extensions[-1])

    def test_database_name_is_validated_before_it_reaches_sql(self):
        with self.assertRaises(gitops.ApiError):
            showcase.database_commands({**showcase.cfg(), "database": "x; DROP DATABASE munserv_dev"})

    def test_backend_command_runs_the_jar_under_the_demo_profile(self):
        command = showcase.backend_command(Path("/w/munserv-demo/backend/build/libs/app.jar"))
        self.assertIn("SPRING_PROFILES_ACTIVE=local,mailpit,demo", command)
        self.assertTrue(command.endswith("java -jar /w/munserv-demo/backend/build/libs/app.jar"))

    def test_web_is_served_by_vite_preview_on_4000_and_proxied_to_8090(self):
        command = showcase.web_command()
        self.assertIn("PREVIEW_API_TARGET=http://localhost:8090", command)
        self.assertIn("vite preview", command)
        self.assertIn("--port 4000 --strictPort", command)
        self.assertEqual(showcase.web_build_env()["VITE_API_URL"], "/api/v1")

    def test_built_jar_skips_the_plain_jar(self):
        with tempfile.TemporaryDirectory() as tmp:
            libs = Path(tmp) / "backend" / "build" / "libs"
            libs.mkdir(parents=True)
            (libs / "app-plain.jar").write_text("")
            (libs / "app.jar").write_text("")
            with patch.object(showcase, "checkout", return_value=Path(tmp)):
                self.assertEqual(showcase.built_jar(), libs / "app.jar")

    def test_start_without_a_build_is_refused(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(showcase, "checkout", return_value=Path(tmp)):
            with self.assertRaises(gitops.ApiError) as raised:
                showcase.start(Path(tmp))
        self.assertEqual(raised.exception.status, 409)

    def test_update_creates_a_detached_worktree_then_follows_origin_master(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            origin, repo, demo = tmp_path / "origin.git", tmp_path / "repo", tmp_path / "demo"

            def git(*args, cwd=repo):
                return subprocess.check_output(["git", "-C", str(cwd), *args], text=True).strip()

            subprocess.check_call(["git", "init", "-q", "--bare", "-b", "master", str(origin)])
            subprocess.check_call(["git", "clone", "-q", str(origin), str(repo)], stderr=subprocess.DEVNULL)
            git("config", "user.email", "t@example.com")
            git("config", "user.name", "t")
            (repo / "a.txt").write_text("1")
            git("add", ".")
            git("commit", "-qm", "one")
            git("push", "-q", "origin", "HEAD:master")
            with patch.object(showcase, "ROOT", repo), patch.object(showcase, "checkout", return_value=demo), \
                    patch.object(showcase, "copy_local_files"):
                first = showcase.update()
                self.assertEqual(first, git("rev-parse", "--short", "HEAD"))
                self.assertEqual(git("rev-parse", "--abbrev-ref", "HEAD", cwd=demo), "HEAD")  # detached
                (repo / "a.txt").write_text("2")
                git("commit", "-qam", "two")
                git("push", "-q", "origin", "HEAD:master")
                second = showcase.update()
            self.assertEqual(second, git("rev-parse", "--short", "HEAD"))
            self.assertNotEqual(first, second)
            self.assertEqual((demo / "a.txt").read_text(), "2")


if __name__ == "__main__":
    unittest.main(verbosity=2)
