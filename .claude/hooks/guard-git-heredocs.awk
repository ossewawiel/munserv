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

BEGIN { skip = 0; nb = 0; ne = 0 }

function code(   b) { for (b = 1; b <= nb; b++) print body[b]; nb = 0; skip = 0 }

function closebody(   b, txt) {
  if (want == "bodies") { for (b = 1; b <= nb; b++) print body[b]; printf "\036" }
  else if (expand) {
    txt = ""; for (b = 1; b <= nb; b++) txt = txt (b > 1 ? "\n" : "") body[b]
    exps[++ne] = txt
  }
  nb = 0; skip = 0
}

# Is position p of line l inside a quote opened earlier on the line? A stack of contexts: code (c),
# double quote (d), single quote (s). $( opens code again inside a double quote, so the heredoc in
# --body "$(cat <<'EOF' is real.
function inquote(l, p,   k, ch, cur, top, st) {
  top = 1; st[1] = "c"
  for (k = 1; k < p; k++) {
    ch = substr(l, k, 1); cur = st[top]
    if (cur != "s" && ((ch == "\\" && ps != "1") || (ch == "`" && ps == "1"))) { k++; continue }
    if (cur == "s") { if (ch == "'") top--; continue }
    if (ch == "$" && substr(l, k + 1, 1) == "(") { st[++top] = "c"; k++; continue }
    if (cur == "d") { if (ch == "\"") top--; continue }
    if (ch == "'") st[++top] = "s"
    else if (ch == "\"") st[++top] = "d"
    else if (ch == "(") st[++top] = "c"
    else if (ch == ")" && top > 1) top--
  }
  return st[top] != "c"
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
  if (ps != "1" && match(l, /(^|[^<])<<-?[ \t]*\\?['"]?[A-Za-z_][A-Za-z0-9_.-]*/) && !inquote(l, RSTART + 1)) {
    m = substr(l, RSTART, RLENGTH); sub(/^[^<]?<<-?[ \t]*/, "", m)
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
  if (want != "bodies") print l
}

{
  n = split($0, part, "\036")
  if (n == 0) { line(""); next }
  for (i = 1; i <= n; i++) {
    if (i > 1) {
      if (skip) { if (want == "bodies") closebody(); else code() }
      if (want != "bodies") printf "\036"
    }
    line(part[i])
  }
}

END {
  if (skip) { if (want == "bodies") closebody(); else code() }
  if (want != "bodies") for (e = 1; e <= ne; e++) printf "\036\035%s\n", exps[e]
}
