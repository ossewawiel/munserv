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
import os
import re
import shutil
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

def _repo_root() -> Path:
    """The eyeball script's own repository root -- resolved via git, not a fixed path depth, so
    the script keeps working if it is copied to another project at a different nesting (see
    scripts/eyeball/project.yaml). Read-only git for candidates always runs here, never in a
    checkout directory that may not exist yet."""
    script_dir = Path(__file__).resolve().parent
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=script_dir, text=True,
                              capture_output=True)
        if out.returncode == 0:
            return Path(out.stdout.strip())
    except OSError:
        pass
    return script_dir.parent


ROOT = _repo_root()
EYEBALL_DIR = ROOT / "scripts" / "eyeball"


def load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8")) if path.exists() else None


# Everything project-specific lives in scripts/eyeball/{accounts,services,smoke}.yaml plus this
# optional project.yaml; copying the eyeball dashboard to another repo means editing those files,
# never this script. See scripts/eyeball/README.md.
PROJECT = load_yaml(EYEBALL_DIR / "project.yaml") or {}
PROJECT_NAME = PROJECT.get("name") or ROOT.name
DEFAULT_PORT = int(PROJECT.get("port", 3999))
HANDOFF_GLOB = PROJECT.get("handoff_glob", "specs/features")
STORY_LABEL_PREFIX = PROJECT.get("story_label_prefix", "story:")
CHECKOUT_DIR_NAME = PROJECT.get("checkout_dir", f"{PROJECT_NAME}-eyeball")

PASS_LABEL = ("eyeball:pass", "0e8a16", "Eyeball: every check passed")
FAIL_LABEL = ("eyeball:fail", "d73a4a", "Eyeball: at least one check failed")
SOURCE_LABEL = ("source:eyeball", "fbca04", "Filed from a manual eyeball session")

_state_lock = threading.Lock()
_cache: dict = {"candidates": None, "fetched_at": 0}
_processes: dict[str, subprocess.Popen] = {}
_repo_slug: list[str] = []
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


class CommandError(Exception):
    """A subprocess exited non-zero; carries its stderr instead of leaking it to the terminal."""


def run_captured(args: list[str], cwd: Path = ROOT, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command with stdout/stderr captured -- never inherited -- so a git/gh failure never
    reaches the dashboard's own terminal. On failure (when check) raises CommandError carrying the
    command's stderr (or stdout, if stderr is empty) for the caller to surface in a JSON response."""
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if check and result.returncode != 0:
        message = (result.stderr or result.stdout or f"exit {result.returncode}").strip()
        raise CommandError(f"{' '.join(args)}: {message}")
    return result


def gh(*args: str) -> str:
    return run_captured(["gh", *args]).stdout


def gh_json(*args: str):
    return json.loads(gh(*args))


def repo() -> str:
    """`owner/name` for `gh --repo`: an explicit `project.yaml: repo` wins; otherwise it is
    detected from the origin remote on first use (never at import, so importing this module for
    unit tests never shells out to `gh`)."""
    if not _repo_slug:
        override = PROJECT.get("repo")
        if override:
            _repo_slug.append(override)
        else:
            try:
                _repo_slug.append(run_captured(
                    ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
                    cwd=ROOT).stdout.strip())
            except CommandError:
                _repo_slug.append("")
    return _repo_slug[0]


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
        names = gh_run(["git", "ls-tree", "-r", "--name-only", f"origin/{branch}", "--", HANDOFF_GLOB])
    except CommandError:
        return None
    return match_handoff(names.splitlines(), story)


def gh_run(args: list[str]) -> str:
    """Read-only git (ls-tree, show, fetch) for the candidate list: always runs in ROOT, the main
    repository, never in a checkout directory that may not exist yet."""
    return run_captured(args, cwd=ROOT).stdout


def build_candidates(force: bool) -> list[dict]:
    with _state_lock:
        if not force and _cache["candidates"] is not None and time.time() - _cache["fetched_at"] < 30:
            return _cache["candidates"]
        try:
            gh_run(["git", "fetch", "origin"])
        except CommandError:
            pass
        prs = gh_json("pr", "list", "--repo", repo(), "--state", "open", "--json",
                      "number,title,headRefName,labels,url,reviewDecision")
        candidates = []
        for pr in prs:
            labels = [l["name"] for l in pr["labels"]]
            story = next((l[len(STORY_LABEL_PREFIX):] for l in labels if l.startswith(STORY_LABEL_PREFIX)), None)
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
    return ROOT.parent / CHECKOUT_DIR_NAME


def branch_state_file(checkout: Path) -> Path:
    return checkout / ".eyeball" / "branch"


def worktree_add_args(checkout: Path, branch: str) -> list[str]:
    """Add the checkout worktree detached at `origin/<branch>` -- never claims the branch name
    itself. Claiming it (`git worktree add <dir> <branch>`, or `-B <branch>`) fails outright, or
    force-resets a local branch, whenever that same branch is already checked out somewhere else
    -- which happens constantly here, since factory agents hold feature branches checked out in
    their own worktrees under .claude/worktrees/."""
    return ["git", "-C", str(ROOT), "worktree", "add", "--detach", str(checkout), f"origin/{branch}"]


def worktree_switch_args(checkout: Path, branch: str) -> tuple[list[str], list[str]]:
    """Move an existing checkout worktree to `origin/<branch>`, still detached."""
    fetch = ["git", "-C", str(checkout), "fetch", "origin", branch]
    switch = ["git", "-C", str(checkout), "checkout", "--detach", f"origin/{branch}"]
    return fetch, switch


def _preserve_eyeball_state(checkout: Path) -> Path | None:
    """`git worktree add` needs its target directory to not exist, or to be completely empty --
    but `/api/state` (via load_results) may already have written `.eyeball/` (results, logs) into
    `checkout` before the first-ever checkout runs, since main() pre-creates that directory. Move
    that state aside so `add` can proceed; `_restore_eyeball_state` puts it back afterwards."""
    state_dir = checkout / ".eyeball"
    if not state_dir.exists():
        return None
    if any(p.name != ".eyeball" for p in checkout.iterdir()):
        return None  # something unexpected is already there; let git report on it
    tmp = checkout.with_name(checkout.name + ".eyeball-tmp")
    if tmp.exists():
        shutil.rmtree(tmp)
    shutil.move(str(state_dir), str(tmp))
    return tmp


def _restore_eyeball_state(checkout: Path, tmp: Path | None) -> None:
    if tmp is None:
        return
    checkout.mkdir(parents=True, exist_ok=True)
    dest = checkout / ".eyeball"
    if dest.exists():
        shutil.rmtree(dest)
    shutil.move(str(tmp), str(dest))


def checkout_branch(checkout: Path, branch: str) -> str:
    checkout.parent.mkdir(parents=True, exist_ok=True)
    if is_worktree(checkout):
        fetch, switch = worktree_switch_args(checkout, branch)
        run_captured(fetch, cwd=ROOT)
        run_captured(switch, cwd=ROOT)
    else:
        # Never touch the main checkout's own branches: fetch the branch into origin/<branch>,
        # then add a *detached* worktree against it (see worktree_add_args).
        run_captured(["git", "-C", str(ROOT), "fetch", "origin", branch], cwd=ROOT)
        preserved = _preserve_eyeball_state(checkout) if checkout.exists() else None
        if checkout.exists() and not any(checkout.iterdir()):
            checkout.rmdir()
        run_captured(worktree_add_args(checkout, branch), cwd=ROOT)
        _restore_eyeball_state(checkout, preserved)
    branch_state_file(checkout).parent.mkdir(parents=True, exist_ok=True)
    branch_state_file(checkout).write_text(branch, encoding="utf-8")
    return current_branch(checkout)


def is_worktree(checkout: Path) -> bool:
    """True only once `checkout` is a real git worktree -- never invoke git inside it before
    then, so a fresh dashboard with nothing checked out yet never shells out to a plain directory
    (which would fail with "not a git repository")."""
    return (checkout / ".git").exists()


def current_branch(checkout: Path) -> str:
    """The branch last requested via /api/checkout, read back from its state file: the worktree
    itself is checked out detached (see checkout_branch), so `git branch --show-current` would
    always report nothing."""
    f = branch_state_file(checkout)
    return f.read_text(encoding="utf-8").strip() if f.exists() else ""


def current_sha(checkout: Path) -> str:
    if not is_worktree(checkout):
        return ""
    try:
        return run_captured(["git", "-C", str(checkout), "rev-parse", "--short", "HEAD"], cwd=ROOT).stdout.strip()
    except CommandError:
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
    cwd = checkout / cfg["cwd"]
    if not cwd.is_dir():
        # Nothing has been checked out yet (or the checkout is missing this path): a Popen with a
        # non-existent cwd raises FileNotFoundError, which is not an ApiError and would otherwise
        # surface as a raw traceback. Ask for a checkout instead of crashing.
        raise ApiError("Check out a branch first", 409)
    with open(log_dir(checkout) / f"{name}.log", "a", encoding="utf-8") as logf:
        logf.write(f"\n--- eyeball start {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
        logf.flush()
        # The child inherits its own duplicated file descriptor for stdout/stderr, so this file
        # object can (and must) be closed in the parent as soon as Popen returns.
        proc = subprocess.Popen(cfg["start"], shell=True, cwd=cwd, stdout=logf, stderr=subprocess.STDOUT,
                                 start_new_session=True)
    _processes[name] = proc
    return f"{name} starting (pid {proc.pid})"


def stop_service(name: str, checkout: Path) -> str:
    proc = _processes.get(name)
    if proc and proc.poll() is None:
        try:
            os.killpg(proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        _processes.pop(name, None)
        return f"{name} stopped"
    # No tracked process, or it already exited on its own (`docker compose up -d` does, since the
    # containers it starts outlive it): fall back to the service's own `stop` command, if any.
    cfg = services_config().get(name) or {}
    stop_cmd = cfg.get("stop")
    if stop_cmd:
        cwd = checkout / cfg["cwd"]
        if cwd.is_dir():
            subprocess.run(stop_cmd, shell=True, cwd=cwd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return f"{name} stopped"
    return f"{name} not running"


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
    existing = {l["name"] for l in gh_json("label", "list", "--repo", repo(), "--limit", "200", "--json", "name")}
    for name, color, desc in (PASS_LABEL, FAIL_LABEL, SOURCE_LABEL):
        if name not in existing:
            run_captured(["gh", "label", "create", name, "--repo", repo(), "--color", color,
                          "--description", desc], cwd=ROOT, check=False)


def issue_milestone(candidate: dict) -> str | None:
    """The milestone of the story this candidate belongs to: `gh pr view --json
    closingIssuesReferences` carries no milestone field, so look one up on the first closing
    issue; if the PR closes nothing, fall back to the issue carrying the same `story:*` label."""
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
                              "--label", f"{STORY_LABEL_PREFIX}{candidate['story']}", "--json", "number")
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
        "issue", "create", "--repo", repo(),
        "--title", f"[Eyeball] {candidate['story']} {check['id']}: {check['title']}",
        "--body", "\n".join(lines),
        "--label", "type:bug,status:ready,source:eyeball",
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
        body += f"\n\nFiled from an eyeball session. PR: {candidate['url']}"
    args = [
        "issue", "create", "--repo", repo(),
        "--title", f"[Eyeball] {candidate['story']}: {first_line}",
        "--body", body,
        "--label", f"{kind},status:ready,source:eyeball",
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
        run_captured(["gh", "pr", "comment", str(candidate["number"]), "--repo", repo(), "--body", body],
                     cwd=ROOT, check=False)
        # Pass only when every check was ticked Pass and none failed; anything else (including an
        # untouched check) is eyeball:fail.
        want = PASS_LABEL[0] if total and passed == total else FAIL_LABEL[0]
        other = FAIL_LABEL[0] if want == PASS_LABEL[0] else PASS_LABEL[0]
        run_captured(["gh", "pr", "edit", str(candidate["number"]), "--repo", repo(),
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

    def _allowed_origins(self) -> set[str]:
        port = self.server.server_address[1]
        return {f"http://localhost:{port}", f"http://127.0.0.1:{port}"}

    def _reject_cross_origin(self) -> None:
        """A `text/plain` (or missing-Content-Type) POST is a CORS *simple* request -- no
        preflight -- so without this, any page open in the tester's browser while the dashboard
        runs could POST to it and trigger real side effects (filing issues, swapping labels,
        starting services) using the tester's own session. Reject any request that carries an
        Origin header naming something other than this server itself."""
        origin = self.headers.get("Origin")
        if origin and origin not in self._allowed_origins():
            raise ApiError("cross-origin request rejected", 403)

    def _require_json_content_type(self) -> None:
        content_type = (self.headers.get("Content-Type") or "").split(";", 1)[0].strip()
        if content_type != "application/json":
            raise ApiError("Content-Type must be application/json", 403)

    def do_GET(self):
        try:
            self._reject_cross_origin()
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
            self._reject_cross_origin()
            self._require_json_content_type()
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
                msg = stop_service(name, self.checkout)
                return self._json({"ok": True, "message": msg})
            if self.path == "/api/service/start-required":
                body = self._read_json()
                names = [validate_name(n, "service name") for n in body.get("names", [])]
                branch = body.get("branch")
                if branch:
                    branch = validate_branch(branch)
                    if current_branch(self.checkout) != branch:
                        checkout_branch(self.checkout, branch)
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
            "checkout": {"path": str(self.checkout), "branch": current_branch(self.checkout),
                         "sha": current_sha(self.checkout)},
            "otp": latest_otp(self.checkout),
        })


def _raise_system_exit(signum, frame):  # noqa: ARG001 - signal handler signature
    raise SystemExit(0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--checkout", type=Path, default=None)
    args = parser.parse_args()
    Handler.checkout = args.checkout or default_checkout()
    Handler.checkout.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("localhost", args.port), Handler)
    # SIGTERM (dashboard.sh's Ctrl-C trap, or any other supervisor) must run the same cleanup as
    # SIGINT: without a handler, the default disposition kills the process immediately and the
    # `finally` below -- which stops every service's process group -- never runs.
    signal.signal(signal.SIGTERM, _raise_system_exit)
    print(f"eyeball dashboard: http://localhost:{args.port}")
    print(f"checkout under test: {Handler.checkout}")
    try:
        server.serve_forever()
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        for name in list(_processes):
            stop_service(name, Handler.checkout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
