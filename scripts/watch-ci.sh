#!/usr/bin/env bash
# Watches the CI workflow runs for a PR's head commit until they finish, then prints one line per
# job and, for a red run, the failed log tail. `gh pr checks --watch` is not enough on its own:
# right after a push the new runs sit in `pending` with no jobs, so it sees only finished checks and
# exits green.
#
# Usage: scripts/watch-ci.sh <pr-number>
# Env:   CI_WORKFLOW (default CI), CI_APPEAR_TIMEOUT (seconds to wait for runs to appear, default 120)
#        A pull_request run with no jobs is skipped: GitHub fails it at once when the PR was opened
#        with GITHUB_TOKEN (the Auto PR workflow), and the push run covers the same commit.
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

# The push run and the pull_request run do not appear together, so list again after each pass and
# watch any run not yet seen, until a pass finds none.
failed=0
seen=" "
while true; do
  sleep "$POLL_SECONDS"
  new_ids=""
  for id in $(run_ids); do
    [[ "$seen" == *" $id "* ]] || new_ids+="$id "
  done
  [[ -n "$new_ids" ]] || break
  for id in $new_ids; do
    seen+="$id "
    gh run watch "$id" --interval 30 >/dev/null 2>&1 || true
    read -r event job_count conclusion < <(gh run view "$id" --json event,jobs,conclusion --jq '"\(.event) \(.jobs | length) \(.conclusion)"')
    if [[ "$event" == "pull_request" && "$job_count" -eq 0 && "$conclusion" != "success" ]]; then
      echo "--- run $id: pull_request run with no jobs ($conclusion), skipped; the push run covers this commit ---"
      continue
    fi
    gh run view "$id" --json event,jobs --jq '.event as $e | .jobs[] | "\($e)\t\(.name)\t\(.conclusion)"'
    if [[ "$conclusion" != "success" ]]; then
      failed=1
      echo "--- run $id: $conclusion; failed log tail ---"
      gh run view "$id" --log-failed 2>/dev/null | tail -n 40 || true
    fi
  done
done

if (( failed )); then
  echo "CI: red - see the failed jobs above"
  exit 1
fi
echo "CI: green (${SHA:0:7})"
