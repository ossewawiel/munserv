#!/usr/bin/env bash
# Watches the CI workflow runs for a PR's head commit until they finish, then prints one line per
# job and, for a red run, the failed log tail. `gh pr checks --watch` is not enough on its own:
# right after a push the new runs sit in `pending` with no jobs, so it sees only finished checks and
# exits green.
#
# Usage: scripts/watch-ci.sh <pr-number>
# Env:   CI_WORKFLOW (default CI), CI_APPEAR_TIMEOUT (seconds to wait for runs to appear, default 120)
# Exit:  0 when every run passed, 1 when one failed or was cancelled, 2 on usage or timeout.
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 <pr-number>" >&2
  exit 2
fi
PR="$1"
WORKFLOW="${CI_WORKFLOW:-CI}"
APPEAR_TIMEOUT="${CI_APPEAR_TIMEOUT:-120}"
POLL_SECONDS=10

read -r SHA BRANCH < <(gh pr view "$PR" --json headRefOid,headRefName --jq '"\(.headRefOid) \(.headRefName)"')

run_ids() {
  gh run list --branch "$BRANCH" --workflow "$WORKFLOW" --commit "$SHA" --json databaseId --jq '.[].databaseId'
}

waited=0
ids="$(run_ids)"
while [[ -z "$ids" ]]; do
  if (( waited >= APPEAR_TIMEOUT )); then
    echo "CI: red - no $WORKFLOW run for ${SHA:0:7} after ${APPEAR_TIMEOUT}s" >&2
    exit 2
  fi
  sleep "$POLL_SECONDS"
  waited=$(( waited + POLL_SECONDS ))
  ids="$(run_ids)"
done

failed=0
for id in $ids; do
  gh run watch "$id" --interval 30 >/dev/null 2>&1 || true
  conclusion="$(gh run view "$id" --json conclusion --jq .conclusion)"
  gh run view "$id" --json event,jobs --jq '.event as $e | .jobs[] | "\($e)\t\(.name)\t\(.conclusion)"'
  if [[ "$conclusion" != "success" ]]; then
    failed=1
    echo "--- run $id: $conclusion; failed log tail ---"
    gh run view "$id" --log-failed 2>/dev/null | tail -n 40 || true
  fi
done

if (( failed )); then
  echo "CI: red - see the failed jobs above"
  exit 1
fi
echo "CI: green (${SHA:0:7})"
