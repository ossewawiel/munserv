#!/usr/bin/env bash
# PreToolUse guard for Agent: refuse an implementer dispatch that bob-core's gate would not hold.
#
# The implementers have no stop hook of their own; bob-core (prject-bob) gates them at SubagentStop
# from .bob/factory.json. That plugin is a separate install. When it is missing, disabled, older than
# BOB_MIN_VERSION (0.3.0 is the first that honours "handback"), or when node is not on PATH (its
# hook runs on node, and a hook that cannot start does not block), an implementer finishes ungated.
# The factory skill checks this by instruction; this hook checks it on every dispatch (retro
# 2026-11-19, cluster 1).
#
# Gated: any subagent_type ending in "implementer" (backend-implementer, bob-kotlin:implementer).
# scripts/test-guard-dispatch.py pins that every agent in .bob/factory.json matches.
# Fail closed: when the plugin list cannot be read, or takes longer than GUARD_LIST_TIMEOUT (20 s,
# under the 30 s hook timeout), the dispatch is refused.
# The hook reads what is installed, not what this session loaded. A plugin installed after the session
# started is not loaded in it, so every refusal tells the model to dispatch no implementer in this
# session; reading the session start from the transcript would refuse resumed sessions by mistake.
# Bash with no jq (the Windows laptop has none); node parses the plugin list once it is known to run.
# Exit 2 blocks the call and returns the message to the model.
set -u

input=$(cat)
# A JSON string cannot hold an unescaped quote, so "subagent_type" followed by a quote and a colon
# only matches the real key, never text inside the prompt or description.
agent=$(printf '%s' "$input" | grep -o '"subagent_type"[[:space:]]*:[[:space:]]*"[^"\\]*"' | head -n 1 \
  | sed -E 's/.*:[[:space:]]*"([^"]*)"$/\1/')
case "$agent" in
  *implementer) ;;
  *) exit 0 ;;
esac
# From here on, any exit but 0 (pass) or 2 (refuse) is a refusal: Claude Code runs the tool on
# other codes.
trap 'rc=$?; if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then echo "guard-dispatch: not dispatching $agent: the check stopped with exit $rc. Dispatch no implementer; report this to the user." >&2; exit 2; fi' EXIT

plugin="${BOB_PLUGIN:-bob-core@prject-bob}"
min="${BOB_MIN_VERSION:-0.3.0}"
fix="claude plugin marketplace add ossewawiel/prject-bob; claude plugin install $plugin (or claude plugin update $plugin); then start a new session"
deny() {
  echo "guard-dispatch: not dispatching $agent: $1. Its stop gate is bob-core (.bob/factory.json), and it would finish ungated. Dispatch no implementer in this session, even after the fix: a running session does not load a plugin installed after it started. Report this to the user with the fix: $2" >&2
  exit 2
}

command -v node >/dev/null 2>&1 || deny "node is not on PATH, so bob-core's gate hook cannot start" "install Node.js, then start a new session"

claude_bin=""
for c in "$(command -v claude 2>/dev/null)" "$HOME/.local/bin/claude" "$HOME/.local/bin/claude.exe"; do
  if [ -n "$c" ] && [ -x "$c" ]; then claude_bin="$c"; break; fi
done
[ -n "$claude_bin" ] || deny "the claude CLI is not on PATH, so the plugin list cannot be read" "put claude on PATH for hooks, then start a new session"

project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Claude Code lets the tool run when the hook outlives its 30 s timeout, so the list gets less: a hang
# must end in a refusal here. The list runs from the checkout, because its "enabled" is the effective
# value for the cwd's project. A missing `timeout` exits 127, which also refuses.
plugins=$(cd "$project" && timeout "${GUARD_LIST_TIMEOUT:-20}" "$claude_bin" plugin list --json 2>/dev/null) \
  || deny "claude plugin list --json failed or ran past ${GUARD_LIST_TIMEOUT:-20}s" "run claude plugin list --json and fix what it reports"
# Prints one word: ok, missing, disabled, old <version>, or unreadable.
verdict=$(printf '%s' "$plugins" | PLUGIN="$plugin" MIN="$min" PROJECT="$project" node -e '
const path = require("path");
const norm = (p) => { const r = path.resolve(p).replace(/[\\/]+$/, ""); return process.platform === "win32" ? r.toLowerCase() : r; };
// Strict: 0.3.0-rc1 is below 0.3.0, and anything that is not x.y.z[-pre] fails closed.
const parse = (v) => { const m = /^(\d+)\.(\d+)\.(\d+)(-.+)?$/.exec(String(v)); return m && [+m[1], +m[2], +m[3], m[4] ? 0 : 1]; };
const cmp = (a, b) => { for (let i = 0; i < 4; i++) if (a[i] !== b[i]) return a[i] - b[i]; return 0; };
let list;
try { list = JSON.parse(require("fs").readFileSync(0, "utf8")); } catch { console.log("unreadable"); process.exit(0); }
if (!Array.isArray(list)) { console.log("unreadable"); process.exit(0); }
// A project or local install counts only for this checkout: the list also holds other projects
// installs, each reported as enabled.
const here = list.filter((p) => p && p.id === process.env.PLUGIN
  && (p.scope === "user" || (p.projectPath && norm(p.projectPath) === norm(process.env.PROJECT))));
if (here.length === 0) { console.log("missing"); process.exit(0); }
// The most specific install is the one to judge (local, then project, then user), not the newest:
// a newer user copy must not vouch for an older project copy.
const rank = { local: 0, project: 1, user: 2 };
const pick = here.slice().sort((a, b) => (rank[a.scope] ?? 3) - (rank[b.scope] ?? 3))[0];
if (pick.enabled !== true) { console.log("disabled"); process.exit(0); }
const min = parse(process.env.MIN);
const have = parse(pick.version);
if (!min || !have) { console.log("badversion " + pick.version); process.exit(0); }
console.log(cmp(have, min) >= 0 ? "ok" : "old " + pick.version);
' 2>/dev/null) || verdict="unreadable"

case "$verdict" in
  ok) exit 0 ;;
  missing) deny "$plugin is not installed for this checkout" "$fix" ;;
  disabled) deny "$plugin is installed but disabled" "claude plugin enable $plugin, then start a new session" ;;
  old\ *) deny "$plugin ${verdict#old } is older than $min" "claude plugin update $plugin, then start a new session" ;;
  badversion\ *) deny "$plugin reports version '${verdict#badversion }', which is not x.y.z, or BOB_MIN_VERSION '$min' is not" "claude plugin update $plugin, then start a new session" ;;
  *) deny "the plugin list could not be read" "run claude plugin list --json and fix what it reports" ;;
esac
