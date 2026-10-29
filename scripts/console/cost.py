"""Cost section: spend and tokens from the Claude Code OTLP metrics the telemetry collector writes
(infrastructure/telemetry, `docker compose --profile telemetry up -d`), grouped by day, agent, model
and story. Read-only.

Claude Code exports `claude_code.cost.usage` (USD) and `claude_code.token.usage` (tokens, split by
`type`) as delta sums. Every data point carries `model`, and subagent requests carry `agent.name`
(the real name only when the run sets OTEL_LOG_TOOL_DETAILS=1; otherwise user-defined agents all
read `custom`). The story comes from `OTEL_RESOURCE_ATTRIBUTES=story.id=<id>` on the run.
"""
from __future__ import annotations

import json
import threading
from datetime import datetime
from pathlib import Path

from .config import CONFIG

COST_METRIC = "claude_code.cost.usage"
TOKEN_METRIC = "claude_code.token.usage"
TOKEN_TYPES = ("input", "output", "cacheRead", "cacheCreation")
MAIN_AGENT = "main"
NO_STORY = "none"

_lock = threading.Lock()
_cache: dict = {"key": None, "snapshot": None}


def _attr_map(attributes: list[dict]) -> dict[str, object]:
    out: dict[str, object] = {}
    for a in attributes or []:
        value = a.get("value") or {}
        out[a["key"]] = next(iter(value.values()), None)
    return out


def _point_value(point: dict) -> float:
    return float(point.get("asDouble", point.get("asInt", 0)) or 0)


def _empty() -> dict:
    return {"cost": 0.0, "tokens": dict.fromkeys(TOKEN_TYPES, 0)}


def _add(group: dict, key: str, metric: str, value: float, token_type: str | None) -> None:
    bucket = group.setdefault(key, _empty())
    if metric == COST_METRIC:
        bucket["cost"] += value
    elif token_type in TOKEN_TYPES:
        bucket["tokens"][token_type] += int(value)


def _read_lines(path: Path):
    """JSONL lines of a file the collector may still be appending to. A truncated or NUL-padded
    line is skipped, never raised."""
    try:
        raw = path.read_bytes()
    except OSError:
        return
    for line in raw.replace(b"\0", b"").decode("utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            yield json.loads(line)
        except ValueError:
            continue


def _day(point: dict) -> str:
    nanos = int(point.get("timeUnixNano") or point.get("startTimeUnixNano") or 0)
    return datetime.fromtimestamp(nanos / 1e9).strftime("%Y-%m-%d")


def aggregate(path: Path) -> dict:
    """Group the cost and token delta points in one metrics.jsonl file."""
    groups: dict[str, dict] = {"day": {}, "agent": {}, "model": {}, "story": {}}
    total = _empty()
    for doc in _read_lines(path):
        for rm in doc.get("resourceMetrics", []):
            resource = _attr_map(rm.get("resource", {}).get("attributes", []))
            for sm in rm.get("scopeMetrics", []):
                for metric in sm.get("metrics", []):
                    name = metric.get("name")
                    if name not in (COST_METRIC, TOKEN_METRIC):
                        continue
                    for point in (metric.get("sum") or {}).get("dataPoints", []):
                        attrs = _attr_map(point.get("attributes", []))
                        value = _point_value(point)
                        token_type = attrs.get("type")
                        keys = {
                            "day": _day(point),
                            "agent": str(attrs.get("agent.name") or MAIN_AGENT),
                            "model": str(attrs.get("model") or "unknown"),
                            "story": str(attrs.get("story.id") or resource.get("story.id") or NO_STORY),
                        }
                        for dimension, key in keys.items():
                            _add(groups[dimension], key, name, value, token_type)
                        _add({"all": total}, "all", name, value, token_type)
    return {"total": total, **{dimension: _rows(group) for dimension, group in groups.items()}}


def _rows(group: dict) -> list[dict]:
    rows = [{"key": key, **bucket} for key, bucket in group.items()]
    return sorted(rows, key=lambda r: r["key"], reverse=True) if _is_days(group) \
        else sorted(rows, key=lambda r: r["cost"], reverse=True)


def _is_days(group: dict) -> bool:
    return bool(group) and all(len(k) == 10 and k[4] == "-" and k[7] == "-" for k in group)


def get_snapshot() -> dict:
    """The aggregate for the configured telemetry directory, recomputed only when the file changed."""
    path = CONFIG.telemetry_dir / "metrics.jsonl"
    try:
        stat = path.stat()
        key = (stat.st_mtime_ns, stat.st_size)
    except OSError:
        return {"available": False, "path": str(path), "total": _empty(),
                "day": [], "agent": [], "model": [], "story": []}
    with _lock:
        if _cache["key"] != (str(path), key):
            _cache["snapshot"] = {"available": True, "path": str(path), **aggregate(path)}
            _cache["key"] = (str(path), key)
        return _cache["snapshot"]
