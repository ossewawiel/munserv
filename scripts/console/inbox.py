"""The Inbox: every item waiting on a human, oldest first, with its age.

Five kinds, each with the moment it started waiting:
  story    open issue labelled `status:triage` (the planner's stories and bugs that need a decision);
           waiting since the issue was opened
  canvas   a pending UI handoff with a design canvas and `design_approved: false`; waiting since the
           handoff's last commit
  eyeball  open PR the reviewer approved that has no eyeball label; waiting since the verdict
  merge    open PR labelled `eyeball:pass` that has not merged; waiting since the label was added
  blocked  open issue labelled `status:blocked`; waiting since the label was added, reason is the
           issue's last comment

`build` is pure. `collect` reads GitHub and the checkout; the Overview refresher and the factory tick
(`python3 -m scripts.console inbox --markdown`) both call it, so they never disagree.

The pinned issue lives in a public repo, so `render_markdown` never carries the console access token.
"""
from __future__ import annotations

import json
import re
import time
from datetime import datetime
from pathlib import Path

from . import remote
from .config import CONFIG
from .gitops import CommandError, gh, run_captured

KINDS = ("story", "canvas", "eyeball", "merge", "blocked")
KIND_LABELS = {
    "story": "Story awaiting approval", "canvas": "Canvas awaiting approval", "eyeball": "PR awaiting eyeball",
    "merge": "PR ready to merge", "blocked": "Blocked story",
}
REASON_MAX_CHARS = 200
SECONDS_PER_MINUTE, SECONDS_PER_HOUR, SECONDS_PER_DAY = 60, 3600, 86400
EMPTY_MESSAGE = "Nothing is waiting on you."
STATE_MARKER = "<!-- inbox-state:"
_STATE_RE = re.compile(r"<!-- inbox-state: ([^>]*?) -->")


def parse_time(stamp: str | None) -> float | None:
    if not stamp:
        return None
    try:
        return datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def format_age(seconds: float) -> str:
    seconds = max(0, int(seconds))
    if seconds >= SECONDS_PER_DAY:
        days, rest = divmod(seconds, SECONDS_PER_DAY)
        return f"{days}d {rest // SECONDS_PER_HOUR}h"
    if seconds >= SECONDS_PER_HOUR:
        hours, rest = divmod(seconds, SECONDS_PER_HOUR)
        return f"{hours}h {rest // SECONDS_PER_MINUTE}m"
    return f"{seconds // SECONDS_PER_MINUTE}m"


def item_key(item: dict) -> str:
    return f"{item['kind']}:{item['ref']}"


def build(*, triage_issues: list[dict], canvases: list[dict], prs: list[dict], blocked_issues: list[dict],
          links: dict[str, str], now: float) -> list[dict]:
    """Items, oldest first. Inputs are plain dicts (see `collect`); an entry with no known start
    time is dated `now`, so it sorts last instead of vanishing."""
    items = []
    for i in triage_issues:
        items.append({"kind": "story", "ref": f"#{i['number']}", "number": i["number"], "title": i["title"],
                      "url": i["url"], "since": i.get("since") or now, "detail": None})
    for c in canvases:
        items.append({"kind": "canvas", "ref": c["story"], "number": None, "title": c["title"],
                      "url": c["url"], "since": c.get("since") or now, "detail": f"design_approved is false in {c['path']}"})
    for pr in prs:
        if pr["stage"] == "awaiting_eyeball":
            items.append({"kind": "eyeball", "ref": f"PR #{pr['number']}", "number": pr["number"], "title": pr["title"],
                          "url": pr["url"], "since": pr.get("since") or now, "detail": None,
                          "links": {"web": links.get("web"), "swagger": links.get("swagger"),
                                    "console": links.get("console")},
                          "command": f"scripts/eyeball-up.sh {pr['number']}"})
        elif pr["stage"] == "ready_to_merge":
            items.append({"kind": "merge", "ref": f"PR #{pr['number']}", "number": pr["number"], "title": pr["title"],
                          "url": pr["url"], "since": pr.get("since") or now, "detail": None})
    for i in blocked_issues:
        items.append({"kind": "blocked", "ref": f"#{i['number']}", "number": i["number"], "title": i["title"],
                      "url": i["url"], "since": i.get("since") or now,
                      "detail": i.get("reason") or "no reason commented"})
    items.sort(key=lambda it: (it["since"], it["kind"], it["ref"]))
    for it in items:
        it["age_seconds"] = max(0, int(now - it["since"]))
        it["age"] = format_age(it["age_seconds"])
    return items


# --- GitHub and checkout readers ----------------------------------------------------------------

def label_since(slug: str, number: int, label: str) -> float | None:
    """When `label` was last added to issue or PR `number`."""
    try:
        events = json.loads(gh("api", f"repos/{slug}/issues/{number}/events", "--paginate"))
    except (CommandError, json.JSONDecodeError):
        return None
    stamps = [parse_time(e.get("created_at")) for e in events
              if e.get("event") == "labeled" and (e.get("label") or {}).get("name") == label]
    stamps = [s for s in stamps if s is not None]
    return max(stamps) if stamps else None


def blocked_reason(slug: str, number: int) -> str | None:
    """First line of the issue's last comment: the factory comments the reason when it blocks a story."""
    try:
        data = json.loads(gh("issue", "view", str(number), "--repo", slug, "--json", "comments"))
    except (CommandError, json.JSONDecodeError):
        return None
    comments = data.get("comments") or []
    if not comments:
        return None
    lines = [ln.strip() for ln in (comments[-1].get("body") or "").splitlines() if ln.strip()]
    return lines[0][:REASON_MAX_CHARS] if lines else None


def waiting_canvases(root: Path) -> list[dict]:
    """Pending UI handoffs that have a canvas and no approval yet."""
    from .knowledge import _frontmatter  # noqa: PLC0415 - one private parser, same package

    features_dir = root / "specs" / "features"
    found = []
    if not features_dir.is_dir():
        return found
    for path in sorted(features_dir.rglob("*.md")):
        if "completed" in path.parts or path.parent.name == "_template":
            continue
        fm = _frontmatter(path.read_text(encoding="utf-8", errors="ignore"))
        if not (fm.get("ui") and fm.get("design_canvas") and not fm.get("design_approved")
                and fm.get("status") == "pending"):
            continue
        rel = path.relative_to(root)
        committed = run_captured(["git", "log", "-1", "--format=%ct", "--", str(rel)], cwd=root, check=False).stdout.strip()
        found.append({"story": str(fm.get("story") or path.stem), "title": str(fm.get("title") or path.stem),
                      "url": fm["design_canvas"], "path": str(rel),
                      "since": float(committed) if committed.isdigit() else None})
    return found


def eyeball_links(console_port: int) -> dict[str, str]:
    """The web, Swagger and console links `scripts/eyeball-up.sh` prints, without the access token."""
    return remote.urls(console_port)


def collect(slug: str, prs: list[dict], root: Path, console_port: int, now: float | None = None) -> list[dict]:
    """`prs`: open PRs as `{number, title, url, stage, since}` (see github.fetch_prs)."""
    now = time.time() if now is None else now
    issues = {}
    for label in ("status:triage", "status:blocked"):
        try:
            issues[label] = json.loads(gh("issue", "list", "--repo", slug, "--state", "open", "--label", label,
                                          "--limit", "100", "--json", "number,title,url,createdAt"))
        except (CommandError, json.JSONDecodeError):
            issues[label] = []
    triage = [{**i, "since": parse_time(i.get("createdAt"))} for i in issues["status:triage"]]
    blocked = [{**i, "since": label_since(slug, i["number"], "status:blocked") or parse_time(i.get("createdAt")),
                "reason": blocked_reason(slug, i["number"])} for i in issues["status:blocked"]]
    merge_ready = [{**pr, "since": label_since(slug, pr["number"], "eyeball:pass") or pr.get("since")}
                   if pr["stage"] == "ready_to_merge" else pr for pr in prs]
    return build(triage_issues=triage, canvases=waiting_canvases(root), prs=merge_ready, blocked_issues=blocked,
                 links=eyeball_links(console_port), now=now)


# --- rendering ----------------------------------------------------------------------------------

def render_markdown(items: list[dict]) -> str:
    """The pinned issue's body: the same list the Overview shows, oldest first. Ends with a hidden
    line of item keys so the tick can tell whether anything new arrived."""
    if not items:
        return f"{EMPTY_MESSAGE}\n\n{state_comment(items)}\n"
    lines = [f"{len(items)} item{'s' if len(items) != 1 else ''} waiting on you, oldest first.", ""]
    for it in items:
        lines.append(f"- **{it['age']}** · {KIND_LABELS[it['kind']]} · [{it['ref']}]({it['url']}) {it['title']}")
        if it.get("detail"):
            lines.append(f"  - {it['detail']}")
        if it["kind"] == "eyeball":
            lines.append(f"  - `{it['command']}` prints the tokenised console link")
            links = it.get("links") or {}
            lines.append("  - " + " · ".join(f"[{name}]({url})" for name, url in links.items() if url))
    lines += ["", state_comment(items)]
    return "\n".join(lines) + "\n"


def state_comment(items: list[dict]) -> str:
    return f"{STATE_MARKER} {json.dumps(sorted(item_key(i) for i in items))} -->"


def previous_keys(body: str) -> set[str]:
    match = _STATE_RE.search(body or "")
    if not match:
        return set()
    try:
        return set(json.loads(match.group(1)))
    except json.JSONDecodeError:
        return set()


def new_items(items: list[dict], previous: set[str]) -> list[dict]:
    return [i for i in items if item_key(i) not in previous]


PINNED_TITLE = "Waiting on you"
CREATED_BODY = "Written by `python3 -m scripts.console inbox --publish`."


def _find_or_create_issue(slug: str) -> int | None:
    """The open "Waiting on you" issue, created and pinned on first use."""
    found = json.loads(gh("issue", "list", "--repo", slug, "--state", "open", "--search",
                          f'in:title "{PINNED_TITLE}"', "--json", "number,title"))
    numbers = [i["number"] for i in found if i["title"] == PINNED_TITLE]
    if numbers:
        return numbers[0]
    url = gh("issue", "create", "--repo", slug, "--title", PINNED_TITLE, "--body", CREATED_BODY).strip()
    number = url.rsplit("/", 1)[-1]
    if not number.isdigit():
        return None
    run_captured(["gh", "issue", "pin", number, "--repo", slug], check=False)
    return int(number)


def publish(slug: str, items: list[dict]) -> str:
    """Write the list into the pinned issue's body. Edits send no notification, so when items have
    arrived since the last write, also comment on the issue and mention the owner."""
    body = render_markdown(items)
    number = _find_or_create_issue(slug)
    if number is None:
        return "could not create the issue"
    current = json.loads(gh("issue", "view", str(number), "--repo", slug, "--json", "body,comments"))
    arrived = new_items(items, previous_keys(current.get("body") or ""))
    if (current.get("body") or "").strip() != body.strip():
        gh("issue", "edit", str(number), "--repo", slug, "--body", body)
    if not arrived:
        return f"#{number} updated, nothing new"
    owner = slug.split("/", 1)[0]
    lines = [f"@{owner} {len(arrived)} new item{'s' if len(arrived) != 1 else ''} waiting on you:"]
    lines += [f"- {KIND_LABELS[i['kind']]}: {i['ref']} {i['title']}" for i in arrived]
    gh("issue", "comment", str(number), "--repo", slug, "--body", "\n".join(lines))
    return f"#{number} updated, commented {len(arrived)} new"


def main(fmt: str, console_port: int, publish_issue: bool = False) -> int:
    from .github import fetch_prs  # noqa: PLC0415 - github imports this module for the refresher
    from .gitops import repo

    slug = repo()
    items = collect(slug, fetch_prs(slug), CONFIG.root, console_port)
    if publish_issue:
        print(publish(slug, items))
    elif fmt == "json":
        print(json.dumps(items, indent=2))
    else:
        print(render_markdown(items), end="")
    return 0
