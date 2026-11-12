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
        .library(name: "CYLTabBarController", targets: ["CYLTabBarController"])
    ],
    dependencies: [
        // Same requirement as the podspec's `LottieSwift` subspec: 'lottie-ios', '>= 4.5.1' (`removeValueProvider(for:)`).
        // lottie-spm is Airbnb's official SPM distribution of lottie-ios.
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.1"),
    ],
    targets: [
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
            path: "CYLTabBarController",
            sources: ["CYLUtils/Swift"],
            // [EN] The resource bundle belongs to the target that reads it (`CYLResourceBundle()`, now in Swift).
            // [CN] 资源包属于读取它的 target（`CYLResourceBundle()`，现在用 Swift 实现）。
            resources: [.copy("Resources/CYLTabBarController.bundle")]
        ),
        .target(
            name: "CYLTabBarController",
            dependencies: [
                "CYLTabBarControllerSwift",
                "CYLTabBarControllerLottieSwift",
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "CYLTabBarController",
            // [EN] `RiveSwift`: the Swift bridge of the CocoaPods `Rive` subspec. SPM does not offer RiveRuntime here, and
            //      this target cannot hold Swift, so it is left out; `CYLTabBarItemAnimation/Rive/` is then empty, like `PAG/`.
            // [CN] `RiveSwift`：CocoaPods `Rive` 子库的 Swift 桥接。这里的 SPM 不提供 RiveRuntime，且本 target 不能包含 Swift，因此排除它；
            //      `CYLTabBarItemAnimation/Rive/` 随之为空，与 `PAG/` 相同。
            exclude: ["LottieSwift", "RiveSwift", "CYLUtils/Swift", "Resources/CYLTabBarController.bundle"],
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
