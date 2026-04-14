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
<a href="README_IT.md">IT Italiano</a>
</p>

**[Claude Code](https://code.claude.com) के लिए तुरंत उपयोग योग्य सुरक्षा हुक्स।**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![Hooks: 6](https://img.shields.io/badge/हुक्स-6-orange.svg)](#क्या-इंस्टॉल-होता-है)
[![Shell: bash](https://img.shields.io/badge/shell-bash-blue.svg)](#आवश्यकताएं)
[![Requires: Python 3](https://img.shields.io/badge/python-3-blue.svg)](https://python.org)

<br/>

<table>
<tr>
<td align="center">
<img src="../assets/demo.svg" width="420" alt="bash-guard एक विनाशकारी कमांड को ब्लॉक करते हुए"/>
</td>
<td align="center">
<img src="https://api.star-history.com/svg?repos=OutBlade/claude-code-hooks&type=Date" width="420" alt="Star इतिहास"/>
</td>
</tr>
</table>

<br/>

<a href="#क्या-इंस्टॉल-होता-है">क्या इंस्टॉल होता है</a> •
<a href="#bash-guard-विस्तार-से">bash-guard</a> •
<a href="#git-guard-विस्तार-से">git-guard</a> •
<a href="#secret-guard-विस्तार-से">secret-guard</a> •
<a href="#auto-format">auto-format</a> •
<a href="#अपने-हुक्स-लिखें">अपने हुक्स</a> •
<a href="#आवश्यकताएं">आवश्यकताएं</a>

</div>

---

> Claude ने refactoring के दौरान मेरा पूरा `src/` फोल्डर डिलीट कर दिया।
> उसने force-push करके `main` पर मेरी टीम का सारा काम मिटा दिया।
> उसने असली API keys वाली `.env` फाइल को commit कर दिया।
>
> यह सब एक ही हफ्ते में हुआ।

ये हुक्स Claude और आपकी मशीन के बीच खड़े होते हैं और नुकसान होने से पहले उसे रोकते हैं।

```bash
git clone https://github.com/OutBlade/claude-code-hooks
cd claude-code-hooks && bash install.sh
```

Claude Code को रिस्टार्ट करें। बस, हो गया।

---

## क्या इंस्टॉल होता है

छह shell स्क्रिप्ट जो Claude Code हुक्स के रूप में रजिस्टर होती हैं। हर एक एक खास तरह के नुकसान को रोकती है।

| हुक | कब ट्रिगर होता है | क्या करता है |
|---|---|---|
| `bash-guard` | हर shell कमांड पर | `rm -rf /`, disk format, fork bomb, `DROP DATABASE`, pipe-to-shell को हार्ड-ब्लॉक करता है |
| `git-guard` | हर git कमांड पर | main पर force-push, `reset --hard HEAD~N`, protected branch डिलीट को ब्लॉक करता है |
| `secret-guard` | हर फाइल लिखने पर | `.env`, `*.pem`, `id_rsa` या API key जैसे कंटेंट लिखने से पहले चेतावनी देता है |
| `auto-format` | हर फाइल एडिट पर | prettier / black / gofmt / rustfmt अपने आप चलाता है |
| `notify` | काम पूरा होने पर | Claude के काम खत्म होने पर desktop notification |
| `session-log` | हर ऑपरेशन पर | `~/.claude/logs/` में रोज का audit log |

**हार्ड-ब्लॉक**: Claude आगे नहीं बढ़ सकता। उसे कारण बताया जाता है और दूसरा तरीका खोजना होता है।
**चेतावनी**: Claude को context inject किया जाता है और वह खुद फैसला ले सकता है।

---

## bash-guard विस्तार से

ये कमांड बिना किसी अपवाद के ब्लॉक होती हैं:

```
rm -rf /          rm -rf ~          rm -rf .
mkfs.*            dd if=... of=/dev/sd*
:(){:|:&};:       chmod -R 777 /
DROP DATABASE     DROP SCHEMA ... CASCADE
shutdown          poweroff          halt
```

सिर्फ चेतावनी:

```
curl <url> | bash        sudo ... > /etc/
```

---

## git-guard विस्तार से

ब्लॉक:

```
git push --force origin main      git push -f origin master
git reset --hard HEAD~3           git push origin :main
```

सिर्फ चेतावनी:

```
git push --force <कोई और branch>
git commit --amend
git reset --hard HEAD
git clean -fd
```

---

## secret-guard विस्तार से

इन नामों वाली फाइलें लिखते समय चेतावनी:

```
.env  .env.*  credentials.json  secrets.yaml  *.pem  *.key  *.p12
id_rsa  id_ed25519  kubeconfig  terraform.tfvars  .netrc  .npmrc
```

इन patterns से मेल खाने वाले कंटेंट पर चेतावनी:

```
sk-...                OpenAI key
sk-ant-...            Anthropic key
AKIA...               AWS Access Key ID
ghp_...               GitHub Personal Access Token
xoxb-...              Slack Bot Token
sk_live_...           Stripe Live Secret Key
-----BEGIN * PRIVATE KEY-----
password = "..."      api_key = "..."
```

---

## auto-format

फाइल के extension से सही formatter पहचानता है:

```
.js .ts .tsx .jsx .css .html .json .yaml .md   →  prettier
.py                                              →  ruff, फिर black
.go                                              →  gofmt
.rs                                              →  rustfmt
.sh                                              →  shfmt
.lua                                             →  stylua
```

---

## अपने हुक्स लिखें

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
")

if echo "$COMMAND" | grep -q "खतरनाक-काम"; then
  echo "ब्लॉक: कारण यहाँ लिखें" >&2
  exit 2
fi
```

पूरा API reference: [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)

---

## अनइंस्टॉल

```bash
bash uninstall.sh
```

---

## आवश्यकताएं

Python 3. macOS और Linux पर पहले से इंस्टॉल। [Windows के लिए डाउनलोड करें।](https://python.org)

---

## संबंधित प्रोजेक्ट

[claude-mem](https://github.com/OutBlade/claude-mem) — Claude Code के लिए सेशन के पार persistent memory
