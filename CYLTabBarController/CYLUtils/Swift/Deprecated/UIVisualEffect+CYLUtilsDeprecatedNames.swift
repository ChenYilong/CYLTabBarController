//
//  UIVisualEffect+CYLUtilsDeprecatedNames.swift
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

extension UIVisualEffect {
    /**
     [EN] Deprecated: renamed to `cylEffect`.
     [CN] 已废弃：已改名为 `cylEffect`。
     */
    @available(*, deprecated, renamed: "cylEffect(themeProvider:)")
    @nonobjc
    public class func cyl_effect(themeProvider provider: @escaping CYLThemeEffectProvider) -> UIVisualEffect { Self.cylEffect(themeProvider: provider) }

    /**
     [EN] Deprecated: renamed to `cylEffect`.
     [CN] 已废弃：已改名为 `cylEffect`。
     */
    @available(*, deprecated, renamed: "cylEffect(withThemeManagerName:provider:)")
    @nonobjc
    public class func cyl_effect(withThemeManagerName managerName: (NSCopying & NSObjectProtocol)?, provider: @escaping CYLThemeEffectProvider) -> UIVisualEffect { Self.cylEffect(withThemeManagerName: managerName, provider: provider) }
}
