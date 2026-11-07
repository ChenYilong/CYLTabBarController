---
name: android-mobile-harness
description: Use for Android phone control through mobilerun-core over cloud, ADB with optional Portal, or Portal HTTP-only. Classifies modes, defines observe-act-verify rules and app-card loading.
---

# Android Mobile Harness

Use this when operating an Android phone through Mobilerun Cloud, ADB, and/or
Mobilerun Portal.

## Scope

- Android only.
- Primary API is `mobilerun_core.Mobilerun`.
- Cloud Android uses `backend="cloud"`.
- Local public Portal only: `com.mobilerun.portal`.
- Local Android backends require `mobilerun-core` installed with the `local` extra, or `mobilerun-core-local` installed alongside it.

## Primary Control

```python
from mobilerun_core import Mobilerun

m = Mobilerun()

# Cloud Android.
device = m.connect("<cloud-device-id>", backend="cloud")

# ADB-first local Android; Portal is used automatically when available.
device = m.connect("<adb-serial>", backend="local-android-adb")

# Portal HTTP-only local Android.
device = m.connect(
    backend="local-android-http",
    url="http://127.0.0.1:18080",
    token="<portal-token>",
)

device.ui()
device.screenshot()
device.start_app("com.android.settings")
```

After connecting, inspect `device.capabilities` and use `device.supports(...)`
before optional operations.

```python
if device.supports("stop_app"):
    device.stop_app("com.android.settings")
```

`device.execute_script("<js>")` runs JavaScript in the device's foreground
Chrome tab and returns its JSON result (`None` when the script returns
`undefined`). Cloud devices only; local backends raise `UnsupportedOperation`.
Gate it with `device.supports("execute_script")` and know its quirks:

- On cloud connections this check fetches device capabilities over the
  network, once per connection, and a fetch failure raises instead of
  returning `False`. On local backends it returns `False` without any network
  call.
- It reports the device type, not the current Chrome state. A capable device
  still fails with `DEVICE_NO_BROWSER_TARGET` when no debuggable foreground
  Chrome tab exists; bring Chrome to the foreground and retry.
- `DEVICE_TOOL_UNSUPPORTED` (HTTP 400) means the device type has no browser
  tooling. Neither error is a connection failure.
- `"execute_script"` appears in `device.capabilities["actions"]` only after a
  successful `supports()` probe, so check via `supports()`, not the dict.

## Common Helpers

Prefer accessibility-tree helpers over guessed coordinates. The foreground
package is `device.current_app_id()` (`None` on an empty tree).

- `device.find_nodes(...)` accepts filters such as `text=`, `desc=`,
  `resource_id=`, `text_contains=`, `desc_contains=`, and `any_contains=`.
  `any_contains=` matches case-insensitive substrings across text, content
  description, resource id, and accessibility identifier. Nodes may carry two
  flags: `offscreen: True` marks a real element outside the viewport, scroll
  to reach it; `hidden: True` marks an element Android reports as not visible,
  collapsed or covered, so scrolling alone may not reveal it unless it is also
  offscreen. A missing flag is not proof of visibility; older tree sources do
  not emit `hidden`.
- `device.tap_node(node)` taps the center of a node and fails clearly if bounds
  are missing or unusable. Before any bounds check, it raises a distinct error
  for a node flagged hidden unless the node is also offscreen; change the UI
  state instead of retrying that tap. For an offscreen node, bring it into
  view with `scroll_until` first.
- `device.tap_text("label")` taps the first on-screen, non-hidden match across
  text, description, resource id, and accessibility identifier. It raises a
  distinct error when matches exist but none are tappable on-screen; the
  message says whether to scroll or to re-inspect.
- `device.scroll(direction, distance=0.5, ms=..., verify=False)` scrolls
  content-relative: `"down"` reveals rows below. `distance` is a fraction of
  half the screen. `verify=True` returns whether the viewport actually moved,
  at the cost of two extra UI reads; otherwise the call returns `None`. Raise
  `ms=` for lists that swallow fast swipes.
- `device.scroll_until(text_contains=..., direction="down", max_swipes=10)`
  scrolls until a match is on-screen and not hidden, returning the node or
  `None`. On a viewport stall it retries once with a stronger swipe, then
  returns `None` early. Early `None` means the viewport stopped moving; `None`
  after `max_swipes` means the swipe budget ran out. Do not re-call it
  blindly.
- `device.type("text", clear=True)` clears the focused field before typing.
  ADB-only mode supports ordinary text input; Portal remains the richer path
  when available.
- `device.clear_input()` clears the focused field when supported.
- `device.key("back")` takes a name from `device.capabilities["buttons"]`
  (`back`, `home`, `enter`, `delete`, `tab`, ...).
- `device.wait_for_app("<package>", timeout=10)` polls until that package is
  in the foreground and returns `False` on timeout.
- `device.list_apps()` excludes system apps by default. Use
  `device.list_apps(include_system_apps=True)` when a full installed-package
  inventory is needed and supported.
- `device.open_deep_link("<uri>")` opens a deep link; `package_name=` pins
  the app and `action=` sets the intent action.
- `device.grant_permission("<package>", "CAMERA")` grants a runtime
  permission; a bare name means `android.permission.<NAME>`.
- `device.ui(filter=False)` returns the unfiltered tree, including off-screen
  nodes.

## Capability Classification

Classify before acting:

1. **Cloud**: the user provided a Mobilerun Cloud device id. Use `backend="cloud"`.
2. **ADB + Portal**: ADB works and Portal's accessibility service answers (see ADB Checks). Use `backend="local-android-adb"`; core will use Portal-enhanced features automatically.
3. **ADB-only**: ADB works but Portal is missing or its accessibility service is off. Use `backend="local-android-adb"`; core still supports ADB-native UI, text input, screenshots, and app lifecycle.
4. **Portal HTTP-only**: ADB is unavailable but the user provided a reachable Portal HTTP URL and bearer token. Use `backend="local-android-http"`.
5. **Blocked**: no cloud device id, ADB, or reachable authenticated Portal HTTP is available. Stop and ask the user to provide a cloud device, enable ADB, or provide Portal HTTP access.

Cloud requires `MOBILERUN_CLOUD_API_KEY`, `MOBILERUN_API_BASE_URL`, and
`MOBILERUN_CLOUD_DEVICE_ID`. Use the default `MOBILERUN_API_BASE_URL` from
`install.md` unless the user provides a different endpoint.

For cloud devices, do not run ADB checks, Android Portal HTTP probes, or local
Portal recovery unless the user also provided a local Android target.

If ADB works and `pm list packages com.mobilerun.portal` shows Portal installed, but `content://com.mobilerun.portal/version` fails or says provider not found, `mobilerun_core` can continue through ADB-first control. Treat the Portal issue as setup debt and read `platforms/android/recovery/GUIDE.md` only when Portal-specific features are required.

An installed Portal app is not enough for Portal HTTP-only mode. The agent needs both:

- `MOBILERUN_ANDROID_PORTAL_URL`
- `MOBILERUN_ANDROID_PORTAL_TOKEN`

For `mobilerun-core`, pass those values as `url=` / `token=`, or expose them
as environment variables.

## ADB Checks

Use ADB when available:

```bash
adb devices -l
adb -s <serial> shell pm list packages com.mobilerun.portal
adb -s <serial> shell content query --uri content://com.mobilerun.portal/version
adb -s <serial> shell settings get secure enabled_accessibility_services
adb -s <serial> shell content query --uri content://com.mobilerun.portal/ping
```

Portal is active when the services list contains `com.mobilerun.portal/` and
`ping` returns `"result":"pong"`. `Accessibility service not available` means
the service is off and core runs ADB-only; enable it with the recovery guide.

If Portal is installed and ADB is available, enable HTTP on the device and forward it locally:

```bash
adb -s <serial> shell content insert --uri content://com.mobilerun.portal/toggle_socket_server --bind enabled:b:true --bind port:i:8080
adb -s <serial> forward tcp:18080 tcp:8080
```

Then use `http://127.0.0.1:18080` as the Portal URL.

## Portal HTTP Contract

Default device port is `8080`.

- `GET /ping` does not require auth and should return `pong`.
- `/ping` alone does not prove the target is an Android Portal: the local iOS
  portal (`mobilerun-ios --local`) answers the same `pong` and also defaults
  to port 8080. When the platform is ambiguous, probe `GET /version`: a 200
  whose JSON `result` field starts with `iosportal(` is the iOS local portal
  (it answers without auth unless started with `--local-token`). A 401/403 is
  ambiguous: either an Android Portal without a valid bearer token or a
  token-protected iOS local portal. Ask the user which server owns the port.
- Every other endpoint requires `Authorization: Bearer <token>`.
- Verify the token with `GET /version` before connecting through `mobilerun-core`.

Diagnostic probes:

```bash
curl -sS "$MOBILERUN_ANDROID_PORTAL_URL/ping"
curl -sS -H "Authorization: Bearer $MOBILERUN_ANDROID_PORTAL_TOKEN" "$MOBILERUN_ANDROID_PORTAL_URL/version"
curl -sS -H "Authorization: Bearer $MOBILERUN_ANDROID_PORTAL_TOKEN" "$MOBILERUN_ANDROID_PORTAL_URL/state_full"
curl -sS -H "Authorization: Bearer $MOBILERUN_ANDROID_PORTAL_TOKEN" "$MOBILERUN_ANDROID_PORTAL_URL/screenshot" -o screenshot.png
```

## ADB-Only Fallback

```bash
adb -s <serial> exec-out screencap -p > screenshot.png
adb -s <serial> exec-out uiautomator dump /dev/tty
adb -s <serial> shell input tap <x> <y>
adb -s <serial> shell input swipe <x1> <y1> <x2> <y2> <duration_ms>
adb -s <serial> shell input keyevent 4
adb -s <serial> shell monkey -p <package> 1
adb -s <serial> shell pm list packages
```

Prefer UI-tree coordinates over guessed screenshot coordinates when possible. But if UI tree is not available
or is not suitable for some reasons, use the screenshots.

## Observe-Act-Verify Loop

1. Observe current state before acting.
2. Identify foreground package and activity.
3. Load `apps/android/<package>/CARD.md` if present and not already loaded this turn.
4. Act once.
5. Observe again and verify the expected change.
6. If the expected change did not happen, read `platforms/android/recovery/GUIDE.md`.

Do not chain many actions blindly.

## Credential Gate

If the screen asks for a username, password, API key, OTP, 2FA, payment detail, recovery code, or other secret, stop. Read the credentials guide under `core/credentials` and ask the user how to proceed, unless the current action is explicitly authorized.

## App Cards

App cards are not auto-loaded. When the foreground package is known:

```bash
test -f apps/android/<package>/CARD.md && sed -n '1,220p' apps/android/<package>/CARD.md
```

Read only the current package card. Do not scan every app card.

## Memory

Read or write `local/memory/` only when operational facts would help future runs. Read `core/memory/GUIDE.md` first. Never store secrets or private screen content.
