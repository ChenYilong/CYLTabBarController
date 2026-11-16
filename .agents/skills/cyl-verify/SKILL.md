---
name: cyl-verify
description: "How to build, test and check CYLTabBarController and its demos, run the simulator safely, and read common failures. Use before saying a change works, before pushing, and when a demo does not build."
---

# Verify

Say plainly what could not be verified. Never call something fixed from a build alone if it is a visual change.

## Before every build of a project that depends on CYLTabBarController

Find the latest commit again, every time: `scripts/latest-cyl-commit.sh` prints the newest commit on any branch by commit
timestamp (`<sha> <date> <branch>`). A project not named CYLTabBarController must depend on exactly that commit
(`pod 'CYLTabBarController', :git => '…', :commit => '<sha>'`, then `pod install`); a project named CYLTabBarController uses
the relative path to the folder with the podspec (`:path => '../'` from a demo). Name the commit in the report. AGENTS.md,
"Depending on CYLTabBarController".

## Commit message author line

Every commit message carries the line `By  @ChenYilong <luohanchenyilong@163.com>` (exactly as written, two spaces after
`By`) in its body, after the description and before trailers such as `Claude-Session:`. Check it before every push
(`git log -1 --format=%B`); amend a commit that lacks it. AGENTS.md, "Commit messages".

## Commit message style: `git cz`, English only

Every commit uses the `git cz` (Commitizen) style and is written entirely in English: no Chinese (and no other non-English text) anywhere in the subject, the body or the trailers. A user's prompt in another language is quoted in the task's document in `docs/`, never in the commit message.
Before pushing: `git log -1 --format=%B | python3 -c "import re,sys; sys.exit(1 if re.search('[\u4e00-\u9fff]', sys.stdin.read()) else 0)"` prints nothing. AGENTS.md, "Git and pull requests".

## Commit and push at the end of every turn

**Commit and push at the end of every turn (added 2026-11-16)**: when a question-and-answer turn ends and the current branch is not `master` or `main`, commit and push the work of that turn, without asking. This is always safe: the code stays on a branch and is never pushed to `master` or `main`, so pushing carries no risk to worry about. The open pull request rule still applies to every such commit (check for an open pull request first, open one if missing). On `master` or `main`, ask first. AGENTS.md, "Git and pull requests".

## Badge debugging: animations off

**Badge debugging: turn badge animations off with the build option (added 2026-11-17)**: while checking badge positions (coordinates, offsets, alignment with the icon), build with the badge-animation build option `CYL_BADGE_ANIMATION_DISABLED` on, so an animation (Bounce, Shake, Scale, Breathe, the one-shot types) never moves a badge while a screenshot or a layout dump is taken: an animated badge is drawn away from its laid-out place, and the measured coordinates are wrong. It exists in the core of each platform: iOS, the Swift compilation condition `CYL_BADGE_ANIMATION_DISABLED` on the CYLTabBarController target (Podfile `post_install`: `SWIFT_ACTIVE_COMPILATION_CONDITIONS = '$(inherited) CYL_BADGE_ANIMATION_DISABLED'`); Android (and the React Native and Flutter components, which use its host view), the Gradle property `-PcylBadgeAnimationDisabled=true` (`BuildConfig.CYL_BADGE_ANIMATION_DISABLED`); HarmonyOS, `CYL_BADGE_ANIMATION_DISABLED: true` in `buildProfileFields` of `CrossPlatform/harmonyos-cyltabbar/cyltabbar/build-profile.json5`. Turn it off again before committing (never commit it on, never ship it): after the positions are right, take one more check with animations on, because an animation's own offsets can still be wrong. Say in the report and in the screenshot label that the build option was on. Details: `docs/Badge-Debugging.md`. AGENTS.md, "Code rules".

## Where a check runs: GitHub CI or locally

GitHub CI/CD for iOS runs on **macOS 26** by default: always read `.github/workflows/ios.yml` on master first to confirm it
(`runs-on: ${{ vars.MACOS_RUNNER || 'macos-26' }}`; the `MACOS_RUNNER` variable can change it). Running **locally** (not
through GitHub CI/CD, directly on this Mac) ignores that limit: the default local system is **macOS 27** with **Xcode 27**
and its simulators. Name the environment (runner, or local macOS and Xcode versions) in every report. AGENTS.md,
"CI/CD and where tests run".

Before every local build, check the first line of `.github/workflows/ios.yml`, the local environment comment
(`# local-run-environment: macOS …, Xcode …`): run `scripts/local-run-environment.sh`, which adds it when missing, leaves it
when the versions are unchanged and rewrites it when macOS or Xcode differs (Xcode of `/Applications/Xcode.app`).

- **Screenshots (added 2026-11-12)**: every screenshot, from CI/CD and from local builds, is saved in the repository with the related document in `docs/` (create the document when none fits; images in `docs/assets/`) and committed to git. Use clear original screenshots: never scaled down or recompressed; a crop that keeps the original resolution is allowed. When the result looks as expected, also update `README.md` with the latest screenshots, in the related section (create it when there is none). Every screenshot, in the document and in the README, is labeled with: the platform (iOS, Android, Flutter, React Native, HarmonyOS, WeChat Mini Program); the environment: operating system version, simulator or emulator (device model and OS version), and the SDK version of that platform (iOS SDK / Xcode, Android SDK / API level, Flutter SDK, React Native, HarmonyOS SDK, WeChat Mini Program base library); this repository's version or commit (with its link); and the time it was taken.
- **Screenshot moments and layout (added 2026-11-12)**: take and commit screenshots at key moments: when a TODO or Linux note can be removed, when a pull request can be merged, or when the result is judged as expected with no bug and no open issue. The README shows cropped key details, a full screen only when it is needed; several details go into one stitched image. Stitching order of preference: a vertical stack (one column, top to bottom), easiest to read on a phone; then two columns with several rows; last, a single horizontal row, at most three images in a row. (Corrected by the maintainer on 2026-11-12: the original wording said both "prefer a horizontal arrangement" and "a horizontal row is the worst", which contradict each other; the rule is to prefer a vertical stack.)

## Commands

```sh
pod lib lint CYLTabBarController.podspec --quick            # before every push
scripts/unit-tests.sh "iPhone 17 Pro Max"                   # the unit tests (scheme CYLTabBarController-Framework)
scripts/ci-build-example.sh <demo folder>                   # one demo, as CI builds it
scripts/plus-child-theme-test.sh "iPhone 17 Pro Max"        # plus child + theme, on a simulator
scripts/scroll-hide-self-test.sh                            # scroll hiding, on a simulator
python3 scripts/update-docs-navigation.py --check
python3 scripts/check-localization-macros.py                    # localization acceptance: a core macro and an example macro, each reading its own bundle
python3 scripts/check-public-api-comments.py                    # public API comments are /*! ... */ blocks, not stacked //
python3 scripts/sync-agent-skills.py --check
scripts/publish-android.sh staging                          # Android library: Maven bundle, checked (local | staging | central | github)
(cd Example-Android && LC_ALL=C.UTF-8 gradle testDebugUnitTest :tabpages:test lintDebug assembleRelease)   # Android, as .github/workflows/android.yml runs it
# React Native component (CrossPlatform/react-native-cyltabbar): yarn; yarn tsc --noEmit; in example/ios: LANG=en_US.UTF-8 pod install,
# then xcodebuild; in example/android: JAVA_HOME=<JDK 17> ./gradlew :app:assembleDebug
# Flutter component (CrossPlatform/flutter_cyltabbar): flutter analyze; flutter test; in example: flutter build ios --simulator
#   (Swift Package Manager, the plugin depends on this repository's Package.swift) / flutter build apk (JDK 17)
# Library: CYLTabBarHostViewTests (scripts/unit-tests.sh), CYLTabBarHostViewTest (Android, Robolectric)
```

Localization acceptance (AGENTS.md, "Localization (i18n / l10n) file structure"): a project must have at least two different
macros that read the localized files of two different layers, and a project is accepted only when both exist and are used:
the **core** macro (iOS: `CYLLocalizedString`, reading `CYLTabBarController.bundle`) and the **example** macro (iOS:
`CYLDemoLocalizedString`, in Swift `cylDemoLocalizedString`, reading `Example-Shared/CYLDemo.bundle`). Other platforms use another package form, name and folder
name, but still one macro or helper per layer. `scripts/check-localization-macros.py` checks the iOS side and every example
Xcode project that compiles a file calling the example macro (it must also compile `CYLDemoLocalization.m` or `.swift` and
ship `CYLDemo.bundle`); after adding a localized text or a demo project, run it, then build that demo.

The `CYLTabBarController` scheme has no test action: use `scripts/unit-tests.sh`. Static analysis: `xcodebuild analyze` must report no warnings.

Screenshots of the ObjC demo without driving the UI (it shows a splash ad for about 10 s first, so wait about 18 s):
`xcrun simctl launch <udid> CYL.CYLTabBarController -CYLDemoGalleryScene 8.1` opens gallery scene 8.1 (section.row, as the
list numbers it; docs/Tab-Bar-Gallery.md), and `-CYLDemoManifestTheme light|dark|christmas` builds the tab bar from the
configuration manifest. Taps with axe are often swallowed under load: prefer these launch arguments.

- **Run scripts with bash, not zsh (added 2026-11-16).** The interactive shell here is zsh, which does not split an
  unquoted variable into words: `for f in $list`, `cmd $args` or `sips $box` get one argument holding the whole
  string, where bash would pass several. A command that works in bash then fails or measures the wrong thing in zsh
  (seen: "zsh doesn't split $box into words either", and the measurement had to be run again as a bash script).
  So prefer bash for every script and every command with variables, loops or word lists:
  - run a script file with `bash script.sh` (shebang `#!/usr/bin/env bash`), never `zsh` or `sh` when it relies on
    bash behavior; run a one-off multi-line command as `bash -c '…'` or a heredoc piped to `bash`;
  - in zsh, when bash is not possible, use arrays (`files=(a b)`, `"${files[@]}"`) or `${=var}` to split on purpose;
  - quote every expansion (`"$var"`) unless splitting is wanted.

## Common failures

| Symptom | Cause | Fix |
|:---|:---|:---|
| The ObjC demo runs old code after a library fix | Xcode did not relink: the library lands in the app's binary | Build with a fresh `-derivedDataPath`; check with `nm <app>/<binary>` |
| `cannot find 'CYLTabBarItemAnimationFactory' in scope`, or `type 'CYLTabBarAnimationOption' has no member` | Stale `Pods/` after headers changed | `pod install` in the demo |
| Simulator taps do nothing | The simulator's input is stuck | Shut it down, boot it, wait, try again |
| `pod` fails with a missing `ffi` | The system's CocoaPods | Use the Homebrew one: put `/opt/homebrew/opt/ruby/bin` and its gems `bin` first in `PATH` |
| Git errors about `._*` files on the exFAT volume | macOS AppleDouble files inside `.git` | `find .git -name '._*' -delete` |
| `umbrella header for module 'CYLTabBarController' does not include header '._….h'` | Derived data on the exFAT volume: macOS writes `._*` files into the built framework's `Headers` | Build into a folder on the internal disk (`$TMPDIR`); `scripts/unit-tests.sh` does |
| VoiceOver (`axe describe-ui`) reads a tab's old title on Liquid Glass | The selected layer's tab button reads the item's own `accessibilityLabel`, else its first title | The library writes the title as the item's label on layout (`-cyl_syncTabBarItemAccessibility`); keep that call in the tab bar's `-layoutSubviews` |
| `-[UIApplication statusBarStyle] ... no-op` | `UIViewControllerBasedStatusBarAppearance = NO` in `Info.plist` | Remove the key |
| `CVPixelBufferCreate returned err -6680`, simulator only | JPEG assets decoded by the system | Use PNG, or ignore it |
| `cannot add handler to 0 from 0`, `pointeruid` | UIKit and the system, no app frames | Ignore |
| `pod install`: `Unicode Normalization not appropriate for ASCII-8BIT` | No UTF-8 locale | `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install` |
| A CrossPlatform example on the exFAT volume: CocoaPods finds no library sources through a symlink, or Gradle fails on `._*` files in `.gradle` / `build` | Symlinked folders are not globbed; AppleDouble files | Use the real repository path (no symlinks); for Gradle, `--project-cache-dir /tmp/...` or build a copy in `/tmp` |
| A `CYLTabBarHostView` (React Native, Flutter) shows titles cut to "..." | The bar was laid out at width 0 (a platform view starts with an empty frame) | The host builds the controller once it has a window and a real width; keep it that way |
| Flutter iOS: `duplicate symbols` | CYLTabBarController from both CocoaPods and Swift Package Manager | `example` is Swift Package Manager only (no Podfile); `example_pag` / `example_rive` are CocoaPods only (`enable-swift-package-manager: false`) |
| React Native iOS: Lottie tabs show the static images | Pods built as static libraries: `<Lottie/Lottie-Swift.h>` is not found, so `__has_include` is false | Static frameworks: the example's Podfile defaults `USE_FRAMEWORKS` to `static`; run `pod install` again |
| xcodebuild fails in a Swift macro (`swift-plugin-server`) under an agent sandbox | The macro server runs its own sandbox, which a nested sandbox blocks | Run that build outside the agent sandbox |
| Simulator taps (axe / idb) stop registering | Simulator input state | Reboot the simulator (`xcrun simctl shutdown` / `boot`) |
| Android emulator: taps you did not send | Another session shares the emulator | Check `adb devices` and take a screenshot before trusting a result |
| Flutter Android release: R8 `Missing class javax.annotation.Nullable` | okio, pulled in by lottie-android | `-dontwarn javax.annotation.Nullable` in `android/app/proguard-rules.pro` |
| React Native Android debug build: red screen, `Unable to load script` / Metro download stalls on the emulator | The emulator cannot reach the Mac's Metro | `adb reverse tcp:8081 tcp:8081`, then reopen the app (or `./gradlew :app:assembleRelease`, which bundles the JS) |
| R8-minified release (RN, Flutter): tabs show images, or a crash `ClassNotFoundException: org.libpag.…` | The wrappers compile the library's sources, so its `consumer-rules.pro` must be added with `consumerProguardFiles` | Keep that line in the wrapper's Gradle file; check a demo with `flutter build apk --release` |
| Checking the transparent strip (RN Android, Flutter) | Nothing tappable lies below the strip in the demos | In a scratch copy, make a page a tappable color toggle; a tap in the strip must toggle it, a tap on the plus button's upper part must not |
| PAG / Rive demo (RN, Flutter) Android: icons blank | No `.pag` files (fetched by `pod install` in `Example-PAG`), or Rive not initialized | Run `pod install` in `Example-PAG` first; the library calls `Rive.init` itself |
| A resource added to a Flutter Runner project lands in `RunnerTests` | The script took the first Resources phase | Add it to the Resources phase of the application target |
| `CYLTabBarHostView` shows no tab for an item | Neither a page ID nor an identifier: no page | The host gives such a tab a page ID of its own (`CYLTabBarHostView-tab-<index>`) |

### Clean builds

- **Before every build and run** (an app, `xcodebuild test`, a script that builds), start from an empty derived data
  folder: `rm -rf <derived data>` or a new `-derivedDataPath`. The Objective-C demo does not relink after a change in the
  library only, so an incremental build runs the old library code: a test or a screenshot from it proves nothing.
  `scripts/plus-child-theme-test.sh` deletes its build folder itself; `scripts/unit-tests.sh` builds into a new folder
  under `$TMPDIR` and deletes it afterwards.
- When in doubt, check that the app holds the new code: `strings <app>/<binary> | grep <new symbol>`.

### Running the simulator

- **Before every run of the iOS Simulator** (`xcrun simctl boot`, `xcodebuild test`, installing and launching an app,
  opening Simulator.app, simulator screenshots), AI agents first run `scripts/free-ram.sh` to free up RAM.
- It never asks for a password: `purge` runs through `sudo -n`, and is skipped with a hint when the maintainer has not
  run the one-time `scripts/free-ram.sh --install` (a sudoers rule that allows only `/usr/sbin/purge`). Never type,
  store or ask for a password to work around that; continue without the purge and mention the hint.
- It quits no app or simulator, and does nothing outside macOS.

### CYLTableViewPlaceHolder in every example

Every example, existing and new, integrates CYLTableViewPlaceHolder with CocoaPods at its latest commit on any branch
(`CYL_REPO_URL=https://github.com/ChenYilong/CYLTableViewPlaceHolder.git scripts/latest-cyl-commit.sh --sha`, then
`:git => …, :commit => '<sha>'`, plus the `LottieSwift` subspec). Every iOS example scroll view has pull to refresh
(`cyl_header`), an empty-data and a no-network placeholder (animated icons preferred) and a red bar at the top while
offline. MJRefresh is not used (`mj_` → `cyl_`, `MJRefresh…` → `CYLRefresh…`). Library-caused build errors go into
`docs/CYLTableViewPlaceHolder-Integration-Issues.md`. AGENTS.md, "Depending on CYLTableViewPlaceHolder".

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

## Locating controls in UI tests

All code of this project supports accessibility and localization, including the HarmonyOS code. UI tests and simulator /
emulator checks locate controls through accessibility identifiers, accessibility labels / texts and localized strings
first (XCUITest, `axe describe-ui`, `uiautomator`, HarmonyOS UiTest `ON.id()` / `ON.text()`, Flutter
`find.bySemanticsLabel`, React Native `getByLabelText`), for taps, complex flows and consecutive steps. Coordinates are
the last resort; a control that cannot be found that way is a bug: add the label first. HarmonyOS details: `cyl-harmonyos-a11y-l10n`.

## Pull requests for every branch

- **Every branch with commits has an open pull request (added 2026-11-16).** After creating a branch, any commit on it
  must be in a pull request. Never create a branch and keep committing to it without one: commits on a branch with no
  pull request are ignored, because nothing ever merges them.
  - **Before every commit**, check that the current branch has an open pull request
    (`gh pr list --state open --head <branch>`). If it has none (never opened, closed or merged), open a new one right
    after pushing (`gh pr create --base <target> --head <branch>`).
  - **Target branch**: the branch of the pull request that was active (open) before this one was created; only when
    there is none, `master` (or `main`).
  - **More than two open pull requests: ask first.** When the repository already has more than two open pull requests,
    do not open another one on your own: ask the owner whether to create a new branch and pull request or to keep
    committing on the current branch. More than two open branches make merging hard and leave no sensible target for
    each branch.
  - Push only to branches that have an open pull request; do not recreate a branch that was deleted after its pull
    request was closed or merged.

## Fix in the core first (added 2026-11-17)

Change the core code (the code published to CocoaPods, Swift Package Manager, Maven / Gradle, npm, pub.dev, ohpm or
the WeChat Mini Program component) so that the whole class of bug is avoided; a fix only in the example layer is the
worst option. If the core cannot fix it, ask the owner first and explain why; after the owner agrees, fix it in the
example and record the reason in `docs/Example-Layer-Fixes.md` (see AGENTS.md, "Code rules").
