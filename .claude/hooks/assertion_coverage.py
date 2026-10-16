#!/usr/bin/env python3
"""Report assertion coverage while a feature's tests are being written.

Every assertion in a feature document needs a test whose name contains its ID
(F13-A07 -> test_F13_A07_...). After a test file is edited, this tells Claude which
assertions of that feature still have no test.

Advisory, never blocking: the contract-auditor is the enforcing check. This exists to
surface gaps early, while the feature is still in context.

PostToolUse hook on Write/Edit. Always exits 0.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _harness import (  # noqa: E402
    ASSERTION_RE,
    FEATURE_IN_NAME_RE,
    TEST_ID_RE,
    load_config,
    read_payload,
    relpath,
    under,
    walk_files,
)


def main() -> int:
    payload = read_payload()
    file_path = (payload.get("tool_input") or {}).get("file_path", "")
    root, cfg = load_config()
    if not cfg.get("enabled", True):
        return 0

    rel = relpath(file_path, root)
    if rel is None or not under(rel, cfg["test_paths"]):
        return 0
    match = FEATURE_IN_NAME_RE.search(Path(file_path).name)
    if not match:
        return 0
    feature = match.group(1).upper()

    doc = next((root / cfg["features_dir"]).glob(f"{feature}-*.md"), None)
    if doc is None:
        return 0
    declared = {f"{f}-{a}" for f, a in ASSERTION_RE.findall(doc.read_text(encoding="utf-8", errors="replace"))}
    declared = {d for d in declared if d.startswith(feature + "-")}
    if not declared:
        return 0

    covered = set()
    for test_file in walk_files(root, cfg["test_paths"]):
        try:
            text = test_file.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        covered.update(f"{f}-{a}" for f, a in TEST_ID_RE.findall(text))

    missing = sorted(declared - covered)
    if missing:
        msg = (f"[assertion coverage] {feature}: {len(declared) - len(missing)}/{len(declared)} "
               f"assertions have tests. Still needed: {', '.join(missing)}")
    else:
        msg = f"[assertion coverage] {feature}: all {len(declared)} assertions have tests."

    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
