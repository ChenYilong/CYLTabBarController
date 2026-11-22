//
//  CYLBadgeProtocol+CYLBadgeDeprecatedNames.swift
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
 [EN] Deprecated: renamed to `cylBadgeAnimationKeyForType`.
 [CN] 已废弃：已改名为 `cylBadgeAnimationKeyForType`。
 */
@available(*, deprecated, renamed: "cylBadgeAnimationKeyForType(_:)")
public func CYLBadgeAnimationKeyForType(_ animationType: CYLBadgeAnimationType) -> String? { cylBadgeAnimationKeyForType(animationType) }

/**
 [EN] Deprecated: renamed to `cylBadgeAnimationTypeRepeats`.
 [CN] 已废弃：已改名为 `cylBadgeAnimationTypeRepeats`。
 */
@available(*, deprecated, renamed: "cylBadgeAnimationTypeRepeats(_:)")
public func CYLBadgeAnimationTypeRepeats(_ animationType: CYLBadgeAnimationType) -> Bool { cylBadgeAnimationTypeRepeats(animationType) }

/**
 [EN] Deprecated: renamed to `cylBadgeAllAnimationKeys`.
 [CN] 已废弃：已改名为 `cylBadgeAllAnimationKeys`。
 */
@available(*, deprecated, renamed: "cylBadgeAllAnimationKeys()")
public func CYLBadgeAllAnimationKeys() -> [String] { cylBadgeAllAnimationKeys() }
