"""Headless smoke run: every probe check of the completed handoffs and smoke.yaml, no console, no browser.

CI runs this on master after a merge (`smoke` job in .github/workflows/ci.yml). Auto-merge can land a
PR before a reviewer verdict or an eyeball pass arrives, so the probes of finished stories run again
against what is now on master.

A check is a probe when it has `auto: true` and a `probe` key (`autocheck.is_auto`, `run_probe`). A page
check needs a browser and is skipped. The requests go to localhost: remote mode is forced off.

With `--file-issues`, a failed check opens one `type:bug` issue, or comments on the open one, labelled
`source:smoke` and naming the commit. A passing check closes its open issue with a comment naming the commit.

Usage: python3 -m scripts.console.smoke_run [--list] [--file-issues] [--commit SHA] [--run-url URL]
Exit code: 0 all probes passed, 1 a probe failed or none was found.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import autocheck, eyeball, remote
from .config import CONFIG, ROOT
from .gitops import CommandError, repo, run_captured

COMPLETED_GLOB = "*/completed/*.md"
SOURCE_LABEL = ("source:smoke", "b60205", "Found by the post-merge smoke run on master")
SMOKE_SOURCE = "smoke.yaml"
TITLE_PREFIX = "[Smoke]"
EXCERPT_CHARS = 600


def is_probe(check: dict) -> bool:
    return autocheck.is_auto(check) and "probe" in check


def _handoff_checks(path: Path) -> list[dict]:
    _, body = eyeball.frontmatter_and_body(path.read_text(encoding="utf-8"))
    return eyeball.eyeball_block(body)


def collect(features_dir: Path, smoke_checks: list) -> tuple[list[dict], list[str]]:
    """Every probe check as `{"source", "check"}`, and the handoffs whose Eyeball block did not parse.
    `source` is the handoff's file name without `.md`, or `smoke.yaml`."""
    found: list[dict] = []
    unparsed: list[str] = []
    for path in sorted(features_dir.glob(COMPLETED_GLOB)):
        try:
            checks = _handoff_checks(path)
        except eyeball.EyeballParseError as e:
            unparsed.append(f"{path.relative_to(features_dir.parent.parent)}: {e}")
            continue
        found += [{"source": path.stem, "check": c} for c in checks if is_probe(c)]
    found += [{"source": SMOKE_SOURCE, "check": c} for c in smoke_checks if is_probe(c)]
    return found, unparsed


def failure_lines(evidence: dict) -> list[str]:
    """What went wrong, one line each: the check's own problems, or the failing request."""
    lines = list(evidence.get("problems", []))
    for request in evidence.get("requests", []):
        for problem in request["problems"]:
            lines.append(f"{request['method']} {request['path']}: {problem}")
    return lines


def issue_prefix(entry: dict) -> str:
    return f"{TITLE_PREFIX} {entry['source']} {entry['check']['id']}:"


def issue_body(entry: dict, evidence: dict, commit: str, run_url: str) -> str:
    check = entry["check"]
    lines = [f"The post-merge smoke run failed `{check['id']}` from `{entry['source']}` on commit `{commit}`."]
    if run_url:
        lines.append(f"Run: {run_url}")
    lines += ["", f"**Check:** {check['title']}", f"**Account:** {check.get('as', 'none')}", "**Problems:**"]
    lines += [f"- {line}" for line in failure_lines(evidence)]
    for request in evidence.get("requests", []):
        lines += ["", f"`{request['method']} {request['path']}` answered {request['status']}:",
                  "```", request["response"][:EXCERPT_CHARS], "```"]
    return "\n".join(lines)


def ensure_label() -> None:
    name, color, description = SOURCE_LABEL
    run_captured(["gh", "label", "create", name, "--repo", repo(), "--color", color, "--description", description,
                  "--force"], cwd=ROOT)


def file_issue(entry: dict, evidence: dict, commit: str, run_url: str) -> str:
    """Open the check's issue, or comment on the open one; returns its URL."""
    prefix = issue_prefix(entry)
    existing = eyeball.pick_reusable_issue(eyeball.search_open_issues(prefix), prefix)
    body = issue_body(entry, evidence, commit, run_url)
    if existing:
        run_captured(["gh", "issue", "comment", existing["url"], "--body", body], cwd=ROOT)
        return existing["url"]
    out = run_captured(["gh", "issue", "create", "--repo", repo(), "--title", f"{prefix} {entry['check']['title']}",
                        "--body", body, "--label", "type:bug,status:ready,source:smoke"], cwd=ROOT).stdout.strip()
    return out.splitlines()[-1]


def close_recovered(entry: dict, commit: str, run_url: str) -> str | None:
    """Close the check's open issue, if any, now that it passes; returns its URL."""
    prefix = issue_prefix(entry)
    existing = eyeball.pick_reusable_issue(eyeball.search_open_issues(prefix), prefix)
    if not existing:
        return None
    note = f"`{entry['check']['id']}` passes again on commit `{commit}`." + (f" Run: {run_url}" if run_url else "")
    run_captured(["gh", "issue", "close", existing["url"], "--comment", note], cwd=ROOT)
    return existing["url"]


def run_all(entries: list[dict]) -> list[dict]:
    """Run every probe; returns the entries with their `evidence`."""
    return [{**e, "evidence": autocheck.run_check(e["check"], SMOKE_SOURCE, ROOT)} for e in entries]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run every probe check against localhost.")
    parser.add_argument("--list", action="store_true", help="print the probes and exit")
    parser.add_argument("--file-issues", action="store_true", help="open or update one bug issue per failed probe")
    parser.add_argument("--commit", default="unknown", help="commit under test, named in the issues")
    parser.add_argument("--run-url", default="", help="link to the CI run, named in the issues")
    args = parser.parse_args(argv)

    remote.set_mode(False)
    entries, unparsed = collect(ROOT / CONFIG.handoff_glob, CONFIG.smoke_config)
    for line in unparsed:
        print(f"unparsed Eyeball block, skipped: {line}", file=sys.stderr)
    if not entries:
        print("no probe checks found", file=sys.stderr)
        return 1
    if args.list:
        for e in entries:
            print(f"{e['source']} {e['check']['id']}: {e['check']['title']}")
        return 0

    results = run_all(entries)
    failed = [r for r in results if not r["evidence"]["ok"]]
    for r in results:
        print(f"{'PASS' if r['evidence']['ok'] else 'FAIL'} {r['source']} {r['check']['id']}: {r['check']['title']}")
        for line in failure_lines(r["evidence"]) if not r["evidence"]["ok"] else []:
            print(f"     {line}")
    print(f"{len(results) - len(failed)}/{len(results)} probes passed")

    if args.file_issues:
        try:
            if failed:
                ensure_label()
            for r in results:
                if r["evidence"]["ok"]:
                    closed = close_recovered(r, args.commit, args.run_url)
                    if closed:
                        print(f"closed {closed}")
                else:
                    print(f"issue for {r['source']} {r['check']['id']}: "
                          f"{file_issue(r, r['evidence'], args.commit, args.run_url)}")
        except CommandError as e:
            print(f"could not file issues: {e}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
