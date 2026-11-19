#!/usr/bin/env bash
# Runs one of the repo's test scripts in a throwaway Linux container, so a checkout without Linux
# (the Windows laptop) can run the tests CI runs: test-factory-tick.py needs flock, jq and python3.
#
# The working tree goes in as a tar stream on stdin: tracked files plus untracked files git does not
# ignore, uncommitted edits included. node_modules and build output stay out, because .gitignore
# lists them. Nothing is mounted, so the container cannot write to the checkout. Inside, the tree is
# committed to a fresh git repo, so a test that reads HEAD sees the working tree.
#
# The image is python:3.12-slim, the CI test job's Python, plus jq, git, util-linux (flock) and PyYAML.
# The first run downloads the image and Debian packages; expect about a minute.
#
# Usage: scripts/test-in-container.sh <test script> [args...]
#   scripts/test-in-container.sh scripts/test-factory-tick.py
#   TEST_PIP="textual==8.2.8" scripts/test-in-container.sh scripts/test-tui.py
# Env:   TEST_IMAGE (default python:3.12-slim)
#        TEST_APT   extra Debian packages, space-separated (TEST_APT=nodejs puts a real node on PATH)
#        TEST_PIP   extra pip packages, space-separated (test-tui.py needs textual==8.2.8, as in ci.yml)
# Exit:  the test's exit code; 2 when the arguments are wrong or docker is missing or not running.
set -euo pipefail

usage() { echo "usage: scripts/test-in-container.sh <test script (.py or .sh)> [args...]" >&2; exit 2; }
[[ $# -ge 1 ]] || usage
script="$1"
shift

root="$(git rev-parse --show-toplevel)"
cd "$root"
[[ -f "$script" ]] || { echo "test-in-container: no file $script (paths are relative to the repo root)" >&2; exit 2; }
case "$script" in
  *.py) runner=python3 ;;
  *.sh) runner=bash ;;
  *) usage ;;
esac

command -v docker >/dev/null 2>&1 || { echo "test-in-container: docker is not on PATH" >&2; exit 2; }
docker info >/dev/null 2>&1 || { echo "test-in-container: docker is not running (docker info failed)" >&2; exit 2; }

# Windows does not keep the executable bit, so the container restores it from git's index.
exec_files="$(git ls-files -s | awk '$1 == "100755" { sub(/^[^\t]*\t/, ""); print }')"

# shellcheck disable=SC2016 # expanded inside the container, not here
inner='
set -euo pipefail
mkdir /w && cd /w && tar -xf -
while IFS= read -r f; do [[ -z "$f" || ! -e "$f" ]] || chmod +x "$f"; done <<< "$EXEC_FILES"
apt-get update -qq >/dev/null
# shellcheck disable=SC2086 # word splitting is the point
apt-get install -y -qq --no-install-recommends jq git util-linux $TEST_APT >/dev/null
# shellcheck disable=SC2086
pip install --quiet --disable-pip-version-check --root-user-action=ignore pyyaml $TEST_PIP
git init -q -b master
git add -A
git -c user.name=test-in-container -c user.email=test-in-container@localhost commit -q -m "working tree snapshot"
echo "--- $RUNNER $* (in ${TEST_IMAGE})"
exec "$RUNNER" "$@"
'

# Tracked files deleted in the working tree are still listed; --ignore-failed-read skips them.
# MSYS_NO_PATHCONV stops Git Bash rewriting /w and /dev/null into Windows paths.
git ls-files -z --cached --others --exclude-standard \
  | tar --null --ignore-failed-read -T - -cf - 2>/dev/null \
  | MSYS_NO_PATHCONV=1 docker run --rm -i \
      -e EXEC_FILES="$exec_files" -e RUNNER="$runner" -e DEBIAN_FRONTEND=noninteractive \
      -e TEST_APT="${TEST_APT:-}" -e TEST_PIP="${TEST_PIP:-}" -e TEST_IMAGE="${TEST_IMAGE:-python:3.12-slim}" \
      "${TEST_IMAGE:-python:3.12-slim}" bash -c "$inner" bash "$script" "$@"
