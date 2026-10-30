"""Runs a command step from a handoff's Eyeball block on this laptop and returns what it printed.

A step is a command when the whole step is one backtick span (`curl -s localhost:8080/...`) or starts
with "$ ". The TUI shows the command before the person presses its Run key, so nothing runs unseen.
Standard library only, so the parser and the runner are testable without Textual.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COMMAND_TIMEOUT_SECONDS = 30
MAX_OUTPUT_LINES = 40
MAX_LINE_CHARS = 200
BACKTICK_STEP = re.compile(r"^`([^`]+)`$")
PROMPT_PREFIX = "$ "


def command_of(step: str) -> str | None:
    """The shell command a step stands for, or None when the step is an instruction for a person."""
    text = step.strip()
    if match := BACKTICK_STEP.match(text):
        return match.group(1).strip()
    if text.startswith(PROMPT_PREFIX):
        return text[len(PROMPT_PREFIX):].strip() or None
    return None


def run_command(command: str, cwd: Path = ROOT) -> str:
    """Runs `command` in bash; returns stdout and stderr together, trimmed, with the exit code last."""
    try:
        done = subprocess.run(["bash", "-c", command], cwd=cwd, capture_output=True, text=True,
                              timeout=COMMAND_TIMEOUT_SECONDS, stdin=subprocess.DEVNULL, check=False)
    except subprocess.TimeoutExpired:
        return f"stopped after {COMMAND_TIMEOUT_SECONDS} seconds"
    lines = (done.stdout + done.stderr).rstrip().splitlines()
    shown = [line[:MAX_LINE_CHARS] for line in lines[:MAX_OUTPUT_LINES]]
    if len(lines) > MAX_OUTPUT_LINES:
        shown.append(f"... {len(lines) - MAX_OUTPUT_LINES} more lines")
    shown.append(f"exit {done.returncode}")
    return "\n".join(shown)
