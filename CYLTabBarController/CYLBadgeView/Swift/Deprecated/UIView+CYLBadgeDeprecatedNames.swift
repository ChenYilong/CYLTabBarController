//
//  UIView+CYLBadgeDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension UIView {
    /**
     [EN] Deprecated: renamed to `cylShowBadgeValue`.
     [CN] 已废弃：已改名为 `cylShowBadgeValue`。
     */
    @available(*, deprecated, renamed: "cylShowBadgeValue(_:)")
    @nonobjc
    public func cyl_showBadgeValue(_ value: String) { cylShowBadgeValue(value) }

    /**
     [EN] Deprecated: renamed to `cylShowBadge`.
     [CN] 已废弃：已改名为 `cylShowBadge`。
     */
    @available(*, deprecated, renamed: "cylShowBadge(withValue:)")
    @nonobjc
    public func cyl_showBadge(withValue value: String?) { cylShowBadge(withValue: value) }

    /**
     [EN] Deprecated: renamed to `cylMoveBadge`.
     [CN] 已废弃：已改名为 `cylMoveBadge`。
     */
    @available(*, deprecated, renamed: "cylMoveBadge(to:)")
    @nonobjc
    public func cyl_moveBadge(to newHost: UIView) { cylMoveBadge(to: newHost) }

    /**
     [EN] Deprecated: renamed to `cylAnimatedItemBadgeHost`.
     [CN] 已废弃：已改名为 `cylAnimatedItemBadgeHost`。
     */
    @available(*, deprecated, renamed: "cylAnimatedItemBadgeHost()")
    @nonobjc
    public func cyl_animatedItemBadgeHost() -> UIView? { cylAnimatedItemBadgeHost() }

    /**
     [EN] Deprecated: renamed to `cylRefreshBadge`.
     [CN] 已废弃：已改名为 `cylRefreshBadge`。
     */
    @available(*, deprecated, renamed: "cylRefreshBadge()")
    @nonobjc
    public func cyl_refreshBadge() { cylRefreshBadge() }

    /**
     [EN] Deprecated: renamed to `cylResetBadgeAppearance`.
     [CN] 已废弃：已改名为 `cylResetBadgeAppearance`。
     */
    @available(*, deprecated, renamed: "cylResetBadgeAppearance()")
    @nonobjc
    public func cyl_resetBadgeAppearance() { cylResetBadgeAppearance() }

    /**
     [EN] Deprecated: renamed to `cylIsHidden`.
     [CN] 已废弃：已改名为 `cylIsHidden`。
     */
    @available(*, deprecated, renamed: "cylIsHidden()")
    @nonobjc
    public func cyl_isHidden() -> Bool { cylIsHidden() }

    /**
     [EN] Deprecated: renamed to `cylFindBarButtonContentView`.
     [CN] 已废弃：已改名为 `cylFindBarButtonContentView`。
     */
    @available(*, deprecated, renamed: "cylFindBarButtonContentView()")
    @nonobjc
    public func cyl_findBarButtonContentView() -> UIView { cylFindBarButtonContentView() }
}
