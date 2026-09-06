"""Project configuration for the factory console.

Everything project-specific comes from scripts/console/project.yaml. Missing keys fall back to
sane defaults so the console still runs (with empty-state sections) against a repo that has not
written one yet. See scripts/console/README.md for the full key reference and how to install the
console into another project.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

import yaml


def repo_root() -> Path:
    """The console's own repository root, resolved via git rather than a fixed path depth so the
    package keeps working if it is copied to another project at a different nesting."""
    script_dir = Path(__file__).resolve().parent
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=script_dir, text=True,
                              capture_output=True)
        if out.returncode == 0:
            return Path(out.stdout.strip())
    except OSError:
        pass
    return script_dir.parent.parent


ROOT = repo_root()
CONSOLE_DIR = ROOT / "scripts" / "console"


def load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8")) if path.exists() else None


class Config:
    """Thin accessor over project.yaml with defaults; re-read on every access so an edited
    project.yaml takes effect without restarting the server."""

    def __init__(self, console_dir: Path = CONSOLE_DIR, root: Path = ROOT):
        self.console_dir = console_dir
        self.root = root

    def _raw(self) -> dict:
        return load_yaml(self.console_dir / "project.yaml") or {}

    @property
    def name(self) -> str:
        return self._raw().get("name") or self.root.name

    @property
    def repo(self) -> str | None:
        return self._raw().get("repo")

    @property
    def port(self) -> int:
        return int(self._raw().get("port", 3999))

    @property
    def accent(self) -> str:
        return self._raw().get("accent", "#2f6fed")

    @property
    def checkout_dir_name(self) -> str:
        return self._raw().get("checkout_dir", f"{self.name}-console")

    @property
    def checkout_dir(self) -> Path:
        return self.root.parent / self.checkout_dir_name

    @property
    def legacy_checkout_dir(self) -> Path:
        """The checkout directory name used before a project renamed `checkout_dir` (e.g. the old
        eyeball dashboard's `<name>-eyeball`). Reused in place of creating a second worktree when
        it already exists and the configured one does not -- see gitops.resolve_checkout_dir."""
        return self.root.parent / f"{self.name}-eyeball"

    @property
    def handoff_glob(self) -> str:
        return self._raw().get("handoff_glob", "specs/features")

    @property
    def story_label_prefix(self) -> str:
        return self._raw().get("story_label_prefix", "story:")

    @property
    def domain_language(self) -> Path:
        return self.root / self._raw().get("domain_language", "domain/language.yaml")

    @property
    def requirements_dir(self) -> Path:
        return self.root / self._raw().get("requirements_dir", "specs/requirements")

    @property
    def adr_dir(self) -> Path:
        return self.root / self._raw().get("adr_dir", "specs/architecture/decisions")

    @property
    def registry_dir(self) -> Path:
        return self.root / self._raw().get("registry_dir", "design/registry")

    @property
    def canvases_dir(self) -> Path:
        return self.root / self._raw().get("canvases_dir", "design/canvases")

    @property
    def tokens_path(self) -> Path:
        return self.root / self._raw().get("tokens", "design/tokens/color.tokens.json")

    @property
    def local_files(self) -> list[str]:
        """Paths (relative to the repo root) of untracked, machine-local config a fresh checkout
        never has -- a tool-version pin (mise/asdf) or a local override file -- copied in from the
        main repo on checkout and before Prepare/Start so the checkout under test behaves like the
        tester's own working copy instead of failing with e.g. `mise ERROR No version is set for
        shim: flutter`. See gitops.copy_local_files."""
        return self._raw().get("local_files") or [
            "mise.local.toml",
            ".tool-versions",
            ".mise.toml",
            "backend/src/main/resources/application-local.yml",
            "web/.env",
        ]

    @property
    def changelog(self) -> Path:
        return self.root / self._raw().get("changelog", "CHANGELOG.md")

    @property
    def links(self) -> dict:
        return self._raw().get("links") or {}

    @property
    def sections(self) -> dict:
        """Section id -> enabled. Any section not listed defaults to enabled."""
        return self._raw().get("sections") or {}

    def section_enabled(self, section_id: str) -> bool:
        return bool(self.sections.get(section_id, True))

    @property
    def services_config(self) -> dict:
        return load_yaml(self.console_dir / "services.yaml") or {}

    @property
    def accounts_config(self) -> dict:
        return load_yaml(self.console_dir / "accounts.yaml") or {}

    @property
    def smoke_config(self) -> list:
        return load_yaml(self.console_dir / "smoke.yaml") or []


CONFIG = Config()
