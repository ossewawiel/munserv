#!/usr/bin/env python3
"""Run the guard-git hook against .claude/hooks/tests/guard-git-cases.txt.

Case file format: `<expected exit>\t<command>`; a case may continue over following
lines (heredocs) until the next line that starts with a digit and a tab.
Each case runs twice: with jq, and with jq hidden so the guard falls back to node, as on the
Windows laptop. Then the fail-closed cases: no parser, or input that does not parse, refuses.
Needs jq and node on PATH (CI has both; in the container: TEST_APT=nodejs).
Exit 1 if any case returns a different exit code.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOOK = ROOT / ".claude" / "hooks" / "guard-git.sh"
CASES = ROOT / ".claude" / "hooks" / "tests" / "guard-git-cases.txt"


def parse(text: str) -> list[tuple[int, str, str]]:
    """Each case is `<exit>\t<command>` or `<exit>\t<branch>\t<command>` (branch defaults to a feature branch)."""
    entries: list[list] = []
    for line in text.split("\n"):
        if len(line) > 1 and line[0].isdigit() and line[1] == "\t":
            parts = line[2:].split("\t", 1)
            branch, cmd = (parts[0], parts[1]) if len(parts) == 2 else ("feat/hook-test", parts[0])
            entries.append([int(line[0]), branch, cmd])
        elif entries:
            entries[-1][2] += "\n" + line
    return [(e[0], e[1], e[2].rstrip("\n")) for e in entries]


def path_without(path: str, tools: tuple[str, ...], shim: Path) -> str:
    """PATH with `tools` gone: each folder holding one is swapped for a shim folder linking the rest."""
    shim.mkdir(exist_ok=True)
    dirs: list[str] = []
    for d in path.split(os.pathsep):
        folder = Path(d)
        if not any((folder / t).exists() for t in tools):
            dirs.append(d)
            continue
        for f in folder.iterdir():
            if f.name not in tools and not (shim / f.name).exists():
                try:
                    (shim / f.name).symlink_to(f)
                except OSError:
                    pass
        if str(shim) not in dirs:
            dirs.append(str(shim))
    return os.pathsep.join(dirs)


def run(stdin: str, branch: str, path: str) -> subprocess.CompletedProcess:
    # Pin the branch context, whatever CI checked out.
    env = {**os.environ, "GUARD_GIT_BRANCH": branch, "PATH": path}
    return subprocess.run(["bash", str(HOOK)], input=stdin, capture_output=True, text=True, cwd=ROOT, env=env)


def main() -> int:
    for tool in ("jq", "node"):
        if not shutil.which(tool):
            print(f"FAIL {tool} is not on PATH; these tests run the guard with jq and with its node fallback"
                  " (container: TEST_APT=nodejs)")
            return 1
    failures = 0
    cases = parse(CASES.read_text())
    with tempfile.TemporaryDirectory() as tmp:
        full = os.environ["PATH"]
        no_jq = path_without(full, ("jq",), Path(tmp) / "no-jq")
        neither = path_without(full, ("jq", "node"), Path(tmp) / "neither")
        # Every case, read by jq and then by the node fallback the Windows laptop uses.
        for label, path in (("jq", full), ("node", no_jq)):
            for want, branch, cmd in cases:
                r = run(json.dumps({"tool_input": {"command": cmd}}), branch, path)
                ok = r.returncode == want
                failures += not ok
                print(("ok  " if ok else "FAIL"), f"[{label}] want={want} got={r.returncode}", cmd.splitlines()[0][:70])
        # Fail closed: an unreadable command is refused, never read as empty and allowed.
        closed = [
            ("no jq and no node refuses a harmless command", json.dumps({"tool_input": {"command": "ls"}}), neither),
            ("no jq and no node refuses a force push", json.dumps({"tool_input": {"command": "git push --force"}}), neither),
            ("jq refuses input that does not parse", "not json", full),
            ("node refuses input that does not parse", "not json", no_jq),
            ("node refuses empty input", "", no_jq),
        ]
        for name, stdin, path in closed:
            r = run(stdin, "feat/hook-test", path)
            ok = r.returncode == 2
            failures += not ok
            print(("ok  " if ok else "FAIL"), f"want=2 got={r.returncode}", name)
        r = run(json.dumps({"tool_input": {"command": "ls"}}), "feat/hook-test", neither)
        ok = "install jq" in r.stderr
        failures += not ok
        print(("ok  " if ok else "FAIL"), "the no-parser refusal names the fix")
    print(f"{failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
