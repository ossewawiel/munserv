#!/usr/bin/env python3
"""Lint story handoffs and the CLAUDE.md cards.

A story handoff needs valid front matter (a status from STATUSES, the template's value types),
every section of `_template/story-handoff.md`, and at most MAX_HANDOFF_LINES lines. Every
CLAUDE.md card has at most MAX_CARD_LINES lines.

A handoff with `ui: true` or `user_facing: true` needs an Eyeball block the console can run:
a fenced yaml list of 2 to 6 checks, each with the template's keys, a real account and real
services, and a `covers` list naming the acceptance criteria it proves. Together the checks
cover every criterion, except the ones listed in the front matter's `eyeball_exempt`.

Usage:
  python3 scripts/lint-handoffs.py PATH...              lint these handoffs
  python3 scripts/lint-handoffs.py --cards              lint the CLAUDE.md cards
  python3 scripts/lint-handoffs.py --changed-since REF  lint handoffs added since REF (handoffs
                                                        written before `covers` existed are not linted)

Exit 0 when every linted handoff passes, 1 otherwise.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
ACCOUNTS = ROOT / "scripts/console/accounts.yaml"
SERVICES = ROOT / "scripts/console/services.yaml"
FEATURES = "specs/features/"
SKIPPED_DIRS = ("/_template/", "/completed/", "/archive/")
REQUIRED_KEYS = ("id", "title", "as", "services", "url", "steps", "expect", "covers")
TEMPLATE = ROOT / "specs/features/_template/story-handoff.md"
STATUSES = ("pending", "in_progress", "completed", "blocked")
PLATFORMS = ("backend", "web", "mobile", "infra")
MAX_HANDOFF_LINES = 120
MAX_CARD_LINES = 80
LIST_KEYS = ("depends_on", "touches", "eyeball_exempt", "design_artboards", "files_changed", "tests_added")
BOOL_KEYS = ("ui", "user_facing", "design_approved")
MIN_CHECKS = 2
MAX_CHECKS = 6

FRONT_MATTER = re.compile(r"\A---\n(.*?)\n---\n(.*)\Z", re.S)
EYEBALL = re.compile(r"^## Eyeball\b(.*?)(?=^## |\Z)", re.S | re.M)
YAML_FENCE = re.compile(r"```yaml\n(.*?)\n```", re.S)
AC_SECTION = re.compile(r"^## Acceptance criteria\b(.*?)(?=^## |\Z)", re.S | re.M)
AC_ITEM = re.compile(r"^(?:- \[[ xX]\] |- |\d+\. )\S", re.M)
HEADING = re.compile(r"^## (.+?)\s*$", re.M)
AC_REF = re.compile(r"\A(?:AC)?(\d+)\Z", re.I)


def load_keys(path: Path) -> set[str]:
    data = yaml.safe_load(path.read_text()) or {}
    return set(data) if isinstance(data, dict) else set()


def ac_number(ref: object) -> int | None:
    m = AC_REF.match(str(ref).strip())
    return int(m.group(1)) if m else None


def lint_checks(checks: object, ac_count: int, exempt: set[int], platform: str,
                accounts: set[str], services: set[str]) -> list[str]:
    if not isinstance(checks, list) or not all(isinstance(c, dict) for c in checks):
        return ["Eyeball yaml is not a list of mappings"]
    problems = []
    if not MIN_CHECKS <= len(checks) <= MAX_CHECKS:
        problems.append(f"Eyeball has {len(checks)} checks; write {MIN_CHECKS} to {MAX_CHECKS}")
    covered: set[int] = set()
    seen_ids: set[str] = set()
    for check in checks:
        cid = str(check.get("id", "?"))
        if cid in seen_ids:
            problems.append(f"{cid}: duplicate id")
        seen_ids.add(cid)
        missing = [k for k in REQUIRED_KEYS if k not in check]
        if missing:
            problems.append(f"{cid}: missing {', '.join(missing)}")
        who = check.get("as")
        if who is not None and who != "none" and who not in accounts:
            problems.append(f"{cid}: as '{who}' is not a key in scripts/console/accounts.yaml")
        for svc in check.get("services") or []:
            if svc not in services:
                problems.append(f"{cid}: service '{svc}' is not in scripts/console/services.yaml")
        url = str(check.get("url", ""))
        if url and platform != "mobile" and not url.startswith(("http://", "https://")):
            problems.append(f"{cid}: url '{url}' is not a complete address")
        steps = check.get("steps")
        if "steps" in check and (not isinstance(steps, list) or not steps):
            problems.append(f"{cid}: steps is not a non-empty list")
        refs = check.get("covers")
        if "covers" in check:
            if not isinstance(refs, list) or not refs:
                problems.append(f"{cid}: covers is not a non-empty list of AC numbers")
                continue
            for ref in refs:
                n = ac_number(ref)
                if n is None or not 1 <= n <= ac_count:
                    problems.append(f"{cid}: covers '{ref}' is not an acceptance criterion (1-{ac_count})")
                else:
                    covered.add(n)
    uncovered = sorted(set(range(1, ac_count + 1)) - covered - exempt)
    if uncovered:
        names = ", ".join(f"AC{n}" for n in uncovered)
        problems.append(f"no check covers {names}; add a check or list it in eyeball_exempt")
    return problems


def template_sections() -> list[str]:
    """Headings every handoff needs: the template's, minus Eyeball and the ui-only Visual."""
    names = HEADING.findall(FRONT_MATTER.match(TEMPLATE.read_text()).group(2))
    return [n for n in names if not n.startswith(("Eyeball", "Visual"))]


def lint_structure(meta: dict, body: str, line_count: int, sections: list[str]) -> list[str]:
    problems = []
    if not isinstance(meta.get("issue"), int) or isinstance(meta.get("issue"), bool):
        problems.append("front matter: issue is not a number")
    if not isinstance(meta.get("story"), str) or not meta["story"]:
        problems.append("front matter: story is not a story id")
    if meta.get("platform") not in PLATFORMS:
        problems.append(f"front matter: platform '{meta.get('platform')}' is not one of {', '.join(PLATFORMS)}")
    if meta.get("status") not in STATUSES:
        problems.append(f"front matter: status '{meta.get('status')}' is not one of {', '.join(STATUSES)}")
    for key in LIST_KEYS:
        if key in meta and not isinstance(meta[key], list):
            problems.append(f"front matter: {key} is not a list")
    for key in BOOL_KEYS:
        if key in meta and not isinstance(meta[key], bool):
            problems.append(f"front matter: {key} is not true or false")
    have = {h.split(" (")[0] for h in HEADING.findall(body)}
    for name in sections + (["Visual"] if meta.get("ui") is True else []):
        if name.split(" (")[0] not in have:
            problems.append(f"missing section ## {name.split(' (')[0]}")
    if line_count > MAX_HANDOFF_LINES:
        problems.append(f"{line_count} lines; keep a handoff to {MAX_HANDOFF_LINES} (split the story)")
    return problems


def lint_handoff(path: Path, accounts: set[str], services: set[str]) -> list[str]:
    text = path.read_text()
    m = FRONT_MATTER.match(text)
    if not m:
        return []
    try:
        meta = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError as e:
        return [f"front matter is not valid yaml: {e}"]
    if not isinstance(meta, dict) or "story" not in meta:
        return []
    body = m.group(2)
    problems = lint_structure(meta, body, len(text.splitlines()), template_sections())
    return problems + lint_eyeball(meta, body, accounts, services)


def lint_eyeball(meta: dict, body: str, accounts: set[str], services: set[str]) -> list[str]:
    if meta.get("ui") is not True and meta.get("user_facing") is not True:
        return []
    section = EYEBALL.search(body)
    if not section:
        return ["ui or user_facing is true but there is no ## Eyeball section"]
    fence = YAML_FENCE.search(section.group(1))
    if not fence:
        return ["## Eyeball has no ```yaml block; the console reads only that (prose gives zero checks)"]
    try:
        checks = yaml.safe_load(fence.group(1))
    except yaml.YAMLError as e:
        return [f"Eyeball yaml does not parse: {e}"]
    ac = AC_SECTION.search(body)
    ac_count = len(AC_ITEM.findall(ac.group(1))) if ac else 0
    if ac_count == 0:
        return ["no acceptance criteria found under ## Acceptance criteria"]
    raw_exempt = meta.get("eyeball_exempt") or []
    exempt = {n for n in (ac_number(r) for r in raw_exempt) if n is not None}
    return lint_checks(checks, ac_count, exempt, str(meta.get("platform", "")), accounts, services)


def lint_cards() -> list[str]:
    cards = [p for p in ROOT.glob("*/CLAUDE.md")] + [ROOT / "CLAUDE.md"]
    problems = []
    for card in sorted(cards):
        n = len(card.read_text().splitlines())
        if n > MAX_CARD_LINES:
            problems.append(f"{card.relative_to(ROOT)}: {n} lines; keep a card to {MAX_CARD_LINES}")
    return problems


def is_handoff_path(rel: str) -> bool:
    return rel.startswith(FEATURES) and rel.endswith(".md") and not any(d in "/" + rel for d in SKIPPED_DIRS)


def changed_since(ref: str) -> list[Path]:
    out = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=A", f"{ref}...HEAD", "--", FEATURES],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout
    return [ROOT / rel for rel in out.split() if is_handoff_path(rel)]


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--changed-since", metavar="REF")
    parser.add_argument("--cards", action="store_true", help="lint the CLAUDE.md cards")
    args = parser.parse_args(argv)
    paths = list(args.paths)
    if args.changed_since:
        paths += changed_since(args.changed_since)
    accounts, services = load_keys(ACCOUNTS), load_keys(SERVICES)
    failed = 0
    if args.cards:
        card_problems = lint_cards()
        for p in card_problems:
            print(f"FAIL {p}")
        failed += len(card_problems)
    for path in paths:
        problems = lint_handoff(path, accounts, services)
        shown = path.resolve().relative_to(ROOT) if path.resolve().is_relative_to(ROOT) else path
        if problems:
            failed += 1
            print(f"FAIL {shown}")
            for p in problems:
                print(f"  - {p}")
        else:
            print(f"ok   {shown}")
    print(f"{len(paths)} handoffs linted, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
