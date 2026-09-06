"""Release section: latest tag, commits since it (grouped by conventional-commit type), the head
of CHANGELOG.md, and master's CI status. Read-only; nothing here executes a release -- the exact
tag/push commands are handed back as text for the human to run.
"""
from __future__ import annotations

import json
import re
import threading
import time

from .config import CONFIG
from .gitops import CommandError, ROOT, gh, repo, run_captured

REFRESH_INTERVAL_SECONDS = 60

_lock = threading.Lock()
_snapshot: dict = {"latest_tag": None, "commits": {}, "changelog_head": "", "ci": None, "fetched_at": 0}
_thread: threading.Thread | None = None
_stop = threading.Event()
_wake = threading.Event()

_CONV_RE = re.compile(r"^(feat|fix|chore|docs|refactor|test|perf|build|ci|style|revert)(\([^)]*\))?!?:\s*(.*)$")


def _latest_tag() -> str | None:
    try:
        return run_captured(["git", "-C", str(ROOT), "describe", "--tags", "--abbrev=0"]).stdout.strip() or None
    except CommandError:
        return None


def _commits_since(tag: str | None) -> dict[str, list[str]]:
    rev_range = f"{tag}..HEAD" if tag else "HEAD"
    try:
        out = run_captured(["git", "-C", str(ROOT), "log", rev_range, "--pretty=%s"]).stdout
    except CommandError:
        return {}
    grouped: dict[str, list[str]] = {}
    for subject in out.splitlines():
        m = _CONV_RE.match(subject.strip())
        kind = m.group(1) if m else "other"
        grouped.setdefault(kind, []).append(subject.strip())
    return grouped


def _changelog_head(lines: int = 30) -> str:
    path = CONFIG.changelog
    if not path.exists():
        return ""
    return "\n".join(path.read_text(encoding="utf-8").splitlines()[:lines])


def _master_ci() -> dict | None:
    try:
        out = json.loads(run_captured(
            ["gh", "api", f"repos/{repo()}/commits/master/check-runs", "-q",
             "{runs: [.check_runs[] | {name, status, conclusion}]}"]).stdout)
        runs = out.get("runs", [])
        if not runs:
            return None
        conclusions = {r.get("conclusion") for r in runs}
        overall = "success" if conclusions <= {"success", None} and all(r.get("status") == "completed" for r in runs) else (
            "failure" if "failure" in conclusions else "pending")
        return {"overall": overall, "runs": runs}
    except (CommandError, json.JSONDecodeError):
        return None


def _fetch() -> dict:
    tag = _latest_tag()
    return {
        "latest_tag": tag, "commits": _commits_since(tag), "changelog_head": _changelog_head(),
        "ci": _master_ci(), "fetched_at": time.time(),
    }


def _loop() -> None:
    while not _stop.is_set():
        try:
            snap = _fetch()
            with _lock:
                _snapshot.update(snap)
        except Exception:  # noqa: BLE001 - the refresher thread must never die
            pass
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


def release_commands(next_version: str) -> list[str]:
    return [
        f"git tag -a {next_version} -m \"{next_version}\"",
        f"git push origin {next_version}",
    ]
