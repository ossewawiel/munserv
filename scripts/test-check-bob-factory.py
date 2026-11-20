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

    def test_a_string_gate_is_a_problem_and_says_command_windows_is_optional(self):
        config = json.loads(json.dumps(GOOD))
        config["gates"]["bob-react"] = "cd web && pnpm test"
        self.write(config)
        self.assertOneProblem("gate `bob-react` must be an object with a `command` and, optionally, a `commandWindows`")

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
        self.write({"agents": {}, "handback": "BLOCKED:", "gates": {}}, {"reviewer": None})
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

    def test_a_pack_name_bob_core_rejects_is_a_problem(self):
        # PR 320 review B1: bob-core takes only bob-<name>; otherwise it blocks once and lets the agent go.
        # "bob-kotlin\n": Python's `$` matches before a trailing newline; bob-core's JavaScript `$` does not.
        for pack in ("kotlin", "bob-", "Bob-kotlin", "bob_kotlin", "bob-kotlin:implementer", "bob-kotlin\n"):
            with self.subTest(pack):
                config = json.loads(json.dumps(GOOD))
                config["agents"]["backend-implementer"] = pack
                config["gates"][pack] = {"command": "x"}
                self.write(config)
                self.assertOneProblem("which bob-core rejects")

    def test_pack_names_bob_core_accepts_pass(self):
        config = json.loads(json.dumps(GOOD))
        config["agents"]["backend-implementer"] = "bob-kotlin-2"
        config["gates"]["bob-kotlin-2"] = {"command": "x"}
        self.write(config)
        self.assertEqual(self.problems(), [])

    def raw(self, name: str, text: bytes) -> None:
        (self.root / ".claude" / "agents" / f"{name}.md").write_bytes(text)

    def test_a_quoted_name_on_an_implementer_with_no_key_is_a_problem(self):
        # PR 320 review B2: the quotes must not hide the implementer suffix.
        self.write(GOOD)
        self.raw("mobile-implementer", b'---\nname: "mobile-implementer"\ndescription: x\n---\n')
        self.assertOneProblem("`mobile-implementer` is an implementer with no entry")

    def test_an_implementer_file_name_with_another_frontmatter_name_is_a_problem(self):
        self.write(GOOD)
        self.raw("mobile-implementer", b"---\nname: mobile-builder\ndescription: x\n---\n")
        self.assertOneProblem("is an implementer with no entry")

    def test_quotes_a_comment_and_a_bom_on_a_keyed_agent_pass(self):
        self.write(GOOD, {"reviewer": None})
        self.raw("backend-implementer", b"\xef\xbb\xbf---\nname: 'backend-implementer'  # the Kotlin one\n---\n")
        self.raw("web-implementer", b'---\nname: "web-implementer"\n---\n')
        self.assertEqual(self.problems(), [])

    def test_an_agent_file_that_is_not_utf8_is_a_problem_not_a_crash(self):
        self.write(GOOD)
        self.raw("designer", b"---\nname: designer\ndescription: caf\xe9\n---\n")
        self.assertOneProblem("designer.md is not UTF-8")

    def test_frontmatter_that_is_not_yaml_is_a_problem(self):
        self.write(GOOD)
        self.raw("designer", b"---\nname: [designer\n---\n")
        self.assertOneProblem("frontmatter is not valid YAML")

    def test_a_missing_handback_is_a_problem(self):
        config = json.loads(json.dumps(GOOD))
        del config["handback"]
        self.write(config)
        self.assertOneProblem("`handback` must be a non-empty string")

    def test_a_string_gate_is_refused_as_munserv_rule(self):
        config = json.loads(json.dumps(GOOD))
        config["gates"]["bob-react"] = "cd web && pnpm test:run"
        self.write(config)
        self.assertOneProblem("munserv's rule")

    def test_the_repo_itself_passes(self):
        self.assertEqual(check.problems(ROOT), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
