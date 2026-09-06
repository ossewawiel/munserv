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


def _pipeline_column(pr: dict) -> str:
    labels = {l["name"] for l in pr.get("labels", [])}
    eyeball = next((l for l in labels if l.startswith("eyeball:")), None)
    if eyeball == "eyeball:pass":
        return "ready_to_merge"
    if eyeball == "eyeball:fail":
        return "in_review"
    if pr.get("reviewDecision") == "APPROVED":
        return "awaiting_eyeball"
    if "status:review" in labels or pr.get("reviewDecision") in ("CHANGES_REQUESTED", "REVIEW_REQUIRED"):
        return "in_review"
    return "in_progress"


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
                      "number,title,url,labels,reviewDecision,headRefName")
        for pr in prs:
            column = _pipeline_column(pr)
            pipeline[column].append({
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
