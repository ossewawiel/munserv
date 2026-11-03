#!/usr/bin/env python3
"""Check the pure parts of scripts/retro-gather.py: verdict extraction, BLOCKED lines, ledger spend,
CI log de-duplication and body quoting. No gh calls. Exit 1 if any case fails."""
from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("retro_gather", ROOT / "scripts" / "retro-gather.py")
if spec is None or spec.loader is None:
    sys.exit("cannot load scripts/retro-gather.py")
rg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rg)


def case_verdicts() -> list[str]:
    pr = {
        "reviews": [{"submittedAt": "2026-11-01T10:00:00Z", "body": "## Review\nFindings\n\nREQUEST CHANGES"}],
        "comments": [
            {"createdAt": "2026-11-01T09:00:00Z", "body": "Design review: one artboard differs\n\nAPPROVE"},
            {"createdAt": "2026-11-01T11:00:00Z", "body": "CI is green"},
        ],
    }
    got = [(v["kind"], v["verdict"]) for v in rg.verdicts(pr)]
    return [] if got == [("design", "APPROVE"), ("code", "REQUEST CHANGES")] else [f"verdicts {got}"]


def case_blocked_lines() -> list[str]:
    got = rg.blocked_lines("Done some work\nBLOCKED: the handoff names a missing table\nnot blocked")
    return [] if got == ["BLOCKED: the handoff names a missing table"] else [f"blocked lines {got}"]


def case_ledger_spend() -> list[str]:
    rows = [
        {"date": "2026-10-01", "kind": "story", "story": 1, "total_cost_usd": 9},
        {"date": "2026-11-02", "kind": "story", "story": 149, "total_cost_usd": 1.45},
        {"date": "2026-11-02", "kind": "select", "total_cost_usd": 0.05},
        {"date": "2026-11-03", "kind": "story", "story": 150, "total_cost_usd": 5, "subtype": "error_max_budget_usd"},
    ]
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "ticks.jsonl"
        path.write_text("".join(json.dumps(r) + "\n" for r in rows) + "not json\n")
        spend = rg.ledger_spend(path, "2026-11-01")
    return [e for e in [
        round(spend["total"], 2) != 6.5 and f"total {spend['total']}, want 6.5",
        dict(spend["story"]) != {"149": 1.45, "150": 5.0} and f"stories {dict(spend['story'])}",
        spend["capped"] != ["#150 error_max_budget_usd on 2026-11-03"] and f"capped {spend['capped']}",
    ] if isinstance(e, str)]


def case_log_key() -> list[str]:
    a = ["web\tLint\t2026-11-01T10:00:00.1234567Z error  'x' is unused"]
    b = ["web\tLint\t2026-11-02T08:30:12.0000001Z error  'x' is unused"]
    c = ["web\tLint\t2026-11-02T08:30:12.0000001Z error  'y' is unused"]
    return [e for e in [
        rg.log_key(a) != rg.log_key(b) and "same failure on two days does not match",
        rg.log_key(a) == rg.log_key(c) and "different failures match",
    ] if isinstance(e, str)]


def case_clip_quotes() -> list[str]:
    got = rg.clip("## Heading\n\nbody", 1000)
    long = rg.clip("x" * 50, 10)
    return [e for e in [
        got != "> ## Heading\n>\n> body" and f"quoted {got!r}",
        not long.endswith("> [... clipped]") and f"clipped {long!r}",
    ] if isinstance(e, str)]


def case_sizes() -> list[str]:
    names = [name for name, _, _ in rg.sizes(ROOT)]
    return [e for e in [
        "CLAUDE.md" not in names and "root card missing",
        ".claude/skills/factory-retro/SKILL.md" not in names and "retro skill missing",
        any("worktrees" in n for n in names) and "agent worktrees counted",
    ] if isinstance(e, str)]


CASES = [
    ("verdicts are tagged code or design, oldest first", case_verdicts),
    ("BLOCKED lines are picked out of a report", case_blocked_lines),
    ("ledger spend counts only the window and flags capped runs", case_ledger_spend),
    ("a CI failure rerun on another day matches its first run", case_log_key),
    ("bodies are quoted and clipped", case_clip_quotes),
    ("sizes cover cards and skills, not worktrees", case_sizes),
]


def main() -> int:
    failures = 0
    for name, check in CASES:
        errors = check()
        failures += bool(errors)
        print(f"{'FAIL' if errors else 'ok  '}  {name}" + "".join(f"\n      {e}" for e in errors))
    print(f"{len(CASES) - failures}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
