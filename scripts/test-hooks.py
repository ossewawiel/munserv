#!/usr/bin/env python3
"""Run the guard-git hook against .claude/hooks/tests/guard-git-cases.txt.

Case file format: `<expected exit>\t<command>`; a case may continue over following
lines (heredocs) until the next line that starts with a digit and a tab.
Exit 1 if any case returns a different exit code.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
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


def main() -> int:
    failures = 0
    for want, branch, cmd in parse(CASES.read_text()):
        env = {**os.environ, "GUARD_GIT_BRANCH": branch}  # pin the branch context, whatever CI checked out
        r = subprocess.run([str(HOOK)], input=json.dumps({"tool_input": {"command": cmd}}), capture_output=True, text=True, cwd=ROOT, env=env)
        ok = r.returncode == want
        failures += not ok
        print(("ok  " if ok else "FAIL"), f"want={want} got={r.returncode}", cmd.splitlines()[0][:70])
    print(f"{failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
