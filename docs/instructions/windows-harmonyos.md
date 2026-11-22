# Windows and HarmonyOS (tag: `windows-harmonyos`)

Full text of the `windows-harmonyos` rules. [AGENTS.md](../../AGENTS.md#windows-and-harmonyos-tag-windows-harmonyos) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

## HarmonyOS port

**CYLTabBarController ships a HarmonyOS component and a HarmonyOS example (added 2026-11-16, required).** The repository must always contain (1) the HarmonyOS tab bar component, the library module `CrossPlatform/harmonyos-cyltabbar/cyltabbar` (ArkTS / ArkUI, the HarmonyOS version of the tab bar), and (2) the HarmonyOS example, the `entry` module next to it, which shows that component's features as a showcase. Never delete, move out or leave them behind when merging or closing branches and pull requests; a branch or pull request that carries HarmonyOS work keeps both modules buildable (`hvigorw assembleHap`), and both reach `master` with the pull request that merges the cross-platform work.

HarmonyOS (HarmonyOS 6.0.1, API 21, DevEco Studio 6.0, ArkTS / ArkUI, code in `CrossPlatform/harmonyos-cyltabbar`) principles: the public API matches the iOS library; the example (entry) is a one-to-one replica of the iOS Objective-C Example; the internal implementation is ported from the Android Kotlin sources (`Example-Android/cyltabbar`). Progress and score: [docs/HarmonyOS-Parity.md](docs/HarmonyOS-Parity.md); remove one TODO per feature done, until the score is 100. Build from an ASCII path without spaces (hvigor refuses others), e.g. a copy at `C:cyl-hm`.

**DevEco Studio setup and emulator prerequisites** (full steps: the `cyl-harmonyos-setup` skill):
- Windows features `Microsoft-Hyper-V-All`, `Microsoft-Hyper-V-Hypervisor`, `VirtualMachinePlatform` and
  `HypervisorPlatform` are enabled, and **Windows itself has been restarted** (restarting DevEco Studio is not enough).
- **The region must be China.** In `%APPDATA%\Huawei\DevEcoStudio6.0\options\country.region.xml`, change any other
  region (for example `NZ`) to China, and make sure the region file says `<countryregion name="CN"/>`. Edit it only
  while DevEco Studio is closed (it can write the old value back on exit), then confirm `request region:CN` in
  `%LOCALAPPDATA%\Huawei\DevEcoStudio6.0\log\idea.log` after the restart.
- Sign in with a Huawei developer account; an account that is not Chinese Mainland and not real-name verified may
  still be refused the emulator image. Fallback: a real HarmonyOS device through `hdc`.

**HarmonyOS accessibility, localization and UI tests** (full steps: the `cyl-harmonyos-a11y-l10n` skill):
- **All code of this project supports accessibility (screen readers such as ScreenReader / TalkBack-style blind
  assistance and other visual assistance) and internationalization / localization, and so does the HarmonyOS code.**
  If you find a control, a text or a page that does not, add the support first, then continue with your task.
- Accessibility: every tab, the plus button, every list row and every button is one accessibility element with a
  meaningful `accessibilityText` (badges are read as part of their host, e.g. "Messages, 99+ new messages") and an
  `accessibilityDescription` (role, position, selected state, subtitle); decorations (badge views, Lottie canvases,
  covers, overlays) use `accessibilityLevel('no')` or sit inside an `accessibilityGroup`.
- Localization: every user-visible text goes through `CYLLocalizedString('<key>')` (or is marked with
  `cyl_localizationKey('<key>')`). The key is the original text, the same key as iOS (`CYLLocalizedString(@"<original
  Chinese text>")`), so the translations are copied from the iOS bundle
  (`CYLTabBarController/Resources/CYLTabBarController.bundle/<lang>.lproj/CYLTabBarController.strings`); only the keys
  the HarmonyOS code uses are copied. Texts only the port has go into `scripts/harmonyos-l10n.json`. Run
  `python3 scripts/harmonyos-l10n.py` after changing texts (`--check` fails when the resources are stale); never edit
  the generated `string.json` files or `CYLLocalizationTable.ets` by hand.
- Automated UI tests drive the UI through these features first: locate controls by their accessibility text or
  description (and the `id` given to every control, e.g. `cyl-tab-<identifier>`, `cyl-row-<page>-<id>`), then trigger
  taps, long presses, swipes and multi-step flows on them (wechatide-style automation, `hdc shell uitest`, ArkUI
  `on.text()` / `on.id()` / `on.description()` matchers). Fall back to coordinates only when no element can be found,
  and treat that as a missing accessibility label to fix.

## HarmonyOS: IDE preparation and emulator prerequisites (added 2026-11-16)

Before any HarmonyOS work (building, installing or running a HAP, taking emulator screenshots), check these:

1. **DevEco Studio is installed**: `/Applications/DevEco-Studio.app` (DevEco Studio 6.0). The SDK is the bundled one:
   `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`; `hdc` is at
   `sdk/default/openharmony/toolchains/hdc`; build with the bundled node running
   `tools/hvigor/bin/hvigorw.js assembleHap --no-daemon`.
2. **The region is China.** The emulator (Device Manager, emulator images) is only offered when DevEco Studio's region
   is China. The region file is
   `~/Library/Application Support/Huawei/DevEcoStudio6.0/options/country.region.xml` (the folder follows the DevEco
   version). It must say `<countryregion name="CN"/>`, not another region such as `NZ`:

   ```xml
   <application>
       <component name="CountryRegionSetting">
           <countryregion name="CN"/>
       </component>
   </application>
   ```

   Check it with `grep countryregion "$HOME/Library/Application Support/Huawei/DevEcoStudio"*/options/country.region.xml`.
   If it is not `CN`: quit DevEco Studio first (it writes its settings back on exit), keep a copy of the file, change
   the value to `CN`, start DevEco Studio again and check the file once more.
3. **An emulator image is installed and the emulator starts**: the Mate 70 Pro image under `~/.Huawei/Emulator/deployed`
   (`Emulator -hvd "Mate 70 Pro" -path ~/.Huawei/Emulator/deployed -imageRoot ~/Library/Huawei/Sdk`, from
   `/Applications/DevEco-Studio.app/Contents/tools/emulator/`), signed in to a Huawei account in DevEco Studio when
   the image download asks for it, with hardware virtualization available on the Mac.
4. **Signing is not needed on the emulator**: it installs the unsigned `entry-default-unsigned.hap`
   (`hdc install -r`). Do not ask the owner for a signing setup for emulator runs.

## From instructions.md (moved 2026-11-22)

### HarmonyOS x86_64 emulator and arm64-only animation engines (added 2026-11-22, owner)

- **The problem.** The local HarmonyOS emulator (127.0.0.1:5557, Mate 70 Pro image, HarmonyOS 6.0.1) is x86_64. @ohos/rive 1.0.4 (`libohos_rive.so`) and @tencent/libpag 4.4.31 (`libpag.so`) ship `arm64-v8a` libraries only. The CollectionViewClassifyMenu HAP won't install on this x86_64 emulator because its Rive and PAG libraries are arm64-only (install error 9568347). Removing `libs/` from the HAP lets it install, but the first PAG or Rive view then crashes the app ("SyntaxError: the requested module 'libpag.so' does not provide an export name 'JPAGView'").
- **Where the fix goes (owner's decision).** Build the x86_64 test path into CYLTabBarController's CYLAnimatedItemView library (`CrossPlatform/harmonyos-cyltabbar/cylanimateditem`), not into each example, so every example and every library that depends on the component (the cyltabbar example, CollectionViewClassifyMenu, CYLTableViewPlaceHolder, CYLSearchViewController) can run its complete test on the x86_64 emulator:
  1. An engine declares the native ABIs it needs when it registers (e.g. PAG and Rive: `arm64-v8a`). On a device without them (`deviceInfo.abiList`), `CYLAnimatedItemEngines.canPlay` answers false, no engine view is created, nothing loads the missing `.so`, and the item shows its still image (or the placeholder) with a debug log, the same way `cylRiveIsSupported()` already protects cyltabbar's Rive tabs.
  2. An x86_64 debug build option (documented, off by default, never in a release or published package) leaves the arm64-only `.so` files out of the HAP so it installs on the x86_64 emulator.
  3. Every test that depends on the component passes on the x86_64 emulator with PAG and Rive items on their still images; PAG and Rive playback itself is still checked on an arm64 device, and the report says so.
- **Until it is done (local workaround, never committed).** Build the HAP, copy it without `libs/` (for example with Python's `zipfile`), and in a local copy of the example skip the PAG and Rive views when `deviceInfo.abiList` has no `arm64-v8a`. Used on 2026-11-22 for HarmonyOS-Issues rows 28 and 29 (CollectionViewClassifyMenu `9dc1f761`).
- Status (2026-11-22): built in `cylanimateditem` (ABI check in `CYLAnimatedItemEngines`, `tools/cyl_hap_x86_64.py`, the `emulator` target recipe in `cylanimateditem/README.md`, used by the cyltabbar example); dependents adopt it next. Task and score: `docs/Animated-Item.md`, "HarmonyOS x86_64 emulator".

### Rive and PAG on the x86_64 emulator: two plans for arm64-only tests (added 2026-11-22, owner)

Tests that today can only run on arm64 (PAG and Rive playback, their `onEnded`, Rive's dispose crash workarounds) get one of two plans, in this order:

1. **Plan 1: x86_64 libraries inside CYLTabBarController's CYLAnimatedItemView.** Change the HarmonyOS `cylanimateditem` (and the engine views it hands work to) so that, on an x86_64 device, PAG and Rive load x86_64 builds of their dependency libraries brought in from GitHub (the upstream sources of `@tencent/libpag` and `@ohos/rive` built for x86_64), so these tests run on the x86_64 emulator.
   - **Guard condition:** the architecture of the running system: the x86_64 path is taken only when the device reports x86_64 (`deviceInfo.abiList`).
   - **Order of goals:** first, the x86_64 build compiles and never crashes or breaks any other feature (Lottie, SVGA, GIF, still images, the arm64 path on phones); only then make PAG and Rive actually play correctly on x86_64.
   - **Debug guard until verified:** until Plan 1 passes its tests, keep it behind a debug build option (off in release builds and in every published package), because it is only triggered on the emulator. Remove the debug guard only after Plan 1 is verified, and **only with the owner's approval: ask first**.
   - Until Plan 1 works, the current fallback stays: on x86_64, PAG and Rive items show their still images (`CYLAnimatedItemEngines.isSupportedOnDevice`, the `emulator` build target, `cylanimateditem/README.md`, "x86_64 emulator").
2. **Plan 2, if Plan 1 fails: hand the test to the macOS session.** A Mac (Apple silicon) is arm64, so its arm64 HarmonyOS emulator runs PAG and Rive natively. Send the task to the active session whose name starts with `Mac` (`ListAgents`), with the build, the commands and what to check; when none is reachable, record it as a TODO in the task's document for the next Mac session.

Status (2026-11-22): Plan 1 done for Rive and PAG behind the debug guard (`cylanimateditem/x86_64-debug-engines/rive` and `/pag`, `CYLAnimatedItemEngines.loadX86_64DebugEngines`, `tools/cyl_hap_x86_64.py install`, which adds only the engines the app uses); removing the debug guard needs the owner's approval. Task and score: `docs/Animated-Item.md`, "Rive and PAG on the x86_64 emulator".
