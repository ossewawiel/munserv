"""Entry point: `python3 -m scripts.tui [--console http://localhost:3999]`. ./tui.sh runs this
through uv with the pinned Textual version and starts the console first when it is down."""
from __future__ import annotations

import argparse

from .api import DEFAULT_BASE_URL, ConsoleApi
from .app import OperatorApp


def main() -> int:
    parser = argparse.ArgumentParser(description="MunServ operator TUI")
    parser.add_argument("--console", default=DEFAULT_BASE_URL, help="factory console base URL")
    args = parser.parse_args()
    OperatorApp(ConsoleApi(args.console)).run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
