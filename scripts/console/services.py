"""Service process management for the checkout under test: start/stop, health checks, log tails,
and a background "Prepare" step per service (installing dependencies a fresh checkout lacks).

A fresh checkout has no web/node_modules, so `pnpm dev` fails immediately with
"vite: command not found" -- and previously that failure sat inside a collapsed log element that
nobody opened. This module tracks each service process explicitly so the moment one exits, the
API can report its exit code and the last meaningful log line, with a remedy ("Run Prepare").
"""
from __future__ import annotations

import os
import shutil
import signal
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

from .config import CONFIG, ROOT
from .gitops import ApiError

_lock = threading.Lock()
_processes: dict[str, subprocess.Popen] = {}
_exits: dict[str, dict] = {}  # name -> {code, at}
_jobs: dict[str, dict] = {}  # job id -> {service, kind, status, started_at, finished_at, message}
_job_seq = 0


def services_config() -> dict:
    return CONFIG.services_config


def state_dir(checkout: Path) -> Path:
    d = checkout / ".console"
    d.mkdir(parents=True, exist_ok=True)
    return d


def log_dir(checkout: Path) -> Path:
    d = state_dir(checkout) / "logs"
    d.mkdir(parents=True, exist_ok=True)
    return d


def log_path(checkout: Path, name: str) -> Path:
    return log_dir(checkout) / f"{name}.log"


def tail_log(checkout: Path, name: str, n: int = 200) -> str:
    path = log_path(checkout, name)
    if not path.exists():
        return ""
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    return "\n".join(lines[-n:])


def last_meaningful_line(checkout: Path, name: str) -> str:
    """The last non-blank log line, used as the remedy hint next to an exited service."""
    text = tail_log(checkout, name, n=500)
    for line in reversed(text.splitlines()):
        if line.strip():
            return line.strip()
    return ""


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


def process_status(name: str) -> dict:
    """{running, exit_code} for a tracked process; exit_code is remembered even after the
    Popen object is gone, so a poll a few seconds after the exit still reports it."""
    proc = _processes.get(name)
    if proc is not None:
        code = proc.poll()
        if code is None:
            return {"running": True, "exit_code": None}
        _exits[name] = {"code": code, "at": time.time()}
        _processes.pop(name, None)
    exit_info = _exits.get(name)
    if exit_info is not None:
        return {"running": False, "exit_code": exit_info["code"]}
    return {"running": False, "exit_code": None}


def _service_cwd(checkout: Path, cfg: dict) -> Path:
    return checkout / cfg["cwd"]


def start_service(name: str, checkout: Path) -> str:
    cfg = services_config().get(name)
    if not cfg:
        raise ApiError(f"unknown service: {name}", 404)
    if cfg.get("manual"):
        return f"{name} must be started manually"
    if name in _processes and _processes[name].poll() is None:
        return f"{name} already running"
    cwd = _service_cwd(checkout, cfg)
    if not cwd.is_dir():
        raise ApiError("Check out a branch first", 409)
    _exits.pop(name, None)
    with open(log_path(checkout, name), "a", encoding="utf-8") as logf:
        logf.write(f"\n--- console start {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
        logf.flush()
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
    cfg = services_config().get(name) or {}
    stop_cmd = cfg.get("stop")
    if stop_cmd:
        cwd = _service_cwd(checkout, cfg)
        if cwd.is_dir():
            subprocess.run(stop_cmd, shell=True, cwd=cwd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return f"{name} stopped"
    return f"{name} not running"


def stop_all(checkout: Path) -> None:
    for name in list(_processes):
        stop_service(name, checkout)


# --- OTP -------------------------------------------------------------------

def latest_otp(checkout: Path) -> str | None:
    import re
    text = tail_log(checkout, "backend", n=2000)
    matches = re.findall(r"OTP for ([^:]+): (\d{6})", text)
    if not matches:
        return None
    phone, code = matches[-1]
    return f"{code} (for {phone.strip()})"


# --- prepare -----------------------------------------------------------------

def prepare_needed(name: str, checkout: Path) -> bool:
    cfg = services_config().get(name) or {}
    prep = cfg.get("prepare")
    if not prep:
        return False
    cwd = _service_cwd(checkout, cfg)
    if not cwd.is_dir():
        return False
    marker = prep.get("marker")
    if marker:
        marker_path = cwd / marker
        if not marker_path.exists():
            return True
        newer = prep.get("newer_than")
        if newer:
            newer_path = cwd / newer
            if newer_path.exists() and newer_path.stat().st_mtime > marker_path.stat().st_mtime:
                return True
    for copy in prep.get("copy", []):
        dest = cwd / copy["dest"]
        if not dest.exists():
            return True
    return False


def _run_prepare_job(job_id: str, name: str, checkout: Path) -> None:
    cfg = services_config().get(name) or {}
    prep = cfg.get("prepare") or {}
    cwd = _service_cwd(checkout, cfg)
    logf_path = log_dir(checkout) / f"{name}.prepare.log"
    with open(logf_path, "a", encoding="utf-8") as logf:
        logf.write(f"\n--- prepare start {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
        logf.flush()
        try:
            for copy in prep.get("copy", []):
                src = ROOT / copy["src"]
                dest = cwd / copy["dest"]
                if not dest.exists() and src.exists():
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dest)
                    logf.write(f"copied {src} -> {dest}\n")
                    logf.flush()
            command = prep.get("command")
            if command:
                result = subprocess.run(command, shell=True, cwd=cwd, stdout=logf, stderr=subprocess.STDOUT)
                if result.returncode != 0:
                    with _lock:
                        _jobs[job_id]["status"] = "failed"
                        _jobs[job_id]["message"] = f"exit {result.returncode}"
                        _jobs[job_id]["finished_at"] = time.time()
                    return
            with _lock:
                _jobs[job_id]["status"] = "success"
                _jobs[job_id]["message"] = "ready"
                _jobs[job_id]["finished_at"] = time.time()
        except Exception as e:  # noqa: BLE001 - a job must never crash the server thread
            with _lock:
                _jobs[job_id]["status"] = "failed"
                _jobs[job_id]["message"] = str(e)
                _jobs[job_id]["finished_at"] = time.time()


def start_prepare(name: str, checkout: Path) -> dict:
    cfg = services_config().get(name)
    if not cfg:
        raise ApiError(f"unknown service: {name}", 404)
    cwd = _service_cwd(checkout, cfg)
    if not cwd.is_dir():
        raise ApiError("Check out a branch first", 409)
    global _job_seq
    with _lock:
        for job in _jobs.values():
            if job["service"] == name and job["kind"] == "prepare" and job["status"] == "running":
                return job
        _job_seq += 1
        job_id = f"job-{_job_seq}"
        job = {"id": job_id, "service": name, "kind": "prepare", "status": "running",
               "message": "running", "started_at": time.time(), "finished_at": None}
        _jobs[job_id] = job
    thread = threading.Thread(target=_run_prepare_job, args=(job_id, name, checkout), daemon=True)
    thread.start()
    return job


def prepare_log(checkout: Path, name: str, n: int = 200) -> str:
    path = log_dir(checkout) / f"{name}.prepare.log"
    if not path.exists():
        return ""
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    return "\n".join(lines[-n:])


def jobs_snapshot() -> list[dict]:
    with _lock:
        return list(_jobs.values())


def state_snapshot(checkout: Path) -> list[dict]:
    """One row per configured service: health, process status, prepare status/need."""
    rows = []
    cfg = services_config()
    for name, sc in cfg.items():
        manual = bool(sc.get("manual"))
        up = False if manual else health_ok(sc["health"])
        proc = process_status(name)
        row = {
            "name": name,
            "manual": manual,
            "up": up,
            "url": sc.get("url", ""),
            "notes": sc.get("notes", ""),
            "running": proc["running"],
            "exit_code": proc["exit_code"],
        }
        if proc["exit_code"] is not None and not up:
            row["last_log_line"] = last_meaningful_line(checkout, name)
            row["remedy"] = "Run Prepare" if sc.get("prepare") else "Check the log"
        if sc.get("prepare"):
            row["needs_prepare"] = prepare_needed(name, checkout)
        rows.append(row)
    return rows
