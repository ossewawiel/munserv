#!/usr/bin/env python3
"""Unit tests for scripts/lint-handoffs.py.

Usage: python3 scripts/test-lint-handoffs.py
"""
from __future__ import annotations

import importlib.util
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def _load_module():
    spec = importlib.util.spec_from_file_location("lint_handoffs", ROOT / "scripts" / "lint-handoffs.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


lint = _load_module()
ACCOUNTS = {"pod_chief", "sector_admin"}
SERVICES = {"db", "backend", "web", "storybook"}

GOOD_CHECKS = """\
- id: E1
  title: Pod chief sees the list
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - Log in as the pod chief.
  expect: The list shows.
  covers: [AC1]
- id: E2
  title: Anonymous call is refused
  as: none
  services: [db, backend]
  url: http://localhost:8080/swagger-ui/index.html#/Pod/list
  steps:
    - Execute without a token.
  expect: The answer is 401.
  covers: [2, AC3]
"""


def handoff(checks: str = GOOD_CHECKS, front: str = "ui: true", acs: int = 3, eyeball: str | None = None) -> str:
    criteria = "\n".join(f"- [ ] Criterion {n}" for n in range(1, acs + 1))
    block = eyeball if eyeball is not None else f"## Eyeball\nIntro.\n\n```yaml\n{checks}```\n"
    return (
        f"---\nissue: 1\nstory: W99\nplatform: web\n{front}\n---\n\n# W99\n\n"
        f"## Acceptance criteria\n{criteria}\n\n## Steps\n1. Do it.\n\n{block}"
    )


class LintHandoffsTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.path = Path(self._tmp.name) / "001-W99-thing-web.md"

    def problems(self, text: str) -> list[str]:
        self.path.write_text(text)
        return lint.lint_handoff(self.path, ACCOUNTS, SERVICES)

    def test_should_pass_a_complete_block(self):
        self.assertEqual(self.problems(handoff()), [])

    def test_should_skip_a_story_that_is_neither_ui_nor_user_facing(self):
        self.assertEqual(self.problems(handoff(front="ui: false\nuser_facing: false", eyeball="")), [])

    def test_should_require_a_block_for_user_facing(self):
        found = self.problems(handoff(front="user_facing: true", eyeball=""))
        self.assertIn("no ## Eyeball section", found[0])

    def test_should_refuse_a_prose_block(self):
        found = self.problems(handoff(eyeball="## Eyeball\n1. Log in.\n2. Look at the list.\n"))
        self.assertIn("no ```yaml block", found[0])

    def test_should_name_an_uncovered_criterion(self):
        found = self.problems(handoff(acs=4))
        self.assertTrue(any("no check covers AC4" in p for p in found), found)

    def test_should_accept_an_exempt_criterion(self):
        self.assertEqual(self.problems(handoff(acs=4, front="ui: true\neyeball_exempt: [AC4]")), [])

    def test_should_refuse_a_cover_beyond_the_criteria(self):
        found = self.problems(handoff(checks=GOOD_CHECKS.replace("[AC1]", "[AC1, AC9]")))
        self.assertTrue(any("'AC9' is not an acceptance criterion" in p for p in found), found)

    def test_should_require_covers_on_every_check(self):
        found = self.problems(handoff(checks=GOOD_CHECKS.replace("  covers: [AC1]\n", "")))
        self.assertTrue(any(p.startswith("E1: missing covers") for p in found), found)

    def test_should_refuse_an_unknown_account(self):
        found = self.problems(handoff(checks=GOOD_CHECKS.replace("as: pod_chief", "as: podchief")))
        self.assertTrue(any("as 'podchief' is not a key" in p for p in found), found)

    def test_should_refuse_an_unknown_service(self):
        found = self.problems(handoff(checks=GOOD_CHECKS.replace("[db, backend, web]", "[db, api]")))
        self.assertTrue(any("service 'api'" in p for p in found), found)

    def test_should_refuse_a_bare_path_url(self):
        found = self.problems(handoff(checks=GOOD_CHECKS.replace("http://localhost:3000/pod-administrators", "/pod-administrators")))
        self.assertTrue(any("is not a complete address" in p for p in found), found)

    def test_should_refuse_a_single_check(self):
        one = GOOD_CHECKS.split("- id: E2")[0].replace("[AC1]", "[AC1, AC2, AC3]")
        found = self.problems(handoff(checks=one))
        self.assertTrue(any("has 1 checks" in p for p in found), found)

    def test_should_refuse_duplicate_ids(self):
        found = self.problems(handoff(checks=GOOD_CHECKS.replace("id: E2", "id: E1")))
        self.assertTrue(any("E1: duplicate id" in p for p in found), found)

    def test_should_lint_the_template_examples_as_a_ui_story(self):
        text = (ROOT / "specs/features/_template/story-handoff.md").read_text().replace("ui: false ", "ui: true ", 1)
        accounts = lint.load_keys(lint.ACCOUNTS)
        services = lint.load_keys(lint.SERVICES)
        self.path.write_text(text)
        self.assertEqual(lint.lint_handoff(self.path, accounts, services), [])

    def test_should_only_take_open_handoffs_from_a_diff(self):
        self.assertTrue(lint.is_handoff_path("specs/features/quick-login/208-W31-quick-login-web.md"))
        self.assertFalse(lint.is_handoff_path("specs/features/_template/story-handoff.md"))
        self.assertFalse(lint.is_handoff_path("specs/features/quick-login/completed/208-W31-quick-login-web.md"))
        self.assertFalse(lint.is_handoff_path("web/src/App.tsx"))


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    sys.exit(0 if result.wasSuccessful() else 1)
