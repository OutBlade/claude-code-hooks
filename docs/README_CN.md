<div align="center">

<img src="../assets/logo.svg" width="480" alt="claude-code-hooks"/>

<br/>

<p>
<a href="../README.md">EN English</a> •
<a href="README_TW.md">TW 繁體中文</a> •
<a href="README_JP.md">JP 日本語</a> •
<a href="README_PT.md">PT Português</a> •
<a href="README_KR.md">KR 한국어</a> •
<a href="README_ES.md">ES Español</a> •
<a href="README_DE.md">DE Deutsch</a> •
<a href="README_FR.md">FR Français</a> •
<a href="README_RU.md">RU Русский</a> •
<a href="README_AR.md">AR العربية</a> •
<a href="README_HI.md">IN हिन्दी</a> •
<a href="README_IT.md">IT Italiano</a>
</p>

**为 [Claude Code](https://code.claude.com) 设计的即插即用安全钩子。**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/钩子-6个-orange.svg)](#已安装内容)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#系统要求)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard 拦截破坏性命令"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Star 历史"/>
</td>
</tr>
</table>

<br/>

<a href="#已安装内容">已安装内容</a> •
<a href="#bash-guard-详情">bash-guard</a> •
<a href="#git-guard-详情">git-guard</a> •
<a href="#secret-guard-详情">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#编写自定义钩子">编写自定义钩子</a> •
<a href="#系统要求">系统要求</a>

</div>

---

> Claude 在重构时删除了我整个 `src/` 目录。
> 它强制推送覆盖了团队在 `main` 上的工作。
> 它把带有真实 API 密钥的 `.env` 文件提交到了仓库。
>
> 以上都发生在同一周。

这些钩子介于 Claude 和你的机器之间，在损害发生之前将其拦截。

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

重启 Claude Code，完成。

---

## 已安装内容

六个 shell 脚本，作为 Claude Code 钩子注册。每个脚本针对一类特定的破坏。

| 钩子 | 触发于 | 功能 |
|---|---|---|
| `bash-guard` | 每条 shell 命令 | 硬性拦截 `rm -rf /`、磁盘格式化、fork 炸弹、`DROP DATABASE`、管道执行 |
| `git-guard` | 每条 git 命令 | 硬性拦截强制推送到 main、`reset --hard HEAD~N`、删除受保护分支 |
| `secret-guard` | 每次文件写入 | 写入 `.env`、`*.pem`、`id_rsa` 或疑似 API 密钥内容前发出警告 |
| `auto-format` | 每次文件编辑 | 自动运行 prettier / black / gofmt / rustfmt |
| `notify` | 任务完成 | 桌面通知，让你可以切换窗口等待 |
| `session-log` | 所有操作 | 每日工具调用审计日志，保存于 `~/.claude/logs/` |

**硬性拦截**：Claude 无法继续执行，它会收到原因说明并必须寻找其他方法。
**警告**：Claude 收到注入的上下文，可以自行判断是否继续。

---

## bash-guard 详情

以下命令被直接拦截，无法绕过：

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

以下命令触发警告：

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard 详情

被拦截：

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

仅警告：

```
git push --force <其他分支>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard 详情

写入以下文件名时发出警告：

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

文件内容匹配以下模式时发出警告：

```
sk-...                OpenAI 密钥
sk-ant-...            Anthropic 密钥
AKIA...               AWS 访问密钥 ID
ghp_...               GitHub 个人访问令牌
xoxb-...              Slack Bot 令牌
sk_live_...           Stripe 生产密钥
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

不会直接拦截——Claude 可能合法地创建带占位符的 `.env.example`。但它始终会收到警告并添加 `.gitignore` 条目。

---

## auto-format

每次 `Edit` 或 `Write` 调用后执行。根据文件扩展名检测合适的格式化工具：

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff，其次 black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

未安装格式化工具时静默跳过，无需任何配置。

---

## session-log

每次工具调用追加到 `~/.claude/logs/YYYY-MM-DD.log`：

```
[09:14:02] [3f8a1c2b] Bash                 [success] git checkout -b feature/auth
[09:14:09] [3f8a1c2b] Write                [success] src/auth/middleware.ts
[09:14:13] [3f8a1c2b] Bash                 [success] npm test -- --testPathPattern=auth
[09:14:35] [3f8a1c2b] Bash                 [error  ] tsc --noEmit
```

每天一个日志文件，跨会话持久保存。

---

## 按需选择安装

```bash
cp hooks/bash-guard.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/bash-guard.sh
```

添加到 `~/.claude/settings.json`：

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

## 编写自定义钩子

每个钩子都是一个 shell 脚本，从 stdin 读取 JSON，退出码含义如下：

- `0` — 允许（可选输出 JSON `systemMessage` 为 Claude 注入上下文）
- `2` — 拦截（将原因写入 stderr，Claude 会读取并调整）

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "危险操作"; then
  echo "已拦截：请说明原因" >&2
  exit 2
fi
```

完整 API 参考：[Claude Code 钩子文档](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## 卸载

```bash
bash uninstall.sh
```

移除钩子脚本，清理 `settings.json`，保留日志。

---

## 系统要求

Python 3。macOS 和 Linux 已预装。[Windows 请下载。](https://python.org)

---

## 相关项目

[claude-mem](https://github.com/OutBlade/claude-mem) — Claude Code 的跨会话持久记忆
