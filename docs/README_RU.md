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
<a href="README_AR.md">AR العربية</a> •
<a href="README_HI.md">IN हिन्दी</a> •
<a href="README_IT.md">IT Italiano</a>
</p>

**Готовые к использованию хуки безопасности для [Claude Code](https://code.claude.com).**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/хуков-6-orange.svg)](#что-устанавливается)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#требования)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard блокирует опасную команду"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="История звёзд"/>
</td>
</tr>
</table>

<br/>

<a href="#что-устанавливается">Что устанавливается</a> •
<a href="#bash-guard-подробно">bash-guard</a> •
<a href="#git-guard-подробно">git-guard</a> •
<a href="#secret-guard-подробно">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#создание-собственных-хуков">Свои хуки</a> •
<a href="#требования">Требования</a>

</div>

---

> Claude удалил всю мою папку `src/` во время рефакторинга.
> Он сделал force-push, перезаписав работу команды в `main`.
> Он закоммитил мой `.env` файл с реальными API-ключами.
>
> Всё это случилось за одну неделю.

Эти хуки встают между Claude и вашей машиной, перехватывая ущерб до того, как он произойдёт.

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Перезапустите Claude Code. Готово.

---

## Что устанавливается

Шесть shell-скриптов, зарегистрированных как хуки Claude Code. Каждый направлен против определённого класса повреждений.

| Хук | Срабатывает на | Функция |
|---|---|---|
| `bash-guard` | каждой shell-команде | жёстко блокирует `rm -rf /`, форматирование диска, fork-бомбы, `DROP DATABASE`, pipe-выполнение |
| `git-guard` | каждой git-команде | жёстко блокирует force-push в main, `reset --hard HEAD~N`, удаление защищённых веток |
| `secret-guard` | каждой записи файла | предупреждает перед записью `.env`, `*.pem`, `id_rsa` или API-ключей |
| `auto-format` | каждом редактировании | автоматически запускает prettier / black / gofmt / rustfmt |
| `notify` | завершении задачи | уведомление рабочего стола, когда Claude закончил |
| `session-log` | всём | ежедневный лог всех вызовов инструментов в `~/.claude/logs/` |

**Жёсткая блокировка**: Claude не может продолжить. Получает объяснение и должен найти другой подход.
**Предупреждение**: Claude получает контекст и может принять собственное решение.

---

## bash-guard подробно

Эти команды блокируются безоговорочно:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

Только предупреждение:

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard подробно

Заблокировано:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

Только предупреждение:

```
git push --force <другая ветка>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard подробно

Предупреждает при записи файлов с такими именами:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

Предупреждает при совпадении содержимого с этими паттернами:

```
sk-...                Ключ OpenAI
sk-ant-...            Ключ Anthropic
AKIA...               AWS Access Key ID
ghp_...               GitHub Personal Access Token
xoxb-...              Slack Bot Token
sk_live_...           Stripe Live Secret Key
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

Определяет нужный форматтер по расширению файла:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, затем black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## Создание собственных хуков

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "опасная-вещь"; then
  echo "Заблокировано: причина здесь" >&2
  exit 2
fi
```

Полная справка по API: [Документация хуков Claude Code](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## Удаление

```bash
bash uninstall.sh
```

---

## Требования

Python 3. Предустановлен на macOS и Linux. [Скачать для Windows.](https://python.org)

---

## Связанные проекты

[claude-mem](https://github.com/OutBlade/claude-mem) — Постоянная память между сессиями для Claude Code
