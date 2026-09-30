// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// SPM mirrors the CocoaPods `CYLFlatDesignTabBar` subspec: Core + FlatDesign + LottieSwift.
// SPM cannot share one set of sources between several products, so there is no Core-only variant.
let package = Package(
    name: "CYLTabBarController",
    platforms: [
        // lottie-ios 4.x requires iOS 13.
        .iOS(.v13),
    ],
    products: [
        .library(name: "CYLTabBarController", targets: ["CYLTabBarController"])
    ],
    dependencies: [
        // Same requirement as the podspec's `LottieSwift` subspec: 'lottie-ios', '>= 4.0.0'.
        // lottie-spm is Airbnb's official SPM distribution of lottie-ios.
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.0.0"),
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
        .target(
            name: "CYLTabBarController",
            dependencies: [
                "CYLTabBarControllerLottieSwift",
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "CYLTabBarController",
            exclude: ["LottieSwift"],
            // `include/` holds the module map plus `CYLTabBarController/*.h` shims, so the
            // CocoaPods-style `<CYLTabBarController/...>` imports and `__has_include` checks
            // (which enable FlatDesign and Lottie code) also resolve under SPM.
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("CYLBadge"),
                .headerSearchPath("CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/CYLFlatDesignTabBar"),
                .headerSearchPath("CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/CYLFlatDesignTabBarPrivate"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
