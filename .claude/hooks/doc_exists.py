#!/usr/bin/env python3
"""No document, no code.

Blocks CREATING an implementation file when no feature document with numbered
assertions exists. The project is built document-first: docs/README.md is the
contract, and code follows it. Editing existing files is always allowed.

PreToolUse hook on Write. Exit code 2 blocks. Configured by .claude/harness.json.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _harness import ASSERTION_RE, block, is_exempt, load_config, read_payload, relpath, under  # noqa: E402


def main() -> int:
    payload = read_payload()
    file_path = (payload.get("tool_input") or {}).get("file_path", "")
    root, cfg = load_config()
    if not cfg.get("enabled", True):
        return 0

    rel = relpath(file_path, root)
    if rel is None or not under(rel, cfg["code_paths"]) or is_exempt(rel, cfg["code_exempt"]):
        return 0
    if Path(file_path).exists():
        return 0  # editing existing code is fine; this guards creation

    features = root / cfg["features_dir"]
    if not features.is_dir():
        return 0  # harness not initialised for docs; nothing to enforce against

    docs = list(features.glob("F*.md"))
    if not docs:
        return block(
            "NO FEATURE DOCUMENT EXISTS.\n\n"
            f"You are creating {rel}, but {cfg['features_dir']}/ has no feature documents.\n"
            "This project is built document-first: write the feature document, including its\n"
            "numbered assertions (section 11), before any implementation.\n"
            f"Copy {cfg['features_dir']}/_TEMPLATE.md to start one. See docs/README.md."
        )

    if not any(ASSERTION_RE.search(d.read_text(encoding="utf-8", errors="replace")) for d in docs):
        return block(
            "NO ASSERTIONS WRITTEN.\n\n"
            f"You are creating {rel}, but no feature document contains numbered assertions\n"
            "(format F##-A##).\n\n"
            "Assertions define correctness independently of the implementation, so they must\n"
            "exist BEFORE code. Tests written after implementation confirm decisions rather\n"
            "than catching bugs. See docs/foundation/06-validation-contract.md."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
