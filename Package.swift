// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// SPM mirrors the CocoaPods `CYLFlatDesignTabBar` subspec: Core + FlatDesign + LottieSwift.
// SPM cannot share one set of sources between several products, so there is no Core-only variant.
let package = Package(
    name: "CYLTabBarController",
    // The resource bundle (localized strings, see `CYLResourceBundle()`) is `CYLTabBarController/Resources/CYLTabBarController.bundle`.
    defaultLocalization: "en",
    platforms: [
        // lottie-ios 4.x requires iOS 13.
        .iOS(.v13),
    ],
    products: [
        .library(name: "CYLTabBarController", targets: ["CYLTabBarController"]),
        // [EN] The animated item component on its own (CocoaPods `CYLAnimatedItem` pod, docs/Animated-Item.md): the view, its
        //      placeholder bundle and the animation engine, without the tab bar.
        // [CN] 单独的动效条目组件（CocoaPods `CYLAnimatedItem` pod，docs/Animated-Item.md）：视图、占位图资源包与动画引擎，不含 TabBar。
        .library(name: "CYLAnimatedItem", targets: ["CYLAnimatedItem", "CYLAnimatedItemViews"]),
    ],
    dependencies: [
        // Same requirement as the podspec's `LottieSwift` subspec: 'lottie-ios', '>= 4.5.1' (`removeValueProvider(for:)`).
        // lottie-spm is Airbnb's official SPM distribution of lottie-ios.
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.1"),
    ],
    targets: [
        // [EN] CYLAnimatedItem, Swift half: the animation URL options and the engine's Swift protocols, plus the component's
        //      resource bundle. SwiftPM cannot mix Swift and Objective-C in one target, so the component is two targets.
        // [CN] CYLAnimatedItem 的 Swift 部分：动画 URL 选项与引擎的 Swift 协议，以及组件的资源包。SwiftPM 不能在一个 target 中混用 Swift 与
        //      Objective-C，因此组件分为两个 target。
        .target(
            name: "CYLAnimatedItemSwift",
            path: "CYLTabBarController",
            sources: ["CYLUtils/Swift/CYLAnimationURLOptions.swift", "CYLUtils/Swift/CYLAnimationKeyLookup.swift", "CYLTabBarItemAnimation/Swift"],
            resources: [.copy("CYLAnimatedItem/Resources/CYLAnimatedItem.bundle")]
        ),
        // [EN] CYLAnimatedItem, Objective-C half: CYLAnimatedItemView, the animation keys and the engine (the CocoaPods
        //      `CYLAnimatedItem/Core` and `CYLAnimatedItem/Engine` subspecs). It never depends on the tab bar.
        // [CN] CYLAnimatedItem 的 Objective-C 部分：CYLAnimatedItemView、动画 key 与引擎（CocoaPods 的 `CYLAnimatedItem/Core` 与
        //      `CYLAnimatedItem/Engine` 子库）。它从不依赖 TabBar。
        .target(
            name: "CYLAnimatedItem",
            dependencies: ["CYLAnimatedItemSwift"],
            path: "CYLTabBarController",
            exclude: ["CYLAnimatedItem/Resources", "CYLAnimatedItem/Swift"],
            sources: [
                "CYLAnimatedItem",
                "CYLUtils/CYLAnimationKeys.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayer.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimatorRegistry.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimationFactory.m",
                "CYLTabBarItemAnimation/CYLTabBarItemViewAnimator.m",
            ],
            publicHeadersPath: "CYLAnimatedItem/include",
            cSettings: [
                .headerSearchPath("CYLAnimatedItem"),
                .headerSearchPath("CYLUtils"),
                .headerSearchPath("CYLTabBarItemAnimation"),
            ]
        ),
        // [EN] CYLAnimatedItem, Swift views: CYLAnimatedItemView and CYLAnimatedItemStackView (Swift since step 60), above the
        //      Objective-C half (the engine), which they re-export; SwiftPM users `import CYLAnimatedItemViews` (CocoaPods and
        //      the Xcode framework compile them into `CYLAnimatedItem`).
        // [CN] CYLAnimatedItem 的 Swift 视图：CYLAnimatedItemView 与 CYLAnimatedItemStackView（自第 60 步起为 Swift），位于 Objective-C 部分（引擎）
        //      之上并重新导出它；SwiftPM 用户需 `import CYLAnimatedItemViews`（CocoaPods 与 Xcode framework 把它们编进 `CYLAnimatedItem`）。
        .target(
            name: "CYLAnimatedItemViews",
            dependencies: ["CYLAnimatedItem"],
            path: "CYLTabBarController/CYLAnimatedItem/Swift",
            // [EN] SwiftPM always builds the engine (the CYLAnimatedItem target). [CN] SwiftPM 总是编译引擎（CYLAnimatedItem target）。
            swiftSettings: [.define("CYL_ANIMATION_ENGINE_AVAILABLE")]
        ),
        // Swift bridge that exposes Lottie 4.x to the Objective-C sources (`CYLCompatibleLOTAnimationView`).
        // SPM cannot mix Swift and Objective-C in one target, so it lives in its own target.
        .target(
            name: "CYLTabBarControllerLottieSwift",
            dependencies: [
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "CYLTabBarController/LottieSwift"
        ),
        // [EN] Swift migration (docs/Swift-Migration.md): SwiftPM cannot mix Swift and Objective-C in one target, so the
        //      translated files (the `Swift/` folders) are a lower target the Objective-C target depends on.
        // [CN] Swift 迁移（docs/Swift-Migration.md）：SwiftPM 不能在一个 target 中混用 Swift 与 Objective-C，因此已翻译的文件
        //      （各 `Swift/` 目录）组成一个更底层的 target，由 Objective-C target 依赖。
        .target(
            name: "CYLTabBarControllerSwift",
            dependencies: ["CYLAnimatedItem", "CYLAnimatedItemSwift", "CYLAnimatedItemViews"],
            path: "CYLTabBarController",
            exclude: ["CYLUtils/Swift/CYLAnimationURLOptions.swift", "CYLUtils/Swift/CYLAnimationKeyLookup.swift"],
            sources: ["CYLUtils/Swift", "CYLBadgeView/Swift", "Swift", "CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/Swift"],
            // [EN] The resource bundle belongs to the target that reads it (`CYLResourceBundle()`, now in Swift).
            // [CN] 资源包属于读取它的 target（`CYLResourceBundle()`，现在用 Swift 实现）。
            resources: [.copy("Resources/CYLTabBarController.bundle")]
        ),
        .target(
            name: "CYLTabBarController",
            dependencies: [
                "CYLTabBarControllerSwift",
                "CYLAnimatedItem",
                "CYLTabBarControllerLottieSwift",
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "CYLTabBarController",
            // [EN] `RiveSwift`: the Swift bridge of the CocoaPods `Rive` subspec. SPM does not offer RiveRuntime here, and
            //      this target cannot hold Swift, so it is left out; `CYLTabBarItemAnimation/Rive/` is then empty, like `PAG/`.
            // [CN] `RiveSwift`：CocoaPods `Rive` 子库的 Swift 桥接。这里的 SPM 不提供 RiveRuntime，且本 target 不能包含 Swift，因此排除它；
            //      `CYLTabBarItemAnimation/Rive/` 随之为空，与 `PAG/` 相同。
            // [EN] The component's sources are the CYLAnimatedItem targets above. [CN] 组件的源码属于上面的 CYLAnimatedItem target。
            exclude: ["LottieSwift", "RiveSwift", "CYLUtils/Swift", "CYLBadgeView/Swift", "Swift", "CYLTabBarItemAnimation/Swift", "CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/Swift", "Resources/CYLTabBarController.bundle",
                      "CYLAnimatedItem", "CYLUtils/CYLAnimationKeys.m", "CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayer.m",
                      "CYLTabBarItemAnimation/CYLTabBarItemAnimatorRegistry.m", "CYLTabBarItemAnimation/CYLTabBarItemAnimationFactory.m",
                      "CYLTabBarItemAnimation/CYLTabBarItemViewAnimator.m"],
            // `include/` holds the module map plus `CYLTabBarController/*.h` shims, so the
            // CocoaPods-style `<CYLTabBarController/...>` imports and `__has_include` checks
            // (which enable FlatDesign and Lottie code) also resolve under SPM.
            cSettings: [
                .headerSearchPath("."),
                // FIX: issue #535 — the CYLBadgeView sources (the CocoaPods `CYLBadgeView` subspec), built as part of this target
                // because they use Core when it is there; CocoaPods offers them on their own.
                .headerSearchPath("CYLBadgeView"),
                // FIX: issue #535 — the CYLUtils sources (CocoaPods `CYLUtils` subspec), shared by Core and CYLBadgeView.
                .headerSearchPath("CYLUtils"),
                // FIX: issue #604 — the CYLTabBarItemAnimation sources (CocoaPods `CYLTabBarItemAnimation` subspec, with Lottie):
                // the shared engine, the animator protocol and registry, and one folder per library (`Lottie/`, and `PAG/` and
                // `Rive/`, which are empty without libpag and RiveRuntime; SPM does not offer them).
                // `GIF/` needs only ImageIO, so SPM builds it. `GIF/` 只需要 ImageIO，因此 SPM 会编译它。
                // [CN] 共用引擎、animator 协议与注册表，以及每个动画库一个目录（`Lottie/`；`PAG/` 与 `Rive/` 在没有 libpag、RiveRuntime 时为空，
                // SPM 不提供它们）。
                .headerSearchPath("CYLTabBarItemAnimation"),
                // [EN] CYLAnimatedItem (CocoaPods `CYLAnimatedItem` subspec): CYLAnimatedItemView, built on the engine above.
                // [CN] CYLAnimatedItem（CocoaPods `CYLAnimatedItem` 子库）：基于上述引擎的 CYLAnimatedItemView。
                .headerSearchPath("CYLAnimatedItem"),
                // [EN] The animator headers, so that CYLAnimatedItemMacros.h finds them for CYL_GIF_AVAILABLE, CYL_PAG_AVAILABLE,
                //      CYL_RIVE_AVAILABLE and CYL_SVGA_AVAILABLE (each still needs its library).
                // [CN] animator 头文件，使 CYLAnimatedItemMacros.h 能为 CYL_GIF_AVAILABLE 等开关找到它们（各自仍需其动画库）。
                .headerSearchPath("CYLTabBarItemAnimation/GIF"),
                .headerSearchPath("CYLTabBarItemAnimation/Lottie"),
                .headerSearchPath("CYLTabBarItemAnimation/PAG"),
                .headerSearchPath("CYLTabBarItemAnimation/Rive"),
                .headerSearchPath("CYLTabBarItemAnimation/SVGA"),
                // FIX: issue #216 — theme switching (skins), in CYLUtils/CYLComponents/CYLTheme.
                .headerSearchPath("CYLUtils/CYLComponents/CYLTheme"),
                .headerSearchPath("CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/CYLFlatDesignTabBar"),
                .headerSearchPath("CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/CYLFlatDesignTabBarPrivate"),
            ],
            // FIX: issue #535 — the tab tap sound.
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
