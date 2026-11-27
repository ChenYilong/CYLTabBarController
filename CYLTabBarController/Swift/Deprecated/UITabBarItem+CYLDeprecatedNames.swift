//
//  UITabBarItem+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension UITabBarItem {
    /**
     [EN] Deprecated: renamed to `cylImageView`.
     [CN] 已废弃：已改名为 `cylImageView`。
     */
    @available(*, deprecated, renamed: "cylImageView()")
    @nonobjc
    public func cyl_imageView() -> UIImageView? { cylImageView() }

    /**
     [EN] Deprecated: renamed to `cylImageViewInTabBarButton`.
     [CN] 已废弃：已改名为 `cylImageViewInTabBarButton`。
     */
    @available(*, deprecated, renamed: "cylImageViewInTabBarButton()")
    @nonobjc
    public func cyl_imageViewInTabBarButton() -> UIImageView? { cylImageViewInTabBarButton() }
}
