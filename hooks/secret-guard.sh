#!/usr/bin/env bash
# secret-guard — warns before writing files that may contain secrets
# Hook event: PreToolUse (matcher: Edit|Write)
#
# Detects: .env files, private keys, API key patterns (OpenAI, AWS, GitHub,
#          Stripe, etc.), hardcoded passwords, and sensitive filenames.
# Action:  Adds a systemMessage warning. Does not block (Claude may legitimately
#          create placeholder .env files). Claude will see the warning and can
#          choose to add .gitignore entries or ask the user.

set -euo pipefail

PYTHON=$(for cmd in python3 python py; do p=$(command -v "$cmd" 2>/dev/null) && "$p" -c "import sys; assert sys.version_info[0]==3" 2>/dev/null && echo "$p" && break; done)
[ -z "$PYTHON" ] && exit 0

INPUT=$(cat)

parse_python() {
  echo "$INPUT" | "$PYTHON" - <<'PYEOF'
import sys, json, re, os

d = json.load(sys.stdin)
ti = d.get('tool_input', {})
tool = d.get('tool_name', '')

file_path = ti.get('file_path', '')
# Edit uses new_string, Write uses content
content = ti.get('new_string', '') or ti.get('content', '')

warnings = []

# --- Sensitive filename patterns ---
filename = os.path.basename(file_path).lower()
sensitive_names = [
  r'^\.env(\.|$)', r'credentials?\.json$', r'secrets?\.json$',
  r'secrets?\.ya?ml$', r'\.pem$', r'\.key$', r'\.p12$', r'\.pfx$',
  r'^id_rsa$', r'^id_ed25519$', r'^id_dsa$', r'^id_ecdsa$',
  r'service.?account.*\.json$', r'\.netrc$', r'\.npmrc$',
  r'kubeconfig$', r'terraform\.tfvars$',
]
for pat in sensitive_names:
  if re.search(pat, filename, re.IGNORECASE):
    warnings.append(f"Sensitive filename: {os.path.basename(file_path)}")
    break

# --- Secret patterns in content ---
if content:
  secret_patterns = [
    (r'sk-[a-zA-Z0-9]{40,}', 'OpenAI API key'),
    (r'sk-ant-[a-zA-Z0-9\-_]{40,}', 'Anthropic API key'),
    (r'AKIA[A-Z0-9]{16}', 'AWS Access Key ID'),
    (r'(?i)aws.{0,20}secret.{0,20}["\']([a-zA-Z0-9/+=]{40})["\']', 'AWS Secret Key'),
    (r'ghp_[a-zA-Z0-9]{36}', 'GitHub personal access token'),
    (r'ghs_[a-zA-Z0-9]{36}', 'GitHub Actions token'),
    (r'github_pat_[a-zA-Z0-9_]{82}', 'GitHub fine-grained PAT'),
    (r'xox[baprs]-[a-zA-Z0-9\-]+', 'Slack token'),
    (r'sk_live_[a-zA-Z0-9]{24,}', 'Stripe live secret key'),
    (r'-----BEGIN\s+(RSA |EC |OPENSSH )?PRIVATE KEY-----', 'Private key block'),
    (r'(?i)(password|passwd|pwd)\s*[=:]\s*["\'][^"\']{6,}["\']', 'Hardcoded password'),
    (r'(?i)(api.?key|apikey|api.?secret)\s*[=:]\s*["\'][^"\']{8,}["\']', 'Hardcoded API key'),
    (r'(?i)(bearer|token)\s+[a-zA-Z0-9\-._~+/]{20,}', 'Bearer token in content'),
  ]
  for pattern, label in secret_patterns:
    if re.search(pattern, content):
      warnings.append(f"Possible {label} found in file content")

if warnings:
  msg = "secret-guard detected potential secrets in " + file_path + ":\\n"
  for w in warnings:
    msg += "  * " + w + "\\n"
  msg += "Make sure this file is in .gitignore and will not be committed."
  import json as j
  print(j.dumps({"continue": True, "systemMessage": msg}))
PYEOF
}

OUTPUT=$(parse_python)

if [ -n "$OUTPUT" ]; then
  echo "$OUTPUT"
fi

exit 0
