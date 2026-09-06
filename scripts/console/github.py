"""GitHub state for the Overview section: milestones, the PR pipeline, and source:eyeball issues.

All `gh` calls happen on a background refresher thread, never on the request thread -- /api/state
must answer in well under 200ms on every call, including the first one after a cold start (which
returns the empty snapshot immediately rather than blocking on the network).
"""
from __future__ import annotations

import json
import threading
import time

from .gitops import CommandError, gh, repo
from .pipeline import classify_pr

REFRESH_INTERVAL_SECONDS = 60

_lock = threading.Lock()
_snapshot: dict = {
    "milestones": [], "pipeline": {"in_progress": [], "in_review": [], "awaiting_eyeball": [], "ready_to_merge": []},
    "eyeball_issues": [], "fetched_at": 0, "error": None,
}
_thread: threading.Thread | None = None
_stop = threading.Event()
_wake = threading.Event()


def gh_json(*args: str):
    return json.loads(gh(*args))


def pr_verdict_sources(number: int, slug: str) -> list[dict]:
    """Every place a verdict could be posted, oldest first: `reviewer` and `design-reviewer` post
    their APPROVE / REQUEST CHANGES verdict with `gh pr review --comment` (never `--approve` --
    merging stays the user's call), which is a PR *review* (`reviews`, state COMMENTED), not a
    plain issue comment (`comments`) -- so `reviewDecision` never reflects it and both lists must
    be checked, merged in the order they were actually posted."""
    try:
        data = gh_json("pr", "view", str(number), "--repo", slug, "--json", "comments,reviews")
    except CommandError:
        return []
    events = [(c.get("createdAt", ""), c) for c in (data.get("comments") or [])]
    events += [(r.get("submittedAt", ""), r) for r in (data.get("reviews") or [])]
    events.sort(key=lambda e: e[0])
    return [body for _, body in events]


def _fetch() -> dict:
    slug = repo()
    milestones = []
    try:
        ms = gh_json("api", f"repos/{slug}/milestones", "-q", ".")
        for m in ms:
            open_i, closed_i = m.get("open_issues", 0), m.get("closed_issues", 0)
            total = open_i + closed_i
            milestones.append({
                "title": m.get("title"), "open": open_i, "closed": closed_i, "total": total,
                "percent": round(100 * closed_i / total) if total else 0,
                "url": m.get("html_url"),
            })
    except CommandError:
        pass

    pipeline = {"in_progress": [], "in_review": [], "awaiting_eyeball": [], "ready_to_merge": []}
    try:
        prs = gh_json("pr", "list", "--repo", slug, "--state", "open", "--json",
                      "number,title,url,labels,headRefName")
        for pr in prs:
            labels = {l["name"] for l in pr.get("labels", [])}
            comments = pr_verdict_sources(pr["number"], slug)
            stage = classify_pr(labels, comments)
            pipeline[stage].append({
                "number": pr["number"], "title": pr["title"], "url": pr["url"], "branch": pr["headRefName"],
            })
    except CommandError:
        pass

    eyeball_issues = []
    try:
        issues = gh_json("issue", "list", "--repo", slug, "--state", "open", "--label", "source:eyeball",
                         "--json", "number,title,url,labels,milestone")
        for i in issues:
            eyeball_issues.append({
                "number": i["number"], "title": i["title"], "url": i["url"],
                "milestone": (i.get("milestone") or {}).get("title"),
            })
    except CommandError:
        pass

    return {"milestones": milestones, "pipeline": pipeline, "eyeball_issues": eyeball_issues,
            "fetched_at": time.time(), "error": None}


def _loop() -> None:
    while not _stop.is_set():
        try:
            snap = _fetch()
            with _lock:
                _snapshot.update(snap)
        except Exception as e:  # noqa: BLE001 - the refresher thread must never die
            with _lock:
                _snapshot["error"] = str(e)
        _wake.wait(REFRESH_INTERVAL_SECONDS)
        _wake.clear()


def start_refresher() -> None:
    global _thread
    if _thread is not None:
        return
    _thread = threading.Thread(target=_loop, daemon=True)
    _thread.start()


def refresh_now() -> None:
    _wake.set()


def get_snapshot() -> dict:
    with _lock:
        return dict(_snapshot)
