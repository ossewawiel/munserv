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
#        RUN_TIMEOUT (seconds to wait for one run to finish, default 2400)
#        MERGE_TIMEOUT (seconds to wait for the merge after green CI, default 90)
#        A pull_request run with no jobs is skipped: GitHub fails it at once when the PR was opened
#        with GITHUB_TOKEN (the Auto PR workflow), and the push run covers the same commit.
#        GitHub can leave a run `in_progress` long after its last job ended (#299). Once the gate job
#        has finished and RUN_SETTLE_SECONDS have passed, the script judges that run from its jobs.
# Exit:  0 when CI passed and the PR merged, 1 when a run failed or was cancelled, 2 on usage or
#        timeout (a run that has not finished is not a red run), 3 when CI passed but the PR did not merge (conflict, behind, no auto-merge, closed,
#        held by the CI edit guard, or still open after MERGE_TIMEOUT).
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
RUN_TIMEOUT="${RUN_TIMEOUT:-2400}"
RUN_POLL_SECONDS=30
RUN_SETTLE_SECONDS=120
# Needs every other job and runs always, so it is the last job of a run. A listed job set without it
# is not complete: GitHub lists a job only once its `needs` are met.
GATE_JOB="CI status"

read -r SHA BRANCH < <(gh pr view "$PR" --json headRefOid,headRefName --jq '"\(.headRefOid) \(.headRefName)"')

run_ids() {
  gh run list --branch "$BRANCH" --workflow "$WORKFLOW" --commit "$SHA" --json databaseId --jq '.[].databaseId' || true
}

# Waits for one run and sets event, job_count and conclusion. Returns 1 at RUN_TIMEOUT. This polls
# instead of `gh run watch`, which has no time limit and can return before the run has a conclusion.
# A failed gh call counts as "not finished yet", so a network blip cannot end the watch.
wait_for_run() {
  local id="$1" run_waited=0 settled=0 view status open gate bad
  while (( run_waited < RUN_TIMEOUT )); do
    if view=$(gh run view "$id" --json event,status,conclusion,jobs --jq '[.event, .status, (.conclusion // "" | if . == "" then "none" else . end), (.jobs | length),
      ([.jobs[] | select(.status != "completed")] | length),
      ([.jobs[] | select(.name == "'"$GATE_JOB"'")] | length),
      ([.jobs[] | select(.conclusion != "success" and .conclusion != "skipped")] | length)] | map(tostring) | join(" ")' 2>/dev/null); then
      read -r event status conclusion job_count open gate bad <<<"$view"
      if [[ "$status" == "completed" && "$conclusion" != "none" ]]; then
        return 0
      fi
      if (( open == 0 && gate > 0 )); then
        settled=$(( settled + RUN_POLL_SECONDS ))
        if (( settled > RUN_SETTLE_SECONDS )); then
          echo "--- run $id: GitHub still says $status, but its jobs finished $RUN_SETTLE_SECONDS seconds ago; judging it from the jobs ---"
          if (( bad > 0 )); then conclusion="failure"; else conclusion="success"; fi
          return 0
        fi
      else
        settled=0
      fi
    fi
    sleep "$RUN_POLL_SECONDS"
    run_waited=$(( run_waited + RUN_POLL_SECONDS ))
  done
  return 1
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
    if ! wait_for_run "$id"; then
      echo "CI: not finished - run $id is not done after ${RUN_TIMEOUT}s; check it with gh run view $id"
      exit 2
    fi
    if [[ "$event" == "pull_request" && "$job_count" -eq 0 && "$conclusion" != "success" ]]; then
      echo "--- run $id: pull_request run with no jobs ($conclusion), skipped; the push run covers this commit ---"
      continue
    fi
    gh run view "$id" --json event,jobs --jq '.event as $e | .jobs[] | "\($e)\t\(.name)\t\(.conclusion)"' || true
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
  read -r state merge_state armed guard < <(gh pr view "$PR" --json state,mergeStateStatus,autoMergeRequest,statusCheckRollup \
    --jq '"\(.state) \(.mergeStateStatus) \(.autoMergeRequest != null) \([.statusCheckRollup[] | select(.name == "CI edit guard") | .conclusion] | last // "NONE")"')
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
  # A failed guard is a hold for a person, not a red build: no agent can clear it (#294).
  if [[ "$guard" == "FAILURE" ]]; then
    echo "CI: green, not merging - held by CI edit guard; the owner reads the diff, then runs gh pr edit $PR --add-label ci-edit-approved"
    exit 3
  fi
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
