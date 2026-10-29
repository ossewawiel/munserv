"""The showcase stack: a second, independent run of origin/master for demos, beside the dev stack.

It has its own detached git worktree (default `../munserv-demo`, tracking only origin/master), its
own database in the shared PostGIS container, a backend started with `java -jar` under the `demo`
profile, and the web app built with `pnpm build` and served by `vite preview`. The dev services
and the eyeball checkout are untouched. Four actions: update (move the worktree to origin/master),
build (database, bootJar, web build; a job whose log is the `demo-build` log), start and stop.

Processes are tracked by services.py under the names in SERVICES, with their logs in the console's
main checkout, so `/api/log`, the health dots and the TUI work for them like for any service.
"""
from __future__ import annotations

import os
import re
import shlex
import subprocess
import sys
import threading
import time
from pathlib import Path

from . import network, remote, services
from .config import CONFIG, ROOT
from .gitops import ApiError, CommandError, copy_local_files, current_sha, is_worktree, run_captured

BACKEND = "demo-backend"
WEB = "demo-web"
BUILD_LOG = "demo-build"
SERVICES = (BACKEND, WEB)
JOB_SERVICE = "demo"

BRANCH = "master"
SEED_SCRIPT = ROOT / "scripts" / "dev-seed.py"
SEED_WAIT_SECONDS = 240
SEED_POLL_SECONDS = 2
DB_STEP_TIMEOUT_SECONDS = 60
_DB_NAME_RE = re.compile(r"^[a-z_][a-z0-9_]*$")
_log_lock = threading.Lock()


def cfg() -> dict:
    return CONFIG.showcase


def checkout() -> Path:
    return cfg()["checkout_dir"]


def owns(name: str) -> bool:
    return name in SERVICES


def state_file(name: str) -> Path:
    return services.state_dir(checkout()) / name


def read_state(name: str) -> str:
    path = state_file(name)
    return path.read_text(encoding="utf-8").strip() if path.exists() else ""


# --- update ------------------------------------------------------------------

def update() -> str:
    """Create the worktree on first use, then move it to the latest origin/master. Returns the
    short SHA it now sits on."""
    directory = checkout()
    directory.parent.mkdir(parents=True, exist_ok=True)
    if is_worktree(directory):
        run_captured(["git", "-C", str(directory), "fetch", "origin", BRANCH], cwd=ROOT)
        run_captured(["git", "-C", str(directory), "checkout", "--detach", f"origin/{BRANCH}"], cwd=ROOT)
    else:
        run_captured(["git", "-C", str(ROOT), "fetch", "origin", BRANCH], cwd=ROOT)
        run_captured(["git", "-C", str(ROOT), "worktree", "add", "--detach", str(directory), f"origin/{BRANCH}"],
                     cwd=ROOT)
    copy_local_files(directory)
    return current_sha(directory)


# --- build -------------------------------------------------------------------

def database_commands(settings: dict) -> list[list[str]]:
    """The psql invocations that make the showcase database exist with the extensions Flyway needs.
    Over TCP with the dev credentials, so no docker access is needed."""
    name = settings["database"]
    if not _DB_NAME_RE.match(name):
        raise ApiError(f"invalid showcase database name: {name!r}", 400)
    base = ["psql", "-h", settings["db_host"], "-p", str(settings["db_port"]), "-U", settings["db_user"],
            "-v", "ON_ERROR_STOP=1"]
    return [
        base + ["-d", "postgres", "-tAc", f"SELECT 1 FROM pg_database WHERE datname = '{name}'"],
        base + ["-d", "postgres", "-c", f"CREATE DATABASE {name}"],
        base + ["-d", name, "-c", 'CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'],
    ]


def ensure_database(logf) -> bool:
    settings = cfg()
    probe, create, extensions = database_commands(settings)
    env = {**os.environ, "PGPASSWORD": settings["db_password"]}

    def run(command: list[str], capture: bool = False) -> subprocess.CompletedProcess:
        return subprocess.run(command, env=env, text=True, timeout=DB_STEP_TIMEOUT_SECONDS,
                              stdout=subprocess.PIPE if capture else logf, stderr=subprocess.STDOUT)

    exists = run(probe, capture=True)
    if exists.returncode != 0:
        logf.write(exists.stdout or "")
        return False
    if not exists.stdout.strip():
        logf.write(f"creating database {settings['database']}\n")
        if run(create).returncode != 0:
            return False
    return run(extensions).returncode == 0


def web_build_env() -> dict:
    """The build bakes a relative API URL; `vite preview` proxies it to the showcase backend."""
    return {**os.environ, "VITE_API_URL": "/api/v1"}


def _run_build(job_id: str, main: Path) -> None:
    directory = checkout()
    try:
        with open(services.log_path(main, BUILD_LOG), "a", encoding="utf-8") as logf:
            def say(text: str) -> None:
                logf.write(f"\n=== {text} ({time.strftime('%H:%M:%S')}) ===\n")
                logf.flush()

            def step(title: str, command: list[str], cwd: Path, env: dict | None = None) -> bool:
                say(title)
                return subprocess.run(command, cwd=cwd, env=env, stdout=logf, stderr=subprocess.STDOUT).returncode == 0

            logf.write(f"\n--- showcase build {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
            if not is_worktree(directory):
                say("update: no worktree yet")
                update()
            say(f"building {current_sha(directory)}")
            say("database")
            ok = ensure_database(logf)
            ok = ok and step("backend: bootJar", ["./gradlew", "bootJar"], directory / "backend")
            ok = ok and step("web: install", ["pnpm", "install", "--frozen-lockfile"], directory / "web")
            ok = ok and step("web: build", ["pnpm", "build"], directory / "web", web_build_env())
            if not ok:
                say("FAILED")
                services.finish_job(job_id, "failed", "see the demo-build log")
                return
            state_file("built-sha").write_text(current_sha(directory), encoding="utf-8")
            say("done")
            services.finish_job(job_id, "success", f"built {current_sha(directory)}")
    except Exception as e:  # noqa: BLE001 - a job must never crash the server thread
        services.finish_job(job_id, "failed", str(e))


def start_build(main: Path) -> dict:
    existing = services.running_job(JOB_SERVICE, "build")
    if existing:
        return existing
    job = services.new_job(JOB_SERVICE, "build")
    threading.Thread(target=_run_build, args=(job["id"], main), daemon=True).start()
    return job


# --- start and stop ----------------------------------------------------------

def built_jar() -> Path | None:
    libs = checkout() / "backend" / "build" / "libs"
    jars = sorted(p for p in libs.glob("*.jar") if not p.name.endswith("-plain.jar")) if libs.is_dir() else []
    return jars[-1] if jars else None


def backend_command(jar: Path) -> str:
    return (f"MUNSERV_APP_ADMIN_PORTAL_URL=http://{remote.host()}:{cfg()['web_port']} "
            f"SPRING_PROFILES_ACTIVE=local,mailpit,demo java -jar {shlex.quote(str(jar))}")


def web_command() -> str:
    return (f"PREVIEW_API_TARGET=http://localhost:{cfg()['backend_port']} "
            f"__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS={remote.hostname()} "
            f"pnpm exec vite preview --host {remote.listen_address()} --port {cfg()['web_port']} --strictPort")


def start(main: Path, names: tuple[str, ...] = SERVICES) -> list[str]:
    jar = built_jar()
    if jar is None or not (checkout() / "web" / "dist").is_dir():
        raise ApiError("Build the showcase first", 409)
    if BACKEND in names and not services.health_ok(f"tcp:{cfg()['db_port']}"):
        raise ApiError("The database is down; start the db service first", 409)
    messages = []
    if BACKEND in names:
        messages.append(services.start_tracked_process(BACKEND, main, backend_command(jar), checkout() / "backend"))
        threading.Thread(target=_seed_once, args=(main,), daemon=True).start()
    if WEB in names:
        messages.append(services.start_tracked_process(WEB, main, web_command(), checkout() / "web"))
    return messages


def stop(main: Path) -> list[str]:
    return [services.stop_service(name, main) for name in SERVICES]


def _seed_once(main: Path) -> None:
    """After the first start, create the dev accounts through the API. A marker file records
    success, so later starts skip it; dev-seed.py is idempotent anyway."""
    if state_file("seeded").exists():
        return
    health = f"http://localhost:{cfg()['backend_port']}/actuator/health/liveness"
    deadline = time.monotonic() + SEED_WAIT_SECONDS
    while time.monotonic() < deadline:
        if services.health_ok(health):
            break
        time.sleep(SEED_POLL_SECONDS)
    else:
        return
    with _log_lock, open(services.log_path(main, BACKEND), "a", encoding="utf-8") as logf:
        logf.write("\n--- dev-seed ---\n")
        logf.flush()
        result = subprocess.run([sys.executable, str(SEED_SCRIPT), "--base-url", f"http://localhost:{cfg()['backend_port']}"],
                                cwd=ROOT, stdout=logf, stderr=subprocess.STDOUT)
    if result.returncode == 0:
        state_file("seeded").write_text("ok", encoding="utf-8")


# --- what the state and remote endpoints report ------------------------------

def master_sha() -> str:
    try:
        return run_captured(["git", "-C", str(ROOT), "rev-parse", "--short", f"origin/{BRANCH}"], cwd=ROOT).stdout.strip()
    except CommandError:
        return ""


def snapshot() -> dict:
    directory = checkout()
    exists = is_worktree(directory)
    return {"path": str(directory), "exists": exists, "sha": current_sha(directory) if exists else "",
            "built_sha": read_state("built-sha") if exists else "", "master_sha": master_sha(),
            "seeded": exists and state_file("seeded").exists()}


def ports() -> list[int]:
    return [cfg()["web_port"], cfg()["backend_port"]]


def remote_block() -> dict:
    """Links for the showcase and the one firewall command that opens its two ports."""
    base = remote.host()
    active = network.detect_active_firewall()
    subnet = network.lan_subnet(network.lan_ip() or "")
    return {"urls": {"web": f"http://{base}:{cfg()['web_port']}",
                     "swagger": f"http://{base}:{cfg()['backend_port']}{CONFIG.remote['swagger_path']}"},
            "firewall": {"command": network.firewall_remedy_for_ports(active, ports(), subnet)}}
