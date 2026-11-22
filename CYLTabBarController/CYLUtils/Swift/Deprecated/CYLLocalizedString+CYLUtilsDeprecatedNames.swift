//
//  CYLLocalizedString+CYLUtilsDeprecatedNames.swift
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
 [EN] Deprecated: renamed to `cylLocalizationLanguageDidChangeNotification`.
 [CN] 已废弃：已改名为 `cylLocalizationLanguageDidChangeNotification`。
 */
@available(*, deprecated, renamed: "cylLocalizationLanguageDidChangeNotification")
public let CYLLocalizationLanguageDidChangeNotification = cylLocalizationLanguageDidChangeNotification

/**
 [EN] Deprecated: renamed to `cylLocalizedString`.
 [CN] 已废弃：已改名为 `cylLocalizedString`。
 */
@available(*, deprecated, renamed: "cylLocalizedString(_:)")
public func CYLLocalizedString(_ key: String) -> String { cylLocalizedString(key) }

/**
 [EN] Deprecated: renamed to `cylResourceBundle`.
 [CN] 已废弃：已改名为 `cylResourceBundle`。
 */
@available(*, deprecated, renamed: "cylResourceBundle()")
public func CYLResourceBundle() -> Bundle { cylResourceBundle() }

/**
 [EN] Deprecated: renamed to `cylSetLocalizationLanguage`.
 [CN] 已废弃：已改名为 `cylSetLocalizationLanguage`。
 */
@available(*, deprecated, renamed: "cylSetLocalizationLanguage(_:)")
public func CYLSetLocalizationLanguage(_ language: String?) { cylSetLocalizationLanguage(language) }

/**
 [EN] Deprecated: renamed to `cylLocalizedStringForLanguage`.
 [CN] 已废弃：已改名为 `cylLocalizedStringForLanguage`。
 */
@available(*, deprecated, renamed: "cylLocalizedStringForLanguage(_:_:)")
public func CYLLocalizedStringForLanguage(_ key: String, _ language: String?) -> String { cylLocalizedStringForLanguage(key, language) }

/**
 [EN] Deprecated: renamed to `cylLocalizationLanguage`.
 [CN] 已废弃：已改名为 `cylLocalizationLanguage`。
 */
@available(*, deprecated, renamed: "cylLocalizationLanguage()")
public func CYLLocalizationLanguage() -> String { cylLocalizationLanguage() }
