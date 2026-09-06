"""Checkout management: a detached git worktree under test, separate from the main checkout.

Never claims a branch name (factory implementers hold feature branches checked out in their own
worktrees), never touches the main checkout's own branches, and preserves .eyeball/.console state
that may already have been written into the checkout directory before the first checkout runs.
"""
from __future__ import annotations

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
