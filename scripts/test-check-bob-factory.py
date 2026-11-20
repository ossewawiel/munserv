#!/usr/bin/env python3
"""Unit tests for scripts/check-bob-factory.py.

Usage: python3 scripts/test-check-bob-factory.py
"""
from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def _load_module():
    spec = importlib.util.spec_from_file_location("check_bob_factory", ROOT / "scripts" / "check-bob-factory.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


check = _load_module()

GOOD = {
    "agents": {"backend-implementer": "bob-kotlin", "web-implementer": "bob-react"},
    "handback": "BLOCKED:",
    "gates": {"bob-kotlin": {"command": "cd backend && ./gradlew test", "commandWindows": "cd backend && gradlew.bat test"},
              "bob-react": {"command": "cd web && pnpm test:run"}},
}


class CheckBobFactoryTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        (self.root / ".bob").mkdir()
        (self.root / ".claude" / "agents").mkdir(parents=True)

    def write(self, config: object, agents: dict[str, str | None] | None = None) -> None:
        (self.root / ".bob" / "factory.json").write_text(config if isinstance(config, str) else json.dumps(config))
        for name, fm_name in (agents if agents is not None else {"backend-implementer": None, "web-implementer": None, "reviewer": None}).items():
            fm = name if fm_name is None else fm_name
            (self.root / ".claude" / "agents" / f"{name}.md").write_text(f"---\nname: {fm}\ndescription: x\n---\n\nBody.\n")

    def problems(self) -> list[str]:
        return check.problems(self.root)

    def assertOneProblem(self, needle: str) -> None:
        found = self.problems()
        self.assertEqual(len(found), 1, found)
        self.assertIn(needle, found[0])

    def test_a_matching_config_passes(self):
        self.write(GOOD)
        self.assertEqual(self.problems(), [])

    def test_main_prints_a_summary_and_exits_zero(self):
        self.write(GOOD)
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = check.main(["x", str(self.root)])
        self.assertEqual(code, 0)
        self.assertIn("2 agents", out.getvalue())

    def test_main_exits_one_on_a_problem(self):
        self.write(GOOD, {"backend-implementer": None})
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(check.main(["x", str(self.root)]), 1)

    def test_an_agent_with_no_file_is_a_problem(self):
        # The renamed-agent slip: the gate guards a name nobody dispatches.
        self.write(GOOD, {"backend-implementer": None, "reviewer": None})
        self.assertOneProblem("agent `web-implementer` has no .claude/agents/web-implementer.md")

    def test_an_implementer_with_no_key_is_a_problem(self):
        self.write(GOOD, {"backend-implementer": None, "web-implementer": None, "mobile-implementer": None})
        self.assertOneProblem("`mobile-implementer` is an implementer with no entry")

    def test_other_agents_need_no_key(self):
        self.write(GOOD, {"backend-implementer": None, "web-implementer": None, "reviewer": None, "designer": None})
        self.assertEqual(self.problems(), [])

    def test_a_frontmatter_name_that_differs_from_the_file_is_a_problem(self):
        self.write(GOOD, {"backend-implementer": "backend-impl", "web-implementer": None})
        found = self.problems()
        self.assertTrue(any("frontmatter `name:` is 'backend-impl'" in p for p in found), found)

    def test_a_pack_with_no_gate_is_a_problem(self):
        config = json.loads(json.dumps(GOOD))
        del config["gates"]["bob-react"]
        self.write(config)
        self.assertOneProblem("names pack `bob-react`, which has no entry in `gates`")

    def test_a_gate_with_no_command_is_a_problem(self):
        config = json.loads(json.dumps(GOOD))
        config["gates"]["bob-react"] = {"commandWindows": "x"}
        self.write(config)
        self.assertOneProblem("gate `bob-react` has no `command`")

    def test_a_blank_command_windows_is_a_problem(self):
        config = json.loads(json.dumps(GOOD))
        config["gates"]["bob-kotlin"]["commandWindows"] = " "
        self.write(config)
        self.assertOneProblem("`commandWindows` must be a non-empty string")

    def test_a_non_string_pack_is_a_problem(self):
        config = json.loads(json.dumps(GOOD))
        config["agents"]["web-implementer"] = ["bob-react"]
        self.write(config)
        self.assertOneProblem("agent `web-implementer` must name a pack")

    def test_empty_agents_is_a_problem(self):
        self.write({"agents": {}, "gates": {}}, {"reviewer": None})
        self.assertOneProblem("`agents` must be a non-empty object")

    def test_a_blank_handback_is_a_problem(self):
        config = json.loads(json.dumps(GOOD))
        config["handback"] = ""
        self.write(config)
        self.assertOneProblem("`handback` must be a non-empty string")

    def test_a_file_that_does_not_parse_is_a_problem(self):
        self.write("{ not json")
        self.assertOneProblem("does not parse")

    def test_a_missing_file_is_a_problem(self):
        self.assertOneProblem("is missing")

    def test_the_repo_itself_passes(self):
        self.assertEqual(check.problems(ROOT), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
