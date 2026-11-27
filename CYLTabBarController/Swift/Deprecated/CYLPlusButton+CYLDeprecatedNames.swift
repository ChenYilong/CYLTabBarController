//
//  CYLPlusButton+CYLDeprecatedNames.swift
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
import ObjectiveC

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

/**
 [EN] Deprecated: renamed to `cylExternPlusButton`.
 [CN] 已废弃：已改名为 `cylExternPlusButton`。
 */
@available(*, deprecated, renamed: "cylExternPlusButton")
public var CYLExternPlusButton: (CYLPlusButton & CYLPlusButtonSubclassing)! {
    get { cylExternPlusButton }
    set { cylExternPlusButton = newValue }
}

/**
 [EN] Deprecated: renamed to `cylPlusChildViewController`.
 [CN] 已废弃：已改名为 `cylPlusChildViewController`。
 */
@available(*, deprecated, renamed: "cylPlusChildViewController")
public var CYLPlusChildViewController: UIViewController! {
    get { cylPlusChildViewController }
    set { cylPlusChildViewController = newValue }
}

/**
 [EN] Deprecated: renamed to `cylPlusButtonWidthValue`.
 [CN] 已废弃：已改名为 `cylPlusButtonWidthValue`。
 */
@available(*, deprecated, renamed: "cylPlusButtonWidthValue")
public var CYLPlusButtonWidth: CGFloat {
    get { cylPlusButtonWidthValue }
    set { cylPlusButtonWidthValue = newValue }
}

/**
 [EN] Deprecated: renamed to `cylPlusButtonCurrentExternPlusButton`.
 [CN] 已废弃：已改名为 `cylPlusButtonCurrentExternPlusButton`。
 */
@available(*, deprecated, renamed: "cylPlusButtonCurrentExternPlusButton()")
public func CYLPlusButtonCurrentExternPlusButton() -> CYLPlusButton? { cylPlusButtonCurrentExternPlusButton() }

/**
 [EN] Deprecated: renamed to `cylPlusButtonCurrentPlusChildViewController`.
 [CN] 已废弃：已改名为 `cylPlusButtonCurrentPlusChildViewController`。
 */
@available(*, deprecated, renamed: "cylPlusButtonCurrentPlusChildViewController()")
public func CYLPlusButtonCurrentPlusChildViewController() -> UIViewController? { cylPlusButtonCurrentPlusChildViewController() }

/**
 [EN] Deprecated: renamed to `cylPlusButtonCurrentWidth`.
 [CN] 已废弃：已改名为 `cylPlusButtonCurrentWidth`。
 */
@available(*, deprecated, renamed: "cylPlusButtonCurrentWidth()")
public func CYLPlusButtonCurrentWidth() -> CGFloat { cylPlusButtonCurrentWidth() }
