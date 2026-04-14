#!/usr/bin/env bash
# session-log — appends every tool call to a daily audit log
# Hook event: PostToolUse (matcher: *)
#
# Writes to ~/.claude/logs/YYYY-MM-DD.log
# Useful for reviewing what Claude did across sessions, debugging, and audits.

set -euo pipefail

INPUT=$(cat)

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)
LOG_FILE="$LOG_DIR/$DATE.log"

python3 - <<PYEOF
import sys, json, os, re

raw = """$INPUT"""
try:
    d = json.loads(raw)
except Exception:
    sys.exit(0)

tool   = d.get('tool_name', 'unknown')
ti     = d.get('tool_input', {})
result = d.get('tool_result', {})
cwd    = d.get('cwd', '')
sid    = d.get('session_id', '')[:8]

# Build a short, human-readable summary of the tool call
summary_parts = []

if tool == 'Bash':
    cmd = ti.get('command', '')
    # Truncate long commands
    summary_parts.append(cmd[:120] + ('...' if len(cmd) > 120 else ''))

elif tool in ('Edit', 'Write', 'Read'):
    fp = ti.get('file_path', ti.get('path', ''))
    summary_parts.append(fp)

elif tool == 'Glob':
    summary_parts.append(ti.get('pattern', ''))

elif tool == 'Grep':
    summary_parts.append(f"/{ti.get('pattern', '')}/ in {ti.get('path', '.')}")

elif tool == 'Agent':
    summary_parts.append(ti.get('description', ''))

else:
    # Generic: first string value in tool_input
    for v in ti.values():
        if isinstance(v, str) and v:
            summary_parts.append(v[:80])
            break

status = result.get('type', '') if isinstance(result, dict) else 'ok'
summary = ' | '.join(summary_parts) if summary_parts else ''

line = f"[$TIME] [{sid}] {tool:20s} [{status:7s}] {summary}\n"

with open("$LOG_FILE", 'a', encoding='utf-8') as f:
    f.write(line)
PYEOF

exit 0
