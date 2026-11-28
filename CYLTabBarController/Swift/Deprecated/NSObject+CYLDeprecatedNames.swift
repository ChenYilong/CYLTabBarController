//
//  NSObject+CYLDeprecatedNames.swift
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

extension NSObject {
    /**
     [EN] Deprecated: renamed to `cylOwningTabBarController`.
     [CN] 已废弃：已改名为 `cylOwningTabBarController`。
     */
    @available(*, deprecated, renamed: "cylOwningTabBarController()")
    @nonobjc
    public func cyl_owningTabBarController() -> CYLTabBarController? { cylOwningTabBarController() }

    /**
     [EN] Deprecated: renamed to `cylTabBarController`.
     [CN] 已废弃：已改名为 `cylTabBarController`。
     */
    @available(*, deprecated, renamed: "cylTabBarController(forStyleType:)")
    @nonobjc
    public func cyl_tabBarController(forStyleType styleType: CYLTabBarStyleType) -> CYLTabBarController? { cylTabBarController(forStyleType: styleType) }

    /**
     [EN] Deprecated: renamed to `cylTabBarController`.
     [CN] 已废弃：已改名为 `cylTabBarController`。
     */
    @available(*, deprecated, renamed: "cylTabBarController")
    @nonobjc
    public var cyl_tabBarController: CYLTabBarController? {
        get { cylTabBarController }
        set { cylTabBarController = newValue }
    }

    /**
     [EN] Deprecated: renamed to `cylSharedAppDelegate`.
     [CN] 已废弃：已改名为 `cylSharedAppDelegate`。
     */
    @available(*, deprecated, renamed: "cylSharedAppDelegate()")
    @nonobjc
    public func cyl_sharedAppDelegate() -> (UIResponder & UIApplicationDelegate)! { cylSharedAppDelegate() }

    /**
     [EN] Deprecated: renamed to `cylForceUpdateInterfaceOrientation`.
     [CN] 已废弃：已改名为 `cylForceUpdateInterfaceOrientation`。
     */
    @available(*, deprecated, renamed: "cylForceUpdateInterfaceOrientation(_:)")
    @nonobjc
    public func cyl_forceUpdateInterfaceOrientation(_ orientation: UIInterfaceOrientation) { cylForceUpdateInterfaceOrientation(orientation) }

    /**
     [EN] Deprecated: renamed to `cylTopmostViewController`.
     [CN] 已废弃：已改名为 `cylTopmostViewController`。
     */
    @available(*, deprecated, renamed: "cylTopmostViewController()")
    @nonobjc
    public class func cyl_topmostViewController() -> UIViewController? { Self.cylTopmostViewController() }

    /**
     [EN] Deprecated: renamed to `cylCurrentNavigationController`.
     [CN] 已废弃：已改名为 `cylCurrentNavigationController`。
     */
    @available(*, deprecated, renamed: "cylCurrentNavigationController()")
    @nonobjc
    public class func cyl_currentNavigationController() -> UINavigationController? { Self.cylCurrentNavigationController() }

    /**
     [EN] Deprecated: renamed to `cylDismissAll`.
     [CN] 已废弃：已改名为 `cylDismissAll`。
     */
    @available(*, deprecated, renamed: "cylDismissAll(_:)")
    @nonobjc
    public class func cyl_dismissAll(_ completion: (() -> Void)?) { Self.cylDismissAll(completion) }

    /**
     [EN] Deprecated: renamed to `cylIvarList`.
     [CN] 已废弃：已改名为 `cylIvarList`。
     */
    @available(*, deprecated, renamed: "cylIvarList()")
    @nonobjc
    public func cyl_ivarList() -> String { cylIvarList() }

    /**
     [EN] Deprecated: renamed to `cylIsContinuousGestureRecognizer`.
     [CN] 已废弃：已改名为 `cylIsContinuousGestureRecognizer`。
     */
    @available(*, deprecated, renamed: "cylIsContinuousGestureRecognizer()")
    @nonobjc
    public func cyl_isContinuousGestureRecognizer() -> Bool { cylIsContinuousGestureRecognizer() }

    /**
     [EN] Deprecated: renamed to `cylIsLongGestureRecognizer`.
     [CN] 已废弃：已改名为 `cylIsLongGestureRecognizer`。
     */
    @available(*, deprecated, renamed: "cylIsLongGestureRecognizer()")
    @nonobjc
    public func cyl_isLongGestureRecognizer() -> Bool { cylIsLongGestureRecognizer() }

    /**
     [EN] Deprecated: renamed to `cylIsPlusViewControllerAdded`.
     [CN] 已废弃：已改名为 `cylIsPlusViewControllerAdded`。
     */
    @available(*, deprecated, renamed: "cylIsPlusViewControllerAdded(_:)")
    @nonobjc
    public func cyl_isPlusViewControllerAdded(_ viewControllers: [Any]?) -> Bool { cylIsPlusViewControllerAdded(viewControllers) }
}
