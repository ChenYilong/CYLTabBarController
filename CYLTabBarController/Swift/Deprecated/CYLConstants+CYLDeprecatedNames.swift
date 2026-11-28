//
//  CYLConstants+CYLDeprecatedNames.swift
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

/**
 [EN] Deprecated: renamed to `cylTabBarItemImagePlaceholderWidth`.
 [CN] 已废弃：已改名为 `cylTabBarItemImagePlaceholderWidth`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImagePlaceholderWidth")
public var CYLTabBarItemImagePlaceholderWidth: CGFloat {
    get { cylTabBarItemImagePlaceholderWidth }
    set { cylTabBarItemImagePlaceholderWidth = newValue }
}

/**
 [EN] Deprecated: renamed to `cylTabBarItemImagePlaceholderHeight`.
 [CN] 已废弃：已改名为 `cylTabBarItemImagePlaceholderHeight`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImagePlaceholderHeight")
public var CYLTabBarItemImagePlaceholderHeight: CGFloat {
    get { cylTabBarItemImagePlaceholderHeight }
    set { cylTabBarItemImagePlaceholderHeight = newValue }
}

/**
 [EN] Deprecated: renamed to `cylTabBarItemImagePlaceholderCurrentWidth`.
 [CN] 已废弃：已改名为 `cylTabBarItemImagePlaceholderCurrentWidth`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImagePlaceholderCurrentWidth()")
public func CYLTabBarItemImagePlaceholderCurrentWidth() -> CGFloat { cylTabBarItemImagePlaceholderCurrentWidth() }

/**
 [EN] Deprecated: renamed to `cylTabBarItemImagePlaceholderCurrentHeight`.
 [CN] 已废弃：已改名为 `cylTabBarItemImagePlaceholderCurrentHeight`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImagePlaceholderCurrentHeight()")
public func CYLTabBarItemImagePlaceholderCurrentHeight() -> CGFloat { cylTabBarItemImagePlaceholderCurrentHeight() }

/**
 [EN] Deprecated: renamed to `cylConstantsUIBasisWidthScale`.
 [CN] 已废弃：已改名为 `cylConstantsUIBasisWidthScale`。
 */
@available(*, deprecated, renamed: "cylConstantsUIBasisWidthScale()")
public func CYLConstantsUIBasisWidthScale() -> CGFloat { cylConstantsUIBasisWidthScale() }

/**
 [EN] Deprecated: renamed to `cylConstantsUIBasisHeightScale`.
 [CN] 已废弃：已改名为 `cylConstantsUIBasisHeightScale`。
 */
@available(*, deprecated, renamed: "cylConstantsUIBasisHeightScale()")
public func CYLConstantsUIBasisHeightScale() -> CGFloat { cylConstantsUIBasisHeightScale() }
