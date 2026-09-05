#!/usr/bin/env python3
"""Build the static progress dashboard (site/dashboard/index.html) from GitHub and the repo.

Data sources, all read-only:
  - gh api: open milestones, open issues (status:* labels), open PRs (checks, review decision),
    the last CI runs on master
  - domain/language.yaml: the vocabulary, rendered as the Domain page section
  - specs/features/**/*.md handoff frontmatter: stories with a design canvas and their approval
  - design/canvases/*: features with a canvas

Runs in .github/workflows/pages.yml with GH_TOKEN, and locally with a logged-in gh.
No tokens are spent by Claude; this is plain Python.
"""
from __future__ import annotations

import html
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "site" / "dashboard" / "index.html"
REPO = "ossewawiel/munserv"
PAGES = "https://ossewawiel.github.io/munserv"


def gh(*args: str):
    return json.loads(subprocess.check_output(["gh", *args], text=True))


def api(path: str, *jq: str):
    return gh("api", "--paginate", path, *jq)


def esc(s) -> str:
    return html.escape(str(s if s is not None else ""))


def label(issue, prefix: str) -> str:
    for l in issue.get("labels", []):
        n = l["name"] if isinstance(l, dict) else l
        if n.startswith(prefix):
            return n[len(prefix):]
    return ""


def story_id(title: str) -> str:
    m = re.match(r"\[([MWBS]\d+)\]", title or "")
    return m.group(1) if m else ""


def frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="ignore")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    try:
        return yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError:
        return {}


def collect():
    milestones = api(f"repos/{REPO}/milestones?state=open")
    issues = [i for i in api(f"repos/{REPO}/issues?state=open&per_page=100") if "pull_request" not in i]
    prs = gh("pr", "list", "--repo", REPO, "--state", "open", "--json",
             "number,title,headRefName,author,createdAt,statusCheckRollup,reviewDecision,labels,isDraft")
    runs = gh("run", "list", "--repo", REPO, "--workflow", "CI", "--branch", "master", "--limit", "10",
              "--json", "conclusion,headSha,createdAt,displayTitle,url")
    closed_recent = api(f"repos/{REPO}/issues?state=closed&per_page=30&sort=updated")
    closed_recent = [i for i in closed_recent if "pull_request" not in i][:12]

    lang = yaml.safe_load((ROOT / "domain" / "language.yaml").read_text(encoding="utf-8"))
    handoffs = []
    for p in sorted((ROOT / "specs" / "features").rglob("*.md")):
        if "completed" in p.parts or p.name in ("spec.md", "implementation-plan.md") or "_template" in p.parts:
            continue
        fm = frontmatter(p)
        if fm.get("story") or fm.get("issue"):
            fm["_path"] = str(p.relative_to(ROOT))
            fm["_feature"] = p.parent.name
            handoffs.append(fm)
    canvases = sorted(d.name for d in (ROOT / "design" / "canvases").glob("*") if d.is_dir()) if (ROOT / "design" / "canvases").exists() else []
    return milestones, issues, prs, runs, closed_recent, lang, handoffs, canvases


def pr_state(pr) -> tuple[str, str]:
    rollup = pr.get("statusCheckRollup") or []
    concl = {c.get("conclusion") or c.get("state") for c in rollup}
    if not rollup:
        ci = ("none", "no checks")
    elif any(c in ("FAILURE", "ERROR", "TIMED_OUT", "CANCELLED") for c in concl):
        ci = ("bad", "CI red")
    elif any(c in (None, "", "PENDING", "IN_PROGRESS", "QUEUED", "EXPECTED") for c in concl):
        ci = ("warn", "CI running")
    else:
        ci = ("ok", "CI green")
    rd = pr.get("reviewDecision") or ""
    review = {"APPROVED": ("ok", "approved"), "CHANGES_REQUESTED": ("bad", "changes requested"), "REVIEW_REQUIRED": ("warn", "review pending")}.get(rd, ("none", "no review"))
    return ci, review


def render(milestones, issues, prs, runs, closed_recent, lang, handoffs, canvases) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    by_status: dict[str, list] = {}
    for i in issues:
        by_status.setdefault(label(i, "status:") or "unlabelled", []).append(i)
    order = ["ready", "in-progress", "review", "blocked", "triage", "unlabelled", "done"]
    cols = [(s, by_status.get(s, [])) for s in order if by_status.get(s)]

    # Stories with a design stage
    design_rows = []
    for fm in handoffs:
        if fm.get("ui"):
            design_rows.append(fm)

    def pill(kind, text):
        return f'<span class="pill {kind}">{esc(text)}</span>'

    ms_html = ""
    for m in milestones:
        o, c = m["open_issues"], m["closed_issues"]
        total = o + c
        pct = int(round(100 * c / total)) if total else 0
        ms_html += f'''<article class="ms"><div class="row"><h3>{esc(m["title"])}</h3><span class="fig">{c}<small>/{total}</small></span></div>
        <div class="bar"><div style="width:{pct}%"></div></div>
        <p class="muted">{pct}% closed · <a href="{esc(m["html_url"])}">milestone</a></p></article>'''

    board_html = ""
    for status, items in cols:
        kind = {"ready": "ok", "in-progress": "warn", "review": "warn", "blocked": "bad"}.get(status, "none")
        board_html += f'<section class="col"><h3>{pill(kind, status)} <span class="muted">{len(items)}</span></h3><ul>'
        for i in sorted(items, key=lambda x: x["number"]):
            plat = ", ".join(l["name"][9:] for l in i["labels"] if l["name"].startswith("platform:"))
            ms = (i.get("milestone") or {}).get("title", "")
            board_html += f'<li><a href="{esc(i["html_url"])}">#{i["number"]}</a> {esc(i["title"])}<span class="muted"> {esc(plat)}{" · " + esc(ms) if ms else ""}</span></li>'
        board_html += "</ul></section>"

    pr_html = ""
    for pr in prs:
        ci, review = pr_state(pr)
        pr_html += f'<tr><td><a href="https://github.com/{REPO}/pull/{pr["number"]}">#{pr["number"]}</a></td><td>{esc(pr["title"])}</td><td>{pill(*ci)}</td><td>{pill(*review)}</td><td class="muted">{esc(pr["author"]["login"])}</td></tr>'
    if not prs:
        pr_html = '<tr><td colspan="5" class="muted">No open pull requests.</td></tr>'

    runs_html = "".join(
        f'<a class="run {("ok" if r["conclusion"]=="success" else "bad" if r["conclusion"] in ("failure","timed_out") else "warn")}" href="{esc(r["url"])}" title="{esc(r["displayTitle"])} · {esc(r["createdAt"][:16])}"></a>'
        for r in reversed(runs)
    )
    last = runs[0] if runs else None
    ci_line = f'{pill("ok" if last and last["conclusion"]=="success" else "bad", "master " + (last["conclusion"] if last else "unknown"))} on <a href="{esc(last["url"]) if last else "#"}">{esc(last["displayTitle"][:60]) if last else ""}</a>'

    design_html = ""
    for fm in design_rows:
        canvas = fm.get("design_canvas") or ""
        state = ("ok", "approved") if fm.get("design_approved") else (("warn", "awaiting approval") if canvas else ("none", "no canvas yet"))
        design_html += f'<tr><td>{esc(fm.get("story"))}</td><td>{esc(fm.get("title"))}</td><td>{esc(fm.get("_feature"))}</td><td>{pill(*state)}</td><td>{("<a href=\"" + esc(canvas) + "\">canvas</a>") if canvas else ""}</td></tr>'
    if not design_rows:
        design_html = '<tr><td colspan="5" class="muted">No UI stories in flight.</td></tr>'

    domain_html = ""
    for key, c in (lang.get("concepts") or {}).items():
        values = c.get("values") or {}
        vals = "; ".join(f'<b>{esc(k)}</b>: {esc(", ".join(map(str, v)))}' for k, v in values.items())
        code = c.get("code") or {}
        kt = len(code.get("kotlin") or []); ts = len(code.get("typescript") or []); dt = len(code.get("dart") or [])
        db = code.get("db") or {}; dbn = len(db.get("tables") or []) + len(db.get("enums") or [])
        drift = c.get("drift_issue")
        domain_html += f'''<article class="concept"><div class="row"><h3>{esc(key)}</h3>{pill("warn", "drift #" + str(drift)) if drift else ""}</div>
        <p>{esc(c.get("definition"))}</p>
        <p class="muted">Kotlin {kt} · DB {dbn} · TS {ts} · Dart {dt} · <a href="https://github.com/{REPO}/blob/master/domain/{esc(c.get("file"))}">{esc(c.get("file"))}</a></p>
        {("<p class=\"vals\">" + vals + "</p>") if vals else ""}</article>'''

    closed_html = "".join(f'<li><a href="{esc(i["html_url"])}">#{i["number"]}</a> {esc(i["title"])}<span class="muted"> {esc(i["closed_at"][:10])}</span></li>' for i in closed_recent)

    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>MunServ Factory</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@87.5,500;87.5,700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400&display=swap">
<style>
:root{{--ink:#1c2a25;--ink-2:#4a5b54;--ink-3:#7a8a83;--ground:#fbfaf6;--paper:#fff;--paper-2:#f3f1e9;--rule:#dcd9cd;--forest:#233d36;--forest-soft:#e2ebe6;--clay:#d9613f;--clay-soft:#fbe6de;--clay-ink:#8f3418;--ok:#2f7d4f;--ok-soft:#e0f0e6;--warn:#b7791f;--warn-soft:#fbf0d5;--bad:#b8332f;--bad-soft:#f9e0de}}
@media (prefers-color-scheme:dark){{:root{{--ink:#eef0ea;--ink-2:#b9c2bb;--ink-3:#8a958e;--ground:#141b18;--paper:#1b2420;--paper-2:#222d28;--rule:#34423b;--forest:#a9c8ba;--forest-soft:#23342d;--clay:#f0805e;--clay-soft:#46271d;--clay-ink:#ffb79f;--ok:#7fcf9a;--ok-soft:#1f3a2a;--warn:#e6b45a;--warn-soft:#3d3117;--bad:#f08a86;--bad-soft:#452221}}}}
*{{box-sizing:border-box}} body{{margin:0;background:var(--ground);color:var(--ink);font-family:"IBM Plex Sans",system-ui,sans-serif;font-size:15px;line-height:1.5}}
a{{color:var(--forest)}} .wrap{{max-width:1180px;margin:0 auto;padding:40px 28px 80px;display:flex;flex-direction:column;gap:40px}}
.eyebrow{{font-family:Archivo,sans-serif;font-stretch:87.5%;font-size:.72rem;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:var(--clay)}}
h1{{font-family:Archivo,sans-serif;font-stretch:87.5%;font-size:2.2rem;font-weight:700;line-height:1.05;margin:4px 0 8px}} h2{{font-family:Archivo,sans-serif;font-stretch:87.5%;font-size:1.3rem;margin:0 0 12px}} h3{{font-family:Archivo,sans-serif;font-stretch:87.5%;font-size:1rem;margin:0}}
p{{margin:0}} .muted{{color:var(--ink-3);font-size:.85rem}} .row{{display:flex;justify-content:space-between;align-items:baseline;gap:8px}}
.pill{{display:inline-block;padding:1px 8px;border-radius:999px;font-size:.74rem;font-weight:600;white-space:nowrap}} .pill.ok{{background:var(--ok-soft);color:var(--ok)}} .pill.warn{{background:var(--warn-soft);color:var(--warn)}} .pill.bad{{background:var(--bad-soft);color:var(--bad)}} .pill.none{{background:var(--paper-2);color:var(--ink-3)}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px}} .ms,.concept{{background:var(--paper);border:1px solid var(--rule);border-top:3px solid var(--forest);padding:14px 16px;display:flex;flex-direction:column;gap:8px}}
.fig{{font-family:Archivo,sans-serif;font-stretch:87.5%;font-size:1.5rem;font-weight:700;font-variant-numeric:tabular-nums}} .fig small{{font-size:.8rem;color:var(--ink-3);font-weight:500}}
.bar{{height:6px;background:var(--paper-2);border-radius:3px;overflow:hidden}} .bar div{{height:100%;background:var(--clay)}}
.board{{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px}} .col{{background:var(--paper);border:1px solid var(--rule);padding:12px 14px}} .col ul{{margin:8px 0 0;padding-left:18px;display:flex;flex-direction:column;gap:6px;font-size:.9rem}}
table{{border-collapse:collapse;width:100%;background:var(--paper);font-size:.9rem}} .tw{{overflow-x:auto;border:1px solid var(--rule)}} th,td{{text-align:left;padding:8px 10px;border-bottom:1px solid var(--rule)}} th{{font-size:.72rem;letter-spacing:.08em;text-transform:uppercase;color:var(--ink-3);background:var(--paper-2)}} tr:last-child td{{border-bottom:0}}
.runs{{display:flex;gap:4px;align-items:center}} .run{{width:18px;height:18px;border-radius:3px;display:inline-block}} .run.ok{{background:var(--ok)}} .run.bad{{background:var(--bad)}} .run.warn{{background:var(--warn)}}
.vals{{font-size:.82rem;color:var(--ink-2)}} .links{{display:flex;gap:16px;flex-wrap:wrap;font-size:.9rem}} ul.plain{{margin:0;padding-left:18px;display:flex;flex-direction:column;gap:5px;font-size:.9rem}}
</style></head><body><div class="wrap">
<header><div class="eyebrow">MunServ · factory</div><h1>Progress</h1><p class="muted">Built {now} from master. Rebuilt on every merge and nightly.</p>
<div class="links"><a href="../">Design catalogues</a><a href="../storybook/">Storybook</a><a href="../widgetbook/">Widgetbook</a><a href="https://github.com/{REPO}/pulls">Pull requests</a><a href="https://github.com/users/ossewawiel/projects/5">Board</a></div></header>

<section><h2>Milestones</h2><div class="grid">{ms_html or '<p class="muted">No open milestones.</p>'}</div></section>

<section><h2>Pull requests waiting on you</h2><div class="tw"><table><thead><tr><th>PR</th><th>Title</th><th>CI</th><th>Review</th><th>Author</th></tr></thead><tbody>{pr_html}</tbody></table></div></section>

<section><h2>CI on master</h2><p>{ci_line}</p><div class="runs" style="margin-top:8px">{runs_html}</div><p class="muted">Last ten runs, oldest first.</p></section>

<section><h2>Stories by status</h2><div class="board">{board_html or '<p class="muted">No open issues.</p>'}</div></section>

<section><h2>Design sign-off</h2><div class="tw"><table><thead><tr><th>Story</th><th>Title</th><th>Feature</th><th>Canvas</th><th></th></tr></thead><tbody>{design_html}</tbody></table></div>
<p class="muted">Canvases in the repo: {esc(", ".join(canvases)) if canvases else "none yet"}.</p></section>

<section><h2>Recently closed</h2><ul class="plain">{closed_html or "<li class='muted'>Nothing recently.</li>"}</ul></section>

<section><h2>Domain language</h2><p class="muted">{len((lang.get("concepts") or {}))} concepts from <a href="https://github.com/{REPO}/tree/master/domain">domain/</a>, validated against the code in CI.</p><div class="grid" style="margin-top:12px">{domain_html}</div></section>
</div></body></html>'''


def main() -> int:
    data = collect()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(render(*data), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
