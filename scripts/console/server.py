"""The factory console HTTP server: a JSON API plus static files, localhost only.

Same request-safety posture as the old eyeball dashboard: an Origin header naming anything other
than this server is rejected (no CORS preflight would stop a same-page POST otherwise), and every
POST must carry an explicit `application/json` Content-Type.
"""
from __future__ import annotations

import json
import mimetypes
import signal
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from . import eyeball, github, knowledge, release, services
from .config import CONFIG, ROOT
from .gitops import ApiError, CommandError, checkout_branch, current_branch, current_sha, default_checkout, \
    validate_branch, validate_name

UI_DIR = Path(__file__).resolve().parent / "ui"


def _load_yaml_or_empty(fn):
    try:
        return fn()
    except Exception:  # noqa: BLE001 - a knowledge-source hiccup must not break the whole page
        return None


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
        origin = self.headers.get("Origin")
        if origin and origin not in self._allowed_origins():
            raise ApiError("cross-origin request rejected", 403)

    def _require_json_content_type(self) -> None:
        content_type = (self.headers.get("Content-Type") or "").split(";", 1)[0].strip()
        if content_type != "application/json":
            raise ApiError("Content-Type must be application/json", 403)

    # --- static files --------------------------------------------------

    def _serve_static(self, rel_path: str) -> bool:
        path = (UI_DIR / rel_path.lstrip("/")).resolve()
        if UI_DIR.resolve() not in path.parents and path != UI_DIR.resolve():
            return False
        if not path.is_file():
            return False
        mime, _ = mimetypes.guess_type(str(path))
        data = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", mime or "application/octet-stream")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)
        return True

    # --- routing ---------------------------------------------------------

    def do_GET(self):
        try:
            self._reject_cross_origin()
            parsed = urlparse(self.path)
            path = parsed.path
            if path == "/" or path == "/index.html":
                return self._require_ok(self._serve_static("index.html"))
            if path.startswith("/api/"):
                return self._route_get(path, parse_qs(parsed.query))
            if self._serve_static(path):
                return
            self.send_response(404)
            self.end_headers()
        except ApiError as e:
            self._json({"ok": False, "error": str(e)}, e.status)
        except Exception as e:  # noqa: BLE001 - never let a request bring the server down
            self._json({"ok": False, "error": str(e)}, 500)

    def _require_ok(self, served: bool) -> None:
        if not served:
            self.send_response(404)
            self.end_headers()

    def _route_get(self, path: str, qs: dict) -> None:
        if path == "/api/state":
            return self._api_state()
        if path == "/api/github":
            return self._json(github.get_snapshot())
        if path == "/api/knowledge":
            return self._api_knowledge()
        if path == "/api/release":
            return self._json(release.get_snapshot())
        if path == "/api/eyeball/candidates":
            candidates = eyeball.build_candidates(force=bool(qs.get("refresh")))
            for c in candidates:
                c["results"] = eyeball.load_results(self.checkout, c["id"])
            return self._json({"candidates": candidates, "accounts": CONFIG.accounts_config})
        if path == "/api/log":
            name = validate_name((qs.get("name") or [""])[0], "service name")
            kind = (qs.get("kind") or ["start"])[0]
            log = services.prepare_log(self.checkout, name) if kind == "prepare" else services.tail_log(self.checkout, name)
            return self._json({"log": log})
        self.send_response(404)
        self.end_headers()

    def _api_knowledge(self):
        self._json({
            "concepts": _load_yaml_or_empty(knowledge.domain_concepts) or [],
            "requirements": _load_yaml_or_empty(knowledge.requirements_summary) or [],
            "adrs": _load_yaml_or_empty(knowledge.adr_list) or [],
            "registry": _load_yaml_or_empty(knowledge.registry_pages) or [],
            "tokens": _load_yaml_or_empty(knowledge.color_tokens) or {},
            "canvases": _load_yaml_or_empty(knowledge.design_canvases) or [],
            "fetched_at": time.time(),
        })

    def _api_state(self):
        self._json({
            "checkout": {"path": str(self.checkout), "branch": current_branch(self.checkout),
                         "sha": current_sha(self.checkout)},
            "services": services.state_snapshot(self.checkout),
            "jobs": services.jobs_snapshot(),
            "otp": services.latest_otp(self.checkout),
            "project": {"name": CONFIG.name, "accent": CONFIG.accent, "links": CONFIG.links,
                        "sections": {s: CONFIG.section_enabled(s) for s in
                                     ("overview", "knowledge", "design", "eyeball", "release")}},
            "fetched_at": time.time(),
        })

    def do_POST(self):
        try:
            self._reject_cross_origin()
            self._require_json_content_type()
            self._route_post(self.path, self._read_json())
        except ApiError as e:
            self._json({"ok": False, "error": str(e)}, e.status)
        except CommandError as e:
            self._json({"ok": False, "error": str(e)}, 500)
        except Exception as e:  # noqa: BLE001 - never let a request bring the server down
            self._json({"ok": False, "error": str(e)}, 500)

    def _route_post(self, path: str, body: dict) -> None:
        if path == "/api/refresh":
            github.refresh_now()
            release.refresh_now()
            eyeball.build_candidates(force=True)
            return self._json({"ok": True})
        if path == "/api/checkout":
            branch = validate_branch(body.get("branch", ""))
            branch = checkout_branch(self.checkout, branch)
            return self._json({"ok": True, "branch": branch})
        if path == "/api/prepare":
            name = validate_name(body.get("name", ""), "service name")
            job = services.start_prepare(name, self.checkout)
            return self._json({"ok": True, "job": job})
        if path == "/api/service/start":
            name = validate_name(body.get("name", ""), "service name")
            msg = services.start_service(name, self.checkout)
            return self._json({"ok": True, "message": msg})
        if path == "/api/service/stop":
            name = validate_name(body.get("name", ""), "service name")
            msg = services.stop_service(name, self.checkout)
            return self._json({"ok": True, "message": msg})
        if path == "/api/service/start-required":
            names = [validate_name(n, "service name") for n in body.get("names", [])]
            branch = body.get("branch")
            if branch:
                branch = validate_branch(branch)
                if current_branch(self.checkout) != branch:
                    checkout_branch(self.checkout, branch)
            messages = [services.start_service(n, self.checkout) for n in names]
            return self._json({"ok": True, "messages": messages})
        if path == "/api/eyeball/save":
            candidate_id = validate_name(body.get("candidate", ""), "candidate")
            eyeball.save_results(self.checkout, candidate_id, body.get("data", {}))
            return self._json({"ok": True})
        if path == "/api/eyeball/submit":
            candidate_id = validate_name(body.get("candidate", ""), "candidate")
            candidate = next((c for c in eyeball.build_candidates(False) if c["id"] == candidate_id), None)
            if not candidate:
                return self._json({"ok": False, "error": "unknown candidate"}, 404)
            data = eyeball.load_results(self.checkout, candidate_id)
            data = eyeball.submit(candidate, data, self.checkout)
            return self._json({"ok": True, "data": data})
        self.send_response(404)
        self.end_headers()


def _raise_system_exit(signum, frame):  # noqa: ARG001 - signal handler signature
    raise SystemExit(0)


def run(port: int | None = None, checkout: Path | None = None) -> int:
    Handler.checkout = checkout or default_checkout()
    Handler.checkout.mkdir(parents=True, exist_ok=True)
    github.start_refresher()
    release.start_refresher()
    server = ThreadingHTTPServer(("localhost", port or CONFIG.port), Handler)
    signal.signal(signal.SIGTERM, _raise_system_exit)
    print(f"factory console: http://localhost{'' if (port or CONFIG.port) == 80 else ':' + str(port or CONFIG.port)}/")
    print(f"checkout under test: {Handler.checkout}")
    try:
        server.serve_forever()
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        services.stop_all(Handler.checkout)
    return 0
