#!/usr/bin/env bash
# Stop hook for implementer agents: refuse to finish while the platform's own gate is red.
# Usage: verify-platform.sh <backend|web|mobile>
# The agent may end with a message containing "BLOCKED:" to hand the story back with a reason.
# Order: BLOCKED escape, environment probe, green cache, loop breaker, gate.
platform="$1"
input=$(cat)
last=$(printf '%s' "$input" | jq -r '.last_assistant_message // ""')
if printf '%s' "$last" | grep -q 'BLOCKED:'; then exit 0; fi

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

block_environment() {
  echo "verify-platform: environment: $1; end your message with BLOCKED: environment" >&2
  exit 2
}

case "$platform" in
  backend)
    docker info >/dev/null 2>&1 || block_environment "docker info"
    ;;
  web)
    mise --version >/dev/null 2>&1 || block_environment "mise"
    if [ ! -d "$root/web/node_modules" ]; then
      (cd "$root/web" && pnpm install --frozen-lockfile) >&2 || block_environment "pnpm install --frozen-lockfile"
    fi
    ;;
  mobile)
    flutter --version >/dev/null 2>&1 || block_environment "flutter --version"
    ;;
  *) echo "verify-platform: unknown platform '$platform'" >&2; exit 0 ;;
esac

# Hash the working tree (staged, unstaged and untracked, minus ignored) through a scratch
# index, so the real index is untouched. The marker files live in the git dir, which is
# per worktree.
tree_hash() {
  local scratch
  scratch=$(mktemp)
  cp "$(git -C "$root" rev-parse --path-format=absolute --git-path index)" "$scratch" 2>/dev/null
  GIT_INDEX_FILE="$scratch" git -C "$root" add -A >/dev/null 2>&1 \
    && GIT_INDEX_FILE="$scratch" git -C "$root" write-tree 2>/dev/null
  rm -f "$scratch"
}
marker() { git -C "$root" rev-parse --path-format=absolute --git-path "verify-$platform.$1" 2>/dev/null; }

hash=$(tree_hash)
ok_file=$(marker ok)
red_file=$(marker red)
if [ -n "$hash" ] && [ -n "$ok_file" ]; then
  [ "$(cat "$ok_file" 2>/dev/null)" = "$hash" ] && exit 0
  active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
  if [ "$active" = "true" ] && [ "$(cat "$red_file" 2>/dev/null)" = "$hash" ]; then
    echo "verify-platform: the $platform gate is still red on the same tree as the last red run; letting the agent stop." >&2
    exit 0
  fi
fi

log=$(mktemp)
case "$platform" in
  backend) (cd "$root/backend" && ./gradlew ktlintCheck test -q) >"$log" 2>&1 ;;
  web)     (cd "$root/web" && pnpm lint && pnpm typecheck && pnpm test:run) >"$log" 2>&1 ;;
  mobile)  (cd "$root/mobile" && dart format --set-exit-if-changed lib test >/dev/null && flutter analyze --fatal-infos && flutter test) >"$log" 2>&1 ;;
esac
status=$?
if [ $status -ne 0 ]; then
  [ -n "$hash" ] && [ -n "$red_file" ] && printf '%s' "$hash" >"$red_file"
  echo "verify-platform: the $platform gate is red. Fix it before finishing, or end your message with 'BLOCKED: <reason>' to hand the story back. Last 40 lines:" >&2
  tail -40 "$log" >&2
  rm -f "$log"
  exit 2
fi
rm -f "$log"
if [ -n "$hash" ] && [ -n "$ok_file" ]; then
  printf '%s' "$hash" >"$ok_file"
  rm -f "$red_file"
fi
exit 0
