<div align="center">

<img src="assets/logo.svg" width="480" alt="claude-code-hooks"/>

<br/>

<p>
<a href="docs/README_CN.md">CN 中文</a> •
<a href="docs/README_TW.md">TW 繁體中文</a> •
<a href="docs/README_JP.md">JP 日本語</a> •
<a href="docs/README_PT.md">PT Português</a> •
<a href="docs/README_KR.md">KR 한국어</a> •
<a href="docs/README_ES.md">ES Español</a> •
<a href="docs/README_DE.md">DE Deutsch</a> •
<a href="docs/README_FR.md">FR Français</a> •
<a href="docs/README_RU.md">RU Русский</a> •
<a href="docs/README_AR.md">AR العربية</a> •
<a href="docs/README_HI.md">IN हिन्दी</a> •
<a href="docs/README_IT.md">IT Italiano</a>
</p>

**A safety net for Claude Code. Stops `rm -rf`, force-push to main, and API key commits — before they happen.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Hooks: 6](https://img.shields.io/badge/hooks-6-orange.svg)](#whats-installed)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#requirements)
[![Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-hooks-blueviolet.svg)](https://docs.anthropic.com/en/docs/claude-code/hooks)

```bash
curl -sSL https://raw.githubusercontent.com/OutBlade/claude-code-hooks/main/install.sh | bash
```

Then restart Claude Code.

<br/>

<table>
<tr>
<td align="center">
<img src="assets/demo.svg" width="440" alt="Demo: bash-guard and git-guard intercepting dangerous commands"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="360" alt="Star history"/>
</td>
</tr>
</table>

<br/>

<a href="#whats-installed">What's installed</a> •
<a href="#bash-guard-in-detail">bash-guard</a> •
<a href="#git-guard-in-detail">git-guard</a> •
<a href="#secret-guard-in-detail">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#write-your-own">Write your own</a> •
<a href="#requirements">Requirements</a>

</div>

---

Claude Code is the most powerful coding assistant ever built. It is also perfectly capable of deleting your project, overwriting your team's work, or leaking your credentials — not out of malice, but because nothing stops it.

These hooks stop it.

Each one is a shell script that Claude Code calls before or after a tool runs. They take less than a second and require no configuration.

---

## What's installed

| Hook | When it runs | What it does |
|---|---|---|
| **bash-guard** | before every shell command | hard-blocks `rm -rf /~/.`, disk format, fork bombs, `DROP DATABASE`, pipe-to-shell |
| **git-guard** | before every git command | hard-blocks force-push to main, `reset --hard HEAD~N`, deleting protected branches |
| **secret-guard** | before every file write | warns before writing `.env`, private keys, or content matching API key patterns |
| **auto-format** | after every file edit | runs prettier / black / gofmt / rustfmt automatically |
| **notify** | when Claude stops | desktop notification so you can switch windows and come back |
| **session-log** | after every tool call | daily audit log at `~/.claude/logs/YYYY-MM-DD.log` |

**Hard-blocked** means Claude cannot proceed. It sees the reason and must find a safer approach.
**Warned** means Claude gets context injected and can make its own call.

---

## bash-guard in detail

Blocked outright — no override:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

Warning only — Claude proceeds but sees the message:

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

Warning only:

```
git push --force <any other branch>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard in detail

Warns before writing files with these names:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

Warns if file content matches:

```
sk-...            OpenAI key          sk-ant-...        Anthropic key
AKIA...           AWS Access Key      ghp_...           GitHub token
xoxb-...          Slack token         sk_live_...       Stripe live key
-----BEGIN * PRIVATE KEY-----
password = "..."  api_key = "..."
```

Does not block — Claude may legitimately create `.env.example` with placeholders. But it always sees the warning and will add `.gitignore` entries.

---

## auto-format

Runs after every `Edit` or `Write`. Detects the formatter from the file extension:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, then black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

Silently skips if no formatter is installed.

---

## session-log

Every tool call appended to `~/.claude/logs/YYYY-MM-DD.log`:

```
[09:14:02] [3f8a1c2b] Bash                 [success] git checkout -b feature/auth
[09:14:09] [3f8a1c2b] Write                [success] src/auth/middleware.ts
[09:14:13] [3f8a1c2b] Bash                 [success] npm test -- --testPathPattern=auth
[09:14:35] [3f8a1c2b] Bash                 [error  ] tsc --noEmit
```

One log per day. Survives session restarts. Useful for reviewing what Claude did while you were away.

---

## Selective install

To install a single hook without the script:

```bash
curl -sSL https://raw.githubusercontent.com/OutBlade/claude-code-hooks/main/hooks/bash-guard.sh \
  -o ~/.claude/hooks/bash-guard.sh && chmod +x ~/.claude/hooks/bash-guard.sh
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

## Write your own

Every hook reads JSON from stdin and exits with:

- `0` — allow (optionally output a JSON `systemMessage` to inject context for Claude)
- `2` — block (write the reason to stderr; Claude reads it and must adjust)

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "my-dangerous-thing"; then
  echo "Blocked: reason here" >&2
  exit 2
fi
```

Full API reference: [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)

Pull requests welcome. Each hook should be a single self-contained shell script, silent on the happy path, and require only Python 3 and standard OS tools.

---

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/OutBlade/claude-code-hooks/main/uninstall.sh | bash
```

Removes hook scripts, cleans `settings.json`, leaves logs intact.

---

## Requirements

Python 3. Pre-installed on macOS and Linux. [Download for Windows.](https://python.org)

---

## Related

[claude-mem](https://github.com/OutBlade/claude-mem) — persistent cross-session memory for Claude Code
