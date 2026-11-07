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

### Running the simulator

- **Before every run of the iOS Simulator** (`xcrun simctl boot`, `xcodebuild test`, installing and launching an app,
  opening Simulator.app, simulator screenshots), AI agents first run `scripts/free-ram.sh` to free up RAM.
- It never asks for a password: `purge` runs through `sudo -n`, and is skipped with a hint when the maintainer has not
  run the one-time `scripts/free-ram.sh --install` (a sudoers rule that allows only `/usr/sbin/purge`). Never type,
  store or ask for a password to work around that; continue without the purge and mention the hint.
- It quits no app or simulator, and does nothing outside macOS.
