#!/usr/bin/env python3
"""Entry point: `python3 -m scripts.console [--port 3999] [--checkout DIR] [--remote|--local]`, or
`python3 -m scripts.console ensure <pr>` to set up a PR for eyeball through the running console."""
from __future__ import annotations

import argparse
from pathlib import Path

from . import ensure, remote
from .config import CONFIG
from .server import run


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=CONFIG.port)
    parser.add_argument("--checkout", type=Path, default=None)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--remote", action="store_true", help="listen on the LAN, require the access token")
    mode.add_argument("--local", action="store_true", help="listen on localhost only, no token")
    subcommands = parser.add_subparsers(dest="command")
    ensure_parser = subcommands.add_parser("ensure", help="check out a PR and start what it needs")
    ensure_parser.add_argument("pr", type=int)
    args = parser.parse_args()
    if args.command == "ensure":
        return ensure.main(args.pr, args.port)
    remote.set_mode(True if args.remote else False if args.local else None)
    return run(port=args.port, checkout=args.checkout)


if __name__ == "__main__":
    raise SystemExit(main())
