#!/usr/bin/env python3
"""Run the guard-git hook against .claude/hooks/tests/guard-git-cases.txt.

Case file format: `<expected exit>\t<command>`; a case may continue over following
lines (heredocs) until the next line that starts with a digit and a tab.
Each case runs twice: with jq, and with jq hidden so the guard falls back to node, as on the
Windows laptop. Then the fail-closed cases: no parser, or input that does not parse, refuses.
Needs jq and node on PATH (CI has both; in the container: TEST_APT=nodejs).
Exit 1 if any case returns a different exit code.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOOK = ROOT / ".claude" / "hooks" / "guard-git.sh"
CASES = ROOT / ".claude" / "hooks" / "tests" / "guard-git-cases.txt"
PS_CASES = ROOT / ".claude" / "hooks" / "tests" / "guard-git-powershell-cases.txt"
SETTINGS = ROOT / ".claude" / "settings.json"


def parse(text: str) -> list[tuple[int, str, str]]:
    """Each case is `<exit>\t<command>` or `<exit>\t<branch>\t<command>` (branch defaults to a feature branch)."""
    entries: list[list] = []
    for line in text.split("\n"):
        if len(line) > 1 and line[0].isdigit() and line[1] == "\t":
            parts = line[2:].split("\t", 1)
            branch, cmd = (parts[0], parts[1]) if len(parts) == 2 else ("feat/hook-test", parts[0])
            entries.append([int(line[0]), branch, cmd])
        elif entries:
            entries[-1][2] += "\n" + line
    return [(e[0], e[1], e[2].rstrip("\n")) for e in entries]


def path_without(path: str, tools: tuple[str, ...], shim: Path) -> str:
    """PATH with `tools` gone: each folder holding one is swapped for a shim folder linking the rest."""
    shim.mkdir(exist_ok=True)
    dirs: list[str] = []
    for d in path.split(os.pathsep):
        folder = Path(d)
        if not any((folder / t).exists() for t in tools):
            dirs.append(d)
            continue
        for f in folder.iterdir():
            if f.name not in tools and not (shim / f.name).exists():
                try:
                    (shim / f.name).symlink_to(f)
                except OSError:
                    pass
        if str(shim) not in dirs:
            dirs.append(str(shim))
    return os.pathsep.join(dirs)


def run(stdin: str, branch: str, path: str, windows_bash: bool = False, mode: str = "bash") -> subprocess.CompletedProcess:
    # Pin the branch context, whatever CI checked out; optionally stand in for Git Bash.
    env = {**os.environ, "GUARD_GIT_BRANCH": branch, "PATH": path}
    env.pop("GUARD_GIT_WINDOWS_BASH", None)
    if windows_bash:
        env["GUARD_GIT_WINDOWS_BASH"] = "1"
    return subprocess.run(["bash", str(HOOK), mode], input=stdin, capture_output=True, text=True, cwd=ROOT, env=env)


def main() -> int:
    for tool in ("jq", "node"):
        if not shutil.which(tool):
            print(f"FAIL {tool} is not on PATH; these tests run the guard with jq and with its node fallback"
                  " (container: TEST_APT=nodejs)")
            return 1
    failures = 0
    cases = parse(CASES.read_text())
    ps_cases = parse(PS_CASES.read_text())
    with tempfile.TemporaryDirectory() as tmp:
        full = os.environ["PATH"]
        no_jq = path_without(full, ("jq",), Path(tmp) / "no-jq")
        neither = path_without(full, ("jq", "node"), Path(tmp) / "neither")
        # A jq that writes CRLF, as a native jq.exe does under Git Bash (PR 317 review B1).
        crlf_dir = Path(tmp) / "crlf-jq"
        crlf_dir.mkdir()
        (crlf_dir / "jq").write_text(f"#!/usr/bin/env bash\n\"{shutil.which('jq')}\" \"$@\" | sed 's/$/\\r/'\n")
        (crlf_dir / "jq").chmod(0o755)
        # Under Git Bash node is tried first, so the CRLF jq is only reached with node gone.
        crlf = f"{crlf_dir}{os.pathsep}{path_without(full, ('node',), Path(tmp) / 'no-node')}"
        # The shims must hide what they claim, or the [node], CRLF and no-parser runs prove nothing.
        shims = [("no-jq hides jq", shutil.which("jq", path=no_jq) is None),
                 ("no-jq keeps node", shutil.which("node", path=no_jq) is not None),
                 ("neither hides jq and node", shutil.which("jq", path=neither) is None and shutil.which("node", path=neither) is None),
                 ("crlf puts the CRLF jq first and hides node",
                  shutil.which("jq", path=crlf) == str(crlf_dir / "jq") and shutil.which("node", path=crlf) is None)]
        for name, ok in shims:
            failures += not ok
            print(("ok  " if ok else "FAIL"), name)
        # Every case, read by jq and then by the node fallback the Windows laptop uses.
        # Both shell tools must reach the guard: Bash plain, PowerShell with its mode.
        entries = json.loads(SETTINGS.read_text())["hooks"]["PreToolUse"]
        wired = {e["matcher"]: [h["command"] for h in e["hooks"]] for e in entries}
        for matcher, suffix in (("Bash", "guard-git.sh"), ("PowerShell", "guard-git.sh powershell")):
            ok = any(c.endswith(suffix) for c in wired.get(matcher, []))
            failures += not ok
            print(("ok  " if ok else "FAIL"), f"settings.json runs {suffix} on {matcher}")
        # The PowerShell tool's entry runs the same hook with `powershell` (backtick continuations,
        # here-strings, Start-Process, the call operator).
        for label, path in (("jq", full), ("node", no_jq)):
            for mode, mode_cases in (("bash", cases), ("powershell", ps_cases)):
                for want, branch, cmd in mode_cases:
                    r = run(json.dumps({"tool_input": {"command": cmd}}), branch, path, mode=mode)
                    ok = r.returncode == want
                    failures += not ok
                    print(("ok  " if ok else "FAIL"), f"[{label} {mode}] want={want} got={r.returncode}", cmd.splitlines()[0][:70])
        # Fail closed: an unreadable command is refused, never read as empty and allowed.
        def cmd_input(c: object) -> str:
            return json.dumps({"tool_input": {"command": c}})

        win = True
        closed = [
            ("no jq and no node refuses a harmless command", cmd_input("ls"), neither, 2, False),
            ("no jq and no node refuses a force push", cmd_input("git push --force"), neither, 2, False),
            # PR 317 review B1: a native jq.exe under Git Bash writes CRLF.
            ("Git Bash: a CRLF jq still joins a continued force push", cmd_input("git push \\\n  -f origin feat/x"), crlf, 2, win),
            ("Git Bash: a CRLF jq still joins a continued label release",
             cmd_input("gh pr edit 3 \\\n--add-label ci-edit-approved"), crlf, 2, win),
            ("Git Bash: a CRLF jq lets a harmless command through", cmd_input("git status"), crlf, 0, win),
            ("Git Bash: backslash-CR-LF in the command joins, as Git Bash does",
             cmd_input("git push \\\r\n  -f origin feat/x"), no_jq, 2, win),
            # PR 317 second review S1: Linux bash does not join backslash-CR-LF; the next line runs alone.
            ("Linux: backslash-CR-LF does not hide the next line",
             cmd_input("echo \\\r\ngh pr edit 3 --add-label ci-edit-approved"), full, 2, False),
            ("Linux: backslash-CR-LF does not hide a force push on the next line",
             cmd_input("echo \\\r\ngit push -f origin feat/x"), full, 2, False),
        ]
        for label, path in (("jq", full), ("node", no_jq)):
            closed += [
                (f"{label} refuses input that does not parse", "not json", path, 2, False),
                (f"{label} refuses empty input", "", path, 2, False),
                (f"{label} refuses whitespace-only input", "   \n", path, 2, False),
                (f"{label} refuses a payload with no command", json.dumps({"tool_input": {}}), path, 2, False),
                (f"{label} refuses a command that is not a string", cmd_input(123), path, 2, False),
                (f"{label} lets an empty command string through", cmd_input(""), path, 0, False),
            ]
        for name, stdin, path, want, windows_bash in closed:
            r = run(stdin, "feat/hook-test", path, windows_bash)
            ok = r.returncode == want
            failures += not ok
            print(("ok  " if ok else "FAIL"), f"want={want} got={r.returncode}", name)
        # A hook past its 10 s timeout lets the call run, so many quoted strings after an interpreter
        # must still be scanned in time and reach a forbidden command at the very end (PR 319 review B5).
        many = 'eval "x"; ' + " ; ".join(f"echo 'a {i}' \"b {i}\"" for i in range(150)) + " ; bash -c 'git push -f origin feat/x'"
        started = time.monotonic()
        r = run(json.dumps({"tool_input": {"command": many}}), "feat/hook-test", full)
        took = time.monotonic() - started
        ok = r.returncode == 2 and took < 8
        failures += not ok
        print(("ok  " if ok else "FAIL"), f"150 quoted strings after eval: want=2 got={r.returncode} in {took:.1f}s (limit 8s)")
        # More than 200 substitutions refuses instead of leaving the rest unread (PR 319 second review S2).
        subs = "echo " + " ".join(["$(:)"] * 201) + " ; echo done"
        r = run(json.dumps({"tool_input": {"command": subs}}), "feat/hook-test", full)
        ok = r.returncode == 2
        failures += not ok
        print(("ok  " if ok else "FAIL"), f"201 substitutions: want=2 got={r.returncode}")
        # The cap holds below depth 0 too (PR 319 third review B2).
        deep = "bash -c 'echo " + " ".join(["$(:)"] * 200) + " $(git push -f origin feat/x)'"
        r = run(json.dumps({"tool_input": {"command": deep}}), "feat/hook-test", full)
        ok = r.returncode == 2
        failures += not ok
        print(("ok  " if ok else "FAIL"), f"200 substitutions inside bash -c, then a push: want=2 got={r.returncode}")
        # Without its awk files beside it, the hook refuses everything.
        for missing in ("guard-git-tok.awk", "guard-git-heredocs.awk"):
            lone = Path(tmp) / f"lone-{missing}"
            lone.mkdir()
            shutil.copy(HOOK, lone / "guard-git.sh")
            for other in ("guard-git-tok.awk", "guard-git-heredocs.awk"):
                if other != missing:
                    shutil.copy(HOOK.parent / other, lone / other)
            r = subprocess.run(["bash", str(lone / "guard-git.sh")], input=json.dumps({"tool_input": {"command": "git status"}}),
                               capture_output=True, text=True, cwd=ROOT, env={**os.environ, "GUARD_GIT_BRANCH": "feat/hook-test"})
            ok = r.returncode == 2
            failures += not ok
            print(("ok  " if ok else "FAIL"), f"no {missing} beside the hook: want=2 got={r.returncode}")
        r = run(json.dumps({"tool_input": {"command": "ls"}}), "feat/hook-test", neither)
        ok = "install node or jq" in r.stderr
        failures += not ok
        print(("ok  " if ok else "FAIL"), "the no-parser refusal names the fix")
    print(f"{failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
