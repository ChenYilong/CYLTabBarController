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
| Rive tab icons | `pod 'CYLTabBarController/Rive'` (RiveRuntime ~> 6.29; CocoaPods only) | `Example-Rive`, `Example-SwiftUI-Rive` | subspec 14.0; demos use 15.4 |
| FlatDesign (the classic layout on every system) | `pod 'CYLTabBarController/CYLFlatDesignTabBar'` | `Example-network-download`, the root ObjC demo | subspec 13.0; use 15.0 |
| Swift Package Manager | package URL or `relativePath = ..` (Core + FlatDesign + Lottie 4.x; no PAG or Rive) | `Example-Swift-SwiftManager-FlatDesign`, `Example-Swift-Gallery`, `Example-Swift-SwiftManager` (iOS 26) | package iOS 13; use 15.0 |
| Carthage | `github "ChenYilong/CYLTabBarController"` (no Lottie, PAG or Rive) | `Example-Swift-Carthage` | 15.0 |
| Objective-C, every feature | root `CYLTabBarController.xcodeproj` + `Example/` | `Example/` (the Tab Bar Gallery has a scene per API) | 15.0 |

`Example-Shared/` holds Swift sources that the Swift demos share; reuse it instead of copying. See [Tab-Bar-Item-Animation](../../../docs/Tab-Bar-Item-Animation.md) for combining libraries and [Swift-Guide](../../../docs/Swift-Guide.md) for `import` failures.

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

## 4. A demo inside this repository, in addition

1. Copy the nearest demo above; do not start from an Xcode template, which writes a newer project format.
2. Import only `#import <CYLTabBarController/CYLTabBarController.h>` or `import CYLTabBarController`.
3. Name the project in the Podfile (`project '<Name>.xcodeproj'`). `Pods/` stays out of Git.
4. Add the folder to the `Demo` matrix in `.github/workflows/ios.yml`. Today `Example-PAG`, `Example-Rive`, `Example-SwiftUI-Rive` and `Example-Swift-Carthage` are not in it; say so in the PR if a new demo stays out too.
5. Add it to the table in section 1 and to the demo list in `README.md`.
6. Build: `scripts/ci-build-example.sh <folder>`, then follow `cyl-verify`.
7. Check the project format with the commands in `cyl-xcode-compat`.
