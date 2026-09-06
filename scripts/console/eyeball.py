"""Eyeball flow: candidates (open story:* PRs plus the smoke checklist), handoff parsing, results
storage, and GitHub submit effects (comment, eyeball:* label, source:eyeball issues).

This is the same logic the standalone scripts/eyeball.py used to own, now folded into the console
so the Eyeball section can share its checkout, services and GitHub caching with the rest of the
app.
"""
from __future__ import annotations

import json
import re
import threading
import time
from pathlib import Path

import yaml

from .config import CONFIG
from .gitops import ApiError, CommandError, gh, repo, run_captured, ROOT

PASS_LABEL = ("eyeball:pass", "0e8a16", "Eyeball: every check passed")
FAIL_LABEL = ("eyeball:fail", "d73a4a", "Eyeball: at least one check failed")
SOURCE_LABEL = ("source:eyeball", "fbca04", "Filed from a manual eyeball session")

_state_lock = threading.Lock()
_cache: dict = {"candidates": None, "fetched_at": 0}


class EyeballParseError(Exception):
    """A handoff's frontmatter or Eyeball block did not parse."""


def gh_json(*args: str):
    return json.loads(gh(*args))


def gh_run(args: list[str]) -> str:
    return run_captured(args, cwd=ROOT).stdout


def frontmatter_and_body(text: str) -> tuple[dict, str]:
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return {}, text
    try:
        return (yaml.safe_load(m.group(1)) or {}), m.group(2)
    except yaml.YAMLError as e:
        raise EyeballParseError(f"handoff frontmatter: {e}") from e


def eyeball_block(body: str) -> list:
    m = re.search(r"## Eyeball\b.*?```yaml\n(.*?)\n```", body, re.S)
    if not m:
        return []
    try:
        checks = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        raise EyeballParseError(f"Eyeball block: {e}") from e
    if not isinstance(checks, list) or not all(isinstance(c, dict) and "id" in c for c in checks):
        raise EyeballParseError("Eyeball block is not a list of checks with an id")
    return checks


def match_handoff(names: list[str], story: str) -> str | None:
    pattern = re.compile(rf"(?:^|[/-]){re.escape(story)}-")
    for line in names:
        if pattern.search(line):
            return line
    return None


def find_handoff_path(branch: str, story: str) -> str | None:
    try:
        names = gh_run(["git", "ls-tree", "-r", "--name-only", f"origin/{branch}", "--", CONFIG.handoff_glob])
    except CommandError:
        return None
    return match_handoff(names.splitlines(), story)


def build_candidates(force: bool) -> list[dict]:
    with _state_lock:
        if not force and _cache["candidates"] is not None and time.time() - _cache["fetched_at"] < 30:
            return _cache["candidates"]
        try:
            gh_run(["git", "fetch", "origin"])
        except CommandError:
            pass
        try:
            prs = gh_json("pr", "list", "--repo", repo(), "--state", "open", "--json",
                          "number,title,headRefName,labels,url,reviewDecision")
        except CommandError:
            prs = []
        candidates = []
        prefix = CONFIG.story_label_prefix
        for pr in prs:
            labels = [l["name"] for l in pr["labels"]]
            story = next((l[len(prefix):] for l in labels if l.startswith(prefix)), None)
            if not story:
                continue
            platform = next((l.split(":", 1)[1] for l in labels if l.startswith("platform:")), "")
            branch = pr["headRefName"]
            handoff_path = find_handoff_path(branch, story)
            checks: list = []
            parse_error = None
            handoff_text = ""
            if handoff_path:
                try:
                    handoff_text = gh_run(["git", "show", f"origin/{branch}:{handoff_path}"])
                except CommandError:
                    handoff_text = ""
            if handoff_text:
                try:
                    fm, body = frontmatter_and_body(handoff_text)
                    checks = eyeball_block(body)
                    platform = fm.get("platform", platform)
                except EyeballParseError as e:
                    checks = []
                    parse_error = str(e)
            eyeball_label = next((l for l in labels if l.startswith("eyeball:")), None)
            candidates.append({
                "id": f"pr-{pr['number']}", "kind": "pr", "number": pr["number"], "title": pr["title"],
                "branch": branch, "url": pr["url"], "story": story, "platform": platform,
                "review_decision": pr.get("reviewDecision") or "", "eyeball_label": eyeball_label,
                "handoff_path": handoff_path, "checks": checks, "parse_error": parse_error,
            })
        smoke_checks = CONFIG.smoke_config
        candidates.append({
            "id": "smoke", "kind": "smoke", "number": None, "title": "Smoke checklist",
            "branch": "master", "url": "", "story": "SMOKE", "platform": "web",
            "review_decision": "", "eyeball_label": None,
            "handoff_path": "scripts/console/smoke.yaml", "checks": smoke_checks, "parse_error": None,
        })
        _cache["candidates"] = candidates
        _cache["fetched_at"] = time.time()
        return candidates


# --- results -----------------------------------------------------------------

def results_path(checkout: Path, candidate_id: str) -> Path:
    d = checkout / ".console" / "results"
    d.mkdir(parents=True, exist_ok=True)
    return d / f"{candidate_id}.json"


def load_results(checkout: Path, candidate_id: str) -> dict:
    p = results_path(checkout, candidate_id)
    if p.exists():
        return json.loads(p.read_text(encoding="utf-8"))
    return {"candidate": candidate_id, "checks": {}, "observations": []}


def save_results(checkout: Path, candidate_id: str, data: dict) -> None:
    results_path(checkout, candidate_id).write_text(json.dumps(data, indent=2), encoding="utf-8")


def ensure_labels() -> None:
    existing = {l["name"] for l in gh_json("label", "list", "--repo", repo(), "--limit", "200", "--json", "name")}
    for name, color, desc in (PASS_LABEL, FAIL_LABEL, SOURCE_LABEL):
        if name not in existing:
            run_captured(["gh", "label", "create", name, "--repo", repo(), "--color", color,
                          "--description", desc], cwd=ROOT, check=False)


def issue_milestone(candidate: dict) -> str | None:
    issue_number = None
    pr_number = candidate.get("number")
    if pr_number is not None:
        try:
            refs = gh_json("pr", "view", str(pr_number), "--repo", repo(), "--json", "closingIssuesReferences")
            refs = refs.get("closingIssuesReferences") or []
            if refs:
                issue_number = refs[0]["number"]
        except (CommandError, KeyError, IndexError):
            issue_number = None
    if issue_number is None and candidate.get("story"):
        try:
            issues = gh_json("issue", "list", "--repo", repo(), "--state", "all", "--limit", "1",
                              "--label", f"{CONFIG.story_label_prefix}{candidate['story']}", "--json", "number")
            if issues:
                issue_number = issues[0]["number"]
        except (CommandError, KeyError, IndexError):
            issue_number = None
    if issue_number is None:
        return None
    try:
        title = gh("issue", "view", str(issue_number), "--repo", repo(), "--json", "milestone",
                    "-q", ".milestone.title").strip()
        return title or None
    except CommandError:
        return None


def file_check_issue(candidate: dict, check: dict, result: dict) -> str:
    account = check.get("as", "none")
    lines = [
        f"Filed from a factory console eyeball session against {candidate.get('url') or candidate['id']}.",
        "", f"**Account:** {account}", f"**URL:** {check.get('url', '')}", "**Steps:**",
    ]
    for step in check.get("steps", []):
        lines.append(f"1. {step}")
    lines.append(f"**Expected:** {check.get('expect', '')}")
    note = result.get("note")
    if note:
        lines.append("")
        lines.append(f"**Tester's note:** {note}")
    if candidate.get("url"):
        lines.append("")
        lines.append(f"PR: {candidate['url']}")
    args = [
        "issue", "create", "--repo", repo(),
        "--title", f"[Eyeball] {candidate['story']} {check['id']}: {check['title']}",
        "--body", "\n".join(lines), "--label", "type:bug,status:ready,source:eyeball",
    ]
    if candidate.get("platform"):
        args += ["--label", f"platform:{candidate['platform']}"]
    ms = issue_milestone(candidate)
    if ms:
        args += ["--milestone", ms]
    out = run_captured(["gh", *args], cwd=ROOT).stdout.strip()
    return out.splitlines()[-1]


def file_observation_issue(candidate: dict, obs: dict) -> str:
    kind = "type:feature" if obs.get("kind") == "improvement" else "type:bug"
    first_line = obs["text"].strip().splitlines()[0][:80]
    body = obs["text"]
    if candidate.get("url"):
        body += f"\n\nFiled from a factory console eyeball session. PR: {candidate['url']}"
    args = [
        "issue", "create", "--repo", repo(), "--title", f"[Eyeball] {candidate['story']}: {first_line}",
        "--body", body, "--label", f"{kind},status:ready,source:eyeball",
    ]
    ms = issue_milestone(candidate)
    if ms:
        args += ["--milestone", ms]
    out = run_captured(["gh", *args], cwd=ROOT).stdout.strip()
    return out.splitlines()[-1]


def submit(candidate: dict, data: dict, checkout: Path) -> dict:
    checks = candidate["checks"]
    passed = sum(1 for c in checks if data["checks"].get(c["id"], {}).get("result") == "pass")
    failed = sum(1 for c in checks if data["checks"].get(c["id"], {}).get("result") == "fail")
    if passed + failed == 0:
        raise ApiError("tick at least one check Pass or Fail before submitting", 400)

    ensure_labels()
    for check in checks:
        cid = check["id"]
        result = data["checks"].setdefault(cid, {"result": None, "note": "", "issue_url": None})
        if result.get("result") == "fail" and not result.get("issue_url"):
            result["issue_url"] = file_check_issue(candidate, check, result)
            save_results(checkout, candidate["id"], data)
    for obs in data.get("observations", []):
        if not obs.get("issue_url") and obs.get("text", "").strip():
            obs["issue_url"] = file_observation_issue(candidate, obs)
            save_results(checkout, candidate["id"], data)

    total = len(checks)
    passed = sum(1 for c in checks if data["checks"].get(c["id"], {}).get("result") == "pass")

    rows = ["| id | title | result | note | issue |", "|---|---|---|---|---|"]
    for check in checks:
        r = data["checks"].get(check["id"], {})
        result = r.get("result") or "-"
        note = (r.get("note") or "").replace("|", "/").replace("\n", " ")
        issue = r.get("issue_url") or ""
        rows.append(f"| {check['id']} | {check['title']} | {result} | {note} | {issue} |")
    body = f"**Eyeball: {passed}/{total} passed**\n\n" + "\n".join(rows)
    obs_with_issues = [o for o in data.get("observations", []) if o.get("issue_url")]
    if obs_with_issues:
        body += "\n\n**Observations filed:**\n" + "\n".join(f"- {o['issue_url']}" for o in obs_with_issues)

    if candidate["kind"] == "pr":
        run_captured(["gh", "pr", "comment", str(candidate["number"]), "--repo", repo(), "--body", body],
                     cwd=ROOT, check=False)
        want = PASS_LABEL[0] if total and passed == total else FAIL_LABEL[0]
        other = FAIL_LABEL[0] if want == PASS_LABEL[0] else PASS_LABEL[0]
        run_captured(["gh", "pr", "edit", str(candidate["number"]), "--repo", repo(),
                     "--remove-label", other, "--add-label", want], cwd=ROOT, check=False)

    data["submitted_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    save_results(checkout, candidate["id"], data)
    return data
