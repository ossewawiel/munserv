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
# Env:   CI_WORKFLOW (default CI)
#        CI_APPEAR_TIMEOUT (seconds to wait for runs to appear or a failing read to recover,
#        default 120)
#        RUN_TIMEOUT (seconds to wait for one run to finish, default 2400)
#        MERGE_TIMEOUT (seconds to wait for the merge after green CI, default 90)
#        GH_TIMEOUT (seconds one gh call may take, default 60)
#        A pull_request run with no jobs is skipped: GitHub fails it at once when the PR was opened
#        with GITHUB_TOKEN (the Auto PR workflow), and the push run covers the same commit.
#        GitHub can leave a run `in_progress` long after its last job ended (#299). Once the gate
#        job has finished and RUN_SETTLE_SECONDS have passed, the script judges that run from its
#        jobs.
#        A label on an open PR starts a new run and cancels the running one of that event. A
#        cancelled run with a newer run of the same event on this commit is not a failure.
# Exit:  0 when CI passed and the PR merged.
#        1 when a run failed, or the newest run of an event was cancelled.
#        2 on usage or when the watch cannot give a verdict: no run appeared, a run did not finish,
#        gh kept failing, or the head moved. None of these is a red run.
#        3 when CI passed but the PR did not merge (conflict, behind, no auto-merge, closed, held
#        by the infra review guard or the CI edit guard, unreadable, or still open after
#        MERGE_TIMEOUT).
# Every CI line goes to stdout, and the last line of stdout is the result.
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
GH_TIMEOUT="${GH_TIMEOUT:-60}"
# Needs every other job and runs always, so it is the last job of a run. A listed job set without it
# is not complete: GitHub lists a job only once its `needs` are met.
GATE_JOB="CI status"

GH_BIN="$(type -P gh)" || { echo "CI: not finished - gh is not installed"; exit 2; }

# gh has no time limit of its own, and a call that never returns would stop every limit below. The
# wait counters add the time each call took, so a slow gh cannot stretch a limit either.
gh() {
  timeout "$GH_TIMEOUT" "$GH_BIN" "$@"
}

# Prints "<head sha> <branch>". Retries until APPEAR_TIMEOUT, so a network blip cannot end the watch.
read_head() {
  local read_waited=0 started head
  while true; do
    started=$SECONDS
    if head=$(gh pr view "$PR" --json headRefOid,headRefName --jq '"\(.headRefOid) \(.headRefName)"') && [[ -n "$head" ]]; then
      echo "$head"
      return 0
    fi
    read_waited=$(( read_waited + POLL_SECONDS + SECONDS - started ))
    (( read_waited < APPEAR_TIMEOUT )) || return 1
    sleep "$POLL_SECONDS"
  done
}

if ! head_at_start="$(read_head)"; then
  echo "CI: not finished - cannot read PR $PR after ${APPEAR_TIMEOUT}s"
  exit 2
fi
read -r SHA BRANCH <<<"$head_at_start"

# Fails when gh fails, so a caller can tell "no runs" from "could not ask".
run_ids() {
  gh run list --branch "$BRANCH" --workflow "$WORKFLOW" --commit "$SHA" --json databaseId --jq '.[].databaseId'
}

# Waits for one run and sets event, job_count, conclusion and judged. Returns 1 at RUN_TIMEOUT. This
# polls instead of `gh run watch`, which has no time limit and can return before the run has a
# conclusion. A failed gh call counts as "not finished yet", so a network blip cannot end the watch.
wait_for_run() {
  local id="$1" run_waited=0 settled=0 started view status open gate bad
  judged=0
  while (( run_waited < RUN_TIMEOUT )); do
    started=$SECONDS
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
          judged=1
          return 0
        fi
      else
        settled=0
      fi
    fi
    run_waited=$(( run_waited + RUN_POLL_SECONDS + SECONDS - started ))
    sleep "$RUN_POLL_SECONDS"
  done
  return 1
}

# Prints the failed log tail of a run. `gh run view --log-failed` refuses a run that still says
# in_progress, so a run judged from its jobs reads the log of each failed job instead.
print_failed_log() {
  local id="$1" from_jobs="$2" job_id
  if (( from_jobs )); then
    for job_id in $(gh run view "$id" --json jobs --jq '.jobs[] | select(.conclusion != "success" and .conclusion != "skipped") | .databaseId' || true); do
      echo "--- job $job_id ---"
      gh api "repos/{owner}/{repo}/actions/jobs/$job_id/logs" 2>/dev/null | tail -n 40 || true
    done
  else
    gh run view "$id" --log-failed 2>/dev/null | tail -n 40 || true
  fi
}

# A push during the watch cancels this commit's runs, and nobody is merging this commit any more, so
# its verdict means nothing. A failed read leaves the verdict standing: the merge phase reads the PR
# again anyway.
end_if_head_moved() {
  local head_now
  if head_now="$(read_head)" && [[ "${head_now%% *}" != "$SHA" ]]; then
    echo "CI: not finished - head moved to ${head_now:0:7}; watch again"
    exit 2
  fi
}

end_red() {
  end_if_head_moved
  echo "CI: red - see the failed jobs above"
  exit 1
}

waited=0
started=$SECONDS
ids="$(run_ids)" || ids=""
while [[ -z "$ids" ]]; do
  waited=$(( waited + SECONDS - started ))
  if (( waited >= APPEAR_TIMEOUT )); then
    echo "CI: not finished - no $WORKFLOW run for ${SHA:0:7} after ${APPEAR_TIMEOUT}s"
    exit 2
  fi
  sleep "$POLL_SECONDS"
  waited=$(( waited + POLL_SECONDS ))
  started=$SECONDS
  ids="$(run_ids)" || ids=""
done

# The push run and the pull_request run do not appear together, so list again after each pass and
# watch any run not yet seen, until a pass finds none. Runs appeared above, so an empty listing here
# is a failed read like any other, not "no runs left": treating it as the end would pass a run
# nobody watched.
failed=0
seen=" "
cancelled=""
declare -A newest=()
list_waited=0
while true; do
  sleep "$POLL_SECONDS"
  started=$SECONDS
  if ! listed="$(run_ids)" || [[ -z "$listed" ]]; then
    list_waited=$(( list_waited + POLL_SECONDS + SECONDS - started ))
    if (( list_waited >= APPEAR_TIMEOUT )); then
      (( failed == 0 )) || end_red
      echo "CI: not finished - cannot list $WORKFLOW runs for ${SHA:0:7} after ${APPEAR_TIMEOUT}s"
      exit 2
    fi
    continue
  fi
  list_waited=0
  new_ids=""
  for id in $listed; do
    [[ "$seen" == *" $id "* ]] || new_ids+="$id "
  done
  [[ -n "$new_ids" ]] || break
  for id in $new_ids; do
    seen+="$id "
    if ! wait_for_run "$id"; then
      # A failure already seen is the result. `CI: not finished` would hide it from /factory.
      (( failed == 0 )) || end_red
      echo "CI: not finished - run $id is not done after ${RUN_TIMEOUT}s; check it with gh run view $id"
      exit 2
    fi
    if [[ "$event" == "pull_request" && "$job_count" -eq 0 && "$conclusion" != "success" ]]; then
      echo "--- run $id: pull_request run with no jobs ($conclusion), skipped; the push run covers this commit ---"
      continue
    fi
    if (( id > ${newest[$event]:-0} )); then newest[$event]="$id"; fi
    gh run view "$id" --json event,jobs --jq '.event as $e | .jobs[] | "\($e)\t\(.name)\t\(.conclusion)"' || true
    if [[ "$conclusion" == "cancelled" ]]; then
      cancelled+="$id:$event "
    elif [[ "$conclusion" != "success" ]]; then
      failed=1
      echo "--- run $id: $conclusion; failed log tail ---"
      print_failed_log "$id" "$judged"
    fi
  done
done

# Judged only now, because `gh run list` gives the newest run first and the runs arrive in any order.
for entry in $cancelled; do
  id="${entry%%:*}"
  event="${entry#*:}"
  if (( id < ${newest[$event]} )); then
    echo "--- run $id: cancelled; newer $event run ${newest[$event]} covers this commit ---"
  else
    failed=1
    echo "--- run $id: cancelled; failed log tail ---"
    print_failed_log "$id" 0
  fi
done

(( failed == 0 )) || end_red
end_if_head_moved
echo "CI: green (${SHA:0:7})"

# Merge phase. Auto-merge lands the squash a few seconds after green CI, so one look at the PR
# right now often still reads OPEN. Poll until MERGED, or until a state auto-merge cannot clear.
merge_waited=0
while true; do
  started=$SECONDS
  if ! pr_fields=$(gh pr view "$PR" --json state,mergeStateStatus,autoMergeRequest,statusCheckRollup \
    --jq 'def newest($name): [.statusCheckRollup[] | select(.name == $name)] | sort_by(.startedAt) | (last.conclusion // "") | if . == "" then "NONE" else . end;
      "\(.state) \(.mergeStateStatus) \(.autoMergeRequest != null) \(newest("CI edit guard")) \(newest("Infra review guard"))"') || [[ -z "$pr_fields" ]]; then
    if (( merge_waited >= MERGE_TIMEOUT )); then
      echo "CI: green, not merging - cannot read the PR after ${MERGE_TIMEOUT}s; watch again"
      exit 3
    fi
    merge_waited=$(( merge_waited + MERGE_POLL_SECONDS + SECONDS - started ))
    sleep "$MERGE_POLL_SECONDS"
    continue
  fi
  read -r state merge_state armed guard infra_guard <<<"$pr_fields"
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
  # A failed guard is a hold, not a red build. The reviewer goes first, so the owner reads a PR that
  # has already had its review.
  if [[ "$infra_guard" == "FAILURE" ]]; then
    echo "CI: green, not merging - held by infra review guard; dispatch the reviewer agent on PR $PR, and its APPROVE on this commit releases it"
    exit 3
  fi
  # No agent can clear this one (#294).
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
  merge_waited=$(( merge_waited + MERGE_POLL_SECONDS + SECONDS - started ))
  sleep "$MERGE_POLL_SECONDS"
done
