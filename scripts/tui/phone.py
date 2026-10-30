"""The Phone screen: pair a phone over wireless debugging, build and install the app, read its log.

Like the main screen it owns no process: every adb and flutter call runs in the factory console
(scripts/console/mobile.py) and this screen reads the result over the console API. The pairing
wizard walks the person through the phone-side steps; the two adb commands behind it are
`adb pair <ip>:<port> <code>` and `adb connect <ip>:<port>`. Wireless debugging needs Android 11.
"""
from __future__ import annotations

from rich.text import Text
from textual import work
from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import DataTable, Footer, Input, Log, Static

from .api import ConsoleApi, ConsoleError, Device, Job, Phone

POLL_SECONDS = 3.0
BUILD_LOG = "mobile-install"
LOGCAT_LOG = "phone-logcat"
SOURCE_LABEL = {"eyeball": "the eyeball checkout", "showcase": "the showcase checkout"}

# Each step: the plain-English instruction and the inputs it shows.
WIZARD_STEPS: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("On the phone, open Settings, then About phone. Tap Build number seven times to turn on "
     "developer options. The phone must run Android 11 or newer.", ()),
    ("On the phone, open Settings, then System, then Developer options. Switch on Wireless debugging "
     "and allow it on this Wi-Fi network. The phone and this laptop must be on the same Wi-Fi.", ()),
    ("On the phone, tap Pair device with pairing code. The phone shows an IP address and port and a "
     "six-digit code. Type the address and the code below, then press Enter.", ("pair-address", "pair-code")),
    ("Close the pairing window. At the top of the Wireless debugging screen the phone shows IP address "
     "and port. This port differs from the pairing port. Type it below, then press Enter.", ("connect-address",)),
    ("The phone is connected. Select it in the list and press i to build and install the app.", ()),
)
LAST_STEP = len(WIZARD_STEPS) - 1
PAIR_STEP = 2
CONNECT_STEP = 3
INPUT_IDS = ("pair-address", "pair-code", "connect-address")

ANDROID_STYLE = {"ok": "#E6E9EE", "old": "#E5B73B"}
DEVICE_STATE_STYLE = {"device": "#5DBE8A", "unauthorized": "#E5B73B", "offline": "#FF6B62"}


def android_cell(device: Device, min_sdk: int) -> Text:
    if not device.sdk:
        return Text("")
    old = device.sdk < min_sdk
    return Text(f"{device.release}" + (" (too old)" if old else ""), style=ANDROID_STYLE["old" if old else "ok"])


def state_cell(device: Device) -> Text:
    return Text(device.state, style=DEVICE_STATE_STYLE.get(device.state, "#9AA3B2"))


class PhoneScreen(Screen):
    BINDINGS = [
        Binding("escape", "back", "Back"),
        Binding("n", "next_step", "Wizard: next"),
        Binding("b", "previous_step", "Wizard: back"),
        Binding("i", "install('eyeball')", "Install: eyeball"),
        Binding("s", "install('showcase')", "Install: showcase"),
        Binding("o", "open_app", "Open app"),
        Binding("l", "toggle_logcat", "Log on/off"),
        Binding("v", "toggle_view", "Build/app log"),
    ]

    def __init__(self, api: ConsoleApi) -> None:
        super().__init__()
        self.api = api
        self.phone: Phone | None = None
        self.step = 0
        self.view = BUILD_LOG
        self.last_log = ""
        self.awaiting_job = False

    def compose(self) -> ComposeResult:
        yield Static(id="phone-top")
        with Horizontal(id="phone-main"):
            with Vertical(id="phone-left"):
                yield Static("PHONES", classes="eyebrow")
                yield DataTable(id="devices", cursor_type="row", zebra_stripes=False)
                yield Static(id="wizard-title", classes="eyebrow")
                yield Static(id="wizard-text")
                yield Input(placeholder="pairing address, e.g. 192.168.1.20:37099", id="pair-address")
                yield Input(placeholder="six-digit pairing code", id="pair-code", max_length=6)
                yield Input(placeholder="connect address, e.g. 192.168.1.20:41233", id="connect-address")
            with Vertical(id="phone-right"):
                yield Static(id="phone-log-title", classes="eyebrow")
                yield Log(id="phone-log", auto_scroll=True)
        yield Footer()

    def on_mount(self) -> None:
        table = self.query_one("#devices", DataTable)
        table.add_column("Phone", key="id", width=22)
        table.add_column("Model", key="model", width=18)
        table.add_column("Android", key="android", width=14)
        table.add_column("State", key="state", width=13)
        self.show_step()
        self.show_log_title()
        self.poll()
        self.set_interval(POLL_SECONDS, self.poll)

    # ---- polling -------------------------------------------------------------------------------

    @work(thread=True, exclusive=True, group="phone-poll")
    def poll(self) -> None:
        try:
            phone = self.api.phone()
            job = self.api.install_job()
            log = self.api.log(self.view)
        except ConsoleError as err:
            self.app.call_from_thread(self.show_offline, str(err))
            return
        self.app.call_from_thread(self.show_phone, phone, job, log)

    def show_offline(self, message: str) -> None:
        self.query_one("#phone-top", Static).update(
            Text.assemble(("Phone", "bold #F0873F"), (" │ console offline: ", "#FF6B62"), (message, "#E6E9EE")))

    def show_phone(self, phone: Phone, job: Job | None, log: str) -> None:
        self.phone = phone
        ports = " and ".join(f"{port} ({SOURCE_LABEL[name].split()[1]})" for name, port in phone.ports.items())
        self.query_one("#phone-top", Static).update(Text.assemble(
            ("Phone", "bold #F0873F"), (" │ laptop ", "#9AA3B2"), (phone.lan_ip or "no LAN address", "#E6E9EE"),
            (" │ the app calls port ", "#9AA3B2"), (ports, "#E6E9EE"),
            (f" │ Android {_release_name(phone.min_sdk)}+", "#9AA3B2")))
        self.fill_devices(phone)
        if self.awaiting_job and job and job.status != "running":
            self.awaiting_job = False
            self.notify(job.message, severity="information" if job.status == "success" else "error")
        if log != self.last_log:
            widget = self.query_one("#phone-log", Log)
            widget.clear()
            widget.write(log)
            self.last_log = log

    def fill_devices(self, phone: Phone) -> None:
        table = self.query_one("#devices", DataTable)
        ids = [d.id for d in phone.devices]
        if ids != [str(key.value) for key in table.rows]:
            cursor = table.cursor_row
            table.clear()
            for d in phone.devices:
                table.add_row(d.id, d.model or "unknown", android_cell(d, phone.min_sdk), state_cell(d), key=d.id)
            if ids:
                table.move_cursor(row=min(cursor, len(ids) - 1))
            return
        for d in phone.devices:
            table.update_cell(d.id, "model", d.model or "unknown")
            table.update_cell(d.id, "android", android_cell(d, phone.min_sdk))
            table.update_cell(d.id, "state", state_cell(d))

    def selected_device(self) -> Device | None:
        table = self.query_one("#devices", DataTable)
        if not self.phone or not table.row_count:
            return None
        key = table.coordinate_to_cell_key(table.cursor_coordinate).row_key.value
        return next((d for d in self.phone.devices if d.id == key), None)

    def ready_device(self) -> Device | None:
        """The highlighted phone when it can take the app; otherwise a notice saying why not."""
        device = self.selected_device()
        if device is None:
            self.notify("No phone in the list. Pair one with the wizard first.", severity="warning")
        elif device.state != "device":
            self.notify(f"{device.id} is {device.state}. Accept the debugging prompt on the phone.", severity="warning")
        elif self.phone and device.sdk < self.phone.min_sdk:
            self.notify(f"{device.id} runs Android {device.release}. Wireless debugging needs "
                        f"{_release_name(self.phone.min_sdk)} or newer.", severity="error")
        else:
            return device
        return None

    # ---- pairing wizard ------------------------------------------------------------------------

    def show_step(self) -> None:
        text, inputs = WIZARD_STEPS[self.step]
        self.query_one("#wizard-title", Static).update(f"PAIR A PHONE · step {self.step + 1} of {len(WIZARD_STEPS)}")
        self.query_one("#wizard-text", Static).update(
            text + ("" if inputs or self.step == LAST_STEP else "  Press n when done."))
        for input_id in INPUT_IDS:
            self.query_one(f"#{input_id}", Input).display = input_id in inputs
        if inputs:
            self.query_one(f"#{inputs[0]}", Input).focus()
        else:
            self.query_one("#devices", DataTable).focus()

    def action_next_step(self) -> None:
        if self.step == PAIR_STEP or self.step == CONNECT_STEP:
            return  # these steps advance when adb succeeds
        self.step = 0 if self.step == LAST_STEP else self.step + 1
        self.show_step()

    def action_previous_step(self) -> None:
        self.step = max(0, self.step - 1)
        self.show_step()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if event.input.id == "connect-address":
            self.run_connect(event.value.strip())
        elif event.input.id == "pair-address":
            self.query_one("#pair-code", Input).focus()
        else:
            self.run_pair(self.query_one("#pair-address", Input).value.strip(), event.value.strip())

    @work(thread=True, exclusive=True, group="phone-wizard")
    def run_pair(self, address: str, code: str) -> None:
        self.app.call_from_thread(self.notify, "pairing: working")
        try:
            message = self.api.phone_pair(address, code)
        except ConsoleError as err:
            self.app.call_from_thread(self.notify, str(err), severity="error")
            return
        self.app.call_from_thread(self.wizard_to, CONNECT_STEP, message)

    @work(thread=True, exclusive=True, group="phone-wizard")
    def run_connect(self, address: str) -> None:
        self.app.call_from_thread(self.notify, "connecting: working")
        try:
            message = self.api.phone_connect(address)
        except ConsoleError as err:
            self.app.call_from_thread(self.notify, str(err), severity="error")
            return
        self.app.call_from_thread(self.wizard_to, LAST_STEP, message)
        self.app.call_from_thread(self.poll)

    def wizard_to(self, step: int, message: str) -> None:
        self.step = step
        self.show_step()
        self.notify(message)

    # ---- build, install, launch, log -----------------------------------------------------------

    def action_install(self, source: str) -> None:
        if device := self.ready_device():
            self.view = BUILD_LOG
            self.last_log = ""
            self.show_log_title()
            self.run_install(device.id, source)

    @work(thread=True, group="phone-install")
    def run_install(self, device_id: str, source: str) -> None:
        try:
            self.api.phone_install(device_id, source)
        except ConsoleError as err:
            self.app.call_from_thread(self.notify, str(err), severity="error")
            return
        self.awaiting_job = True
        self.app.call_from_thread(self.notify, f"building from {SOURCE_LABEL[source]}, then installing on {device_id}")
        self.app.call_from_thread(self.poll)

    def action_open_app(self) -> None:
        if device := self.ready_device():
            self.run_simple(lambda: self.api.phone_launch(device.id))

    def action_toggle_logcat(self) -> None:
        if self.view == LOGCAT_LOG and self.last_log:
            self.run_simple(self.api.phone_logcat_stop)
            self.view = BUILD_LOG
            self.show_log_title()
        elif device := self.ready_device():
            self.view = LOGCAT_LOG
            self.last_log = ""
            self.show_log_title()
            self.run_simple(lambda: self.api.phone_logcat(device.id))

    def action_toggle_view(self) -> None:
        self.view = LOGCAT_LOG if self.view == BUILD_LOG else BUILD_LOG
        self.last_log = ""
        self.show_log_title()
        self.poll()

    def show_log_title(self) -> None:
        self.query_one("#phone-log-title", Static).update(
            "LOG · build and install" if self.view == BUILD_LOG else "LOG · app on the phone")

    @work(thread=True, group="phone-action")
    def run_simple(self, call) -> None:
        try:
            self.app.call_from_thread(self.notify, call())
        except ConsoleError as err:
            self.app.call_from_thread(self.notify, str(err), severity="error")
        self.app.call_from_thread(self.poll)

    def action_back(self) -> None:
        if isinstance(self.focused, Input):
            self.query_one("#devices", DataTable).focus()
        else:
            self.app.pop_screen()


def _release_name(sdk: int) -> str:
    """Android 11 is API 30: the release number the person knows, from the API level adb reports."""
    return str(sdk - 19) if sdk else "?"
