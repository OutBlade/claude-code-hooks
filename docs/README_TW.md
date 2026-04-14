<div align="center">

<img src="../assets/logo.svg" width="480" alt="claude-code-hooks"/>

<br/>

<p>
<a href="../README.md">EN English</a> •
<a href="README_CN.md">CN 中文</a> •
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

**為 [Claude Code](https://code.claude.com) 設計的即插即用安全鉤子。**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/鉤子-6個-orange.svg)](#已安裝內容)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#系統要求)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard 攔截破壞性指令"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Star 歷史"/>
</td>
</tr>
</table>

<br/>

<a href="#已安裝內容">已安裝內容</a> •
<a href="#bash-guard-詳情">bash-guard</a> •
<a href="#git-guard-詳情">git-guard</a> •
<a href="#secret-guard-詳情">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#撰寫自訂鉤子">撰寫自訂鉤子</a> •
<a href="#系統要求">系統要求</a>

</div>

---

> Claude 在重構時刪除了我整個 `src/` 目錄。
> 它強制推送覆蓋了團隊在 `main` 上的工作。
> 它把含有真實 API 金鑰的 `.env` 檔案提交到了儲存庫。
>
> 以上都發生在同一週。

這些鉤子介於 Claude 和你的機器之間，在損害發生之前將其攔截。

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

重啟 Claude Code，完成。

---

## 已安裝內容

六個 shell 腳本，作為 Claude Code 鉤子註冊。每個腳本針對一類特定的破壞。

| 鉤子 | 觸發於 | 功能 |
|---|---|---|
| `bash-guard` | 每條 shell 命令 | 硬性攔截 `rm -rf /`、磁碟格式化、fork 炸彈、`DROP DATABASE`、管道執行 |
| `git-guard` | 每條 git 命令 | 硬性攔截強制推送到 main、`reset --hard HEAD~N`、刪除受保護分支 |
| `secret-guard` | 每次檔案寫入 | 寫入 `.env`、`*.pem`、`id_rsa` 或疑似 API 金鑰內容前發出警告 |
| `auto-format` | 每次檔案編輯 | 自動執行 prettier / black / gofmt / rustfmt |
| `notify` | 任務完成 | 桌面通知，讓你可以切換視窗等待 |
| `session-log` | 所有操作 | 每日工具呼叫稽核日誌，儲存於 `~/.claude/logs/` |

**硬性攔截**：Claude 無法繼續執行，它會收到原因說明並必須尋找其他方法。
**警告**：Claude 收到注入的上下文，可以自行判斷是否繼續。

---

## bash-guard 詳情

以下命令被直接攔截，無法繞過：

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

以下命令觸發警告：

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard 詳情

被攔截：

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

僅警告：

```
git push --force <其他分支>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard 詳情

寫入以下檔案名稱時發出警告：

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

檔案內容符合以下模式時發出警告：

```
sk-...                OpenAI 金鑰
sk-ant-...            Anthropic 金鑰
AKIA...               AWS 存取金鑰 ID
ghp_...               GitHub 個人存取權杖
xoxb-...              Slack Bot 權杖
sk_live_...           Stripe 正式環境密鑰
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

根據副檔名偵測合適的格式化工具：

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff，其次 black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## 卸載

```bash
bash uninstall.sh
```

---

## 系統要求

Python 3。macOS 和 Linux 已預裝。[Windows 請下載。](https://python.org)

---

## 相關專案

[claude-mem](https://github.com/OutBlade/claude-mem) — Claude Code 的跨會話持久記憶
