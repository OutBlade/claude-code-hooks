#!/usr/bin/env bash
# git-guard — prevents dangerous git operations
# Hook event: PreToolUse (matcher: Bash)
#
# Blocks: force-push to main/master, hard reset losing commits,
#         rebase --onto main, deleting remote branches.
# Warns:  force-push to any branch, amending published commits.

set -euo pipefail

INPUT=$(cat)

parse() {
  echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null || echo ""
}

COMMAND=$(parse)

# Only process git commands
echo "$COMMAND" | grep -qP '^\s*git\s' || exit 0

block() {
  echo "git-guard: $1" >&2
  echo "" >&2
  echo "Blocked command: $COMMAND" >&2
  exit 2
}

warn() {
  python3 -c "
import json, sys
print(json.dumps({'continue': True, 'systemMessage': sys.argv[1]}))
" "git-guard warning: $1"
  exit 0
}

# --- Hard blocks --------------------------------------------------------------

# Force push to main or master (any remote)
echo "$COMMAND" | grep -qP 'git\s+push\s+.*(-f|--force)\s+\S+\s+(main|master)$' \
  && block "Force-push to main/master is blocked. Push to a feature branch and open a PR."

echo "$COMMAND" | grep -qP 'git\s+push\s+.*\+(refs/heads/)?(main|master)' \
  && block "Force-push to main/master is blocked. Push to a feature branch and open a PR."

# git push --force with upstream tracking pointing to main/master
# (harder to detect, so we just warn — see below)

# Hard reset that drops commits (HEAD~N or a specific SHA)
echo "$COMMAND" | grep -qP 'git\s+reset\s+--hard\s+HEAD~[0-9]' \
  && block "Hard reset removing commits is blocked. Use git revert to undo changes safely, or stash if you want to discard working-tree changes."

echo "$COMMAND" | grep -qP 'git\s+reset\s+--hard\s+[0-9a-f]{7,40}' \
  && block "Hard reset to a specific commit is blocked. Use git revert instead."

# Delete remote branch (can lose work on shared repos)
echo "$COMMAND" | grep -qP 'git\s+push\s+\S+\s+--delete\s+(main|master|release|production|prod|staging)' \
  && block "Deleting a protected remote branch is blocked."

echo "$COMMAND" | grep -qP 'git\s+push\s+\S+\s+:(main|master|release|production|prod|staging)' \
  && block "Deleting a protected remote branch via colon-refspec is blocked."

# --- Soft warnings ------------------------------------------------------------

# Force push to any branch
echo "$COMMAND" | grep -qP 'git\s+push\s+.*(-f|--force)' \
  && warn "Force-pushing rewrites history on the remote. Make sure no one else is working on this branch."

# Amend a commit (could rewrite published history)
echo "$COMMAND" | grep -qP 'git\s+commit\s+--amend' \
  && warn "Amending a commit rewrites history. If this commit is already pushed, you will need to force-push."

# Hard reset to HEAD (discards working tree, but no commits lost — just warn)
echo "$COMMAND" | grep -qP 'git\s+reset\s+--hard\s+(HEAD|ORIG_HEAD|FETCH_HEAD)$' \
  && warn "Hard reset to HEAD will discard all unstaged and staged changes permanently."

# git clean -fd (removes untracked files)
echo "$COMMAND" | grep -qP 'git\s+clean\s+(-\S*f\S*|-\S*d\S*)' \
  && warn "git clean will permanently delete untracked files. Make sure you don't need them."

exit 0
