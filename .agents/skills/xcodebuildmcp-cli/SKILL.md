---
name: xcodebuildmcp-cli
description: Official skill for the XcodeBuildMCP CLI. Use when doing iOS/macOS/watchOS/tvOS/visionOS work (build, test, run, debug, log, UI automation).
---

# XcodeBuildMCP CLI

Use XcodeBuildMCP tools via the `xcodebuildmcp` executable instead of raw `xcodebuild`, `xcrun`, or `simctl`.

## Step 1: Ensure the CLI Exists

Check availability:
```bash
xcodebuildmcp --help
```

If missing, install with one of:
```bash
brew tap getsentry/xcodebuildmcp
brew install xcodebuildmcp
```

```bash
npm install -g xcodebuildmcp@latest
```

Re-check after install:
```bash
xcodebuildmcp --help
```

## Step 2: Use Help-First Discovery

Discover workflows and arguments from the CLI itself:
```bash
xcodebuildmcp --help
xcodebuildmcp tools
xcodebuildmcp <workflow> --help
xcodebuildmcp <workflow> <tool> --help
```

Use this discovery path instead of memorizing static tool lists.

## Step 3: Keep Execution Minimal

- Choose the smallest command sequence that satisfies the request.
- Prefer direct workflow commands over manual multi-step chains unless explicitly requested.
- For simulator run intent, prefer the combined `build-and-run` command.
- Do not chain `build` then `build-and-run` unless explicitly requested.

## Capability Overview

`xcodebuildmcp` supports:
- simulator and device build/test/run
- debugging and log capture
- UI automation
- project discovery and scaffolding
- session defaults and workflow configuration

## Exit Criteria

- CLI presence is verified or installation steps are provided.
- Commands are discovered via `--help` / `tools`.
- Session defaults are checked before first build/run/test action.
