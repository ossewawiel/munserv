# Heredoc pass for guard-git.sh, run before the tokenizer.
#
#   want=keep    print the command with heredoc bodies taken out (the default).
#   want=bodies  print only the bodies, each followed by \036 so the tokenizer reads it on its own.
#   ps=1         PowerShell here-strings instead of bash heredocs.
#
# Bash mode reads <<TAG, << TAG, <<-TAG, <<\TAG and quoted tags (TAG may hold . and -), not <<<
# here-strings, and not a << inside quotes on its line. PowerShell mode reads only here-strings: an @'
# or @" that ends a line after a line start, blank, = ( , or ;, closed by the same quote and @ at
# column 0. The opener is printed with its @' replaced by _, so the tokenizer never sees an open quote,
# and the rest of the closing line after '@ is printed, because PowerShell runs it. In bash a line can
# end in @" without opening anything, so that rule stays in PowerShell.
#
# An expanding body (unquoted bash tag, PowerShell @") still runs its $(...) and backticks, so in keep
# mode it is printed at the end as a record that starts with \035; the tokenizer reads such a record as
# double-quoted text and scans only its substitutions.
#
# Input lines may hold \036 record separators (the interpreter rescan joins payloads with them). A body
# never runs past one: at each separator an open body is closed as code, so one payload cannot hide the
# next. An unclosed body is code too: it is printed.

BEGIN { skip = 0; nb = 0; ne = 0; reset() }

function code(   b) { for (b = 1; b <= nb; b++) print body[b]; nb = 0; skip = 0 }

function closebody(   b, txt) {
  if (want == "bodies") { for (b = 1; b <= nb; b++) print body[b]; printf "\036" }
  else if (expand) {
    txt = ""; for (b = 1; b <= nb; b++) txt = txt (b > 1 ? "\n" : "") body[b]
    exps[++ne] = txt
  }
  nb = 0; skip = 0
}

# Quote state carried across the lines of a record (bash mode): a stack of contexts, code (c), double
# quote (d), single quote (s), $'...' (a). $( opens code again inside a double quote, so the heredoc in
# --body "$(cat <<'EOF' is real, while a <<EOF on the second line of a multi-line "..." is text.
# Heredoc bodies do not move the state; a # comment in code ends the line; each \036 resets it.
function reset() { top = 1; st[1] = "c" }

# Walk line l from the carried state and leave the state after it; atq tells whether position p was
# inside a quote (p = 0: no question).
function walk(l, p,   k, n, ch, cur, prev) {
  atq = 0; n = length(l)
  for (k = 1; k <= n; k++) {
    if (k == p) atq = (st[top] != "c")
    ch = substr(l, k, 1); cur = st[top]
    # An escaped < before << is a literal character: `echo \<<EOF` redirects from a file, no heredoc.
    if (cur != "s" && ch == "\\") { if (k + 1 == p) atq = 1; k++; continue }
    if (cur == "s") { if (ch == "'") top--; continue }
    if (cur == "a") { if (ch == "'") top--; continue }
    if (ch == "$" && substr(l, k + 1, 1) == "(") { st[++top] = "c"; k++; continue }
    if (cur == "d") { if (ch == "\"") top--; continue }
    # $'...' (code only): a backslash escapes, as the tokenizer reads it, so $'it\'s <<EOF' is text.
    if (ch == "$" && substr(l, k + 1, 1) == "'") { st[++top] = "a"; k++; continue }
    prev = (k == 1) ? " " : substr(l, k - 1, 1)
    if (ch == "#" && prev ~ /[ \t;&|(]/) break
    if (ch == "'") st[++top] = "s"
    else if (ch == "\"") st[++top] = "d"
    else if (ch == "(") st[++top] = "c"
    else if (ch == ")" && top > 1) top--
  }
  if (p > n) atq = (st[top] != "c")
}

function line(l,   t, m, q) {
  if (skip) {
    if ((tag != "" && l ~ ("^[ \t]*" etag "[ \t]*$")) || (tag == "" && substr(l, 1, 2) == closer)) {
      closebody()
      if (tag == "" && want != "bodies" && substr(l, 3) != "") print substr(l, 3)
      return
    }
    body[++nb] = l; return
  }
  if (ps != "1" && match(l, /(^|[^<])<<-?[ \t]*\\?['"]?[A-Za-z_][A-Za-z0-9_.-]*/)) {
    m = substr(l, RSTART, RLENGTH)
    walk(l, (substr(m, 1, 1) == "<") ? RSTART : RSTART + 1)
    if (atq) { if (want != "bodies") print l; return }
    sub(/^[^<]?<<-?[ \t]*/, "", m)
    expand = (m !~ /^[\\'"]/)
    tag = m; sub(/^[\\'"]/, "", tag)
    etag = tag; gsub(/\./, "\\.", etag)
    if (want != "bodies") print l
    skip = 1; nb = 0; return
  }
  if (ps == "1" && match(l, /(^|[ \t=(,;])@['"][ \t]*$/)) {
    t = l; sub(/[ \t]*$/, "", t); q = substr(t, length(t), 1)
    closer = q "@"; tag = ""; expand = (q == "\"")
    if (want != "bodies") { sub(/@['"]$/, "_", t); print t }
    skip = 1; nb = 0; return
  }
  if (ps != "1") walk(l, 0)
  if (want != "bodies") print l
}

{
  n = split($0, part, "\036")
  if (n == 0) { line(""); next }
  for (i = 1; i <= n; i++) {
    if (i > 1) {
      if (skip) { if (want == "bodies") closebody(); else code() }
      reset()
      if (want != "bodies") printf "\036"
    }
    line(part[i])
  }
}

END {
  if (skip) { if (want == "bodies") closebody(); else code() }
  if (want != "bodies") for (e = 1; e <= ne; e++) printf "\036\035%s\n", exps[e]
}
