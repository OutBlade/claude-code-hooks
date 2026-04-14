---
name: New hook idea
about: Propose a new safety or productivity hook
title: "[hook] "
labels: new-hook
assignees: ''
---

**What should the hook do?**
A clear description of what it blocks or enables.

**Hook event**
Which event should it listen on? (PreToolUse / PostToolUse / Stop / Notification)

**Matcher**
Which tool(s) should it match? (Bash / Edit / Write / * / ...)

**Blocked or warning?**
Should it hard-block (exit 2) or inject a warning (exit 0 + systemMessage)?

**Example trigger**
Show an example command or action that should trigger it.

**Why is this hard to implement as a CLAUDE.md rule?**
Hooks run unconditionally; explain why that matters here.
