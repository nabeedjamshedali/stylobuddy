#!/usr/bin/env python3
"""A worker never finishes by saying "done".

Blocks stopping when implementation files changed but no structured handoff was
written. The handoff -- above all its "Not completed" section -- is what lets the
orchestrator catch a problem at a milestone boundary instead of at the end.

Stop hook. Exit code 2 blocks stopping once; a second stop always goes through
(stop_hook_active), so it can never trap a session.
"""

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _harness import block, is_exempt, load_config, read_payload, under  # noqa: E402

REQUIRED_SECTIONS = ("## Completed", "## Not completed", "## Commands run", "## Assertions")


def changed_files(root: Path) -> list[str]:
    try:
        out = subprocess.run(
            ["git", "status", "--porcelain", "--untracked-files=all"],
            cwd=root, capture_output=True, text=True, timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return []
    if out.returncode != 0:
        return []
    files = []
    for line in out.stdout.splitlines():
        path = line[3:].strip()
        if " -> " in path:  # rename: keep the new name
            path = path.split(" -> ", 1)[1]
        files.append(path.strip('"'))
    return files


def main() -> int:
    payload = read_payload()
    if payload.get("stop_hook_active"):
        return 0  # never block a stop that is already the result of a blocked stop

    root, cfg = load_config()
    if not cfg.get("enabled", True):
        return 0

    implementation = [
        f for f in changed_files(root)
        if under(f, cfg["code_paths"]) and not is_exempt(f, cfg["code_exempt"]) and not f.endswith(".md")
    ]
    if not implementation:
        return 0

    handoffs = root / cfg["handoffs_dir"]
    docs = list(handoffs.glob("F*.md")) if handoffs.is_dir() else []
    template = f"{cfg['handoffs_dir']}/_TEMPLATE.md"
    if not docs:
        return block(
            "NO HANDOFF WRITTEN.\n\n"
            f"{len(implementation)} implementation file(s) changed, but {cfg['handoffs_dir']}/ has no handoff.\n\n"
            f"Write {cfg['handoffs_dir']}/F<NN>.md before finishing (copy {template}). It must record:\n"
            "  ## Completed\n"
            "  ## Not completed      <- what you did NOT finish, honestly\n"
            "  ## Commands run       <- with exit codes\n"
            "  ## Issues discovered\n"
            "  ## Assertions         <- n/n PASS\n"
            "  ## Procedures followed\n\n"
            "See docs/foundation/08-agent-harness.md section 6."
        )

    latest = max(docs, key=lambda p: p.stat().st_mtime)
    text = latest.read_text(encoding="utf-8", errors="replace")
    missing = [s for s in REQUIRED_SECTIONS if s not in text]
    if missing:
        return block(
            f"INCOMPLETE HANDOFF: {latest.name}\n\n"
            f"Missing section(s): {', '.join(missing)}\n\n"
            "A handoff that omits what was left undone is the one that costs most later.\n"
            "See docs/foundation/08-agent-harness.md section 6."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
