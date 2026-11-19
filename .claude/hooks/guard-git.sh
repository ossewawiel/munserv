#!/usr/bin/env bash
# PreToolUse guard for Bash and PowerShell: refuse the git operations no agent may run.
# Usage: guard-git.sh [bash|powershell] (the PowerShell tool's entry passes `powershell`).
# Only real git and gh invocations are inspected: line continuations are joined, then heredoc
# bodies (and PowerShell here-string bodies) and multi-word quoted strings (commit messages, PR bodies,
# test strings) are removed. A quoted single word and the value of --add-label stay readable, since
# they are arguments. The command is then split on ; & | ( ) { } ` and newlines, so a subshell,
# a group or a command substitution is its own segment.
# Each segment loses its wrappers before it is read: `!`, `&`, VAR=value, env, command, builtin, exec,
# eval, time, nohup, nice, timeout, xargs, sudo, a path or a `\` before the program, `.exe`, and the
# letter case of git and gh (Windows finds GIT.EXE). Segments that then start with git or gh are checked.
# When any segment runs an interpreter (bash -c, sh, eval, source, pwsh, powershell, cmd,
# Invoke-Expression), each quoted string and heredoc body is scanned again as a command, three levels
# deep. Start-Process with git or gh is refused outright.
# Exit 2 blocks the call and returns the message to the model.
#
# Fail closed: the command is read with jq or node, whichever is found first (node first under Git Bash
# and Cygwin, where a native jq.exe writes CRLF). With neither, with empty input, input that does not
# parse, or no string at tool_input.command, every call is refused. Before this, a missing jq read as
# an empty command and let everything through, force pushes included.
deny() { echo "guard-git: $1" >&2; exit 2; }

read_with_jq() {
  # -e: whitespace-only input yields no value, which exits 4 instead of reading as an empty command.
  printf '%s' "$input" | jq -er '.tool_input.command | if type == "string" then . else error("no command") end'
}
read_with_node() {
  printf '%s' "$input" | node -e '
let s = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (d) => { s += d; }).on("end", () => {
  const c = ((JSON.parse(s) || {}).tool_input || {}).command;
  if (typeof c !== "string") throw new Error("no command");
  process.stdout.write(c);
});' 2>/dev/null
}

input=$(cat)
[ -n "$input" ] || deny "the tool input is empty, so this guard cannot read the command; refusing"
# GUARD_GIT_WINDOWS_BASH lets the test runner stand in for Git Bash on Linux, where bash sets OSTYPE.
windows_bash="${GUARD_GIT_WINDOWS_BASH:-}"
case "${OSTYPE:-}" in msys*|cygwin*) windows_bash=1 ;; esac
if [ -n "$windows_bash" ]; then readers="node jq"; else readers="jq node"; fi
reader=""
for r in $readers; do
  if command -v "$r" >/dev/null 2>&1; then reader="$r"; break; fi
done
[ -n "$reader" ] || deny "neither jq nor node is on PATH, so this guard cannot read the command and refuses every Bash call. Ask the user to install node or jq (apt install jq), then start a new session"
cmd=$("read_with_$reader") || deny "the tool input did not parse or has no command, so this guard cannot read it; refusing"
# Read the line ends the way the bash that runs the command does. Git Bash and Cygwin join `\`+CR+LF
# as a continuation, and a native jq.exe writes CRLF there, so CRLF becomes LF before the join below.
# Linux bash does not: there `\` escapes the CR and the LF ends the command, so folding would hide the
# next line from the checks. Every other CR becomes a space, which can only split a word: it adds
# checks and never hides one.
mode="${1:-bash}"
if [ "$mode" = "powershell" ]; then
  # PowerShell ends a line at CRLF or LF and continues one with a trailing backtick; elsewhere the
  # backtick is an escape (g`it runs git), so it is dropped.
  cmd=${cmd//$'\r\n'/$'\n'}
  cmd=${cmd//$'`\n'/ }
  cmd=${cmd//\`/}
else
  if [ -n "$windows_bash" ]; then cmd=${cmd//$'\r\n'/$'\n'}; fi
  cmd=${cmd//$'\\\n'/ }
fi
cmd=${cmd//$'\r'/ }

# Heredoc bodies (and, in PowerShell mode only, here-string bodies) out, or only those bodies with
# `bodies`. In bash a line can end in @" without opening anything, so that rule must stay in PowerShell.
heredocs() {
  awk -v want="$1" -v ps="$([ "$mode" = powershell ] && echo 1)" 'BEGIN{skip=0}
       { if (skip) { if ((tag != "" && $0 ~ ("^[ \t]*" tag "[ \t]*$")) || (tag == "" && $0 ~ /^[ \t]*[\047"]@/)) { skip=0; next }
                     if (want == "bodies") print; next }
         if (match($0, /<<-?[\047"]?[A-Za-z_][A-Za-z0-9_]*/)) {
           tag=substr($0, RSTART, RLENGTH); sub(/^<<-?[\047"]?/, "", tag); if (want != "bodies") print; skip=1; next }
         if (ps == "1" && $0 ~ /@[\047"][ \t]*$/) { tag=""; if (want != "bodies") print; skip=1; next }
         if (want != "bodies") print }'
}

# Strip one segment's wrappers until it stops changing; sets interp when a wrapper runs an interpreter.
# Pure bash, no subprocess per segment: process starts are slow on Windows and the hook has 10 s.
interp=""
re_interp='^(bash|sh|zsh|dash|ksh|fish|eval|source|pwsh|powershell|cmd|invoke-expression|iex)$'
re_start='^(start-process|saps|start)$'
re_gitword='(^|[[:space:]\\/])(git|gh)(\.exe)?([[:space:]]|$)'
re_wrap='^((!|&)[[:space:]]*|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+|(command|builtin|exec|eval|time|nohup|nice|timeout|stdbuf|xargs|sudo|doas|env|source|bash|sh|zsh|dash|ksh|fish|pwsh|powershell|cmd|invoke-expression|iex)(\.exe)?(([[:space:]]+[-/][^[:space:]]*)|([[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)|([[:space:]]+[0-9][0-9.]*[smhd]?))*([[:space:]]+|$))'
# Does this interpreter run code from the command line or stdin, rather than a script file?
# eval and Invoke-Expression always do. A shell does with -c / -Command / /c, or with no script
# argument (`| bash`, `bash <<EOF`). `sh scripts/run.sh "git push -f ..."` only passes text.
runs_code() {
  local name="$1" t
  local -a toks
  case "$name" in eval|iex|invoke-expression) interp=1; return ;; esac
  read -ra toks <<< "$2"
  for t in "${toks[@]:1}"; do
    if [[ $name == pwsh || $name == powershell ]] && [[ ${t,,} =~ ^-(e|ec|en|enc|enco.*)$ ]]; then
      deny "an encoded PowerShell command hides what it runs from this guard; pass the command as text"
    fi
    case "${t,,}" in
      -c|-[a-z]*c|-command|-com*|/c|/k) interp=1; return ;;
      -*|/*|\<*) ;;
      *) return ;;
    esac
  done
  interp=1
}

norm() {
  local s="$1" prev w lw i
  for i in 1 2 3 4 5 6 7 8; do
    prev="$s"
    s="${s#"${s%%[![:space:]]*}"}"
    # A path before the program (/usr/bin/git, C:\...\git.exe, \git) and .exe or capitals on git and gh.
    w="${s%%[[:space:]]*}"
    if [[ $w == *[\\/]* ]]; then s="${w##*[\\/]}${s:${#w}}"; w="${w##*[\\/]}"; fi
    lw="${w,,}"
    lw="${lw%.exe}"
    if [[ $lw == git || $lw == gh ]]; then s="$lw${s:${#w}}"; fi
    s="${s/#git --% /git }"
    if [[ $lw =~ $re_interp ]]; then runs_code "$lw" "$s"; fi
    if [[ $lw =~ $re_start ]] && [[ ${s,,} =~ $re_gitword ]]; then
      deny "Start-Process hides the git or gh command from this guard; run git or gh directly"
    fi
    shopt -s nocasematch
    if [[ $s =~ $re_wrap ]]; then s="${s:${#BASH_REMATCH[0]}}"; fi
    shopt -u nocasematch
    [ "$s" = "$prev" ] && break
  done
  # A global, not output: in $(...) the deny above and interp would be lost in the subshell.
  normed="$s"
}

re_quoted='"(([^"\\]|\\.)*)"|'"'"'([^'"'"']*)'"'"
# Check every git and gh segment of $1; then, when it ran an interpreter, its quoted strings and
# heredoc bodies as commands of their own, up to depth 3.
scan() {
  local text="$1" depth="$2" stripped seg rest payload
  interp=""
  stripped=$(printf '%s\n' "$text" | heredocs keep \
    | sed -E "s#['\"][^'\"]*[\\/](git|gh)(\.exe)?['\"]#\1#Ig; s/(--add-label)[ =]+[\"']([^\"']*)[\"']/\1 \2/g; s/'([^' ]*)'/\1/g; s/\"([^\" ]*)\"/\1/g; s/'[^']*'/_/g; s/\"[^\"]*\"/_/g")
  while IFS= read -r seg; do
    norm "$seg"
    case "$normed" in git\ *) check "$normed" ;; gh\ *) check_gh "$normed" ;; esac
  done < <(printf '%s\n' "$stripped" | tr ';&|(){}`' '\n\n\n\n\n\n\n\n')
  [ -n "$interp" ] && [ "$depth" -lt 3 ] || return 0
  rest="$text"
  while [[ $rest =~ $re_quoted ]]; do
    payload="${BASH_REMATCH[1]}${BASH_REMATCH[3]}"
    rest="${rest#*"${BASH_REMATCH[0]}"}"
    payload=${payload//\\\"/\"}
    scan "$payload" $((depth + 1))
  done
  payload=$(printf '%s\n' "$text" | heredocs bodies)
  [ -z "$payload" ] || scan "$payload" $((depth + 1))
}
# GUARD_GIT_BRANCH lets the test runner pin the branch context (CI checks out master).
branch="${GUARD_GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"

check() {
  local g="$1"
  # `git -C <dir> push` and `git -c k=v push` hide the subcommand; drop the global options first.
  g=$(printf '%s' "$g" | sed -E 's/^(sudo )?git( +(-C|-c) +[^ ]+)+/\1git/')
  case "$g" in
    *"git push"*)
      if printf '%s' "$g" | grep -Eq -- '(^|[[:space:]])(--force|-f)([[:space:]]|$)' && ! printf '%s' "$g" | grep -q -- '--force-with-lease'; then
        deny "force push is not allowed; use --force-with-lease on a feature branch only"
      fi
      if printf '%s' "$g" | grep -Eq '(^|[[:space:]]|:)master([[:space:]]|$)'; then deny "pushing to master is not allowed; open a pull request"; fi
      # On master, a bare push would target master; a push naming another branch (worktrees do this) is fine.
      if [ "$branch" = "master" ] && ! printf '%s' "$g" | grep -Eq 'git push([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^-[:space:]]+[[:space:]]+[^-[:space:]]+'; then
        deny "you are on master; create a branch before pushing"
      fi
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

check_gh() {
  # Merging is automatic (auto-pr.yml arms --auto); a manual merge skips the CI gate.
  if printf '%s' "$1" | grep -Eq '^gh pr merge' && ! printf '%s' "$1" | grep -Eq -- '(^|[[:space:]])--auto([[:space:]]|$)'; then
    deny "merging is automatic; use gh pr merge <n> --auto --squash only"
  fi
  # Agents use the owner's gh login, so GitHub cannot tell who applied a label or changed a setting
  # (#294). These lines are what keep the CI edit guard's release with a person.
  if printf '%s' "$1" | grep -Eq '^gh (pr|issue) edit' && printf '%s' "$1" | grep -q -- '--add-label' \
    && printf '%s' "$1" | grep -q 'ci-edit-approved'; then
    deny "only the owner releases a held CI edit; report the release command to the user and stop"
  fi
  if printf '%s' "$1" | grep -Eq '^gh api graphql'; then
    # The query is a multi-word string, which the segment no longer holds.
    if printf '%s' "$cmd" | grep -Eq 'addLabelsToLabelable|mergePullRequest|(create|update|delete)(BranchProtectionRule|RepositoryRuleset)'; then
      deny "this mutation can release or bypass the CI edit guard; ask the user"
    fi
  elif printf '%s' "$1" | grep -Eq '^gh api( |$)' && gh_api_writes "$1"; then
    if printf '%s' "$1" | grep -Eq 'branches/[^ ]*/protection|/rulesets|/pulls/[^ /]+/merge|/issues/[^ /]+/labels'; then
      deny "this API write can release or bypass the CI edit guard; ask the user"
    fi
  fi
}

# gh api sends a GET unless -X says otherwise or a field or input is given. -X GET with fields stays a read.
gh_api_writes() {
  if printf '%s' "$1" | grep -Eq -- '(^|[[:space:]])(-X|--method)([[:space:]]+|=)'; then
    ! printf '%s' "$1" | grep -Eiq -- '(^|[[:space:]])(-X|--method)([[:space:]]+|=)get([[:space:]]|$)'
  else
    printf '%s' "$1" | grep -Eq -- '(^|[[:space:]])(-f|-F|--field|--raw-field|--input)([[:space:]=]|$)'
  fi
}

scan "$cmd" 0
exit 0
