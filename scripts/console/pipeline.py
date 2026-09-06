"""Pure PR review-stage classification, shared by github.py (the Overview pipeline) and eyeball.py
(the same stage chip on each Eyeball candidate).

MunServ's `reviewer` and `design-reviewer` agents post their verdict with `gh pr review --comment
--body` (never `--approve` -- merging stays the user's call): that creates a PR *review* (state
COMMENTED), not a plain issue comment, and it is never a real GitHub approval -- so a PR's
`reviewDecision` must never be used for this. The verdict is the review body's last non-blank
line, written as bold markdown (`**APPROVE**`) and sometimes followed by a short parenthetical
(`**REQUEST CHANGES** (B1 rebase, B2 wording).`), per `.claude/agents/reviewer.md` and
`design-reviewer.md`.
"""
from __future__ import annotations

STAGES = ("in_progress", "in_review", "awaiting_eyeball", "ready_to_merge")


def _last_line(body: str) -> str:
    lines = [line.strip() for line in (body or "").strip().splitlines() if line.strip()]
    return lines[-1] if lines else ""


def _verdict(body: str) -> str | None:
    """APPROVE / REQUEST CHANGES / None, tolerating the reviewer's own markdown bold and a
    trailing parenthetical note on the verdict line."""
    line = _last_line(body).strip("*_ \t")
    if line.startswith("APPROVE"):
        return "APPROVE"
    if line.startswith("REQUEST CHANGES"):
        return "REQUEST CHANGES"
    return None


def classify_pr(labels: set[str], comments: list[dict]) -> str:
    """`labels` is a set of label names; `comments` is every comment and review on the PR (see
    github.pr_verdict_sources), as `{"body": str}`, in the order they were actually posted --
    oldest first -- since only the *latest* verdict counts: an implementer can push a fix and get
    re-reviewed."""
    if "eyeball:pass" in labels:
        return "ready_to_merge"

    verdicts = [c for c in comments if _verdict(c.get("body", ""))]
    latest_verdict = verdicts[-1] if verdicts else None
    design_comments = [c for c in comments if (c.get("body") or "").strip().startswith("Design review:")]
    latest_design = design_comments[-1] if design_comments else None

    code_approved = latest_verdict is not None and _verdict(latest_verdict["body"]) == "APPROVE"
    design_approved = latest_design is None or _verdict(latest_design["body"]) == "APPROVE"
    if code_approved and design_approved and "eyeball:fail" not in labels:
        return "awaiting_eyeball"

    if "status:review" in labels:
        return "in_review"
    if latest_verdict is not None and _verdict(latest_verdict["body"]) == "REQUEST CHANGES":
        return "in_review"

    return "in_progress"


STAGE_LABELS = {
    "in_progress": "In progress",
    "in_review": "In review",
    "awaiting_eyeball": "Awaiting eyeball",
    "ready_to_merge": "Ready to merge",
}
