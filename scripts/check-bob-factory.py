#!/usr/bin/env python3
"""Check that .bob/factory.json and .claude/agents/ agree, so no implementer runs without its gate.

bob-core (prject-bob) gates an agent at SubagentStop only when the agent's name is a key of the
`agents` map in .bob/factory.json, and only with the gate of the pack that key names. Three slips make
an implementer finish ungated, and none of them fails a build:
  - a key with no .claude/agents/<key>.md (a renamed or deleted agent): the gate guards a name that is
    never dispatched;
  - an agent file whose name ends in "implementer" with no key: bob-core never gates it;
  - a key whose pack has no gate, or a gate with no command.
Also checked: the file parses, `agents` is a non-empty map of strings, `handback` (when present) is a
non-empty string, every gate has a string `command` and at most a string `commandWindows`, and each
agent file's frontmatter `name:` matches its file name.

Retro 2026-11-19 (specs/metrics/retro-2026-11-19-bob-core-cutover.md); the PR #312 reviewer noted it
on both passes.

Usage: python3 scripts/check-bob-factory.py [repo root]
Exit 1 with one line per problem; exit 0 and a summary line when all agree.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

NAME = re.compile(r"^name:\s*(\S+)\s*$", re.MULTILINE)


def frontmatter_name(path: Path) -> str | None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    match = NAME.search(text[3:end if end != -1 else len(text)])
    return match.group(1) if match else None


def problems(root: Path) -> list[str]:
    factory = root / ".bob" / "factory.json"
    agents_dir = root / ".claude" / "agents"
    if not factory.is_file():
        return [f"{factory.relative_to(root)} is missing"]
    try:
        config = json.loads(factory.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f".bob/factory.json does not parse: {e}"]
    if not isinstance(config, dict):
        return [".bob/factory.json is not a JSON object"]

    found: list[str] = []
    agents = config.get("agents")
    gates = config.get("gates")
    if not isinstance(agents, dict) or not agents:
        found.append(".bob/factory.json: `agents` must be a non-empty object of agent name -> pack")
        agents = {}
    if not isinstance(gates, dict):
        found.append(".bob/factory.json: `gates` must be an object of pack -> gate")
        gates = {}
    if "handback" in config and (not isinstance(config["handback"], str) or not config["handback"].strip()):
        found.append(".bob/factory.json: `handback` must be a non-empty string")

    for agent, pack in agents.items():
        if not isinstance(pack, str) or not pack:
            found.append(f".bob/factory.json: agent `{agent}` must name a pack (a string), not {pack!r}")
            continue
        md = agents_dir / f"{agent}.md"
        if not md.is_file():
            found.append(f".bob/factory.json: agent `{agent}` has no .claude/agents/{agent}.md, so its gate guards a name nobody dispatches")
        elif frontmatter_name(md) != agent:
            found.append(f".claude/agents/{agent}.md: frontmatter `name:` is {frontmatter_name(md)!r}, not `{agent}`")
        if pack not in gates:
            found.append(f".bob/factory.json: agent `{agent}` names pack `{pack}`, which has no entry in `gates`")

    for pack, gate in gates.items():
        if not isinstance(gate, dict):
            found.append(f".bob/factory.json: gate `{pack}` must be an object with `command`")
            continue
        if not isinstance(gate.get("command"), str) or not gate["command"].strip():
            found.append(f".bob/factory.json: gate `{pack}` has no `command`")
        if "commandWindows" in gate and (not isinstance(gate["commandWindows"], str) or not gate["commandWindows"].strip()):
            found.append(f".bob/factory.json: gate `{pack}`: `commandWindows` must be a non-empty string")

    if agents_dir.is_dir():
        for md in sorted(agents_dir.glob("*.md")):
            name = frontmatter_name(md) or md.stem
            if name.endswith("implementer") and name not in agents:
                found.append(f".claude/agents/{md.name}: `{name}` is an implementer with no entry in .bob/factory.json `agents`, so bob-core never gates it")
    return found


def main(argv: list[str]) -> int:
    root = Path(argv[1]).resolve() if len(argv) > 1 else Path(__file__).resolve().parent.parent
    found = problems(root)
    for line in found:
        print(f"FAIL {line}")
    if found:
        return 1
    config = json.loads((root / ".bob" / "factory.json").read_text(encoding="utf-8"))
    print(f"ok   .bob/factory.json: {len(config['agents'])} agents, each with an agent file and a gate")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
