#!/usr/bin/env bash
# install.sh — installs claude-code-hooks into ~/.claude/hooks/
#
# Usage:
#   git clone https://github.com/OutBlade/claude-code-hooks && cd claude-code-hooks && bash install.sh
#   OR one-liner:
#   bash <(curl -sSL https://raw.githubusercontent.com/OutBlade/claude-code-hooks/main/install.sh)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DEST="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

ok()   { echo -e "${GREEN}  [ok]${NC} $1"; }
warn() { echo -e "${YELLOW}  [!] ${NC} $1"; }
err()  { echo -e "${RED}  [x] ${NC} $1"; }

echo ""
echo "claude-code-hooks installer"
echo "==========================="
echo ""

# 1. Check dependencies — verify Python actually runs (Windows Store stubs don't)
find_python() {
  for cmd in python3 python py; do
    local p
    p=$(command -v "$cmd" 2>/dev/null) || continue
    # Test it actually executes
    if "$p" -c "import sys; assert sys.version_info[0]==3" 2>/dev/null; then
      echo "$p"; return 0
    fi
  done
  return 1
}
PYTHON=$(find_python || echo "")
if [ -z "$PYTHON" ]; then
  err "Python 3 is required but not found. Install it from https://python.org"
  exit 1
fi
PY_VER=$("$PYTHON" --version 2>&1)
ok "Python found: $PY_VER ($PYTHON)"

# 2. Create hooks directory
mkdir -p "$HOOKS_DEST"
ok "Hooks directory: $HOOKS_DEST"

# 3. Copy hook scripts
HOOKS=(
  bash-guard.sh
  git-guard.sh
  secret-guard.sh
  auto-format.sh
  notify.sh
  session-log.sh
)

INSTALLED=0
for hook in "${HOOKS[@]}"; do
  src="$REPO_DIR/hooks/$hook"
  dst="$HOOKS_DEST/$hook"
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    chmod +x "$dst"
    ok "Installed $hook"
    INSTALLED=$((INSTALLED + 1))
  else
    warn "Hook not found in repo: $hook (skipping)"
  fi
done

# 4. Merge settings.json
echo ""
echo "Updating settings.json ..."
"$PYTHON" "$REPO_DIR/merge-settings.py"

# 5. Create log directory
mkdir -p "$HOME/.claude/logs"
ok "Log directory: $HOME/.claude/logs"

# 6. Done
echo ""
echo "Installation complete. $INSTALLED hooks active."
echo ""
echo "Active hooks:"
echo "  bash-guard    PreToolUse/Bash    — blocks destructive shell commands"
echo "  git-guard     PreToolUse/Bash    — prevents dangerous git operations"
echo "  secret-guard  PreToolUse/Edit    — warns before writing secrets"
echo "  auto-format   PostToolUse/Edit   — formats code after edits"
echo "  notify        Stop               — desktop notification on task finish"
echo "  session-log   PostToolUse/*      — audit log at ~/.claude/logs/"
echo ""
echo "Restart Claude Code to activate hooks."
echo ""
