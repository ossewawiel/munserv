#!/usr/bin/env python3
"""Quick-login build input, read from scripts/console/accounts.yaml only.

An account is offered when it has a `group`. The portal gets the web accounts as a JSON array
(VITE_DEMO_ACCOUNTS); the app gets the mobile accounts in a dart-define file.

Usage:
  python3 scripts/demo_accounts.py web
  python3 scripts/demo_accounts.py mobile --out <file>
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import yaml

GROUP_ORDER = (
    "pod_chief",
    "pod_admin",
    "ward_chief",
    "ward_admin",
    "sector_chief",
    "sector_admin",
    "member",
    "ground_admin",
)
DEFAULT_ACCOUNTS = Path(__file__).resolve().parent / "console" / "accounts.yaml"


def load(path: Path) -> dict:
    return yaml.safe_load(path.read_text())


def entries(accounts: dict, platform: str) -> list[dict]:
    offered = []
    for key, account in accounts.items():
        group = account.get("group")
        if group is None or account.get("platform") != platform:
            continue
        if group not in GROUP_ORDER:
            raise ValueError(f"{key}: unknown group {group!r}")
        offered.append(
            {
                "group": group,
                "name": account.get("first_name", ""),
                "email": account["email"],
                "password": account["password"],
            }
        )
    return sorted(offered, key=lambda e: (GROUP_ORDER.index(e["group"]), e["name"]))


def _dump(accounts: dict, platform: str) -> str:
    return json.dumps(entries(accounts, platform), separators=(",", ":"))


def web_value(accounts: dict) -> str:
    return _dump(accounts, "web")


def mobile_define(accounts: dict) -> dict:
    return {"DEMO_ACCOUNTS": _dump(accounts, "mobile")}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Quick-login build input from accounts.yaml")
    parser.add_argument("--accounts", type=Path, default=DEFAULT_ACCOUNTS)
    sub = parser.add_subparsers(dest="platform", required=True)
    sub.add_parser("web")
    mobile = sub.add_parser("mobile")
    mobile.add_argument("--out", type=Path, required=True)
    args = parser.parse_args(argv)

    try:
        accounts = load(args.accounts)
        if args.platform == "web":
            print(web_value(accounts))
        else:
            define = mobile_define(accounts)
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_text(json.dumps(define))
            print(args.out)
    except ValueError as err:
        print(err, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
