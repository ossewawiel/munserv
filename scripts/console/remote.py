"""Remote eyeball mode: the console and the services listen on the LAN so a tester on another
machine can open the printed links, and every non-loopback request to the console needs an access
token. Local mode (the default of `--local`, or `enabled: false` in project.yaml) behaves exactly
as before: everything on localhost, no token.

The token lives in a file (default under the XDG state dir) so it is stable across restarts and a
bookmarked console link keeps working. It is never logged and never shown to a remote user.
"""
from __future__ import annotations

import hmac
import ipaddress
import os
import secrets
import shlex
import socket
import time
from http.cookies import SimpleCookie

from . import demo_input, network
from .config import CONFIG

LOCAL_HOST = "localhost"
TOKEN_COOKIE = "console_token"
TOKEN_QUERY = "token"
TOKEN_HEADER = "X-Console-Token"
TOKEN_FILE_MODE = 0o600
TOKEN_BYTES = 32

HOST_CACHE_SECONDS = 30

_override: bool | None = None
_host_cache: dict = {"value": "", "at": None}


def set_mode(enabled: bool | None) -> None:
    """Force remote mode on or off for this process (the `--remote` / `--local` flags); `None`
    defers to project.yaml."""
    global _override
    _override = enabled


def enabled() -> bool:
    return CONFIG.remote["enabled"] if _override is None else _override


def listen_address() -> str:
    """The address the console's own HTTP server binds."""
    return CONFIG.remote["bind"] if enabled() else LOCAL_HOST


def hostname() -> str:
    return socket.gethostname()


def host() -> str:
    """What a browser on another machine calls this one: the LAN address, or the hostname when no
    address is found. `localhost` in local mode. The address lookup shells out, so it is cached
    briefly; the state poll expands services.yaml every few seconds."""
    if not enabled():
        return LOCAL_HOST
    now = time.monotonic()
    if _host_cache["at"] is None or now - _host_cache["at"] > HOST_CACHE_SECONDS:
        _host_cache.update(value=network.lan_ip() or hostname(), at=now)
    return _host_cache["value"]


def api_base() -> str:
    """Prefix of the web client's API URL. Empty in remote mode: the client then calls the same
    origin and the Vite proxy forwards `/api` to the backend, so a remote browser never needs to
    reach `localhost:8080` or pass a CORS check."""
    if enabled():
        return ""
    return f"http://{LOCAL_HOST}:{CONFIG.remote['ports']['backend']}"


def expand(text: str) -> str:
    """Fill the `{bind}`, `{host}`, `{hostname}`, `{api_base}` and `{demo_accounts_web}` placeholders
    in a services.yaml value. Plain replacement, so other braces in a shell command are left alone."""
    values = {"{bind}": listen_address, "{host}": host, "{hostname}": hostname, "{api_base}": api_base,
              "{demo_accounts_web}": lambda: shlex.quote(demo_input.web_value())}
    for key, value in values.items():
        if key in text:
            text = text.replace(key, value())
    return text


def ports(console_port: int) -> dict[str, int]:
    return {**CONFIG.remote["ports"], "console": console_port}


def urls(console_port: int) -> dict[str, str]:
    configured = ports(console_port)
    base = host()
    return {
        "web": f"http://{base}:{configured['web']}",
        "swagger": f"http://{base}:{configured['backend']}{CONFIG.remote['swagger_path']}",
        "console": f"http://{base}:{console_port}",
    }


def console_url(console_port: int, with_token: bool) -> str:
    """The console's address for a browser; carries the access token only when asked and only in
    remote mode (local mode has none)."""
    url = urls(console_port)["console"]
    return f"{url}/?{TOKEN_QUERY}={token()}" if with_token and enabled() else url


def allowed_origins(console_port: int) -> set[str]:
    origins = {f"http://{LOCAL_HOST}:{console_port}", f"http://127.0.0.1:{console_port}"}
    if enabled():
        origins |= {f"http://{host()}:{console_port}", f"http://{hostname()}:{console_port}"}
    return origins


# --- access token -----------------------------------------------------------

def token() -> str:
    """The access token, created (0600) on first use and read back on every later start."""
    path = CONFIG.remote["token_file"]
    if path.exists():
        return path.read_text(encoding="utf-8").strip()
    path.parent.mkdir(parents=True, exist_ok=True)
    value = secrets.token_urlsafe(TOKEN_BYTES)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, TOKEN_FILE_MODE)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(value)
    return value


def is_loopback(address: str) -> bool:
    try:
        return ipaddress.ip_address(address).is_loopback
    except ValueError:
        return False


def token_matches(candidate: str | None) -> bool:
    return bool(candidate) and hmac.compare_digest(candidate.encode("utf-8"), token().encode("utf-8"))


def cookie_token(cookie_header: str | None) -> str | None:
    if not cookie_header:
        return None
    jar = SimpleCookie()
    try:
        jar.load(cookie_header)
    except Exception:  # noqa: BLE001 - a malformed Cookie header is simply "no token"
        return None
    morsel = jar.get(TOKEN_COOKIE)
    return morsel.value if morsel else None


def cookie_header(value: str) -> str:
    return f"{TOKEN_COOKIE}={value}; HttpOnly; SameSite=Strict; Path=/"


def granted_by(client_address: str, headers, query: dict) -> str | None:
    """How the request is allowed in: "open" (local mode or loopback), "cookie", "header",
    "query", or None when it must be refused."""
    if not enabled() or is_loopback(client_address):
        return "open"
    if token_matches(cookie_token(headers.get("Cookie"))):
        return "cookie"
    if token_matches(headers.get(TOKEN_HEADER)):
        return "header"
    if token_matches((query.get(TOKEN_QUERY) or [None])[0]):
        return "query"
    return None


# --- what the UI and the ensure report show ----------------------------------

def firewall(console_port: int) -> dict:
    active = network.detect_active_firewall()
    subnet = network.lan_subnet(network.lan_ip() or "")
    return {"active": active, "subnet": subnet,
            "command": network.firewall_remedy_for_ports(active, list(ports(console_port).values()), subnet)}


def snapshot(console_port: int, loopback: bool) -> dict:
    """The `remote` block of /api/remote. The tokenised console link is included only for a
    loopback request: a remote user already holds the token, and it is never echoed back."""
    if not enabled():
        return {"enabled": False}
    result_urls = urls(console_port)
    if loopback:
        result_urls["console_with_token"] = console_url(console_port, with_token=True)
    return {"enabled": True, "host": host(), "hostname": hostname(), "urls": result_urls,
            "ports": ports(console_port), "firewall": firewall(console_port)}
