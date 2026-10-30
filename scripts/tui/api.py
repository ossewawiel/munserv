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
from dataclasses import dataclass, field

DEFAULT_BASE_URL = "http://localhost:3999"
TIMEOUT_SECONDS = 10
UPDATE_TIMEOUT_SECONDS = 120  # the showcase update runs git fetch inside the request
PHONE_TIMEOUT_SECONDS = 45  # adb pair waits up to 30 seconds for the phone


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
class Showcase:
    exists: bool
    sha: str
    built_sha: str
    master_sha: str


@dataclass(frozen=True)
class State:
    checkout: Checkout
    services: tuple[Service, ...]
    showcase: Showcase | None = None


@dataclass(frozen=True)
class Device:
    id: str
    state: str
    model: str
    release: str
    sdk: int

    @classmethod
    def from_json(cls, data: dict) -> Device:
        android = data.get("android") or {}
        return cls(id=data["id"], state=data.get("state") or "", model=(data.get("model") or "").replace("_", " "),
                   release=android.get("release") or "", sdk=int(android.get("sdk") or 0))


@dataclass(frozen=True)
class Phone:
    lan_ip: str
    min_sdk: int
    ports: dict[str, int]
    devices: tuple[Device, ...]


@dataclass(frozen=True)
class Job:
    status: str
    message: str


@dataclass(frozen=True)
class Remote:
    host: str
    urls: dict[str, str]
    firewall_command: str
    showcase_urls: dict[str, str] = field(default_factory=dict)
    showcase_firewall_command: str = ""


class ConsoleApi:
    def __init__(self, base_url: str = DEFAULT_BASE_URL) -> None:
        self.base_url = base_url.rstrip("/")

    def _request(self, method: str, path: str, body: dict | None = None, timeout: int = TIMEOUT_SECONDS) -> dict:
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base_url + path, data=data, method=method)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
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
            showcase=self._showcase(data.get("showcase")),
        )

    @staticmethod
    def _showcase(data: dict | None) -> Showcase | None:
        if not data:
            return None
        return Showcase(exists=bool(data.get("exists")), sha=data.get("sha") or "",
                        built_sha=data.get("built_sha") or "", master_sha=data.get("master_sha") or "")

    def remote(self) -> Remote:
        data = self._request("GET", "/api/remote")
        return Remote(
            host=data.get("host") or "localhost",
            urls=dict(data.get("urls") or {}),
            firewall_command=(data.get("firewall") or {}).get("command") or "",
            showcase_urls=dict((data.get("showcase") or {}).get("urls") or {}),
            showcase_firewall_command=((data.get("showcase") or {}).get("firewall") or {}).get("command") or "",
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

    def showcase_update(self) -> str:
        return self._request("POST", "/api/showcase/update", {}, timeout=UPDATE_TIMEOUT_SECONDS).get("message", "")

    def showcase_build(self) -> str:
        job = self._request("POST", "/api/showcase/build", {}).get("job") or {}
        return f"showcase build {job.get('status', 'started')}"

    def showcase_start(self) -> str:
        return self._request("POST", "/api/showcase/start", {}).get("message", "")

    def showcase_stop(self) -> str:
        return self._request("POST", "/api/showcase/stop", {}).get("message", "")

    def phone(self) -> Phone:
        data = self._request("GET", "/api/mobile/devices")
        return Phone(
            lan_ip=data.get("lan_ip") or "",
            min_sdk=int(data.get("min_android_sdk") or 0),
            ports={"eyeball": int(data.get("api_port") or 0), "showcase": int(data.get("showcase_api_port") or 0)},
            devices=tuple(Device.from_json(d) for d in data.get("devices", [])),
        )

    def install_job(self) -> Job | None:
        """The newest phone build-and-install job, or None before the first."""
        jobs = [j for j in self._request("GET", "/api/state").get("jobs", [])
                if j.get("service") == "mobile" and j.get("kind") == "install"]
        return Job(status=jobs[-1]["status"], message=jobs[-1].get("message") or "") if jobs else None

    def phone_pair(self, address: str, code: str) -> str:
        return self._request("POST", "/api/mobile/pair", {"address": address, "code": code},
                             timeout=PHONE_TIMEOUT_SECONDS).get("message", "")

    def phone_connect(self, address: str) -> str:
        return self._request("POST", "/api/mobile/connect", {"address": address},
                             timeout=PHONE_TIMEOUT_SECONDS).get("message", "")

    def phone_install(self, device_id: str, source: str) -> None:
        self._request("POST", "/api/mobile/install", {"device_id": device_id, "source": source})

    def phone_launch(self, device_id: str) -> str:
        return self._request("POST", "/api/mobile/launch", {"device_id": device_id}).get("message", "")

    def phone_logcat(self, device_id: str) -> str:
        return self._request("POST", "/api/mobile/logcat", {"device_id": device_id}).get("message", "")

    def phone_logcat_stop(self) -> str:
        return self._request("POST", "/api/mobile/logcat/stop", {}).get("message", "")
