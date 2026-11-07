---
name: ios-simulator-skill
version: 1.8.0
description: Build, test, and drive iOS apps in the Simulator with 30 token-efficient scripts. Use when asked to build or test an Xcode project, launch an app on a simulator, tap/type/swipe through its UI by accessibility label, take screenshots or visual diffs, audit accessibility, read logs or diagnose hangs, or manage simulators (boot, erase, permissions, location, push, appearance). macOS only; needs Xcode, Python 3.12+ and idb.
---

# iOS Simulator Skill

Build, test, and automate iOS applications using accessibility-driven navigation and structured data instead of pixel coordinates.

## Quick Start

```bash
# 1. Check environment
bash scripts/sim_health_check.sh

# 2. Launch app
python3 scripts/app_launcher.py --launch com.example.app

# 3. Map screen to see elements
python3 scripts/screen_mapper.py

# 4. Tap button
python3 scripts/navigator.py --find-text "Login" --tap

# 5. Enter text
python3 scripts/navigator.py --find-type TextField --enter-text "user@example.com"
```

**Paths:** `scripts/` is relative to the directory containing this SKILL.md, not the user's project.
Examples write `scripts/...` for brevity; run them by absolute path from the user's project
(e.g. `python3 <skill-dir>/scripts/navigator.py ...`) so relative Xcode project paths still resolve.

All scripts support `--help` for detailed options; most support `--json` for machine-readable output.

## Navigation Strategy

**Always prefer the accessibility tree over screenshots for navigation.** The accessibility tree gives you element types, labels, frames, and tap targets — structured data that's cheaper and more reliable than image analysis.

Use this priority:
1. `screen_mapper.py` → structured element list (5-7 lines, ~10 tokens)
2. `navigator.py --find-text/--find-type/--find-id` → semantic interaction
3. Screenshots → only for visual verification, bug reports, or visual diff

Screenshots cost 1,600–6,300 tokens depending on size. The accessibility tree costs 10–50 tokens in default mode.

## 30 Production Scripts

### Build & Development (2 scripts)

1. **build_and_test.py** - Build Xcode projects, run tests, parse results with progressive disclosure
   - Build with live result streaming
   - Parse errors and warnings from xcresult bundles
   - Retrieve detailed build logs on demand
   - `--run` builds, installs and launches the app in one call: `Launched: <bundle> on <device> (pid N)`
   - Tests that never started (parallel clone failed to boot) report `Tests: NOT RUN`, not FAIL; retry with `--no-parallel`
   - Options: `--project`, `--scheme`, `--clean`, `--test`, `--run`, `--no-parallel`, `--verbose`, `--json`

2. **log_monitor.py** - Real-time log monitoring with intelligent filtering
   - Stream logs or capture by duration
   - Filter by severity (error/warning/info/debug)
   - Deduplicate repeated messages
   - Options: `--app`, `--severity`, `--follow`, `--duration`, `--output`, `--json`

### Device State (3 scripts)

3. **appearance.py** - Control simulator appearance: dark mode, Dynamic Type size, contrast, and locale/region
   - Toggle light/dark theme via `xcrun simctl ui`
   - Set Dynamic Type size with friendly aliases (XS through AX5)
   - `--contrast high|normal` toggles Increase Contrast and reads it back to confirm; `--reset` also restores normal contrast
   - Write locale and region defaults; optional app restart via `--bundle-id`
   - RTL flagged automatically for ar/he/fa/ur/yi locales
   - Options: `--theme`, `--text-size`, `--contrast`, `--locale`, `--region`, `--reset`, `--bundle-id`, `--udid`, `--json`, `--verbose`

4. **location.py** - Simulate GPS coordinates, named city presets, and GPX scenario playback
   - Fix a coordinate with `--lat`/`--lng` or pick a city with `--city`
   - Play a built-in scenario (City Run, Freeway Drive, etc.) via `--gpx <scenario>`
   - Animate multi-waypoint paths with configurable speed via `--waypoints` and `--speed`
   - Clear simulated location with `--clear`; list available scenarios with `--list-scenarios`
   - Options: `--lat`, `--lng`, `--city`, `--gpx`, `--waypoints`, `--speed`, `--clear`, `--list-scenarios`, `--udid`, `--json`, `--verbose`

5. **media.py** - Seed or empty the photo library for photo-picker tests
   - `--add a.jpg b.png` via `xcrun simctl addmedia`
   - `--clear --yes` empties the library via `idb photos clear` (idb 1.7+); `--clear --yes --add` leaves exactly the added files
   - Without `--yes`, `--clear` refuses if the library has photos (they can't be recovered): ask the user first
   - Fails fast on a missing file
   - Options: `--add`, `--clear`, `--yes`, `--udid`, `--json`

### Navigation & Interaction (5 scripts)

6. **screen_mapper.py** - Analyze current screen and list interactive elements
   - Element type breakdown
   - Interactive button list
   - Text field status
   - If labelled elements cover under 10% of the screen, adds a `Coverage:` line suggesting `--deep`
   - `--deep` reads through idb's axbridge backend (idb 1.7+): also sees Safari/WKWebView content
     and in-app alerts the default read misses, plus many unlabelled container views. It turns on
     the device's accessibility automation mode (not restored afterwards). Web-content frames are
     relative to the web view, so use `--deep` to find elements, not to take tap coordinates
   - Options: `--verbose`, `--hints`, `--deep`, `--json`

7. **navigator.py** - Find and interact with elements semantically
   - Find by text (fuzzy, or exact with `--find-exact`); interactive leaf elements rank above containers sharing the label
   - Find by element type
   - Find by accessibility ID
   - Enter text or tap elements
   - `--tap` on a Button/Link/Switch/CheckBox/Tab with a unique accessibility ID or label uses an accessibility press
     (idb 1.7+), so overlays like a floating search bar can't intercept it; output says
     `(accessibility press)`. Otherwise it taps the frame center
   - `--set-value TEXT` replaces a field's value without the keyboard (any characters, idb 1.7+).
     Focus doesn't move, so use `--enter-text` when a Return key must submit afterwards
     The value is read back before success is claimed (not for secure fields); a mismatch exits 1
   - `--tap --expect VALUE` taps only if the element's value is VALUE (toggles: `1` on, `0` off) and
     exits 1 without tapping otherwise, so "turn X off" is safe to repeat
   - iOS 27 reports toggles as `CheckBox`. Only a press flips them (no HID touch does, even on the
     switch itself); if neither ID nor label is unique, the output warns to check the value
   - A frozen app stalls every read and tap until its main thread responds
   - Failures include idb's stderr (e.g. a dead companion)
   - Options: `--find-text`, `--find-exact`, `--find-type`, `--find-id`, `--index`, `--tap`, `--expect`, `--tap-at`, `--enter-text`, `--set-value`, `--list`

8. **gesture.py** - Perform swipes, scrolls, pinches, and complex gestures
   - Directional swipes (up/down/left/right) - `--swipe` is the direction the finger moves
   - Multi-swipe scrolling - `--scroll` is the direction the content moves (`down` reveals content below)
   - Pinch zoom via `idb ui pinch` (`--pinch out` zooms in; `--scale` sets an explicit factor)
   - Long press via `idb ui tap --duration`
   - Pull to refresh
   - `--double-tap X,Y [--tap-count N]` - multi-tap at a point (idb 1.7+)
   - `--drag SOURCE DEST` - press-hold, drag, release; each end is `x,y` or an accessibility label,
     e.g. `--drag "Row 1" "Row 4"` (idb 1.7+)
   - `--rotate portrait|portrait-upside-down|landscape-left|landscape-right` - physical device rotation (idb 1.7+)
   - `--shake` - shake the device, for debug menus and undo (idb 1.7+)
   - Options: `--swipe`, `--swipe-from/--swipe-to`, `--scroll`, `--scroll-amount`, `--pinch`, `--scale`, `--long-press`, `--duration`, `--refresh`, `--double-tap`, `--tap-count`, `--drag`, `--rotate`, `--shake`

9. **keyboard.py** - Text input and hardware button control
   - Type text (fast or slow; ASCII only)
   - Special keys (return, delete, tab, space, escape, arrows), single letters, or raw HID codes
   - Key sequences (`--key-sequence h,i,return`)
   - Key chords: `--key z --command --shift` (redo); `--shift/--control/--option` need idb 1.7+
   - Clear the focused field (Cmd+A, delete)
   - Hardware buttons: home, lock/power, side, siri, apple-pay, volume-up/down (volume needs idb 1.6.3+)
   - Options: `--type`, `--slow`, `--key`, `--shift`, `--control`, `--option`, `--command`, `--count`, `--key-sequence`, `--button`, `--clear`, `--dismiss`

10. **app_launcher.py** - App lifecycle management
   - Launch apps by bundle ID
   - Terminate apps
   - Install/uninstall from .app bundles (`--uninstall` needs `--yes`: the app's data is deleted)
   - Deep link navigation
   - List installed apps
   - Check app state
   - Pass launch arguments (`--args`) and environment variables (`--env KEY=VALUE`, injected as `SIMCTL_CHILD_*`) to the app on launch/restart
   - Options: `--launch`, `--terminate`, `--restart`, `--install`, `--uninstall`, `--yes`, `--open-url`, `--list`, `--state`, `--args`, `--env`, `--wait-for-debugger`

### Testing & Analysis (9 scripts)

11. **accessibility_audit.py** - Check WCAG compliance on current screen
    - Critical issues (missing labels, empty buttons, no alt text)
    - Warnings (missing hints, small touch targets)
    - Info (missing IDs, deep nesting)
    - Options: `--verbose`, `--output`, `--json`

12. **visual_diff.py** - Compare two screenshots for visual changes
    - Pixel-by-pixel comparison
    - Threshold-based pass/fail
    - Generate diff images
    - Options: `--threshold`, `--output`, `--details`, `--json`

13. **test_recorder.py** - Automatically document test execution
    - Capture screenshots and accessibility trees per step
    - Generate markdown reports with timing data
    - Options: `--test-name`, `--output`, `--verbose`, `--json`

14. **app_state_capture.py** - Create comprehensive debugging snapshots
    - Screenshot, UI hierarchy, app logs, device info
    - Markdown summary for bug reports
    - Options: `--app-bundle-id`, `--output`, `--log-lines`, `--json`

15. **sim_health_check.sh** - Verify environment is properly configured
    - Check macOS, Xcode, simctl, IDB, Python
    - List available and booted simulators
    - Verify Python packages (Pillow)

16. **model_inspector.py** - Inspect Core Data and SwiftData models from project files
    - Parse .xcdatamodeld packages (entities, attributes, relationships)
    - Detect model versions and current active version
    - Best-effort SwiftData @Model class extraction
    - Raw source dump for any model on demand (`--raw ModelName`)
    - Options: `--project-path`, `--core-data-only`, `--swiftdata-only`, `--show-versions`, `--raw`, `--verbose`, `--json`

17. **container.py** - Inspect app sandbox: files, UserDefaults, and Core Data store paths
    - List data container files at configurable depth via `--ls`
    - Read files with auto-detected plist decoding via `--cat` (large files cached)
    - Dump UserDefaults as key=value or JSON via `--userdefaults`
    - Locate `.sqlite` / `.sqlite-wal` / `.sqlite-shm` stores via `--core-data-path`
    - Export full container snapshot via `--export`
    - Options: `--ls`, `--cat`, `--userdefaults`, `--core-data-path`, `--export`, `--udid`, `--json`, `--verbose`

18. **hang_watcher.py** (HangBuster) - Record + summarise os_log hang events with progressive disclosure
    - **Session mode (HangBuster, agent-native):** start a detached recorder, interact with the simulator, stop for a token-tight summary
      - `--start` → returns a session ID; detached worker normalises + thresholds events on the fly
      - `--stop SESSION_ID` → emits ~80–120 token L1 summary (header + top-N clusters + drill hint)
      - `--get-details SESSION_ID [--cluster N | --raw]` → L2 full clusters or L3 per-event detail
      - `--list-sessions` / `--clear-sessions [--older-than 24h]` / `--diff A B` (cross-session regression report)
      - Filter pipeline: parse → normalise → threshold → bucket → cluster → aggregate → rank → format (in `common/hang_pipeline.py`)
      - `--budget-tokens N` picks the densest level (L0/L1/L2) that fits; `--terse` forces L0
      - `--auto-sample` captures a main-thread stack on first event per cluster (soft dependency: `main_thread_sampler.py` #62; graceful no-op if absent)
    - **Raw capture mode (full fidelity for `jq` exploration):** skip the clustering pipeline, dump every matching log line verbatim to `raw.ndjson`
      - `--start --raw-capture [--max-size-mb 10] [--no-gzip]` — spawns `log stream --style ndjson`
      - Per-session size cap (`--max-size-mb`, default 10) — worker stops cleanly on cap; `extras.truncated=true`
      - `--stop` gzips `raw.ndjson` → `raw.ndjson.gz` (~15–19× compression; `--no-gzip` opts out)
      - `--get-details SESSION_ID` on a raw session prints the path with a `zcat | jq ...` hint
    - **Resilience (auto-restart on stream death):** EOF or subprocess death triggers a `stream_died` event then a bounded restart with 2s backoff. After `IOS_SIM_HANG_MAX_RESTARTS` (default 3) the session is marked `crashed`, never left in stale `running` state. `--list-sessions` shows `capture=Xs` and `restarts=N`.
    - **Cleanup is automatic:** TTL prune (`IOS_SIM_HANG_SESSION_TTL_HOURS`, default 24h) + aggregate cap (`IOS_SIM_HANG_TOTAL_CAP_MB`, default 100 MB, oldest-first eviction) both run on every `--start`.
    - **Legacy modes (unchanged for backward compat):** `--watch [--duration N]` (live stream) and `--since 5m` (historical)
    - Filters: `--bundle-id` (post-parse — hang capture stays simulator-global so RunningBoard/SpringBoard events are kept), `--predicate` (also via `IOS_SIM_HANG_PREDICATE`)
    - All output supports `--json`; session storage at `~/.ios-simulator-skill/sessions/<id>/{meta.json,events.jsonl,summary.json,raw.ndjson.gz}`

    **Quick start (summarised mode):**
    ```bash
    SID=$(python3 scripts/hang_watcher.py --start --min-hang-ms 200)
    # ... interact with the simulator (open sheets, scroll, navigate) ...
    python3 scripts/hang_watcher.py --stop $SID                  # token-tight L1 summary
    python3 scripts/hang_watcher.py --get-details $SID --cluster 1  # drill into cluster 1
    python3 scripts/hang_watcher.py --diff $SID_BASELINE $SID    # cross-session regression
    ```

    **Quick start (raw capture + `jq` exploration):**
    ```bash
    SID=$(python3 scripts/hang_watcher.py --start --raw-capture --max-size-mb 5)
    # ... interact with the simulator ...
    python3 scripts/hang_watcher.py --stop $SID
    # → "Session ...: raw mode, 737 lines, 0.96 MB → 0.05 MB gzipped"

    # Top processes by event count:
    zcat ~/.ios-simulator-skill/sessions/$SID/raw.ndjson.gz \
      | jq -s 'group_by(.processImagePath) | map({proc: (.[0].processImagePath | split("/") | last), n: length}) | sort_by(-.n) | .[:5]'

    # All RunningBoard assertion invalidations:
    zcat .../raw.ndjson.gz | jq -c 'select(.subsystem == "com.apple.runningboard" and (.eventMessage | startswith("Invalidating")))'

    # Hangs per minute:
    zcat .../raw.ndjson.gz | jq -r '.timestamp[:16]' | sort | uniq -c
    ```

19. **localization_audit.py** - Detect string catalog gaps, missing keys, and placeholder mismatches
    - Report missing and `needs_review`/`new` keys per locale in `.xcstrings` catalogs
    - Cross-reference catalog keys against Swift source (`String(localized:)` / `NSLocalizedString`) via `--source`
    - Flag placeholder count mismatches (`%d`, `%@`, `%s`, `%lld`) across locales
    - Legacy `.strings` and `.stringsdict` support via `plistlib`
    - CI-friendly `--strict` exits 2 on any finding
    - Options: `--catalog`, `--source`, `--locale`, `--strict`, `--json`, `--verbose`

### Advanced Testing & Permissions (4 scripts)

20. **clipboard.py** - Manage simulator clipboard for paste testing
    - Copy text to clipboard
    - Test paste flows without manual entry
    - Options: `--copy`, `--test-name`, `--expected`, `--json`

21. **status_bar.py** - Override simulator status bar appearance
    - Presets: clean (9:41, 100% battery), testing (11:11, 50%), low-battery (20%), airplane (offline)
    - Custom time, network, battery, WiFi settings
    - Options: `--preset`, `--time`, `--data-network`, `--battery-level`, `--clear`, `--json`

22. **push_notification.py** - Send simulated push notifications
    - Simple mode (title + body + badge)
    - Custom JSON payloads
    - Test notification handling and deep links
    - `--list` shows delivered notifications; `--clear` withdraws them all (both idb 1.7+; sending stays on simctl)
    - A push sent while its app is in the foreground isn't delivered to Notification Center, so `--list` won't show it
    - Options: `--bundle-id`, `--title`, `--body`, `--badge`, `--payload`, `--list`, `--clear`, `--json`

23. **privacy_manager.py** - Grant, revoke, and reset app permissions
    - 13 supported services (camera, microphone, location, contacts, photos, calendar, health, etc.)
    - Batch operations (comma-separated services)
    - Audit trail with test scenario tracking
    - Options: `--bundle-id`, `--grant`, `--revoke`, `--reset`, `--list`, `--json`

### Simulator Discovery (2 scripts)

24. **sim_list.py** - List simulators with progressive disclosure
    - Concise summary by default (total / available / booted)
    - Full details on demand via cache IDs
    - Filter by device type
    - Suggest recommended simulators with `--suggest`
    - 96% token reduction vs raw `simctl list` (57k → 2k tokens)
    - Options: `--get-details`, `--suggest`, `--device-type`, `--json`

25. **simulator_selector.py** - Suggest the best simulator for the job
    - Ranks candidates by recent use (from `config.json`), latest iOS, common test models, and boot status
    - List all available simulators with `--list`
    - Boot a selected simulator directly with `--boot`
    - JSON output for programmatic use
    - Options: `--suggest`, `--list`, `--boot`, `--json`

### Device Lifecycle Management (5 scripts)

26. **simctl_boot.py** - Boot simulators with optional readiness verification
    - Boot by UDID or device name
    - Wait for device ready with timeout
    - Batch boot operations (--all, --type)
    - Performance timing
    - Options: `--udid`, `--name`, `--wait-ready`, `--timeout`, `--all`, `--type`, `--json`

27. **simctl_shutdown.py** - Gracefully shutdown simulators
    - Shutdown by UDID or device name
    - Optional verification of shutdown completion
    - Batch shutdown operations
    - Options: `--udid`, `--name`, `--verify`, `--timeout`, `--all`, `--type`, `--json`

28. **simctl_create.py** - Create simulators dynamically
    - Create by device type and iOS version
    - List available device types and runtimes
    - Custom device naming
    - Returns UDID for CI/CD integration
    - Options: `--device`, `--runtime`, `--name`, `--list-devices`, `--list-runtimes`, `--json`

29. **simctl_delete.py** - Permanently delete simulators
    - Delete by UDID or device name
    - Refuses without `--yes` (no prompt; the simulator and its data can't be recovered): ask the user first
    - Batch delete operations
    - Smart deletion (--old N to keep N per device type)
    - Options: `--udid`, `--name`, `--yes`, `--all`, `--type`, `--old`, `--json`

30. **simctl_erase.py** - Factory reset simulators without deletion
    - Preserve device UUID (faster than delete+create)
    - Erase all, by type, or booted simulators
    - Optional verification
    - Refuses without `--yes` (apps, data and settings can't be recovered): ask the user first
    - Options: `--udid`, `--name`, `--yes`, `--verify`, `--timeout`, `--all`, `--type`, `--booted`, `--json`

## Common Patterns

**Auto-UDID Detection**: Most scripts auto-detect the booted simulator if --udid is not provided.

**Device Name Resolution**: Use device names (e.g., "iPhone 16 Pro") instead of UDIDs - scripts resolve automatically.

**Batch Operations**: Many scripts support `--all` for all simulators or `--type iPhone` for device type filtering.

**Output Formats**: Default is concise human-readable output. Use `--json` for machine-readable output in CI/CD.

**Help**: All scripts support `--help` for detailed options and examples.

**Screenshot Sizing**: Screenshots are resized to save tokens. Presets: `full` (3-4 tiles, ~5K tokens), `half` (1 tile, ~1.6K tokens, default), `quarter` (1 tile, ~800 tokens, less detail). Use `quarter` for quick visual checks, `half` for readable UI, `full` only when pixel-level detail matters. Scripts that capture screenshots (`app_state_capture.py`, `test_recorder.py`) default to `half`.

## Typical Workflow

1. Verify environment: `bash scripts/sim_health_check.sh`
2. Launch app: `python3 scripts/app_launcher.py --launch com.example.app`
3. Analyze screen: `python3 scripts/screen_mapper.py`
4. Interact: `python3 scripts/navigator.py --find-text "Button" --tap`
5. Verify: `python3 scripts/accessibility_audit.py`
6. Debug if needed: `python3 scripts/app_state_capture.py --app-bundle-id com.example.app`

## Configuration

Most operational limits can be tuned via environment variables. Defaults work for typical local development; raise them for slow CI runners, large monorepo builds, or accessibility audits on complex screens.

| Variable | Default | Controls |
|---|---|---|
| `IOS_SIM_A11Y_LABEL_MAX` | `80` | Max chars of `AXLabel` retained in accessibility audit output |
| `IOS_SIM_A11Y_TOP_ISSUES` | `10` | Top accessibility issues surfaced per audit |
| `IOS_SIM_APPS_PREVIEW` | `30` | App entries listed by `app_launcher.py` before truncation |
| `IOS_SIM_BOOT_SUBPROCESS_TIMEOUT` | `60` | Timeout for the `simctl boot` subprocess itself (seconds) |
| `IOS_SIM_BOOT_TIMEOUT` | `300` | Wait-for-ready timeout after boot (seconds) |
| `IOS_SIM_BUILD_JSON_CAP` | `50` | Max build errors / failed tests in JSON output |
| `IOS_SIM_BUILD_LOG_PREVIEW` | `4000` | Chars of build log preview in default output |
| `IOS_SIM_BUILD_TIMEOUT` | `1800` | Max seconds for an `xcodebuild build` invocation before kill |
| `IOS_SIM_INTROSPECT_TIMEOUT` | `60` | Timeout for `xcodebuild -list` and `simctl list` lookups (seconds) |
| `IOS_SIM_TEST_TIMEOUT` | `2700` | Max seconds for an `xcodebuild test` invocation before kill |
| `IOS_SIM_BUILD_SUMMARY_CAP` | `15` | Errors/failures in default build summary |
| `IOS_SIM_BUILD_VERBOSE_CAP` | `100` | Errors/warnings in verbose build output |
| `IOS_SIM_CACHE_MAX_ENTRIES` | `500` | Max entries in progressive disclosure cache (LRU eviction) |
| `IOS_SIM_CACHE_TTL_HOURS` | `1` | Cache entry expiration |
| `IOS_SIM_ERASE_TIMEOUT` | `90` | Wait-for-erase timeout (seconds) |
| `IOS_SIM_HANG_PREDICATE` | _(default)_ | Override the `os_log` predicate used by `hang_watcher.py` (default catches RunningBoard kills + "Hang detected" + main-thread hangs). Hang events originate from system daemons (RunningBoard, SpringBoard) so the predicate stays simulator-global — `--bundle-id` is applied post-parse, not ANDed in. |
| `IOS_SIM_HANG_MIN_MS` | `250` | HangBuster threshold — events below this duration never reach disk (smaller = more sensitive, larger summaries) |
| `IOS_SIM_HANG_SESSION_TTL_HOURS` | `24` | HangBuster session prune age; pruning runs on every `--start` |
| `IOS_SIM_HANG_DEFAULT_TOP_N` | `3` | Default top-N clusters in `--stop` L1 output |
| `IOS_SIM_HANG_BUDGET_TOKENS` | _(unset)_ | Default token budget for `--stop` (picks L0/L1/L2 to fit) |
| `IOS_SIM_HANG_MAX_RESTARTS` | `3` | HangBuster worker: max `log stream` respawn attempts on EOF/subprocess death before the session is marked `crashed` |
| `IOS_SIM_HANG_TOTAL_CAP_MB` | `100` | HangBuster aggregate disk cap. When total session-state exceeds this on `--start`, oldest sessions are dropped first. Set to `0` to disable. |
| `IOS_SIM_LOG_JSON_CAP` | `100` | Max errors/warnings in `log_monitor.py` JSON output |
| `IOS_SIM_LOG_LINE_MAX` | `300` | Per-line truncation in log summaries |
| `IOS_SIM_LOG_TAIL` | `200` | Lines of log tail in verbose / sample output |
| `IOS_SIM_LOG_TEXT_SUMMARY` | `15` | Errors/warnings shown in text-mode log summary |
| `IOS_SIM_MAX_ELEMENTS` | `25` | Items listed by `navigator.py --list` and `push_notification.py --list` |
| `IOS_SIM_POLL_INTERVAL` | `0.5` | Boot/erase state polling interval (seconds) |
| `IOS_SIM_RELAUNCH_DELAY_MS` | `1000` | Delay between terminate and re-launch in `app_launcher.py` |
| `IOS_SIM_SCREEN_BUTTONS_PREVIEW` | `15` | Button names listed by `screen_mapper.py` |
| `IOS_SIM_SCREEN_SECTION_ITEMS` | `10` | Items per section shown by `screen_mapper.py` |
| `IOS_SIM_STATE_SUBPROCESS_TIMEOUT` | `15` | Subprocess timeout in `app_state_capture.py` (seconds) |
| `IOS_SIM_TAP_SETTLE_MS` | `500` | Post-tap settle delay in `navigator.py` |

Example:

```bash
# Slow GitHub Actions runner: give boot 10 minutes
IOS_SIM_BOOT_TIMEOUT=600 python3 scripts/simctl_boot.py --wait-ready
```

## Requirements

- macOS 15 (Sequoia)+
- Xcode 26+ (the full app; Command Line Tools alone are not enough for idb)
- Apple silicon Mac (the Homebrew idb build is arm64-only)
- Python 3.12+
- `idb` **1.5.1+** (1.6.3+ recommended) - required for every interactive script (tap, swipe, type):
  `brew install facebook/fb/idb` (installs both idb-cli and idb-companion)
- Pillow, for visual diffs only: `pip3 install pillow`

Verify with `bash scripts/sim_health_check.sh` (add `--json` for structured output).

## Troubleshooting

**Taps, swipes and typing do nothing, but reads work.** `idb` reports success and the screen
never changes. On Xcode 27 this means `idb-companion` is older than 1.5.1: it looks for
`SimulatorKit.framework` at the path Xcode 26 used. Upgrade both together, then restart running
companions: `brew upgrade facebook/fb/idb-cli facebook/fb/idb-companion && idb kill`.

**`SimulatorKit is required for HID interactions`.** Same cause, same fix.

**Health check warns "idb companions started before idb-companion was last installed".** Those
companions still run the pre-upgrade binary. Run `idb kill`; the next idb call starts a fresh one.

**`Connection refused` or `No such file` from every idb call.** A dead companion is still in
idb's registry at `/tmp/idb/state`, so idb dials a socket nobody is listening on instead of
starting a fresh companion. Fix: `idb disconnect <udid>`.

**`open -a Simulator` fails.** Xcode 27 has no `Simulator.app`; it was replaced by
`DeviceHub.app` in `Xcode.app/Contents/Applications/`. Boot headlessly instead:
`xcrun simctl boot <udid>`. Note that quitting DeviceHub shuts down the simulator it hosts.

**`idb: command not found`.** The companion and the CLI are separate packages;
`brew install facebook/fb/idb` installs both. If `which -a idb` shows more than one, the first on
`PATH` wins. An old pip `fb-idb` there needs `pip uninstall fb-idb`.

**Known upstream idb issues** (open as of idb 1.7.6):
- [facebook/idb#964](https://github.com/facebook/idb/issues/964): on some iOS 26+ screens
  `describe-all` returns only the application node, and SpringBoard alerts can't be tapped. The
  default `ax` backend can't see across process boundaries; try
  `idb ui describe-all --json --api axbridge`. Tap coordinates are points, not screenshot pixels.
  After an app relaunch the default read can also stay stuck on a single zero-size Application
  node; one `screen_mapper.py --deep` read (which may itself time out once) brings it back.
- [facebook/idb#978](https://github.com/facebook/idb/issues/978): accessibility custom actions
  are listed by `describe-all` but can't be performed.
- [facebook/idb#954](https://github.com/facebook/idb/issues/954): the Homebrew build is
  arm64-only, so Intel Macs are unsupported.

## Documentation

- **SKILL.md** (this file) - Script reference, requirements, troubleshooting
- **[README.md](https://github.com/conorluddy/ios-simulator-skill/blob/main/README.md)** - Installation, updating idb, Xcode 27 notes
- **[AGENTS.md](https://github.com/conorluddy/ios-simulator-skill/blob/main/AGENTS.md)** - Architecture and implementation details

## Key Design Principles

**Semantic Navigation**: Find elements by meaning (text, type, ID) not pixel coordinates. Survives UI changes.

**Token Efficiency**: Concise default output (3-5 lines) with optional verbose and JSON modes for detailed results.

**Accessibility-First**: Built on standard accessibility APIs for reliability and compatibility.

**Zero Configuration**: Works immediately on any macOS with Xcode. No setup required.

**Structured Data**: Scripts output JSON or formatted text, not raw logs. Easy to parse and integrate.

**Auto-Learning**: Build system remembers your device preference. Configuration stored per-project.

---

Use these scripts directly or let Claude Code invoke them automatically when your request matches the skill description.
