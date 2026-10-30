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
from scripts.tui.phone import PhoneScreen  # noqa: E402


class StubConsole:
    """In-memory console: three services, a log per service, and a record of every POST."""

    def __init__(self) -> None:
        self.services = {
            "db": {"name": "db", "up": True, "running": False, "manual": False, "url": "postgresql://localhost:5435", "exit_code": 0},
            "backend": {"name": "backend", "up": True, "running": True, "manual": False, "url": "http://79.6.23.52:8080", "exit_code": None},
            "web": {"name": "web", "up": False, "running": False, "manual": False, "url": "http://79.6.23.52:3000", "exit_code": 1},
        }
        self.posts: list[tuple[str, str]] = []
        self.bodies: list[tuple[str, dict]] = []
        self.pair_error = ""
        self.devices = [
            {"id": "192.168.1.20:41233", "state": "device", "model": "Pixel_8", "android": {"release": "14", "sdk": 34}},
            {"id": "R58N30ABCDE", "state": "device", "model": "Galaxy_S9", "android": {"release": "10", "sdk": 29}},
        ]

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
                if url.path == "/api/mobile/devices":
                    return self._json({"devices": stub.devices, "lan_ip": "192.168.1.5", "api_port": 8080,
                                       "showcase_api_port": 8090, "min_android_sdk": 30})
                if url.path == "/api/state":
                    return self._json({"jobs": [{"service": "mobile", "kind": "install", "status": "success",
                                                 "message": "installed and opened on x"}],
                                       "checkout": {"path": "/x", "branch": "master", "sha": "a222098abcdef"},
                                       "services": list(stub.services.values()),
                                       "showcase": {"exists": True, "sha": "b111111", "built_sha": "a000000",
                                                    "master_sha": "c222222"}})
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
                if self.path.startswith("/api/showcase/"):
                    verb = self.path.rsplit("/", 1)[-1]
                    stub.posts.append(("showcase", verb))
                    return self._json({"ok": True, "message": f"showcase {verb}", "job": {"status": "running"}})
                if self.path.startswith("/api/mobile/"):
                    body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                    stub.bodies.append((self.path.rsplit("/", 1)[-1], body))
                    if stub.pair_error and self.path.endswith("/pair"):
                        return self._json({"ok": False, "error": stub.pair_error}, 409)
                    return self._json({"ok": True, "message": "done"})
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


class StubbedTuiCase(unittest.TestCase):
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


class TuiTest(StubbedTuiCase):
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

    def test_demo_keys_post_the_showcase_actions(self) -> None:
        async def scenario(app, pilot) -> None:
            for key, verb in (("u", "update"), ("b", "build"), ("d", "start"), ("e", "stop")):
                await pilot.press(key)
                await wait_for(pilot, lambda verb=verb: ("showcase", verb) in self.stub.posts)
        self.run_app(scenario)

    def test_top_bar_summarises_the_demo_worktree(self) -> None:
        async def scenario(app, pilot) -> None:
            await wait_for(pilot, lambda: "demo" in str(app.query_one("#topbar").render()))
            self.assertIn("b111111 built a000000, master c222222", str(app.query_one("#topbar").render()))
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


class PhoneScreenTest(StubbedTuiCase):
    def run_phone(self, scenario) -> None:
        async def main() -> None:
            app = OperatorApp(self.api)
            async with app.run_test(size=(140, 40)) as pilot:
                await wait_for(pilot, lambda: app.query_one("#services").row_count == 3)
                await pilot.press("p")
                await wait_for(pilot, lambda: isinstance(app.screen, PhoneScreen)
                               and app.screen.query_one("#devices").row_count == 2)
                await scenario(app.screen, pilot)
        asyncio.run(main())

    def sent(self, verb: str) -> list[dict]:
        return [body for name, body in self.stub.bodies if name == verb]

    def test_device_list_shows_model_and_android_version(self) -> None:
        async def scenario(screen, pilot) -> None:
            table = screen.query_one("#devices")
            row = lambda key: [str(table.get_cell(key, c)) for c in ("model", "android", "state")]
            self.assertEqual(row("192.168.1.20:41233"), ["Pixel 8", "14", "device"])
            self.assertEqual(row("R58N30ABCDE"), ["Galaxy S9", "10 (too old)", "device"])
            self.assertIn("192.168.1.5", str(screen.query_one("#phone-top").render()))
        self.run_phone(scenario)

    def test_wizard_pairs_then_connects_with_the_typed_addresses(self) -> None:
        async def scenario(screen, pilot) -> None:
            self.assertIn("step 1 of 5", str(screen.query_one("#wizard-title").render()))
            await pilot.press("n", "n")
            self.assertIn("step 3 of 5", str(screen.query_one("#wizard-title").render()))
            await pilot.press(*"192.168.1.20:37099", "enter", *"123456", "enter")
            await wait_for(pilot, lambda: self.sent("pair"))
            self.assertEqual(self.sent("pair"), [{"address": "192.168.1.20:37099", "code": "123456"}])
            await wait_for(pilot, lambda: "step 4 of 5" in str(screen.query_one("#wizard-title").render()))
            await pilot.press(*"192.168.1.20:41233", "enter")
            await wait_for(pilot, lambda: self.sent("connect"))
            self.assertEqual(self.sent("connect"), [{"address": "192.168.1.20:41233"}])
            await wait_for(pilot, lambda: "step 5 of 5" in str(screen.query_one("#wizard-title").render()))
        self.run_phone(scenario)

    def test_failed_pairing_stays_on_the_pairing_step(self) -> None:
        self.stub.pair_error = "Failed: wrong pairing code"
        async def scenario(screen, pilot) -> None:
            await pilot.press("n", "n", *"192.168.1.20:37099", "enter", *"000000", "enter")
            await wait_for(pilot, lambda: self.sent("pair"))
            await pilot.pause(0.3)
            self.assertIn("step 3 of 5", str(screen.query_one("#wizard-title").render()))
        self.run_phone(scenario)

    def test_install_keys_pick_the_checkout_for_the_highlighted_phone(self) -> None:
        async def scenario(screen, pilot) -> None:
            screen.query_one("#devices").focus()
            await pilot.press("i")
            await wait_for(pilot, lambda: self.sent("install"))
            await pilot.press("s")
            await wait_for(pilot, lambda: len(self.sent("install")) == 2)
            self.assertEqual(self.sent("install"), [{"device_id": "192.168.1.20:41233", "source": "eyeball"},
                                                    {"device_id": "192.168.1.20:41233", "source": "showcase"}])
        self.run_phone(scenario)

    def test_install_refuses_a_phone_older_than_android_11(self) -> None:
        async def scenario(screen, pilot) -> None:
            screen.query_one("#devices").focus()
            await pilot.press("down", "i")
            await pilot.pause(0.3)
            self.assertEqual(self.sent("install"), [])
        self.run_phone(scenario)

    def test_open_and_log_keys_call_the_console(self) -> None:
        async def scenario(screen, pilot) -> None:
            screen.query_one("#devices").focus()
            await pilot.press("o")
            await wait_for(pilot, lambda: self.sent("launch"))
            await pilot.press("l")
            await wait_for(pilot, lambda: self.sent("logcat"))
            self.assertEqual(self.sent("logcat"), [{"device_id": "192.168.1.20:41233"}])
            self.assertEqual(screen.view, "phone-logcat")
        self.run_phone(scenario)


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
