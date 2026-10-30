"""The quick-login input for builds the console makes.

`scripts/demo_accounts.py` turns scripts/console/accounts.yaml into the build input. The web gets
it as an environment variable, the app as a dart-define file. Builds made by hand carry none.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from .config import ROOT
from .gitops import ApiError

SCRIPT = ROOT / "scripts" / "demo_accounts.py"
ACCOUNTS = ROOT / "scripts" / "console" / "accounts.yaml"
MOBILE_FILE = "demo-accounts.json"
DART_DEFINE = f"--dart-define-from-file={MOBILE_FILE}"

_web_cache: dict = {"mtime": None, "value": ""}


def _run(*args: str) -> str:
    result = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)
    if result.returncode != 0:
        raise ApiError(f"quick-login input failed: {result.stderr.strip()}", 500)
    return result.stdout.strip()


def web_value() -> str:
    """Value of VITE_DEMO_ACCOUNTS. Cached until accounts.yaml changes: services_config() expands
    placeholders on every poll and must not start a process each time."""
    mtime = ACCOUNTS.stat().st_mtime
    if _web_cache["mtime"] != mtime:
        _web_cache.update(mtime=mtime, value=_run("web"))
    return _web_cache["value"]


def write_mobile_file(mobile_dir: Path) -> Path:
    return Path(_run("mobile", "--out", str(mobile_dir / MOBILE_FILE)))


def count(value: str) -> int:
    return len(json.loads(value))
