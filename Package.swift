// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CYLTabBarController",
    platforms: [
        .iOS(.v8),
    ],
    products: [
        .library(name: "CYLTabBarController",  targets: ["CYLTabBarController"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CYLTabBarController",
            path: "CYLTabBarController",
            // Same as the CocoaPods `Core` subspec: FlatDesign relies on
            // `__has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)`, which is never
            // true under SPM, so its sources would not compile (issue #649).
            exclude: ["LottieSwift", "CYLFlatDesignTabBar"],
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("CYLBadge")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
