#!/usr/bin/env bash
# PreToolUse guard for Bash: refuse the git operations no agent may run.
# Only real git invocations are inspected: heredoc bodies and quoted strings (commit
# messages, PR bodies, test strings) are removed first, then the command is split on
# ; & | and newlines and only segments that start with `git` are checked.
# Exit 2 blocks the call and returns the message to the model.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

deny() { echo "guard-git: $1" >&2; exit 2; }

stripped=$(printf '%s\n' "$cmd" \
  | awk 'BEGIN{skip=0}
         { if (skip) { if ($0 ~ ("^[ \t]*" tag "[ \t]*$")) skip=0; next }
           if (match($0, /<<-?[\047"]?[A-Za-z_][A-Za-z0-9_]*/)) {
             tag=substr($0, RSTART, RLENGTH); sub(/^<<-?[\047"]?/, "", tag); print; skip=1; next }
           print }' \
  | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
# GUARD_GIT_BRANCH lets the test runner pin the branch context (CI checks out master).
branch="${GUARD_GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"

check() {
  local g="$1"
  case "$g" in
    *"git push"*)
      if printf '%s' "$g" | grep -Eq -- '(^|[[:space:]])(--force|-f)([[:space:]]|$)' && ! printf '%s' "$g" | grep -q -- '--force-with-lease'; then
        deny "force push is not allowed; use --force-with-lease on a feature branch only"
      fi
      if printf '%s' "$g" | grep -Eq '(^|[[:space:]]|:)master([[:space:]]|$)'; then deny "pushing to master is not allowed; open a pull request"; fi
      if [ "$branch" = "master" ]; then deny "you are on master; create a branch before pushing"; fi
      if printf '%s' "$g" | grep -Eq -- '--delete|(^|[[:space:]])-d([[:space:]]|$)'; then deny "deleting remote branches is the user's job"; fi
      ;;
  esac
  if printf '%s' "$g" | grep -Eq 'git (reset --hard|clean -[a-zA-Z]*f|branch -D|filter-repo|filter-branch)'; then
    deny "destructive git operation blocked; ask the user"
  fi
  if printf '%s' "$g" | grep -Eq 'git (merge|rebase)[[:space:]]+(origin/)?master([[:space:]]|$)' && [ "$branch" = "master" ]; then
    deny "do not merge into master locally; pull requests only"
  fi
}

while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  case "$seg" in git\ *|sudo\ git\ *) check "$seg" ;; esac
done < <(printf '%s\n' "$stripped" | tr ';&|' '\n\n\n')
exit 0
