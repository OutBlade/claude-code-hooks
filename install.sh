#!/usr/bin/env bash
# install.sh — installs claude-code-hooks into ~/.claude/hooks/
#
# Supports three install methods:
#   1. curl -sSL https://raw.githubusercontent.com/OutBlade/claude-code-hooks/main/install.sh | bash
#   2. bash <(curl -sSL https://raw.githubusercontent.com/OutBlade/claude-code-hooks/main/install.sh)
#   3. git clone https://github.com/OutBlade/claude-code-hooks && cd claude-code-hooks && bash install.sh

set -euo pipefail

REPO_URL="https://github.com/OutBlade/claude-code-hooks"
HOOKS_DEST="$HOME/.claude/hooks"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  [ok]${NC} $1"; }
warn() { echo -e "${YELLOW}  [!] ${NC} $1"; }
err()  { echo -e "${RED}  [x] ${NC} $1"; }

echo ""
echo "claude-code-hooks installer"
echo "==========================="
echo ""

# --- Detect if running via curl pipe (no local repo available) ----------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-/dev/stdin}")" 2>/dev/null && pwd || echo "")"
REPO_DIR=""

if [ -f "$SCRIPT_DIR/hooks/bash-guard.sh" ]; then
  # Running from a cloned repo
  REPO_DIR="$SCRIPT_DIR"
else
  # Running via curl pipe — clone the repo first
  INSTALL_CLONE="$HOME/.claude/claude-code-hooks"
  if [ -d "$INSTALL_CLONE/.git" ]; then
    echo "Updating existing clone at $INSTALL_CLONE ..."
    git -C "$INSTALL_CLONE" pull --ff-only -q
  else
    echo "Cloning repository to $INSTALL_CLONE ..."
    git clone -q "$REPO_URL" "$INSTALL_CLONE"
  fi
  REPO_DIR="$INSTALL_CLONE"
  ok "Repository ready at $REPO_DIR"
fi

# --- Python detection (skips Windows Store stubs) ----------------------------
find_python() {
  for cmd in python3 python py; do
    local p
    p=$(command -v "$cmd" 2>/dev/null) || continue
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
ok "Python: $("$PYTHON" --version 2>&1)"

# --- Install hook scripts -----------------------------------------------------
mkdir -p "$HOOKS_DEST"
ok "Hooks directory: $HOOKS_DEST"

HOOKS=(bash-guard.sh git-guard.sh secret-guard.sh auto-format.sh notify.sh session-log.sh)
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
    warn "Hook not found: $hook (skipping)"
  fi
done

# --- Merge settings.json ------------------------------------------------------
echo ""
echo "Updating ~/.claude/settings.json ..."
"$PYTHON" "$REPO_DIR/merge-settings.py"

# --- Finish -------------------------------------------------------------------
mkdir -p "$HOME/.claude/logs"

echo ""
echo "Done. $INSTALLED hooks active."
echo ""
echo "  bash-guard    blocks rm -rf, disk format, fork bombs, DROP DATABASE"
echo "  git-guard     blocks force-push to main, hard reset, branch deletion"
echo "  secret-guard  warns before writing .env, private keys, API keys"
echo "  auto-format   runs prettier/black/gofmt/rustfmt after every edit"
echo "  notify        desktop notification when Claude finishes"
echo "  session-log   audit log at ~/.claude/logs/"
echo ""
echo "Restart Claude Code to activate."
echo ""
