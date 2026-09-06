"""Phone support: adb device discovery, this machine's LAN address, and the background jobs that
put the latest mobile build on a connected phone.

The emulator reaches the dev backend on 10.0.2.2 (mobile/lib/shared/providers/dio_provider.dart's
`--dart-define=API_HOST` default) -- a route that only exists inside the emulator's own virtual
network. A physical phone on the same Wi-Fi needs this machine's real LAN address instead. `install`
and `run` both discover that address themselves and pass it through the same `--dart-define`
contract the emulator uses, just with a different host.

`install` is a one-shot background job, tracked with the same job dict shape (and the same
`services.new_job`/`finish_job` machinery) the "Prepare" step uses, so its progress polls through
`/api/state` like any other job. `run` instead starts `flutter run` as a tracked *process* (via
`services.start_tracked_process`), the same mechanism a configured service uses, so its log tails
and its Stop button work exactly like every other row in the Services panel.

Both call `gitops.copy_local_files` before touching `flutter` at all, and both run `flutter`/`adb`
with `cwd` inside `checkout` (the `mobile/` subdirectory) rather than the console's own directory:
a `flutter` that is actually a mise shim resolves its version by walking up from `cwd`, so it only
finds the checkout's own `mise.local.toml`/`.tool-versions` (copied in alongside it) when `cwd` is
somewhere under that checkout -- never the factory's own toolchain pin.
"""
from __future__ import annotations

import re
import shlex
import shutil
import subprocess
import threading
import time
from pathlib import Path

from . import services as services_mod
from .gitops import ApiError, copy_local_files, is_worktree

_DEVICE_ID_RE = re.compile(r"^[A-Za-z0-9_.:-]+$")
_IPV4_RE = re.compile(r"^\d{1,3}(?:\.\d{1,3}){3}$")

ADB_TIMEOUT_SECONDS = 10
IP_COMMAND_TIMEOUT_SECONDS = 5
REACHABILITY_INTERVAL_SECONDS = 30
NC_TIMEOUT_SECONDS = 3
FIREWALL_CHECK_TIMEOUT_SECONDS = 5
WEB_PORT = 3000


def validate_device_id(value: str) -> str:
    if not isinstance(value, str) or not value or not _DEVICE_ID_RE.match(value):
        raise ApiError(f"invalid device id: {value!r}", 400)
    return value


def _mobile_config() -> dict:
    return services_mod.services_config().get("mobile") or {}


def emulator_host() -> str:
    return str(_mobile_config().get("emulator_host", "10.0.2.2"))


def api_port() -> int:
    return int(_mobile_config().get("api_port", 8080))


# --- adb ----------------------------------------------------------------

def devices() -> list[dict]:
    """[{id, model, state}], parsed from `adb devices -l`. An empty list -- never an error -- when
    adb is not on PATH, the daemon fails to start, or the command times out: "no phone attached"
    and "no Android SDK on this machine" must both read as an empty device list, not a broken
    panel."""
    if not shutil.which("adb"):
        return []
    try:
        result = subprocess.run(["adb", "devices", "-l"], text=True, capture_output=True,
                                 timeout=ADB_TIMEOUT_SECONDS)
    except (OSError, subprocess.TimeoutExpired):
        return []
    if result.returncode != 0:
        return []
    return parse_devices(result.stdout)


def parse_devices(output: str) -> list[dict]:
    """Parse `adb devices -l` output, e.g.:

        List of devices attached
        R58N30ABCDE     device usb:1-1 product:foo model:Galaxy_S21 device:foo transport_id:3
        emulator-5554   device product:sdk_gphone64 model:sdk_gphone64_x86_64 device:emu64 transport_id:1
        192.168.1.20:5555 unauthorized transport_id:5

    The first line is a header, not a device; a device with no `model:` token (or one that is
    `unauthorized`/`offline`, which reports no extra tokens at all) still gets a row, with
    `model: None`.
    """
    rows: list[dict] = []
    for line in output.splitlines()[1:]:
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        device_id, state = parts[0], parts[1]
        model = None
        for token in parts[2:]:
            if token.startswith("model:"):
                model = token.split(":", 1)[1]
        rows.append({"id": device_id, "state": state, "model": model})
    return rows


# --- LAN address ----------------------------------------------------------

def lan_ip() -> str | None:
    """This machine's LAN IPv4 address -- what a phone on the same network calls the dev backend
    on. `ip -4 -o addr show scope global` first (excludes loopback and link-local by construction,
    and is what most Linux dev machines have); `hostname -I` as a fallback for an environment
    without `ip`. `None` when neither yields an address (no network, or neither tool exists)."""
    return _lan_ip_via_ip_command() or _lan_ip_via_hostname()


def _first_ipv4(text: str) -> str | None:
    for token in text.replace("/", " ").split():
        if _IPV4_RE.match(token) and not token.startswith("127."):
            return token
    return None


def _lan_ip_via_ip_command() -> str | None:
    try:
        result = subprocess.run(["ip", "-4", "-o", "addr", "show", "scope", "global"], text=True,
                                 capture_output=True, timeout=IP_COMMAND_TIMEOUT_SECONDS)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    return _first_ipv4(result.stdout)


def _lan_ip_via_hostname() -> str | None:
    try:
        result = subprocess.run(["hostname", "-I"], text=True, capture_output=True,
                                 timeout=IP_COMMAND_TIMEOUT_SECONDS)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    return _first_ipv4(result.stdout)


# --- install (background job) --------------------------------------------

def _mobile_dir(checkout: Path) -> Path:
    return checkout / "mobile"


def start_install(device_id: str, checkout: Path) -> dict:
    device_id = validate_device_id(device_id)
    mobile_dir = _mobile_dir(checkout)
    if not mobile_dir.is_dir():
        raise ApiError("Check out a branch first", 409)
    if is_worktree(checkout):
        copy_local_files(checkout)
    existing = services_mod.running_job("mobile", "install")
    if existing:
        return existing
    job = services_mod.new_job("mobile", "install")
    thread = threading.Thread(target=_run_install_job, args=(job["id"], device_id, checkout), daemon=True)
    thread.start()
    return job


def _run_install_job(job_id: str, device_id: str, checkout: Path) -> None:
    mobile_dir = _mobile_dir(checkout)
    log_path = services_mod.log_dir(checkout) / "mobile-install.log"
    with open(log_path, "a", encoding="utf-8") as logf:
        logf.write(f"\n--- install start {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
        logf.flush()
        try:
            if not (mobile_dir / ".dart_tool").exists():
                logf.write("no .dart_tool yet -- running flutter pub get\n")
                logf.flush()
                result = subprocess.run(["flutter", "pub", "get"], cwd=mobile_dir, stdout=logf,
                                         stderr=subprocess.STDOUT)
                if result.returncode != 0:
                    services_mod.finish_job(job_id, "failed", f"flutter pub get exit {result.returncode}")
                    return
            host = lan_ip()
            if not host:
                services_mod.finish_job(job_id, "failed", "could not determine this machine's LAN address")
                return
            build_cmd = ["flutter", "build", "apk", "--debug",
                         f"--dart-define=API_HOST={host}", f"--dart-define=API_PORT={api_port()}"]
            logf.write(" ".join(build_cmd) + "\n")
            logf.flush()
            result = subprocess.run(build_cmd, cwd=mobile_dir, stdout=logf, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                services_mod.finish_job(job_id, "failed", f"flutter build apk exit {result.returncode}")
                return
            apk = mobile_dir / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
            install_cmd = ["adb", "-s", device_id, "install", "-r", str(apk)]
            logf.write(" ".join(install_cmd) + "\n")
            logf.flush()
            result = subprocess.run(install_cmd, stdout=logf, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                services_mod.finish_job(job_id, "failed", f"adb install exit {result.returncode}")
                return
            services_mod.finish_job(job_id, "success", f"installed on {device_id}")
        except Exception as e:  # noqa: BLE001 - a job must never crash the server thread
            services_mod.finish_job(job_id, "failed", str(e))


# The install log is tailed the same way any other service's is: GET /api/log?name=mobile-install
# reads services.log_path(checkout, "mobile-install"), the exact path _run_install_job writes to.


# --- run (tracked process) ------------------------------------------------

def start_run(device_id: str, checkout: Path) -> str:
    device_id = validate_device_id(device_id)
    mobile_dir = _mobile_dir(checkout)
    if not mobile_dir.is_dir():
        raise ApiError("Check out a branch first", 409)
    if is_worktree(checkout):
        copy_local_files(checkout)
    host = lan_ip()
    if not host:
        raise ApiError("Could not determine this machine's LAN address", 409)
    command = (f"flutter run -d {shlex.quote(device_id)} "
               f"--dart-define=API_HOST={host} --dart-define=API_PORT={api_port()}")
    return services_mod.start_tracked_process("mobile", checkout, command, mobile_dir)


# --- phone reachability ----------------------------------------------------
#
# Whether the phone can actually reach this machine's backend (and, once it is up, the web
# service) matters as much as whether the phone is plugged in: a phone that adb sees fine but
# whose Wi-Fi network has this machine's firewall blocking the port looks, to a tester, exactly
# like a backend that is not running. `adb shell toybox nc` runs the reachability probe *from the
# phone itself* -- ordinary `nc`/`ping` from this machine only proves this machine can route to
# itself, not that the phone's network path is open. One background thread per (device, port)
# polls every REACHABILITY_INTERVAL_SECONDS so the Phone panel's 10s poll of /api/mobile/devices
# never blocks on a live probe.

_reachability_lock = threading.Lock()
_reachability: dict[str, dict] = {}  # f"{device_id}:{port}" -> {"reachable": bool, "checked_at": float}
_reachability_threads: dict[str, threading.Thread] = {}


def _reachability_key(device_id: str, port: int) -> str:
    return f"{device_id}:{port}"


def probe_reachable(device_id: str, host: str, port: int) -> bool:
    """True when the phone identified by `device_id` can open a TCP connection to `host:port` --
    run *from the phone* via `adb shell toybox nc`, with stdin closed (`</dev/null`) so `nc` never
    blocks waiting for input to relay once the connection succeeds. False (never an exception) on
    any adb/nc failure, including a timeout: an unreachable phone is exactly what this is checking
    for, not an error to propagate."""
    try:
        result = subprocess.run(
            ["adb", "-s", device_id, "shell", "toybox", "nc", "-w", str(NC_TIMEOUT_SECONDS), host, str(port)],
            stdin=subprocess.DEVNULL, capture_output=True, timeout=NC_TIMEOUT_SECONDS + 5)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0


def _reachability_loop(device_id: str, host: str, port: int) -> None:
    key = _reachability_key(device_id, port)
    while True:
        reachable = probe_reachable(device_id, host, port)
        with _reachability_lock:
            _reachability[key] = {"reachable": reachable, "checked_at": time.time()}
        time.sleep(REACHABILITY_INTERVAL_SECONDS)


def ensure_reachability_watch(device_id: str, host: str, port: int) -> None:
    """Start the background probe loop for (device_id, port) if it is not already running. Safe
    to call on every poll of /api/mobile/devices -- a live thread is left alone."""
    key = _reachability_key(device_id, port)
    with _reachability_lock:
        existing = _reachability_threads.get(key)
        if existing and existing.is_alive():
            return
        thread = threading.Thread(target=_reachability_loop, args=(device_id, host, port), daemon=True)
        _reachability_threads[key] = thread
        thread.start()


def reachability_status(device_id: str, port: int) -> dict | None:
    with _reachability_lock:
        return _reachability.get(_reachability_key(device_id, port))


def lan_subnet(ip: str) -> str:
    """192.168.1.42 -> 192.168.1.0/24, the /24 a ufw `allow from` rule names. Returns `ip`
    unchanged when it is not a plain IPv4 address (nothing sensible to derive a subnet from)."""
    parts = ip.split(".")
    if len(parts) != 4:
        return ip
    return ".".join(parts[:3]) + ".0/24"


def detect_active_firewall() -> str | None:
    """'ufw', 'firewalld', or None -- whichever of the two this machine's systemd reports active,
    checked in that order. Neither being present or `systemctl` itself being unavailable (a
    non-systemd machine) both read as None, the "no known firewall" case."""
    for name in ("ufw", "firewalld"):
        try:
            result = subprocess.run(["systemctl", "is-active", name], text=True, capture_output=True,
                                     timeout=FIREWALL_CHECK_TIMEOUT_SECONDS)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if result.returncode == 0 and result.stdout.strip() == "active":
            return name
    return None


def firewall_remedy(active_firewall: str | None, port: int, subnet: str) -> str:
    """The exact command (or, with neither firewall detected, a generic hint) that unblocks
    `port` for phones on `subnet` -- the command the tester hit today for ufw blocking 8080."""
    if active_firewall == "ufw":
        return f"sudo ufw allow from {subnet} to any port {port} proto tcp"
    if active_firewall == "firewalld":
        return f"sudo firewall-cmd --add-port={port}/tcp"
    return f"Check this machine's firewall for a rule blocking port {port}."


def _device_reachability(device_id: str, port: int) -> dict:
    status = reachability_status(device_id, port)
    if status is None:
        return {"reachable": None, "checked_at": None, "remedy": None}
    remedy = None
    if not status["reachable"]:
        remedy = firewall_remedy(detect_active_firewall(), port, lan_subnet(lan_ip() or ""))
    return {"reachable": status["reachable"], "checked_at": status["checked_at"], "remedy": remedy}


def reachability_snapshot(devices: list[dict], host: str | None, backend_port: int, web_up: bool) -> dict:
    """{device_id: {"backend": {...}, "web": {...} | None}} for every authorized device -- starts
    (or leaves running) the background probe for each, and reports whatever the last probe found.
    An unauthorized/offline device (adb sees it but the phone has not accepted the debugging
    prompt) is skipped entirely: probing it would just report "unreachable" for a reason that has
    nothing to do with the network. `web` is None (not "unreachable") until the web service is up,
    since a probe against a service nobody has started yet is not a useful signal."""
    result: dict = {}
    if not host:
        return result
    for device in devices:
        if device.get("state") != "device":
            continue
        device_id = device["id"]
        ensure_reachability_watch(device_id, host, backend_port)
        entry = {"backend": _device_reachability(device_id, backend_port)}
        if web_up:
            ensure_reachability_watch(device_id, host, WEB_PORT)
            entry["web"] = _device_reachability(device_id, WEB_PORT)
        else:
            entry["web"] = None
        result[device_id] = entry
    return result
