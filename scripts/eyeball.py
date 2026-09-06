#!/usr/bin/env python3
"""Shim: the eyeball dashboard was rebuilt into the factory console (scripts/console/). Run
`python3 -m scripts.console` directly, or use `./dashboard.sh`; this file exists only so any
muscle-memory `python3 scripts/eyeball.py` invocation keeps working."""
from __future__ import annotations

import runpy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if __name__ == "__main__":
    runpy.run_module("scripts.console", run_name="__main__")
