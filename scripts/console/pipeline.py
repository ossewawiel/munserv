"""Pure PR review-stage classification, shared by github.py (the Overview pipeline) and eyeball.py
(the same stage chip on each Eyeball candidate).

MunServ's `reviewer` and `design-reviewer` agents post their verdict with `gh pr review --comment
--body` (never `--approve` -- merging stays the user's call): that creates a PR *review* (state
COMMENTED), not a plain issue comment, and it is never a real GitHub approval -- so a PR's
`reviewDecision` must never be used for this.

The literal word APPROVE or REQUEST CHANGES is the sentinel (`.claude/agents/reviewer.md`,
`design-reviewer.md`), but its exact placement on the line varies in practice: a bare bold line
(`**APPROVE**`), a line ending in a dash-suffixed aside (`APPROVE — merging is the user's call.`),
a trailing parenthetical (`**REQUEST CHANGES** (B1 rebase, B2 wording).`), or a markdown heading
that names the verdict at the end (`## Reviewer verdict: APPROVE`, `## Reviewer verdict
(re-verify): APPROVE`). Rather than anchor to one shape, a line "has a verdict" whenever APPROVE
or REQUEST CHANGES appears in it as a whole word (case-sensitive: these are the two exact tokens
the agents are instructed to write, so this never fires on ordinary prose like "the fix looks
good"); the *last* such line in the body wins, in case a line is quoted or referenced earlier. A
body with no such line anywhere (a bot's lint comment, a mid-review discussion note) is ignored
entirely for classification -- it is not a "no verdict" review, it is not a review at all.
"""
from __future__ import annotations

import re

STAGES = ("in_progress", "in_review", "awaiting_eyeball", "ready_to_merge")

_VERDICT_RE = re.compile(r"\b(APPROVE|REQUEST CHANGES)\b")


def _verdict(body: str) -> str | None:
    """The verdict named by the last matching line in `body`, or None if no line names one."""
    result = None
    for line in (body or "").splitlines():
        matches = list(_VERDICT_RE.finditer(line))
        if matches:
            result = matches[-1].group(1)
    return result


def classify_pr(labels: set[str], comments: list[dict]) -> str:
    """`labels` is a set of label names; `comments` is every comment and review on the PR (see
    github.pr_verdict_sources), as `{"body": str}`, in the order they were actually posted --
    oldest first -- since only the *latest* verdict counts: an implementer can push a fix and get
    re-reviewed, and a bot's lint comment can land after the review without being one."""
    if "eyeball:pass" in labels:
        return "ready_to_merge"

    verdicts = [c for c in comments if _verdict(c.get("body", ""))]
    latest_verdict = verdicts[-1] if verdicts else None
    design_comments = [c for c in verdicts if (c.get("body") or "").strip().startswith("Design review:")]
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
