#!/usr/bin/env python3
"""Run scripts/factory-tick.sh against stub `claude`, `gh` and `notify-send` and a throwaway git repo.

Each case builds a fresh config dir, state dir and a clone of a local bare origin, puts the stubs first
on PATH and checks the exit code, the ledger and the arguments the stubs saw.
Exit 1 if any case fails.
"""
from __future__ import annotations

import datetime
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TICK = ROOT / "scripts" / "factory-tick.sh"

CLAUDE_STUB = r"""#!/usr/bin/env python3
import json, os, sys
log = os.environ["STUB_LOG"]
with open(log, "a") as f:
    f.write(json.dumps({"tool": "claude", "argv": sys.argv[1:], "otel": os.environ.get("OTEL_RESOURCE_ATTRIBUTES", "")}) + "\n")
if "--json-schema" in sys.argv:
    print(json.dumps({"type": "result", "subtype": "success", "is_error": False, "total_cost_usd": 0.04,
                      "structured_output": {"stories": json.loads(os.environ.get("STUB_PICKS", "[]")), "reason": "stub pick"}}))
else:
    print(json.dumps({"type": "result", "subtype": "success", "is_error": False, "total_cost_usd": float(os.environ.get("STUB_STORY_COST", "1.5")),
                      "num_turns": 12, "duration_ms": 1000, "session_id": "s1",
                      "permission_denials": [{"tool_name": "Bash", "tool_use_id": "t1", "tool_input": {"command": "gh label list"}}],
                      "result": "Story done\n```bash\ngh issue create\n```\nCI: green, merged\nPlan: no step\n```"}))
"""

GH_STUB = r"""#!/usr/bin/env python3
import json, os, sys
with open(os.environ["STUB_LOG"], "a") as f:
    f.write(json.dumps({"tool": "gh", "argv": sys.argv[1:]}) + "\n")
if sys.argv[1:3] == ["issue", "list"]:
    print("")
elif sys.argv[1:3] == ["issue", "create"]:
    print("https://github.com/o/r/issues/999")
elif sys.argv[1:3] == ["pr", "list"]:
    print(os.environ.get("STUB_OPEN_SYNC_PRS", "0"))
"""


def write_exe(path: Path, text: str) -> None:
    path.write_text(text)
    path.chmod(0o755)


def git(*args: str, cwd: Path) -> None:
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


class Sandbox:
    def __init__(self, tmp: Path, ledger: list[dict | str], branch: str):
        self.tmp = tmp
        self.config = tmp / "config"
        self.state = tmp / "state"
        self.repo = tmp / "repo"
        self.log = tmp / "stub.log"
        bin_dir = tmp / "bin"
        for d in (self.config, self.state, bin_dir):
            d.mkdir()
        write_exe(bin_dir / "claude", CLAUDE_STUB)
        write_exe(bin_dir / "gh", GH_STUB)
        write_exe(bin_dir / "notify-send", "#!/bin/sh\nexit 0\n")
        origin = tmp / "origin.git"
        git("init", "-q", "--bare", "-b", "master", str(origin), cwd=tmp)
        git("clone", "-q", str(origin), str(self.repo), cwd=tmp)
        (self.repo / ".claude" / "agents").mkdir(parents=True)
        (self.repo / ".claude" / "agents" / "clerk.md").write_text((ROOT / ".claude" / "agents" / "clerk.md").read_text())
        git("add", ".", cwd=self.repo)
        git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "init", cwd=self.repo)
        git("push", "-q", "origin", "master", cwd=self.repo)
        if branch != "master":
            git("switch", "-q", "-c", branch, cwd=self.repo)
        # RETRO_WEEKDAY is empty so a Monday CI run never starts the retro; the retro cases set it.
        base = ["TICK_FIRST_HOUR=0", "TICK_LAST_HOUR=23", f"REPO_DIR={self.repo}", "DAILY_BUDGET_USD=10", "RUN_BUDGET_USD=5",
                "STORIES_PER_TICK=2", "RETRO_WEEKDAY="]
        (self.config / "tick.env").write_text("\n".join(base) + "\n")
        if ledger:
            (self.state / "ticks.jsonl").write_text("".join((r if isinstance(r, str) else json.dumps(r)) + "\n" for r in ledger))
        self.env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}", "STUB_LOG": str(self.log),
                    "MUNSERV_FACTORY_CONFIG": str(self.config), "MUNSERV_FACTORY_STATE": str(self.state)}

    def set_env(self, line: str) -> None:
        """Append a tick.env line; it wins over the base lines and over the process environment."""
        with (self.config / "tick.env").open("a") as f:
            f.write(line + "\n")

    def run(self, *args: str, **env: str) -> subprocess.CompletedProcess:
        return subprocess.run([str(TICK), *args], env={**self.env, **env}, capture_output=True, text=True, timeout=60)

    def calls(self, tool: str) -> list[dict]:
        if not self.log.exists():
            return []
        return [c for c in map(json.loads, self.log.read_text().splitlines()) if c["tool"] == tool]

    def ledger(self) -> list[dict]:
        """The lines this tick wrote (seeded lines carry no tick id)."""
        path = self.state / "ticks.jsonl"
        if not path.exists():
            return []
        rows = []
        for line in path.read_text().splitlines():
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict) and "tick" in row:
                rows.append(row)
        return rows


def arg_after(argv: list[str], flag: str) -> str:
    return argv[argv.index(flag) + 1]


TODAY = datetime.date.today().isoformat()


def case_pause(sb: Sandbox) -> list[str]:
    (sb.config / "pause").touch()
    r = sb.run(STUB_PICKS="[12]")
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}",
        sb.calls("claude") and "claude was called while paused",
        sb.ledger() and "ledger written while paused",
    ] if isinstance(e, str)]


def case_budget_reached(sb: Sandbox) -> list[str]:
    r = sb.run(STUB_PICKS="[12]")
    last = sb.ledger()[-1]
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}",
        sb.calls("claude") and "claude was called with the budget spent",
        last.get("reason") != "daily budget reached" and f"last ledger line {last}",
    ] if isinstance(e, str)]


def case_dispatch(sb: Sandbox) -> list[str]:
    r = sb.run(STUB_PICKS="[12, 14]", STUB_STORY_COST="3.21")
    calls = sb.calls("claude")
    errors = [f"exit {r.returncode}: {r.stderr}"] if r.returncode else []
    if len(calls) != 2:
        return errors + [f"{len(calls)} claude calls, want 2 (select + the first story; the budget is then spent)"]
    select, story = calls[0]["argv"], calls[1]["argv"]
    errors += [e for e in [
        arg_after(select, "--model") != "haiku" and "select not on haiku",
        "You do the factory's bookkeeping" not in arg_after(select, "--append-system-prompt") and "select without the clerk prompt",
        story[:2] != ["-p", "/factory story 12"] and f"story argv {story[:2]}",
        arg_after(story, "--model") != "sonnet" and "story not on sonnet",
        arg_after(story, "--max-turns") != "150" and "max turns not 150",
        arg_after(story, "--output-format") != "json" and "output not json",
        arg_after(story, "--max-budget-usd") != "3.21" and f"run budget {arg_after(story, '--max-budget-usd')}, want 3.21 (10 - 6.75 - 0.04)",
        calls[1]["otel"] != "story.id=12" and f"otel {calls[1]['otel']}",
        any("bypassPermissions" in a or "dangerously" in a for c in calls for a in c["argv"]) and "bypass flag used",
    ] if isinstance(e, str)]
    kinds = [(x["kind"], x.get("story")) for x in sb.ledger()]
    if kinds != [("select", None), ("story", 12), ("skip", 14)]:
        errors.append(f"ledger {kinds}: the second story should be skipped once 6.75 + 0.04 + 3.21 reaches 10")
    story_row = next((x for x in sb.ledger() if x["kind"] == "story"), {})
    if story_row.get("summary") != "CI: green, merged / Plan: no step":
        errors.append(f"summary {story_row.get('summary')!r}, want the CI and Plan lines")
    if story_row.get("permission_denials") != ["Bash: gh label list"]:
        errors.append(f"permission_denials {story_row.get('permission_denials')}")
    if not (sb.state / "runs" / f"{story_row.get('tick')}-12.json").exists():
        errors.append("raw result not kept under runs/")
    comments = [c["argv"] for c in sb.calls("gh") if c["argv"][:2] == ["issue", "comment"]]
    if not comments:
        errors.append("no Factory log comment")
    elif "gh issue create" not in arg_after(comments[0], "--body") or "gh label list" not in arg_after(comments[0], "--body"):
        errors.append("Factory log comment lacks the run's report or its denials")
    return errors


def case_nothing_ready(sb: Sandbox) -> list[str]:
    r = sb.run(STUB_PICKS="[]")
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}",
        len(sb.calls("claude")) != 1 and "story run without a pick",
        [x["kind"] for x in sb.ledger()] != ["select"] and f"ledger {sb.ledger()}",
    ] if isinstance(e, str)]


def case_dry_run(sb: Sandbox) -> list[str]:
    r = sb.run("--dry-run", STUB_PICKS="[12]")
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}",
        len(sb.calls("claude")) != 1 and "dry run dispatched a story",
    ] if isinstance(e, str)]


def case_fetch_fails(sb: Sandbox) -> list[str]:
    git("remote", "set-url", "origin", str(sb.tmp / "missing.git"), cwd=sb.repo)
    r = sb.run(STUB_PICKS="[12]", FETCH_WAIT_SECONDS="0", FETCH_ATTEMPTS="3")
    last = sb.ledger()[-1] if sb.ledger() else {}
    return [e for e in [
        r.returncode != 1 and f"exit {r.returncode}, want 1",
        sb.calls("claude") and "claude was called without a fetch",
        last.get("reason") != "git fetch failed after 3 attempts" and f"last ledger line {last}",
    ] if isinstance(e, str)]


def case_not_on_master(sb: Sandbox) -> list[str]:
    r = sb.run(STUB_PICKS="[12]")
    return [e for e in [
        r.returncode != 1 and f"exit {r.returncode}, want 1",
        sb.calls("claude") and "claude was called off master",
        sb.ledger()[-1]["kind"] != "stop" and "no stop line",
    ] if isinstance(e, str)]


def install_inbox_stub(sb: Sandbox, exit_code: int = 0) -> Path:
    """A `scripts.console` package whose `inbox --publish` records its argv; the real one needs GitHub."""
    package = sb.repo / "scripts" / "console"
    package.mkdir(parents=True)
    (sb.repo / "scripts" / "__init__.py").write_text("")
    (package / "__init__.py").write_text("")
    (package / "inbox.py").write_text("")
    marker = sb.tmp / "inbox.argv"
    (package / "__main__.py").write_text(
        f"import sys\nopen({str(marker)!r}, 'a').write(' '.join(sys.argv[1:]) + '\\n')\nprint('stub inbox')\nsys.exit({exit_code})\n")
    return marker


def case_inbox_on_skip(sb: Sandbox) -> list[str]:
    marker = install_inbox_stub(sb)
    r = sb.run(STUB_PICKS="[12]")
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}",
        not marker.exists() and "inbox was not published on a skipped tick",
        marker.exists() and "inbox --publish" not in marker.read_text() and f"inbox argv {marker.read_text()!r}",
    ] if isinstance(e, str)]


def case_inbox_on_stop(sb: Sandbox) -> list[str]:
    marker = install_inbox_stub(sb)
    r = sb.run(STUB_PICKS="[12]")
    return [e for e in [
        r.returncode != 1 and f"exit {r.returncode}, want 1",
        not marker.exists() and "inbox was not published on a stopped tick",
    ] if isinstance(e, str)]


def case_inbox_failure_keeps_exit_code(sb: Sandbox) -> list[str]:
    install_inbox_stub(sb, exit_code=1)
    r = sb.run(STUB_PICKS="[12]")
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}, want 0",
        "inbox update failed" not in r.stderr and "failure not reported on stderr",
    ] if isinstance(e, str)]


def case_inbox_off(sb: Sandbox) -> list[str]:
    marker = install_inbox_stub(sb)
    sb.run(STUB_PICKS="[12]", INBOX_UPDATE="0")
    return [e for e in [marker.exists() and "inbox published although INBOX_UPDATE=0"] if isinstance(e, str)]


WEEKDAY = str(datetime.date.today().isoweekday())
OTHER_WEEKDAY = str(datetime.date.today().isoweekday() % 7 + 1)


def case_retro_runs_once_on_its_day(sb: Sandbox) -> list[str]:
    sb.set_env(f"RETRO_WEEKDAY={WEEKDAY}")
    first = sb.run(STUB_PICKS="[]", STUB_STORY_COST="1.25")
    second = sb.run(STUB_PICKS="[]")
    calls = [c["argv"] for c in sb.calls("claude")]
    retros = [a for a in calls if a[:2] == ["-p", "/factory-retro"]]
    errors = [f"exit {r.returncode}: {r.stderr}" for r in (first, second) if r.returncode]
    if len(retros) != 1:
        return errors + [f"{len(retros)} retro runs over two ticks, want 1"]
    retro = retros[0]
    errors += [e for e in [
        calls[0][:2] != ["-p", "/factory-retro"] and "retro did not run before the clerk",
        arg_after(retro, "--model") != "opus" and "retro not on opus",
        arg_after(retro, "--max-budget-usd") != "5" and f"retro budget {arg_after(retro, '--max-budget-usd')}, want 5",
        arg_after(retro, "--permission-mode") != "acceptEdits" and "retro not in acceptEdits",
        sb.calls("claude")[0]["otel"] != "story.id=retro" and "retro not tagged for the cost meter",
    ] if isinstance(e, str)]
    kinds = [x["kind"] for x in sb.ledger()]
    if kinds != ["retro", "select", "select"]:
        errors.append(f"ledger kinds {kinds}, want retro then one select per tick")
    retro_row = next((x for x in sb.ledger() if x["kind"] == "retro"), {})
    if retro_row.get("total_cost_usd") != 1.25 or retro_row.get("summary") != "CI: green, merged":
        errors.append(f"retro ledger row {retro_row}")
    return errors


def case_retro_skips_other_days(sb: Sandbox) -> list[str]:
    sb.set_env(f"RETRO_WEEKDAY={OTHER_WEEKDAY}")
    sb.run(STUB_PICKS="[]")
    return ["retro ran on the wrong day"] if any("/factory-retro" in c["argv"] for c in sb.calls("claude")) else []


def case_retro_skips_after_a_manual_run(sb: Sandbox) -> list[str]:
    sb.set_env(f"RETRO_WEEKDAY={WEEKDAY}")
    (sb.repo / "specs" / "metrics").mkdir(parents=True)
    (sb.repo / "specs" / "metrics" / "last-retro").write_text(TODAY + "\n")
    sb.run(STUB_PICKS="[]")
    return ["retro ran although last-retro is today"] if any("/factory-retro" in c["argv"] for c in sb.calls("claude")) else []


def case_retro_not_in_dry_run(sb: Sandbox) -> list[str]:
    sb.set_env(f"RETRO_WEEKDAY={WEEKDAY}")
    r = sb.run("--dry-run", STUB_PICKS="[]")
    return [e for e in [
        any("/factory-retro" in c["argv"] for c in sb.calls("claude")) and "dry run ran the retro",
        "retro is due" not in r.stdout and "dry run does not say the retro is due",
    ] if isinstance(e, str)]


RENDER_STUB = r"""#!/usr/bin/env python3
import os, pathlib, sys
if "--check" in sys.argv:
    sys.exit(int(os.environ.get("STUB_DRIFT", "0")))
row = pathlib.Path("specs/requirements/web.md")
row.parent.mkdir(parents=True, exist_ok=True)
row.write_text("rendered\\n")
"""
GIT_IDENTITY = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"}


def install_render_stub(sb: Sandbox) -> None:
    """Commit a stub render-requirements.py to origin/master; the sync's worktree runs that copy."""
    (sb.repo / "scripts").mkdir(exist_ok=True)
    write_exe(sb.repo / "scripts" / "render-requirements.py", RENDER_STUB)
    git("add", ".", cwd=sb.repo)
    git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "render stub", cwd=sb.repo)
    git("push", "-q", "origin", "master", cwd=sb.repo)


def sync_branches(sb: Sandbox) -> list[str]:
    out = subprocess.run(["git", "ls-remote", "--heads", "origin", "chore/sync-requirements-*"], cwd=sb.repo,
                         capture_output=True, text=True, check=True).stdout
    return out.split()[1::2]


def case_sync_pushes_a_branch_on_drift(sb: Sandbox) -> list[str]:
    install_render_stub(sb)
    r = sb.run(STUB_PICKS="[]", STUB_DRIFT="1", **GIT_IDENTITY)
    local = subprocess.run(["git", "branch", "--list", "chore/sync-requirements-*"], cwd=sb.repo, capture_output=True, text=True).stdout
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}: {r.stderr}",
        len(sync_branches(sb)) != 1 and f"branches on origin {sync_branches(sb)}, want 1",
        bool(local.strip()) and f"local branch left behind: {local}",
        any("requirements-" in p.name for p in (sb.repo / ".claude" / "worktrees").glob("*")) and "worktree left behind",
        [x["kind"] for x in sb.ledger()] != ["requirements_sync", "select"] and f"ledger {[x['kind'] for x in sb.ledger()]}",
    ] if isinstance(e, str)]


def case_sync_quiet_without_drift(sb: Sandbox) -> list[str]:
    install_render_stub(sb)
    sb.run(STUB_PICKS="[]", STUB_DRIFT="0", **GIT_IDENTITY)
    return [f"pushed {sync_branches(sb)} with no drift"] if sync_branches(sb) else []


def case_sync_waits_for_an_open_pr(sb: Sandbox) -> list[str]:
    install_render_stub(sb)
    sb.run(STUB_PICKS="[]", STUB_DRIFT="1", STUB_OPEN_SYNC_PRS="1", **GIT_IDENTITY)
    return [f"pushed {sync_branches(sb)} while a sync PR is open"] if sync_branches(sb) else []


def case_sync_failure_keeps_the_tick_going(sb: Sandbox) -> list[str]:
    install_render_stub(sb)
    git("remote", "set-url", "--push", "origin", str(sb.tmp / "missing.git"), cwd=sb.repo)
    r = sb.run(STUB_PICKS="[]", STUB_DRIFT="1", **GIT_IDENTITY)
    return [e for e in [
        r.returncode != 0 and f"exit {r.returncode}: {r.stderr}",
        "requirements sync failed" not in r.stderr and "failure not reported",
        [x["kind"] for x in sb.ledger()] != ["select"] and f"ledger {[x['kind'] for x in sb.ledger()]}",
    ] if isinstance(e, str)]


def case_sync_skipped_in_dry_run(sb: Sandbox) -> list[str]:
    install_render_stub(sb)
    sb.run("--dry-run", STUB_PICKS="[]", STUB_DRIFT="1", **GIT_IDENTITY)
    return [f"dry run pushed {sync_branches(sb)}"] if sync_branches(sb) else []


def spent(amount: float) -> list[dict]:
    return [{"date": TODAY, "kind": "story", "total_cost_usd": amount}, {"date": "2000-01-01", "total_cost_usd": 99}]


CASES = [
    ("pause file exits before anything", case_pause, {}),
    ("budget reached skips the clerk", case_budget_reached, {"ledger": spent(10)}),
    ("dispatch caps the run at what is left today", case_dispatch, {"ledger": [*spent(6.75), "not json"]}),
    ("nothing ready runs only the clerk", case_nothing_ready, {}),
    ("dry run dispatches nothing", case_dry_run, {}),
    ("a checkout off master stops the tick", case_not_on_master, {"branch": "feat/x"}),
    ("an unreachable origin stops after the retries", case_fetch_fails, {}),
    ("the inbox is published when the tick skips", case_inbox_on_skip, {"ledger": spent(10)}),
    ("the inbox is published when the tick stops", case_inbox_on_stop, {"branch": "feat/x"}),
    ("a failing inbox update keeps the tick's exit code", case_inbox_failure_keeps_exit_code, {"ledger": spent(10)}),
    ("INBOX_UPDATE=0 leaves the inbox alone", case_inbox_off, {"ledger": spent(10)}),
    ("the retro runs once on its weekday, before the clerk", case_retro_runs_once_on_its_day, {}),
    ("the retro waits on other weekdays", case_retro_skips_other_days, {}),
    ("a retro run by hand today is not repeated", case_retro_skips_after_a_manual_run, {}),
    ("a dry run reports the retro but does not run it", case_retro_not_in_dry_run, {}),
    ("requirement drift pushes one sync branch and cleans up", case_sync_pushes_a_branch_on_drift, {}),
    ("no drift pushes nothing", case_sync_quiet_without_drift, {}),
    ("an open sync PR holds the next sync", case_sync_waits_for_an_open_pr, {}),
    ("a failed sync does not stop the tick", case_sync_failure_keeps_the_tick_going, {}),
    ("a dry run does not sync", case_sync_skipped_in_dry_run, {}),
]


def main() -> int:
    failures = 0
    for name, check, opts in CASES:
        with tempfile.TemporaryDirectory() as tmp:
            sb = Sandbox(Path(tmp), opts.get("ledger", []), opts.get("branch", "master"))
            errors = check(sb)
        failures += bool(errors)
        print(f"{'FAIL' if errors else 'ok  '}  {name}" + "".join(f"\n      {e}" for e in errors))
    print(f"{len(CASES) - failures}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
