#!/usr/bin/env bash
# bash-guard — blocks destructive shell commands before Claude executes them
# Hook event: PreToolUse (matcher: Bash)
#
# Blocks: rm -rf on root/home, disk formatting, fork bombs, raw disk writes,
#         shutdown/halt, mass chmod 777, and other unrecoverable operations.
# Warns:  sudo commands, large file deletions, pipe-to-shell patterns.

set -euo pipefail

INPUT=$(cat)

# Extract fields using Python3 (reliable cross-platform JSON parsing)
parse() {
  echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('command', ''))
" 2>/dev/null || echo ""
}

COMMAND=$(parse)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- Hard blocks (exit 2 = Claude sees the message and must not retry) --------

block() {
  echo "bash-guard: $1" >&2
  echo "" >&2
  echo "Blocked command: $COMMAND" >&2
  exit 2
}

# Root filesystem destruction
echo "$COMMAND" | grep -qP 'rm\s+(-\S*r\S*|-\S*f\S*\s+-\S*r\S*)\s+/' \
  && block "Blocked: recursive delete on root filesystem"

echo "$COMMAND" | grep -qP 'rm\s+(-\S*r\S*|-\S*f\S*\s+-\S*r\S*)\s+~' \
  && block "Blocked: recursive delete on home directory"

echo "$COMMAND" | grep -qP 'rm\s+(-\S*r\S*|-\S*f\S*\s+-\S*r\S*)\s+\.' \
  && block "Blocked: recursive delete starting from current directory"

# Disk operations
echo "$COMMAND" | grep -qP 'mkfs\.' \
  && block "Blocked: disk formatting (mkfs)"

echo "$COMMAND" | grep -qP 'dd\s+.*of=/dev/[sh]d' \
  && block "Blocked: raw disk write via dd"

echo "$COMMAND" | grep -qP '>\s*/dev/[sh]d' \
  && block "Blocked: direct write to raw block device"

echo "$COMMAND" | grep -qiP 'format\s+[a-z]:' \
  && block "Blocked: Windows drive format command"

# System control
echo "$COMMAND" | grep -qP '(shutdown|poweroff|halt)(\s|$)' \
  && block "Blocked: system shutdown command"

echo "$COMMAND" | grep -qP 'init\s+0' \
  && block "Blocked: system halt via init 0"

# Fork bomb pattern
echo "$COMMAND" | grep -qF ':(){:|:&};:' \
  && block "Blocked: fork bomb"

echo "$COMMAND" | grep -qP '\(\)\s*\{.*\|.*&.*\}' \
  && block "Blocked: potential fork bomb pattern"

# Mass permission change on root
echo "$COMMAND" | grep -qP 'chmod\s+-R\s+777\s+/' \
  && block "Blocked: recursive 777 chmod on root"

# Drop database (protect against accidental full wipes)
echo "$COMMAND" | grep -qiP 'drop\s+database\s+\w+' \
  && block "Blocked: DROP DATABASE — use a migration script instead"

echo "$COMMAND" | grep -qiP 'drop\s+schema\s+\w+.*cascade' \
  && block "Blocked: DROP SCHEMA CASCADE"

# --- Soft warnings (exit 0 + systemMessage shown to Claude) -------------------

warn() {
  python3 -c "
import json, sys
print(json.dumps({'continue': True, 'systemMessage': sys.argv[1]}))
" "bash-guard warning: $1"
  exit 0
}

# curl | bash / wget | bash patterns (supply chain risk)
echo "$COMMAND" | grep -qP '(curl|wget)\s+.*\|\s*(ba)?sh' \
  && warn "Pipe-to-shell detected. Verify the URL is trustworthy before running: $COMMAND"

# sudo with write to system paths
echo "$COMMAND" | grep -qP 'sudo\s+.*>\s*/etc/' \
  && warn "Writing to /etc via sudo. Double-check this is intentional."

# All clear
exit 0
