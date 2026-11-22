//
//  NSNotificationName+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension NSNotification.Name {
    /**
     [EN] Deprecated: renamed to `cylTabBarLoginStateDidChange`.
     [CN] 已废弃：已改名为 `cylTabBarLoginStateDidChange`。
     */
    @available(*, deprecated, renamed: "cylTabBarLoginStateDidChange")
    public static let CYLTabBarLoginStateDidChange = Self.cylTabBarLoginStateDidChange

    /**
     [EN] Deprecated: renamed to `cylTabBarItemAnimationPlaying`.
     [CN] 已废弃：已改名为 `cylTabBarItemAnimationPlaying`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemAnimationPlaying")
    public static let CYLTabBarItemAnimationPlaying = Self.cylTabBarItemAnimationPlaying

    /**
     [EN] Deprecated: renamed to `cylTabBarItemAnimationViewDidAdd`.
     [CN] 已废弃：已改名为 `cylTabBarItemAnimationViewDidAdd`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemAnimationViewDidAdd")
    public static let CYLTabBarItemAnimationViewDidAdd = Self.cylTabBarItemAnimationViewDidAdd

    /**
     [EN] Deprecated: renamed to `cylTabBarItemTitleDidChange`.
     [CN] 已废弃：已改名为 `cylTabBarItemTitleDidChange`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemTitleDidChange")
    public static let CYLTabBarItemTitleDidChange = Self.cylTabBarItemTitleDidChange

    /**
     [EN] Deprecated: renamed to `cylTabBarItemDidChange`.
     [CN] 已废弃：已改名为 `cylTabBarItemDidChange`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemDidChange")
    public static let CYLTabBarItemDidChange = Self.cylTabBarItemDidChange

    /**
     [EN] Deprecated: renamed to `cylTabBarItemIconDidChange`.
     [CN] 已废弃：已改名为 `cylTabBarItemIconDidChange`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemIconDidChange")
    public static let CYLTabBarItemIconDidChange = Self.cylTabBarItemIconDidChange

    /**
     [EN] Deprecated: renamed to `cylTabBarControllerThemeDidApply`.
     [CN] 已废弃：已改名为 `cylTabBarControllerThemeDidApply`。
     */
    @available(*, deprecated, renamed: "cylTabBarControllerThemeDidApply")
    public static let CYLTabBarControllerThemeDidApply = Self.cylTabBarControllerThemeDidApply
}
