#!/usr/bin/env bash
# Opens the MunServ operator TUI (scripts/tui/) in this terminal; made for an SSH session.
# Starts the factory console first when it is not running (the systemd user unit when installed,
# otherwise a detached process), then runs the TUI through uv with the pinned Textual version, so
# nothing is installed globally.
#
# Usage: ./tui.sh
# Env:   CONSOLE_PORT (default 3999), CONSOLE_UNIT (default munserv-console),
#        CONSOLE_START_TIMEOUT (seconds to wait for a started console, default 30)
set -euo pipefail

TEXTUAL_VERSION="8.2.8"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${CONSOLE_PORT:-3999}"
UNIT="${CONSOLE_UNIT:-munserv-console}"
START_TIMEOUT="${CONSOLE_START_TIMEOUT:-30}"
STATE_URL="http://localhost:$PORT/api/state"

console_up() {
  curl -fsS "$STATE_URL" -o /dev/null 2>/dev/null
}

if ! console_up; then
  echo "Starting the factory console on port $PORT..."
  if systemctl --user cat "$UNIT.service" >/dev/null 2>&1; then
    systemctl --user start "$UNIT.service"
  else
    (cd "$DIR" && setsid nohup python3 -m scripts.console --remote --port "$PORT" \
      </dev/null >"${TMPDIR:-/tmp}/factory-console-$PORT.log" 2>&1 &)
  fi
  for _ in $(seq 1 "$START_TIMEOUT"); do
    console_up && break
    sleep 1
  done
  if ! console_up; then
    echo "tui.sh: the console did not come up on port $PORT within ${START_TIMEOUT}s" >&2
    exit 1
  fi
fi

cd "$DIR"
if command -v uv >/dev/null 2>&1; then
  exec uv run --no-project --quiet --with "textual==$TEXTUAL_VERSION" python -m scripts.tui --console "http://localhost:$PORT"
fi
if python3 -c "import textual" 2>/dev/null; then
  exec python3 -m scripts.tui --console "http://localhost:$PORT"
fi
echo "tui.sh: needs uv (https://docs.astral.sh/uv/) or python3 with textual==$TEXTUAL_VERSION installed" >&2
exit 1
