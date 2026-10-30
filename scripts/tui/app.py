"""The MunServ operator TUI: the laptop's services and their logs, driven from an SSH terminal.

Every action goes through the factory console API (api.py); the TUI starts and stops nothing
itself. The screen has three parts: the service table, the log of the highlighted service, and
the links a browser on another machine can open.
"""
from __future__ import annotations

import time

from rich.text import Text
from textual import work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.theme import Theme
from textual.widgets import DataTable, Footer, Log, Static

from .api import ConsoleApi, ConsoleError, Remote, Service, Showcase, State
from .eyeball import EyeballScreen
from .phone import PhoneScreen

POLL_SECONDS = 2.0
STOP_WAIT_SECONDS = 30
EYEBALL_STACK = ("db", "backend", "web")
BUILD_LOG_ROW = "demo-build"

# House palette (~/.claude/skills/house-style/design.md, dark set): graphite ground, one warm accent.
HOUSE_THEME = Theme(
    name="munserv-house",
    primary="#F0873F",
    secondary="#7FB3D5",
    accent="#F0873F",
    foreground="#E6E9EE",
    background="#101317",
    surface="#171B21",
    panel="#1F252D",
    success="#5DBE8A",
    warning="#E5B73B",
    error="#FF6B62",
    dark=True,
)

STATE_STYLE = {
    "up": ("● up", "#5DBE8A"),
    "starting": ("◐ starting", "#7FB3D5"),
    "exited": ("✕ exited", "#FF6B62"),
    "manual": ("○ manual", "#9AA3B2"),
    "stopped": ("○ stopped", "#9AA3B2"),
}


def state_cell(service: Service) -> Text:
    label, colour = STATE_STYLE[service.state]
    if service.state == "exited":
        label = f"{label} {service.exit_code}"
    return Text(label, style=colour)


HEALTH_STYLE = {"healthy": "#5DBE8A", "waiting": "#7FB3D5", "down": "#FF6B62", "n/a": "#9AA3B2"}


def health_cell(service: Service) -> Text:
    return Text(service.health, style=HEALTH_STYLE[service.health])


def sha_cell(service: Service, checkout_sha: str) -> Text:
    """Every service runs from the one checkout, so a live service shows its SHA and a stopped one none."""
    live = service.up or service.running
    return Text(checkout_sha if live else "", style="#E6E9EE")


def note_cell(service: Service) -> Text:
    if service.needs_prepare:
        return Text("prepare", style="#E5B73B")
    return Text("")


def showcase_summary(showcase: Showcase) -> str:
    """One phrase: the demo worktree's SHA, whether the build matches it, and how far master is."""
    if not showcase.exists:
        return "no worktree yet (u)"
    built = "built" if showcase.built_sha == showcase.sha else f"built {showcase.built_sha or 'never'}"
    behind = "" if showcase.master_sha in ("", showcase.sha) else f", master {showcase.master_sha}"
    return f"{showcase.sha} {built}{behind}"


class OperatorApp(App):
    TITLE = "MunServ operator"
    CSS_PATH = "app.tcss"
    BINDINGS = [
        Binding("s", "start", "Start"),
        Binding("x", "stop", "Stop"),
        Binding("r", "restart", "Restart"),
        Binding("a", "start_stack", "Start db+backend+web"),
        Binding("c", "copy('console')", "Copy console link"),
        Binding("w", "copy('web')", "Copy web link"),
        Binding("u", "showcase('update')", "Demo: update from master"),
        Binding("b", "showcase('build')", "Demo: build"),
        Binding("d", "showcase('start')", "Demo: start"),
        Binding("e", "showcase('stop')", "Demo: stop"),
        Binding("p", "phone", "Phone"),
        Binding("y", "eyeball", "Eyeball"),
        Binding("f", "refresh", "Refresh"),
        Binding("q", "quit", "Quit"),
    ]

    def __init__(self, api: ConsoleApi | None = None) -> None:
        super().__init__()
        self.api = api or ConsoleApi()
        self.selected: str | None = None
        self.remote_info: Remote | None = None
        self.last_log = ""
        self.busy: set[str] = set()

    def compose(self) -> ComposeResult:
        yield Static(id="topbar")
        with Horizontal(id="main"):
            with Vertical(id="left"):
                yield Static("SERVICES", classes="eyebrow")
                yield DataTable(id="services", cursor_type="row", zebra_stripes=False)
                yield Static("LINKS FOR YOUR OTHER MACHINE", classes="eyebrow")
                yield Static(id="links")
            with Vertical(id="right"):
                yield Static("LOG", id="log-title", classes="eyebrow")
                yield Log(id="log", auto_scroll=True)
        yield Footer()

    def on_mount(self) -> None:
        self.register_theme(HOUSE_THEME)
        self.theme = HOUSE_THEME.name
        table = self.query_one("#services", DataTable)
        table.add_column("State", key="state", width=12)
        table.add_column("Service", key="name", width=10)
        table.add_column("Port", key="port", width=6)
        table.add_column("Health", key="health", width=9)
        table.add_column("SHA", key="sha", width=8)
        table.add_column("", key="note", width=9)
        self.load_remote()
        self.poll()
        self.set_interval(POLL_SECONDS, self.poll)

    # ---- polling -------------------------------------------------------------------------------

    @work(thread=True, exclusive=True, group="remote")
    def load_remote(self) -> None:
        try:
            remote = self.api.remote()
        except ConsoleError as err:
            self.call_from_thread(self.show_links_error, str(err))
            return
        self.call_from_thread(self.show_links, remote)

    @work(thread=True, exclusive=True, group="poll")
    def poll(self) -> None:
        try:
            state = self.api.state()
        except ConsoleError as err:
            self.call_from_thread(self.show_offline, str(err))
            return
        log = ""
        name = self.selected or (state.services[0].name if state.services else None)
        if name:
            try:
                log = self.api.log(name)
            except ConsoleError:
                log = self.last_log
        self.call_from_thread(self.show_state, state, name, log)

    def show_state(self, state: State, name: str | None, log: str) -> None:
        checkout = state.checkout
        host = self.remote_info.host if self.remote_info else "localhost"
        top = Text.assemble(
            ("MunServ operator", "bold #F0873F"), (" │ checkout ", "#9AA3B2"),
            (f"{checkout.branch or 'detached'}@{checkout.sha}", "#E6E9EE"), (" │ laptop ", "#9AA3B2"), (host, "#E6E9EE"),
        )
        if state.showcase:
            top.append_text(Text.assemble((" │ demo ", "#9AA3B2"), (showcase_summary(state.showcase), "#E6E9EE")))
        self.query_one("#topbar", Static).update(top)
        self.fill_table(state.services, checkout.sha)
        if name and self.selected is None:
            self.selected = name
        self.query_one("#log-title", Static).update(f"LOG · {self.selected or ''}")
        if log != self.last_log:
            widget = self.query_one("#log", Log)
            widget.clear()
            widget.write(log)
            self.last_log = log

    def fill_table(self, services: tuple[Service, ...], sha: str) -> None:
        table = self.query_one("#services", DataTable)
        names = [s.name for s in services]
        current = [str(key.value) for key in table.rows]
        if names != current:
            cursor = table.cursor_row
            table.clear()
            for s in services:
                table.add_row(state_cell(s), s.name, s.port, health_cell(s), sha_cell(s, sha), note_cell(s), key=s.name)
            if services:
                table.move_cursor(row=min(cursor, len(services) - 1))
            return
        for s in services:
            cell = Text("… working", style="#F0873F") if s.name in self.busy else state_cell(s)
            table.update_cell(s.name, "state", cell)
            table.update_cell(s.name, "port", s.port)
            table.update_cell(s.name, "health", health_cell(s))
            table.update_cell(s.name, "sha", sha_cell(s, sha))
            table.update_cell(s.name, "note", note_cell(s))

    def show_offline(self, message: str) -> None:
        self.query_one("#topbar", Static).update(
            Text.assemble(("MunServ operator", "bold #F0873F"), (" │ console offline: ", "#FF6B62"), (message, "#E6E9EE"),
                          ("   run ./tui.sh, which starts it", "#9AA3B2")))

    def show_links(self, remote: Remote) -> None:
        self.remote_info = remote
        lines = [Text.assemble((f"{label:<9}", "#9AA3B2"), (remote.urls[key], "#E6E9EE"))
                 for key, label in (("web", "Web"), ("swagger", "Swagger"), ("console_with_token", "Console"))
                 if remote.urls.get(key)]
        if remote.firewall_command:
            lines.append(Text.assemble(("Firewall ", "#9AA3B2"), (remote.firewall_command, "#E5B73B")))
        for key, label in (("web", "Demo web"), ("swagger", "Demo API")):
            if remote.showcase_urls.get(key):
                lines.append(Text.assemble((f"{label:<9}", "#9AA3B2"), (remote.showcase_urls[key], "#E6E9EE")))
        if remote.showcase_firewall_command:
            lines.append(Text.assemble(("Demo fw  ", "#9AA3B2"), (remote.showcase_firewall_command, "#E5B73B")))
        self.query_one("#links", Static).update(Text("\n").join(lines))

    def show_links_error(self, message: str) -> None:
        self.query_one("#links", Static).update(Text(message, style="#FF6B62"))

    # ---- selection -----------------------------------------------------------------------------

    def on_data_table_row_highlighted(self, event: DataTable.RowHighlighted) -> None:
        name = str(event.row_key.value)
        if name != self.selected:
            self.selected = name
            self.last_log = ""
            self.query_one("#log", Log).clear()
            self.query_one("#log-title", Static).update(f"LOG · {name}")
            self.poll()

    def highlighted(self) -> str | None:
        table = self.query_one("#services", DataTable)
        if not table.row_count:
            return None
        return str(table.coordinate_to_cell_key(table.cursor_coordinate).row_key.value)

    # ---- actions -------------------------------------------------------------------------------

    def action_start(self) -> None:
        if name := self.highlighted():
            self.run_service_action("start", (name,))

    def action_stop(self) -> None:
        if name := self.highlighted():
            self.run_service_action("stop", (name,))

    def action_restart(self) -> None:
        if name := self.highlighted():
            self.run_service_action("restart", (name,))

    def action_start_stack(self) -> None:
        self.run_service_action("start", EYEBALL_STACK)

    def action_phone(self) -> None:
        self.push_screen(PhoneScreen(self.api))

    def action_eyeball(self) -> None:
        self.push_screen(EyeballScreen(self.api))

    def action_refresh(self) -> None:
        self.refresh_console()
        self.load_remote()

    @work(thread=True, exclusive=True, group="refresh")
    def refresh_console(self) -> None:
        try:
            self.api.refresh()
        except ConsoleError as err:
            self.call_from_thread(self.notify, str(err), severity="error")
            return
        self.call_from_thread(self.poll)

    def action_showcase(self, verb: str) -> None:
        if verb == "build":
            self.select_row(BUILD_LOG_ROW)  # the build log fills the log pane
        self.run_showcase_action(verb)

    def select_row(self, name: str) -> None:
        table = self.query_one("#services", DataTable)
        keys = [str(key.value) for key in table.rows]
        if name in keys:
            table.move_cursor(row=keys.index(name))

    @work(thread=True, group="showcase")
    def run_showcase_action(self, verb: str) -> None:
        actions = {"update": self.api.showcase_update, "build": self.api.showcase_build,
                   "start": self.api.showcase_start, "stop": self.api.showcase_stop}
        self.call_from_thread(self.notify, f"demo {verb}: working")
        try:
            message = actions[verb]()
            self.call_from_thread(self.notify, message or f"demo {verb}: done")
        except ConsoleError as err:
            self.call_from_thread(self.notify, str(err), severity="error")
        self.call_from_thread(self.poll)

    def action_copy(self, key: str) -> None:
        urls = self.remote_info.urls if self.remote_info else {}
        url = urls.get("console_with_token" if key == "console" else key)
        if not url:
            self.notify("No link yet; the console has not answered.", severity="warning")
            return
        self.copy_to_clipboard(url)
        self.notify(f"Copied the {key} link. Your terminal must allow OSC 52 clipboard writes.")

    @work(thread=True, group="actions")
    def run_service_action(self, verb: str, names: tuple[str, ...]) -> None:
        for name in names:
            self.busy.add(name)
            message = ""
            try:
                if verb in ("stop", "restart"):
                    message = self.api.stop(name)
                    self.wait_until_down(name)
                if verb in ("start", "restart"):
                    message = self.api.start(name)
                self.call_from_thread(self.notify, message or f"{verb} {name}: done")
            except ConsoleError as err:
                self.call_from_thread(self.notify, str(err), severity="error")
            finally:
                self.busy.discard(name)
        self.call_from_thread(self.poll)

    def wait_until_down(self, name: str) -> None:
        deadline = time.monotonic() + STOP_WAIT_SECONDS
        while time.monotonic() < deadline:
            service = next((s for s in self.api.state().services if s.name == name), None)
            if service is None or not (service.running or service.up):
                return
            time.sleep(0.5)
