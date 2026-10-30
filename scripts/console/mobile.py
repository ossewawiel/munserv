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
from .network import detect_active_firewall, firewall_remedy, lan_ip, lan_subnet

_DEVICE_ID_RE = re.compile(r"^[A-Za-z0-9_.:-]+$")
_ADDRESS_RE = re.compile(r"^(?:\d{1,3}\.){3}\d{1,3}:\d{1,5}$")
_PAIRING_CODE_RE = re.compile(r"^\d{6}$")

APP_ID = "com.munserv.munserv_mobile"  # mobile/android/app/build.gradle.kts applicationId
MIN_ANDROID_SDK = 30  # Android 11: the first release with wireless debugging pairing
ADB_TIMEOUT_SECONDS = 10
ADB_PAIR_TIMEOUT_SECONDS = 30
INSTALL_LOG = "mobile-install"
LOGCAT_PROCESS = "phone-logcat"
REACHABILITY_INTERVAL_SECONDS = 30
NC_TIMEOUT_SECONDS = 3
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


def validate_address(value: str) -> str:
    if not isinstance(value, str) or not _ADDRESS_RE.match(value):
        raise ApiError(f"invalid address, expected <ip>:<port>: {value!r}", 400)
    return value


def validate_pairing_code(value: str) -> str:
    if not isinstance(value, str) or not _PAIRING_CODE_RE.match(value):
        raise ApiError("the pairing code is six digits", 400)
    return value


def _adb(args: list[str], timeout: int = ADB_TIMEOUT_SECONDS) -> subprocess.CompletedProcess:
    if not shutil.which("adb"):
        raise ApiError("adb is not installed on this machine", 409)
    try:
        return subprocess.run(["adb", *args], text=True, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        raise ApiError(f"adb {args[0]} timed out after {timeout} seconds", 409) from e
    except OSError as e:
        raise ApiError(f"adb {args[0]} failed: {e}", 409) from e


def _adb_message(result: subprocess.CompletedProcess) -> str:
    return (result.stdout + result.stderr).strip()


def pair(address: str, code: str) -> str:
    """`adb pair <ip>:<port> <code>` with the address and code the phone shows on its "Pair device
    with pairing code" dialog. adb exits 0 even on a wrong code, so success is read from its text."""
    result = _adb(["pair", validate_address(address), validate_pairing_code(code)], ADB_PAIR_TIMEOUT_SECONDS)
    message = _adb_message(result)
    if "Successfully paired" not in message:
        raise ApiError(message or "adb pair printed nothing", 409)
    return message


def connect(address: str) -> str:
    """`adb connect <ip>:<port>` with the address on the phone's Wireless debugging screen (a
    different port from the pairing dialog's). adb exits 0 on failure, so read its text."""
    message = _adb_message(_adb(["connect", validate_address(address)]))
    if not message.startswith(("connected to", "already connected to")):
        raise ApiError(message or "adb connect printed nothing", 409)
    return message


_android_versions: dict[str, dict] = {}


def android_version(device_id: str) -> dict | None:
    """{"release": "14", "sdk": 34} read from the phone's build properties; None while the phone
    does not answer (unauthorized, offline). A successful answer is cached: it cannot change."""
    cached = _android_versions.get(device_id)
    if cached:
        return cached
    try:
        result = _adb(["-s", device_id, "shell", "getprop ro.build.version.release; getprop ro.build.version.sdk"])
    except ApiError:
        return None
    lines = result.stdout.split()
    if result.returncode != 0 or len(lines) != 2 or not lines[1].isdigit():
        return None
    version = {"release": lines[0], "sdk": int(lines[1])}
    _android_versions[device_id] = version
    return version


def describe_devices(rows: list[dict]) -> list[dict]:
    """Each device row plus `android` ({release, sdk} or None) for the phones that answer."""
    return [{**row, "android": android_version(row["id"]) if row["state"] == "device" else None} for row in rows]


def launch_app(device_id: str) -> str:
    device_id = validate_device_id(device_id)
    result = _adb(["-s", device_id, "shell", "monkey", "-p", APP_ID, "-c", "android.intent.category.LAUNCHER", "1"])
    if result.returncode != 0 or "No activities found" in _adb_message(result):
        raise ApiError(f"could not open {APP_ID}: {_adb_message(result)}", 409)
    return f"opened {APP_ID} on {device_id}"


# --- install (background job) --------------------------------------------

def _mobile_dir(checkout: Path) -> Path:
    return checkout / "mobile"


def start_install(device_id: str, checkout: Path, api_port_override: int | None = None,
                  log_root: Path | None = None) -> dict:
    """Build the debug APK from `checkout`, install it and open it. The phone's backend port is
    `api_port_override` (the showcase's), else the configured dev one. The job's log lives under
    `log_root` (default: `checkout`) so the console's /api/log finds it whichever checkout builds."""
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
    thread = threading.Thread(target=_run_install_job, daemon=True, args=(
        job["id"], device_id, checkout, api_port_override or api_port(), log_root or checkout))
    thread.start()
    return job


def _run_install_job(job_id: str, device_id: str, checkout: Path, backend_port: int, log_root: Path) -> None:
    mobile_dir = _mobile_dir(checkout)
    log_path = services_mod.log_path(log_root, INSTALL_LOG)
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
                         f"--dart-define=API_HOST={host}", f"--dart-define=API_PORT={backend_port}"]
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
            logf.write(f"launching {APP_ID}\n")
            logf.flush()
            try:
                launch_app(device_id)
            except ApiError as e:
                services_mod.finish_job(job_id, "failed", f"installed, but {e}")
                return
            services_mod.finish_job(job_id, "success", f"installed and opened on {device_id}")
        except Exception as e:  # noqa: BLE001 - a job must never crash the server thread
            services_mod.finish_job(job_id, "failed", str(e))


# The install log is tailed the same way any other service's is: GET /api/log?name=mobile-install
# reads services.log_path(checkout, INSTALL_LOG), the exact path _run_install_job writes to.


# --- logcat (tracked process) ----------------------------------------------

def start_logcat(device_id: str, log_root: Path) -> str:
    """Tail the phone's log, filtered to the app's process, into the `phone-logcat` log. The filter
    is the app's pid (`logcat --pid`, Android 7+), so the app must be running when this starts; a
    relaunch changes the pid and needs a restart of the tail."""
    device_id = validate_device_id(device_id)
    pid = _adb(["-s", device_id, "shell", "pidof", "-s", APP_ID]).stdout.strip()
    if not pid.isdigit():
        raise ApiError("The app is not running on the phone. Open it, then start the log.", 409)
    services_mod.stop_service(LOGCAT_PROCESS, log_root)
    services_mod.log_path(log_root, LOGCAT_PROCESS).write_text("", encoding="utf-8")
    command = f"adb -s {shlex.quote(device_id)} logcat -v time --pid={pid}"
    return services_mod.start_tracked_process(LOGCAT_PROCESS, log_root, command, log_root)


def stop_logcat(log_root: Path) -> str:
    return services_mod.stop_service(LOGCAT_PROCESS, log_root)


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
