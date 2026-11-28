//
//  UIView+CYLUtilsDeprecatedNames.swift
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

extension UIView {
    /**
     [EN] Deprecated: renamed to `cylRegisterThemeColorProperties`.
     [CN] 已废弃：已改名为 `cylRegisterThemeColorProperties`。
     */
    @available(*, deprecated, renamed: "cylRegisterThemeColorProperties(_:)")
    @nonobjc
    public func cyl_registerThemeColorProperties(_ getters: [String]) { cylRegisterThemeColorProperties(getters) }

    /**
     [EN] Deprecated: renamed to `cylUnregisterThemeColorProperties`.
     [CN] 已废弃：已改名为 `cylUnregisterThemeColorProperties`。
     */
    @available(*, deprecated, renamed: "cylUnregisterThemeColorProperties(_:)")
    @nonobjc
    public func cyl_unregisterThemeColorProperties(_ getters: [String]) { cylUnregisterThemeColorProperties(getters) }

    /**
     [EN] Deprecated: renamed to `cylApplyCurrentTheme`.
     [CN] 已废弃：已改名为 `cylApplyCurrentTheme`。
     */
    @available(*, deprecated, renamed: "cylApplyCurrentTheme()")
    @nonobjc
    public func cyl_applyCurrentTheme() { cylApplyCurrentTheme() }

    /**
     [EN] Deprecated: renamed to `cylSetHidden`.
     [CN] 已废弃：已改名为 `cylSetHidden`。
     */
    @available(*, deprecated, renamed: "cylSetHidden(_:)")
    @nonobjc
    public func cyl_setHidden(_ hidden: Bool) { cylSetHidden(hidden) }

    /**
     [EN] Deprecated: renamed to `cylIsInvisiable`.
     [CN] 已废弃：已改名为 `cylIsInvisiable`。
     */
    @available(*, deprecated, renamed: "cylIsInvisiable()")
    @nonobjc
    public func cyl_isInvisiable() -> Bool { cylIsInvisiable() }

    /**
     [EN] Deprecated: renamed to `cylCanNotResponseEvent`.
     [CN] 已废弃：已改名为 `cylCanNotResponseEvent`。
     */
    @available(*, deprecated, renamed: "cylCanNotResponseEvent()")
    @nonobjc
    public func cyl_canNotResponseEvent() -> Bool { cylCanNotResponseEvent() }

    /**
     [EN] Deprecated: renamed to `cylAddScaleBounceAnimation`.
     [CN] 已废弃：已改名为 `cylAddScaleBounceAnimation`。
     */
    @available(*, deprecated, renamed: "cylAddScaleBounceAnimation(completion:)")
    @nonobjc
    public func cyl_addScaleBounceAnimation(completion: ((Bool) -> Void)?) { cylAddScaleBounceAnimation(completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylNearestControl`.
     [CN] 已废弃：已改名为 `cylNearestControl`。
     */
    @available(*, deprecated, renamed: "cylNearestControl(below:)")
    @nonobjc
    public func cyl_nearestControl(below stopView: UIView?) -> UIControl? { cylNearestControl(below: stopView) }
}
