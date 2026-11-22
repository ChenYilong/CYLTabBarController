# CYLTabBarController folder instructions

Read this file before reading or writing files in this repository. It inherits the vault's root `instructions.md`.

## Where the rules are

- `AGENTS.md` (loaded through `CLAUDE.md`): the agent rules of this repository. Read it first.
- `docs/instructions.md`: the rules of the documentation folder.
- `.agents/skills/cyl-*` (linked from `.claude/skills`): the project skills; `cyl-docs` for documents and screenshots,
  `cyl-verify` for builds, tests, simulators and emulators.
- `docs/Screenshot-Guidelines.md`: the complete screenshot rules.

## Screenshots (added 2026-11-18)

- Original screenshots only (no scaling, no recompression), cropped to the same region and width, from real runs.
- One column with several rows (top to bottom) first. Two columns with several rows only when the one-column image
  would be taller than one screen of a common phone (height above about 2.17 times the width, 19.5:9). A matrix stays a
  grid; a single horizontal row only as the last resort (at most three). The script picks this by default.
- Every stitched image has a header band, a caption band above each cell and a footer band, added around the
  screenshots and never overlapping or covering them. English only; white bands, bold red text (`#FF3B30`), about 2 %
  of the image width.
- Header, in order: platform and OS version, simulator / emulator / device model, host OS and version, IDE and version
  (build), SDK when not implied by the IDE, app and repository commit (the change's commit in parentheses), branch,
  date, then `Purpose: ...`. Example: `iOS 27.2, iPhone 17 Pro simulator, macOS 27.3, Xcode 27.2 (27B52),
  CYLTabBarController dcbfdec6 (ef1d0313), feat/harmony, 2026-11-18. Purpose: Rive tags rest until played`.
- Captions: the state or step and its measurement (`launch, no play`; `11 s later, 0 changed pixels`).
- Footer: the result against the expectation and the method (`Result: ... (expected: ...). Method: ...`), plus the
  test or document.
- Build it with `python3 scripts/stitch-screenshots.py` (ffmpeg only; it marks the PNG). Before committing a screenshot,
  run `python3 scripts/check-screenshot-labels.py`: it fails on any image added since 2026-11-18 without the marker.
  Run `bash scripts/install-git-hooks.sh` once per clone: its pre-commit hook blocks an unlabeled screenshot (CI does
  not check it). Never bypass it with `--no-verify`. Save it in `docs/assets/`, embed it in the
  related document and repeat the header as its text label.

- Screenshots of a tab bar (added 2026-11-18, maintainer): crop with at least 24 pt (72 px at @3x) above the raised plus button (or the bar), measured on the image (the drawn plus button and its badge reach above its accessibility frame), so the plus button and badges are whole; the stitched image keeps a white gap (`scripts/stitch-screenshots.py --top-gap`, 24 px by default) between every header or caption band and the screenshot below. Full rule: docs/Screenshot-Guidelines.md, "Space above the tab bar and below the bands".

## Swift first (added 2026-11-19)

- **The iOS core is Swift; every new piece of code is Swift first (added 2026-11-19, owner)**: the core code of this project on iOS (the CocoaPods / Swift Package Manager / Carthage sources under `CYLTabBarController/`, including the `CYLAnimatedItem` module) is Swift. Write every new class, extension, test and example in Swift. Use Objective-C only where Swift cannot do the job (a header that must stay importable from Objective-C without modules, a `+load`-time hook, a C macro), and give the reason in a comment and in the task's document in `docs/`. Keep the public API usable from Objective-C (`@objc`, `@objcMembers`, `NS_SWIFT_NAME` counterparts) so existing Objective-C callers keep working. When you touch Objective-C code for a new feature, prefer adding the feature in a Swift file over growing the Objective-C file. Migration log: `docs/Swift-Migration.md`. Details: `AGENTS.md`, "Code rules".

## Sessions (added 2026-11-19)

- **Session roles by name (added 2026-11-19).** Before starting a task, check the names of the active sessions (for example with `ListAgents`). A session whose name starts with `Mac` (case-insensitive) mainly develops and tests the iOS side; a session whose name starts with `Win` (case-insensitive) mainly develops the other platforms (Android, HarmonyOS, React Native, Flutter, WeChat Mini Program). When sessions of both kinds are active, prefer to assign each platform's tasks to the matching session (iOS work to a `Mac` session, other platforms to a `Win` session), by message, instead of doing all of it in one session. When no session follows this naming, skip this rule and finish the task on your own. Full steps: the `cyl-task-workflow` skill, "Check other sessions first".

## HarmonyOS x86_64 emulator and arm64-only animation engines (added 2026-11-22, owner)

- **The problem.** The local HarmonyOS emulator (127.0.0.1:5557, Mate 70 Pro image, HarmonyOS 6.0.1) is x86_64. @ohos/rive 1.0.4 (`libohos_rive.so`) and @tencent/libpag 4.4.31 (`libpag.so`) ship `arm64-v8a` libraries only. The CollectionViewClassifyMenu HAP won't install on this x86_64 emulator because its Rive and PAG libraries are arm64-only (install error 9568347). Removing `libs/` from the HAP lets it install, but the first PAG or Rive view then crashes the app ("SyntaxError: the requested module 'libpag.so' does not provide an export name 'JPAGView'").
- **Where the fix goes (owner's decision).** Build the x86_64 test path into CYLTabBarController's CYLAnimatedItemView library (`CrossPlatform/harmonyos-cyltabbar/cylanimateditem`), not into each example, so every example and every library that depends on the component (the cyltabbar example, CollectionViewClassifyMenu, CYLTableViewPlaceHolder, CYLSearchViewController) can run its complete test on the x86_64 emulator:
  1. An engine declares the native ABIs it needs when it registers (e.g. PAG and Rive: `arm64-v8a`). On a device without them (`deviceInfo.abiList`), `CYLAnimatedItemEngines.canPlay` answers false, no engine view is created, nothing loads the missing `.so`, and the item shows its still image (or the placeholder) with a debug log, the same way `cylRiveIsSupported()` already protects cyltabbar's Rive tabs.
  2. An x86_64 debug build option (documented, off by default, never in a release or published package) leaves the arm64-only `.so` files out of the HAP so it installs on the x86_64 emulator.
  3. Every test that depends on the component passes on the x86_64 emulator with PAG and Rive items on their still images; PAG and Rive playback itself is still checked on an arm64 device, and the report says so.
- **Until it is done (local workaround, never committed).** Build the HAP, copy it without `libs/` (for example with Python's `zipfile`), and in a local copy of the example skip the PAG and Rive views when `deviceInfo.abiList` has no `arm64-v8a`. Used on 2026-11-22 for HarmonyOS-Issues rows 28 and 29 (CollectionViewClassifyMenu `9dc1f761`).
- Status (2026-11-22): built in `cylanimateditem` (ABI check in `CYLAnimatedItemEngines`, `tools/cyl_hap_x86_64.py`, the `emulator` target recipe in `cylanimateditem/README.md`, used by the cyltabbar example); dependents adopt it next. Task and score: `docs/Animated-Item.md`, "HarmonyOS x86_64 emulator".

## Naming after the static analysis (added 2026-11-22)

- SonarCloud flags `cyl_` Swift names (`swift:S100`: 743 of 956 issues on PR #788). In Swift: `CYL` stays on types; members of our own types take no prefix; members added to system types become `cylFoo` (with `@objc(cyl_foo)` for Objective-C); constants `cylFoo`; Objective-C selectors unchanged; released Swift names stay as deprecated shims. Other languages keep the prefix only on names in a global namespace (Android resources, channel / native module names, component tags, CSS classes, storage keys). Full rule: `AGENTS.md`, "Naming"; skill `cyl-naming`.
