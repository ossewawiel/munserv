"""A small client for the factory console's HTTP API (scripts/console/server.py).

The TUI owns no process. Every start, stop and log read goes through the console, which already
tracks the process groups it started, so the TUI, the console's web UI and the factory agree on
what runs. Requests come from localhost, which the console serves without its access token.
Standard library only, so the client is testable without Textual.
"""
from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass

DEFAULT_BASE_URL = "http://localhost:3999"
TIMEOUT_SECONDS = 10


class ConsoleError(Exception):
    """The console is unreachable or refused a request."""


@dataclass(frozen=True)
class Service:
    name: str
    up: bool
    running: bool
    manual: bool
    url: str
    exit_code: int | None
    needs_prepare: bool

    @property
    def state(self) -> str:
        """One word for the table: up, starting, exited, manual or stopped."""
        if self.up:
            return "up"
        if self.running:
            return "starting"
        if self.manual:
            return "manual"
        if self.exit_code not in (None, 0):
            return "exited"
        return "stopped"

    @property
    def port(self) -> str:
        """The port in the service's address, or an empty string when it has none."""
        try:
            port = urllib.parse.urlparse(self.url).port
        except ValueError:
            return ""
        return str(port) if port else ""

    @property
    def health(self) -> str:
        """The health check's word: healthy, waiting (process up, check failing), down or n/a (manual)."""
        if self.manual:
            return "n/a"
        if self.up:
            return "healthy"
        return "waiting" if self.running else "down"

    @classmethod
    def from_json(cls, data: dict) -> Service:
        return cls(
            name=data["name"],
            up=bool(data.get("up")),
            running=bool(data.get("running")),
            manual=bool(data.get("manual")),
            url=data.get("url") or "",
            exit_code=data.get("exit_code"),
            needs_prepare=bool(data.get("needs_prepare")),
        )


@dataclass(frozen=True)
class Checkout:
    path: str
    branch: str
    sha: str


@dataclass(frozen=True)
class State:
    checkout: Checkout
    services: tuple[Service, ...]


@dataclass(frozen=True)
class Remote:
    host: str
    urls: dict[str, str]
    firewall_command: str


class ConsoleApi:
    def __init__(self, base_url: str = DEFAULT_BASE_URL) -> None:
        self.base_url = base_url.rstrip("/")

    def _request(self, method: str, path: str, body: dict | None = None) -> dict:
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base_url + path, data=data, method=method)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as resp:
                return json.loads(resp.read() or b"{}")
        except urllib.error.HTTPError as err:
            try:
                message = json.loads(err.read() or b"{}").get("error") or err.reason
            except json.JSONDecodeError:
                message = err.reason
            raise ConsoleError(f"{method} {path}: {message}") from err
        except (urllib.error.URLError, TimeoutError, ConnectionError) as err:
            raise ConsoleError(f"the console at {self.base_url} is not answering") from err

    def state(self) -> State:
        data = self._request("GET", "/api/state")
        checkout = data.get("checkout") or {}
        return State(
            checkout=Checkout(
                path=checkout.get("path") or "",
                branch=checkout.get("branch") or "",
                sha=(checkout.get("sha") or "")[:7],
            ),
            services=tuple(Service.from_json(s) for s in data.get("services", [])),
        )

    def remote(self) -> Remote:
        data = self._request("GET", "/api/remote")
        return Remote(
            host=data.get("host") or "localhost",
            urls=dict(data.get("urls") or {}),
            firewall_command=(data.get("firewall") or {}).get("command") or "",
        )

    def refresh(self) -> None:
        self._request("POST", "/api/refresh", {})

    def log(self, name: str) -> str:
        query = urllib.parse.urlencode({"name": name})
        return self._request("GET", f"/api/log?{query}").get("log", "")

    def start(self, name: str) -> str:
        return self._request("POST", "/api/service/start", {"name": name}).get("message", "")

    def stop(self, name: str) -> str:
        return self._request("POST", "/api/service/stop", {"name": name}).get("message", "")
