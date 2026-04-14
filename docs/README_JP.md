<div align="center">

<img src="../assets/logo.svg" width="480" alt="claude-code-hooks"/>

<br/>

<p>
<a href="../README.md">EN English</a> •
<a href="README_CN.md">CN 中文</a> •
<a href="README_TW.md">TW 繁體中文</a> •
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

**[Claude Code](https://code.claude.com) のための即使用可能な安全フック集。**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/フック-6個-orange.svg)](#インストール内容)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#動作環境)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard が破壊的コマンドをブロック"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Star 履歴"/>
</td>
</tr>
</table>

<br/>

<a href="#インストール内容">インストール内容</a> •
<a href="#bash-guard-の詳細">bash-guard</a> •
<a href="#git-guard-の詳細">git-guard</a> •
<a href="#secret-guard-の詳細">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#カスタムフックの作成">カスタムフックの作成</a> •
<a href="#動作環境">動作環境</a>

</div>

---

> Claude がリファクタリング中に `src/` ディレクトリ全体を削除しました。
> `main` ブランチにチームの作業を上書きするforce pushを行いました。
> 本物の API キーが含まれた `.env` ファイルをコミットしました。
>
> すべて同じ週に起きたことです。

これらのフックは Claude とあなたのマシンの間に入り、被害が起きる前に食い止めます。

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Claude Code を再起動して完了です。

---

## インストール内容

Claude Code フックとして登録される 6 つのシェルスクリプト。それぞれ特定の被害クラスを対象とします。

| フック | トリガー | 機能 |
|---|---|---|
| `bash-guard` | 全シェルコマンド | `rm -rf /`・ディスクフォーマット・fork 爆弾・`DROP DATABASE`・パイプ実行をハードブロック |
| `git-guard` | 全 git コマンド | main へのforce push・`reset --hard HEAD~N`・保護ブランチ削除をハードブロック |
| `secret-guard` | 全ファイル書き込み | `.env`・`*.pem`・`id_rsa`・API キーらしき内容の書き込み前に警告 |
| `auto-format` | 全ファイル編集 | prettier / black / gofmt / rustfmt を自動実行 |
| `notify` | タスク完了 | デスクトップ通知で作業完了を知らせる |
| `session-log` | 全操作 | `~/.claude/logs/` に日次監査ログを記録 |

**ハードブロック**：Claude は続行不可。理由の説明を受け、別の方法を探す必要があります。
**警告**：Claude にコンテキストが注入され、判断して進めます。

---

## bash-guard の詳細

以下のコマンドは無条件にブロックされます：

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

以下は警告のみ：

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard の詳細

ブロック：

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

警告のみ：

```
git push --force <その他のブランチ>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard の詳細

以下のファイル名への書き込み時に警告：

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

以下のパターンにマッチするコンテンツで警告：

```
sk-...                OpenAI キー
sk-ant-...            Anthropic キー
AKIA...               AWS アクセスキー ID
ghp_...               GitHub 個人アクセストークン
xoxb-...              Slack Bot トークン
sk_live_...           Stripe 本番シークレットキー
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

拡張子から適切なフォーマッターを自動検出：

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff、次に black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## session-log

`~/.claude/logs/YYYY-MM-DD.log` に全ツール呼び出しを追記：

```
[09:14:02] [3f8a1c2b] Bash                 [success] git checkout -b feature/auth
[09:14:09] [3f8a1c2b] Write                [success] src/auth/middleware.ts
[09:14:35] [3f8a1c2b] Bash                 [error  ] tsc --noEmit
```

---

## カスタムフックの作成

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "危険な処理"; then
  echo "ブロック：理由をここに記述" >&2
  exit 2
fi
```

完全な API リファレンス：[Claude Code フックドキュメント](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## アンインストール

```bash
bash uninstall.sh
```

---

## 動作環境

Python 3。macOS・Linux には標準搭載。[Windows はこちらからダウンロード。](https://python.org)

---

## 関連プロジェクト

[claude-mem](https://github.com/OutBlade/claude-mem) — Claude Code のセッション横断型永続メモリ
