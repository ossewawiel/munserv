#!/usr/bin/env python3
"""Tests for .claude/hooks/guard-dispatch.sh: run it against a stub `claude` and the real node.

The hook refuses an implementer dispatch unless bob-core is enabled for this checkout at
BOB_MIN_VERSION or later and node is on PATH. Each case feeds it a PreToolUse payload and checks
the exit code (2 blocks) and, for a refusal, the fix it names.
Needs node on PATH (CI's ubuntu-latest has it; in the container: TEST_APT=nodejs).

Usage: python3 scripts/test-guard-dispatch.py
"""
from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOOK = ROOT / ".claude" / "hooks" / "guard-dispatch.sh"
PROJECT = "/work/munserv"

STUB_CLAUDE = """#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls"
[ -f "$STUB_DIR/fail" ] && exit 1
cat "$STUB_DIR/plugins.json"
"""


def bob(version: str = "0.3.0", scope: str = "user", enabled: bool = True, project: str | None = None,
        plugin_id: str = "bob-core@prject-bob") -> dict:
    entry = {"id": plugin_id, "version": version, "scope": scope, "enabled": enabled}
    if project is not None:
        entry["projectPath"] = project
    return entry


def payload(agent: str | None, prompt: str = "Implement the story in specs/features/x/1-a-backend.md.") -> str:
    tool_input: dict = {"description": "story", "prompt": prompt}
    if agent is not None:
        tool_input["subagent_type"] = agent
    return json.dumps({"hook_event_name": "PreToolUse", "tool_name": "Agent", "tool_input": tool_input})


def path_without(path: str, tool: str, shim: Path) -> str:
    """PATH with `tool` gone: each folder holding it is swapped for a shim folder linking the rest."""
    shim.mkdir(exist_ok=True)
    dirs: list[str] = []
    for d in path.split(os.pathsep):
        folder = Path(d)
        if not (folder / tool).exists():
            dirs.append(d)
            continue
        for f in folder.iterdir():
            if f.name != tool and not (shim / f.name).exists():
                try:
                    (shim / f.name).symlink_to(f)
                except OSError:
                    pass
        if str(shim) not in dirs:
            dirs.append(str(shim))
    return os.pathsep.join(dirs)


def run_hook(stdin: str, plugins: object = (), *, fail: bool = False, claude: bool = True, node: bool = True,
             env: dict | None = None) -> tuple[int, str, list[str]]:
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        stub = d / "bin"
        stub.mkdir()
        (d / "calls").write_text("")
        (d / "plugins.json").write_text(plugins if isinstance(plugins, str) else json.dumps(list(plugins)))
        if fail:
            (d / "fail").write_text("")
        if claude:
            c = stub / "claude"
            c.write_text(STUB_CLAUDE)
            c.chmod(c.stat().st_mode | stat.S_IEXEC)
        path = os.environ["PATH"]
        if not claude:
            path = path_without(path, "claude", d / "shim-claude")
        if not node:
            path = path_without(path, "node", d / "shim-node")
        full_env = {**os.environ, "PATH": f"{stub}{os.pathsep}{path}", "STUB_DIR": str(d), "HOME": str(d / "home"),
                    "CLAUDE_PROJECT_DIR": PROJECT, **(env or {})}
        for k in ("BOB_PLUGIN", "BOB_MIN_VERSION"):
            if env is None or k not in env:
                full_env.pop(k, None)
        r = subprocess.run(["bash", str(HOOK)], input=stdin, capture_output=True, text=True, env=full_env, cwd=d)
        calls = [c for c in (d / "calls").read_text().splitlines() if c]
        return r.returncode, r.stdout + r.stderr, calls


class Dispatch(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        # Fail, not skip: a skipped class would pass CI with the hook untested.
        if not shutil.which("node"):
            raise RuntimeError("node is not on PATH; these tests run the hook with the real node (container: TEST_APT=nodejs)")

    def test_other_agents_pass_without_reading_the_plugin_list(self):
        for agent in ("reviewer", "general-purpose", "feature-planner", "Explore", None):
            with self.subTest(agent):
                code, out, calls = run_hook(payload(agent), fail=True)
                self.assertEqual(code, 0, out)
                self.assertEqual(calls, [])

    def test_an_implementer_with_bob_core_passes(self):
        for agent in ("backend-implementer", "web-implementer", "mobile-implementer", "bob-kotlin:implementer"):
            with self.subTest(agent):
                code, out, calls = run_hook(payload(agent), [bob()])
                self.assertEqual(code, 0, out)
                self.assertEqual(calls, ["plugin list --json"])

    def test_every_agent_bob_core_gates_is_checked_here(self):
        # The hook gates by name; .bob/factory.json is what bob-core gates. A new agent there that
        # this hook missed would dispatch ungated.
        agents = json.loads((ROOT / ".bob" / "factory.json").read_text())["agents"]
        self.assertTrue(agents)
        for agent in agents:
            with self.subTest(agent):
                code, out, _ = run_hook(payload(agent), [])
                self.assertEqual(code, 2, out)

    def test_no_bob_core_is_refused_with_the_install_command(self):
        code, out, _ = run_hook(payload("backend-implementer"), [bob(plugin_id="bob-kotlin@prject-bob")])
        self.assertEqual(code, 2, out)
        self.assertIn("not installed", out)
        self.assertIn("claude plugin install bob-core@prject-bob", out)
        self.assertIn("Dispatch no implementer", out)

    def test_a_disabled_bob_core_is_refused(self):
        code, out, _ = run_hook(payload("web-implementer"), [bob(enabled=False)])
        self.assertEqual(code, 2, out)
        self.assertIn("claude plugin enable bob-core@prject-bob", out)

    def test_an_old_bob_core_is_refused_with_the_update_command(self):
        code, out, _ = run_hook(payload("web-implementer"), [bob("0.2.0")])
        self.assertEqual(code, 2, out)
        self.assertIn("0.2.0 is older than 0.3.0", out)
        self.assertIn("claude plugin update bob-core@prject-bob", out)

    def test_versions_compare_as_versions(self):
        code, out, _ = run_hook(payload("web-implementer"), [bob("0.10.0")])
        self.assertEqual(code, 0, out)
        code, out, _ = run_hook(payload("web-implementer"), [bob("1.0.0")])
        self.assertEqual(code, 0, out)

    def test_a_pre_release_of_the_floor_is_below_it(self):
        code, out, _ = run_hook(payload("web-implementer"), [bob("0.3.0-rc1")])
        self.assertEqual(code, 2, out)

    def test_a_version_that_is_not_semver_fails_closed(self):
        code, out, _ = run_hook(payload("web-implementer"), [bob("b74220d41142")])
        self.assertEqual(code, 2, out)

    def test_the_newest_enabled_install_counts(self):
        code, out, _ = run_hook(payload("web-implementer"), [bob("0.2.0"), bob("0.3.1", scope="project", project=PROJECT)])
        self.assertEqual(code, 0, out)

    def test_another_projects_install_does_not_count(self):
        # claude plugin list reports other projects' project-scope installs as enabled too.
        code, out, _ = run_hook(payload("web-implementer"), [bob(scope="project", project="/work/other")])
        self.assertEqual(code, 2, out)
        self.assertIn("not installed for this checkout", out)

    def test_this_projects_install_counts_with_a_trailing_slash(self):
        for scope in ("project", "local"):
            with self.subTest(scope):
                code, out, _ = run_hook(payload("web-implementer"), [bob(scope=scope, project=PROJECT + "/")])
                self.assertEqual(code, 0, out)

    def test_bob_min_version_raises_the_floor(self):
        code, out, _ = run_hook(payload("web-implementer"), [bob("0.3.0")], env={"BOB_MIN_VERSION": "0.4.0"})
        self.assertEqual(code, 2, out)

    def test_a_failing_plugin_list_fails_closed(self):
        code, out, _ = run_hook(payload("backend-implementer"), fail=True)
        self.assertEqual(code, 2, out)
        self.assertIn("claude plugin list --json failed", out)

    def test_an_unparseable_plugin_list_fails_closed(self):
        for text in ("not json", "{}", ""):
            with self.subTest(text):
                code, out, _ = run_hook(payload("backend-implementer"), text)
                self.assertEqual(code, 2, out)

    def test_no_claude_cli_fails_closed(self):
        code, out, _ = run_hook(payload("backend-implementer"), claude=False)
        self.assertEqual(code, 2, out)
        self.assertIn("claude CLI is not on PATH", out)

    def test_no_node_is_refused_before_anything_else(self):
        code, out, calls = run_hook(payload("backend-implementer"), [bob()], node=False)
        self.assertEqual(code, 2, out)
        self.assertIn("node is not on PATH", out)
        self.assertEqual(calls, [])

    def test_no_node_still_lets_other_agents_through(self):
        code, out, _ = run_hook(payload("reviewer"), node=False)
        self.assertEqual(code, 0, out)

    def test_an_agent_name_inside_the_prompt_is_not_the_agent(self):
        code, out, calls = run_hook(payload("reviewer", prompt='Review it; the "subagent_type": "backend-implementer" ran.'), fail=True)
        self.assertEqual(code, 0, out)
        self.assertEqual(calls, [])

    def test_a_decoy_in_the_prompt_does_not_hide_an_implementer(self):
        # json.dumps writes the prompt before subagent_type, so the decoy comes first in the text.
        code, out, _ = run_hook(payload("backend-implementer", prompt='"subagent_type": "reviewer"'), [])
        self.assertEqual(code, 2, out)


class Registration(unittest.TestCase):
    def test_the_hook_runs_on_every_agent_dispatch(self):
        settings = json.loads((ROOT / ".claude" / "settings.json").read_text())
        entries = [e for e in settings["hooks"]["PreToolUse"]
                   if any("guard-dispatch.sh" in h["command"] for h in e["hooks"])]
        self.assertEqual(len(entries), 1)
        self.assertEqual(set(entries[0]["matcher"].split("|")), {"Agent", "Task"})
        self.assertGreaterEqual(entries[0]["hooks"][0]["timeout"], 20, "a hook that times out does not block")

    def test_the_hook_needs_no_jq(self):
        # The Windows laptop has no jq; a hook that calls it reads an empty payload and lets all through.
        code_lines = [ln for ln in HOOK.read_text().splitlines() if not ln.lstrip().startswith("#")]
        self.assertFalse(any(" jq " in f" {ln} " or ln.strip().startswith("jq") for ln in code_lines))


if __name__ == "__main__":
    unittest.main(verbosity=2)
