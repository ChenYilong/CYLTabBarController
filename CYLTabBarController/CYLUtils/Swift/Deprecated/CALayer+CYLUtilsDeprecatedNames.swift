//
//  CALayer+CYLUtilsDeprecatedNames.swift
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

extension CALayer {
    /**
     [EN] Deprecated: renamed to `cylSetThemeColor`.
     [CN] 已废弃：已改名为 `cylSetThemeColor`。
     */
    @available(*, deprecated, renamed: "cylSetThemeColor(_:forKey:)")
    @nonobjc
    public func cyl_setThemeColor(_ color: UIColor?, forKey key: String) { cylSetThemeColor(color, forKey: key) }

    /**
     [EN] Deprecated: renamed to `cylThemeColor`.
     [CN] 已废弃：已改名为 `cylThemeColor`。
     */
    @available(*, deprecated, renamed: "cylThemeColor(forKey:)")
    @nonobjc
    public func cyl_themeColor(forKey key: String) -> UIColor? { cylThemeColor(forKey: key) }

    /**
     [EN] Deprecated: renamed to `cylUpdateThemeColors`.
     [CN] 已废弃：已改名为 `cylUpdateThemeColors`。
     */
    @available(*, deprecated, renamed: "cylUpdateThemeColors()")
    @nonobjc
    public func cyl_updateThemeColors() { cylUpdateThemeColors() }
}
