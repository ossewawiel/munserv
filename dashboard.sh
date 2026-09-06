#!/usr/bin/env bash
# Launches the factory console (scripts/console/), waits for it to come up, opens it in the
# browser, tails its log, and stops the server and every service it started on Ctrl-C.
#
# Usage: ./dashboard.sh
# Env:   CONSOLE_PORT (default 3999)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${CONSOLE_PORT:-3999}"
LOG_FILE="$(mktemp -t factory-console.XXXXXX.log)"

PYTHON=""
for candidate in python3 python; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PYTHON="$candidate"
    break
  fi
done
if [[ -z "$PYTHON" ]]; then
  echo "dashboard.sh: no python3 (or python) found on PATH" >&2
  exit 1
fi

(cd "$DIR" && "$PYTHON" -m scripts.console --port "$PORT") > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

cleanup() {
  # The server's own SIGTERM/SIGINT handler stops every service process group it started; give it
  # a moment to do that before this script's shell exits.
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill -TERM "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -f "$LOG_FILE"
}
trap cleanup EXIT INT TERM

echo "Starting factory console on port $PORT (pid $SERVER_PID)..."
STATE_URL="http://localhost:$PORT/api/state"
for _ in $(seq 1 60); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "dashboard.sh: server exited before it came up; log follows:" >&2
    cat "$LOG_FILE" >&2
    exit 1
  fi
  if curl -fsS "$STATE_URL" -o /dev/null 2>/dev/null; then
    break
  fi
  sleep 0.5
done

if ! curl -fsS "$STATE_URL" -o /dev/null 2>/dev/null; then
  echo "dashboard.sh: server did not come up after 30s; log follows:" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

URL="http://localhost:$PORT/"
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "$URL" >/dev/null 2>&1 &
else
  echo "Open $URL in your browser."
fi

echo "factory console is up: $URL"
echo "Ctrl-C to stop the server and every service it started."
tail -n +1 -f "$LOG_FILE" &
TAIL_PID=$!
trap 'kill "$TAIL_PID" 2>/dev/null || true; cleanup' EXIT INT TERM

wait "$SERVER_PID"
