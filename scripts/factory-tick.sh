#!/usr/bin/env bash
# One unattended factory tick, run by the munserv-factory systemd user timer (or by hand).
#
# On every exit after the lock (skip, stop or run) the pinned "Waiting on you" issue is refreshed from
# `python3 -m scripts.console inbox --publish`; it comments, mentioning the owner, only when items arrived.
#
# Order: pause file -> lock -> hours window -> fast-forward master -> requirement rows synced from
# GitHub -> daily budget -> on RETRO_WEEKDAY,
# the day's first tick runs `/factory-retro` once (Opus, capped at RETRO_BUDGET_USD) -> clerk picks up
# to STORIES_PER_TICK dispatchable stories (Haiku, structured output) -> one `/factory story <n>` run
# per story (Sonnet), each capped at the smaller of RUN_BUDGET_USD and what is left of today's budget.
# Every Claude run appends its total_cost_usd to the ledger; today's sum is the budget gate.
#
# Settings live in one file, ~/.config/munserv-factory/tick.env (template:
# infrastructure/systemd/tick.env.example). Moving the tick to another host changes that file only.
#
# Usage: scripts/factory-tick.sh [--dry-run]
#        --dry-run asks the clerk and prints the picks, but dispatches nothing.
# Env:   MUNSERV_FACTORY_CONFIG (default ~/.config/munserv-factory),
#        MUNSERV_FACTORY_STATE (default ~/.local/state/munserv-factory)
# Exit:  0 on a tick that ran or skipped on purpose (pause, lock, hours, budget, nothing ready),
#        1 when master cannot be fast-forwarded or the clerk fails, 2 on usage.
set -euo pipefail

DRY_RUN=0
case "${1:-}" in
  "") ;;
  --dry-run) DRY_RUN=1 ;;
  *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

SCRIPT_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${MUNSERV_FACTORY_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/munserv-factory}"
STATE_DIR="${MUNSERV_FACTORY_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/munserv-factory}"
PAUSE_FILE="$CONFIG_DIR/pause"
LEDGER="$STATE_DIR/ticks.jsonl"

if [[ -e "$PAUSE_FILE" ]]; then
  echo "factory-tick: paused ($PAUSE_FILE exists)"
  exit 0
fi

if [[ -f "$CONFIG_DIR/tick.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$CONFIG_DIR/tick.env"
  set +a
fi
DAILY_BUDGET_USD="${DAILY_BUDGET_USD:-10}"
RUN_BUDGET_USD="${RUN_BUDGET_USD:-5}"
SELECT_BUDGET_USD="${SELECT_BUDGET_USD:-0.50}"
STORIES_PER_TICK="${STORIES_PER_TICK:-2}"
TICK_FIRST_HOUR="${TICK_FIRST_HOUR:-7}"
TICK_LAST_HOUR="${TICK_LAST_HOUR:-21}"
STORY_MAX_TURNS="${STORY_MAX_TURNS:-150}"
SELECT_MODEL="${SELECT_MODEL:-haiku}"
STORY_MODEL="${STORY_MODEL:-sonnet}"
REPO_DIR="${REPO_DIR:-$SCRIPT_REPO}"
# A tick that fires right after the laptop wakes can beat the network; retry the fetch for 2 minutes.
FETCH_ATTEMPTS="${FETCH_ATTEMPTS:-6}"
FETCH_WAIT_SECONDS="${FETCH_WAIT_SECONDS:-20}"
INBOX_UPDATE="${INBOX_UPDATE:-1}"
# Weekly retro: `date +%u` day (1 = Monday); empty turns it off.
RETRO_WEEKDAY="${RETRO_WEEKDAY-1}"
RETRO_BUDGET_USD="${RETRO_BUDGET_USD:-5}"
RETRO_MODEL="${RETRO_MODEL:-opus}"
RETRO_MAX_TURNS="${RETRO_MAX_TURNS:-120}"

mkdir -p "$STATE_DIR"
exec 9>"$STATE_DIR/tick.lock"
if ! flock -n 9; then
  echo "factory-tick: another tick holds $STATE_DIR/tick.lock"
  exit 0
fi

TICK_ID="$(date +%Y%m%dT%H%M%S)"

# record <kind> [jq --arg/--argjson pairs...] -- appends one ledger line; total_cost_usd defaults to 0.
record() {
  local kind="$1"
  shift
  jq -cn --arg ts "$(date -Iseconds)" --arg date "$(date +%F)" --arg tick "$TICK_ID" --arg kind "$kind" "$@" \
    '{ts: $ts, date: $date, tick: $tick, kind: $kind, total_cost_usd: 0} + $ARGS.named' >>"$LEDGER"
}

notify() {
  notify-send --app-name="MunServ factory" "MunServ factory" "$1" 2>/dev/null || true
}

# Today's spend: unreadable lines are skipped, so one bad line never zeroes the sum.
spent_today() {
  if [[ ! -f "$LEDGER" ]]; then
    echo 0
    return
  fi
  jq -nR --arg d "$(date +%F)" '[inputs | fromjson? | select(.date == $d) | (.total_cost_usd // 0)] | add // 0' "$LEDGER"
}

left_today() {
  jq -n --argjson daily "$DAILY_BUDGET_USD" --argjson spent "$(spent_today)" '($daily - $spent) * 100 | floor / 100'
}

# Comment on the pinned "Factory log" issue, creating and pinning it on first use. Never fails the tick.
log_to_issue() {
  local body="$1" number url
  number="$(gh issue list --state open --search 'in:title "Factory log"' --json number,title \
    --jq '[.[] | select(.title == "Factory log")][0].number // empty' 2>/dev/null || true)"
  if [[ -z "$number" ]]; then
    url="$(gh issue create --title "Factory log" \
      --body "One comment per factory tick that dispatched work or failed. Written by \`scripts/factory-tick.sh\`." 2>/dev/null || true)"
    number="${url##*/}"
    [[ "$number" =~ ^[0-9]+$ ]] || return 0
    gh issue pin "$number" >/dev/null 2>&1 || true
  fi
  gh issue comment "$number" --body "$body" >/dev/null 2>&1 || true
}

stop() {
  echo "factory-tick: $1" >&2
  record stop --arg reason "$1"
  notify "Tick stopped: $1"
  log_to_issue "**Tick $TICK_ID stopped:** $1"
  exit 1
}

# Refresh the pinned "Waiting on you" issue. Never fails the tick and never changes its exit code.
update_inbox() {
  ((INBOX_UPDATE)) || return 0
  [[ -f "$REPO_DIR/scripts/console/inbox.py" ]] || return 0
  local result
  if result="$(cd "$REPO_DIR" && python3 -m scripts.console inbox --publish 2>&1)"; then
    echo "factory-tick: inbox: $result"
  else
    echo "factory-tick: inbox update failed: $(tail -n 1 <<<"$result")" >&2
  fi
  return 0
}
trap update_inbox EXIT

hour="$(date +%-H)"
if ((hour < TICK_FIRST_HOUR || hour > TICK_LAST_HOUR)); then
  echo "factory-tick: $hour:00 is outside $TICK_FIRST_HOUR:00-$TICK_LAST_HOUR:00"
  record skip --arg reason "outside hours"
  exit 0
fi

cd "$REPO_DIR"
branch="$(git symbolic-ref --short -q HEAD || true)"
[[ "$branch" == master ]] || stop "$REPO_DIR is on '${branch:-detached HEAD}', not master"
git diff --quiet && git diff --cached --quiet || stop "$REPO_DIR has uncommitted changes"
fetched=0
for ((attempt = 1; attempt <= FETCH_ATTEMPTS; attempt++)); do
  if git fetch -q origin; then
    fetched=1
    break
  fi
  ((attempt < FETCH_ATTEMPTS)) && sleep "$FETCH_WAIT_SECONDS"
done
((fetched)) || stop "git fetch failed after $FETCH_ATTEMPTS attempts"
git merge -q --ff-only origin/master || stop "master cannot fast-forward to origin/master"

# Bring specs/requirements back in step with GitHub from a throwaway worktree: closing an issue drifts
# a row, and CI checks only the rows a PR changes. auto-pr.yml opens and merges the branch. Costs no Claude.
sync_requirements() {
  [[ -f scripts/render-requirements.py ]] || return 0
  python3 scripts/render-requirements.py --check >/dev/null 2>&1 && return 0
  local open branch="chore/sync-requirements-$TICK_ID" dir=".claude/worktrees/requirements-$TICK_ID" rc=0
  open="$(gh pr list --state open --json headRefName \
    --jq '[.[] | select(.headRefName | startswith("chore/sync-requirements-"))] | length' 2>/dev/null || true)"
  [[ "${open:-0}" == 0 ]] || return 0
  git worktree add -q "$dir" -b "$branch" origin/master || return 1
  (cd "$dir" && python3 scripts/render-requirements.py >/dev/null && git add specs/requirements \
    && git commit -q -m "chore(specs): sync requirement status from GitHub" && git push -q origin "$branch") || rc=$?
  git worktree remove --force "$dir" || rc=1
  git branch -qD "$branch" || rc=1
  ((rc == 0)) && record requirements_sync --arg branch "$branch"
  return "$rc"
}
if ((!DRY_RUN)); then
  sync_requirements || echo "factory-tick: requirements sync failed; the next tick retries" >&2
fi

left="$(left_today)"
if jq -en "$left <= 0" >/dev/null; then
  echo "factory-tick: daily budget of \$$DAILY_BUDGET_USD reached"
  record skip --arg reason "daily budget reached"
  exit 0
fi

# Weekly retro, once per RETRO_WEEKDAY: any retro line in today's ledger (run, failed or capped) means
# it was tried, and a last-retro of today means someone ran it by hand. A failed retro never stops the tick.
retro_tried_today() {
  [[ "$(cat "$REPO_DIR/specs/metrics/last-retro" 2>/dev/null)" == "$(date +%F)" ]] && return 0
  [[ -f "$LEDGER" ]] && jq -enR --arg d "$(date +%F)" \
    'first(inputs | fromjson? | select(.date == $d and .kind == "retro")) // false' "$LEDGER" >/dev/null
}
if [[ -n "$RETRO_WEEKDAY" && "$(date +%u)" == "$RETRO_WEEKDAY" ]] && ! retro_tried_today; then
  if ((DRY_RUN)); then
    echo "factory-tick: dry run, the weekly retro is due but not run"
  else
    retro_budget="$(jq -n --argjson a "$RETRO_BUDGET_USD" --argjson b "$left" '[$a, $b] | min')"
    echo "factory-tick: /factory-retro (budget \$$retro_budget)"
    mkdir -p "$STATE_DIR/runs"
    rc=0
    out="$(OTEL_RESOURCE_ATTRIBUTES="story.id=retro" claude -p "/factory-retro" --model "$RETRO_MODEL" \
      --max-turns "$RETRO_MAX_TURNS" --output-format json --max-budget-usd "$retro_budget" \
      --permission-mode acceptEdits </dev/null)" || rc=$?
    printf '%s\n' "$out" >"$STATE_DIR/runs/$TICK_ID-retro.json"
    cost="$(jq -r '.total_cost_usd // 0' <<<"$out" 2>/dev/null || echo 0)"
    subtype="$(jq -r '.subtype // "unknown"' <<<"$out" 2>/dev/null || echo no_json)"
    summary="$(jq -r '.result // "" | split("\n") | map(select(test("^(CI:|https://github.com/.*/pull/)"))) | join(" / ")' \
      <<<"$out" 2>/dev/null | head -c 300 || true)"
    record retro --argjson exit "$rc" --argjson total_cost_usd "$cost" --arg subtype "$subtype" --arg summary "$summary"
    log_to_issue "**Tick $TICK_ID retro** - $subtype, \$$cost: ${summary:-no PR line in the report}"
  fi
  left="$(left_today)"
  if jq -en "$left <= 0" >/dev/null; then
    echo "factory-tick: daily budget of \$$DAILY_BUDGET_USD reached after the retro"
    exit 0
  fi
fi

SCHEMA="$(jq -cn --argjson max "$STORIES_PER_TICK" '{
  type: "object",
  properties: {
    stories: {type: "array", items: {type: "integer"}, maxItems: $max},
    reason: {type: "string"}
  },
  required: ["stories", "reason"],
  additionalProperties: false
}')"
SELECT_PROMPT="Pick up to $STORIES_PER_TICK story issues the factory can implement now, unattended. \
Use the selection rules of \`run\` step 2 in .claude/skills/factory/SKILL.md, with these limits: \
the issue is open and labelled status:ready; it has a handoff specs/features/*/<issue>-*-<platform>.md \
with status: pending; every depends_on issue is closed; its touches folders do not overlap a story \
labelled status:in-progress; it has no open PR; a handoff with ui: true has design_approved: true. \
Skip a story without a handoff and a ui story without approval: both wait on a person. \
Order backend before web before mobile, then by priority label, then oldest issue first. \
Return the issue numbers in stories (an empty list when nothing qualifies) and one line in reason."

select_budget="$(jq -n --argjson a "$SELECT_BUDGET_USD" --argjson b "$left" '[$a, $b] | min')"
# Not `--agent clerk`: the agent's tool list leaves out the structured-output tool, so the schema is
# ignored and the answer comes back as prose. The clerk's body and tool limits are passed instead.
CLERK_PROMPT="$(awk 'n >= 2; /^---$/ { n++ }' "$REPO_DIR/.claude/agents/clerk.md")"
select_rc=0
select_out="$(claude -p "$SELECT_PROMPT" --model "$SELECT_MODEL" --output-format json --json-schema "$SCHEMA" \
  --append-system-prompt "$CLERK_PROMPT" --allowedTools Read Grep Glob 'Bash(gh *)' \
  --disallowedTools Edit Write Agent WebFetch WebSearch \
  --max-budget-usd "$select_budget" --no-session-persistence </dev/null)" || select_rc=$?
select_cost="$(jq -r '.total_cost_usd // 0' <<<"$select_out" 2>/dev/null || echo 0)"
picks="$(jq -c '[.structured_output.stories // [] | .[] | select(type == "number")] | .[:'"$STORIES_PER_TICK"']' <<<"$select_out" 2>/dev/null || echo '[]')"
reason="$(jq -r '.structured_output.reason // .result // ""' <<<"$select_out" 2>/dev/null | head -c 300 || true)"
record select --argjson total_cost_usd "$select_cost" --argjson stories "$picks" --arg reason "$reason" --argjson exit "$select_rc"
((select_rc == 0)) || stop "clerk selection failed (exit $select_rc): $reason"

if [[ "$picks" == "[]" ]]; then
  echo "factory-tick: nothing to dispatch - $reason"
  exit 0
fi
echo "factory-tick: picked $picks - $reason"
if ((DRY_RUN)); then
  echo "factory-tick: dry run, dispatching nothing"
  exit 0
fi

# The run's final report goes into the Factory log comment, because commands it hands to a person
# reach nobody otherwise; the raw result is kept under runs/ for `claude --resume <session_id>` triage.
mkdir -p "$STATE_DIR/runs"

# subagent_denials <session_id> -- prints a JSON array of the denials in the run's subagent transcripts.
# A background subagent's denials never reach the result's permission_denials; a foreground one's reach
# both, so the caller removes duplicates by tool_use_id. A transcript marks a denial with toolDenialKind.
subagent_denials() {
  local files=("${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/projects/*/"$1"/subagents/*.jsonl)
  [[ -e "${files[0]}" ]] || { echo '[]'; return 0; }
  jq -cnR '[inputs | fromjson? | select(.message?.content? | type == "array")] as $rows
    | ($rows | map(.message.content[] | select(.type == "tool_use")) | INDEX(.id)) as $uses
    | [$rows[] | select(.toolDenialKind) | .message.content[] | select(.type == "tool_result")
       | $uses[.tool_use_id] // empty | {tool_use_id: .id, tool_name: .name, tool_input: .input}]' "${files[@]}" \
    || echo '[]'
}

lines=()
reports=""
for id in $(jq -r '.[]' <<<"$picks"); do
  left="$(left_today)"
  if jq -en "$left <= 0" >/dev/null; then
    lines+=("#$id not dispatched: daily budget of \$$DAILY_BUDGET_USD reached")
    record skip --arg reason "daily budget reached" --argjson story "$id"
    break
  fi
  run_budget="$(jq -n --argjson a "$RUN_BUDGET_USD" --argjson b "$left" '[$a, $b] | min')"
  echo "factory-tick: /factory story $id (budget \$$run_budget)"
  rc=0
  # acceptEdits lets implementers edit their worktrees, except under .claude/. Shell commands outside the
  # allow list are denied, never prompted for and never bypassed.
  out="$(OTEL_RESOURCE_ATTRIBUTES="story.id=$id" claude -p "/factory story $id" --model "$STORY_MODEL" \
    --max-turns "$STORY_MAX_TURNS" --output-format json --max-budget-usd "$run_budget" \
    --permission-mode acceptEdits </dev/null)" || rc=$?
  printf '%s\n' "$out" >"$STATE_DIR/runs/$TICK_ID-$id.json"
  if jq -e 'type == "object"' <<<"$out" >/dev/null 2>&1; then
    cost="$(jq -r '.total_cost_usd // 0' <<<"$out")"
    subtype="$(jq -r '.subtype // "unknown"' <<<"$out")"
    # The report's CI and Plan lines, else its last line that is not a code fence.
    summary="$(jq -r '.result // "" | split("\n") | map(select(length > 0 and (startswith("```") | not))) as $l
      | ([$l[] | select(test("^(CI|Plan):"))] | join(" / ")) as $status
      | if $status != "" then $status else ($l | last // "") end' <<<"$out" | head -c 300)"
    denied="$({ printf '%s\n' "$out"; subagent_denials "$(jq -r '.session_id // ""' <<<"$out")"; } \
      | jq -cs '[(.[0].permission_denials // []) + .[1] | unique_by(.tool_use_id)[] | "\(.tool_name): \(.tool_input.command // .tool_input | tostring | .[0:120])"]')"
    record story --argjson story "$id" --argjson exit "$rc" --argjson total_cost_usd "$cost" \
      --arg subtype "$subtype" --argjson is_error "$(jq '.is_error // false' <<<"$out")" \
      --argjson num_turns "$(jq '.num_turns // 0' <<<"$out")" \
      --argjson duration_ms "$(jq '.duration_ms // 0' <<<"$out")" \
      --arg session_id "$(jq -r '.session_id // ""' <<<"$out")" \
      --argjson permission_denials "$denied" \
      --arg summary "$summary"
    reports+=$'\n\n'"<details><summary>#$id report</summary>"$'\n\n'"$(jq -r '.result // "" | .[0:20000]' <<<"$out")"
    if [[ "$denied" != "[]" ]]; then
      reports+=$'\n\n'"Denied: "$'\n'"$(jq -r '.[] | "- `" + gsub("`"; "\u2032") + "`"' <<<"$denied")"
    fi
    reports+=$'\n\n'"</details>"
  else
    cost=0
    subtype="no_json"
    summary="$(tail -c 300 <<<"$out")"
    record story --argjson story "$id" --argjson exit "$rc" --arg subtype "$subtype" --arg summary "$summary"
  fi
  lines+=("#$id $subtype, \$$cost: $summary")
done

spent="$(spent_today)"
notify "Tick $TICK_ID: ${#lines[@]} run(s), \$$spent of \$$DAILY_BUDGET_USD spent today"
body="**Tick $TICK_ID** - \$$spent of \$$DAILY_BUDGET_USD spent today"
for line in "${lines[@]}"; do
  body+=$'\n'"- $line"
done
log_to_issue "$body$reports"
printf '%s\n' "${lines[@]}"
