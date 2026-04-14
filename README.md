# claude-code-hooks

A plug-and-play collection of safety and productivity hooks for [Claude Code](https://code.claude.com).

One install command. Immediate protection. No configuration required.

---

## Why

Claude Code is powerful. That power comes with risk. It can and will:

- Run `rm -rf` on the wrong directory
- Force-push over your colleagues' work on `main`
- Write API keys into files that end up committed
- Silently skip formatting, leaving inconsistent code

These hooks intercept Claude before damage happens.

---

## Install

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks
bash install.sh
```

Then restart Claude Code.

Requires: Python 3 (pre-installed on macOS/Linux; [download for Windows](https://python.org))

---

## What's included

### bash-guard

**Event:** `PreToolUse` / `Bash`

Blocks commands that cannot be undone:

| Blocked pattern | Reason |
|---|---|
| `rm -rf /`, `rm -rf ~`, `rm -rf .` | Filesystem destruction |
| `mkfs.*`, `dd if=... of=/dev/sd*` | Disk formatting / raw writes |
| `:(){:\|:&};:` | Fork bomb |
| `chmod -R 777 /` | Mass permission change |
| `shutdown`, `poweroff`, `halt` | System shutdown |
| `DROP DATABASE`, `DROP SCHEMA ... CASCADE` | Database destruction |
| `curl ... \| bash` | Pipe-to-shell (warning only) |

When blocked, Claude receives an explanation and must find a safer approach.

### git-guard

**Event:** `PreToolUse` / `Bash`

| Blocked | Warning only |
|---|---|
| Force-push to `main`/`master` | Force-push to any branch |
| `git reset --hard HEAD~N` (drops commits) | `git reset --hard HEAD` |
| Delete protected remote branches | `git commit --amend` |
| | `git clean -fd` |

### secret-guard

**Event:** `PreToolUse` / `Edit`, `Write`

Warns Claude before writing files that contain sensitive data. Detects:

- Filename patterns: `.env`, `*.pem`, `*.key`, `credentials.json`, `id_rsa`, `kubeconfig`, ...
- Content patterns: OpenAI keys (`sk-...`), Anthropic keys, AWS access keys (`AKIA...`), GitHub tokens (`ghp_...`), Stripe live keys, private key blocks, hardcoded passwords

Does not block (Claude may legitimately create placeholder `.env` files), but adds a visible warning so Claude can add `.gitignore` entries and inform you.

### auto-format

**Event:** `PostToolUse` / `Edit`, `Write`

Runs the right formatter after every file edit, automatically:

| Extension | Formatter |
|---|---|
| `.js`, `.ts`, `.tsx`, `.css`, `.html`, `.json`, `.md`, ... | `prettier` |
| `.py` | `ruff` or `black` |
| `.go` | `gofmt` |
| `.rs` | `rustfmt` |
| `.sh` | `shfmt` |
| `.lua` | `stylua` |

Silently skips if no formatter is installed. Claude sees a confirmation when formatting runs.

### notify

**Event:** `Stop`

Desktop notification when Claude finishes a task — so you can switch to another window and come back when it's done.

Works on Windows (PowerShell balloon), macOS (osascript), and Linux (notify-send).

### session-log

**Event:** `PostToolUse` / all tools

Appends every tool call to `~/.claude/logs/YYYY-MM-DD.log`:

```
[14:32:11] [a1b2c3d4] Bash                 [success] git status
[14:32:14] [a1b2c3d4] Edit                 [success] src/auth/middleware.ts
[14:32:18] [a1b2c3d4] Bash                 [success] npm test -- --testPathPattern=auth
```

Useful for reviewing what Claude did when you weren't watching, or for debugging a failed session.

---

## Selective install

Don't want all hooks? Copy individual scripts manually:

```bash
cp hooks/bash-guard.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/bash-guard.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/hooks/bash-guard.sh" }
        ]
      }
    ]
  }
}
```

---

## Uninstall

```bash
bash uninstall.sh
```

Removes hook scripts and cleans settings.json. Leaves your logs intact.

---

## Writing your own hook

Every hook is a shell script that reads JSON from stdin and exits with:

- `0` — proceed (optionally output JSON to add context for Claude)
- `2` — block (write explanation to stderr; Claude will see it)

Minimal example — block a specific tool:

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))")

if echo "$COMMAND" | grep -q "my-dangerous-thing"; then
  echo "Blocked: reason here" >&2
  exit 2
fi
```

See the [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks) for the full API reference.

---

## Contributing

Pull requests welcome. Each hook should:

- Be a single self-contained shell script
- Exit 0 silently on the happy path (no unnecessary noise)
- Use `python3` for JSON parsing (available on all platforms)
- Include a comment header explaining the event, matcher, and behavior
- Not require external tools beyond what ships with the OS

---

## Related projects

- [claude-mem](https://github.com/OutBlade/claude-mem) — persistent cross-session memory for Claude Code
