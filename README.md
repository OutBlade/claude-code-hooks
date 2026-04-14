# claude-code-hooks

> Claude deleted my entire `src/` folder while refactoring.
> It force-pushed over my team's work on `main`.
> It committed my `.env` file with real API keys.
>
> All in the same week.

These hooks make sure that never happens to you.

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Restart Claude Code. Done.

---

## What gets installed

Six shell scripts that sit between Claude and your machine. Each one intercepts a specific class of damage before it happens.

| Hook | Triggers on | What it does |
|---|---|---|
| `bash-guard` | every shell command | hard-blocks `rm -rf /`, disk format, fork bombs, `DROP DATABASE`, pipe-to-shell |
| `git-guard` | every git command | hard-blocks force-push to main, `reset --hard HEAD~N`, deleting protected branches |
| `secret-guard` | every file write | warns before writing `.env`, `*.pem`, `id_rsa`, or content that looks like an API key |
| `auto-format` | every file edit | runs prettier / black / gofmt / rustfmt automatically |
| `notify` | task complete | desktop notification so you can look away while Claude works |
| `session-log` | everything | daily audit log of every tool call at `~/.claude/logs/` |

Hard-blocked means Claude cannot proceed. It receives the reason and must find a different approach. Warned means Claude gets context injected and can make a judgment call.

---

## bash-guard in detail

These commands are blocked outright, with no override:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

These trigger a warning (Claude sees it, but can proceed):

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard in detail

Blocked:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

Warning only (Claude is told, but can proceed if appropriate):

```
git push --force <any other branch>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard in detail

Warns before writing files matching these names:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

Warns if file content matches these patterns:

```
sk-...                OpenAI key
sk-ant-...            Anthropic key
AKIA...               AWS Access Key ID
ghp_...               GitHub personal access token
xoxb-...              Slack bot token
sk_live_...           Stripe live secret key
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

Does not block — Claude may legitimately create a `.env.example` with placeholders. But it always sees the warning and will add `.gitignore` entries.

---

## auto-format

Runs after every `Edit` or `Write` tool call. Detects the right formatter from the file extension:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, then black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

Silently skips if no formatter is installed. No configuration needed.

---

## session-log

Every tool call appended to `~/.claude/logs/YYYY-MM-DD.log`:

```
[09:14:02] [3f8a1c2b] Bash                 [success] git checkout -b feature/auth
[09:14:09] [3f8a1c2b] Write                [success] src/auth/middleware.ts
[09:14:13] [3f8a1c2b] Bash                 [success] npm test -- --testPathPattern=auth
[09:14:31] [3f8a1c2b] Edit                 [success] src/auth/middleware.ts
[09:14:35] [3f8a1c2b] Bash                 [error  ] tsc --noEmit
```

One log per day. Survives session boundaries. Useful for understanding what Claude actually did while you were away.

---

## Pick only what you need

Install individual hooks without the script:

```bash
cp hooks/bash-guard.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/bash-guard.sh
```

Add to `~/.claude/settings.json`:

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

## Write your own

Every hook is a shell script. It reads JSON from stdin and exits with:

- `0` — allow (optionally output a JSON `systemMessage` to inject context for Claude)
- `2` — block (write the reason to stderr; Claude will read it and adjust)

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "dangerous-thing"; then
  echo "Blocked: explain why here" >&2
  exit 2
fi
```

Full API reference: [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## Uninstall

```bash
bash uninstall.sh
```

Removes hook scripts, cleans settings.json, leaves logs.

---

## Requirements

Python 3. Pre-installed on macOS and Linux. [Download for Windows.](https://python.org)

---

## Related

[claude-mem](https://github.com/OutBlade/claude-mem) — persistent cross-session memory for Claude Code
