# Tokenizer for guard-git.sh: cuts a command into segments, one per output line.
#
# Input records are separated by \036; each record is tokenized on its own, so an unbalanced quote in
# one payload cannot swallow the next. Variables:
#   ps=1           PowerShell rules: backtick escapes, ( ) groups, { } always split, <# #> comments.
#   want=payloads  print each quoted string's text (unescaped as the shell would pass it) followed
#                  by \036, for the interpreter rescan, instead of the segments.
#   strict=1       exit 3 when a record ends inside a quote or substitution, or holds more than 200
#                  substitutions. A shell rejects an unclosed quote, so a command that runs never
#                  ends inside one; reading past it would hide every later line.
#
# A quoted string becomes its text when it is one word, git or gh when it is a path to them, its raw
# text after --add-label, and _ otherwise. Each $(...), <(...), >(...), ${...}, $((...)), backtick span
# (and in PowerShell each (...)) becomes the word _ in its segment, and its text becomes segments of its
# own. ; & | ( ) split segments, and so do { and } when they stand alone (always in PowerShell). An
# unquoted # at the start of a word starts a comment. In bash a backslash escapes the next character
# (g\it is git) and $'...' reads its escapes; in PowerShell a backslash is a path character and the
# backtick escapes.

BEGIN { RS = "\036" }

function quoted(c, out,   lc) {
  if (out ~ /--add-label[ \t]*=?[ \t]*$/) return c
  lc = tolower(c)
  if (lc ~ /[\\\/]gh(\.exe)?$/) return "gh"
  if (lc ~ /[\\\/]git(\.exe)?$/) return "git"
  if (c == "" || c ~ /[ \t\n]/) return "_"
  return c
}

function escapes(ch) { return (ch == "\\" && ps != "1") || (ch == "`" && ps == "1") }

# Index of the quote closing the double quote at p, past escapes and $(...); 0 when there is none.
function dqend(s, p, n,   k, ch) {
  for (k = p + 1; k <= n; k++) {
    ch = substr(s, k, 1)
    if (escapes(ch)) { k++; continue }
    if (ch == "$" && substr(s, k + 1, 1) == "(") { k = pairend(s, k + 1, n, "(", ")"); if (k == 0) return 0; continue }
    if (ch == "\"") return k
  }
  return 0
}

# Index of the `cl` closing the `op` at p, past quoted spans and escapes; 0 when there is none.
function pairend(s, p, n, op, cl,   d, k, ch, j) {
  d = 0
  for (k = p; k <= n; k++) {
    ch = substr(s, k, 1)
    if (escapes(ch)) { k++; continue }
    if (ch == "'") { j = index(substr(s, k + 1), "'"); if (j == 0) return 0; k += j; continue }
    if (ch == "\"") { k = dqend(s, k, n); if (k == 0) return 0; continue }
    if (ch == op) d++
    else if (ch == cl) { d--; if (d == 0) return k }
  }
  return 0
}

function addsub(t) { if (nq >= 200) { bad = 1; return } subq[++nq] = t }

function tok(s,   out, i, n, c, nx, j, k, buf, raw, prev, atword, closed) {
  out = ""; n = length(s); i = 1
  while (i <= n) {
    c = substr(s, i, 1); nx = substr(s, i + 1, 1)
    prev = (i == 1) ? "\n" : substr(s, i - 1, 1)
    atword = (prev ~ /[ \t\n;&|()]/)
    if (escapes(c)) { out = out nx; i += 2; continue }
    if (ps == "1" && c == "<" && nx == "#") {
      j = index(substr(s, i + 2), "#>"); if (j == 0) { bad = 1; i = n + 1 } else i = i + j + 3
      out = out " "; continue
    }
    if (c == "#" && atword) { j = index(substr(s, i), "\n"); i = (j == 0) ? n + 1 : i + j - 1; continue }
    if (c == "'") {
      j = index(substr(s, i + 1), "'")
      if (j == 0) { bad = 1; buf = substr(s, i + 1); i = n + 1 } else { buf = substr(s, i + 1, j - 1); i = i + j + 1 }
      pay[++np] = buf; out = out quoted(buf, out); continue
    }
    if (ps != "1" && c == "$" && nx == "'") {
      buf = ""; k = i + 2; closed = 0
      while (k <= n) {
        c = substr(s, k, 1)
        if (c == "\\") { buf = buf substr(s, k + 1, 1); k += 2; continue }
        if (c == "'") { closed = 1; k++; break }
        buf = buf c; k++
      }
      if (!closed) bad = 1
      pay[++np] = buf; out = out quoted(buf, out); i = k; continue
    }
    if (c == "\"") {
      buf = ""; raw = ""; i++; closed = 0
      while (i <= n) {
        c = substr(s, i, 1); nx = substr(s, i + 1, 1)
        if (c == "\\" && ps != "1") {
          if (nx == "\"" || nx == "\\" || nx == "$" || nx == "`") raw = raw nx; else raw = raw c nx
          buf = buf nx; i += 2; continue }
        if (c == "`" && ps == "1") { raw = raw nx; buf = buf nx; i += 2; continue }
        if (c == "\"") { i++; closed = 1; break }
        if (c == "$" && nx == "(") {
          k = pairend(s, i + 1, n, "(", ")"); if (k == 0) { bad = 1; k = n }
          addsub(substr(s, i + 2, k - i - 2)); raw = raw substr(s, i, k - i + 1); buf = buf "_"; i = k + 1; continue }
        if (c == "$" && nx == "{") {
          k = pairend(s, i + 1, n, "{", "}"); if (k == 0) { bad = 1; k = n }
          addsub(substr(s, i + 2, k - i - 2)); raw = raw substr(s, i, k - i + 1); buf = buf "_"; i = k + 1; continue }
        if (c == "`" && ps != "1") {
          j = index(substr(s, i + 1), "`"); if (j == 0) { bad = 1; k = n } else k = i + j
          addsub(substr(s, i + 1, k - i - 1)); raw = raw substr(s, i, k - i + 1); buf = buf "_"; i = k + 1; continue }
        raw = raw c; buf = buf c; i++
      }
      if (!closed) bad = 1
      pay[++np] = raw; out = out quoted(buf, out); continue
    }
    if ((c == "$" || c == "<" || c == ">") && nx == "(") {
      k = pairend(s, i + 1, n, "(", ")"); if (k == 0) { bad = 1; k = n }
      addsub(substr(s, i + 2, k - i - 2)); out = out "_"; i = k + 1; continue
    }
    if (c == "$" && nx == "{") {
      k = pairend(s, i + 1, n, "{", "}"); if (k == 0) { bad = 1; k = n }
      addsub(substr(s, i + 2, k - i - 2)); out = out "_"; i = k + 1; continue
    }
    if (ps == "1" && c == "(") {
      k = pairend(s, i, n, "(", ")"); if (k == 0) { bad = 1; k = n }
      addsub(substr(s, i + 1, k - i - 1)); out = out "_"; i = k + 1; continue
    }
    if (ps != "1" && c == "`") {
      j = index(substr(s, i + 1), "`"); if (j == 0) { bad = 1; k = n } else k = i + j
      addsub(substr(s, i + 1, k - i - 1)); out = out "_"; i = k + 1; continue
    }
    if (c == ";" || c == "&" || c == "|" || c == "(" || c == ")") { out = out "\n"; i++; continue }
    if (c == "{" || c == "}") {
      if (ps == "1" || (atword && (nx == "" || nx ~ /[ \t\n;&|)]/))) { out = out "\n"; i++; continue }
    }
    out = out c; i++
  }
  return out
}

{
  nq = 0; first = np + 1
  res = tok($0)
  for (q = 1; q <= nq; q++) res = res "\n" tok(subq[q])
  if (want == "payloads") { for (p = first; p <= np; p++) printf "%s\036", pay[p] }
  else print res
}

END { if (bad && strict == "1") exit 3 }
