#!/usr/bin/env python3
"""Validate domain/language.yaml against the code base.

Checks, per concept:
  1. Every Markdown file named in `file` exists in domain/.
  2. Every Kotlin identifier in `code.kotlin` resolves to a class/object/enum/interface
     declaration under backend/src/main/kotlin (fully qualified name).
  3. Every database table/enum in `code.db` is created by a migration.
  4. Every TypeScript identifier in `code.typescript` is exported somewhere under web/src.
  5. Every Dart identifier in `code.dart` is declared under mobile/lib.
  6. For each `values.<set>` that is a database enum, the migrations define exactly
     that set (CREATE TYPE plus ALTER TYPE ... ADD VALUE).
  7. For `issue_state`, `issue_type`, `member_status`: web and mobile declare the same set.
     A mismatch is an error unless the concept carries `drift_issue`, in which case it is a
     warning naming the issue.

Exit code 1 on any error. Run from the repository root:  python3 scripts/validate-domain-language.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
LANG = ROOT / "domain" / "language.yaml"
BACKEND = ROOT / "backend" / "src" / "main" / "kotlin"
MIGRATIONS = ROOT / "backend" / "src" / "main" / "resources" / "db" / "migration"
WEB = ROOT / "web" / "src"
MOBILE = ROOT / "mobile" / "lib"

errors: list[str] = []
warnings: list[str] = []


def kotlin_index() -> set[str]:
    names: set[str] = set()
    decl = re.compile(r"^\s*(?:public |internal |private )?(?:data |sealed |enum |abstract |open |value )*(?:class|object|interface)\s+(\w+)", re.M)
    for f in BACKEND.rglob("*.kt"):
        text = f.read_text(encoding="utf-8")
        pkg = re.search(r"^package\s+([\w.]+)", text, re.M)
        if not pkg:
            continue
        for m in decl.finditer(text):
            names.add(f"{pkg.group(1)}.{m.group(1)}")
        # Kotlin typealias and top-level functions are not tracked; classes only.
    return names


def migrations_text() -> str:
    return "\n".join(f.read_text(encoding="utf-8") for f in sorted(MIGRATIONS.glob("*.sql")))


def db_tables(sql: str) -> set[str]:
    return set(re.findall(r"CREATE TABLE (?:IF NOT EXISTS )?(\w+)", sql, re.I))


def db_enums(sql: str) -> dict[str, list[str]]:
    """Replay CREATE TYPE, ALTER TYPE ADD VALUE, ALTER TYPE RENAME TO and DROP TYPE in order."""
    sql = re.sub(r"--[^\n]*", "", sql)  # strip line comments; they may contain parentheses
    enums: dict[str, list[str]] = {}
    stmt = re.compile(
        r"CREATE TYPE (\w+) AS ENUM\s*\(([^)]*)\)"
        r"|ALTER TYPE (\w+) ADD VALUE (?:IF NOT EXISTS )?'([^']+)'"
        r"|ALTER TYPE (\w+) RENAME TO (\w+)"
        r"|DROP TYPE (?:IF EXISTS )?(\w+)",
        re.I | re.S,
    )
    for m in stmt.finditer(sql):
        if m.group(1):
            enums[m.group(1)] = re.findall(r"'([^']+)'", m.group(2))
        elif m.group(3):
            enums.setdefault(m.group(3), []).append(m.group(4))
        elif m.group(5):
            enums[m.group(6)] = enums.pop(m.group(5), [])
        elif m.group(7):
            enums.pop(m.group(7), None)
    return enums


def web_exports() -> set[str]:
    names: set[str] = set()
    pat = re.compile(r"^export\s+(?:const|type|interface|enum|function|class)\s+(\w+)", re.M)
    for f in WEB.rglob("*.ts*"):
        if "node_modules" in f.parts:
            continue
        names.update(pat.findall(f.read_text(encoding="utf-8", errors="ignore")))
    return names


def dart_decls() -> set[str]:
    names: set[str] = set()
    pat = re.compile(r"^(?:abstract |sealed |final )?(?:class|enum|mixin)\s+(\w+)", re.M)
    for f in MOBILE.rglob("*.dart"):
        if f.name.endswith((".g.dart", ".freezed.dart")):
            continue
        names.update(pat.findall(f.read_text(encoding="utf-8", errors="ignore")))
    return names


def web_union_values(type_name: str) -> list[str] | None:
    """Values of `export type X = 'a' | 'b'` or `export const X = ['a','b'] as const`."""
    for f in WEB.rglob("*.ts"):
        if "node_modules" in f.parts:
            continue
        text = f.read_text(encoding="utf-8", errors="ignore")
        m = re.search(rf"export type {type_name}\s*=\s*((?:\s*\|?\s*'[^']+')+)\s*;", text)
        if m:
            return re.findall(r"'([^']+)'", m.group(1))
        m = re.search(rf"export const {type_name.upper()}S?\s*=\s*\[([^\]]*)\]", text)
        if m:
            return re.findall(r"'([^']+)'", m.group(1))
    return None


def dart_enum_values(enum_name: str) -> list[str] | None:
    """Enum constants of `enum X { a, b; ... }`, converted from camelCase to snake_case."""
    for f in MOBILE.rglob("*.dart"):
        if f.name.endswith((".g.dart", ".freezed.dart")):
            continue
        text = f.read_text(encoding="utf-8", errors="ignore")
        m = re.search(rf"enum {enum_name}\s*\{{([^;}}]*)", text)
        if m:
            raw = [v.strip() for v in re.split(r",", m.group(1)) if v.strip() and not v.strip().startswith("//")]
            return [re.sub(r"(?<!^)(?=[A-Z])", "_", v).lower() for v in raw]
    return None


def main() -> int:
    data = yaml.safe_load(LANG.read_text(encoding="utf-8"))
    concepts: dict = data["concepts"]

    kt = kotlin_index()
    sql = migrations_text()
    tables, enums = db_tables(sql), db_enums(sql)
    ts = web_exports()
    dart = dart_decls()

    platform_enum = {  # domain value set -> (TypeScript type, Dart enum)
        "issue_state": ("IssueState", "IssueState"),
        "issue_type": ("IssueType", "IssueType"),
        "member_status": ("MemberStatus", "MemberStatus"),
    }

    for key, c in concepts.items():
        if not (ROOT / "domain" / c["file"]).exists():
            errors.append(f"{key}: missing domain/{c['file']}")
        code = c.get("code", {})
        for name in code.get("kotlin", []):
            if name not in kt:
                errors.append(f"{key}: Kotlin `{name}` not found under backend/src/main/kotlin")
        db = code.get("db", {}) or {}
        for t in db.get("tables", []) or []:
            if t not in tables:
                errors.append(f"{key}: table `{t}` not created by any migration")
        for e in db.get("enums", []) or []:
            if e not in enums:
                errors.append(f"{key}: database enum `{e}` not created by any migration")
        for name in code.get("typescript", []) or []:
            if name not in ts:
                errors.append(f"{key}: TypeScript `{name}` not exported under web/src")
        for name in code.get("dart", []) or []:
            if name not in dart:
                errors.append(f"{key}: Dart `{name}` not declared under mobile/lib")

        drift = c.get("drift_issue")
        for set_name, values in (c.get("values") or {}).items():
            canonical = list(values)
            if set_name in enums:
                db_set = enums[set_name]
                extra, missing = sorted(set(db_set) - set(canonical)), sorted(set(canonical) - set(db_set))
                if missing:
                    errors.append(f"{key}: database enum `{set_name}` lacks {missing}")
                if extra:
                    msg = f"{key}: database enum `{set_name}` has extra values {extra}"
                    (warnings if drift else errors).append(msg + (f" (tracked in #{drift})" if drift else ""))
            if set_name in platform_enum:
                ts_name, dart_name = platform_enum[set_name]
                for platform, got in (("web", web_union_values(ts_name)), ("mobile", dart_enum_values(dart_name))):
                    if got is None:
                        errors.append(f"{key}: could not read {platform} values for {set_name}")
                        continue
                    if sorted(got) != sorted(canonical):
                        msg = f"{key}: {platform} {set_name} = {sorted(got)}, canonical = {sorted(canonical)}"
                        (warnings if drift else errors).append(msg + (f" (tracked in #{drift})" if drift else ""))

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    print(f"\n{len(concepts)} concepts checked, {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
