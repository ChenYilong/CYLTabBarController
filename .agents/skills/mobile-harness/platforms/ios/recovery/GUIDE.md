---
name: ios-mobile-recovery
description: Use after mobilerun-ios or ios-portal HTTP, WebDriverAgent or XCTest session, state, screenshot, accessibility, input, or app-control failures while using mobile-harness.
---

# iOS Recovery

Use this only after a concrete iOS control failure.

## Classify The Failure

- **No local server**: the first device call raises
  `ConnectionError: No iOS portal answered at ...`. Run Server Triage.
- **Server exited**: requests start failing after earlier success, usually
  because the `mobilerun-ios` process or the Simulator's `ios-portal` XCTest
  runner stopped.
- **State extraction failure**: `ui()` returns but required state fields are
  missing or repeatedly empty while the UI is stable.
- **Screenshot failure**: `screenshot()` is not a PNG, is empty, or times out.
- **Input failed**: tap/type returns success but the UI did not change.
- **App blocked**: Crash or frozen UI.

## Server Triage

Probe both port ranges as in "Local iOS Servers" in `platforms/ios/GUIDE.md`.
If a server for the target answers, reconnect to its URL. Otherwise start one
(Setup Recovery).

## Setup Recovery

USB iPhone:

```bash
mobilerun-ios list
mobilerun-ios verify <udid>
```

Then start `mobilerun-ios --local <udid>` as in Setup in
`platforms/ios/GUIDE.md`. If it exits, `/tmp/mobilerun-ios.log` says why:

- Device not in `list`: it is not connected over USB or not trusted.
- Runner app missing: `mobilerun-ios setup <udid>`. Runner installed but
  WebDriverAgent never starts (expired signature):
  `mobilerun-ios setup <udid> --reinstall`.
- `device ... is busy`: another `mobilerun-ios` process owns the device. Use
  its server if it is a `--local` one; otherwise stop that process and retry.
- `address already in use`: start with a free
  `--local-addr 127.0.0.1:<port>` in 8081-8089.

When requests keep failing while the server is still running, stop it and
start it again; it restarts a wedged WebDriverAgent runner itself.

Simulator: start `ios-portal` as in Setup in `platforms/ios/GUIDE.md`.

## Action Recovery

After a failed tap, swipe, type, launch, or key:

1. Observe again with `device.ui()`.
2. Check whether an app changed the target.
3. Use accessibility bounds when available; they are in points, not
   screenshot pixels.
4. Use screenshot for verification.
5. Try one alternative action. After a missed `key("back")`, tap the
   navigation bar's back button.
6. If still stuck, stop and report the exact blocker.

## Credential Or Human-Gated Screens

If the blocker is Apple ID, login, passcode, OTP, API key, payment, account recovery, or consent for destructive action, read the credentials guide under `core/credentials` and ask the user how to proceed, unless the current action is explicitly authorized.
