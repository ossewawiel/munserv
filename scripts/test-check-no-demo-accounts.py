#!/usr/bin/env python3
"""Unit tests for scripts/check-no-demo-accounts.py.

Usage: python3 scripts/test-check-no-demo-accounts.py
"""
from __future__ import annotations

import contextlib
import importlib.util
import io
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

ACCOUNTS = {"sector_admin": {"email": "admin@ward42.example.com", "password": "admin123"}}


def _load_module():
    spec = importlib.util.spec_from_file_location("check_no_demo_accounts", ROOT / "scripts" / "check-no-demo-accounts.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


check = _load_module()


class CheckNoDemoAccountsTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = Path(self._tmp.name)
        self.accounts = self.dir / "accounts.yaml"
        self.accounts.write_text(yaml.safe_dump(ACCOUNTS))
        self.bundle = self.dir / "dist"
        self.bundle.mkdir()

    def run_check(self, *paths):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = check.main(["--accounts", str(self.accounts), *map(str, paths)])
        return code, out.getvalue()

    def test_planted_email_in_a_bundle_fails(self):
        (self.bundle / "app.js").write_text('login("admin@ward42.example.com")')
        self.assertEqual(self.run_check(self.bundle)[0], 1)

    def test_planted_password_fails(self):
        (self.bundle / "app.js").write_text('const p="admin123"')
        self.assertEqual(self.run_check(self.bundle)[0], 1)

    def test_clean_bundle_passes(self):
        (self.bundle / "app.js").write_text("console.log('hello')")
        code, out = self.run_check(self.bundle)
        self.assertEqual(code, 0)
        self.assertIn("no demo account in 1 files", out)

    def test_account_inside_an_apk_fails(self):
        apk = self.dir / "app-debug.apk"
        with zipfile.ZipFile(apk, "w") as z:
            z.writestr("assets/flutter_assets/define.json", "admin@ward42.example.com")
        code, out = self.run_check(apk)
        self.assertEqual(code, 1)
        self.assertIn("app-debug.apk!assets/flutter_assets/define.json", out)

    def test_utf16_string_fails(self):
        (self.bundle / "classes.dex").write_bytes(b"\x00\x01" + "admin123".encode("utf-16-le"))
        self.assertEqual(self.run_check(self.bundle)[0], 1)

    def test_missing_path_exits_2(self):
        self.assertEqual(self.run_check(self.dir / "nope")[0], 2)

    def test_empty_folder_exits_2(self):
        self.assertEqual(self.run_check(self.bundle)[0], 2)

    def test_output_names_file_and_account(self):
        (self.bundle / "app.js").write_text("admin123")
        _, out = self.run_check(self.bundle)
        self.assertIn("demo account sector_admin (password) found in", out)
        self.assertIn("app.js", out)


if __name__ == "__main__":
    unittest.main()
