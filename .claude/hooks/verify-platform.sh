#!/usr/bin/env bash
# Stop hook for implementer agents: refuse to finish while the platform's own gate is red.
# Usage: verify-platform.sh <backend|web|mobile>
# The agent may end with a message containing "BLOCKED:" to hand the story back with a reason.
platform="$1"
input=$(cat)
last=$(printf '%s' "$input" | jq -r '.last_assistant_message // ""')
if printf '%s' "$last" | grep -q 'BLOCKED:'; then exit 0; fi

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
log=$(mktemp)
case "$platform" in
  backend) (cd "$root/backend" && ./gradlew ktlintCheck test -q) >"$log" 2>&1 ;;
  web)     (cd "$root/web" && pnpm lint && pnpm typecheck && pnpm test:run) >"$log" 2>&1 ;;
  mobile)  (cd "$root/mobile" && dart format --set-exit-if-changed lib test >/dev/null && flutter analyze --fatal-infos && flutter test) >"$log" 2>&1 ;;
  *) echo "verify-platform: unknown platform '$platform'" >&2; exit 0 ;;
esac
status=$?
if [ $status -ne 0 ]; then
  echo "verify-platform: the $platform gate is red. Fix it before finishing, or end your message with 'BLOCKED: <reason>' to hand the story back. Last 40 lines:" >&2
  tail -40 "$log" >&2
  rm -f "$log"
  exit 2
fi
rm -f "$log"
exit 0
