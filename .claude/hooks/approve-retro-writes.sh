#!/usr/bin/env bash
# PreToolUse approval for Write and Edit: lets the unattended weekly retro (.claude/skills/factory-retro)
# write the three protected folders it owns inside its own worktree. Claude Code refuses writes under a
# nested .claude/ in acceptEdits mode, and an allow rule does not lift that.
# Approves only <project>/.claude/worktrees/retro-YYYY-MM-DD/.claude/{metrics,skills,agents}/<file>.
# Every other path gets no decision (exit 0, no output), so the normal permission rules apply.
input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
root="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | jq -r '.cwd // ""')}"

case "$path" in
  */../* | */./* | *'/..' ) exit 0 ;;
esac
[[ "$path" == /* ]] || path="$root/$path"
if [[ -n "$root" && "$path" =~ ^"$root"/\.claude/worktrees/retro-[0-9]{4}-[0-9]{2}-[0-9]{2}/\.claude/(metrics|skills|agents)/[^[:space:]]+$ ]]; then
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow",
    permissionDecisionReason: "factory retro writes its own worktree (approve-retro-writes.sh)"}}'
fi
exit 0
