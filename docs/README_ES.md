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
<a href="README_DE.md">DE Deutsch</a> •
<a href="README_FR.md">FR Français</a> •
<a href="README_RU.md">RU Русский</a> •
<a href="README_AR.md">AR العربية</a> •
<a href="README_HI.md">IN हिन्दी</a> •
<a href="README_IT.md">IT Italiano</a>
</p>

**Hooks de seguridad listos para usar con [Claude Code](https://code.claude.com).**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/hooks-6-orange.svg)](#qué-se-instala)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#requisitos)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard bloqueando un comando destructivo"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Historial de estrellas"/>
</td>
</tr>
</table>

<br/>

<a href="#qué-se-instala">Qué se instala</a> •
<a href="#bash-guard-en-detalle">bash-guard</a> •
<a href="#git-guard-en-detalle">git-guard</a> •
<a href="#secret-guard-en-detalle">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#crea-tus-propios-hooks">Crea tus hooks</a> •
<a href="#requisitos">Requisitos</a>

</div>

---

> Claude eliminó toda mi carpeta `src/` durante un refactoring.
> Hizo un force-push que sobreescribió el trabajo de mi equipo en `main`.
> Hizo commit de mi archivo `.env` con claves API reales.
>
> Todo en la misma semana.

Estos hooks se interponen entre Claude y tu máquina para interceptar el daño antes de que ocurra.

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Reinicia Claude Code. Listo.

---

## Qué se instala

Seis scripts de shell registrados como hooks de Claude Code. Cada uno apunta a una clase específica de daño.

| Hook | Se activa en | Función |
|---|---|---|
| `bash-guard` | cada comando shell | bloquea `rm -rf /`, formateo de disco, fork bombs, `DROP DATABASE`, pipe-to-shell |
| `git-guard` | cada comando git | bloquea force-push a main, `reset --hard HEAD~N`, eliminar ramas protegidas |
| `secret-guard` | cada escritura de archivo | avisa antes de escribir `.env`, `*.pem`, `id_rsa` o contenido con claves API |
| `auto-format` | cada edición de archivo | ejecuta automáticamente prettier / black / gofmt / rustfmt |
| `notify` | tarea completada | notificación de escritorio cuando Claude termina |
| `session-log` | todo | registro de auditoría diario en `~/.claude/logs/` |

**Bloqueo duro**: Claude no puede continuar. Recibe la razón y debe buscar otro enfoque.
**Advertencia**: Claude recibe contexto inyectado y puede tomar su propia decisión.

---

## bash-guard en detalle

Estos comandos se bloquean sin excepción:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

Solo advertencia:

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard en detalle

Bloqueado:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

Solo advertencia:

```
git push --force <otra rama>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard en detalle

Advierte antes de escribir archivos con estos nombres:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

Advierte si el contenido coincide con estos patrones:

```
sk-...                Clave OpenAI
sk-ant-...            Clave Anthropic
AKIA...               AWS Access Key ID
ghp_...               Token de acceso personal GitHub
xoxb-...              Token de Bot Slack
sk_live_...           Clave secreta Stripe (producción)
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

Detecta el formateador correcto según la extensión:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, luego black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## Crea tus propios hooks

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "cosa-peligrosa"; then
  echo "Bloqueado: razón aquí" >&2
  exit 2
fi
```

Referencia completa de la API: [Documentación de hooks de Claude Code](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## Desinstalar

```bash
bash uninstall.sh
```

---

## Requisitos

Python 3. Preinstalado en macOS y Linux. [Descargar para Windows.](https://python.org)

---

## Proyectos relacionados

[claude-mem](https://github.com/OutBlade/claude-mem) — Memoria persistente entre sesiones para Claude Code
