#!/usr/bin/env python3
"""Entry point: `python3 -m scripts.console [--port 3999] [--checkout DIR] [--remote|--local]`, or
`python3 -m scripts.console ensure <pr>` to set up a PR for eyeball through the running console."""
from __future__ import annotations

import argparse
from pathlib import Path

from . import ensure, inbox, remote
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
    inbox_parser = subcommands.add_parser("inbox", help="print what is waiting on a human, oldest first")
    inbox_parser.add_argument("--json", action="store_true")
    inbox_parser.add_argument("--publish", action="store_true",
                              help="update the pinned 'Waiting on you' issue instead of printing")
    args = parser.parse_args()
    if args.command == "ensure":
        return ensure.main(args.pr, args.port)
    if args.command == "inbox":
        return inbox.main("json" if args.json else "markdown", args.port, args.publish)
    remote.set_mode(True if args.remote else False if args.local else None)
    return run(port=args.port, checkout=args.checkout)


if __name__ == "__main__":
    raise SystemExit(main())
