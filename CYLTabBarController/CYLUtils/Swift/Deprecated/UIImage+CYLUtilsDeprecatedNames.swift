//
//  UIImage+CYLUtilsDeprecatedNames.swift
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

extension UIImage {
    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(themeProvider:)")
    @nonobjc
    public class func cyl_image(themeProvider provider: @escaping CYLThemeImageProvider) -> UIImage { Self.cylImage(themeProvider: provider) }

    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(withName:themeProvider:)")
    @nonobjc
    public class func cyl_image(withName name: String?, themeProvider provider: @escaping CYLThemeImageProvider) -> UIImage { Self.cylImage(withName: name, themeProvider: provider) }

    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(withThemeManagerName:provider:)")
    @nonobjc
    public class func cyl_image(withThemeManagerName managerName: (NSCopying & NSObjectProtocol)?, provider: @escaping CYLThemeImageProvider) -> UIImage { Self.cylImage(withThemeManagerName: managerName, provider: provider) }

    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(withName:themeManagerName:provider:)")
    @nonobjc
    public class func cyl_image(withName name: String?, themeManagerName managerName: (NSCopying & NSObjectProtocol)?, provider: @escaping CYLThemeImageProvider) -> UIImage { Self.cylImage(withName: name, themeManagerName: managerName, provider: provider) }
}
