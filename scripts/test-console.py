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

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from console import eyeball, gitops, knowledge, services  # noqa: E402
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


if __name__ == "__main__":
    unittest.main(verbosity=2)


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
