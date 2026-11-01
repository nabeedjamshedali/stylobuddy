#!/usr/bin/env python3
"""Enforce the project's architectural boundaries.

Each rule in .claude/harness.json -> "boundaries" names a set of guarded paths and the
patterns that must never appear in them (forbidden imports, vendor field names, I/O in
a pure layer, ...). A violation is the kind of design leak that passes every test and
only becomes expensive much later, so it is enforced by a machine, not by intention.

PostToolUse hook on Write/Edit. Exit code 2 feeds the violations back to Claude so the
change is corrected immediately. With no boundaries configured, it does nothing.
"""

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _harness import block, load_config, read_payload, relpath, under, warn  # noqa: E402


def main() -> int:
    payload = read_payload()
    file_path = (payload.get("tool_input") or {}).get("file_path", "")
    root, cfg = load_config()
    if cfg.get("_error"):
        return warn(f"[harness] {cfg['_error']}. Boundary rules are NOT enforced until it is fixed.")
    if not cfg.get("enabled", True) or not cfg.get("boundaries"):
        return 0

    rel = relpath(file_path, root)
    if rel is None:
        return 0

    content = None
    found = []
    fixes = []
    for rule in cfg["boundaries"]:
        if not isinstance(rule, dict) or not under(rel, rule.get("guarded_paths", [])):
            continue
        exts = tuple(rule.get("extensions") or ())
        if exts and not rel.endswith(exts):
            continue
        if content is None:
            try:
                content = Path(file_path).read_text(encoding="utf-8", errors="replace")
            except OSError:
                return 0
        hit = False
        for item in rule.get("forbidden", []):
            try:
                pattern = re.compile(item["pattern"], re.MULTILINE)
            except (KeyError, TypeError, re.error):
                continue  # a broken rule must not break the session
            for m in pattern.finditer(content):
                line = content[: m.start()].count("\n") + 1
                found.append((rule.get("name", "boundary"), line, m.group(0).strip()[:80], item.get("reason", "")))
                hit = True
        if hit and rule.get("fix"):
            fixes.append(f"[{rule.get('name', 'boundary')}] {rule['fix']}")

    if not found:
        return 0

    lines = [f"BOUNDARY VIOLATION in {rel}\n"]
    for name, line, snippet, reason in found:
        lines.append(f"  [{name}] line {line}: {snippet}")
        if reason:
            lines.append(f"      -> {reason}")
    lines.append("")
    lines.append("Do not reach around the boundary. Fix the design instead:")
    lines.extend(f"  {f}" for f in fixes or ["see docs/foundation/02-architecture.md"])
    return block("\n".join(lines))


if __name__ == "__main__":
    sys.exit(main())
