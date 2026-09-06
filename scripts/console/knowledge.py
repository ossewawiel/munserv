"""Read-only knowledge base: domain language, requirements, ADRs, design canvases and registry,
and colour tokens. Every function tolerates a missing file or directory and returns an empty
result rather than raising, so a project that has not written one of these yet still renders (the
UI shows an empty state with a hint).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import yaml

from .config import CONFIG


def domain_concepts() -> list[dict]:
    path = CONFIG.domain_language
    if not path.exists():
        return []
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    concepts = data.get("concepts") or {}
    out = []
    for name, body in concepts.items():
        out.append({
            "name": name,
            "definition": (body or {}).get("definition", ""),
            "values": (body or {}).get("values") or {},
            "code": (body or {}).get("code") or {},
            "relationships": (body or {}).get("relationships") or {},
        })
    out.sort(key=lambda c: c["name"])
    return out


_ROW_RE = re.compile(r"^\|(.+)\|\s*$")
_STATUS_RE = re.compile(r"🟢|🟡|🔴")
_STATUS_NAME = {"🟢": "done", "🟡": "in_progress", "🔴": "pending"}


def _parse_table(lines: list[str]) -> tuple[list[str], list[list[str]]]:
    """A minimal GitHub-flavoured markdown table parser: header, a `---` separator, then rows."""
    rows = [_ROW_RE.match(l) for l in lines]
    rows = [r for r in rows if r]
    if len(rows) < 2:
        return [], []
    header = [c.strip() for c in rows[0].group(1).split("|")]
    body = []
    for r in rows[2:]:
        body.append([c.strip() for c in r.group(1).split("|")])
    return header, body


def requirements_summary() -> list[dict]:
    """One entry per specs/requirements/*.md file: counts by status, plus the parsed rows for the
    expandable detail view."""
    reqs_dir = CONFIG.requirements_dir
    if not reqs_dir.is_dir():
        return []
    out = []
    for path in sorted(reqs_dir.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        tables: list[list[str]] = []
        i = 0
        while i < len(lines):
            if lines[i].strip().startswith("|") and i + 1 < len(lines) and set(lines[i + 1].strip()) <= set("|-: "):
                j = i
                block = []
                while j < len(lines) and lines[j].strip().startswith("|"):
                    block.append(lines[j])
                    j += 1
                header, body = _parse_table(block)
                if header and any("status" in h.lower() or "story" in h.lower() for h in header):
                    tables.append((header, body))
                i = j
            else:
                i += 1
        rows = []
        counts = {"done": 0, "in_progress": 0, "pending": 0, "unknown": 0}
        for header, body in tables:
            status_idx = next((idx for idx, h in enumerate(header) if h.lower() == "status"), None)
            for r in body:
                status_raw = r[status_idx] if status_idx is not None and status_idx < len(r) else ""
                m = _STATUS_RE.search(status_raw)
                key = _STATUS_NAME.get(m.group(0), "unknown") if m else "unknown"
                counts[key] += 1
                rows.append(dict(zip(header, r)))
        out.append({
            "file": path.name, "title": path.stem.capitalize(), "counts": counts, "rows": rows,
        })
    return out


def adr_list() -> list[dict]:
    adr_dir = CONFIG.adr_dir
    if not adr_dir.is_dir():
        return []
    out = []
    for path in sorted(adr_dir.glob("*.md")):
        if path.name.lower() == "readme.md":
            continue
        text = path.read_text(encoding="utf-8")
        title = path.stem
        for line in text.splitlines():
            if line.strip().startswith("#"):
                title = line.lstrip("#").strip()
                break
        out.append({"file": path.name, "title": title})
    return out


def registry_pages() -> list[dict]:
    reg_dir = CONFIG.registry_dir
    if not reg_dir.is_dir():
        return []
    out = []
    for path in sorted(reg_dir.glob("*.md")):
        out.append({"file": path.name, "platform": path.stem, "markdown": path.read_text(encoding="utf-8")})
    return out


def color_tokens() -> dict:
    path = CONFIG.tokens_path
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


_FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.S)


def _frontmatter(text: str) -> dict:
    m = _FRONTMATTER_RE.match(text)
    if not m:
        return {}
    try:
        return yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError:
        return {}


def design_canvases() -> list[dict]:
    """Canvases discovered from design/canvases/**/canvas.json, cross-referenced against handoff
    frontmatter (design_canvas / design_artboards / design_approved) so each feature shows an
    approval chip alongside its artboards."""
    canvases_dir = CONFIG.canvases_dir
    root = CONFIG.root
    handoffs_by_feature: dict[str, dict] = {}
    features_dir = root / "specs" / "features"
    if features_dir.is_dir():
        for path in features_dir.rglob("*.md"):
            fm = _frontmatter(path.read_text(encoding="utf-8", errors="ignore"))
            if fm.get("design_canvas"):
                feature = path.parent.name if path.parent.name not in ("completed",) else path.parent.parent.name
                entry = handoffs_by_feature.setdefault(feature, {"canvas_url": None, "approved": False, "artboards": set()})
                entry["canvas_url"] = fm.get("design_canvas")
                entry["approved"] = entry["approved"] or bool(fm.get("design_approved"))
                for ab in fm.get("design_artboards") or []:
                    entry["artboards"].add(ab)

    out = []
    if canvases_dir.is_dir():
        for feature_dir in sorted(p for p in canvases_dir.iterdir() if p.is_dir()):
            canvas_json = feature_dir / "canvas.json"
            artboards = []
            if canvas_json.exists():
                try:
                    data = json.loads(canvas_json.read_text(encoding="utf-8"))
                    artboards = [{"file": a.get("file"), "title": a.get("title", "")} for a in data.get("artboards", [])]
                except json.JSONDecodeError:
                    artboards = []
            meta = handoffs_by_feature.pop(feature_dir.name, {})
            out.append({
                "feature": feature_dir.name, "artboards": artboards,
                "canvas_url": meta.get("canvas_url"), "approved": bool(meta.get("approved")),
            })
    # Features with handoff frontmatter but no canvas.json directory yet still show up.
    for feature, meta in handoffs_by_feature.items():
        out.append({
            "feature": feature,
            "artboards": [{"file": a, "title": ""} for a in sorted(meta["artboards"])],
            "canvas_url": meta.get("canvas_url"), "approved": bool(meta.get("approved")),
        })
    return out
