#!/usr/bin/env python3
"""Check that .bob/factory.json and .claude/agents/ agree, so no implementer runs without its gate.

bob-core (prject-bob) gates an agent at SubagentStop only when the agent's name is a key of the
`agents` map in .bob/factory.json, and only with the gate of the pack that key names. Three slips make
an implementer finish ungated, and none of them fails a build:
  - a key with no .claude/agents/<key>.md (a renamed or deleted agent): the gate guards a name that is
    never dispatched;
  - an agent file whose name ends in "implementer" with no key: bob-core never gates it;
  - a key whose pack has no gate, or a gate with no command.
  - a pack name bob-core rejects (it accepts only ^bob-[a-z0-9]+(-[a-z0-9]+)*$, gate-core.mjs PACK_NAME):
    bob-core then blocks once with an error and lets the agent go on the next stop, so the gate never runs.
Also checked: the file parses, `agents` is a non-empty map of strings, `handback` is a non-empty string
(munserv's agents end a hand-back with `BLOCKED:`; without it a hand-back is blocked once), every gate is
an object with a string `command` and at most a string `commandWindows` (munserv's rule: bob-core also
takes a plain string, but munserv keeps a POSIX and a Windows form), and each agent file's frontmatter
`name:` (read as YAML) matches its file name. An agent file is an implementer when either its file name
or its frontmatter name ends in "implementer".

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

import yaml

PACK_NAME = re.compile(r"^bob-[a-z0-9]+(?:-[a-z0-9]+)*$")


class Unreadable(Exception):
    pass


def frontmatter_name(path: Path) -> str | None:
    """The frontmatter `name:` as YAML reads it (quotes, comments and a BOM handled); None if absent."""
    try:
        text = path.read_text(encoding="utf-8-sig")
    except UnicodeDecodeError as e:
        raise Unreadable(f"{path.name} is not UTF-8 ({e.reason})") from e
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    try:
        meta = yaml.safe_load(text[3:end if end != -1 else len(text)])
    except yaml.YAMLError as e:
        raise Unreadable(f"{path.name}: frontmatter is not valid YAML ({e.__class__.__name__})") from e
    name = meta.get("name") if isinstance(meta, dict) else None
    return name if isinstance(name, str) else None


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
    if not isinstance(config.get("handback"), str) or not config["handback"].strip():
        found.append(".bob/factory.json: `handback` must be a non-empty string (munserv's agents hand back with `BLOCKED:`)")

    names: dict[Path, str | None] = {}
    if agents_dir.is_dir():
        for md in sorted(agents_dir.glob("*.md")):
            try:
                names[md] = frontmatter_name(md)
            except Unreadable as e:
                found.append(f".claude/agents/{e}")
                names[md] = None

    for agent, pack in agents.items():
        if not isinstance(pack, str) or not pack:
            found.append(f".bob/factory.json: agent `{agent}` must name a pack (a string), not {pack!r}")
            continue
        if not PACK_NAME.match(pack):
            found.append(f".bob/factory.json: agent `{agent}` names pack `{pack}`, which bob-core rejects (it takes only bob-<name>); the gate would never run")
        md = agents_dir / f"{agent}.md"
        if not md.is_file():
            found.append(f".bob/factory.json: agent `{agent}` has no .claude/agents/{agent}.md, so its gate guards a name nobody dispatches")
        elif md in names and names[md] != agent:
            found.append(f".claude/agents/{agent}.md: frontmatter `name:` is {names[md]!r}, not `{agent}`")
        if pack not in gates:
            found.append(f".bob/factory.json: agent `{agent}` names pack `{pack}`, which has no entry in `gates`")

    for pack, gate in gates.items():
        if not isinstance(gate, dict):
            found.append(f".bob/factory.json: gate `{pack}` must be an object with `command` and `commandWindows` (munserv's rule; bob-core also takes a plain string)")
            continue
        if not isinstance(gate.get("command"), str) or not gate["command"].strip():
            found.append(f".bob/factory.json: gate `{pack}` has no `command`")
        if "commandWindows" in gate and (not isinstance(gate["commandWindows"], str) or not gate["commandWindows"].strip()):
            found.append(f".bob/factory.json: gate `{pack}`: `commandWindows` must be a non-empty string")

    for md, name in names.items():
        candidates = {md.stem} | ({name} if name else set())
        if any(c.endswith("implementer") for c in candidates) and not candidates & set(agents):
            shown = name or md.stem
            found.append(f".claude/agents/{md.name}: `{shown}` is an implementer with no entry in .bob/factory.json `agents`, so bob-core never gates it")
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
