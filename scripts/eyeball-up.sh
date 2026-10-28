#!/usr/bin/env bash
# Sets a PR up for remote eyeball: starts the factory console when it is not running, then asks it
# to check the PR out, prepare it, start or restart only the services that need it, and prints the
# links, accounts and firewall command.
#
# Usage: scripts/eyeball-up.sh <pr-number>
# Env:   CONSOLE_PORT (default 3999), CONSOLE_UNIT (default munserv-console),
#        CONSOLE_START_TIMEOUT (seconds to wait for a started console, default 30)
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 <pr-number>" >&2
  exit 2
fi
PR="$1"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${CONSOLE_PORT:-3999}"
UNIT="${CONSOLE_UNIT:-munserv-console}"
START_TIMEOUT="${CONSOLE_START_TIMEOUT:-30}"
STATE_URL="http://localhost:$PORT/api/state"

console_up() {
  curl -fsS "$STATE_URL" -o /dev/null 2>/dev/null
}

start_console() {
  if systemctl --user cat "$UNIT.service" >/dev/null 2>&1; then
    systemctl --user start "$UNIT.service"
  else
    (cd "$DIR" && setsid nohup python3 -m scripts.console --remote --port "$PORT" \
      </dev/null >"${TMPDIR:-/tmp}/factory-console-$PORT.log" 2>&1 &)
  fi
}

if ! console_up; then
  start_console
  for _ in $(seq 1 "$START_TIMEOUT"); do
    console_up && break
    sleep 1
  done
  if ! console_up; then
    echo "eyeball-up.sh: the console did not come up on port $PORT within ${START_TIMEOUT}s" >&2
    exit 1
  fi
fi

cd "$DIR"
exec python3 -m scripts.console --port "$PORT" ensure "$PR"
