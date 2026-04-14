#!/usr/bin/env bash
# auto-format — runs the appropriate code formatter after a file is edited
# Hook event: PostToolUse (matcher: Edit|Write)
#
# Supports: prettier (JS/TS/CSS/HTML/JSON/YAML/MD), black/ruff (Python),
#           gofmt (Go), rustfmt (Rust), shfmt (Shell).
# Silently skips if no formatter is installed for the file type.

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null || echo "")

# Skip if no file path or file doesn't exist
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

EXT="${FILE_PATH##*.}"
FORMATTED=0
FORMATTER=""

run_if_available() {
  local cmd="$1"
  if command -v "$cmd" &>/dev/null; then
    return 0
  fi
  return 1
}

case "$EXT" in
  js|jsx|mjs|cjs|ts|tsx|css|scss|less|html|json|yaml|yml|md|mdx)
    if run_if_available prettier; then
      prettier --write "$FILE_PATH" &>/dev/null && FORMATTED=1 && FORMATTER="prettier"
    fi
    ;;

  py)
    if run_if_available ruff; then
      ruff format "$FILE_PATH" &>/dev/null && FORMATTED=1 && FORMATTER="ruff"
    elif run_if_available black; then
      black -q "$FILE_PATH" &>/dev/null && FORMATTED=1 && FORMATTER="black"
    fi
    ;;

  go)
    if run_if_available gofmt; then
      gofmt -w "$FILE_PATH" &>/dev/null && FORMATTED=1 && FORMATTER="gofmt"
    fi
    ;;

  rs)
    if run_if_available rustfmt; then
      rustfmt "$FILE_PATH" &>/dev/null && FORMATTED=1 && FORMATTER="rustfmt"
    fi
    ;;

  sh|bash)
    if run_if_available shfmt; then
      shfmt -w "$FILE_PATH" &>/dev/null && FORMATTED=1 && FORMATTER="shfmt"
    fi
    ;;

  lua)
    if run_if_available stylua; then
      stylua "$FILE_PATH" &>/dev/null && FORMATTED=1 && FORMATTER="stylua"
    fi
    ;;
esac

if [ "$FORMATTED" -eq 1 ]; then
  python3 -c "
import json, sys
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'PostToolUse',
    'additionalContext': f'auto-format: formatted {sys.argv[1]} with {sys.argv[2]}'
  }
}))
" "$FILE_PATH" "$FORMATTER"
fi

exit 0
