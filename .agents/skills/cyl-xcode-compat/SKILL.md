---
name: cyl-xcode-compat
description: "Xcode and iOS version compatibility of CYLTabBarController: project format, deployment targets, CI runners, UIScene, Liquid Glass and FlatDesign availability. Use when creating or touching any .xcodeproj, changing a deployment target, or asking which versions a feature needs."
---

# Xcode and iOS compatibility

Source of truth: code, then `docs/`, then `README.md`. If they disagree, fix the wrong one first (usually `README.md`), then this skill.

## Versions at a glance

| Item | Value | Where |
|:---|:---|:---|
| Library minimum | podspec iOS 12.0; `LottieSwift` and `CYLFlatDesignTabBar` 13.0; `Rive` 14.0; SPM 13 | `CYLTabBarController.podspec`, `Package.swift` |
| Swift | `s.swift_versions = 5.0`, `SWIFT_VERSION = 5.0` in the demos; swift-tools 5.9 | podspec, `Package.swift` |
| Local Xcode | 27 builds down to iOS 15.0 only, so linting forces 15.0 | `scripts/pod-lint.xcconfig` |
| CI | `macos-26` (Xcode 26.x) unless the `MACOS_RUNNER` variable says otherwise | `.github/workflows/ios.yml`, [Mac-CI-CD](../../../docs/Mac-CI-CD.md) |
| New demo | deployment target 15.0, `objectVersion = 46` | below |

## What each system shows

| System | Default tab bar | Notes |
|:---|:---|:---|
| iOS 25 and earlier, iOS 26 compatibility mode | classic system tab bar | selected images are used; item positioning works |
| iOS 26+ | Liquid Glass | a stand-in for the plus button; `CYLTabBarStyleTypeFlatDesign` keeps the classic look (needs the FlatDesign subspec) |
| iOS 27 SDK | Liquid Glass | UIScene life cycle required; `-[UIApplication statusBarStyle]` is a no-op |
| iOS 27.1, unfolded iPhone Duo | vertical bar with `allowsVerticalBar = YES` | the plus button's Y offset methods are ignored |

Guard for Liquid Glass code: `CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType && [CYLConstants isLiquidGlassActive]`.

## 5. Xcode project files keep the ObjC example's format

**Purpose: keep CI/CD from failing.** CI and releases run on the `macos-26` runner (Xcode 26.x, no Xcode 27; see
`docs/Mac-CI-CD.md`). A project saved in a newer format cannot be opened there, and its job fails. This happened to
`scripts/ci-build-example.sh "Example-Swift-SwiftManager-FlatDesign"` after Xcode 27 saved that project
(fixed in [#772](https://github.com/ChenYilong/CYLTabBarController/pull/772)):

```
xcodebuild: error: Unable to read project 'TWDFGASDGDSFDFG.xcodeproj' from folder '/Users/runner/work/CYLTabBarController/CYLTabBarController/Example-Swift-SwiftManager-FlatDesign/.'.
	Reason: The project 'TWDFGASDGDSFDFG' cannot be opened because it is in a future Xcode project file format (110). Adjust the project format using a compatible version of Xcode to allow it to be opened by this version of Xcode.
```

**When this applies**: you create an Xcode project, or a commit touches any file inside a `*.xcodeproj` (above all
`project.pbxproj`). Before committing, search the diff for it, e.g. `git diff --cached --name-only | grep '\.xcodeproj/'`,
and check every project it lists.

**Keywords**: besides `.xcodeproj`, search the commit's code (the diff) for these keywords. A hit means an Xcode
project setting changed and this section applies. Each keyword is followed by a complete example of the line it
appears in, taken from the fix in #772 (CI/CD passed with these values), and by what to do when it shows up:

| Keyword | Complete example (#772) | Guidance |
|:---|:---|:---|
| `.xcodeproj` | `Example-Swift-SwiftManager-FlatDesign/TWDFGASDGDSFDFG.xcodeproj/project.pbxproj` | Any file under a `.xcodeproj` changed: run the check below on that project. Compare it with `CYLTabBarController.xcodeproj`; if the diff is large because Xcode rewrote the project, keep only the changes you meant and restore the format values. |
| `objectVersion` | `objectVersion = 46;` (was `110`) | Must stay `46`. If Xcode raised it, set it back. A value of 77 or more usually comes with folder sync: convert that to explicit file lists as #772 did; do not just change the number. |
| `compatibilityVersion` | `compatibilityVersion = "Xcode 3.2";` (was `"Xcode 8.0"` / `"Xcode 9.3"` / missing) | Must be `"Xcode 3.2"`, in the `PBXProject` object right after `buildConfigurationList`. Add it when missing, and remove `preferredProjectObjectVersion` and the top-level `validationLevel` if present. |
| `IPHONEOS_DEPLOYMENT_TARGET` | `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` (`Example-Swift-04`, was `27.0`) | Never 27 or more, not even at the project level. Use 15.0, like the ObjC example; match the app's Podfile `platform :ios` so the app is not below its pods. Before lowering it, check the code for newer APIs without `#available`. A raised value is usually an accident of a newer Xcode saving the project (e.g. #669), not a code need. |

```sh
git diff --cached --name-only | grep '\.xcodeproj'
git diff --cached | grep -E 'objectVersion|compatibilityVersion|IPHONEOS_DEPLOYMENT_TARGET'
```

**Example fix**: [#772](https://github.com/ChenYilong/CYLTabBarController/pull/772) brought every example back to the
ObjC example's format. Follow its diff when a project needs the same fix: format 110 / 77 / 60 / 50 / 48 set to 46,
folder sync replaced by explicit file lists, the Xcode 27-only keys removed, and every deployment target of 27.0 lowered
to 15.0 (FlatDesign's project level, `Example-Swift-04`'s app target).

**The rule**: every project matches the root ObjC example, `CYLTabBarController.xcodeproj`:

- `objectVersion = 46;` in `project.pbxproj`, and `compatibilityVersion = "Xcode 3.2";` in the `PBXProject` object
  (right after `buildConfigurationList`).
- No `preferredProjectObjectVersion` key, and no top-level `validationLevel` key (Xcode 27 only).
- No folder sync: no `PBXFileSystemSynchronizedRootGroup` or `PBXFileSystemSynchronizedBuildFileExceptionSet`
  (format 77+, Xcode 16). List the files explicitly: `PBXGroup`, `PBXFileReference`, `PBXBuildFile` in the Sources /
  Resources phases, and `PBXVariantGroup` for `Base.lproj` storyboards. Keep the target membership the same (e.g.
  `Info.plist` stays out of Resources). New files are added to the target by hand in Xcode.
- No effective deployment target newer than the CI SDK: no `IPHONEOS_DEPLOYMENT_TARGET` of 27 or more, not even at the
  project level when a target overrides it.
- Scheme files (`*.xcscheme`) may keep `version="1.7"`; Xcode 15 and later read it.
- **Exception**: `CrossPlatform/flutter_cyltabbar/example*/ios/Runner.xcodeproj` (`example`, `example_pag`, `example_rive`) keeps `objectVersion = 54` (Xcode 12
  format, no folder sync), because `flutter build` sets it back to 54 on every build; its `compatibilityVersion` is
  still `"Xcode 3.2"`. `example` uses Swift Package Manager (`XCLocalSwiftPackageReference` to Flutter's generated package),
  which Flutter adds; `example_pag` and `example_rive` use CocoaPods. The React Native examples (`CrossPlatform/react-native-cyltabbar/example*/ios`) follow the rule
  (46), with React Native's minimum deployment target, 15.1 (15.4 for `example-rive`).

**Check it** (each line must print `46` and `"Xcode 3.2"` and nothing else):

```sh
for f in $(git ls-files '*.pbxproj'); do
  echo "$f: $(grep -oE 'objectVersion = [0-9]+|compatibilityVersion = "[^"]+"|preferredProjectObjectVersion|validationLevel|PBXFileSystemSynchronized[A-Za-z]*|IPHONEOS_DEPLOYMENT_TARGET = (2[7-9]|[3-9][0-9])' "$f" | sort -u | tr '\n' ' ')"
done
```

- When Xcode upgrades a project's format (it does when a newer Xcode saves it), set those values back before committing.
- A project that uses folder sync has to be converted to explicit file lists, not just relabeled. Afterwards check it
  with CocoaPods' parser (`ruby -rxcodeproj -e 'Xcodeproj::Project.open(ARGV[0])' <path>.xcodeproj`, run with
  `LC_ALL=C.UTF-8`) and make sure every file in its build phases exists on disk.
- Say in the PR that the project was not opened in Xcode when it could not be; the `Demo …` CI jobs on `macos-26` are
  the real check.
