//
//  CYLTabBarPageRegistry+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import MachO
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

/**
 [EN] Deprecated: renamed to `cylTabBarPageSourceInstanceRegistry`.
 [CN] 已废弃：已改名为 `cylTabBarPageSourceInstanceRegistry`。
 */
@available(*, deprecated, renamed: "cylTabBarPageSourceInstanceRegistry")
public let CYLTabBarPageSourceInstanceRegistry = cylTabBarPageSourceInstanceRegistry

/**
 [EN] Deprecated: renamed to `cylTabBarPageSourceResolver`.
 [CN] 已废弃：已改名为 `cylTabBarPageSourceResolver`。
 */
@available(*, deprecated, renamed: "cylTabBarPageSourceResolver")
public let CYLTabBarPageSourceResolver = cylTabBarPageSourceResolver

/**
 [EN] Deprecated: renamed to `cylTabBarPageSourceSharedRegistry`.
 [CN] 已废弃：已改名为 `cylTabBarPageSourceSharedRegistry`。
 */
@available(*, deprecated, renamed: "cylTabBarPageSourceSharedRegistry")
public let CYLTabBarPageSourceSharedRegistry = cylTabBarPageSourceSharedRegistry

/**
 [EN] Deprecated: renamed to `cylTabBarPageSourceAutomaticRegistration`.
 [CN] 已废弃：已改名为 `cylTabBarPageSourceAutomaticRegistration`。
 */
@available(*, deprecated, renamed: "cylTabBarPageSourceAutomaticRegistration")
public let CYLTabBarPageSourceAutomaticRegistration = cylTabBarPageSourceAutomaticRegistration
