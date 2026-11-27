# HarmonyOS Port [`harmonyos`]

## Principles and progress

HarmonyOS (HarmonyOS 6.0.1, API 21, DevEco Studio 6.0, ArkTS / ArkUI, code in `CrossPlatform/harmonyos-cyltabbar`) principles: the public API matches the iOS library; the example (entry) is a one-to-one replica of the iOS Objective-C Example; the internal implementation is ported from the Android Kotlin sources (`Example-Android/cyltabbar`). Progress and score: [../HarmonyOS-Parity.md](../HarmonyOS-Parity.md); remove one TODO per feature done, until the score is 100. Build from an ASCII path without spaces (`hvigor` refuses others), for example a copy at `C:cyl-hm`.

## DevEco Studio setup and emulator prerequisites

Full steps: the `cyl-harmonyos-setup` skill.

- **Windows features** `Microsoft-Hyper-V-All`, `Microsoft-Hyper-V-Hypervisor`, `VirtualMachinePlatform`, and `HypervisorPlatform` are enabled, and **Windows itself has been restarted** (restarting DevEco Studio is not enough).
- **The region must be China.** In `%APPDATA%\Huawei\DevEcoStudio6.0\options\country.region.xml`, change any other region (for example `NZ`) to China, and make sure the region file says `<countryregion name="CN"/>`. Edit it only while DevEco Studio is closed (it can write the old value back on exit), then confirm `request region:CN` in `%LOCALAPPDATA%\Huawei\DevEcoStudio6.0\log\idea.log` after the restart.
- Sign in with a Huawei developer account; an account that is not Chinese Mainland and not real-name verified may still be refused the emulator image. Fallback: a real HarmonyOS device through `hdc`.

### macOS DevEco Studio and emulator prerequisites (added 2026-11-16)

Before any HarmonyOS work (building, installing or running a HAP, taking emulator screenshots), check these:

1. **DevEco Studio is installed**: `/Applications/DevEco-Studio.app` (DevEco Studio 6.0). The SDK is the bundled one: `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`; `hdc` is at `sdk/default/openharmony/toolchains/hdc`; build with the bundled node running `tools/hvigor/bin/hvigorw.js assembleHap --no-daemon`.
2. **The region is China.** The emulator (Device Manager, emulator images) is only offered when DevEco Studio's region is China. The region file is `~/Library/Application Support/Huawei/DevEcoStudio6.0/options/country.region.xml` (the folder follows the DevEco version). It must say `<countryregion name="CN"/>`, not another region such as `NZ`:

   ```xml
   <application>
       <component name="CountryRegionSetting">
           <countryregion name="CN"/>
       </component>
   </application>
   ```

   Check it with `grep countryregion "$HOME/Library/Application Support/Huawei/DevEcoStudio"*/options/country.region.xml`. If it is not `CN`: quit DevEco Studio first (it writes its settings back on exit), keep a copy of the file, change the value to `CN`, start DevEco Studio again, and check the file once more.
3. **An emulator image is installed and the emulator starts**: the Mate 70 Pro image under `~/.Huawei/Emulator/deployed` (`Emulator -hvd "Mate 70 Pro" -path ~/.Huawei/Emulator/deployed -imageRoot ~/Library/Huawei/Sdk`, from `/Applications/DevEco-Studio.app/Contents/tools/emulator/`), signed in to a Huawei account in DevEco Studio when the image download asks for it, with hardware virtualization available on the Mac.
4. **Signing is not needed on the emulator**: it installs the unsigned `entry-default-unsigned.hap` (`hdc install -r`). Do not ask the owner for a signing setup for emulator runs.

## HarmonyOS accessibility, localization, and UI tests

Full steps: the `cyl-harmonyos-a11y-l10n` skill.

- **All code in this project supports accessibility** (screen readers such as ScreenReader / TalkBack-style blind assistance and other visual assistance) and internationalization/localization, and so does the HarmonyOS code. If you find a control, a text, or a page that does not, add the support first, then continue with your task.
- **Accessibility**: every tab, the plus button, every list row, and every button is one accessibility element with a meaningful `accessibilityText` (badges are read as part of their host, for example "Messages, 99+ new messages") and an `accessibilityDescription` (role, position, selected state, subtitle); decorations (badge views, Lottie canvases, covers, overlays) use `accessibilityLevel('no')` or sit inside an `accessibilityGroup`.
- **Localization**: every user-visible text goes through `CYLLocalizedString('<key>')` (or is marked with `cyl_localizationKey('<key>')`). The key is the original text, the same key as iOS (`CYLLocalizedString(@"<original Chinese text>")`), so the translations are copied from the iOS bundle (`CYLTabBarController/Resources/CYLTabBarController.bundle/<lang>.lproj/CYLTabBarController.strings`); only the keys the HarmonyOS code uses are copied. Texts only the port has go into `scripts/harmonyos-l10n.json`. Run `python3 scripts/harmonyos-l10n.py` after changing texts (`--check` fails when the resources are stale); never edit the generated `string.json` files or `CYLLocalizationTable.ets` by hand.
- **Automated UI tests drive the UI through these features first**: locate controls by their accessibility text or description (and the `id` given to every control, for example `cyl-tab-<identifier>`, `cyl-row-<page>-<id>`), then trigger taps, long presses, swipes, and multi-step flows on them (wechatide-style automation, `hdc shell uitest`, ArkUI `on.text()` / `on.id()` / `on.description()` matchers). Fall back to coordinates only when no element can be found, and treat that as a missing accessibility label to fix.
