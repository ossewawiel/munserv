#!/usr/bin/env python3
"""Regenerate the Status column of specs/requirements/*.md from GitHub issue state.

A story row that links an issue (`[#12](...)`) shows 🟢 Done when the issue is closed and
🔴 Pending when it is open. Rows without an issue link are left as written.

Usage:
  python3 scripts/render-requirements.py           rewrite the files
  python3 scripts/render-requirements.py --check   change nothing; exit 1 when a Status has drifted
  python3 scripts/render-requirements.py --check --changed-since REF
                                                   the same, for rows the branch changed since REF only

CI uses --changed-since: an issue closing elsewhere must not turn an unrelated PR red. The factory
tick runs the whole check and pushes a branch that brings the other rows back in step.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REQUIREMENTS = ROOT / "specs/requirements"
ISSUE_LIMIT = 2000
STATUS_BY_STATE = {"CLOSED": "🟢 Done", "OPEN": "🔴 Pending"}

ROW = re.compile(r"^(\| .* \| )(🟢 Done|🔴 Pending)( \| \[#(\d+)\]\([^)]*\) \|)$")
ID_CELL = re.compile(r"^\| ([^ |]+) \|")


def issue_states() -> dict[int, str]:
    out = subprocess.run(
        ["gh", "issue", "list", "--state", "all", "--limit", str(ISSUE_LIMIT), "--json", "number,state"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout
    return {item["number"]: item["state"] for item in json.loads(out)}


def changed_rows(ref: str) -> set[str]:
    """Lines the branch added or changed in the requirement files since `ref`."""
    out = subprocess.run(
        ["git", "diff", "-U0", f"{ref}...HEAD", "--", "specs/requirements"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout
    return {line[1:] for line in out.split("\n") if line.startswith("+") and not line.startswith("+++")}


def render(text: str, states: dict[int, str], name: str, only: set[str] | None = None) -> tuple[str, list[str]]:
    """The file with each row's Status from `states`, and the drift found. `only` limits both to those lines."""
    lines, drift = [], []
    for line in text.split("\n"):
        m = ROW.match(line)
        state = states.get(int(m.group(4))) if m else None
        wanted = STATUS_BY_STATE.get(state or "")
        if m and wanted and wanted != m.group(2) and (only is None or line in only):
            story = ID_CELL.match(line)
            drift.append(f"{name} {story.group(1) if story else '?'}: #{m.group(4)} is {state.lower()}, "
                         f"row says '{m.group(2)}', want '{wanted}'")
            line = f"{m.group(1)}{wanted}{m.group(3)}"
        lines.append(line)
    return "\n".join(lines), drift


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--changed-since", metavar="REF", help="with --check: only rows changed since REF")
    args = parser.parse_args(argv)
    if args.changed_since and not args.check:
        parser.error("--changed-since needs --check")
    only = changed_rows(args.changed_since) if args.changed_since else None
    if only is not None and not any(ROW.match(line) for line in only):
        print("no requirement rows changed")
        return 0
    states = issue_states()
    drift: list[str] = []
    for path in sorted(REQUIREMENTS.glob("*.md")):
        text = path.read_text()
        new, found = render(text, states, path.name, only)
        drift += found
        if new != text and not args.check:
            path.write_text(new)
    for d in drift:
        print(d)
    if args.check:
        print(f"{len(drift)} status rows drifted; run python3 scripts/render-requirements.py and commit"
              if drift else "requirements status matches GitHub")
        return 1 if drift else 0
    print(f"{len(drift)} status rows rewritten")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
