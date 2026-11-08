---
name: cyl-verify
description: "How to build, test and check CYLTabBarController and its demos, run the simulator safely, and read common failures. Use before saying a change works, before pushing, and when a demo does not build."
---

# Verify

Say plainly what could not be verified. Never call something fixed from a build alone if it is a visual change.

## Commands

```sh
pod lib lint CYLTabBarController.podspec --quick            # before every push
scripts/unit-tests.sh "iPhone 17 Pro Max"                   # the unit tests (scheme CYLTabBarController-Framework)
scripts/ci-build-example.sh <demo folder>                   # one demo, as CI builds it
scripts/plus-child-theme-test.sh "iPhone 17 Pro Max"        # plus child + theme, on a simulator
scripts/scroll-hide-self-test.sh                            # scroll hiding, on a simulator
python3 scripts/update-docs-navigation.py --check
python3 scripts/sync-agent-skills.py --check
scripts/publish-android.sh staging                          # Android library: Maven bundle, checked (local | staging | central | github)
# React Native component (CrossPlatform/react-native-cyltabbar): yarn; yarn tsc --noEmit; in example/ios: LANG=en_US.UTF-8 pod install,
# then xcodebuild; in example/android: JAVA_HOME=<JDK 17> ./gradlew :app:assembleDebug
# Flutter component (CrossPlatform/flutter_cyltabbar): flutter analyze; flutter test; in example: flutter build ios --simulator
#   (Swift Package Manager, the plugin depends on this repository's Package.swift) / flutter build apk (JDK 17)
# Library: CYLTabBarHostViewTests (scripts/unit-tests.sh), CYLTabBarHostViewTest (Android, Robolectric)
```

The `CYLTabBarController` scheme has no test action: use `scripts/unit-tests.sh`. Static analysis: `xcodebuild analyze` must report no warnings.

## Common failures

| Symptom | Cause | Fix |
|:---|:---|:---|
| The ObjC demo runs old code after a library fix | Xcode did not relink: the library lands in the app's binary | Build with a fresh `-derivedDataPath`; check with `nm <app>/<binary>` |
| `cannot find 'CYLTabBarItemAnimationFactory' in scope`, or `type 'CYLTabBarAnimationOption' has no member` | Stale `Pods/` after headers changed | `pod install` in the demo |
| Simulator taps do nothing | The simulator's input is stuck | Shut it down, boot it, wait, try again |
| `pod` fails with a missing `ffi` | The system's CocoaPods | Use the Homebrew one: put `/opt/homebrew/opt/ruby/bin` and its gems `bin` first in `PATH` |
| Git errors about `._*` files on the exFAT volume | macOS AppleDouble files inside `.git` | `find .git -name '._*' -delete` |
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

### Running the simulator

- **Before every run of the iOS Simulator** (`xcrun simctl boot`, `xcodebuild test`, installing and launching an app,
  opening Simulator.app, simulator screenshots), AI agents first run `scripts/free-ram.sh` to free up RAM.
- It never asks for a password: `purge` runs through `sudo -n`, and is skipped with a hint when the maintainer has not
  run the one-time `scripts/free-ram.sh --install` (a sudoers rule that allows only `/usr/sbin/purge`). Never type,
  store or ask for a password to work around that; continue without the purge and mention the hint.
- It quits no app or simulator, and does nothing outside macOS.
