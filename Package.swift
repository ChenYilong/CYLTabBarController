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
        .target(name: "CYLTabBarController", path: "CYLTabBarController")
    ],
    swiftLanguageVersions: [.v5]
)
