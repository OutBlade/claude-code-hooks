#!/usr/bin/env bash
# uninstall.sh — removes claude-code-hooks from ~/.claude/hooks/ and settings.json

set -euo pipefail

HOOKS_DEST="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

ok()   { echo -e "${GREEN}  [ok]${NC} $1"; }
warn() { echo -e "${YELLOW}  [!] ${NC} $1"; }

echo ""
echo "Uninstalling claude-code-hooks..."
echo ""

HOOKS=(bash-guard.sh git-guard.sh secret-guard.sh auto-format.sh notify.sh session-log.sh)

for hook in "${HOOKS[@]}"; do
  target="$HOOKS_DEST/$hook"
  if [ -f "$target" ]; then
    rm "$target"
    ok "Removed $target"
  fi
done

# Remove hook entries from settings.json
if [ -f "$SETTINGS" ]; then
  python3 - <<'PYEOF'
import json, os, shutil
from datetime import datetime

path = os.path.expanduser("~/.claude/settings.json")
hooks_dir = os.path.expanduser("~/.claude/hooks/")

with open(path) as f:
    settings = json.load(f)

backup = path + "." + datetime.now().strftime("%Y%m%d%H%M%S") + ".bak"
shutil.copy2(path, backup)
print(f"  Backed up settings to {backup}")

def filter_hooks(entries):
    cleaned = []
    for entry in entries:
        hooks = [h for h in entry.get("hooks", [])
                 if hooks_dir not in h.get("command", "")]
        if hooks:
            cleaned.append({**entry, "hooks": hooks})
    return cleaned

hooks = settings.get("hooks", {})
for event in list(hooks.keys()):
    hooks[event] = filter_hooks(hooks[event])
    if not hooks[event]:
        del hooks[event]

with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print(f"  Cleaned settings.json")
PYEOF
  ok "settings.json cleaned"
fi

echo ""
echo "Uninstall complete. Restart Claude Code to apply."
echo ""
