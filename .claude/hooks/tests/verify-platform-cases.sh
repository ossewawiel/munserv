#!/usr/bin/env bash
# Cases for verify-platform.sh. Builds a scratch repo with stub tools on PATH, so no docker,
# gradle, pnpm or flutter is needed. Exit 1 if any case fails.
set -u
hook="$(cd "$(dirname "$0")/.." && pwd)/verify-platform.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
bin="$work/bin"; repo="$work/repo"; runs="$work/runs"
mkdir -p "$bin" "$repo/backend" "$repo/web" "$repo/mobile"

stub() { printf '#!/usr/bin/env bash\n%s\n' "$2" >"$bin/$1"; chmod +x "$bin/$1"; }
stub docker '[ -z "${STUB_DOCKER_FAIL:-}" ]'
stub mise '[ -z "${STUB_MISE_FAIL:-}" ]'
stub flutter '[ -z "${STUB_FLUTTER_FAIL:-}" ]'
stub dart 'exit 0'
stub pnpm 'echo "pnpm $*" >>"$STUB_RUNS"; [ "$1" = install ] && { [ -z "${STUB_INSTALL_FAIL:-}" ] && mkdir -p node_modules; exit $?; }; exit 0'
printf '#!/usr/bin/env bash\necho gate >>"$STUB_RUNS"\nexit "${STUB_GATE_EXIT:-0}"\n' >"$repo/backend/gradlew"
chmod +x "$repo/backend/gradlew"

cd "$repo" || exit 1
git init -q -b master
git config user.email t@example.com; git config user.name t
printf 'node_modules/\n' >.gitignore
echo 1 >backend/a.txt
git add -A && git commit -q -m init
export PATH="$bin:$PATH" STUB_RUNS="$runs"

fails=0
# run <platform> <stop_hook_active> [last message]; sets $code and $err
run() {
  err=$(printf '{"stop_hook_active": %s, "last_assistant_message": "%s"}' "$2" "${3:-done}" | "$hook" "$1" 2>&1 >/dev/null)
  code=$?
}
expect() { # <name> <want exit> [stderr fragment]
  if [ "$code" = "$2" ] && { [ -z "${3:-}" ] || [[ "$err" == *"$3"* ]]; }; then echo "ok   $1"
  else echo "FAIL $1 (want=$2 got=$code stderr=${err:0:120})"; fails=$((fails + 1)); fi
}
gate_runs() { grep -c '^gate' "$runs" 2>/dev/null || echo 0; }
reset() { : >"$runs"; rm -f "$repo"/.git/verify-*; unset STUB_GATE_EXIT STUB_DOCKER_FAIL STUB_MISE_FAIL STUB_FLUTTER_FAIL STUB_INSTALL_FAIL; }

reset; STUB_DOCKER_FAIL=1 run backend false "stuck. BLOCKED: x"; expect "BLOCKED escape skips the probe" 0
reset; STUB_DOCKER_FAIL=1 run backend false;  expect "backend: docker down blocks" 2 "environment: docker info; end your message with BLOCKED: environment"
reset; STUB_FLUTTER_FAIL=1 run mobile false;  expect "mobile: flutter missing blocks" 2 "environment: flutter --version; end your message with BLOCKED: environment"
reset; STUB_MISE_FAIL=1 run web false;        expect "web: mise missing blocks" 2 "environment: mise; end your message with BLOCKED: environment"
reset; rm -rf web/node_modules; STUB_INSTALL_FAIL=1 run web false
expect "web: failed install blocks" 2 "environment: pnpm install --frozen-lockfile"
reset; rm -rf web/node_modules; run web false
expect "web: missing node_modules installs, then runs the gate" 0
grep -q 'pnpm install --frozen-lockfile' "$runs" && echo "ok   web: install used the frozen lockfile" || { echo "FAIL web: no frozen install"; fails=$((fails + 1)); }
reset; mkdir -p web/node_modules; run web false; grep -q '^pnpm install' "$runs" && { echo "FAIL web: reinstalled"; fails=$((fails + 1)); } || echo "ok   web: present node_modules skips install"

reset; run backend false; expect "green run passes" 0
run backend false; expect "green rerun on same tree passes" 0
[ "$(gate_runs)" = 1 ] && echo "ok   green rerun skipped the gate" || { echo "FAIL gate ran $(gate_runs) times"; fails=$((fails + 1)); }
echo 2 >backend/a.txt; run backend false; expect "unstaged change reruns the gate" 0
[ "$(gate_runs)" = 2 ] && echo "ok   changed tree ran the gate" || { echo "FAIL gate ran $(gate_runs) times"; fails=$((fails + 1)); }

reset; echo 3 >backend/a.txt; STUB_GATE_EXIT=1 run backend false; expect "red run blocks" 2 "gate is red"
STUB_GATE_EXIT=1 run backend false;  expect "red rerun with stop_hook_active=false still blocks" 2 "gate is red"
STUB_GATE_EXIT=1 run backend true;   expect "stop_hook_active on the same red tree lets it stop" 0 "letting the agent stop"
echo 4 >backend/a.txt; STUB_GATE_EXIT=1 run backend true; expect "stop_hook_active after a tree change reruns and blocks" 2 "gate is red"
echo 5 >backend/a.txt; run backend true; expect "fixed tree goes green" 0
[ ! -e "$repo/.git/verify-backend.red" ] && echo "ok   green clears the red marker" || { echo "FAIL red marker left"; fails=$((fails + 1)); }

echo "$fails failures"
[ "$fails" = 0 ]
