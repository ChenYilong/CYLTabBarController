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
    ],
    dependencies: [
        // Same requirement as the podspec's `LottieSwift` subspec: 'lottie-ios', '>= 4.5.1' (`removeValueProvider(for:)`).
        // lottie-spm is Airbnb's official SPM distribution of lottie-ios.
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.1"),
        // [EN] Lifecycle and dealloc blocks (docs/Lifecycle-Library.md). Pending: `from: "1.4.0"` once it is tagged.
        // [CN] 生命周期与 dealloc block（docs/Lifecycle-Library.md）。待办：打 tag 后改为 `from: "1.4.0"`。
        .package(url: "https://github.com/ChenYilong/CYLDeallocBlockExecutor.git", revision: "43f94adfc31f7f7620f5b07bf03dd15a57f44f45"),
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
                "CYLTabBarControllerLottieSwift",
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "CYLDeallocBlockExecutor", package: "CYLDeallocBlockExecutor"),
            ],
            path: "CYLTabBarController",
            exclude: ["CYLUtils/Swift/CYLAnimationURLOptions.swift", "CYLUtils/Swift/CYLAnimationKeyLookup.swift", "Package"],
            sources: ["CYLUtils/Swift", "CYLBadgeView/Swift", "Swift", "CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/Swift"],
            resources: [.copy("Resources/CYLTabBarController.bundle")],
            // [EN] SwiftPM always builds the engine: Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`) is in.
            // [CN] SwiftPM 总是编译引擎：Core 中只在有引擎时编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`）参与编译。
            swiftSettings: [.define("CYL_ANIMATION_ENGINE_AVAILABLE")]
        ),
        .target(
            name: "CYLTabBarControllerEngine",
            dependencies: ["CYLTabBarController", "CYLTabBarControllerObjC", "CYLAnimatedItem", "CYLAnimatedItemSwift", "CYLTabBarControllerLottieSwift"],
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
