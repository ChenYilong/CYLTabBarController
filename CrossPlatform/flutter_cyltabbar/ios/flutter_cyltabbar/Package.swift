// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_cyltabbar",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "flutter-cyltabbar", targets: ["flutter_cyltabbar"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // [EN] This repository's CYLTabBarController (its Package.swift), so a library change shows up without publishing.
        // [CN] 本仓库的 CYLTabBarController（其 Package.swift），库的改动无需发布即可生效。
        .package(name: "CYLTabBarController", path: "../../../.."),
    ],
    targets: [
        .target(
            name: "flutter_cyltabbar",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "CYLTabBarController", package: "CYLTabBarController"),
            ],
            cSettings: [
                .headerSearchPath("include/flutter_cyltabbar")
            ]
        )
    ]
)
