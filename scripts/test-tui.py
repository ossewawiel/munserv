#!/usr/bin/env python3
"""Headless tests for the operator TUI (scripts/tui/) against a stub factory console.

A small HTTP server stands in for scripts/console/server.py; the app runs under Textual's
App.run_test pilot, so no terminal is needed.

Usage: python3 scripts/test-tui.py   (needs textual==8.2.8; ./tui.sh pins the same version)
"""
from __future__ import annotations

import asyncio
import json
import sys
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from scripts.tui.api import ConsoleApi, ConsoleError, Service  # noqa: E402
from scripts.tui.app import OperatorApp  # noqa: E402


class StubConsole:
    """In-memory console: three services, a log per service, and a record of every POST."""

    def __init__(self) -> None:
        self.services = {
            "db": {"name": "db", "up": True, "running": False, "manual": False, "url": "postgresql://localhost:5435", "exit_code": 0},
            "backend": {"name": "backend", "up": True, "running": True, "manual": False, "url": "http://79.6.23.52:8080", "exit_code": None},
            "web": {"name": "web", "up": False, "running": False, "manual": False, "url": "http://79.6.23.52:3000", "exit_code": 1},
        }
        self.posts: list[tuple[str, str]] = []

    def handler(self):
        stub = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, format: str, *args) -> None:
                pass

            def _json(self, data: dict, status: int = 200) -> None:
                body = json.dumps(data).encode()
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_GET(self) -> None:
                url = urlparse(self.path)
                if url.path == "/api/state":
                    return self._json({"checkout": {"path": "/x", "branch": "master", "sha": "a222098abcdef"},
                                       "services": list(stub.services.values())})
                if url.path == "/api/remote":
                    return self._json({"host": "79.6.23.52", "urls": {"web": "http://79.6.23.52:3000",
                                       "swagger": "http://79.6.23.52:8080/swagger-ui.html",
                                       "console_with_token": "http://79.6.23.52:3999/?token=t"},
                                       "firewall": {"command": "sudo ufw allow from 79.6.23.0/24 to any port 3000,3999,8080 proto tcp"}})
                if url.path == "/api/log":
                    name = parse_qs(url.query)["name"][0]
                    return self._json({"log": f"{name} line 1\n{name} line 2"})
                self._json({"error": "not found"}, 404)

            def do_POST(self) -> None:
                if self.path == "/api/refresh":
                    stub.posts.append(("refresh", ""))
                    return self._json({"ok": True})
                name = json.loads(self.rfile.read(int(self.headers["Content-Length"])))["name"]
                verb = self.path.rsplit("/", 1)[-1]
                stub.posts.append((verb, name))
                service = stub.services[name]
                service["up"] = service["running"] = verb == "start"
                self._json({"ok": True, "message": f"{verb}ed {name}"})

        return Handler


class TuiTest(unittest.TestCase):
    def setUp(self) -> None:
        self.stub = StubConsole()
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), self.stub.handler())
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.api = ConsoleApi(f"http://127.0.0.1:{self.server.server_port}")

    def tearDown(self) -> None:
        self.server.shutdown()
        self.server.server_close()

    def run_app(self, scenario) -> None:
        async def main() -> None:
            app = OperatorApp(self.api)
            async with app.run_test(size=(140, 40)) as pilot:
                await wait_for(pilot, lambda: app.query_one("#services").row_count == 3)
                await scenario(app, pilot)
        asyncio.run(main())

    def test_table_lists_every_service_with_its_state(self) -> None:
        async def scenario(app, pilot) -> None:
            table = app.query_one("#services")
            states = [str(table.get_cell(key, "state")) for key in ("db", "backend", "web")]
            self.assertEqual(states, ["● up", "● up", "✕ exited 1"])
        self.run_app(scenario)

    def test_table_shows_port_health_and_checkout_sha(self) -> None:
        async def scenario(app, pilot) -> None:
            table = app.query_one("#services")
            row = lambda key: [str(table.get_cell(key, c)) for c in ("port", "health", "sha")]
            self.assertEqual(row("db"), ["5435", "healthy", "a222098"])
            self.assertEqual(row("web"), ["3000", "down", ""])
        self.run_app(scenario)

    def test_refresh_key_posts_to_the_console(self) -> None:
        async def scenario(app, pilot) -> None:
            await pilot.press("f")
            await wait_for(pilot, lambda: ("refresh", "") in self.stub.posts)
        self.run_app(scenario)

    def test_log_follows_the_highlighted_service(self) -> None:
        async def scenario(app, pilot) -> None:
            await pilot.press("down")
            await wait_for(pilot, lambda: app.last_log.startswith("backend"))
            self.assertIn("backend line 2", app.last_log)
        self.run_app(scenario)

    def test_stop_and_start_go_through_the_console(self) -> None:
        async def scenario(app, pilot) -> None:
            await pilot.press("down", "x")
            await wait_for(pilot, lambda: ("stop", "backend") in self.stub.posts)
            await pilot.press("s")
            await wait_for(pilot, lambda: ("start", "backend") in self.stub.posts)
        self.run_app(scenario)

    def test_restart_stops_then_starts(self) -> None:
        async def scenario(app, pilot) -> None:
            await pilot.press("down", "r")
            await wait_for(pilot, lambda: len(self.stub.posts) == 2)
            self.assertEqual(self.stub.posts, [("stop", "backend"), ("start", "backend")])
        self.run_app(scenario)

    def test_start_stack_starts_db_backend_web_in_order(self) -> None:
        async def scenario(app, pilot) -> None:
            await pilot.press("a")
            await wait_for(pilot, lambda: len(self.stub.posts) == 3)
            self.assertEqual(self.stub.posts, [("start", "db"), ("start", "backend"), ("start", "web")])
        self.run_app(scenario)

    def test_links_show_the_lan_addresses_and_firewall_command(self) -> None:
        async def scenario(app, pilot) -> None:
            await wait_for(pilot, lambda: app.remote_info is not None)
            links = str(app.query_one("#links").render())
            self.assertIn("http://79.6.23.52:3000", links)
            self.assertIn("sudo ufw allow", links)
        self.run_app(scenario)


class ApiTest(unittest.TestCase):
    def test_service_state_words(self) -> None:
        base = {"name": "x", "url": "", "manual": False, "needs_prepare": False}
        cases = [({"up": True, "running": True, "exit_code": None}, "up"),
                 ({"up": False, "running": True, "exit_code": None}, "starting"),
                 ({"up": False, "running": False, "exit_code": 2}, "exited"),
                 ({"up": False, "running": False, "exit_code": 0}, "stopped")]
        for fields, expected in cases:
            self.assertEqual(Service.from_json({**base, **fields}).state, expected)

    def test_port_and_health_words(self) -> None:
        base = {"name": "x", "manual": False, "needs_prepare": False, "exit_code": None}
        cases = [({"url": "http://h:8080", "up": True, "running": True}, "8080", "healthy"),
                 ({"url": "", "up": False, "running": True}, "", "waiting"),
                 ({"url": "postgresql://localhost:5435", "up": False, "running": False}, "5435", "down"),
                 ({"url": "", "up": False, "running": False, "manual": True}, "", "n/a")]
        for fields, port, health in cases:
            service = Service.from_json({**base, **fields})
            self.assertEqual((service.port, service.health), (port, health))

    def test_unreachable_console_raises_console_error(self) -> None:
        with self.assertRaises(ConsoleError):
            ConsoleApi("http://127.0.0.1:9").state()


async def wait_for(pilot, condition, timeout: float = 5.0) -> None:
    loop = asyncio.get_running_loop()
    deadline = loop.time() + timeout
    while not condition():
        if loop.time() > deadline:
            raise AssertionError("condition not met within the timeout")
        await pilot.pause(0.05)


if __name__ == "__main__":
    unittest.main(verbosity=1)
