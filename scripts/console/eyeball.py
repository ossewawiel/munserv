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
from typing import Callable

import yaml

from .config import CONFIG
from .github import pr_verdict_sources
from .gitops import ApiError, CommandError, gh, repo, run_captured, ROOT
from .pipeline import classify_pr

PASS_LABEL = ("eyeball:pass", "0e8a16", "Eyeball: every check passed")
FAIL_LABEL = ("eyeball:fail", "d73a4a", "Eyeball: at least one check failed")
SOURCE_LABEL = ("source:eyeball", "fbca04", "Filed from a manual eyeball session")

_state_lock = threading.Lock()
_cache: dict = {"candidates": None, "fetched_at": 0}

# --- double-submit guard -----------------------------------------------------
#
# A submit runs several `gh` calls in sequence (issue search/create, PR comment, label edit) and
# can take several seconds; a tester who sees no feedback and clicks Submit again must never kick
# off a second run for the same candidate concurrently -- that is exactly how issue #122 came to
# be filed as a duplicate of #123 against PR #100. `begin_submit`/`end_submit` bracket every
# `/api/eyeball/submit` request; a second request for the same candidate while the first is still
# running is refused with a 409 rather than starting a second `submit()`.

_submitting_lock = threading.Lock()
_submitting_candidates: set[str] = set()


def begin_submit(candidate_id: str) -> None:
    with _submitting_lock:
        if candidate_id in _submitting_candidates:
            raise ApiError(f"a submit for {candidate_id} is already running", 409)
        _submitting_candidates.add(candidate_id)


def end_submit(candidate_id: str) -> None:
    with _submitting_lock:
        _submitting_candidates.discard(candidate_id)


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
            stage = classify_pr(set(labels), pr_verdict_sources(pr["number"], repo()))
            candidates.append({
                "id": f"pr-{pr['number']}", "kind": "pr", "number": pr["number"], "title": pr["title"],
                "branch": branch, "url": pr["url"], "story": story, "platform": platform,
                "review_decision": pr.get("reviewDecision") or "", "eyeball_label": eyeball_label,
                "stage": stage,
                "handoff_path": handoff_path, "checks": checks, "parse_error": parse_error,
            })
        smoke_checks = CONFIG.smoke_config
        candidates.append({
            "id": "smoke", "kind": "smoke", "number": None, "title": "Smoke checklist",
            "branch": "master", "url": "", "story": "SMOKE", "platform": "web",
            "review_decision": "", "eyeball_label": None, "stage": None,
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


# --- reuse an already-open issue instead of filing a duplicate ---------------
#
# Every eyeball-filed issue's title starts with a fixed, greppable prefix (`[Eyeball] <story>
# <check id>:` for a check, `[Eyeball] <story>:` for an observation). Before creating a new issue,
# search open issues for that prefix and reuse a match -- otherwise re-running eyeball against a
# PR that already has an open bug for the same check files a second, duplicate issue every time.

def search_open_issues(title_prefix: str) -> list[dict]:
    """Open issues whose title mentions `title_prefix`, via `gh issue list --search`. Returns []
    (never raises) when `gh` itself fails -- a broken search must fall back to filing a new issue,
    not to crashing the submit."""
    try:
        return gh_json("issue", "list", "--repo", repo(), "--search", f'in:title "{title_prefix}"',
                        "--state", "open", "--json", "number,url,title")
    except CommandError:
        return []


def pick_reusable_issue(issues: list[dict], title_prefix: str) -> dict | None:
    """The first open issue to actually reuse, or None. `gh issue list --search` matches
    loosely -- a title that merely *contains* `title_prefix` somewhere (e.g. quoted in an
    unrelated issue's body-derived title) is not a real match, so only a title that *starts with*
    the prefix counts."""
    for issue in issues:
        if issue.get("title", "").startswith(title_prefix):
            return issue
    return None


def find_or_create_issue(title_prefix: str, create: Callable[[], str]) -> dict:
    """{"url", "reused"} -- reuse the first open issue whose title starts with `title_prefix`, or
    call `create()` (which must return the new issue's URL) and report it as freshly created."""
    existing = pick_reusable_issue(search_open_issues(title_prefix), title_prefix)
    if existing:
        return {"url": existing["url"], "reused": True}
    return {"url": create(), "reused": False}


def file_check_issue(candidate: dict, check: dict, result: dict, kind: str = "bug") -> dict:
    """File (or reuse) an issue for one check -- a `type:bug` for a failed check, or a
    `type:feature` when the tester ticked "File as improvement" on a passing check with a note.
    Same title format and body shape either way, so a check's issue is always found by the same
    title-prefix search regardless of which way it was filed."""
    title_prefix = f"[Eyeball] {candidate['story']} {check['id']}:"

    def create() -> str:
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
            "--title", f"{title_prefix} {check['title']}",
            "--body", "\n".join(lines), "--label", f"type:{kind},status:ready,source:eyeball",
        ]
        if candidate.get("platform"):
            args += ["--label", f"platform:{candidate['platform']}"]
        ms = issue_milestone(candidate)
        if ms:
            args += ["--milestone", ms]
        out = run_captured(["gh", *args], cwd=ROOT).stdout.strip()
        return out.splitlines()[-1]

    return find_or_create_issue(title_prefix, create)


def file_observation_issue(candidate: dict, obs: dict) -> dict:
    title_prefix = f"[Eyeball] {candidate['story']}:"

    def create() -> str:
        kind = "type:feature" if obs.get("kind") == "improvement" else "type:bug"
        first_line = obs["text"].strip().splitlines()[0][:80]
        body = obs["text"]
        if candidate.get("url"):
            body += f"\n\nFiled from a factory console eyeball session. PR: {candidate['url']}"
        args = [
            "issue", "create", "--repo", repo(), "--title", f"{title_prefix} {first_line}",
            "--body", body, "--label", f"{kind},status:ready,source:eyeball",
        ]
        ms = issue_milestone(candidate)
        if ms:
            args += ["--milestone", ms]
        out = run_captured(["gh", *args], cwd=ROOT).stdout.strip()
        return out.splitlines()[-1]

    return find_or_create_issue(title_prefix, create)


def submit(candidate: dict, data: dict, checkout: Path) -> dict:
    checks = candidate["checks"]
    passed = sum(1 for c in checks if data["checks"].get(c["id"], {}).get("result") == "pass")
    failed = sum(1 for c in checks if data["checks"].get(c["id"], {}).get("result") == "fail")
    if passed + failed == 0:
        raise ApiError("tick at least one check Pass or Fail before submitting", 400)

    ensure_labels()
    for check in checks:
        cid = check["id"]
        result = data["checks"].setdefault(
            cid, {"result": None, "note": "", "issue_url": None, "issue_reused": False})
        if result.get("result") == "fail" and not result.get("issue_url"):
            filed = file_check_issue(candidate, check, result)
            result["issue_url"] = filed["url"]
            result["issue_reused"] = filed["reused"]
            save_results(checkout, candidate["id"], data)
        elif (result.get("result") == "pass" and result.get("file_as_improvement")
              and result.get("note", "").strip() and not result.get("issue_url")):
            filed = file_check_issue(candidate, check, result, kind="feature")
            result["issue_url"] = filed["url"]
            result["issue_reused"] = filed["reused"]
            save_results(checkout, candidate["id"], data)
    for obs in data.get("observations", []):
        if not obs.get("issue_url") and obs.get("text", "").strip():
            filed = file_observation_issue(candidate, obs)
            obs["issue_url"] = filed["url"]
            obs["issue_reused"] = filed["reused"]
            save_results(checkout, candidate["id"], data)

    total = len(checks)
    passed = sum(1 for c in checks if data["checks"].get(c["id"], {}).get("result") == "pass")

    rows = ["| id | title | result | note | issue |", "|---|---|---|---|---|"]
    for check in checks:
        r = data["checks"].get(check["id"], {})
        result = r.get("result") or "-"
        note = (r.get("note") or "").replace("|", "/").replace("\n", " ")
        issue = r.get("issue_url") or ""
        if issue and r.get("issue_reused"):
            issue += " (reused)"
        if issue and r.get("file_as_improvement"):
            issue += " (improvement)"
        rows.append(f"| {check['id']} | {check['title']} | {result} | {note} | {issue} |")
    body = f"**Eyeball: {passed}/{total} passed**\n\n" + "\n".join(rows)
    obs_with_issues = [o for o in data.get("observations", []) if o.get("issue_url")]
    if obs_with_issues:
        body += "\n\n**Observations filed:**\n" + "\n".join(
            f"- {o['issue_url']}" + (" (reused)" if o.get("issue_reused") else "") for o in obs_with_issues)

    comment_url = None
    label = None
    if candidate["kind"] == "pr":
        comment_out = run_captured(["gh", "pr", "comment", str(candidate["number"]), "--repo", repo(),
                                    "--body", body], cwd=ROOT, check=False)
        comment_url = comment_out.stdout.strip().splitlines()[-1] if comment_out.stdout.strip() else None
        label = PASS_LABEL[0] if total and passed == total else FAIL_LABEL[0]
        other = FAIL_LABEL[0] if label == PASS_LABEL[0] else PASS_LABEL[0]
        run_captured(["gh", "pr", "edit", str(candidate["number"]), "--repo", repo(),
                     "--remove-label", other, "--add-label", label], cwd=ROOT, check=False)

    data["submitted_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    # Everything the result dialog needs to show without re-deriving it from the checks/
    # observations dicts: the PR comment link, the label the submit actually applied, and the
    # pass/total tally the candidate row keeps showing after the fact.
    data["last_submission"] = {"comment_url": comment_url, "label": label, "passed": passed, "total": total}
    save_results(checkout, candidate["id"], data)
    return data
