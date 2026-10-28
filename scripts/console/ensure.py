"""Headless eyeball set-up: one call checks a PR out, prepares it, (re)starts only the services that
need it, and reports the links, accounts and firewall command a tester needs.

`ensure(pr, checkout)` runs inside the console server, because the console owns the service
processes. `main(pr, port)` is the client behind `python3 -m scripts.console ensure <pr>`: it calls
the local API and prints `format_report`.
"""
from __future__ import annotations

import json
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

from . import eyeball, remote, services
from .config import CONFIG
from .gitops import ApiError, CommandError, checkout_branch, current_sha, gh, repo

HEALTH_POLL_SECONDS = 2
DEFAULT_START_TIMEOUT_SECONDS = 180
PREPARE_TIMEOUT_SECONDS = 900
STOP_TIMEOUT_SECONDS = 30
CLIENT_TIMEOUT_SECONDS = 3600
LOG_LINE_MAX_CHARS = 300

_ensure_lock = threading.Lock()


def restart_reason(*, detached: bool, tracked_running: bool, healthy: bool,
                   recorded_sha: str | None, head_sha: str) -> str | None:
    """Why a service must be (re)started, or None to leave it alone. A detached service (docker
    compose) is kept while healthy. Any other service restarts when its process exited, when it
    was started from a different checkout HEAD, or when it is unhealthy."""
    if detached:
        return None if healthy else "not running"
    if not tracked_running:
        return "process exited" if recorded_sha is not None else "not running"
    if recorded_sha != head_sha:
        return f"checkout moved ({recorded_sha or 'unknown'} -> {head_sha})"
    if not healthy:
        return "unhealthy"
    return None


def _timeout(cfg: dict) -> int:
    return int(cfg.get("start_timeout", DEFAULT_START_TIMEOUT_SECONDS))


def _wait_healthy(name: str, cfg: dict, checkout: Path, timeout: int) -> None:
    """Block until `name` answers its health check, or raise with the last log line. Gives up early
    when a non-detached process has exited."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if services.health_ok(cfg["health"]):
            return
        status = services.process_status(name)
        if not cfg.get("detached") and not status["running"] and status["exit_code"] is not None:
            raise ApiError(_failure(name, f"exited with code {status['exit_code']}", checkout), 502)
        time.sleep(HEALTH_POLL_SECONDS)
    raise ApiError(_failure(name, f"not healthy after {timeout}s", checkout), 504)


def _wait_stopped(cfg: dict) -> None:
    """Wait for the stopped service to release its port; a dev server that finds its port taken
    moves to the next one, which the printed links would not match."""
    deadline = time.monotonic() + STOP_TIMEOUT_SECONDS
    while time.monotonic() < deadline and services.health_ok(cfg["health"]):
        time.sleep(HEALTH_POLL_SECONDS)


def _failure(name: str, what: str, checkout: Path) -> str:
    last = services.last_meaningful_line(checkout, name)[:LOG_LINE_MAX_CHARS]
    return f"{name} {what}. Last log line: {last or '(log is empty)'}"


def _prepare(name: str, checkout: Path) -> None:
    if not services.prepare_needed(name, checkout):
        return
    job = services.start_prepare(name, checkout)
    deadline = time.monotonic() + PREPARE_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        current = next((j for j in services.jobs_snapshot() if j["id"] == job["id"]), job)
        if current["status"] == "success":
            return
        if current["status"] == "failed":
            last = services.prepare_log(checkout, name, n=1).strip()[:LOG_LINE_MAX_CHARS]
            raise ApiError(f"prepare {name} failed ({current['message']}). Last log line: {last}", 502)
        time.sleep(HEALTH_POLL_SECONDS)
    raise ApiError(f"prepare {name} did not finish in {PREPARE_TIMEOUT_SECONDS}s", 504)


def _ensure_service(name: str, cfg: dict, checkout: Path, head: str) -> dict:
    status = services.process_status(name)
    recorded = services.recorded_shas(checkout).get(name)
    healthy = services.health_ok(cfg["health"])
    if status["running"] and recorded == head and not healthy:
        # Still booting from an earlier start: give it the start timeout before calling it unhealthy.
        try:
            _wait_healthy(name, cfg, checkout, _timeout(cfg))
            healthy = True
        except ApiError:
            healthy = False
    reason = restart_reason(detached=bool(cfg.get("detached")), tracked_running=status["running"],
                            healthy=healthy, recorded_sha=recorded, head_sha=head)
    if reason is None:
        return {"state": "up", "restarted": False, "reason": "unchanged"}
    restarted = status["running"]
    if restarted:
        services.stop_service(name, checkout)
        _wait_stopped(cfg)
    services.start_service(name, checkout)
    _wait_healthy(name, cfg, checkout, _timeout(cfg))
    return {"state": "up", "restarted": restarted, "reason": reason}


def pr_branch(pr: int) -> str:
    """The branch to check out for PR `pr`: its head while it is open, the branch it merged into
    once it is merged (the head branch is deleted on merge, and the merged result is what is left
    to eyeball)."""
    try:
        info = json.loads(gh("pr", "view", str(pr), "--repo", repo(), "--json", "headRefName,baseRefName,state"))
    except (CommandError, json.JSONDecodeError) as e:
        raise ApiError(f"cannot read PR #{pr}: {e}", 404) from e
    return info["baseRefName"] if info["state"] == "MERGED" else info["headRefName"]


def story_accounts(pr: int) -> dict:
    """The accounts the PR's Eyeball checks log in as (`as` keys), from accounts.yaml."""
    candidate = next((c for c in eyeball.build_candidates(force=False) if c.get("number") == pr), None)
    known = CONFIG.accounts_config
    keys = sorted({c["as"] for c in (candidate or {}).get("checks", []) if c.get("as") in known})
    return {k: {f: known[k][f] for f in ("role", "email", "phone", "password", "pin") if f in known[k]}
            for k in keys}


def ensure(pr: int, checkout: Path, console_port: int) -> dict:
    """Check out PR `pr`, prepare, start or restart what changed, and return the report."""
    with _ensure_lock:
        branch = pr_branch(pr)
        try:
            checkout_branch(checkout, branch)
        except CommandError as e:
            raise ApiError(f"checkout of {branch} failed: {e}", 409) from e
        head = current_sha(checkout)
        configured = services.services_config()
        names = [n for n in CONFIG.remote["ensure_services"] if n in configured]
        for name in names:
            _prepare(name, checkout)
        result_services = {name: _ensure_service(name, configured[name], checkout, head) for name in names}
        return {
            "pr": pr, "sha": head, "branch": branch, "services": result_services,
            "urls": {**remote.urls(console_port), "console": remote.console_url(console_port, with_token=True)},
            "accounts": story_accounts(pr),
            "otp": services.latest_otp(checkout),
            "firewall_command": remote.firewall(console_port)["command"] if remote.enabled() else None,
        }


# --- client -------------------------------------------------------------------

def format_report(result: dict) -> str:
    """The compact block an agent pastes into its report."""
    lines = [f"PR #{result['pr']} at {result['sha']} ({result['branch']})"]
    for name, info in result["services"].items():
        lines.append(f"  {name}: {info['state']}{' (restarted: ' + info['reason'] + ')' if info['restarted'] else ''}")
    lines += ["", f"Web:     {result['urls']['web']}", f"Swagger: {result['urls']['swagger']}",
              f"Console: {result['urls']['console']}"]
    if result["accounts"]:
        lines += ["", "Accounts:"]
        for key, acc in result["accounts"].items():
            login = acc.get("email") or acc.get("phone") or ""
            secret = acc.get("password") or (f"PIN {acc['pin']}" if acc.get("pin") else "")
            lines.append(f"  {key}: {login} / {secret}")
    if result.get("otp"):
        lines += ["", f"Latest OTP: {result['otp']}"]
    if result.get("firewall_command"):
        lines += ["", "First time only, run once on this laptop (needs sudo):", f"  {result['firewall_command']}"]
    return "\n".join(lines)


def main(pr: int, port: int) -> int:
    request = urllib.request.Request(
        f"http://{remote.LOCAL_HOST}:{port}/api/eyeball/ensure", data=json.dumps({"pr": pr}).encode("utf-8"),
        headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=CLIENT_TIMEOUT_SECONDS) as response:
            body = json.load(response)
    except urllib.error.HTTPError as e:
        body = json.load(e)
    except urllib.error.URLError as e:
        print(f"console not reachable on port {port}: {e.reason}")
        return 1
    if body.get("ok") is False:
        print(f"ensure failed: {body.get('error')}")
        return 1
    print(format_report(body))
    return 0
