#!/usr/bin/env python3
"""Run .claude/hooks/approve-retro-writes.sh against paths it must approve and paths it must leave to
the normal permission rules. Exit 1 if any case differs."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOOK = ROOT / ".claude" / "hooks" / "approve-retro-writes.sh"
PROJECT = "/work/munserv"
WT = f"{PROJECT}/.claude/worktrees/retro-2026-11-09"

CASES = [
    (True, f"{WT}/.claude/metrics/retro-2026-11-09.md"),
    (True, f"{WT}/.claude/metrics/last-retro"),
    (True, f"{WT}/.claude/skills/web-patterns/SKILL.md"),
    (True, f"{WT}/.claude/agents/reviewer.md"),
    (True, ".claude/worktrees/retro-2026-11-09/.claude/agents/reviewer.md"),
    (False, f"{WT}/.claude/settings.json"),
    (False, f"{WT}/.claude/hooks/guard-git.sh"),
    (False, f"{WT}/.claude/settings.local.json"),
    (False, f"{WT}/.claude/metrics/../settings.json"),
    (False, f"{WT}/.claude/skills/./../hooks/guard-git.sh"),
    (False, f"{PROJECT}/.claude/metrics/last-retro"),
    (False, f"{PROJECT}/.claude/worktrees/agent-abc/.claude/skills/x/SKILL.md"),
    (False, f"{PROJECT}/.claude/worktrees/retro-latest/.claude/skills/x/SKILL.md"),
    (False, f"/elsewhere{WT}/.claude/skills/x/SKILL.md"),
    (False, f"{WT}/scripts/lint-handoffs.py"),
    (False, ""),
]


def main() -> int:
    failures = 0
    env = {**os.environ, "CLAUDE_PROJECT_DIR": PROJECT}
    for want, path in CASES:
        r = subprocess.run([str(HOOK)], input=json.dumps({"tool_input": {"file_path": path}}),
                           capture_output=True, text=True, env=env)
        approved = '"allow"' in r.stdout
        ok = r.returncode == 0 and approved == want
        failures += not ok
        print(f"{'ok  ' if ok else 'FAIL'}  {'allow' if want else 'pass '}  {path or '(empty)'}"
              + ("" if ok else f"\n      exit {r.returncode}, stdout {r.stdout.strip()!r}"))
    print(f"{len(CASES) - failures}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
