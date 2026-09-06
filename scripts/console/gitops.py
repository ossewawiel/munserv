"""Checkout management: a detached git worktree under test, separate from the main checkout.

Never claims a branch name (factory implementers hold feature branches checked out in their own
worktrees), never touches the main checkout's own branches, and preserves .eyeball/.console state
that may already have been written into the checkout directory before the first checkout runs.
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path

from .config import CONFIG, ROOT

_NAME_RE = re.compile(r"^[A-Za-z0-9_.:-]+$")
_BRANCH_RE = re.compile(r"^[^\s\-][^\s]*$")


class ApiError(Exception):
    def __init__(self, message: str, status: int = 400):
        super().__init__(message)
        self.status = status


class CommandError(Exception):
    """A subprocess exited non-zero; carries its stderr instead of leaking it to the terminal."""


def validate_name(value: str, what: str) -> str:
    if not isinstance(value, str) or not value or not _NAME_RE.match(value) or ".." in value:
        raise ApiError(f"invalid {what}: {value!r}", 400)
    return value


def validate_branch(value: str) -> str:
    if not isinstance(value, str) or not value or not _BRANCH_RE.match(value) or ".." in value:
        raise ApiError(f"invalid branch: {value!r}", 400)
    return value


def run_captured(args: list[str], cwd: Path = ROOT, check: bool = True) -> subprocess.CompletedProcess:
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if check and result.returncode != 0:
        message = (result.stderr or result.stdout or f"exit {result.returncode}").strip()
        raise CommandError(f"{' '.join(args)}: {message}")
    return result


def gh(*args: str) -> str:
    return run_captured(["gh", *args]).stdout


_repo_slug: list[str] = []


def repo() -> str:
    if not _repo_slug:
        override = CONFIG.repo
        if override:
            _repo_slug.append(override)
        else:
            try:
                _repo_slug.append(run_captured(
                    ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
                    cwd=ROOT).stdout.strip())
            except CommandError:
                _repo_slug.append("")
    return _repo_slug[0]


def state_dir_name() -> str:
    return ".console"


def state_root(checkout: Path) -> Path:
    return checkout / state_dir_name()


def branch_state_file(checkout: Path) -> Path:
    return state_root(checkout) / "branch"


def worktree_add_args(checkout: Path, branch: str) -> list[str]:
    return ["git", "-C", str(ROOT), "worktree", "add", "--detach", str(checkout), f"origin/{branch}"]


def worktree_switch_args(checkout: Path, branch: str) -> tuple[list[str], list[str]]:
    fetch = ["git", "-C", str(checkout), "fetch", "origin", branch]
    switch = ["git", "-C", str(checkout), "checkout", "--detach", f"origin/{branch}"]
    return fetch, switch


def is_worktree(checkout: Path) -> bool:
    return (checkout / ".git").exists()


def _preserve_state(checkout: Path) -> Path | None:
    state = state_root(checkout)
    if not state.exists():
        return None
    if any(p.name != state_dir_name() for p in checkout.iterdir()):
        return None
    tmp = checkout.with_name(checkout.name + ".console-tmp")
    if tmp.exists():
        shutil.rmtree(tmp)
    shutil.move(str(state), str(tmp))
    return tmp


def _restore_state(checkout: Path, tmp: Path | None) -> None:
    if tmp is None:
        return
    checkout.mkdir(parents=True, exist_ok=True)
    dest = state_root(checkout)
    if dest.exists():
        shutil.rmtree(dest)
    shutil.move(str(tmp), str(dest))


# --- local-only config -------------------------------------------------------
#
# A fresh checkout is a real `git worktree`, so it has everything git tracks -- but nothing a
# tester's own working copy keeps locally and gitignored: `application-local.yml` (solved once,
# service-specifically, by services.yaml's own `prepare.copy`), and, more generally, whatever tool
# manages this machine's toolchain versions (mise's `mise.local.toml`, asdf/mise's
# `.tool-versions`). Without it, a step as simple as `flutter pub get` fails with
# "mise ERROR No version is set for shim: flutter" -- a checkout that otherwise looks identical to
# the tester's own. `project.yaml`'s `local_files` lists what to copy in; see Config.local_files.

def local_files_state_file(checkout: Path) -> Path:
    return state_root(checkout) / "local_files_copied.json"


def local_files_copied(checkout: Path) -> list[str]:
    """Every local file copied into `checkout` so far (across every checkout and every
    Prepare/Start since), for the UI to show under the checkout chip. Not merely "does the file
    exist right now" -- a file already tracked by git is deliberately never in this list even if
    present, see copy_local_files."""
    f = local_files_state_file(checkout)
    if not f.exists():
        return []
    try:
        return json.loads(f.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


def _record_local_files_copied(checkout: Path, newly_copied: list[str]) -> None:
    if not newly_copied:
        return
    merged = sorted(set(local_files_copied(checkout)) | set(newly_copied))
    local_files_state_file(checkout).parent.mkdir(parents=True, exist_ok=True)
    local_files_state_file(checkout).write_text(json.dumps(merged), encoding="utf-8")


def _is_tracked(relpath: str, root: Path) -> bool:
    result = subprocess.run(["git", "-C", str(root), "ls-files", "--error-unmatch", relpath],
                             text=True, capture_output=True)
    return result.returncode == 0


def copy_local_files(checkout: Path, root: Path | None = None,
                      file_list: list[str] | None = None) -> list[str]:
    """Copy each configured local file from `root` (the main repo) into `checkout` when: the main
    repo actually has it, the checkout does not have it yet (never overwrite -- a tester's own
    edits to the copy survive a later Prepare/Start), and git does not track it (a tracked file
    already arrives with the checkout on its own; copying over it could mask a real diff between
    branches). Returns the paths (relative to the repo root) copied by *this* call; the running
    total across every call is in `local_files_copied`."""
    root = root or ROOT
    file_list = CONFIG.local_files if file_list is None else file_list
    copied: list[str] = []
    for relpath in file_list:
        src = root / relpath
        dest = checkout / relpath
        if not src.is_file() or dest.exists() or _is_tracked(relpath, root):
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        copied.append(relpath)
    _record_local_files_copied(checkout, copied)
    return copied


def checkout_branch(checkout: Path, branch: str) -> str:
    checkout.parent.mkdir(parents=True, exist_ok=True)
    if is_worktree(checkout):
        fetch, switch = worktree_switch_args(checkout, branch)
        run_captured(fetch, cwd=ROOT)
        run_captured(switch, cwd=ROOT)
    else:
        run_captured(["git", "-C", str(ROOT), "fetch", "origin", branch], cwd=ROOT)
        preserved = _preserve_state(checkout) if checkout.exists() else None
        if checkout.exists() and not any(checkout.iterdir()):
            checkout.rmdir()
        run_captured(worktree_add_args(checkout, branch), cwd=ROOT)
        _restore_state(checkout, preserved)
    branch_state_file(checkout).parent.mkdir(parents=True, exist_ok=True)
    branch_state_file(checkout).write_text(branch, encoding="utf-8")
    copy_local_files(checkout)
    return current_branch(checkout)


def current_branch(checkout: Path) -> str:
    f = branch_state_file(checkout)
    return f.read_text(encoding="utf-8").strip() if f.exists() else ""


def current_sha(checkout: Path) -> str:
    if not is_worktree(checkout):
        return ""
    try:
        return run_captured(["git", "-C", str(checkout), "rev-parse", "--short", "HEAD"], cwd=ROOT).stdout.strip()
    except CommandError:
        return ""


def default_checkout() -> Path:
    return CONFIG.checkout_dir


def resolve_checkout_dir(preferred: Path) -> tuple[Path, str | None]:
    """The checkout directory to actually use, and a one-line notice if it differs from
    `preferred` -- reused when the configured directory is not yet a real worktree (a fresh
    install, or nothing has been checked out yet) but a pre-rename legacy directory already is,
    so a project rename of `checkout_dir` does not orphan an existing checkout and start a second
    one alongside it. Once `preferred` becomes a worktree it is used from then on."""
    if is_worktree(preferred):
        return preferred, None
    legacy = CONFIG.legacy_checkout_dir
    if legacy != preferred and is_worktree(legacy):
        return legacy, f"reusing existing checkout at {legacy} ({preferred.name} not found)"
    return preferred, None


def ensure_checked_out(checkout: Path, branch: str) -> str:
    """Make sure `checkout` is a worktree on `branch`, checking it out if it is missing or on a
    different branch. Used by /api/prepare and /api/service/start-required so pressing either
    step button directly (without Check out first) still works. Raises ApiError(409) with the
    underlying git error text if the checkout itself fails."""
    if is_worktree(checkout) and current_branch(checkout) == branch:
        return branch
    try:
        return checkout_branch(checkout, branch)
    except CommandError as e:
        raise ApiError(str(e), 409) from e
