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
<a href="README_HI.md">IN हिन्दी</a> •
<a href="README_IT.md">IT Italiano</a>
</p>

**خطافات أمان جاهزة للاستخدام مع [Claude Code](https://code.claude.com).**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/خطافات-6-orange.svg)](#ما-يتم-تثبيته)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#المتطلبات)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard يحجب أمرًا مدمرًا"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="سجل النجوم"/>
</td>
</tr>
</table>

<br/>

<a href="#ما-يتم-تثبيته">ما يتم تثبيته</a> •
<a href="#bash-guard-بالتفصيل">bash-guard</a> •
<a href="#git-guard-بالتفصيل">git-guard</a> •
<a href="#secret-guard-بالتفصيل">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#كتابة-خطافاتك-الخاصة">خطافاتك الخاصة</a> •
<a href="#المتطلبات">المتطلبات</a>

</div>

---

<div dir="rtl">

> حذف Claude مجلد `src/` بأكمله أثناء إعادة الهيكلة.
> قام بـ force-push وكتب فوق عمل فريقي في `main`.
> أضاف ملف `.env` الخاص بي — مع مفاتيح API الحقيقية — إلى الـ commit.
>
> كل هذا في نفس الأسبوع.

هذه الخطافات تقف بين Claude وجهازك، وتعترض الأضرار قبل وقوعها.

</div>

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

<div dir="rtl">أعد تشغيل Claude Code. انتهى الأمر.</div>

---

## ما يتم تثبيته

<div dir="rtl">ستة سكريبتات shell مسجّلة كخطافات لـ Claude Code. كل منها يستهدف فئة محددة من الأضرار.</div>

| الخطاف | يُفعَّل عند | الوظيفة |
|---|---|---|
| `bash-guard` | كل أمر shell | يحجب `rm -rf /` وتهيئة الأقراص وقنابل fork و`DROP DATABASE` والتنفيذ عبر الأنابيب |
| `git-guard` | كل أمر git | يحجب force-push إلى main و`reset --hard HEAD~N` وحذف الفروع المحمية |
| `secret-guard` | كل كتابة ملف | يحذّر قبل كتابة `.env` و`*.pem` و`id_rsa` أو محتوى يشبه مفاتيح API |
| `auto-format` | كل تعديل ملف | يشغّل prettier / black / gofmt / rustfmt تلقائيًا |
| `notify` | اكتمال المهمة | إشعار سطح المكتب عند انتهاء Claude |
| `session-log` | كل شيء | سجل تدقيق يومي في `~/.claude/logs/` |

<div dir="rtl">

**الحجب الصارم**: لا يستطيع Claude المتابعة. يتلقى السبب ويجب أن يجد مقاربة أخرى.
**التحذير**: يتلقى Claude سياقًا مُدرجًا ويمكنه اتخاذ قراره.

</div>

---

## bash-guard بالتفصيل

<div dir="rtl">هذه الأوامر محجوبة بشكل مطلق:</div>

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

<div dir="rtl">تحذير فقط:</div>

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard بالتفصيل

<div dir="rtl">محجوب:</div>

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

<div dir="rtl">تحذير فقط:</div>

```
git push --force <فرع آخر>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard بالتفصيل

<div dir="rtl">يحذّر عند الكتابة في ملفات بهذه الأسماء:</div>

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

<div dir="rtl">يحذّر عند تطابق المحتوى مع هذه الأنماط:</div>

```
sk-...                مفتاح OpenAI
sk-ant-...            مفتاح Anthropic
AKIA...               AWS Access Key ID
ghp_...               GitHub Personal Access Token
xoxb-...              Slack Bot Token
sk_live_...           Stripe Live Secret Key
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

<div dir="rtl">يكتشف المُنسِّق المناسب من امتداد الملف:</div>

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff ثم black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## كتابة خطافاتك الخاصة

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "شيء-خطير"; then
  echo "محجوب: اكتب السبب هنا" >&2
  exit 2
fi
```

<div dir="rtl">المرجع الكامل للـ API: <a href="https://docs.anthropic.com/en/docs/claude-code/hooks">توثيق خطافات Claude Code</a></div>

---

## إلغاء التثبيت

```bash
bash uninstall.sh
```

---

## المتطلبات

<div dir="rtl">Python 3. مثبّت مسبقًا على macOS وLinux. <a href="https://python.org">تنزيل لـ Windows.</a></div>

---

## مشاريع ذات صلة

[claude-mem](https://github.com/OutBlade/claude-mem) — <span dir="rtl">ذاكرة دائمة بين الجلسات لـ Claude Code</span>
