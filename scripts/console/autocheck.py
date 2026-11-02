"""Auto checks: the Eyeball checks a machine can run before a person opens the PR.

A check marked `auto: true` in a handoff's Eyeball block is one of two kinds:

* probe -- one HTTP request, or a list of them in order, sent as the `as` account. Each request has
  `method`, `path`, an optional `body`, `expect_status` and an optional `expect_body` (text, or a
  list of texts, that the response body must contain). `save: {name: "dotted.path"}` keeps a value
  from the JSON response; a later `path` or `body` string can use it as `{name}`.
* page -- Playwright opens the check's `url` as the `as` account, asserts every text in
  `page.expect_text` is on the page, and saves a screenshot (`page_check.mjs`).

Both run against the public host (`remote.host()`, the address `scripts/eyeball-up.sh` prints), never
`localhost`, so they prove what a tester on another machine would reach. The result is stored like a
tester's tick (`result` pass or fail) plus an `auto` block holding the evidence: every request with
its status and response, or the screenshot file. A tester can still flip the tick. The access token
is used for the requests and is never written to the evidence.
"""
from __future__ import annotations

import json
import re
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

from . import remote
from .config import CONFIG, ROOT
from .gitops import ApiError

REQUEST_TIMEOUT_SECONDS = 30
PAGE_TIMEOUT_SECONDS = 120
BODY_EXCERPT_CHARS = 2000
PAGE_SCRIPT = Path(__file__).resolve().parent / "page_check.mjs"
EVIDENCE_DIR = "evidence"
_LOCAL_HOST = re.compile(r"\b(?:localhost|127\.0\.0\.1)\b")
_VARIABLE = re.compile(r"\{([A-Za-z_]\w*)\}")


def is_auto(check: dict) -> bool:
    return check.get("auto") is True


def public_url(url: str) -> str:
    """`url` with localhost replaced by the host a tester on another machine uses."""
    return _LOCAL_HOST.sub(remote.host(), url)


def backend_base() -> str:
    return f"http://{remote.host()}:{CONFIG.remote['ports']['backend']}"


def web_base() -> str:
    return f"http://{remote.host()}:{CONFIG.remote['ports']['web']}"


# --- login ----------------------------------------------------------------------

def _post_json(url: str, body: dict) -> tuple[int, str]:
    request = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"), method="POST",
                                     headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            return response.status, response.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")


def login(account_key: str) -> dict | None:
    """Log in as the accounts.yaml entry `account_key`; None for `none`. Returns `access`,
    `refresh` and (web admins) `admin` and `is_super_user`."""
    if account_key in (None, "none"):
        return None
    account = CONFIG.accounts_config.get(account_key)
    if not account or not account.get("email"):
        raise ApiError(f"account {account_key!r} is not in accounts.yaml or has no email login", 400)
    is_admin = account.get("platform") == "web" and account.get("role") != "member"
    path = "/api/v1/auth/admin/login" if is_admin else "/api/v1/auth/member/login"
    status, text = _post_json(backend_base() + path, {"email": account["email"], "password": account["password"]})
    if status != 200:
        raise ApiError(f"login as {account_key} answered {status}: {text[:200]}", 502)
    payload = json.loads(text)
    tokens = payload.get("tokens", payload)
    profile = payload.get("profile") or {}
    return {"access": tokens["accessToken"], "refresh": tokens["refreshToken"],
            "admin": profile.get("admin"), "support_grant": profile.get("supportGrant"),
            "is_super_user": account.get("role") == "super_user"}


# --- probe ----------------------------------------------------------------------

def _lookup(value, dotted: str):
    for part in dotted.split("."):
        value = value[int(part)] if isinstance(value, list) else value[part]
    return value


def _fill(value, variables: dict):
    """Replace `{name}` in every string of `value` (nested lists and dicts included)."""
    if isinstance(value, str):
        return _VARIABLE.sub(lambda m: str(variables[m.group(1)]) if m.group(1) in variables else m.group(0), value)
    if isinstance(value, list):
        return [_fill(v, variables) for v in value]
    if isinstance(value, dict):
        return {k: _fill(v, variables) for k, v in value.items()}
    return value


def _texts(expected) -> list[str]:
    if expected is None:
        return []
    return [expected] if isinstance(expected, str) else list(expected)


def _send(method: str, url: str, body, token: str | None) -> tuple[int, str]:
    headers = {"Accept": "application/json"}
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=data, method=method.upper(), headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            return response.status, response.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")


def run_probe(check: dict) -> dict:
    """Run the check's probe request(s); returns `{"kind": "probe", "ok", "requests": [...]}`."""
    spec = check["probe"]
    steps = spec if isinstance(spec, list) else [spec]
    session = login(check.get("as", "none"))
    token = session["access"] if session else None
    variables: dict = {}
    requests: list[dict] = []
    for step in steps:
        method = step.get("method", "GET")
        path = _fill(step["path"], variables)
        body = _fill(step.get("body"), variables)
        status, text = _send(method, backend_base() + path, body, token)
        problems = []
        if status != int(step["expect_status"]):
            problems.append(f"status {status}, expected {step['expect_status']}")
        problems += [f"body lacks {t!r}" for t in _texts(step.get("expect_body")) if t not in text]
        if not problems:
            for name, dotted in (step.get("save") or {}).items():
                try:
                    variables[name] = _lookup(json.loads(text), dotted)
                except (ValueError, KeyError, IndexError, TypeError):
                    problems.append(f"cannot save {name!r} from {dotted!r}")
        requests.append({"method": method.upper(), "path": path, "body": body, "status": status,
                         "response": text[:BODY_EXCERPT_CHARS], "problems": problems})
        if problems:
            break
    return {"kind": "probe", "as": check.get("as", "none"), "ok": all(not r["problems"] for r in requests),
            "requests": requests}


# --- page -----------------------------------------------------------------------

def playwright_root(checkout: Path) -> Path:
    """The `web/` directory whose node_modules holds Playwright: the checkout's, else the repo's."""
    for base in (checkout, ROOT):
        if (base / "web" / "node_modules" / "playwright").exists():
            return base / "web"
    raise ApiError("Playwright is not installed: run `pnpm install` in web/", 409)


def run_page(check: dict, candidate_id: str, checkout: Path) -> dict:
    """Open the check's url in headless Chromium; returns `{"kind": "page", "ok", "screenshot", ...}`."""
    spec = check.get("page") or {}
    shot_dir = checkout / ".console" / EVIDENCE_DIR / candidate_id
    shot_dir.mkdir(parents=True, exist_ok=True)
    shot = shot_dir / f"{check['id']}.png"
    session = login(check.get("as", "none"))
    job = {"url": public_url(check["url"]), "expect_text": _texts(spec.get("expect_text")),
           "screenshot": str(shot), "session": session}
    try:
        out = subprocess.run(["node", str(PAGE_SCRIPT), str(playwright_root(checkout))], input=json.dumps(job),
                             capture_output=True, text=True, timeout=PAGE_TIMEOUT_SECONDS, check=False)
    except subprocess.TimeoutExpired:
        return {"kind": "page", "as": check.get("as", "none"), "ok": False, "url": job["url"],
                "problems": [f"page did not finish in {PAGE_TIMEOUT_SECONDS}s"], "screenshot": None}
    try:
        report = json.loads(out.stdout)
    except ValueError:
        report = {"ok": False, "problems": [f"page_check failed: {(out.stderr or out.stdout)[-300:]}"]}
    return {"kind": "page", "as": check.get("as", "none"), "url": job["url"], "ok": report["ok"],
            "problems": report.get("problems", []), "title": report.get("title"),
            "screenshot": f"{candidate_id}/{shot.name}" if shot.exists() else None}


# --- run all --------------------------------------------------------------------

def run_check(check: dict, candidate_id: str, checkout: Path) -> dict:
    try:
        if "probe" in check:
            return run_probe(check)
        if "page" in check:
            return run_page(check, candidate_id, checkout)
        return {"kind": "none", "ok": False, "problems": ["auto: true needs a probe or a page block"]}
    except ApiError as e:
        return {"kind": "probe" if "probe" in check else "page", "ok": False, "problems": [str(e)]}
    except OSError as e:
        return {"kind": "probe" if "probe" in check else "page", "ok": False,
                "problems": [f"cannot reach the services: {e}"]}


def run_auto_checks(candidate: dict, data: dict, checkout: Path) -> dict:
    """Run every auto check of `candidate`; pre-tick each in `data["checks"]` with its evidence.
    Returns `data`. Manual checks are not touched."""
    for check in candidate["checks"]:
        if not is_auto(check):
            continue
        evidence = run_check(check, candidate["id"], checkout)
        entry = data["checks"].setdefault(check["id"], {"result": None, "note": "", "issue_url": None})
        entry["result"] = "pass" if evidence["ok"] else "fail"
        entry["auto"] = evidence
    return data
