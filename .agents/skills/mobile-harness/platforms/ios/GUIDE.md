---
name: ios-mobile-harness
description: Use for iOS device or Simulator control through mobilerun-core over cloud, mobilerun-ios local HTTP, or the ios-portal app on Simulator. Defines cloud and local iOS modes, observe-act-verify rules, and app-card loading.
---

# iOS Mobile Harness

Use this when operating an iPhone, iPad, or iOS Simulator through Mobilerun
Cloud, `mobilerun-ios`, or the `ios-portal` app.

## Scope

- iOS only.
- Primary API is `mobilerun_core.Mobilerun`.
- Cloud iOS uses `backend="cloud"`.
- Local iOS uses `backend="local-ios-http"` (`local` extra). It detects
  which local server answers:
  - **`mobilerun-ios --local <udid>`** for a USB-connected iPhone or iPad.
  - **`ios-portal` app** for the iOS Simulator; `mobilerun-ios`
    cannot drive Simulators.

## Primary Control

```python
from mobilerun_core import Mobilerun

m = Mobilerun()

# Cloud iOS.
device = m.connect("<cloud-device-id>", backend="cloud")

# Local iPhone through mobilerun-ios --local.
device = m.connect(backend="local-ios-http", url="http://127.0.0.1:8080")

# Simulator through the ios-portal app.
device = m.connect(backend="local-ios-http", url="http://127.0.0.1:6643")

device.ui()
device.screenshot()
device.start_app("com.apple.Preferences")
device.key("home")
```

Use `MOBILERUN_IOS_PORTAL_URL` to omit `url=`. A server started with
`--local-token` also needs `token=` (or `MOBILERUN_IOS_PORTAL_TOKEN`).

Use `device.supports(...)` before optional operations. On `local-ios-http`
it detects the server on first use; `device.capabilities` lists only what both
servers share until the first device call.

| Capability | `mobilerun-ios` | `ios-portal` (Simulator) |
| --- | --- | --- |
| `ui`, `screenshot`, `time`, `tap`, `swipe`, `type`, `clear_input`, `start_app` | yes | yes |
| `stop_app`, `list_apps` | yes | no |
| `install_app` (HITL-gated; the path or URL is read on the host) | yes | no |
| `uninstall_app` (HITL-gated) | yes | no |
| `get_clipboard`, `set_clipboard`, `open_deep_link` | yes | no |
| `grant_permission`, `stop_app(clear_data=True)`, `execute_script` | no | no |
| `key` names | `home`, `back`, `enter`, `delete`, `app_switch` | `home` |

Check `device.capabilities["buttons"]` before pressing a key; other names
raise.

`device.execute_script("<js>")` runs JavaScript in the device's foreground
Chrome tab and returns its JSON result (`None` when the script returns
`undefined`). Cloud devices only; local backends raise `UnsupportedOperation`.
Gate it with `device.supports("execute_script")`. On cloud connections this
check fetches device capabilities over the network once per connection, a
fetch failure raises instead of returning `False`, and it reports the device
type rather than the current browser state. `DEVICE_NO_BROWSER_TARGET` means
no debuggable foreground Chrome tab right now; `DEVICE_TOOL_UNSUPPORTED`
(HTTP 400) means the device type has no browser tooling. Neither error is a
connection failure.

## Common Helpers

Use the `device` returned by `Mobilerun.connect(...)`:

- `device.find_nodes(...)` searches the accessibility tree. `any_contains=`
  matches case-insensitive substrings across text, content description,
  resource id, and accessibility identifier. Nodes may carry `offscreen: True`
  or `hidden: True` when the tree source reports visibility. A missing flag is
  not proof of visibility; local iOS tree sources may not emit them.
- `device.tap_node(node)` taps the center of a node and fails clearly if bounds
  are missing or unusable. It may also reject a node flagged hidden.
- `device.tap_text("label")` taps the first on-screen match across text,
  description, resource id, and accessibility identifier. It raises a distinct
  error when matches exist but none are tappable on-screen.
- `device.scroll(direction, distance=0.5, ms=..., verify=False)` scrolls
  content-relative: `"down"` reveals rows below. `distance` is a fraction of
  half the screen. `verify=True` returns whether the viewport actually moved,
  at the cost of two extra UI reads; otherwise the call returns `None`.
- `device.scroll_until(text_contains=..., direction="down", max_swipes=10)`
  scrolls until a match is on-screen, returning the node or `None`. On a
  viewport stall it retries once with a stronger swipe, then returns `None`
  early instead of using the whole swipe budget. Do not re-call it blindly.
- `device.type("text", clear=True)` clears the focused field before typing
  when text input is supported. `device.clear_input()` works on both local
  servers.
- `device.current_app_id()` returns the foreground bundle id.
- `device.wait_for_app("com.apple.springboard")` after `key("home")` or
  `stop_app(...)`; the foreground app changes about two seconds later.
- `device.list_apps()` excludes system apps such as Settings; pass
  `include_system_apps=True` for all of them.
- On `mobilerun-ios`, `stop_app(...)` raises when the app is not running.
- `device.open_deep_link("https://...")` opens the URL in its default app;
  `package_name="<bundle-id>"` opens it in that app.
- `device.ui(filter=False)` returns the unfiltered tree, including off-screen
  nodes (`mobilerun-ios` only).

Accessibility bounds, `tap`, and `swipe` use iOS points; local
`device.screenshot()` is a base64 PNG in device pixels (3x on current
iPhones). Derive tap targets from nodes.

`key("back")` on `mobilerun-ios` is a left-edge swipe and can miss; if the
screen did not change, tap the navigation bar's back button.

## Local iOS Servers

- **`mobilerun-ios --local <udid>`**: default `http://127.0.0.1:8080`, one
  port per device (8080-8089). Endpoints: `/ping`, `/version`, `/state_full`,
  `/screenshot`. Setup: https://docs.mobilerun.ai/framework/guides/device-setup
  (iOS tab) and https://docs.mobilerun.ai/guides/connect-iphone (WDA signing).
- **`ios-portal`** (Simulator): default `http://127.0.0.1:6643`,
  one port per device (6643-6652). Endpoints: `/device/date`, `/state`,
  `/vision/screenshot`. Source: https://github.com/droidrun/ios-portal.

Find a running server:

```bash
for p in $(seq 8080 8089); do curl -sS --max-time 3 -w " [%{http_code}] <- $p\n" "http://127.0.0.1:$p/version"; done
for p in $(seq 6643 6652); do curl -sS --max-time 3 -w " [%{http_code}] <- $p\n" "http://127.0.0.1:$p/device/date"; done
```

- `{"status":"success","result":"iosportal(..."}` on `/version`: a
  `mobilerun-ios` server. A 401 there means it was started with
  `--local-token`.
- A JSON body with a `date` field on `/device/date`: an `ios-portal` app.
- Anything else: no server on that port.

With several devices attached, `ps ax | grep -E '[m]obilerun-ios --local|[x]codebuild test'`
shows the UDID or simulator behind each process.

## Capability Classification

1. **Cloud**: the user provided a Mobilerun Cloud device id. Use `backend="cloud"`.
2. **Local `mobilerun-ios`**: a port in 8080-8089 answers `/version` with
   `iosportal(` for the target device.
3. **Local `ios-portal`** (Simulator): a port in 6643-6652 answers
   `/device/date` for the target Simulator.
4. **No server**: start one (Setup).

Cloud requires `MOBILERUN_CLOUD_API_KEY`, `MOBILERUN_API_BASE_URL`, and
`MOBILERUN_CLOUD_DEVICE_ID`. Use
`MOBILERUN_API_BASE_URL=https://api.mobilerun.ai/v1` unless the user provides a
different endpoint.

## Setup

USB iPhone (unlocked, trusted, Developer Mode on; install the CLI with
`brew install droidrun/tap/mobilerun-ios`):

```bash
mobilerun-ios list
mobilerun-ios verify <udid>
nohup mobilerun-ios --local <udid> > /tmp/mobilerun-ios.log 2>&1 & echo $! > /tmp/mobilerun-ios.pid
```

`--local` runs in the foreground and cannot be combined with `-d`, so it is
started in the background. It is ready when `/version` answers (usually
10-30 s); stop it with `kill "$(cat /tmp/mobilerun-ios.pid)"`. It mounts the
developer disk image itself. A missing WebDriverAgent runner needs
`mobilerun-ios setup <udid>`, and an expired one (free Apple accounts expire
after 7 days) `mobilerun-ios setup <udid> --reinstall`; `setup` is interactive
and signs with the user's Apple account.

Simulator (`ios-portal`; the first run builds for a few minutes):

```bash
cd /path/to/ios-portal
nohup ./simulator.sh "<simulator-name>,OS=<ios-version>" > /tmp/ios-portal.log 2>&1 & echo $! > /tmp/ios-portal.pid
```

Simulator names repeat across iOS versions, so add the version
(`xcrun simctl list devices available`). It is ready when `/device/date`
answers; stop it with `pkill -INT -P "$(cat /tmp/ios-portal.pid)"`.

## Local HTTP Probes

```bash
curl -fsS http://127.0.0.1:8080/version
curl -fsS http://127.0.0.1:8080/state_full -o state.json
curl -fsS http://127.0.0.1:6643/device/date
curl -fsS http://127.0.0.1:6643/vision/screenshot -o screenshot.png
```

Normal actions go through `Mobilerun`:

```python
from mobilerun_core import Mobilerun

m = Mobilerun()
device = m.connect(backend="local-ios-http", url="http://127.0.0.1:8080")
device.ui()
device.start_app("com.apple.Preferences")
device.tap(100, 200)
device.swipe(200, 700, 200, 250, 500)
device.type("hello")
device.key("home")
```

## Observe-Act-Verify Loop

1. Observe with `device.ui()` before acting.
2. Identify foreground bundle id/current app when available.
3. Load `apps/ios/<bundle-id>/CARD.md` if present and not already loaded this turn.
4. Act once through `Mobilerun`.
5. Observe again with `device.ui()` and/or `device.screenshot()`.
6. If the expected change did not happen, read `platforms/ios/recovery/GUIDE.md`.

Do not chain many actions blindly.

## Credential Gate

If the screen asks for Apple ID, username, password, OTP, 2FA, passcode,
payment detail, or recovery code, stop. Read the credentials guide under
`core/credentials` and ask the user how to proceed before entering or reading
secrets if the credentials are absent.

## App Cards

App cards are not auto-loaded. When the foreground bundle id is known:

```bash
test -f apps/ios/<bundle-id>/CARD.md && sed -n '1,220p' apps/ios/<bundle-id>/CARD.md
```

Read only the current bundle card. Do not scan every app card.

## Memory

Read or write `local/memory/` only when operational facts would help future runs. Read `core/memory/GUIDE.md` first.
