---
name: cyl-tab-animation
description: "Animated tab icons in CYLTabBarController with Lottie, PAG, Rive or GIF: subspecs, keys, options, availability guards, and adding a new animation library. Use when adding animated tabs or touching the CYLTabBarItemAnimation subspec."
---

# Animated tab icons

Steps for app developers: [Tab-Icon-Animation-Quick-Start](../../../docs/Tab-Icon-Animation-Quick-Start.md). **Tell the user to run the matching demo first** (`Example-PAG`, `Example-Rive`, `Example-Swift`) and tap a few tabs, so they see the effect before integrating. The tab selected at launch shows its last frame without playing (#389), so tell them to tap another tab. Design: [Tab-Bar-Item-Animation](../../../docs/Tab-Bar-Item-Animation.md). Source of truth: code, then `docs/`, then `README.md`. If they disagree, fix the wrong one first (usually `README.md`), then this skill.

## Choose

| Library | Subspec | File key | Size key | Limits | Demo |
|:---|:---|:---|:---|:---|:---|
| Lottie 4.x | `LottieSwift` | `CYLTabBarLottieURL` | `CYLTabBarLottieSize` | iOS 13 | `Example-Swift` |
| Lottie 2.5 | `Lottie` | same | same | Objective-C | `Example-Swift-02` |
| PAG | `PAG`, `PAGEnterprise` | `CYLTabBarPAGURL` / `CYLTabBarPAGFilePath` | `CYLTabBarPAGSize` | [PAG-Animation](../../../docs/PAG-Animation.md) | `Example-PAG` |
| Rive | `Rive` | `CYLTabBarRiveURL` / `CYLTabBarRiveFilePath` | `CYLTabBarRiveSize` | iOS 14, CocoaPods only; options such as `CYLTabBarAnimationOptionRiveArtboard` on the URL | `Example-Rive`, `Example-SwiftUI-Rive` |

| GIF | `GIF` (no third-party dependency) | `CYLTabBarGIFURL` / `CYLTabBarGIFFilePath` (local files) | `CYLTabBarGIFSize` | [GIF-Animation](../../../docs/GIF-Animation.md) | `Example-GIF` |
- `pod 'CYLTabBarController'` alone has **no** animation code. Without a subspec the tabs show their images.
- **A GIF plays according to the key that gives it.** `CYLTabBarItemImage` or `CYLTabBarItemImageURL`: an image, it loops, no subspec. The GIF keys or generic animation keys: an animation, it plays once when selected. Tell the user which one they get.
- Every library works with Liquid Glass, FlatDesign and the classic tab bar. Check all three: `Example-GIF`, `Example-PAG` and `Example-Rive` switch from the navigation bar of the settings list, or with `-CYLDemoTabBarFlatDesign YES`. FlatDesign must be given as `styleType:` when the controller is created. On a simulator, check the classic tab bar on an iOS version before 26. PAG's OpenGL crashes the iOS 17.5 simulator on macOS 27 (`libCoreVMClient`): add `UIDesignRequiresCompatibility` to a copy of the built app's `Info.plist`, sign it again with `codesign -f -s - --deep`, and run it on iOS 26 instead.
- Android: `Example-Android/example-pag`, `example-gif` and `example-rive` are the twins of the iOS examples and read the same animation files ([Android-Examples](../../../docs/Android-Examples.md)); a GIF given as an image loops there too (`CYLGIFDrawable`).
- On the classic tab bar, a tab item's title change makes UIKit replace the tab's button. The library restores the animation on the new button (`-cyl_bindTabControlActions`). A page that sets `self.title` renames its tab: use `navigationItem.title` to keep the tab's title.
- Subspecs combine, and one tab bar can mix libraries and static tabs: [Per-Tab-Animation](../../../docs/Per-Tab-Animation.md).
- Demo files: name them by use (`tab_home.pag`). A tab shows the first frame until it is selected, so pick a small file whose first frame shows the icon; a full-screen poster or a file that starts empty looks like a blank or still tab. Check a new file's frames before using it.
- PAG and Rive files draw their own colors, and Liquid Glass ignores a background color in `standardAppearance`. White icons (the course's `icons.riv`) need a dark interface: the Rive demos set `overrideUserInterfaceStyle = .dark` on the tab bar controller.
- On a simulator several asynchronous `PAGView`s stall inside software OpenGL while holding their locks, which blocks the main thread: blank icons, no playback. The animator sets `-setSync:YES` on every target, so a simulator and a device run the same path. To debug playback, trace `-play` and `onAnimationUpdate:` rather than judging from screenshots.
- A configuration file (`-initWithConfiguration:`, [Configuration-File](../../../docs/Configuration-File.md)) takes the same keys as strings: the generic `CYLTabBarAnimation…` keys, PAG's, Rive's and GIF's keys (by name, whether or not the subspec is installed), `CYLTabBarAnimationOptions` (a dictionary written into the animation URL's fragment, e.g. `{"artboard": "HOME", "input": "active"}`), `CYLTabBarLottieLoopsWhenUnselected`, and the top-level `CYLTabBarControllerTabBarItemAnimationSpeed`.
- React Native and Flutter: the tab bar configuration takes the same keys; `CYLAnimationView` plays a file in a page through `CYLTabBarItemAnimationFactory` (options sorted into the URL fragment). Demos: `CrossPlatform/react-native-cyltabbar/example-pag` / `example-rive`, `CrossPlatform/flutter_cyltabbar/example_pag` / `example_rive`; see [Cross-Platform-Components](../../../docs/Cross-Platform-Components.md#enanimated-icon-demos). On Android the library calls `Rive.init` once (reflection) before the first Rive view; apps do not.
- WeChat Mini Program: the same keys through `cyl-tab-bar-item`, which picks `cyl-lottie`, `cyl-pag` (full libpag-miniprogram 4.5.85, WebAssembly + WebGL, vector PAG files; 4.4.76 fails in DevTools) or `cyl-rive` (`@rive-app/canvas-advanced` + WXWebAssembly) by file type. Package copies are `*.pag.bin` / `*.riv.bin`; the WebAssembly files are copied out of `miniprogram_npm` to `/cyl-rive-miniprogram/rive.wasm.br` and `/cyl-pag-miniprogram/libpag.wasm.br`. Demo: `CrossPlatform/wechat-miniprogram-cyltabbar/example` (Me page, "Tab icons"); see [WeChat-Mini-Program](../../../docs/WeChat-Mini-Program.md).
- `tabBarItemAnimationSpeed` sets the speed. PAG files are downloaded by `scripts/fetch-animation-resources.py` at `pod install`, not kept in the repository.

## Keeping this current

A new animation library, key, limit or demo also updates [Tab-Icon-Animation-Quick-Start](../../../docs/Tab-Icon-Animation-Quick-Start.md).

## Rules for the library

- Core and CYLUtils get no library switch. A library's keys exist only with that library: its header defines `CYL_<LIBRARY>_AVAILABLE` (`__has_include`), and the header's content and the `.m` definitions sit inside it. The released Lottie keys stay defined and are marked `CYL_LOTTIE_REQUIRED`.
- A new library is one more folder, one more animator class and one more subspec, with no change anywhere else. The animator registers itself in `+load` with `CYLTabBarItemAnimatorRegistry`.
- Rive's Metal shader warnings in the console (`program_source ... Compilation succeeded`) come from the `RiveRuntime` binary. They are harmless and cannot be fixed here.
