#!/usr/bin/env python3
"""Mirror GitHub issues onto the "MunServ Factory" project board (project 5).

Every open issue is added to the board; its Status column follows the status:* label
(ready -> Ready, in-progress -> In Progress, review -> In Review, blocked -> Blocked);
closed issues that are on the board move to Done. Idempotent; safe to run after every
factory run or merge. Needs `gh` with the `project` scope.
"""
from __future__ import annotations

import json
import subprocess

OWNER = "ossewawiel"
REPO = "ossewawiel/munserv"
PROJECT = 5
PROJECT_ID = "PVT_kwHOAKW5es4BiiqB"
STATUS_FIELD = "PVTSSF_lAHOAKW5es4BiiqBzhhaVvg"
OPTIONS = {"Ready": "453c9e8f", "In Progress": "674f7c91", "In Review": "925416f6", "Blocked": "ed5a2654", "Done": "9a6f613f"}
LABEL_TO_STATUS = {"status:ready": "Ready", "status:in-progress": "In Progress", "status:review": "In Review", "status:blocked": "Blocked", "status:done": "Done"}


def run(*args: str) -> str:
    return subprocess.check_output(["gh", *args], text=True)


def main() -> int:
    items = json.loads(run("project", "item-list", str(PROJECT), "--owner", OWNER, "--format", "json", "--limit", "500"))["items"]
    on_board = {it["content"]["number"]: it for it in items if it.get("content", {}).get("type") == "Issue"}

    issues = json.loads(run("issue", "list", "--repo", REPO, "--state", "all", "--limit", "300", "--json", "number,state,labels,url"))
    changed = 0
    for issue in issues:
        n = issue["number"]
        labels = {l["name"] for l in issue["labels"]}
        if issue["state"] == "CLOSED":
            want = "Done"
            if n not in on_board:
                continue  # closed issues are only tracked if they were already on the board
        else:
            want = next((LABEL_TO_STATUS[l] for l in LABEL_TO_STATUS if l in labels), None)
            if want is None:
                continue  # untriaged issues stay off the board
        item = on_board.get(n)
        if item is None:
            out = json.loads(run("project", "item-add", str(PROJECT), "--owner", OWNER, "--url", issue["url"], "--format", "json"))
            item = {"id": out["id"], "status": None}
            on_board[n] = item
        current = item.get("status")
        if current != want:
            run("project", "item-edit", "--project-id", PROJECT_ID, "--id", item["id"], "--field-id", STATUS_FIELD, "--single-select-option-id", OPTIONS[want])
            changed += 1
            print(f"#{n}: {current or 'new'} -> {want}")
    print(f"{changed} items updated; board: https://github.com/users/{OWNER}/projects/{PROJECT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
