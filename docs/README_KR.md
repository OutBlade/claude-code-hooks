<div align="center">

<img src="../assets/logo.svg" width="480" alt="claude-code-hooks"/>

<br/>

<p>
<a href="../README.md">EN English</a> •
<a href="README_CN.md">CN 中文</a> •
<a href="README_TW.md">TW 繁體中文</a> •
<a href="README_JP.md">JP 日本語</a> •
<a href="README_PT.md">PT Português</a> •
<a href="README_ES.md">ES Español</a> •
<a href="README_DE.md">DE Deutsch</a> •
<a href="README_FR.md">FR Français</a> •
<a href="README_RU.md">RU Русский</a> •
<a href="README_AR.md">AR العربية</a> •
<a href="README_HI.md">IN हिन्दी</a> •
<a href="README_IT.md">IT Italiano</a>
</p>

**[Claude Code](https://code.claude.com)를 위한 즉시 사용 가능한 안전 훅 모음.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/훅-6개-orange.svg)](#설치-내용)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#요구-사항)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard가 위험한 명령을 차단하는 모습"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Star 히스토리"/>
</td>
</tr>
</table>

<br/>

<a href="#설치-내용">설치 내용</a> •
<a href="#bash-guard-상세">bash-guard</a> •
<a href="#git-guard-상세">git-guard</a> •
<a href="#secret-guard-상세">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#커스텀-훅-작성">커스텀 훅 작성</a> •
<a href="#요구-사항">요구 사항</a>

</div>

---

> Claude가 리팩터링 중에 `src/` 폴더 전체를 삭제했습니다.
> `main`에 있는 팀원들의 작업을 강제 푸시로 덮어썼습니다.
> 실제 API 키가 담긴 `.env` 파일을 커밋했습니다.
>
> 모두 같은 주에 일어난 일입니다.

이 훅들은 Claude와 당신의 머신 사이에서 피해가 발생하기 전에 차단합니다.

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Claude Code를 재시작하면 완료됩니다.

---

## 설치 내용

Claude Code 훅으로 등록되는 6개의 셸 스크립트. 각각 특정 유형의 피해를 대상으로 합니다.

| 훅 | 트리거 | 기능 |
|---|---|---|
| `bash-guard` | 모든 셸 명령 | `rm -rf /`·디스크 포맷·fork 폭탄·`DROP DATABASE`·파이프 실행 강제 차단 |
| `git-guard` | 모든 git 명령 | main 강제 푸시·`reset --hard HEAD~N`·보호 브랜치 삭제 강제 차단 |
| `secret-guard` | 모든 파일 쓰기 | `.env`·`*.pem`·`id_rsa`·API 키 패턴 파일 쓰기 전 경고 |
| `auto-format` | 모든 파일 편집 | prettier / black / gofmt / rustfmt 자동 실행 |
| `notify` | 작업 완료 | 데스크톱 알림으로 완료 통보 |
| `session-log` | 모든 작업 | `~/.claude/logs/`에 일별 감사 로그 기록 |

**강제 차단**: Claude는 진행할 수 없으며 이유를 전달받아 다른 방법을 찾아야 합니다.
**경고**: Claude에게 컨텍스트가 주입되며 스스로 판단하여 진행할 수 있습니다.

---

## bash-guard 상세

다음 명령들은 무조건 차단됩니다:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

경고만 발생:

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard 상세

차단:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

경고만:

```
git push --force <다른 브랜치>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard 상세

다음 파일명 쓰기 시 경고:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

다음 패턴의 내용 포함 시 경고:

```
sk-...                OpenAI 키
sk-ant-...            Anthropic 키
AKIA...               AWS 액세스 키 ID
ghp_...               GitHub 개인 액세스 토큰
xoxb-...              Slack Bot 토큰
sk_live_...           Stripe 라이브 시크릿 키
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

파일 확장자로 적절한 포매터를 자동 감지:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, 다음 black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## 제거

```bash
bash uninstall.sh
```

---

## 요구 사항

Python 3. macOS·Linux에는 기본 설치되어 있습니다. [Windows는 여기서 다운로드.](https://python.org)

---

## 관련 프로젝트

[claude-mem](https://github.com/OutBlade/claude-mem) — Claude Code의 세션 간 지속 메모리
