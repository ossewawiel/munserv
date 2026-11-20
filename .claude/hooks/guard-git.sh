#!/usr/bin/env bash
# PreToolUse guard for Bash and PowerShell: refuse the git operations no agent may run.
# Usage: guard-git.sh [bash|powershell] (the PowerShell tool's entry passes `powershell`).
# Only real git and gh invocations are inspected: line continuations are joined, heredoc bodies (and
# PowerShell here-string bodies) are removed, then a quote-aware tokenizer (guard-git-tok.awk) cuts the command
# into segments. A multi-word quoted string (commit message, PR body) becomes one placeholder word; a
# quoted single word and the value of --add-label stay readable. $(...) and backticks become a
# placeholder in their segment and segments of their own, so `git push origin $(...) -f` keeps its -f.
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
# \035 and \036 are this guard's own record markers; a command that holds them could pose as a heredoc
# body or start a record of its own and hide what follows.
case "$cmd" in *$'\035'*|*$'\036'*) deny "the command holds the control character \\035 or \\036; refusing" ;; esac
# Read the line ends the way the bash that runs the command does. Git Bash and Cygwin join `\`+CR+LF
# as a continuation, and a native jq.exe writes CRLF there, so CRLF becomes LF before the join below.
# Linux bash does not: there `\` escapes the CR and the LF ends the command, so folding would hide the
# next line from the checks. Every other CR becomes a space, which can only split a word: it adds
# checks and never hides one.
mode="${1:-bash}"
if [ "$mode" = "powershell" ]; then
  # PowerShell ends a line at CRLF or LF and continues one with a trailing backtick; elsewhere the
  # backtick is an escape (g`it runs git, `" is a quote character), which the tokenizer reads.
  cmd=${cmd//$'\r\n'/$'\n'}
  cmd=${cmd//$'`\n'/ }
  # PowerShell also quotes with curly and low-9 quotes. One literal per character: a bracket set of
  # multibyte characters matches single bytes in a C locale.
  for q in "“" "”" "„" "‟"; do cmd=${cmd//"$q"/\"}; done
  for q in "‘" "’" "‚" "‛"; do cmd=${cmd//"$q"/\'}; done
else
  if [ -n "$windows_bash" ]; then cmd=${cmd//$'\r\n'/$'\n'}; fi
  cmd=${cmd//$'\\\n'/ }
fi
cmd=${cmd//$'\r'/ }

psflag=""
[ "$mode" = powershell ] && psflag=1

# The heredoc pass and the tokenizer live beside this hook (guard-git-heredocs.awk,
# guard-git-tok.awk); when either is missing awk fails, and the scan refuses.
case "${BASH_SOURCE[0]}" in */*) hook_dir="${BASH_SOURCE[0]%/*}" ;; *) hook_dir=. ;; esac
tok_awk="$hook_dir/guard-git-tok.awk"
heredocs() { awk -v want="$1" -v ps="$psflag" -f "$hook_dir/guard-git-heredocs.awk"; }

# Strip one segment's wrappers until it stops changing; sets interp when a wrapper runs an interpreter.
# Pure bash, no subprocess per segment: process starts are slow on Windows and the hook has 10 s.
interp=""
re_interp='^(bash|sh|zsh|dash|ksh|fish|eval|source|pwsh|powershell|cmd|invoke-expression|iex)$'
re_start='^(start-process|saps|start)$'
re_gitword='(^|[[:space:]\\/])(git|gh)(\.exe)?([[:space:]]|$)'
re_wrap='^((!|&)[[:space:]]*|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+|(command|builtin|exec|eval|time|nohup|nice|timeout|stdbuf|xargs|sudo|doas|env|source|bash|sh|zsh|dash|ksh|fish|pwsh|powershell|cmd|invoke-expression|iex)(\.exe)?(([[:space:]]+[-/][^[:space:]]*)|([[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)|([[:space:]]+[0-9][0-9.]*[smhd]?))*([[:space:]]+|$))'
# Does this interpreter run code from the command line or stdin, rather than a script file?
# eval, Invoke-Expression, cmd, pwsh and powershell always count: Windows PowerShell reads a bare
# argument as a command, and pwsh options take values that look like script names. An sh-family shell
# counts with a short option holding c (-c, -ec, -euxc) or with no script argument (`| bash`,
# `bash <<EOF`); the value after a cluster ending in o or O (-o, -euo, +O) or after
# --rcfile/--init-file is skipped. `sh scripts/run.sh "git push -f"`
# only passes text.
runs_code() {
  local name="$1" t value=""
  local -a toks
  read -ra toks <<< "$2"
  case "$name" in
    eval|iex|invoke-expression|cmd) interp=1; return ;;
    pwsh|powershell)
      for t in "${toks[@]:1}"; do
        t="${t,,}"; t="${t#--}"; t="${t#-}"; t="${t#/}"
        if [[ $t =~ ^(e|ec|en|enc|enco.*)$ ]]; then
          deny "an encoded PowerShell command hides what it runs from this guard; pass the command as text"
        fi
      done
      interp=1; return ;;
  esac
  for t in "${toks[@]:1}"; do
    if [ -n "$value" ]; then value=""; continue; fi
    case "$t" in
      --*) [[ $t == --rcfile || $t == --init-file ]] && value=1 ;;
      -*c*) interp=1; return ;;
      -*o|+*o|-*O|+*O) value=1 ;;
      -*|+*|\<*) ;;
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

# Check every git and gh segment of $1; then, when it ran an interpreter, its quoted strings and
# heredoc bodies as more command text, up to depth 3. One scan per depth, with the payloads as \036-
# separated records that the tokenizer reads one by one: a scan per string costs a process start
# each, and a hook past its timeout lets the call run.
# At depth 0 a command that ends inside a quote or substitution is refused: no shell runs it, and
# reading past the open quote would hide every later line. Deeper, a payload may be plain text.
scan() {
  local text="$1" depth="$2" kept segs seg payload strict=""
  [ "$depth" -eq 0 ] && strict=1
  interp=""
  kept=$(printf '%s\n' "$text" | heredocs keep) || deny "this guard's heredoc pass did not run; refusing"
  segs=$(printf '%s\n' "$kept" | awk -v ps="$psflag" -v want=segments -v strict="$strict" -f "$tok_awk") \
    || deny "the command has an unclosed quote or substitution, or more than 200 substitutions, or this guard's tokenizer did not run, so it cannot be read; refusing"
  while IFS= read -r seg; do
    norm "$seg"
    track "$normed"
    case "$normed" in git\ *) check "$normed" ;; gh\ *) check_gh "$normed" ;; esac
  done <<< "$segs"
  [ -n "$interp" ] && [ "$depth" -lt 3 ] || return 0
  payload=$(printf '%s\n' "$kept" | awk -v ps="$psflag" -v want=payloads -f "$tok_awk") \
    || deny "this guard's tokenizer did not run; refusing"
  payload+=$'\036'$(printf '%s\n' "$text" | heredocs bodies)
  scan "$payload" $((depth + 1))
}
# GUARD_GIT_BRANCH lets the test runner pin the branch context (CI checks out master).
branch="${GUARD_GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"

# The branch a push runs on. The command can move before it pushes: `cd backend && ... && cd ..`,
# `git switch -c fix/x && git push -u origin HEAD`, `cd ../wt && git push`. track() follows those
# segments in order: a directory change is resolved for real, and inside the same checkout the branch
# stays, while another worktree has its own; git switch / checkout set the branch. A target that
# cannot be resolved (a variable, a placeholder, a missing directory, popd, cd -) makes the branch
# unknown, and the "you are on master" rules then stay silent, as they did for worktree pushes.
cur_branch="$branch"; cur_dir="$PWD"; start_top=""
resolve_dir() { # $1 dir: sets res_dir and res_branch, or empties both when it cannot be resolved
  local out top br
  res_dir=""; res_branch=""
  [ -n "$cur_dir" ] || return
  case "$1" in ""|_|-|*'$'*) return ;; esac
  out=$(cd "$cur_dir" 2>/dev/null && cd "$1" 2>/dev/null && pwd && { git rev-parse --show-toplevel 2>/dev/null || echo; } \
        && git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
  { IFS= read -r res_dir; IFS= read -r top; IFS= read -r br; } <<< "$out"
  [ -n "$start_top" ] || start_top=$(cd "$PWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$top" ] && [ "$top" = "$start_top" ]; then res_branch="$cur_branch"; else res_branch="$br"; fi
}
track() {
  local w a rest t i name=""
  local -a toks
  read -r w a rest <<< "$1"
  case "${w,,}" in
    cd|pushd|chdir|set-location|sl)
      case "${a,,}" in -path|-literalpath) a="${rest%%[[:space:]]*}" ;; ""|"~") a="$HOME" ;; esac
      resolve_dir "$a"; cur_dir="$res_dir"; cur_branch="$res_branch" ;;
    popd) cur_dir=""; cur_branch="" ;;
    git)
      [[ $a == switch || $a == checkout ]] || return
      [[ " $rest " == *" -- "* ]] && return
      read -ra toks <<< "$rest"
      for ((i = 0; i < ${#toks[@]}; i++)); do
        t="${toks[i]}"
        case "$t" in
          -c|-C|-b|-B|--create|--force-create|--orphan) name="${toks[i+1]:-}"; break ;;
          -*) ;;
          *) name="$t"; break ;;
        esac
      done
      case "$name" in "") ;; _|-|*'$'*) cur_branch="" ;; *) cur_branch="$name" ;; esac ;;
  esac
}

check() {
  local g="$1" on="$cur_branch" dir
  # `git -C <dir> push` runs in <dir>: resolve that directory's branch for this segment alone.
  if [[ $g =~ ^git([[:space:]]+-c[[:space:]]+[^[:space:]]+)*[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
    dir="${BASH_REMATCH[2]}"; resolve_dir "$dir"; on="$res_branch"
  fi
  # `git -C <dir> push` and `git -c k=v push` hide the subcommand; drop the global options first.
  g=$(printf '%s' "$g" | sed -E 's/^(sudo )?git( +(-C|-c) +[^ ]+)+/\1git/')
  case "$g" in
    *"git push"*)
      if printf '%s' "$g" | grep -Eq -- '(^|[[:space:]])--force([[:space:]]|$)' && ! printf '%s' "$g" | grep -q -- '--force-with-lease'; then
        deny "force push is not allowed; use --force-with-lease on a feature branch only"
      fi
      # -f alone or among short flags (-uf), and a +refspec, force too.
      if printf '%s' "$g" | grep -Eq -- '(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$)|(^|[[:space:]])\+[^[:space:]]'; then
        deny "force push is not allowed; use --force-with-lease on a feature branch only"
      fi
      # -d among short flags, and a :branch refspec, delete the remote branch.
      if printf '%s' "$g" | grep -Eq -- '(^|[[:space:]])-[a-zA-Z]*d[a-zA-Z]*([[:space:]]|$)|(^|[[:space:]]):[^[:space:]]'; then
        deny "deleting remote branches is the user's job"
      fi
      # master as a refspec or its destination, short or full (HEAD:refs/heads/master, HEAD:heads/master).
      if printf '%s' "$g" | grep -Eq '(^|[[:space:]]|:)(refs/heads/|heads/)?master([[:space:]]|$)'; then deny "pushing to master is not allowed; open a pull request"; fi
      # On master, a bare push would target master; a push naming another branch (worktrees do this) is fine.
      if [ "$on" = "master" ] && ! printf '%s' "$g" | grep -Eq 'git push([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^-[:space:]]+[[:space:]]+[^-[:space:]]+'; then
        deny "you are on master; create a branch before pushing"
      fi
      # On master, HEAD (or @) as a whole refspec is master too: `git push -u origin HEAD`.
      # HEAD:<branch> names its destination and stays allowed.
      if [ "$on" = "master" ] && printf '%s' "$g" | grep -Eq '(^|[[:space:]])(HEAD|@)([[:space:]]|$)'; then
        deny "you are on master, so HEAD is master; create a branch, or push HEAD:<branch>"
      fi
      if printf '%s' "$g" | grep -Eq -- '--delete|(^|[[:space:]])-d([[:space:]]|$)'; then deny "deleting remote branches is the user's job"; fi
      ;;
  esac
  if printf '%s' "$g" | grep -Eq 'git (reset --hard|clean -[a-zA-Z]*f|branch -D|filter-repo|filter-branch)'; then
    deny "destructive git operation blocked; ask the user"
  fi
  if printf '%s' "$g" | grep -Eq 'git (merge|rebase)[[:space:]]+(origin/)?master([[:space:]]|$)' && [ "$on" = "master" ]; then
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
