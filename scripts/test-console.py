#!/usr/bin/env python3
"""Unit tests for scripts/console/*.py.

No network, no `gh`, no server: exercises the pure functions directly. Extends (does not replace)
the old scripts/test-eyeball.py test list -- the handoff-matching, request-safety and detached-
worktree tests carry over unchanged in spirit, now against the console package, plus new tests for
config defaults, service prepare detection and knowledge parsing.

Usage: python3 scripts/test-console.py
"""
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from console import eyeball, gitops, knowledge, mobile, services  # noqa: E402
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
            self.assertEqual(mobile.lan_ip(), "192.168.1.42")

    def test_falls_back_to_hostname_when_the_ip_command_is_unavailable(self):
        def fake_run(cmd, **kwargs):
            if cmd[0] == "ip":
                raise FileNotFoundError("no ip command")
            return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="192.168.1.7 172.17.0.1\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(mobile.lan_ip(), "192.168.1.7")

    def test_falls_back_to_hostname_when_the_ip_command_finds_nothing(self):
        def fake_run(cmd, **kwargs):
            if cmd[0] == "ip":
                return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")
            return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="10.0.0.5\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(mobile.lan_ip(), "10.0.0.5")

    def test_returns_none_when_neither_source_has_an_address(self):
        with patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=1, stdout="")
            self.assertIsNone(mobile.lan_ip())


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
        remedy = mobile.firewall_remedy("ufw", 8080, "192.168.1.0/24")
        self.assertEqual(remedy, "sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp")

    def test_firewalld_active_gives_the_firewall_cmd_command(self):
        remedy = mobile.firewall_remedy("firewalld", 8080, "192.168.1.0/24")
        self.assertEqual(remedy, "sudo firewall-cmd --add-port=8080/tcp")

    def test_no_known_firewall_gives_a_generic_hint(self):
        remedy = mobile.firewall_remedy(None, 3000, "192.168.1.0/24")
        self.assertIn("3000", remedy)
        self.assertNotIn("ufw", remedy)
        self.assertNotIn("firewall-cmd", remedy)

    def test_lan_subnet_derives_the_slash_24(self):
        self.assertEqual(mobile.lan_subnet("192.168.1.42"), "192.168.1.0/24")

    def test_lan_subnet_returns_input_unchanged_when_not_ipv4(self):
        self.assertEqual(mobile.lan_subnet("not-an-ip"), "not-an-ip")

    def test_detect_active_firewall_prefers_ufw_when_both_checked(self):
        def fake_run(cmd, **kwargs):
            active = "ufw" in cmd
            return subprocess.CompletedProcess(args=cmd, returncode=0 if active else 3,
                                                stdout="active\n" if active else "inactive\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(mobile.detect_active_firewall(), "ufw")

    def test_detect_active_firewall_falls_back_to_firewalld(self):
        def fake_run(cmd, **kwargs):
            active = "firewalld" in cmd
            return subprocess.CompletedProcess(args=cmd, returncode=0 if active else 3,
                                                stdout="active\n" if active else "inactive\n")
        with patch("console.mobile.subprocess.run", side_effect=fake_run):
            self.assertEqual(mobile.detect_active_firewall(), "firewalld")

    def test_detect_active_firewall_returns_none_when_neither_is_active(self):
        with patch("console.mobile.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess(args=[], returncode=3, stdout="inactive\n")
            self.assertIsNone(mobile.detect_active_firewall())

    def test_detect_active_firewall_returns_none_when_systemctl_is_unavailable(self):
        with patch("console.mobile.subprocess.run", side_effect=FileNotFoundError()):
            self.assertIsNone(mobile.detect_active_firewall())


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


if __name__ == "__main__":
    unittest.main(verbosity=2)
