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
<a href="README_DE.md">DE Deutsch</a> •
<a href="README_FR.md">FR Français</a> •
<a href="README_RU.md">RU Русский</a> •
<a href="README_AR.md">AR العربية</a> •
<a href="README_HI.md">IN हिन्दी</a>
</p>

**Hook di sicurezza pronti all'uso per [Claude Code](https://code.claude.com).**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/hook-6-orange.svg)](#cosa-viene-installato)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#requisiti)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard blocca un comando distruttivo"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Cronologia stelle"/>
</td>
</tr>
</table>

<br/>

<a href="#cosa-viene-installato">Cosa viene installato</a> •
<a href="#bash-guard-in-dettaglio">bash-guard</a> •
<a href="#git-guard-in-dettaglio">git-guard</a> •
<a href="#secret-guard-in-dettaglio">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#scrivi-i-tuoi-hook">Scrivi i tuoi hook</a> •
<a href="#requisiti">Requisiti</a>

</div>

---

> Claude ha cancellato l'intera cartella `src/` durante un refactoring.
> Ha eseguito un force-push sovrascrivendo il lavoro del mio team su `main`.
> Ha committato il mio file `.env` con chiavi API reali.
>
> Tutto nella stessa settimana.

Questi hook si frappongono tra Claude e la tua macchina, intercettando i danni prima che avvengano.

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Riavvia Claude Code. Fatto.

---

## Cosa viene installato

Sei script shell registrati come hook di Claude Code. Ognuno prende di mira una specifica categoria di danni.

| Hook | Si attiva su | Funzione |
|---|---|---|
| `bash-guard` | ogni comando shell | blocca `rm -rf /`, formattazione disco, fork bomb, `DROP DATABASE`, pipe-to-shell |
| `git-guard` | ogni comando git | blocca force-push su main, `reset --hard HEAD~N`, eliminazione di branch protetti |
| `secret-guard` | ogni scrittura file | avvisa prima di scrivere `.env`, `*.pem`, `id_rsa` o contenuto simile a chiavi API |
| `auto-format` | ogni modifica file | esegue automaticamente prettier / black / gofmt / rustfmt |
| `notify` | completamento task | notifica desktop quando Claude ha finito |
| `session-log` | tutto | log di audit giornaliero in `~/.claude/logs/` |

**Blocco duro**: Claude non può proseguire. Riceve la motivazione e deve trovare un approccio diverso.
**Avviso**: Claude riceve contesto iniettato e può prendere la propria decisione.

---

## bash-guard in dettaglio

Questi comandi sono bloccati senza eccezioni:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

Solo avviso:

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard in dettaglio

Bloccato:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

Solo avviso:

```
git push --force <altro branch>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard in dettaglio

Avvisa prima di scrivere file con questi nomi:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

Avvisa se il contenuto corrisponde a questi pattern:

```
sk-...                Chiave OpenAI
sk-ant-...            Chiave Anthropic
AKIA...               AWS Access Key ID
ghp_...               GitHub Personal Access Token
xoxb-...              Slack Bot Token
sk_live_...           Stripe Live Secret Key
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

Rileva il formatter corretto dall'estensione del file:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, poi black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## session-log

Ogni chiamata agli strumenti aggiunta a `~/.claude/logs/YYYY-MM-DD.log`:

```
[09:14:02] [3f8a1c2b] Bash                 [success] git checkout -b feature/auth
[09:14:09] [3f8a1c2b] Write                [success] src/auth/middleware.ts
[09:14:35] [3f8a1c2b] Bash                 [error  ] tsc --noEmit
```

---

## Scrivi i tuoi hook

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "cosa-pericolosa"; then
  echo "Bloccato: motivo qui" >&2
  exit 2
fi
```

Riferimento API completo: [Documentazione hook Claude Code](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## Disinstallazione

```bash
bash uninstall.sh
```

Rimuove gli script, pulisce `settings.json`, lascia i log intatti.

---

## Requisiti

Python 3. Preinstallato su macOS e Linux. [Scarica per Windows.](https://python.org)

---

## Progetti correlati

[claude-mem](https://github.com/OutBlade/claude-mem) — Memoria persistente tra sessioni per Claude Code
