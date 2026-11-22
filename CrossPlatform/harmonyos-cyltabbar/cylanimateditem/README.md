# cylanimateditem

The animated icon + title component of CYLTabBarController for HarmonyOS NEXT (`CYLAnimatedItemView`,
`CYLAnimatedItemStackView`, `CYLAnimatedItemEngines`). It depends on no other package and on no animation library.
Guide: [docs/Animated-Item.md](../../../docs/Animated-Item.md) in CYLTabBarController.

## x86_64 emulator

The local HarmonyOS emulator (Mate 70 Pro image, HarmonyOS 6.0.1) is x86_64. `@ohos/rive` 1.0.4 (`libohos_rive.so`) and
`@tencent/libpag` 4.4.31 (`libpag.so`) ship `arm64-v8a` libraries only, so a HAP that bundles them does not install
there ("install parse native so failed", error 9568347), and a HAP without them crashes at the first PAG or Rive view.
This module owns the x86_64 test path, so every app and library that depends on it (the cyltabbar example,
CollectionViewClassifyMenu, CYLTableViewPlaceHolder, CYLSearchViewController) can test fully on the x86_64 emulator.

### 1. Runtime check (in this module)

`CYLAnimatedItemEngines` reads the device's ABIs (`deviceInfo.abiList`) and knows the ABIs each engine's library ships:
PAG and Rive need `arm64-v8a`; Lottie, SVGA and GIF are pure ArkTS. On a device without them:

- `CYLAnimatedItemEngines.canPlay(url)` is false, so `CYLAnimatedItemView` never calls `animationBuilder` for that item:
  no engine view is created, nothing loads the missing `.so`, and the item shows its still image (or the placeholder).
- `CYLAnimatedItemEngines.isSupportedOnDevice('Rive')` is false and `unsupportedReason(url)` says why
  ("Rive needs a native library built for arm64-v8a; this device has x86_64"); debug builds log it once per type.
- `setRequiredNativeAbis(type, abis)` (or the fourth argument of `register`) changes what an engine needs, e.g. when a
  library version adds x86_64, or for an app's own engine with a native library; `setDeviceAbis(['x86_64'])` simulates
  the emulator in a test.

Static imports of `@ohos/rive` / `@tencent/libpag` are fine: the native library is resolved when a view is created
(checked 2026-11-22: CollectionViewClassifyMenu's animations page, which imports both statically, ran without its
`.so` files once no PAG or Rive view was built). An app that creates PAG or Rive views outside `animationBuilder`
checks `CYLAnimatedItemEngines.isSupportedOnDevice(type)` first.

### 2. A HAP for the emulator (in the app's build profile)

`entry/build-profile.json5`: an `emulator` build option that leaves out every `arm64-v8a` library (`libc++_shared.so`
too: leaving it alone still fails the install), an `emulator` target bound to it, and, for an app with an `ohosTest`
target, an `emulatorTest` build mode:

```json5
"buildOptionSet": [
  { "name": "emulator", "nativeLib": { "filter": { "excludes": ["**/arm64-v8a/*.so"] } } }
],
"buildModeBinder": [
  { "buildModeName": "debug", "mappings": [{ "targetName": "emulator", "buildOptionName": "emulator" }] },
  { "buildModeName": "release", "mappings": [{ "targetName": "emulator", "buildOptionName": "emulator" }] },
  { "buildModeName": "emulatorTest", "mappings": [{ "targetName": "ohosTest", "buildOptionName": "emulator" }] }
],
"targets": [{ "name": "default" }, { "name": "ohosTest" }, { "name": "emulator" }]
```

The root `build-profile.json5` lists the target (`{ "name": "emulator", "applyToProducts": ["default"] }`) and, with
`ohosTest`, the mode (`buildModeSet`: `{ "name": "emulatorTest" }`). Build with
`hvigorw --mode module -p module=entry@emulator -p product=default assembleHap` and install
`entry/build/default/outputs/emulator/entry-emulator-unsigned.hap`; tests with `-p buildMode=emulatorTest`. Phones,
arm64 emulators and releases keep the `default` target. The cyltabbar example (`entry/build-profile.json5`) has it.

### 3. A HAP built without it: `tools/cyl_hap_x86_64.py`

`python3 tools/cyl_hap_x86_64.py install <app.hap> [--target 127.0.0.1:5557]` asks the device for its ABIs, strips the
`libs/<abi>/` folders it cannot load, and runs `hdc install -r` (`--strip yes|no` or `CYL_HAP_STRIP_LIBS=1|0` forces
it); `strip <in.hap> [<out.hap>]` only copies the HAP without native libraries. Standard library only; tests in
`test/test_cyl_hap_x86_64.py`.

### 4. Test plan on x86_64

| Testable on the x86_64 emulator | Needs an arm64 device |
|:---|:---|
| Lottie, SVGA and GIF playback; still images and placeholders; PAG and Rive items on their still images (no crash, no blank item); Rive playback in debug builds with the debug engine kit (section 5); `showsImageWhenAnimationEnds` with Lottie or SVGA; layout, dark mode, accessibility, localization, gestures, countdown, stack view | PAG playback; Rive in release builds; Rive's dispose crash workarounds on a real device |

Device tests (hypium): the cyltabbar example's `entry/src/ohosTest` (`CYLAnimatedItemFallback.test.ets`) checks the
ABI rules on the device (expectations follow `deviceInfo.abiList`, so it also passes on arm64), a simulated x86_64 and
arm64 device, an app engine with a native library, and a UI test whose page holds a Rive and a Lottie item with a marker
builder: without `arm64-v8a` the Rive item builds no engine view and keeps its still image, the Lottie item builds one.
On the x86_64 emulator:

```sh
hvigorw --mode module -p module=entry@emulator -p product=default assembleHap
hvigorw --mode module -p module=entry@ohosTest -p isOhosTest=true -p buildMode=emulatorTest -p product=default assembleHap
hdc install -r entry/build/default/outputs/emulator/entry-emulator-unsigned.hap
hdc install -r entry/build/default/outputs/ohosTest/entry-ohosTest-unsigned.hap
hdc shell aa test -b com.cyl.tabbar.harmony -m entry_test -s unittest OpenHarmonyTestRunner -s timeout 15000
```

Result on 2026-11-22 (x86_64 emulator, HarmonyOS 6.0.1): Tests run: 6, Failure: 0, Error: 0, Pass: 6. On Windows give hdc
backslash paths (`tools/cyl_hap_x86_64.py` does).

### 5. Rive and PAG playback on x86_64: the debug engine kit (owner's Plan 1)

`x86_64-debug-engines/rive/` holds `libohos_rive.so` of @ohos/rive 1.0.4 built for x86_64 from its sources and the x86_64
`libc++_shared.so` it links; `x86_64-debug-engines/pag/` holds `libpag.so` of @tencent/libpag 4.4.31 built for x86_64 from
GitHub Tencent/libpag `v4.4.31` (provenance, checksums and licenses in each README). It is never part of a build:

- `tools/cyl_hap_x86_64.py install <app.hap>` adds the kit (`libs/x86_64/`) and the marker rawfile
  `cyl_x86_64_debug_engines.json` when the device is x86_64, only for the engines the app uses (its `libs/` files and the
  native modules its `ets/modules.abc` imports) (`--x86-engines auto`, the default; `no` / `yes` or
  `CYL_X86_ENGINES=0|1` force it).
- `CYLAnimatedItemEngines.loadX86_64DebugEngines(context)` (called by `CYLAnimatedItemView` and `CYLTabBarController`)
  reads the marker **in debug builds only** and lets the engines it names (Rive, PAG) accept `x86_64`; `x86_64DebugEngines()` lists what it turned on.
  Release builds and debug builds installed without the kit keep the still images.
- The debug guard stays until the owner approves removing it.

Checked on the x86_64 emulator (2026-11-22): with the kit the Rive tab icons draw and animate, without it they keep their
still images, and the hypium suite passes 9 / 9 in both installs; in CollectionViewClassifyMenu the PAG icons play and end
on their last frame with the kit, no crash.

Say in every report and screenshot footer which part ran on x86_64 and which still needs an arm64 device.
