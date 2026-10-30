"""The Eyeball screen: run a PR's manual checks from the terminal.

Each check in the handoff's Eyeball block is a card: title, who to log in as, numbered steps and what
you should see. A step that is a command shows a Run key; its output prints under the step. Pass, Fail
and a note per check save through the console (`/api/eyeball/save`); Submit (`/api/eyeball/submit`)
files the failures, comments on the PR and sets its eyeball label, exactly as the console's web
section does. Commands run on this laptop (runner.py).
"""
from __future__ import annotations

import copy
import threading

from rich.text import Text
from textual import work
from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.screen import Screen
from textual.widgets import Footer, Input, Static

from .api import Candidate, Check, ConsoleApi, ConsoleError, Eyeball
from .runner import command_of, run_command

RESULT_MARK = {"pass": ("PASS", "#5DBE8A"), "fail": ("FAIL", "#FF6B62"), None: ("not checked", "#9AA3B2")}
STAGE_WORDS = {"in_progress": "in progress", "in_review": "in review", "awaiting_eyeball": "awaiting eyeball",
               "ready_to_merge": "ready to merge"}
MAX_STEP_KEYS = 9
EMPTY_ENTRY = {"result": None, "note": "", "issue_url": None, "issue_reused": False}


def label_of(candidate: Candidate) -> str:
    return f"PR #{candidate.number}" if candidate.number else candidate.title


def tally(candidate: Candidate, results: dict) -> tuple[int, int]:
    """(checked, total) for the candidate's checks."""
    entries = results.get("checks", {})
    checked = sum(1 for c in candidate.checks if entries.get(c.id, {}).get("result"))
    return checked, len(candidate.checks)


def login_line(check: Check, accounts: dict[str, dict]) -> str:
    account = accounts.get(check.account) or {}
    if check.account == "none":
        return "no login needed"
    if account.get("email"):
        return f"{check.account}: {account['email']} / {account.get('password', '')}"
    return check.account


def card_text(check: Check, entry: dict, accounts: dict[str, dict], outputs: dict[int, str]) -> Text:
    """One check as a card. `outputs` maps a step index to what its command printed."""
    mark, colour = RESULT_MARK[entry.get("result")]
    text = Text.assemble((f"{check.id}  ", "bold #F0873F"), (check.title, "bold"), ("   ", ""), (f"[{mark}]", f"bold {colour}"))
    text.append("\nLog in as  ", style="#9AA3B2")
    text.append(login_line(check, accounts))
    if check.url:
        text.append("\nOpen       ", style="#9AA3B2")
        text.append(check.url)
    for index, step in enumerate(check.steps):
        command = command_of(step)
        text.append(f"\n{index + 1:>2}. ", style="#9AA3B2")
        if command is None:
            text.append(step)
            continue
        text.append(command, style="#7FB3D5")
        if index < MAX_STEP_KEYS:
            text.append(f"   ▶ press {index + 1} to run", style="#F0873F")
        if index in outputs:
            text.append("\n" + "\n".join(f"      {line}" for line in outputs[index].splitlines()), style="#9AA3B2")
    text.append("\nYou should see  ", style="#9AA3B2")
    text.append(check.expect)
    if entry.get("note"):
        text.append("\nNote            ", style="#9AA3B2")
        text.append(entry["note"], style="#E5B73B")
    if entry.get("issue_url"):
        text.append(f"\nIssue           {entry['issue_url']}", style="#9AA3B2")
    return text


class EyeballScreen(Screen):
    BINDINGS = [
        Binding("escape", "back", "Back"),
        Binding("down,j", "move_check(1)", "Next check"),
        Binding("up,k", "move_check(-1)", "Previous check"),
        Binding("right_square_bracket", "move_candidate(1)", "Next PR"),
        Binding("left_square_bracket", "move_candidate(-1)", "Previous PR"),
        Binding("p", "mark('pass')", "Pass"),
        Binding("f", "mark('fail')", "Fail"),
        Binding("n", "edit_note", "Note"),
        Binding("s", "submit", "Submit"),
        Binding("r", "reload", "Reload"),
        *[Binding(str(n), f"run_step({n})", "Run step" if n == 1 else "", show=n == 1, key_display="1-9" if n == 1 else None)
          for n in range(1, MAX_STEP_KEYS + 1)],
    ]

    def __init__(self, api: ConsoleApi) -> None:
        super().__init__()
        self.api = api
        self.eyeball: Eyeball | None = None
        self.results: dict[str, dict] = {}
        self.outputs: dict[tuple[str, str], dict[int, str]] = {}
        self.candidate_index = 0
        self.check_index = 0
        self.confirming = False
        self.save_lock = threading.Lock()

    def compose(self) -> ComposeResult:
        yield Static(id="eyeball-top")
        with Horizontal(id="eyeball-main"):
            with Vertical(id="eyeball-left"):
                yield Static("PULL REQUESTS", classes="eyebrow")
                yield Static(id="candidates")
            with Vertical(id="eyeball-right"):
                yield Static(id="eyeball-title", classes="eyebrow")
                yield VerticalScroll(id="cards")
                yield Input(placeholder="note for this check, then Enter (Esc cancels)", id="note")
        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#note", Input).display = False
        self.load()

    def say(self, message: str, severity: str = "information") -> None:
        self.notify(message, severity=severity, markup=False)

    # ---- state ---------------------------------------------------------------------------------

    @property
    def candidate(self) -> Candidate | None:
        if not self.eyeball or not self.eyeball.candidates:
            return None
        return self.eyeball.candidates[self.candidate_index]

    @property
    def check(self) -> Check | None:
        candidate = self.candidate
        return candidate.checks[self.check_index] if candidate and candidate.checks else None

    def entry(self, candidate: Candidate, check: Check) -> dict:
        return self.results[candidate.id]["checks"].setdefault(check.id, dict(EMPTY_ENTRY))

    # ---- loading -------------------------------------------------------------------------------

    @work(thread=True, exclusive=True, group="eyeball-load")
    def load(self, refresh: bool = False) -> None:
        try:
            eyeball = self.api.eyeball(refresh)
        except ConsoleError as err:
            self.app.call_from_thread(self.show_error, str(err))
            return
        self.app.call_from_thread(self.show_eyeball, eyeball)

    def show_error(self, message: str) -> None:
        self.query_one("#eyeball-top", Static).update(
            Text.assemble(("Eyeball", "bold #F0873F"), (" │ console offline: ", "#FF6B62"), (message, "#E6E9EE")))

    def show_eyeball(self, eyeball: Eyeball) -> None:
        self.eyeball = eyeball
        self.results = {c.id: copy.deepcopy(c.results) for c in eyeball.candidates}
        for results in self.results.values():
            results.setdefault("checks", {})
        self.candidate_index = min(self.candidate_index, max(len(eyeball.candidates) - 1, 0))
        self.check_index = 0
        self.render_all()

    # ---- drawing -------------------------------------------------------------------------------

    def render_all(self) -> None:
        self.render_top()
        self.render_candidates()
        self.render_cards()

    def render_top(self) -> None:
        candidate = self.candidate
        top = Text.assemble(("Eyeball", "bold #F0873F"))
        if candidate:
            top.append_text(Text.assemble((" │ ", "#9AA3B2"), (candidate.title, "#E6E9EE")))
        self.query_one("#eyeball-top", Static).update(top)

    def render_candidates(self) -> None:
        lines = []
        for index, candidate in enumerate(self.eyeball.candidates if self.eyeball else ()):
            checked, total = tally(candidate, self.results.get(candidate.id, {}))
            current = index == self.candidate_index
            stage = STAGE_WORDS.get(candidate.stage, candidate.stage)
            line = Text.assemble(("▸ " if current else "  ", "#F0873F"), (label_of(candidate), "bold" if current else ""),
                                 (f"  {checked}/{total}", "#9AA3B2"), (f"  {stage}" if stage else "", "#9AA3B2"))
            lines.append(line)
        self.query_one("#candidates", Static).update(Text("\n").join(lines) if lines else Text("no pull requests"))

    def render_cards(self) -> None:
        cards = self.query_one("#cards", VerticalScroll)
        cards.remove_children()
        candidate = self.candidate
        title = self.query_one("#eyeball-title", Static)
        if candidate is None:
            title.update("CHECKS")
            return
        title.update(f"CHECKS · {label_of(candidate)} · up/down to move, p pass, f fail, n note, s submit")
        if candidate.parse_error:
            cards.mount(Static(Text(f"The handoff's Eyeball block does not parse: {candidate.parse_error}", style="#FF6B62"),
                               classes="card"))
        elif not candidate.checks:
            cards.mount(Static(Text("This pull request has no Eyeball checks."), classes="card"))
        for index, check in enumerate(candidate.checks):
            body = card_text(check, self.entry(candidate, check), self.eyeball.accounts,
                             self.outputs.get((candidate.id, check.id), {}))
            card = Static(body, classes="card current" if index == self.check_index else "card")
            cards.mount(card)
            if index == self.check_index:
                card.scroll_visible(animate=False)

    # ---- moving --------------------------------------------------------------------------------

    def action_move_check(self, step: int) -> None:
        candidate = self.candidate
        if candidate and candidate.checks:
            self.check_index = (self.check_index + step) % len(candidate.checks)
            self.confirming = False
            self.render_cards()

    def action_move_candidate(self, step: int) -> None:
        if self.eyeball and self.eyeball.candidates:
            self.candidate_index = (self.candidate_index + step) % len(self.eyeball.candidates)
            self.check_index = 0
            self.confirming = False
            self.render_all()

    def action_reload(self) -> None:
        self.load(True)

    # ---- marking -------------------------------------------------------------------------------

    def action_mark(self, result: str) -> None:
        candidate, check = self.candidate, self.check
        if candidate is None or check is None:
            return
        entry = self.entry(candidate, check)
        entry["result"] = None if entry.get("result") == result else result
        self.after_edit()

    def action_edit_note(self) -> None:
        candidate, check = self.candidate, self.check
        if candidate is None or check is None:
            return
        field = self.query_one("#note", Input)
        field.value = self.entry(candidate, check).get("note", "")
        field.display = True
        field.focus()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        candidate, check = self.candidate, self.check
        if candidate and check:
            self.entry(candidate, check)["note"] = event.value.strip()
        self.close_note()
        self.after_edit()

    def close_note(self) -> None:
        field = self.query_one("#note", Input)
        field.display = False
        self.query_one("#cards", VerticalScroll).focus()

    def after_edit(self) -> None:
        self.confirming = False
        self.render_candidates()
        self.render_cards()
        self.save()

    @work(thread=True, group="eyeball-save")
    def save(self) -> None:
        """Saves the newest results; the lock keeps two saves from interleaving, and each reads the state at its turn."""
        with self.save_lock:
            candidate = self.candidate
            if candidate is None:
                return
            snapshot = copy.deepcopy(self.results[candidate.id])
            try:
                self.api.eyeball_save(candidate.id, snapshot)
            except ConsoleError as err:
                self.app.call_from_thread(self.say, str(err), severity="error")

    # ---- run a command step --------------------------------------------------------------------

    def action_run_step(self, number: int) -> None:
        candidate, check = self.candidate, self.check
        if candidate is None or check is None or number > len(check.steps):
            return
        command = command_of(check.steps[number - 1])
        if command is None:
            self.say(f"Step {number} is for you to do; it is not a command.", severity="warning")
            return
        self.outputs.setdefault((candidate.id, check.id), {})[number - 1] = "running..."
        self.render_cards()
        self.run_step(candidate.id, check.id, number - 1, command)

    @work(thread=True, group="eyeball-run")
    def run_step(self, candidate_id: str, check_id: str, index: int, command: str) -> None:
        output = run_command(command)
        self.app.call_from_thread(self.show_output, candidate_id, check_id, index, output)

    def show_output(self, candidate_id: str, check_id: str, index: int, output: str) -> None:
        self.outputs.setdefault((candidate_id, check_id), {})[index] = output
        self.render_cards()

    # ---- submit --------------------------------------------------------------------------------

    def action_submit(self) -> None:
        candidate = self.candidate
        if candidate is None:
            return
        checked, _ = tally(candidate, self.results[candidate.id])
        if not checked:
            self.say("Mark at least one check Pass or Fail before you submit.", severity="warning")
            return
        if not self.confirming:
            self.confirming = True
            kind = "labels the PR and files an issue for every failed check" if candidate.number else "saves the smoke result"
            self.say(f"Submit {kind}. Press s again to go ahead.", severity="warning")
            return
        self.confirming = False
        self.say("submitting: working")
        self.submit(candidate.id)

    @work(thread=True, exclusive=True, group="eyeball-submit")
    def submit(self, candidate_id: str) -> None:
        try:
            with self.save_lock:
                self.api.eyeball_save(candidate_id, copy.deepcopy(self.results[candidate_id]))
                submission, data = self.api.eyeball_submit(candidate_id)
        except ConsoleError as err:
            self.app.call_from_thread(self.say, str(err), severity="error")
            return
        self.app.call_from_thread(self.show_submitted, candidate_id, submission, data)

    def show_submitted(self, candidate_id: str, submission, data: dict) -> None:
        self.results[candidate_id] = data
        self.render_candidates()
        self.render_cards()
        label = f" Label: {submission.label}." if submission.label else ""
        link = f" {submission.comment_url}" if submission.comment_url else ""
        self.say(f"Submitted: {submission.passed} of {submission.total} passed.{label}{link}")

    # ---- leaving -------------------------------------------------------------------------------

    def action_back(self) -> None:
        if isinstance(self.focused, Input):
            self.close_note()
        else:
            self.app.pop_screen()
