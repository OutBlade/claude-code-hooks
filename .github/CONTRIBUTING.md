# Contributing

## Adding a new hook

1. Create `hooks/your-hook-name.sh`
2. Add the header comment block (event, matcher, behavior)
3. Read JSON from stdin, parse with Python 3
4. Exit 0 on the happy path — no output, no noise
5. Exit 2 to block, with the reason written to stderr
6. Exit 0 with `{"continue":true,"systemMessage":"..."}` on stdout to warn without blocking
7. Add it to `install.sh` HOOKS array and `merge-settings.py` HOOK_CONFIG
8. Document it in README.md and all translation files in `docs/`

## Hook requirements

- Single self-contained shell script
- Only requires Python 3 and tools that ship with the OS
- Silent on the happy path
- Fails open (if the hook crashes, Claude should proceed — use `|| exit 0` on the PYTHON detection)
- Tested on macOS, Linux, and Windows Git Bash

## Translations

If you speak a language listed in the README header, corrections and improvements to `docs/README_XX.md` are very welcome.
