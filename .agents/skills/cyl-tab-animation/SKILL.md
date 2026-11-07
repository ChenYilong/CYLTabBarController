---
name: cyl-tab-animation
description: "Animated tab icons in CYLTabBarController with Lottie, PAG or Rive: subspecs, keys, options, availability guards, and adding a new animation library. Use when adding animated tabs or touching the CYLTabBarItemAnimation subspec."
---

# Animated tab icons

Main document: [Tab-Bar-Item-Animation](../../../docs/Tab-Bar-Item-Animation.md). Source of truth: code, then `docs/`, then `README.md`. If they disagree, fix the wrong one first (usually `README.md`), then this skill.

## Choose

| Library | Subspec | File key | Size key | Limits | Demo |
|:---|:---|:---|:---|:---|:---|
| Lottie 4.x | `LottieSwift` | `CYLTabBarLottieURL` | `CYLTabBarLottieSize` | iOS 13 | `Example-Swift` |
| Lottie 2.5 | `Lottie` | same | same | Objective-C | `Example-Swift-02` |
| PAG | `PAG`, `PAGEnterprise` | `CYLTabBarPAGURL` / `CYLTabBarPAGFilePath` | `CYLTabBarPAGSize` | [PAG-Animation](../../../docs/PAG-Animation.md) | `Example-PAG` |
| Rive | `Rive` | `CYLTabBarRiveURL` / `CYLTabBarRiveFilePath` | `CYLTabBarRiveSize` | iOS 14, CocoaPods only; options such as `CYLTabBarAnimationOptionRiveArtboard` on the URL | `Example-Rive`, `Example-SwiftUI-Rive` |

- `pod 'CYLTabBarController'` alone has **no** animation code. Without a subspec the tabs show their images.
- Subspecs combine, and one tab bar can mix libraries and static tabs: [Per-Tab-Animation](../../../docs/Per-Tab-Animation.md).
- Demo files: name them by use (`tab_home.pag`). A tab shows the first frame until it is selected, so pick a small file whose first frame shows the icon; a full-screen poster or a file that starts empty looks like a blank or still tab. Check a new file's frames before using it.
- PAG and Rive files draw their own colors, and Liquid Glass ignores a background color in `standardAppearance`. White icons (the course's `icons.riv`) need a dark interface: the Rive demos set `overrideUserInterfaceStyle = .dark` on the tab bar controller.
- On a simulator libpag draws with software OpenGL: icons can appear many seconds late, and the main thread can wait on libpag. Judge PAG playback on a device.
- `tabBarItemAnimationSpeed` sets the speed. PAG files are downloaded by `scripts/fetch-animation-resources.py` at `pod install`, not kept in the repository.

## Rules for the library

- Core and CYLUtils get no library switch. A library's keys exist only with that library: its header defines `CYL_<LIBRARY>_AVAILABLE` (`__has_include`), and the header's content and the `.m` definitions sit inside it. The released Lottie keys stay defined and are marked `CYL_LOTTIE_REQUIRED`.
- A new library is one more folder, one more animator class and one more subspec, with no change anywhere else. The animator registers itself in `+load` with `CYLTabBarItemAnimatorRegistry`.
- Rive's Metal shader warnings in the console (`program_source ... Compilation succeeded`) come from the `RiveRuntime` binary. They are harmless and cannot be fixed here.
