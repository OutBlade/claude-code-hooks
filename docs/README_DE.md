<div align="center">

<img src="../assets/logo.svg" width="480" alt="claude-code-hooks"/>

<br/>

<p>
<a href="../README.md">EN English</a> •
<a href="README_CN.md">CN 中文</a> •
<a href="README_TW.md">TW 繁體中文</a> •
<a href="README_JP.md">JP 日本語</a> •
<a href="README_PT.md">PT Português</a> •
<a href="README_KR.md">KR 한국어</a> •
<a href="README_ES.md">ES Español</a> •
<a href="README_FR.md">FR Français</a> •
<a href="README_RU.md">RU Русский</a> •
<a href="README_AR.md">AR العربية</a> •
<a href="README_HI.md">IN हिन्दी</a> •
<a href="README_IT.md">IT Italiano</a>
</p>

**Sofort einsatzbereite Sicherheits-Hooks für [Claude Code](https://code.claude.com).**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/Hooks-6-orange.svg)](#was-wird-installiert)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#voraussetzungen)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard blockiert einen destruktiven Befehl"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Star-Verlauf"/>
</td>
</tr>
</table>

<br/>

<a href="#was-wird-installiert">Was wird installiert</a> •
<a href="#bash-guard-im-detail">bash-guard</a> •
<a href="#git-guard-im-detail">git-guard</a> •
<a href="#secret-guard-im-detail">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#eigene-hooks-schreiben">Eigene Hooks</a> •
<a href="#voraussetzungen">Voraussetzungen</a>

</div>

---

> Claude hat beim Refactoring meinen gesamten `src/`-Ordner gelöscht.
> Es hat die Arbeit meines Teams auf `main` mit einem Force-Push überschrieben.
> Es hat meine `.env`-Datei mit echten API-Schlüsseln commitet.
>
> Alles in derselben Woche.

Diese Hooks stehen zwischen Claude und deinem System und verhindern Schäden, bevor sie entstehen.

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Claude Code neu starten. Fertig.

---

## Was wird installiert

Sechs Shell-Skripte, die als Claude Code Hooks registriert werden. Jedes adressiert eine bestimmte Schadenskategorie.

| Hook | Löst aus bei | Funktion |
|---|---|---|
| `bash-guard` | jedem Shell-Befehl | blockiert `rm -rf /`, Disk-Formatierung, Fork-Bomben, `DROP DATABASE`, Pipe-Ausführung |
| `git-guard` | jedem git-Befehl | blockiert Force-Push auf main, `reset --hard HEAD~N`, Löschen geschützter Branches |
| `secret-guard` | jedem Schreibvorgang | warnt vor `.env`, `*.pem`, `id_rsa` oder API-Schlüssel-Inhalten |
| `auto-format` | jeder Dateibearbeitung | führt prettier / black / gofmt / rustfmt automatisch aus |
| `notify` | Aufgabenabschluss | Desktop-Benachrichtigung wenn Claude fertig ist |
| `session-log` | allen Operationen | tägliches Audit-Log unter `~/.claude/logs/` |

**Hart blockiert**: Claude kann nicht fortfahren. Es erhält den Grund und muss einen anderen Weg finden.
**Warnung**: Claude erhält Kontext injiziert und kann selbst entscheiden.

---

## bash-guard im Detail

Folgende Befehle werden bedingungslos blockiert:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

Nur Warnung:

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard im Detail

Blockiert:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

Nur Warnung:

```
git push --force <anderer Branch>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard im Detail

Warnt vor Schreibvorgängen mit folgenden Dateinamen:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

Warnt bei folgenden Inhaltsmustern:

```
sk-...                OpenAI-Schlüssel
sk-ant-...            Anthropic-Schlüssel
AKIA...               AWS Access Key ID
ghp_...               GitHub Personal Access Token
xoxb-...              Slack Bot Token
sk_live_...           Stripe Live Secret Key
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

Erkennt den richtigen Formatter anhand der Dateiendung:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, dann black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## Eigene Hooks schreiben

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "gefährliche-sache"; then
  echo "Blockiert: Begründung hier" >&2
  exit 2
fi
```

Vollständige API-Referenz: [Claude Code Hooks Dokumentation](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## Deinstallation

```bash
bash uninstall.sh
```

---

## Voraussetzungen

Python 3. Auf macOS und Linux vorinstalliert. [Für Windows herunterladen.](https://python.org)

---

## Verwandte Projekte

[claude-mem](https://github.com/OutBlade/claude-mem) — Sitzungsübergreifendes persistentes Gedächtnis für Claude Code
