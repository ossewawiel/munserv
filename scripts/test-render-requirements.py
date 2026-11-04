#!/usr/bin/env python3
"""Check scripts/render-requirements.py: a row's status follows its issue, and `only` limits the
check to the rows a branch changed, so an issue closing elsewhere never fails an unrelated PR."""
from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def _load_module():
    spec = importlib.util.spec_from_file_location("render_requirements", ROOT / "scripts" / "render-requirements.py")
    if spec is None or spec.loader is None:
        sys.exit("cannot load scripts/render-requirements.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


render = _load_module()

MINE = "| W1 | Mine | 🔴 Pending | [#1](https://github.com/o/r/issues/1) |"
OTHER = "| W2 | Other | 🔴 Pending | [#2](https://github.com/o/r/issues/2) |"
TEXT = f"# Web\n\n{MINE}\n{OTHER}\n"
BOTH_CLOSED = {1: "CLOSED", 2: "CLOSED"}


class RenderTest(unittest.TestCase):
    def test_should_rewrite_every_drifted_row_without_a_limit(self):
        new, drift = render.render(TEXT, BOTH_CLOSED, "web.md")
        self.assertEqual(len(drift), 2)
        self.assertEqual(new.count("🟢 Done"), 2)

    def test_should_ignore_drift_on_rows_the_branch_did_not_change(self):
        _, drift = render.render(TEXT, BOTH_CLOSED, "web.md", only={MINE})
        self.assertEqual(len(drift), 1)
        self.assertIn("W1", drift[0])

    def test_should_pass_a_branch_that_changed_no_drifted_row(self):
        _, drift = render.render(TEXT, BOTH_CLOSED, "web.md", only={"| W9 | New | 🔴 Pending | [#9](u) |"})
        self.assertEqual(drift, [])

    def test_should_leave_a_row_alone_when_its_issue_is_unknown(self):
        _, drift = render.render(TEXT, {}, "web.md")
        self.assertEqual(drift, [])

    def test_should_refuse_changed_since_without_check(self):
        with self.assertRaises(SystemExit):
            render.main(["--changed-since", "origin/master"])


if __name__ == "__main__":
    unittest.main()
