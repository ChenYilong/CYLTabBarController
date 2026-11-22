//
//  NSObject+CYLUtilsDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ObjectiveC

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension NSObject {
    /**
     [EN] Deprecated: renamed to `cylValue`.
     [CN] 已废弃：已改名为 `cylValue`。
     */
    @available(*, deprecated, renamed: "cylValue(forKey:)")
    @nonobjc
    public func cyl_value(forKey key: String) -> Any? { cylValue(forKey: key) }

    /**
     [EN] Deprecated: renamed to `cylSetValue`.
     [CN] 已废弃：已改名为 `cylSetValue`。
     */
    @available(*, deprecated, renamed: "cylSetValue(_:forKey:)")
    @nonobjc
    public func cyl_setValue(_ value: Any?, forKey key: String) { cylSetValue(value, forKey: key) }

    /**
     [EN] Deprecated: renamed to `cylSetWeakAssociatedObject`.
     [CN] 已废弃：已改名为 `cylSetWeakAssociatedObject`。
     */
    @available(*, deprecated, renamed: "cylSetWeakAssociatedObject(_:forKey:)")
    @nonobjc
    public func cyl_setWeakAssociatedObject(_ object: Any?, forKey key: UnsafeRawPointer) { cylSetWeakAssociatedObject(object, forKey: key) }

    /**
     [EN] Deprecated: renamed to `cylWeakAssociatedObject`.
     [CN] 已废弃：已改名为 `cylWeakAssociatedObject`。
     */
    @available(*, deprecated, renamed: "cylWeakAssociatedObject(forKey:)")
    @nonobjc
    public func cyl_weakAssociatedObject(forKey key: UnsafeRawPointer) -> Any? { cylWeakAssociatedObject(forKey: key) }
}
