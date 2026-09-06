#!/usr/bin/env python3
"""Unit tests for scripts/eyeball.py's handoff lookup and issue-safety helpers.

No network, no `gh`, no server: exercises the pure functions directly, using the real
specs/features tree at HEAD to prove the handoff naming convention actually matches.

Usage: python3 scripts/test-eyeball.py
"""
from __future__ import annotations

import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

spec = importlib.util.spec_from_file_location("eyeball", ROOT / "scripts" / "eyeball.py")
eyeball = importlib.util.module_from_spec(spec)
spec.loader.exec_module(eyeball)


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
        # No M* handoff exists in specs/features yet (mobile stories predate this template), so
        # this proves the <issue>-<story>-<platform>.md convention generalises to mobile rather
        # than being backend/web-specific, against a small synthetic tree shaped like the real one.
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
        self.assertEqual(eyeball.validate_name("pr-100", "candidate"), "pr-100")

    def test_accepts_the_smoke_candidate_id(self):
        self.assertEqual(eyeball.validate_name("smoke", "candidate"), "smoke")

    def test_rejects_a_path_traversal_attempt(self):
        with self.assertRaises(eyeball.ApiError):
            eyeball.validate_name("../../etc/passwd", "candidate")

    def test_rejects_a_slash(self):
        with self.assertRaises(eyeball.ApiError):
            eyeball.validate_name("a/b", "service name")

    def test_rejects_empty(self):
        with self.assertRaises(eyeball.ApiError):
            eyeball.validate_name("", "candidate")

    def test_validate_branch_allows_slashes(self):
        self.assertEqual(eyeball.validate_branch("feat/eyeball-testing"), "feat/eyeball-testing")

    def test_validate_branch_rejects_leading_dash(self):
        with self.assertRaises(eyeball.ApiError):
            eyeball.validate_branch("--upload-pack=evil")


class SubmitGuardTests(unittest.TestCase):
    def test_submit_refuses_when_nothing_is_ticked(self, tmp_path=None):
        import tempfile
        candidate = {
            "id": "smoke", "kind": "smoke", "number": None, "story": "SMOKE", "platform": "web",
            "url": "", "checks": [{"id": "S1", "title": "t", "as": "none", "services": [],
                                    "url": "", "steps": [], "expect": "e"}],
        }
        data = {"candidate": "smoke", "checks": {}, "observations": []}
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(eyeball.ApiError):
                eyeball.submit(candidate, data, Path(d))


if __name__ == "__main__":
    unittest.main(verbosity=2)
