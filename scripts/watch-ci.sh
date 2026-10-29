#!/usr/bin/env bash
# Watches the CI workflow runs for a PR's head commit until they finish, then prints one line per
# job and, for a red run, the failed log tail. `gh pr checks --watch` is not enough on its own:
# right after a push the new runs sit in `pending` with no jobs, so it sees only finished checks and
# exits green.
#
# When CI is green the script keeps going: merging is automatic (auto-merge), so it polls the PR
# every MERGE_POLL_SECONDS for up to MERGE_TIMEOUT and ends on the real outcome, never on "armed".
# It is read-only: it never arms or runs a merge itself.
#
# Usage: scripts/watch-ci.sh <pr-number>
# Env:   CI_WORKFLOW (default CI), CI_APPEAR_TIMEOUT (seconds to wait for runs to appear, default 120)
#        MERGE_TIMEOUT (seconds to wait for the merge after green CI, default 90)
#        A pull_request run with no jobs is skipped: GitHub fails it at once when the PR was opened
#        with GITHUB_TOKEN (the Auto PR workflow), and the push run covers the same commit.
# Exit:  0 when CI passed and the PR merged, 1 when a run failed or was cancelled, 2 on usage or
#        timeout, 3 when CI passed but the PR did not merge (conflict, behind, no auto-merge, closed,
#        or still open after MERGE_TIMEOUT).
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 <pr-number>" >&2
  exit 2
fi
PR="$1"
WORKFLOW="${CI_WORKFLOW:-CI}"
APPEAR_TIMEOUT="${CI_APPEAR_TIMEOUT:-120}"
POLL_SECONDS=10
MERGE_TIMEOUT="${MERGE_TIMEOUT:-90}"
MERGE_POLL_SECONDS=5

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

# Merge phase. Auto-merge lands the squash a few seconds after green CI, so one look at the PR
# right now often still reads OPEN. Poll until MERGED, or until a state auto-merge cannot clear.
merge_waited=0
while true; do
  read -r state merge_state armed < <(gh pr view "$PR" --json state,mergeStateStatus,autoMergeRequest \
    --jq '"\(.state) \(.mergeStateStatus) \(.autoMergeRequest != null)"')
  case "$state" in
    MERGED)
      echo "CI: green, merged"
      exit 0 ;;
    CLOSED)
      echo "CI: green, but the PR is closed without merging"
      exit 3 ;;
  esac
  case "$merge_state" in
    DIRTY)
      echo "CI: green, not merging - conflicts with master; rebase onto origin/master and push"
      exit 3 ;;
    BEHIND)
      echo "CI: green, not merging - branch is behind master; rebase onto origin/master and push"
      exit 3 ;;
  esac
  if [[ "$armed" != "true" && $merge_waited -ge 15 ]]; then
    echo "CI: green, not merging - auto-merge is not armed (mergeStateStatus $merge_state); arm it with gh pr merge $PR --auto --squash"
    exit 3
  fi
  if (( merge_waited >= MERGE_TIMEOUT )); then
    echo "CI: green, still OPEN after ${MERGE_TIMEOUT}s (mergeStateStatus $merge_state, auto-merge armed: $armed)"
    exit 3
  fi
  sleep "$MERGE_POLL_SECONDS"
  merge_waited=$(( merge_waited + MERGE_POLL_SECONDS ))
done
