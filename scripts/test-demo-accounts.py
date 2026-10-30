#!/usr/bin/env python3
"""Unit tests for scripts/demo_accounts.py.

Usage: python3 scripts/test-demo-accounts.py
"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import yaml  # noqa: E402

import demo_accounts  # noqa: E402

ACCOUNTS = {
    "super_user": {"platform": "web", "email": "su@x", "password": "p0"},
    "sector_admin": {"platform": "web", "group": "sector_admin", "email": "sa@x", "password": "p1"},
    "pod_chief": {"platform": "web", "group": "pod_chief", "email": "pc@x", "password": "p2"},
    "member": {"platform": "mobile", "group": "member", "email": "john@x", "password": "p3", "first_name": "John"},
    "other": {"platform": "mobile", "group": "member", "email": "ann@x", "password": "p4", "first_name": "Ann"},
    "ground_admin": {"platform": "mobile", "group": "ground_admin", "email": "sip@x", "password": "p5", "first_name": "Sipho"},
    "nameless": {"platform": "mobile", "group": "member", "email": "zed@x", "password": "p6"},
}


def _write(accounts: dict) -> Path:
    handle = tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False)
    yaml.safe_dump(accounts, handle)
    handle.close()
    return Path(handle.name)


class DemoAccountsTest(unittest.TestCase):
    def test_web_lists_only_web_accounts_with_a_group(self):
        emails = [e["email"] for e in demo_accounts.entries(ACCOUNTS, "web")]
        self.assertEqual(emails, ["pc@x", "sa@x"])

    def test_super_user_is_never_offered(self):
        for platform in ("web", "mobile"):
            emails = [e["email"] for e in demo_accounts.entries(ACCOUNTS, platform)]
            self.assertNotIn("su@x", emails)

    def test_entries_follow_group_order_then_name(self):
        got = [(e["group"], e["name"]) for e in demo_accounts.entries(ACCOUNTS, "mobile")]
        self.assertEqual(
            got,
            [("member", ""), ("member", "Ann"), ("member", "John"), ("ground_admin", "Sipho")],
        )

    def test_name_is_empty_without_first_name(self):
        web = demo_accounts.entries(ACCOUNTS, "web")
        self.assertEqual(web[0], {"group": "pod_chief", "name": "", "email": "pc@x", "password": "p2"})

    def test_mobile_file_holds_the_array_as_a_string(self):
        define = demo_accounts.mobile_define(ACCOUNTS)
        self.assertEqual(list(define), ["DEMO_ACCOUNTS"])
        self.assertIsInstance(define["DEMO_ACCOUNTS"], str)
        self.assertEqual(len(json.loads(define["DEMO_ACCOUNTS"])), 4)

    def test_unknown_group_exits_2(self):
        path = _write({"bad": {"platform": "web", "group": "king", "email": "k@x", "password": "p"}})
        self.assertEqual(demo_accounts.main(["--accounts", str(path), "web"]), 2)

    def test_real_accounts_file_gives_six_web_and_three_mobile_entries(self):
        accounts = demo_accounts.load(demo_accounts.DEFAULT_ACCOUNTS)
        self.assertEqual(len(demo_accounts.entries(accounts, "web")), 6)
        self.assertEqual(len(demo_accounts.entries(accounts, "mobile")), 3)


if __name__ == "__main__":
    unittest.main()
