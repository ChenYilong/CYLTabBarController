---
name: mobile-harness
description: Portable Android and iOS device-control harness for agents. Use when an agent needs to control or automate Android/iOS devices — tap, swipe, screenshot, app control — locally (ADB/Portal/Simulator) or on Mobilerun cloud devices.
---

# mobile-harness

Use this harness when an agent needs to control Android or iOS devices through
Mobilerun.

Start by reading `AGENTS.md`. It routes you to the smallest platform file for
the current task.

## Paths

When Claude Code loads this skill from a plugin, it fills in:

- `<harness-root>`: `${CLAUDE_PLUGIN_ROOT}`
- `<state-root>`: `${CLAUDE_PLUGIN_DATA}`

If those still read as `${...}` placeholders, `<harness-root>` and
`<state-root>` are both the directory containing this file.

## Primary Control Model

Normal device control always uses:

```python
from mobilerun_core import Mobilerun
```

Use `Mobilerun()` to connect to cloud devices, local Android ADB with optional
Portal, local Android Portal HTTP-only, or local iOS HTTP (`mobilerun-ios` for
USB iPhones, `ios-portal` for Simulators). Do not import
or call `mobilerun_core_local` directly for normal agent work. `mobilerun-core-local` is the
local-driver dependency used internally by `mobilerun-core` for Android and iOS
local backends.

## Load Order

1. Read `AGENTS.md`.
2. Read `platforms/android/GUIDE.md` for Android work.
3. Read `platforms/ios/GUIDE.md` for iOS work.
4. Read recovery, credentials, memory, and app-card files only when routed
   there by `AGENTS.md` or the platform guide.

For setup and runtime registration, read `install.md`.
