#!/usr/bin/env bash
# notify — sends a desktop notification when Claude finishes a task
# Hook event: Stop
#
# Supports: Windows (PowerShell toast), macOS (osascript), Linux (notify-send).
# Also plays a system sound where possible.

set -euo pipefail

INPUT=$(cat)

# Extract whether Claude stopped on its own vs being interrupted
STOP_ACTIVE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(str(d.get('stop_hook_active', False)).lower())
" 2>/dev/null || echo "false")

# Don't re-notify if stop hook is already active (prevents loops)
[ "$STOP_ACTIVE" = "true" ] && exit 0

TITLE="Claude Code"
MESSAGE="Task complete"

notify_windows() {
  powershell.exe -NoProfile -NonInteractive -Command "
    Add-Type -AssemblyName System.Windows.Forms
    \$n = New-Object System.Windows.Forms.NotifyIcon
    \$n.Icon = [System.Drawing.SystemIcons]::Information
    \$n.BalloonTipTitle = '$TITLE'
    \$n.BalloonTipText = '$MESSAGE'
    \$n.Visible = \$true
    \$n.ShowBalloonTip(4000)
    Start-Sleep -Milliseconds 4500
    \$n.Dispose()
    [System.Media.SystemSounds]::Beep.Play()
  " &>/dev/null &
}

notify_macos() {
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\"" &>/dev/null &
}

notify_linux() {
  if command -v notify-send &>/dev/null; then
    notify-send "$TITLE" "$MESSAGE" --icon=dialog-information &>/dev/null &
  fi
  # Also try paplay for a sound
  if command -v paplay &>/dev/null; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga &>/dev/null & 2>/dev/null || true
  fi
}

case "$(uname -s)" in
  CYGWIN*|MINGW*|MSYS*) notify_windows ;;
  Darwin)               notify_macos   ;;
  Linux)                notify_linux   ;;
esac

exit 0
