#!/usr/bin/env python3
"""MunServ eyeball dashboard: manual acceptance testing for stories awaiting merge.

Serves a local dashboard (dashboard.html) and a JSON API on http://localhost:3999 (default).
Candidates are open PRs labelled story:* (their handoff supplies the Eyeball checks) plus a
"smoke" candidate from scripts/eyeball/smoke.yaml. The dashboard can check out a candidate's
branch into a separate working copy, start/stop the dev services there, and walk a human tester
through the checks. Submitting: files a GitHub issue per failed check and per "bug" observation,
comments the results table on the PR, and swaps the eyeball:pass / eyeball:fail label.

Usage: python3 scripts/eyeball.py [--port 3999] [--checkout DIR]

Dependencies: Python 3 stdlib, PyYAML, and the `gh` CLI, logged in.
"""
from __future__ import annotations

import argparse
import json
import re
import signal
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
EYEBALL_DIR = ROOT / "scripts" / "eyeball"
REPO = "ossewawiel/munserv"
PASS_LABEL = ("eyeball:pass", "0e8a16", "Eyeball: every check passed")
FAIL_LABEL = ("eyeball:fail", "d73a4a", "Eyeball: at least one check failed")
SOURCE_LABEL = ("source:eyeball", "fbca04", "Filed from a manual eyeball session")

_state_lock = threading.Lock()
_cache: dict = {"candidates": None, "fetched_at": 0}
_processes: dict[str, subprocess.Popen] = {}
_NAME_RE = re.compile(r"^[A-Za-z0-9_.:-]+$")


class EyeballParseError(Exception):
    """A handoff's frontmatter or Eyeball block did not parse."""


class ApiError(Exception):
    """A request was rejected; carries the HTTP status to answer with."""

    def __init__(self, message: str, status: int = 400):
        super().__init__(message)
        self.status = status


def validate_name(value: str, what: str) -> str:
    """A candidate id or service name: used to build filesystem paths, so no separators."""
    if not isinstance(value, str) or not value or not _NAME_RE.match(value) or ".." in value:
        raise ApiError(f"invalid {what}: {value!r}", 400)
    return value


_BRANCH_RE = re.compile(r"^[^\s\-][^\s]*$")


def validate_branch(value: str) -> str:
    """A git branch name: passed as an argv element (never a shell string) to `git`, not used to
    build a path, so slashes are fine; reject only whitespace and a leading dash (an option-like
    value)."""
    if not isinstance(value, str) or not value or not _BRANCH_RE.match(value) or ".." in value:
        raise ApiError(f"invalid branch: {value!r}", 400)
    return value


def gh(*args: str) -> str:
    return subprocess.check_output(["gh", *args], text=True, cwd=ROOT)


def gh_json(*args: str):
    return json.loads(gh(*args))


def load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8")) if path.exists() else None


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
    """Find the handoff for `story` among handoff paths, named `<issue>-<story>-<platform>.md`
    (or the legacy `<story>-<platform>.md`) anywhere under specs/features."""
    pattern = re.compile(rf"(?:^|[/-]){re.escape(story)}-")
    for line in names:
        if pattern.search(line):
            return line
    return None


def find_handoff_path(branch: str, story: str) -> str | None:
    try:
        names = gh_run(["git", "ls-tree", "-r", "--name-only", f"origin/{branch}", "--", "specs/features"])
    except subprocess.CalledProcessError:
        return None
    return match_handoff(names.splitlines(), story)


def gh_run(args: list[str]) -> str:
    return subprocess.check_output(args, text=True, cwd=ROOT)


def build_candidates(force: bool) -> list[dict]:
    with _state_lock:
        if not force and _cache["candidates"] is not None and time.time() - _cache["fetched_at"] < 30:
            return _cache["candidates"]
        try:
            gh_run(["git", "fetch", "origin"])
        except subprocess.CalledProcessError:
            pass
        prs = gh_json("pr", "list", "--repo", REPO, "--state", "open", "--json",
                      "number,title,headRefName,labels,url,reviewDecision")
        candidates = []
        for pr in prs:
            labels = [l["name"] for l in pr["labels"]]
            story = next((l.split(":", 1)[1] for l in labels if l.startswith("story:")), None)
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
                except subprocess.CalledProcessError:
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
                "id": f"pr-{pr['number']}",
                "kind": "pr",
                "number": pr["number"],
                "title": pr["title"],
                "branch": branch,
                "url": pr["url"],
                "story": story,
                "platform": platform,
                "review_decision": pr.get("reviewDecision") or "",
                "eyeball_label": eyeball_label,
                "handoff_path": handoff_path,
                "checks": checks,
                "parse_error": parse_error,
            })
        smoke_checks = load_yaml(EYEBALL_DIR / "smoke.yaml") or []
        candidates.append({
            "id": "smoke", "kind": "smoke", "number": None, "title": "Smoke checklist",
            "branch": "master", "url": "", "story": "SMOKE", "platform": "web",
            "review_decision": "", "eyeball_label": None, "handoff_path": "scripts/eyeball/smoke.yaml",
            "checks": smoke_checks, "parse_error": None,
        })
        _cache["candidates"] = candidates
        _cache["fetched_at"] = time.time()
        return candidates


# --- checkout ---------------------------------------------------------------

def default_checkout() -> Path:
    return ROOT.parent / "munserv-eyeball"


def checkout_branch(checkout: Path, branch: str) -> str:
    checkout.parent.mkdir(parents=True, exist_ok=True)
    if (checkout / ".git").exists():
        subprocess.check_call(["git", "-C", str(checkout), "fetch", "origin"])
        subprocess.check_call(["git", "-C", str(checkout), "checkout", branch])
        subprocess.check_call(["git", "-C", str(checkout), "pull", "--ff-only"])
    else:
        # Never touch the main checkout's own branches: fetch the branch into origin/<branch>,
        # then add a worktree for it. No -B: that would force-reset a same-named local branch in
        # the main repo (or fail if it is checked out there or in another agent's worktree).
        subprocess.check_call(["git", "-C", str(ROOT), "fetch", "origin", branch])
        subprocess.check_call(["git", "-C", str(ROOT), "worktree", "add", str(checkout), branch])
    return current_branch(checkout)


def current_branch(checkout: Path) -> str:
    try:
        return subprocess.check_output(["git", "-C", str(checkout), "branch", "--show-current"], text=True,
                                        stderr=subprocess.DEVNULL).strip()
    except subprocess.CalledProcessError:
        return ""


# --- services ----------------------------------------------------------------

def services_config() -> dict:
    return load_yaml(EYEBALL_DIR / "services.yaml") or {}


def log_dir(checkout: Path) -> Path:
    d = checkout / ".eyeball" / "logs"
    d.mkdir(parents=True, exist_ok=True)
    return d


def health_ok(health: str) -> bool:
    try:
        if health.startswith("tcp:"):
            port = int(health.split(":", 1)[1])
            with socket.create_connection(("localhost", port), timeout=1.5):
                return True
        req = urllib.request.Request(health, method="GET")
        with urllib.request.urlopen(req, timeout=2) as resp:
            return resp.status < 400
    except (OSError, urllib.error.URLError, ValueError):
        return False


def start_service(name: str, checkout: Path) -> str:
    cfg = services_config().get(name)
    if not cfg or cfg.get("manual"):
        return f"{name} must be started manually"
    if name in _processes and _processes[name].poll() is None:
        return f"{name} already running"
    logf = open(log_dir(checkout) / f"{name}.log", "a", encoding="utf-8")
    logf.write(f"\n--- eyeball start {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
    logf.flush()
    cwd = checkout / cfg["cwd"]
    proc = subprocess.Popen(cfg["start"], shell=True, cwd=cwd, stdout=logf, stderr=subprocess.STDOUT,
                             start_new_session=True)
    _processes[name] = proc
    return f"{name} starting (pid {proc.pid})"


def stop_service(name: str) -> str:
    proc = _processes.get(name)
    if not proc or proc.poll() is not None:
        return f"{name} not running"
    try:
        import os
        os.killpg(proc.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    _processes.pop(name, None)
    return f"{name} stopped"


def tail_log(checkout: Path, name: str, n: int = 40) -> str:
    path = log_dir(checkout) / f"{name}.log"
    if not path.exists():
        return ""
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    return "\n".join(lines[-n:])


def latest_otp(checkout: Path) -> str | None:
    text = tail_log(checkout, "backend", n=2000)
    matches = re.findall(r"OTP for ([^:]+): (\d{6})", text)
    if not matches:
        return None
    phone, code = matches[-1]
    return f"{code} (for {phone.strip()})"


# --- results -------------------------------------------------------------

def results_path(checkout: Path, candidate_id: str) -> Path:
    d = checkout / ".eyeball" / "results"
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
    existing = {l["name"] for l in gh_json("label", "list", "--repo", REPO, "--limit", "200", "--json", "name")}
    for name, color, desc in (PASS_LABEL, FAIL_LABEL, SOURCE_LABEL):
        if name not in existing:
            subprocess.run(["gh", "label", "create", name, "--repo", REPO, "--color", color, "--description", desc],
                            cwd=ROOT, check=False)


def issue_milestone(pr_number: int | None) -> str | None:
    # `gh pr view --json closingIssuesReferences` does not carry a milestone field; look it up on
    # the first closing issue instead.
    if pr_number is None:
        return None
    try:
        refs = gh_json("pr", "view", str(pr_number), "--repo", REPO, "--json", "closingIssuesReferences")
        refs = refs.get("closingIssuesReferences") or []
        if not refs:
            return None
        issue_number = refs[0]["number"]
        issue = gh_json("issue", "view", str(issue_number), "--repo", REPO, "--json", "milestone")
        ms = issue.get("milestone")
        return ms.get("title") if ms else None
    except (subprocess.CalledProcessError, KeyError, IndexError):
        return None


def file_check_issue(candidate: dict, check: dict, result: dict) -> str:
    account = check.get("as", "none")
    lines = [
        f"Filed from an eyeball session against {candidate.get('url') or candidate['id']}.",
        "",
        f"**Account:** {account}",
        f"**URL:** {check.get('url', '')}",
        "**Steps:**",
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
        "issue", "create", "--repo", REPO,
        "--title", f"[Eyeball] {candidate['story']} {check['id']}: {check['title']}",
        "--body", "\n".join(lines),
        "--label", "type:bug,status:ready,source:eyeball",
    ]
    if candidate.get("platform"):
        args += ["--label", f"platform:{candidate['platform']}"]
    ms = issue_milestone(candidate.get("number"))
    if ms:
        args += ["--milestone", ms]
    out = subprocess.check_output(["gh", *args], text=True, cwd=ROOT).strip()
    return out.splitlines()[-1]


def file_observation_issue(candidate: dict, obs: dict) -> str:
    kind = "type:feature" if obs.get("kind") == "improvement" else "type:bug"
    first_line = obs["text"].strip().splitlines()[0][:80]
    body = obs["text"]
    if candidate.get("url"):
        body += f"\n\nFiled from an eyeball session. PR: {candidate['url']}"
    args = [
        "issue", "create", "--repo", REPO,
        "--title", f"[Eyeball] {candidate['story']}: {first_line}",
        "--body", body,
        "--label", f"{kind},status:ready,source:eyeball",
    ]
    ms = issue_milestone(candidate.get("number"))
    if ms:
        args += ["--milestone", ms]
    out = subprocess.check_output(["gh", *args], text=True, cwd=ROOT).strip()
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
    failed = sum(1 for c in checks if data["checks"].get(c["id"], {}).get("result") == "fail")

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
        subprocess.run(["gh", "pr", "comment", str(candidate["number"]), "--repo", REPO, "--body", body],
                        cwd=ROOT, check=False)
        # Pass only when every check was ticked Pass and none failed; anything else (including an
        # untouched check) is eyeball:fail.
        want = PASS_LABEL[0] if total and passed == total else FAIL_LABEL[0]
        other = FAIL_LABEL[0] if want == PASS_LABEL[0] else PASS_LABEL[0]
        subprocess.run(["gh", "pr", "edit", str(candidate["number"]), "--repo", REPO,
                        "--remove-label", other, "--add-label", want], cwd=ROOT, check=False)

    data["submitted_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    save_results(checkout, candidate["id"], data)
    return data


# --- HTTP server -----------------------------------------------------------

class Handler(BaseHTTPRequestHandler):
    checkout: Path = default_checkout()

    def log_message(self, *args):  # quiet
        pass

    def _json(self, obj, status=200):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        if not length:
            return {}
        return json.loads(self.rfile.read(length) or b"{}")

    def do_GET(self):
        try:
            if self.path == "/" or self.path == "/index.html":
                html = (EYEBALL_DIR / "dashboard.html").read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(html)))
                self.end_headers()
                self.wfile.write(html)
                return
            if self.path.startswith("/api/state"):
                return self._api_state()
            if self.path.startswith("/api/log"):
                return self._api_log()
            self.send_response(404)
            self.end_headers()
        except ApiError as e:
            self._json({"ok": False, "error": str(e)}, e.status)
        except Exception as e:  # noqa: BLE001 - never let a request bring the server down
            self._json({"ok": False, "error": str(e)}, 500)

    def do_POST(self):
        try:
            if self.path == "/api/refresh":
                build_candidates(force=True)
                return self._api_state()
            if self.path == "/api/checkout":
                body = self._read_json()
                branch = validate_branch(body.get("branch", ""))
                branch = checkout_branch(self.checkout, branch)
                return self._json({"ok": True, "branch": branch})
            if self.path == "/api/service/start":
                body = self._read_json()
                name = validate_name(body.get("name", ""), "service name")
                msg = start_service(name, self.checkout)
                return self._json({"ok": True, "message": msg})
            if self.path == "/api/service/stop":
                body = self._read_json()
                name = validate_name(body.get("name", ""), "service name")
                msg = stop_service(name)
                return self._json({"ok": True, "message": msg})
            if self.path == "/api/service/start-required":
                body = self._read_json()
                names = [validate_name(n, "service name") for n in body.get("names", [])]
                messages = [start_service(n, self.checkout) for n in names]
                return self._json({"ok": True, "messages": messages})
            if self.path == "/api/save":
                body = self._read_json()
                candidate_id = validate_name(body.get("candidate", ""), "candidate")
                save_results(self.checkout, candidate_id, body.get("data", {}))
                return self._json({"ok": True})
            if self.path == "/api/submit":
                body = self._read_json()
                candidate_id = validate_name(body.get("candidate", ""), "candidate")
                candidate = next((c for c in build_candidates(False) if c["id"] == candidate_id), None)
                if not candidate:
                    return self._json({"ok": False, "error": "unknown candidate"}, 404)
                data = load_results(self.checkout, candidate_id)
                data = submit(candidate, data, self.checkout)
                return self._json({"ok": True, "data": data})
            self.send_response(404)
            self.end_headers()
        except ApiError as e:
            self._json({"ok": False, "error": str(e)}, e.status)
        except Exception as e:  # noqa: BLE001 - never let a request bring the server down
            self._json({"ok": False, "error": str(e)}, 500)

    def _api_log(self):
        from urllib.parse import urlparse, parse_qs
        qs = parse_qs(urlparse(self.path).query)
        name = validate_name((qs.get("name") or [""])[0], "service name")
        self._json({"log": tail_log(self.checkout, name)})

    def _api_state(self):
        candidates = build_candidates(force=False)
        for c in candidates:
            c["results"] = load_results(self.checkout, c["id"])
        services = []
        cfg = services_config()
        for name, sc in cfg.items():
            manual = bool(sc.get("manual"))
            up = False if manual else health_ok(sc["health"])
            services.append({
                "name": name, "manual": manual, "up": up, "url": sc.get("url", ""),
                "notes": sc.get("notes", ""),
            })
        self._json({
            "candidates": candidates,
            "services": services,
            "accounts": load_yaml(EYEBALL_DIR / "accounts.yaml") or {},
            "checkout": {"path": str(self.checkout), "branch": current_branch(self.checkout)},
            "otp": latest_otp(self.checkout),
        })


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=3999)
    parser.add_argument("--checkout", type=Path, default=None)
    args = parser.parse_args()
    Handler.checkout = args.checkout or default_checkout()
    Handler.checkout.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("localhost", args.port), Handler)
    print(f"eyeball dashboard: http://localhost:{args.port}")
    print(f"checkout under test: {Handler.checkout}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        for name in list(_processes):
            stop_service(name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
