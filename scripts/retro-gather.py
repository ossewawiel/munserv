#!/usr/bin/env python3
"""Collect the evidence for the weekly factory retro (.claude/skills/factory-retro) as one Markdown
document on stdout: reviewer and design-reviewer verdicts on merged PRs, issues filed by the eyeball,
review and smoke gates, red CI runs with their failed-log tails, BLOCKED reasons, spend from the tick
ledger and the cost meter, and the size of every card, agent and skill.

Read-only. Run it from the checkout the tick uses: the tick ledger and the cost meter's data live
outside git, so a fresh worktree has neither.

Usage: python3 scripts/retro-gather.py [--since YYYY-MM-DD]
       --since defaults to the date in specs/metrics/last-retro.
Env:   MUNSERV_FACTORY_STATE (default ~/.local/state/munserv-factory)
Exit:  0, or 2 when no start date is given or found.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from scripts.console import cost  # noqa: E402
from scripts.console.config import CONFIG  # noqa: E402
from scripts.console.pipeline import _verdict  # noqa: E402

LAST_RETRO = ROOT / "specs" / "metrics" / "last-retro"
GATE_LABELS = ("source:eyeball", "source:review", "source:smoke")
MAX_PRS = 200
MAX_RED_RUNS = 30
LOG_TAIL_LINES = 30
BODY_LIMIT = 4000
TIMESTAMP_RE = re.compile(r"\d{4}-\d{2}-\d{2}T[\d:.]+Z ?")
BLOCKED_RE = re.compile(r"^.*\bBLOCKED:.*$", re.MULTILINE)
# The error line a guard prints when it holds a PR on purpose (ci-edit-guard.yml, infra-review-guard.yml,
# baseline-guard.yml). Matches the runtime output only: the script listing shows `::error::`, not `##[error]`.
HOLD_RE = re.compile(r"##\[error\](Held: |New commits arrived after the release)")
SIZE_GLOBS = ("CLAUDE.md", "*/CLAUDE.md", ".claude/agents/*.md", ".claude/skills/*/SKILL.md")


def gh_json(*args: str) -> list | dict:
    out = subprocess.run(["gh", *args], cwd=ROOT, text=True, capture_output=True)
    if out.returncode != 0:
        print(f"retro-gather: gh {' '.join(args[:3])} failed: {out.stderr.strip()[:200]}", file=sys.stderr)
        return []
    return json.loads(out.stdout or "[]")


def gh_text(*args: str) -> str:
    out = subprocess.run(["gh", *args], cwd=ROOT, text=True, capture_output=True)
    return out.stdout if out.returncode == 0 else f"(gh failed: {out.stderr.strip()[:200]})"


def clip(text: str, limit: int = BODY_LIMIT) -> str:
    """`text` cut to `limit` characters and quoted, so its own headings stay inside its section."""
    text = (text or "").strip()
    text = text if len(text) <= limit else text[:limit] + "\n[... clipped]"
    return "\n".join(f"> {line}" if line else ">" for line in text.splitlines())


def log_key(lines: list[str]) -> str:
    """A failed-log tail with job, step and timestamp columns dropped, so reruns of one failure match."""
    return "\n".join(TIMESTAMP_RE.sub("", line.split("\t")[-1]) for line in lines)


def is_hold(lines: list[str]) -> bool:
    """True when a failed-log tail is a guard holding a PR as designed, not a defect."""
    return any(HOLD_RE.search(line) for line in lines)


def verdicts(pr: dict) -> list[dict]:
    """Every review or comment on `pr` that names a verdict, oldest first, tagged code or design."""
    posts = [*pr.get("reviews", []), *pr.get("comments", [])]
    posts.sort(key=lambda p: p.get("submittedAt") or p.get("createdAt") or "")
    out = []
    for p in posts:
        body = p.get("body") or ""
        verdict = _verdict(body)
        if verdict:
            kind = "design" if body.strip().startswith("Design review:") else "code"
            out.append({"kind": kind, "verdict": verdict, "body": body})
    return out


def blocked_lines(text: str) -> list[str]:
    return [m.group(0).strip() for m in BLOCKED_RE.finditer(text or "")]


def ledger_spend(path: Path, since: str) -> dict:
    """Tick ledger rows on or after `since`: total, by kind, by story, and the runs that hit a cap."""
    totals = {"total": 0.0, "kind": defaultdict(float), "story": defaultdict(float), "capped": []}
    if not path.exists():
        return totals
    for line in path.read_text(errors="replace").splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(row, dict) or (row.get("date") or "") < since:
            continue
        amount = float(row.get("total_cost_usd") or 0)
        totals["total"] += amount
        totals["kind"][row.get("kind", "unknown")] += amount
        if "story" in row:
            totals["story"][str(row["story"])] += amount
        if str(row.get("subtype", "")).startswith("error_max"):
            totals["capped"].append(f"#{row.get('story')} {row['subtype']} on {row.get('date')}")
    return totals


def sizes(root: Path) -> list[tuple[str, int, int]]:
    rows = []
    for pattern in SIZE_GLOBS:
        for path in sorted(root.glob(pattern)):
            name = str(path.relative_to(root))
            if ".claude/worktrees" in name or "node_modules" in path.parts:
                continue
            text = path.read_text(errors="replace")
            rows.append((name, text.count("\n"), len(text.encode())))
    return rows


def section_reviews(since: str) -> list[str]:
    prs = gh_json("pr", "list", "--state", "merged", "--search", f"merged:>={since}", "--limit", str(MAX_PRS),
                  "--json", "number,title,mergedAt,headRefName,reviews,comments")
    out = [f"## Reviewer and design-reviewer verdicts on merged PRs ({len(prs)} merged since {since})", ""]
    for pr in sorted(prs, key=lambda p: p["number"]):
        found = verdicts(pr)
        if not found:
            continue
        out.append(f"### PR #{pr['number']} {pr['title']} (merged {pr['mergedAt'][:10]}, {pr['headRefName']})")
        for v in found:
            out += [f"**{v['kind']} review: {v['verdict']}**", "", clip(v["body"]), ""]
    no_review = [f"#{p['number']}" for p in prs if not verdicts(p)]
    out += [f"Merged with no verdict: {', '.join(no_review) or 'none'}", ""]
    return out


def section_gate_issues(since: str) -> list[str]:
    out = ["## Issues filed by the eyeball, review and smoke gates", ""]
    for label in GATE_LABELS:
        issues = gh_json("issue", "list", "--state", "all", "--label", label, "--search", f"created:>={since}",
                         "--limit", "100", "--json", "number,title,state,createdAt,body")
        out.append(f"### {label} ({len(issues)})")
        for i in sorted(issues, key=lambda x: x["number"]):
            out += [f"**#{i['number']} {i['title']}** ({i['state'].lower()}, {i['createdAt'][:10]})", "",
                    clip(i.get("body") or "", 1500), ""]
        out.append("")
    return out


def section_red_ci(since: str) -> list[str]:
    runs = gh_json("run", "list", "--status", "failure", "--created", f">={since}", "--limit", str(MAX_RED_RUNS),
                   "--json", "databaseId,workflowName,headBranch,event,createdAt,displayTitle")
    out = [f"## Red CI runs ({len(runs)}, newest first, at most {MAX_RED_RUNS}; identical log tails shown once)", ""]
    seen: dict[str, list[str]] = {}
    holds: dict[str, list[str]] = defaultdict(list)
    for run in runs:
        tail = gh_text("run", "view", str(run["databaseId"]), "--log-failed").splitlines()[-LOG_TAIL_LINES:]
        title = f"{run['workflowName']} on {run['headBranch']} ({run['event']}, {run['createdAt'][:10]}, run {run['databaseId']})"
        if is_hold(tail):
            holds[run["workflowName"]].append(f"{run['headBranch']} run {run['databaseId']}")
            continue
        key = log_key(tail)
        if key in seen:
            seen[key].append(title)
            continue
        seen[key] = []
        out += [f"### {title}: {run['displayTitle']}", "", "```", *tail, "```", ""]
    repeats = [f"- {t}" for titles in seen.values() for t in titles]
    out += ["Same log tail as a run above:", *repeats, ""] if repeats else []
    held = [f"- {name} ({len(items)}): {', '.join(items)}" for name, items in sorted(holds.items())]
    return out + (["Guard holds, as designed (not findings):", *held, ""] if held else [])


def section_blocked(since: str, state_dir: Path) -> list[str]:
    out = ["## BLOCKED reasons", ""]
    issues = gh_json("issue", "list", "--state", "all", "--search", f"BLOCKED in:comments updated:>={since}",
                     "--limit", "50", "--json", "number,title,comments")
    for i in issues:
        for c in i.get("comments", []):
            if (c.get("createdAt") or "") >= since:
                out += [f"- #{i['number']} {i['title']}: {line}" for line in blocked_lines(c.get("body", ""))]
    cutoff = datetime.fromisoformat(since).timestamp()
    runs_dir = state_dir / "runs"
    for path in sorted(runs_dir.glob("*.json")) if runs_dir.exists() else []:
        if path.stat().st_mtime < cutoff:
            continue
        try:
            result = json.loads(path.read_text()).get("result", "")
        except (json.JSONDecodeError, AttributeError):
            continue
        out += [f"- tick run {path.stem}: {line}" for line in blocked_lines(result)]
    for path in sorted((ROOT / "specs" / "features").glob("*/*.md")):
        if re.search(r"^status: blocked\s*$", path.read_text(errors="replace"), re.MULTILINE):
            out.append(f"- handoff {path.relative_to(ROOT)} has status: blocked")
    if len(out) == 2:
        out.append("None.")
    return out + [""]


def section_cost(since: str, state_dir: Path) -> list[str]:
    spend = ledger_spend(state_dir / "ticks.jsonl", since)
    out = ["## Spend", "", f"### Tick ledger: ${spend['total']:.2f} since {since}", ""]
    out += [f"- {kind}: ${amount:.2f}" for kind, amount in sorted(spend["kind"].items())]
    out += [f"- story #{s}: ${amount:.2f}" for s, amount in sorted(spend["story"].items(), key=lambda x: -x[1])]
    out += [f"- capped: {c}" for c in spend["capped"]]
    metrics = CONFIG.telemetry_dir / "metrics.jsonl"
    out += ["", "### Cost meter (all sessions, OTLP)", ""]
    if not metrics.exists():
        return out + [f"No data at {metrics}.", ""]
    agg = cost.aggregate(metrics, since)
    out.append(f"Total ${agg['total']['cost']:.2f}")
    for dimension in ("agent", "model", "story"):
        out.append(f"- by {dimension}: " + ", ".join(f"{r['key']} ${r['cost']:.2f}" for r in agg[dimension][:10]))
    return out + [""]


def section_sizes() -> list[str]:
    out = ["## Card, agent and skill sizes", "", "| File | Lines | Bytes |", "|---|---|---|"]
    out += [f"| `{name}` | {lines} | {size:,} |" for name, lines, size in sizes(ROOT)]
    return out + [""]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--since")
    args = parser.parse_args()
    since = args.since or (LAST_RETRO.read_text().strip() if LAST_RETRO.exists() else "")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", since):
        print(f"retro-gather: no start date (--since or {LAST_RETRO.relative_to(ROOT)})", file=sys.stderr)
        return 2
    state_dir = Path(os.environ.get("MUNSERV_FACTORY_STATE")
                     or Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "munserv-factory")
    doc = [f"# Retro evidence since {since}", ""]
    doc += section_reviews(since) + section_gate_issues(since) + section_red_ci(since)
    doc += section_blocked(since, state_dir) + section_cost(since, state_dir) + section_sizes()
    print("\n".join(doc))
    return 0


if __name__ == "__main__":
    sys.exit(main())
