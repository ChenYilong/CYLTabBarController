---
name: cyl-new-project
description: "Create a new app or a new demo with CYLTabBarController: choose the integration and subspec, the iOS and Xcode versions, app entry, tabs and plus button. Use whenever a new Example-* folder or a new project based on this library is created."
---

# New project or demo with CYLTabBarController

Every new demo in this repository is created with this skill. Source of truth: code, then `docs/`, then `README.md`. If they disagree, fix the wrong one first (usually `README.md`), then this skill.

## 1. Choose the integration

| Need | Integration | Nearest demo to copy | Minimum iOS |
|:---|:---|:---|:---|
| Tab bar, plus button, badges, themes (no animation) | `pod 'CYLTabBarController'` (Core is the default subspec) | `Example-Swift-04` (smallest UIKit), `Example-Swift-03` | podspec 12.0; use 15.0 |
| SwiftUI app | same pod, `UIViewControllerRepresentable` + `UIHostingController` | `Example-SwiftUI` | 15.0 |
| Lottie 4.x tab icons | `pod 'CYLTabBarController/LottieSwift'` | `Example-Swift` | subspec 13.0; use 15.0 |
| Lottie 2.5 (Objective-C) | `pod 'CYLTabBarController/Lottie'` | `Example-Swift-02` | use 15.0 |
| PAG tab icons | `pod 'CYLTabBarController/PAG'` | `Example-PAG` | use 15.0 |
| Rive tab icons | `pod 'CYLTabBarController/Rive'` (RiveRuntime ~> 6.29; CocoaPods only) | `Example-Rive`, `Example-SwiftUI-Rive` | subspec 14.0; demos use 15.0 |
| GIF tab icons that play once | `pod 'CYLTabBarController/GIF'` (no third-party dependency) | `Example-GIF` | use 15.0 |
| FlatDesign (the classic layout on every system) | `pod 'CYLTabBarController/CYLFlatDesignTabBar'` | `Example-network-download`, the root ObjC demo | subspec 13.0; use 15.0 |
| Swift Package Manager | package URL or `relativePath = ..` (Core + FlatDesign + Lottie 4.x; no PAG or Rive) | `Example-Swift-SwiftManager-FlatDesign`, `Example-Swift-Gallery`, `Example-Swift-SwiftManager` (iOS 26) | package iOS 13; use 15.0 |
| Carthage | `binary "https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/CYLTabBarController.json"`, a prebuilt XCFramework (up to 1.100.0: `github "ChenYilong/CYLTabBarController"`; no Lottie, PAG or Rive; see docs/Carthage.md) | `Example-Swift-Carthage` | 15.0 |
| Objective-C, every feature | root `CYLTabBarController.xcodeproj` + `Example/` | `Example/` (the Tab Bar Gallery has a scene per API) | 15.0 |
| Android app: `CYLTabBarController` for Android (the iOS API in Kotlin and Java) from the same configuration file | `Example-Android/cyltabbar` (Gradle; depends on `tabpages`) | `Example-Android` | minSdk 23, compileSdk 35; see [Android-Library](../../../docs/Android-Library.md) |
| React Native or Flutter app: the native tab bar, pages drawn in JS / Dart | `CrossPlatform/react-native-cyltabbar` (Fabric) or `CrossPlatform/flutter_cyltabbar` (platform view); Flutter on Android needs `FlutterFragmentActivity` | `CrossPlatform/*/example` | iOS 15.1 (RN) / 15.0 (Flutter); follow [React-Native-Component](../../../docs/React-Native-Component.md) or [Flutter-Component](../../../docs/Flutter-Component.md); a native app that draws its own pages: `CYLTabBarHostView` |
| React Native or Flutter app with PAG / Rive tab icons | The same component plus the iOS subspec `CYLTabBarController/PAG` or `/Rive` (CocoaPods; Flutter turns Swift Package Manager off) and libpag / rive-android on Android; `CYLAnimationView` for animations in a page | `CrossPlatform/react-native-cyltabbar/example-pag`, `example-rive`; `CrossPlatform/flutter_cyltabbar/example_pag`, `example_rive` | the Podfile's `post_install` sets every pod to iOS 15.0 (React Native: 15.1), as AGENTS.md "Xcode projects"; reuse the native demo's files: add them to the iOS app target, point Android `assets.srcDirs` at them; see [Cross-Platform-Components](../../../docs/Cross-Platform-Components.md#enanimated-icon-demos) |

`Example-Shared/` holds Swift sources that the Swift demos share; reuse it instead of copying (SonarCloud counts copies as duplicated code). A new HealthyHome demo references `Example-Swift-03/HealthyHome` and puts its differences behind a compile condition; see AGENTS.md, "No copied sources". See [Tab-Bar-Item-Animation](../../../docs/Tab-Bar-Item-Animation.md) for combining libraries and [Swift-Guide](../../../docs/Swift-Guide.md) for `import` failures.

## 2. Versions (see `cyl-xcode-compat`)

- Deployment target 15.0 unless a dependency needs more: Xcode 27 only supports iOS 15.0+. Never 27 or more, in the target or the project.
- Project format: `objectVersion = 46`, `compatibilityVersion = "Xcode 3.2"`, no folder sync. CI opens projects with Xcode 26.
- Built with the iOS 27 SDK, an app needs the UIScene life cycle: a `UIApplicationSceneManifest` and a `SceneDelegate`. A SwiftUI `App` names no `UISceneDelegateClassName`.
- Do not set `UIViewControllerBasedStatusBarAppearance = NO`: UIKit then reads `-[UIApplication statusBarStyle]`, a no-op on iOS 27 that logs on every status bar update.
- Orientations: only the Xcode target settings decide. Add no orientation limit in code.

## 3. The app (Swift, UIKit)

```ruby
# Podfile
project 'YourApp.xcodeproj'
platform :ios, '15.0'
target 'YourApp' do
  use_frameworks!
  pod 'CYLTabBarController'
end
```

```swift
// AppDelegate: before any CYLTabBarController is created. Skip it without a plus button.
CYLPlusButtonSubclass.register()

// SceneDelegate
func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    // The provider rebuilds the root after an in-app language change.
    window.cyl_setRootViewControllerProvider {
        CYLTabBarController(viewControllers: makeViewControllers(), tabBarItemsAttributes: makeAttributes())
    }
    window.makeKeyAndVisible()
    self.window = window
}
```

- Open the `.xcworkspace` after `pod install`.
- `viewControllers` and `tabBarItemsAttributes` have the same count; the plus button is in neither.
- Pass image names (`NSString`), not `UIImage`: names render as original and find their Dark images. Details in `README.md`, step 2.
- Subclassing in Swift has two traps (override both initializers; `init(nibName:bundle:)` forwards only to super): [Swift-Guide](../../../docs/Swift-Guide.md), section 3. Never return another instance from `-init` (#404).
- Objective-C: `README.md`, steps 2 to 4, and `Example/SceneDelegate.m`. SwiftUI: [SwiftUI-Integration](../../../docs/SwiftUI-Integration.md).
- Plus button: `cyl-plus-button`. Animated icons: `cyl-tab-animation` and [Tab-Icon-Animation-Quick-Start](../../../docs/Tab-Icon-Animation-Quick-Start.md); suggest running the matching demo first. Skins: `cyl-theme`.

### How the Podfile depends on CYLTabBarController

Always CocoaPods, always the latest commit of CYLTabBarController on any branch (AGENTS.md, "Depending on CYLTabBarController").
Before every build run `scripts/latest-cyl-commit.sh --podfile` (by its absolute path from another project) and put the line it
prints into the Podfile: `pod 'CYLTabBarController', :git => 'https://github.com/ChenYilong/CYLTabBarController.git', :commit => '<sha>'`;
then `pod install`. Not a version number, not a branch, not a tag. The only exception is a project named CYLTabBarController (this
repository and its demos): `pod 'CYLTabBarController', :path => '<relative path to the folder with CYLTabBarController.podspec>'`,
for example `:path => '../'` in a demo folder.

## 4. A demo inside this repository, in addition

1. Copy the nearest demo above; do not start from an Xcode template, which writes a newer project format.
2. Import only `#import <CYLTabBarController/CYLTabBarController.h>` or `import CYLTabBarController`.
3. Name the project in the Podfile (`project '<Name>.xcodeproj'`). `Pods/` stays out of Git.
4. Add the folder to the `Demo` matrix in `.github/workflows/ios.yml`. Today `Example-PAG`, `Example-Rive`, `Example-SwiftUI-Rive` and `Example-Swift-Carthage` are not in it; say so in the PR if a new demo stays out too.
5. Add it to the table in section 1 and to the demo list in `README.md`.
6. Build: `scripts/ci-build-example.sh <folder>`, then follow `cyl-verify`.
7. Check the project format with the commands in `cyl-xcode-compat`.
8. Localization: a project must have at least two different macros that read the localized files of two different layers.
   The library's own texts come from the **core** macro (`CYLLocalizedString`, `CYLTabBarController.bundle`); the demo's own
   texts come from the **example** macro (iOS: `CYLDemoLocalizedString`, in Swift `cylDemoLocalizedString`, reading `Example-Shared/CYLDemo.bundle`). In a demo
   project add `Example-Shared/CYLDemoLocalization.swift` (Swift) or `.m` + `.h` (Objective-C) and `CYLDemo.bundle` to the app
   target (file references with `SOURCE_ROOT`, as the other demos do), and call the example macro for every demo-only text.
   Never read the core bundle with `NSLocalizedString` / `NSBundle` calls of your own, and never leave loose `.lproj` folders.
   Check with `python3 scripts/check-localization-macros.py`. Other platforms: the same two layers in their own package form
   (AGENTS.md, "Localization (i18n / l10n) file structure").

## Podfile, app icon, launch screen

Every Xcode project checks its Podfile (top lines `platform :ios, '15.0'`, `ENV['SWIFT_VERSION'] = '5'`, `project '<name>.xcodeproj'`; a `post_install` hook that sets `IPHONEOS_DEPLOYMENT_TARGET` to 15.0 on every pod), and copies the ObjC example's app icon and launch screen when it has none. Full rule and exceptions (one `post_install` only, React Native minimum 15.1): AGENTS.md, "Xcode projects: Podfile, app icon, launch screen".

### Default setup in the examples

Unless the task says otherwise, an example's CYLTabBarController has a plus button **with its own page**
(`plusChildViewController`) and is created **from a local configuration file** with
`+tabBarControllerWithConfigurationFile:error:` (tabs in `CYLTabBarControllerTabBarItemsAttributes`, the plus button in
`CYLTabBarControllerPlusButton`, its page by `CYLTabBarItemPageIdentifier`). Another setup is used only on purpose and named
in the demo. AGENTS.md, "How the examples set CYLTabBarController up".

### CYLTableViewPlaceHolder in every example

Every example, existing and new, integrates CYLTableViewPlaceHolder with CocoaPods at its latest commit on any branch
(`CYL_REPO_URL=https://github.com/ChenYilong/CYLTableViewPlaceHolder.git scripts/latest-cyl-commit.sh --sha`, then
`:git => …, :commit => '<sha>'`, plus the `LottieSwift` subspec). Every iOS example scroll view has pull to refresh
(`cyl_header`), an empty-data and a no-network placeholder (animated icons preferred) and a red bar at the top while
offline. MJRefresh is not used (`mj_` → `cyl_`, `MJRefresh…` → `CYLRefresh…`). Library-caused build errors go into
`docs/CYLTableViewPlaceHolder-Integration-Issues.md`. AGENTS.md, "Depending on CYLTableViewPlaceHolder".
