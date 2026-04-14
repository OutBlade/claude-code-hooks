#!/usr/bin/env python3
"""
Merges claude-code-hooks entries into ~/.claude/settings.json
without overwriting existing configuration.
"""

import json
import os
import sys
import shutil
from datetime import datetime

HOOKS_DIR = os.path.expanduser("~/.claude/hooks")
SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")

def hook_cmd(name):
    path = os.path.join(HOOKS_DIR, name)
    # On Windows Git Bash, use bash explicitly
    return f'bash "{path}"'

HOOK_CONFIG = {
    "PreToolUse": [
        {
            "matcher": "Bash",
            "hooks": [
                {"type": "command", "command": hook_cmd("bash-guard.sh")},
                {"type": "command", "command": hook_cmd("git-guard.sh")},
            ],
        },
        {
            "matcher": "Edit|Write",
            "hooks": [
                {"type": "command", "command": hook_cmd("secret-guard.sh")},
            ],
        },
    ],
    "PostToolUse": [
        {
            "matcher": "Edit|Write",
            "hooks": [
                {"type": "command", "command": hook_cmd("auto-format.sh")},
                {"type": "command", "command": hook_cmd("session-log.sh")},
            ],
        },
        {
            # Log all other tool calls too
            "matcher": "Bash|Read|Glob|Grep|Agent",
            "hooks": [
                {"type": "command", "command": hook_cmd("session-log.sh")},
            ],
        },
    ],
    "Stop": [
        {
            "hooks": [
                {"type": "command", "command": hook_cmd("notify.sh")},
            ],
        }
    ],
}

def merge_hook_list(existing: list, additions: list) -> list:
    """Append new matchers; skip if an identical command already exists."""
    existing_commands = set()
    for entry in existing:
        for h in entry.get("hooks", []):
            existing_commands.add(h.get("command", ""))

    merged = list(existing)
    for entry in additions:
        new_hooks = [
            h for h in entry.get("hooks", [])
            if h.get("command", "") not in existing_commands
        ]
        if new_hooks:
            merged.append({**entry, "hooks": new_hooks})
    return merged


def main():
    # Load existing settings
    if os.path.exists(SETTINGS_PATH):
        with open(SETTINGS_PATH, "r", encoding="utf-8") as f:
            try:
                settings = json.load(f)
            except json.JSONDecodeError:
                print(f"ERROR: {SETTINGS_PATH} is not valid JSON. Fix it manually first.")
                sys.exit(1)
        # Backup
        backup = SETTINGS_PATH + "." + datetime.now().strftime("%Y%m%d%H%M%S") + ".bak"
        shutil.copy2(SETTINGS_PATH, backup)
        print(f"Backed up existing settings to {backup}")
    else:
        settings = {}

    hooks_section = settings.setdefault("hooks", {})

    for event, entries in HOOK_CONFIG.items():
        existing = hooks_section.get(event, [])
        hooks_section[event] = merge_hook_list(existing, entries)

    with open(SETTINGS_PATH, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")

    print(f"Updated {SETTINGS_PATH}")
    print("Hook events registered:")
    for event in HOOK_CONFIG:
        print(f"  {event}")


if __name__ == "__main__":
    main()
