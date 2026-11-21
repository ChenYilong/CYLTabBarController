---
name: cyl-harmonyos-setup
description: "Prepare a Windows machine and DevEco Studio for the HarmonyOS port (CrossPlatform/harmonyos-cyltabbar), and the prerequisites for installing the HarmonyOS local emulator: Hyper-V features, a full Windows restart, region set to China (CN) in country.region.xml, Huawei account sign-in. Use before the first HarmonyOS build, when Device Manager lists no phone, or when the emulator image cannot be downloaded or installed."
---

# HarmonyOS IDE setup and emulator prerequisites

Target: HarmonyOS 6.0.1 (API 21), DevEco Studio 6.0 (`C:\Program Files\Huawei\DevEco Studio`), Windows 11.
Check every item below, in order, before saying the emulator "cannot be installed".

## 1. Windows virtualization

All four optional features must be `Enabled` with `RestartNeeded: False`:

```powershell
foreach ($f in 'Microsoft-Hyper-V-All','Microsoft-Hyper-V-Hypervisor','VirtualMachinePlatform','HypervisorPlatform') {
  Get-WindowsOptionalFeature -Online -FeatureName $f | Select FeatureName, State, RestartNeeded
}
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent   # must be True
Get-Service vmcompute, vmms | Select Name, Status           # both Running
```

- Enable a missing one with `Enable-WindowsOptionalFeature -Online -FeatureName <name> -All -NoRestart` (admin shell).
- **Restart Windows itself.** Restarting DevEco Studio is not enough: the features only take effect after a Windows
  restart. Confirm with `(Get-CimInstance Win32_OperatingSystem).LastBootUpTime`.
- `VirtualizationFirmwareEnabled: False` from `Win32_Processor` is normal while Hyper-V is running; it does not mean
  VT-x is off in the BIOS. `HypervisorPresent: True` is the real check.
- Leave enough room: 16 GB RAM or more, and 20 GB or more free on the drive that holds the SDK.

## 2. Region must be China (CN)

The local emulator's phone list and images are only offered when DevEco Studio's region is China.

- File: `%APPDATA%\Huawei\DevEcoStudio6.0\options\country.region.xml`
- Required content — **make sure the region file says China**:

  ```xml
  <application>
      <component name="CountryRegionSetting">
          <countryregion name="CN"/>
      </component>
  </application>
  ```

- If it says another region (for example `<countryregion name="NZ"/>` for New Zealand), change it to `CN`:
  1. Back it up first (`country.region.xml.bak-<old code>`).
  2. **Quit DevEco Studio before editing** (File > Exit, confirm the dialog). DevEco Studio reads the file at start-up
     and can write the old value back when it exits, so an edit made while it runs may be lost.
  3. Replace the code with `CN`, then start DevEco Studio again.
- Verify after the restart:
  - the file still says `<countryregion name="CN"/>`;
  - `%LOCALAPPDATA%\Huawei\DevEcoStudio6.0\log\idea.log` has `request region:CN` (not `request region:NZ`) after the
    latest start.

## 3. Huawei account

Sign in to DevEco Studio with a Huawei developer account (avatar, top right) and accept the agreements. After sign-in,
`idea.log` prints:

```
Whether a developer has completed real-name authentication: <true|false>
Whether a developer has registered an account in Chinese Mainland: <true|false>
```

When both are `false`, the image download may still be refused even with the region set to CN: then use a Chinese
Mainland account with real-name authentication, or a real device (section 6). Report what the log says; do not guess.

## 4. Install the emulator

Tools > Device Manager > Local Emulator > + New Emulator > Phone (for example Mate 70 Pro) > download the HarmonyOS
6.0.x image > Finish > start it. Images go to `%LOCALAPPDATA%\Huawei\Sdk\system-image\HarmonyOS-<version>`; emulator
instances to `%LOCALAPPDATA%\Huawei\Emulator`.

## 5. Diagnose "no phone listed" / "cannot install"

| Symptom | Meaning | Fix |
|---|---|---|
| `Emulator\deployed\phone_config.json` is empty | DevEco Studio never received the device list | Section 2 (region CN), then section 3 (account) |
| `Sdk\system-image\HarmonyOS-<version>` is empty | No image was downloaded | Same as above; retry the download after sign-in |
| `idea.log`: `request region:` is not `CN` | Region change not applied | Quit DevEco Studio, edit the file, restart (section 2) |
| `idea.log`: `Connect timed out` to a Huawei host | Network / proxy problem | Fix the network or proxy, sign in again |
| Features show `RestartNeeded: True` | Windows not restarted | Restart Windows (section 1) |

## 6. Fallback: real device

Connect a HarmonyOS phone by USB with developer mode and USB debugging on. `hdc`
(`C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe`) lists it with `hdc list targets`,
and DevEco Studio can deploy the entry module to it directly.

## 7. Building the project

Build `CrossPlatform/harmonyos-cyltabbar` from an ASCII path without spaces (hvigor refuses others), for example a copy
at `C:\cyl-hm`. Progress and score: [docs/HarmonyOS-Parity.md](../../../docs/HarmonyOS-Parity.md).

## 8. Accessibility and localization

Every HarmonyOS control and text supports accessibility and localization: see the `cyl-harmonyos-a11y-l10n` skill.
UI tests locate controls through accessibility text / description and ids first.

## Fix in the core first (added 2026-11-17)

Change the core code (the code published to CocoaPods, Swift Package Manager, Maven / Gradle, npm, pub.dev, ohpm or
the WeChat Mini Program component) so that the whole class of bug is avoided; a fix only in the example layer is the
worst option. If the core cannot fix it, ask the owner first and explain why; after the owner agrees, fix it in the
example and record the reason in `docs/Example-Layer-Fixes.md` (see AGENTS.md, "Code rules").

## Hung emulator (added 2026-11-18)

When the HarmonyOS emulator hangs or does not open, restart it first, without asking the user: tell the other sessions
that use it, restart it, check `hdc list targets`, then tell all active sessions it is available again so that they resume tasks paused
because of it. Details: the `cyl-task-workflow` skill,
"Hung emulator".

## Swift first on iOS (added 2026-11-19)

- **The iOS core is Swift; every new piece of code is Swift first (added 2026-11-19, owner)**: the core code of this project on iOS (the CocoaPods / Swift Package Manager / Carthage sources under `CYLTabBarController/`, including the `CYLAnimatedItem` module) is Swift. Write every new class, extension, test and example in Swift. Use Objective-C only where Swift cannot do the job (a header that must stay importable from Objective-C without modules, a `+load`-time hook, a C macro), and give the reason in a comment and in the task's document in `docs/`. Keep the public API usable from Objective-C (`@objc`, `@objcMembers`, `NS_SWIFT_NAME` counterparts) so existing Objective-C callers keep working. When you touch Objective-C code for a new feature, prefer adding the feature in a Swift file over growing the Objective-C file. Migration log: `docs/Swift-Migration.md`. Details: `AGENTS.md`, "Code rules".

## HarmonyOS x86_64 emulator and arm64-only engines (added 2026-11-22, owner)

The CollectionViewClassifyMenu HAP won't install on this x86_64 emulator because its Rive and PAG libraries are arm64-only (`libohos_rive.so`, `libpag.so`: `arm64-v8a` only; install error 9568347; without `libs/` it installs but the first PAG or Rive view crashes). The fix belongs in CYLTabBarController's CYLAnimatedItemView library (`CrossPlatform/harmonyos-cyltabbar/cylanimateditem`): engines declare the native ABIs they need, `CYLAnimatedItemEngines.canPlay` is false on a device without them and the item shows its still image, plus an x86_64 debug build option that leaves the arm64-only `.so` files out of the HAP; then every example and library on the component runs its full test on the x86_64 emulator. Check the emulator ABI with `hdc shell param get const.product.cpu.abilist` before installing a HAP that bundles PAG or Rive. Full text: `instructions.md`, "HarmonyOS x86_64 emulator and arm64-only animation engines" and `CrossPlatform/harmonyos-cyltabbar/cylanimateditem/README.md`, "x86_64 emulator". Status: built in cylanimateditem (2026-11-22); dependents adopt it.
