<div align="center">

<img src="../assets/logo.svg" width="480" alt="claude-code-hooks"/>

<br/>

<p>
<a href="../README.md">EN English</a> •
<a href="README_CN.md">CN 中文</a> •
<a href="README_TW.md">TW 繁體中文</a> •
<a href="README_JP.md">JP 日本語</a> •
<a href="README_KR.md">KR 한국어</a> •
<a href="README_ES.md">ES Español</a> •
<a href="README_DE.md">DE Deutsch</a> •
<a href="README_FR.md">FR Français</a> •
<a href="README_RU.md">RU Русский</a> •
<a href="README_AR.md">AR العربية</a> •
<a href="README_HI.md">IN हिन्दी</a> •
<a href="README_IT.md">IT Italiano</a>
</p>

**Hooks de segurança prontos para usar com [Claude Code](https://code.claude.com).**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/hooks-6-orange.svg)](#o-que-é-instalado)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#requisitos)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard bloqueando um comando destrutivo"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Histórico de estrelas"/>
</td>
</tr>
</table>

<br/>

<a href="#o-que-é-instalado">O que é instalado</a> •
<a href="#bash-guard-em-detalhe">bash-guard</a> •
<a href="#git-guard-em-detalhe">git-guard</a> •
<a href="#secret-guard-em-detalhe">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#crie-seus-próprios-hooks">Crie seus hooks</a> •
<a href="#requisitos">Requisitos</a>

</div>

---

> O Claude apagou toda a minha pasta `src/` durante um refactoring.
> Ele fez um force-push que sobrescreveu o trabalho da minha equipe no `main`.
> Ele fez commit do meu arquivo `.env` com chaves de API reais.
>
> Tudo na mesma semana.

Esses hooks ficam entre o Claude e a sua máquina, interceptando danos antes que aconteçam.

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Reinicie o Claude Code. Pronto.

---

## O que é instalado

Seis scripts de shell registrados como hooks do Claude Code. Cada um visa uma classe específica de danos.

| Hook | Ativado em | Função |
|---|---|---|
| `bash-guard` | todo comando shell | bloqueia `rm -rf /`, formatação de disco, fork bombs, `DROP DATABASE`, pipe-to-shell |
| `git-guard` | todo comando git | bloqueia force-push no main, `reset --hard HEAD~N`, exclusão de branches protegidas |
| `secret-guard` | toda escrita de arquivo | avisa antes de gravar `.env`, `*.pem`, `id_rsa` ou conteúdo com chaves API |
| `auto-format` | toda edição de arquivo | executa automaticamente prettier / black / gofmt / rustfmt |
| `notify` | tarefa concluída | notificação de desktop quando o Claude termina |
| `session-log` | tudo | log de auditoria diário em `~/.claude/logs/` |

**Bloqueio total**: o Claude não pode prosseguir. Recebe a razão e deve encontrar outra abordagem.
**Aviso**: o Claude recebe contexto injetado e pode tomar sua própria decisão.

---

## bash-guard em detalhe

Estes comandos são bloqueados sem exceção:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

Apenas aviso:

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard em detalhe

Bloqueado:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

Apenas aviso:

```
git push --force <outro branch>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard em detalhe

Avisa antes de gravar arquivos com estes nomes:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

Avisa se o conteúdo corresponder a estes padrões:

```
sk-...                Chave OpenAI
sk-ant-...            Chave Anthropic
AKIA...               AWS Access Key ID
ghp_...               Token de acesso pessoal do GitHub
xoxb-...              Token de Bot do Slack
sk_live_...           Chave secreta Stripe (produção)
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

Detecta o formatador correto pela extensão do arquivo:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, depois black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## Crie seus próprios hooks

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "coisa-perigosa"; then
  echo "Bloqueado: motivo aqui" >&2
  exit 2
fi
```

Referência completa da API: [Documentação de hooks do Claude Code](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## Desinstalar

```bash
bash uninstall.sh
```

---

## Requisitos

Python 3. Pré-instalado no macOS e Linux. [Baixar para Windows.](https://python.org)

---

## Projetos relacionados

[claude-mem](https://github.com/OutBlade/claude-mem) — Memória persistente entre sessões para o Claude Code
