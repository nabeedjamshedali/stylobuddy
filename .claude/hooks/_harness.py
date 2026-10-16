"""Shared helpers for the harness hooks.

Standard library only, so the hooks run on any machine with Python 3.8+ and no installs.

Every helper fails OPEN: a missing config, unreadable file or malformed payload makes
the hook allow the action rather than block it. A guard that bricks the session on its
own bug teaches people to delete the guard.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

# Feature IDs are F01, F02 ... F999. Assertions are F13-A07; tests name them F13_A07.
# Lookarounds, not \b: in "test_F13_A07_x" the "_" before "F" is a word character, so
# \b never matches there and every test would silently count as uncovered.
ASSERTION_RE = re.compile(r"(?<![A-Za-z0-9])(F\d{2,3})-(A\d{2,3})(?!\d)")
TEST_ID_RE = re.compile(r"(?<![A-Za-z0-9])(F\d{2,3})_(A\d{2,3})(?!\d)")
FEATURE_IN_NAME_RE = re.compile(r"(f\d{2,3})", re.IGNORECASE)

DEFAULTS: dict = {
    "enabled": True,
    "features_dir": "docs/features",
    "handoffs_dir": ".memory/handoffs",
    "code_paths": ["src"],
    "code_exempt": ["__init__.py", "conftest.py", "/migrations/", "/tests/", "/test/"],
    "test_paths": ["tests"],
    "boundaries": [],
}

SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", ".next", "target"}


def repo_root() -> Path:
    env = os.environ.get("CLAUDE_PROJECT_DIR")
    if env:
        return Path(env)
    return Path(__file__).resolve().parents[2]  # .claude/hooks/<this> -> repo


def load_config() -> tuple[Path, dict]:
    """Config merged over DEFAULTS. A broken file is reported in cfg["_error"] rather than
    swallowed: silently falling back would quietly switch off every boundary rule."""
    root = repo_root()
    cfg = dict(DEFAULTS)
    cfg["_error"] = None
    try:
        data = json.loads((root / ".claude" / "harness.json").read_text(encoding="utf-8"))
        if isinstance(data, dict):
            cfg.update(data)
        else:
            cfg["_error"] = ".claude/harness.json must contain a JSON object"
    except FileNotFoundError:
        pass
    except (OSError, ValueError) as exc:
        cfg["_error"] = f".claude/harness.json is invalid ({exc}); guards are running on defaults"
    return root, cfg


def warn(message: str, event: str = "PostToolUse") -> int:
    """Tell Claude something without blocking it (JSON on stdout, exit 0)."""
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": message}}))
    return 0


def read_payload() -> dict:
    try:
        data = json.load(sys.stdin)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def relpath(path: str, root: Path) -> str | None:
    """Repo-relative POSIX path, or None when the file is outside the repo."""
    if not path:
        return None
    absolute = os.path.abspath(path)
    base = os.path.abspath(str(root))
    if os.path.normcase(absolute).startswith(os.path.normcase(base) + os.sep):
        return absolute[len(base) + 1 :].replace("\\", "/")
    return None


def _norm(s: str) -> str:
    s = s.replace("\\", "/").strip("/")
    return s.lower() if os.name == "nt" else s


def under(rel: str, prefixes: list[str]) -> bool:
    r = _norm(rel)
    for p in prefixes:
        p = _norm(p)
        if p == "" or r == p or r.startswith(p + "/"):
            return True
    return False


def is_exempt(rel: str, exempt: list[str]) -> bool:
    """True when any exempt fragment ("/tests/", "__init__.py") occurs in the path."""
    fold = (lambda s: s.lower()) if os.name == "nt" else (lambda s: s)
    probe = fold("/" + rel.replace("\\", "/"))
    return any(e and fold(e.replace("\\", "/")) in probe for e in exempt)


def walk_files(root: Path, prefixes: list[str]):
    for prefix in prefixes:
        base = root / prefix
        if not base.is_dir():
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for name in filenames:
                yield Path(dirpath) / name


def block(message: str) -> int:
    """Exit code 2 blocks the action and feeds stderr back to Claude."""
    print(message, file=sys.stderr)
    return 2
