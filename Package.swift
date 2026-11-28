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
        .iOS(.v15),
    ],
    products: [
        .library(name: "CYLTabBarController", targets: ["CYLTabBarController", "CYLTabBarControllerEngine"]),
        // [EN] The animated item component on its own (CocoaPods `CYLAnimatedItem` pod, docs/Animated-Item.md): the view, its
        //      placeholder bundle and the animation engine, without the tab bar.
        // [CN] 单独的动效条目组件（CocoaPods `CYLAnimatedItem` pod，docs/Animated-Item.md）：视图、占位图资源包与动画引擎，不含 TabBar。
        .library(name: "CYLAnimatedItem", targets: ["CYLAnimatedItem", "CYLAnimatedItemViews"]),
        // [EN] The two layers below the component (docs/Animated-Item-Badge.md, step 9): CYLUtilsKit (macros' Swift side, themes, localization, the
        //      library bundle; the only target that depends on the lifecycle library, D8) and CYLBadge on top of it. TODO: the SwiftPM build fails on Xcode 27.2 with a module
        //      cycle, CYLAnimatedItem -> CYLTabBarControllerObjC -> CYLAnimatedItem (2026-11-29).
        // [CN] 组件之下的两层（docs/Animated-Item-Badge.md，第 9 步）：CYLUtilsKit（主题、本地化、库资源包；唯一依赖生命周期库的 target，D8）与其上的 CYLBadge。
        //      TODO：在 Xcode 27.2 上 SwiftPM 构建因模块循环失败（CYLAnimatedItem -> CYLTabBarControllerObjC -> CYLAnimatedItem，2026-11-29）。
        .library(name: "CYLUtilsKit", targets: ["CYLUtilsKit"]),
        .library(name: "CYLBadge", targets: ["CYLBadge"]),
    ],
    dependencies: [
        // Same requirement as the podspec's `LottieSwift` subspec: 'lottie-ios', '>= 4.5.1' (`removeValueProvider(for:)`).
        // lottie-spm is Airbnb's official SPM distribution of lottie-ios.
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.1"),
        // [EN] Lifecycle and dealloc blocks (docs/Lifecycle-Library.md). Pending: `from: "1.4.0"` once it is tagged.
        // [CN] 生命周期与 dealloc block（docs/Lifecycle-Library.md）。待办：打 tag 后改为 `from: "1.4.0"`。
        .package(url: "https://github.com/ChenYilong/CYLDeallocBlockExecutor.git", revision: "4276a6dab5a428ccc3a5f3f347eab991881fb97c"),
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
            // [EN] The module map is read from `publicHeadersPath`; as a source file it only warns "no rule to process file". [CN] module map 从 `publicHeadersPath` 读取；作为源文件只会产生 "no rule to process file" 警告。
            exclude: ["CYLAnimatedItem/Resources", "CYLAnimatedItem/Swift", "CYLAnimatedItem/include/module.modulemap"],
            sources: [
                "CYLAnimatedItem",
                "CYLUtils/CYLAnimationKeys.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayer.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimatorRegistry.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimationFactory.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimationTint.m",
                "CYLTabBarItemAnimation/CYLTabBarItemAnimationColorCount.m",
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
        // [EN] CYLUtilsKit, Swift half of the bottom layer: its Objective-C declarations (the theme typedefs, `CYLLocalizedString`) come through the
        //      C target `CYLTabBarControllerObjC`. It owns the library's resource bundle, so `Bundle.module` in its localization code is that bundle,
        //      and the lifecycle library (re-exported).
        // [CN] CYLUtilsKit，最底层的 Swift 部分：其 Objective-C 声明（主题 typedef、`CYLLocalizedString`）来自 C 目标 `CYLTabBarControllerObjC`。它拥有库的资源包，
        //      因此其本地化代码中的 `Bundle.module` 就是该资源包，并重新导出生命周期库。
        .target(
            name: "CYLUtilsKit",
            dependencies: [
                "CYLTabBarControllerObjC",
                .product(name: "CYLDeallocBlockExecutor", package: "CYLDeallocBlockExecutor"),
            ],
            path: "CYLTabBarController",
            exclude: ["CYLUtils/Swift/CYLAnimationURLOptions.swift", "CYLUtils/Swift/CYLAnimationKeyLookup.swift"],
            sources: ["CYLUtils/Swift"],
            resources: [.copy("Resources/CYLTabBarController.bundle")]
        ),
        // [EN] CYLBadge: the badge on top of CYLUtilsKit; it sees no tab bar and no animated item.
        // [CN] CYLBadge：位于 CYLUtilsKit 之上的角标；看不到 TabBar，也看不到动效 item。
        .target(
            name: "CYLBadge",
            dependencies: ["CYLUtilsKit", "CYLTabBarControllerObjC"],
            path: "CYLTabBarController",
            sources: ["CYLBadgeView/Swift"],
            resources: [.copy("CYLBadgeView/Resources/CYLBadge.bundle")]
        ),
        .target(
            name: "CYLAnimatedItemViews",
            dependencies: ["CYLAnimatedItem", "CYLBadge", "CYLUtilsKit"],
            path: "CYLTabBarController",
            // [EN] The views, plus the GIF view (the GIF animator, its Objective-C composition root, is in CYLTabBarControllerEngine).
            // [CN] 视图，以及 GIF 视图（GIF animator 这个 Objective-C 组合根位于 CYLTabBarControllerEngine）。
            sources: ["CYLAnimatedItem/Swift", "CYLTabBarItemAnimation/GIF/CYLGIFTabBarItemAnimationView.swift"],
            // [EN] SwiftPM always builds the engine (the CYLAnimatedItem target). [CN] SwiftPM 总是编译引擎（CYLAnimatedItem target）。
            swiftSettings: [.define("CYL_ANIMATION_ENGINE_AVAILABLE")]
        ),
        // Swift bridge that exposes Lottie 4.x to the Objective-C sources (`CYLCompatibleLOTAnimationView`), and the
        // Lottie 4.x player (`CYLLottieSwiftTabBarItemAnimationPlayer`, a subclass of the engine's base player).
        // SPM cannot mix Swift and Objective-C in one target, so it lives in its own target.
        .target(
            name: "CYLTabBarControllerLottieSwift",
            dependencies: [
                "CYLAnimatedItem",
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "CYLTabBarController/LottieSwift"
        ),
        // [EN] Swift migration (docs/Swift-Migration.md): SwiftPM cannot mix Swift and Objective-C in one target, so the
        //      translated files (the `Swift/` folders) are a lower target the Objective-C target depends on.
        // [CN] Swift 迁移（docs/Swift-Migration.md）：SwiftPM 不能在一个 target 中混用 Swift 与 Objective-C，因此已翻译的文件
        //      （各 `Swift/` 目录）组成一个更底层的 target，由 Objective-C target 依赖。
        // [EN] Phase 3 of the class switch (docs/Swift-Migration.md): CYLTabBarController is Swift, so there is one Swift target that holds it,
        //      above a small C target with the Objective-C declarations Swift imports (typedefs, option sets, constants, C globals), and
        //      below the C target with the animation engine, which calls Swift `@_cdecl` functions.
        // [CN] 类切换的第 3 阶段（docs/Swift-Migration.md）：CYLTabBarController 是 Swift 类，因此只有一个 Swift 目标承载它，其下是一个很小的 C
        //      目标（提供 Swift 导入的 Objective-C 声明：typedef、选项集、常量、C 全局变量），其上是动画引擎的 C 目标（它调用 Swift 的 `@_cdecl` 函数）。
        .target(
            name: "CYLTabBarControllerObjC",
            dependencies: ["CYLAnimatedItem", "CYLAnimatedItemSwift"],
            path: "CYLTabBarController",
            sources: ["CYLTabBarControllerGlobals.m", "NSObject+CYLTabBarControllerExtention.m"],
            publicHeadersPath: "Package/ObjC/include",
            cSettings: [
                .define("CYL_OBJC_BASE_TARGET"),
                .headerSearchPath("."),
                .headerSearchPath("CYLBadgeView"),
                .headerSearchPath("CYLUtils"),
                .headerSearchPath("CYLTabBarItemAnimation"),
                .headerSearchPath("CYLAnimatedItem"),
                .headerSearchPath("CYLUtils/CYLComponents/CYLTheme"),
                .headerSearchPath("CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/CYLFlatDesignTabBar"),
                .headerSearchPath("CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/CYLFlatDesignTabBarPrivate"),
            ]
        ),
        .target(
            name: "CYLTabBarController",
            dependencies: [
                "CYLTabBarControllerObjC",
                "CYLAnimatedItem",
                "CYLAnimatedItemSwift",
                "CYLAnimatedItemViews",
                "CYLBadge",
                "CYLUtilsKit",
                "CYLTabBarControllerLottieSwift",
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "CYLTabBarController",
            exclude: ["Package"],
            // [EN] The CYLUtils and CYLBadgeView Swift folders are the CYLUtilsKit and CYLBadge targets now; the resource bundle went with CYLUtilsKit; the lifecycle
            //      library comes through it (D8). [CN] CYLUtils 与 CYLBadgeView 的 Swift 目录现在是 CYLUtilsKit 与 CYLBadge 两个 target；资源包随 CYLUtilsKit 走；生命周期库经由它得到（D8）。
            sources: ["Swift", "CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/Swift"],
            // [EN] SwiftPM always builds the engine: Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`) is in.
            // [CN] SwiftPM 总是编译引擎：Core 中只在有引擎时编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`）参与编译。
            swiftSettings: [.define("CYL_ANIMATION_ENGINE_AVAILABLE")]
        ),
        .target(
            name: "CYLTabBarControllerEngine",
            dependencies: ["CYLTabBarController", "CYLTabBarControllerObjC", "CYLAnimatedItem", "CYLAnimatedItemSwift", "CYLBadge", "CYLUtilsKit", "CYLTabBarControllerLottieSwift"],
            path: "CYLTabBarController",
            sources: [
                "CYLTabBarItemAnimation/CYLTabBarItemAnimationEngine.m",
                "CYLTabBarItemAnimation/GIF/CYLGIFTabBarItemAnimator.m",
                "CYLTabBarItemAnimation/Lottie/CYLLottieTabBarItemAnimator.m",
                "CYLTabBarItemAnimation/PAG/CYLPAGTabBarItemAnimator.m",
                "CYLTabBarItemAnimation/Rive/CYLRiveTabBarItemAnimator.m",
                "CYLTabBarItemAnimation/SVGA/CYLSVGATabBarItemAnimator.m",
            ],
            publicHeadersPath: "Package/Engine/include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("CYLUtils"),
                // [EN] The Core interface header imports `CYLBadgeSwiftInterface.h` from here (docs/Animated-Item-Badge.md, step 3). [CN] Core 的接口头文件从这里导入 `CYLBadgeSwiftInterface.h`（docs/Animated-Item-Badge.md，第 3 步）。
                .headerSearchPath("CYLBadgeView"),
                .headerSearchPath("CYLTabBarItemAnimation"),
                .headerSearchPath("CYLAnimatedItem"),
                .headerSearchPath("CYLTabBarItemAnimation/GIF"),
                .headerSearchPath("CYLTabBarItemAnimation/Lottie"),
                .headerSearchPath("CYLTabBarItemAnimation/PAG"),
                .headerSearchPath("CYLTabBarItemAnimation/Rive"),
                .headerSearchPath("CYLTabBarItemAnimation/SVGA"),
            ],
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
