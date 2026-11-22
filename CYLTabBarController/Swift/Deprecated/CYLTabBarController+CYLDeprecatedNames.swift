//
//  CYLTabBarController+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension CYLTabBarController {
    /**
     [EN] Deprecated: renamed to `cylTabBarController`.
     [CN] 已废弃：已改名为 `cylTabBarController`。
     */
    @available(*, deprecated, renamed: "cylTabBarController(forContext:)")
    @nonobjc
    public static func cyl_tabBarController(forContext context: String?) -> CYLTabBarController? { Self.cylTabBarController(forContext: context) }

    /**
     [EN] Deprecated: renamed to `cylActive`.
     [CN] 已废弃：已改名为 `cylActive`。
     */
    @available(*, deprecated, renamed: "cylActive()")
    @nonobjc
    public static func cyl_active() -> CYLTabBarController? { Self.cylActive() }

    /**
     [EN] Deprecated: renamed to `cylSimulateMemoryWarning`.
     [CN] 已废弃：已改名为 `cylSimulateMemoryWarning`。
     */
    @available(*, deprecated, renamed: "cylSimulateMemoryWarning()")
    @nonobjc
    public static func cyl_simulateMemoryWarning() { Self.cylSimulateMemoryWarning() }

    /**
     [EN] Deprecated: renamed to `cylSimulateMemoryWarning`.
     [CN] 已废弃：已改名为 `cylSimulateMemoryWarning`。
     */
    @available(*, deprecated, renamed: "cylSimulateMemoryWarning(for:)")
    @nonobjc
    public static func cyl_simulateMemoryWarning(for tabBarController: CYLTabBarController?) { Self.cylSimulateMemoryWarning(for: tabBarController) }
}
