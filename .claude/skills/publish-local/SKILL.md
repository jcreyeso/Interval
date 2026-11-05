---
name: publish-local
description: Runs the unit tests, builds Interval in Release, and installs it over /Applications/Interval.app, then relaunches it. Use when the user asks to publish locally, install, or update the app on this Mac. Does not commit or push.
---

# Publish Interval locally

Run from the repo root:

```bash
.claude/skills/publish-local/scripts/publish.sh
```

Options:

- `--skip-tests`: skip the unit tests
- `--skip-install`: test and build only; the running app is left alone
- `--no-launch`: install without relaunching

Tell the user afterwards:

- Relaunching resets the running timer, because the phase is not persisted. It only restarts by itself when "Start timer when Interval opens" is on.
- If the script reports uncommitted changes, the installed build matches no commit. Commit only if the user asks.

The script stops without touching the installed app if tests or the build fail, or if Interval will not quit. Do not force-kill it to get past that: `applicationWillTerminate` is what flushes buffered stats, so a kill loses them.
