#!/usr/bin/env python3
"""Fail when a build output contains a dev account from scripts/console/accounts.yaml.

Scans every file under each path, and every member of a zip-like file (apk, aab, jar, zip),
for each account's email and password as UTF-8 and UTF-16-LE.

Usage: python3 scripts/check-no-demo-accounts.py [--accounts PATH] PATH [PATH ...]
Exit: 0 clean, 1 an account was found, 2 a path is missing or nothing was scanned.
"""
from __future__ import annotations

import argparse
import io
import sys
import zipfile
from pathlib import Path

import yaml

DEFAULT_ACCOUNTS = Path(__file__).resolve().parent / "console" / "accounts.yaml"
MIN_LENGTH = 6
FIELDS = ("email", "password")


def needles(accounts: dict) -> list[tuple[str, str, bytes]]:
    found = []
    for key, account in accounts.items():
        for field in FIELDS:
            value = str(account.get(field, ""))
            if len(value) < MIN_LENGTH:
                if value:
                    print(f"skipped {key} ({field}): shorter than {MIN_LENGTH} characters")
                continue
            for encoding in ("utf-8", "utf-16-le"):
                found.append((key, field, value.encode(encoding)))
    return found


def scan_bytes(data: bytes, label: str, wanted: list[tuple[str, str, bytes]], hits: list[str]) -> int:
    if zipfile.is_zipfile(io.BytesIO(data)):
        count = 0
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for member in archive.namelist():
                if member.endswith("/"):
                    continue
                count += scan_bytes(archive.read(member), f"{label}!{member}", wanted, hits)
        return count
    for key, field, needle in wanted:
        if needle in data:
            hit = f"demo account {key} ({field}) found in {label}"
            if hit not in hits:
                hits.append(hit)
    return 1


def scan_path(path: Path, wanted: list[tuple[str, str, bytes]], hits: list[str]) -> int:
    files = [path] if path.is_file() else sorted(p for p in path.rglob("*") if p.is_file())
    return sum(scan_bytes(f.read_bytes(), str(f), wanted, hits) for f in files)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Fail when a build contains a dev account")
    parser.add_argument("--accounts", type=Path, default=DEFAULT_ACCOUNTS)
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args(argv)

    missing = [p for p in args.paths if not p.exists()]
    if missing:
        print(f"path not found: {', '.join(map(str, missing))}", file=sys.stderr)
        return 2

    wanted = needles(yaml.safe_load(args.accounts.read_text()))
    hits: list[str] = []
    scanned = sum(scan_path(p, wanted, hits) for p in args.paths)
    if scanned == 0:
        print("no file was scanned", file=sys.stderr)
        return 2
    if hits:
        print("\n".join(hits))
        return 1
    print(f"no demo account in {scanned} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
