---
name: run-device
description: Build, install, and launch an iOS app on a physical iPhone or iPad entirely from the command line (no Xcode GUI), using xcodebuild + devicectl. Use when the user wants to run, test, or screenshot their app on a real device without opening Xcode.
allowed-tools: [Bash, Read]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Run on a Physical Device (CLI)

Builds, signs, installs, and launches an app on a **connected physical device**
straight from the terminal — no Xcode Run button. The companion `run-simulator`
skill covers the Simulator; this is the hardware path, which uses a different
toolchain: `devicectl` (not `simctl`), real code signing, and an external tool
for screenshots.

Building proves the code typechecks and signs; launching proves it installs and
runs on real hardware. A crash on launch or a failed install is a failure.

## When This Skill Activates

Use when the user wants to:
- Run / test their app on a real iPhone or iPad from the CLI
- Install a build on a device without opening Xcode
- Reproduce a device-only bug (camera, sensors, performance, push)
- Screenshot the app running on hardware

Not for the Simulator (use `run-simulator`) and not for `xcodebuild test`.

## Prerequisites (one-time, partly interactive — cannot be scripted)

1. **Device connected** by USB (or paired over Wi-Fi).
2. **Developer Mode ON** (iOS 16+): Settings → Privacy & Security → Developer
   Mode → on → restart. There is no CLI to enable this.
3. **Device trusted/paired**: the first connection shows "Trust This Computer?"
   on the device — tap Trust. `devicectl` pairs once trusted.
4. **Automatic signing configured**: the target needs `CODE_SIGN_STYLE = Automatic`
   and a `DEVELOPMENT_TEAM`, and the signing Apple ID must already be logged into
   Xcode (Settings → Accounts) so `-allowProvisioningUpdates` can mint profiles.
   A free personal team works but apps expire after 7 days.

Confirm reachability before building:

```bash
xcrun devicectl list devices
```

The **Identifier** column is a CoreDevice UUID (e.g. `A1B2C3D4-…`). It is used by
`devicectl` for install/launch. **It is NOT the value `xcodebuild` wants** — see
the trap in step 2. Pick a row whose State is `available (paired)` /
`connected`.

## Process

### 1. Pick the device identifier

```bash
xcrun devicectl list devices    # grab the Identifier (CoreDevice UUID) of the paired device
```

Store it: `DEV=<identifier-from-the-Identifier-column>`.

### 2. Build + sign for a device

**Trap:** `xcodebuild` matches on the *hardware* UDID, not the `devicectl`
identifier. Passing `-destination 'platform=iOS,id=<devicectl-id>'` fails with
*"Unable to find a device matching the provided destination specifier."* Build
for a generic device instead — it produces the same signed `.app`:

```bash
xcodebuild build \
  -project MyApp.xcodeproj -scheme MyApp \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates 2>&1 | tail -5
```

(Use `-workspace MyApp.xcworkspace` instead of `-project` if the project has one.)
Look for `** BUILD SUCCEEDED **`. `-allowProvisioningUpdates` lets xcodebuild
register the device and create/refresh the provisioning profile automatically.

Common failures:
- *"Signing requires a development team"* → set `DEVELOPMENT_TEAM=XXXXXXXXXX` on
  the command line, or fix it in project settings.
- *"No profiles for '…' were found"* → add `-allowProvisioningUpdates` (above), and
  make sure the signing Apple ID is logged into Xcode.

### 3. Resolve the built `.app` (device build → `Debug-iphoneos`)

Don't guess DerivedData — read it from build settings. Note the directory is
`Debug-iphoneos` for device builds (vs `Debug-iphonesimulator` for the Simulator):

```bash
eval $(xcodebuild -project MyApp.xcodeproj -scheme MyApp \
  -destination 'generic/platform=iOS' -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ TARGET_BUILD_DIR =/{print "DIR=\""$2"\""} / FULL_PRODUCT_NAME =/{print "NAME=\""$2"\""}')
APP="$DIR/$NAME"   # .../Debug-iphoneos/MyApp.app
BID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist")
```

### 4. Install

```bash
xcrun devicectl device install app --device "$DEV" "$APP"
```

Prints `App installed:` with the `bundleID` and `installationURL` on success.

### 5. Launch

```bash
xcrun devicectl device process launch --device "$DEV" "$BID"
```

Prints `Launched application with <bundle id> …`.

**Known quirk:** adding `--terminate-existing` (to relaunch a running app)
sometimes returns `CoreDeviceError 10004 — "process identifier … could not be
determined"` even though the app launched. If you see it, run the **plain**
launch above and verify it's actually running:

```bash
xcrun devicectl device info processes --device "$DEV" | grep -i MyApp.app
```

A matching `pid  /…/MyApp.app` line confirms it's live.

### 6. Screenshot (optional — needs an extra tool)

`devicectl` has **no** screenshot command, so device screenshots require
[`libimobiledevice`](https://libimobiledevice.org):

```bash
brew install libimobiledevice          # one-time
idevicescreenshot /tmp/device-shot.png # captures the foreground screen
```

Then **Read `/tmp/device-shot.png`** and verify the change renders.

Caveats:
- `idevicescreenshot` needs the Developer Disk Image mounted. Running the app via
  `devicectl` (steps 4–5) mounts it, so screenshot *after* launching.
- If multiple devices are attached, target one: `idevicescreenshot -u <hardware-udid> …`
  (`idevice_id -l` lists hardware UDIDs — again, distinct from the `devicectl` id).
- On a headless/CI box without Homebrew, this step isn't available; fall back to a
  manual screenshot on the device.

## Output Format

Report:
- Device used (name + identifier) and that it was paired/available
- Build result (`** BUILD SUCCEEDED **` or the `error:` lines, then stop)
- Install result and launch confirmation (pid or the running-process check)
- If screenshotted: read the image back and state whether it confirms the change
- Any interactive prerequisite the user must still do (enable Developer Mode, tap
  Trust, log the Apple ID into Xcode)

## Reliability Notes

- **Wrong identifier for `xcodebuild`** → "Unable to find a device matching the
  destination." Build `generic/platform=iOS`; use the `devicectl` id only for
  install/launch (step 2 trap).
- **`-quiet` hides success** → it suppresses `** BUILD SUCCEEDED **`; drop it for
  the confirming run or grep `error:`.
- **`10004` on launch** → usually a false alarm from `--terminate-existing`; plain
  launch + `device info processes` confirms (step 5).
- **Developer Mode / Trust** → cannot be enabled from the CLI; if install fails
  with a pairing/trust error, have the user complete it on-device once.
- **Profile expiry** → free-team builds stop launching after 7 days; rebuild.
- **Wi-Fi devices** → `devicectl` works over the network once paired; the device
  must be awake and on the same network.
- **Stale install** → if behavior looks unchanged, uninstall then reinstall:
  `xcrun devicectl device uninstall app --device "$DEV" "$BID"`.
