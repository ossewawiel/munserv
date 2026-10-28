#!/usr/bin/env python3
"""Entry point: `python3 -m scripts.console [--port 3999] [--checkout DIR]`."""
from __future__ import annotations

import argparse
from pathlib import Path

from .config import CONFIG
from .server import run


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=CONFIG.port)
    parser.add_argument("--checkout", type=Path, default=None)
    args = parser.parse_args()
    return run(port=args.port, checkout=args.checkout)


if __name__ == "__main__":
    raise SystemExit(main())
