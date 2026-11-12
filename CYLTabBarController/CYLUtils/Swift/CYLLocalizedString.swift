//
//  CYLLocalizedString.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The library's strings and resource bundle. Translated from Objective-C (docs/Swift-Migration.md). Objective-C
 *      callers keep the C declarations in `CYLLocalizedString.h`; each function is exported under its old C name
 *      (`@_cdecl`), so the binary interface does not change. `CYLLocalizationLanguageDidChangeNotification` is a macro
 *      for Objective-C and a constant for Swift.
 * [CN] 本库的字符串与资源包。已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）。Objective-C 调用方继续使用
 *      `CYLLocalizedString.h` 中的 C 声明；每个函数以原来的 C 名称导出（`@_cdecl`），二进制接口不变。
 *      `CYLLocalizationLanguageDidChangeNotification` 对 Objective-C 是宏，对 Swift 是常量。
 */

/**
 * [EN] Posted on the main thread after `CYLSetLocalizationLanguage()` changed the language.
 * [CN] `CYLSetLocalizationLanguage()` 修改语言后在主线程发送。
 */
public let CYLLocalizationLanguageDidChangeNotification = "CYLLocalizationLanguageDidChangeNotification"

/**
 * [EN] The string of `key` in the library's string table, in the current language; `key` itself when there is none.
 * [CN] 本库字符串表中 `key` 在当前语言下的字符串；没有时返回 `key` 本身。
 */
public func CYLLocalizedString(_ key: String) -> String {
    CYLLocalization.string(key, bundle: CYLLocalization.languageBundle().bundle)
}

/**
 * [EN] The library's resource bundle (`CYLTabBarController.bundle`), found the same way in CocoaPods, SwiftPM,
 *      Carthage and a copied folder.
 * [CN] 本库的资源包（`CYLTabBarController.bundle`），在 CocoaPods、SwiftPM、Carthage 与直接拖入时以同样方式找到。
 */
public func CYLResourceBundle() -> Bundle {
    CYLLocalization.resourceBundle
}

/**
 * [EN] Sets the language of the library's strings; nil follows the app again. Posts
 *      `CYLLocalizationLanguageDidChangeNotification` on the main thread.
 * [CN] 设置本库字符串的语言；传 nil 恢复跟随 App。在主线程发送 `CYLLocalizationLanguageDidChangeNotification`。
 */
public func CYLSetLocalizationLanguage(_ language: String?) {
    CYLLocalization.setLanguage(language)
}

/**
 * [EN] The string of `key` in `language` (nil: the system's preferred languages).
 * [CN] `key` 在 `language` 中的字符串（nil：系统的首选语言）。
 */
public func CYLLocalizedStringForLanguage(_ key: String, _ language: String?) -> String {
    let closest = CYLLocalization.closestLanguage(language.map { [$0] } ?? Locale.preferredLanguages)
    return CYLLocalization.string(key, bundle: CYLLocalization.bundle(forLanguage: closest))
}

/**
 * [EN] The language the library's strings are in now.
 * [CN] 本库字符串当前使用的语言。
 */
public func CYLLocalizationLanguage() -> String {
    CYLLocalization.languageBundle().language
}

// MARK: - The C entry points for Objective-C callers

@_cdecl("CYLLocalizedString")
public func _CYLLocalizedStringC(_ key: NSString?) -> NSString {
    CYLLocalizedString((key ?? "") as String) as NSString
}

@_cdecl("CYLResourceBundle")
public func _CYLResourceBundleC() -> Bundle {
    CYLResourceBundle()
}

@_cdecl("CYLSetLocalizationLanguage")
public func _CYLSetLocalizationLanguageC(_ language: NSString?) {
    CYLSetLocalizationLanguage(language as String?)
}

@_cdecl("CYLLocalizedStringForLanguage")
public func _CYLLocalizedStringForLanguageC(_ key: NSString?, _ language: NSString?) -> NSString {
    CYLLocalizedStringForLanguage((key ?? "") as String, language as String?) as NSString
}

@_cdecl("CYLLocalizationLanguage")
public func _CYLLocalizationLanguageC() -> NSString {
    CYLLocalizationLanguage() as NSString
}

// MARK: - Implementation

private final class CYLLocalizationBundleToken: NSObject {}

private enum CYLLocalization {
    static let table = "CYLTabBarController"
    static let fallbackLanguage = "en"

    private static let lock = NSLock()
    private static var overriddenLanguage: String?
    private static var resolved: (language: String, bundle: Bundle)?

    static let resourceBundle: Bundle = {
        var containers: [Bundle] = []
        #if SWIFT_PACKAGE
        containers.append(Bundle.module)
        #endif
        containers.append(Bundle(for: CYLLocalizationBundleToken.self))
        containers.append(Bundle.main)
        for container in containers {
            if let url = container.url(forResource: table, withExtension: "bundle"), let bundle = Bundle(url: url) {
                return bundle
            }
        }
        return containers[0]
    }()

    static func string(_ key: String, bundle: Bundle) -> String {
        guard !key.isEmpty else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: table)
    }

    static func closestLanguage(_ preferences: [String]) -> String {
        let available = resourceBundle.localizations.filter { $0 != "Base" }
        let language = Bundle.preferredLocalizations(from: available, forPreferences: preferences).first ?? ""
        return language.isEmpty ? fallbackLanguage : language
    }

    static func bundle(forLanguage language: String) -> Bundle {
        if let path = resourceBundle.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle
        }
        return resourceBundle
    }

    static func languageBundle() -> (language: String, bundle: Bundle) {
        lock.lock()
        defer { lock.unlock() }
        if let resolved {
            return resolved
        }
        var wanted = overriddenLanguage
        if wanted == nil, let appLanguage = Bundle.main.preferredLocalizations.first, appLanguage != "Base" {
            wanted = appLanguage
        }
        let language = closestLanguage(wanted.map { [$0] } ?? Locale.preferredLanguages)
        let result = (language: language, bundle: bundle(forLanguage: language))
        resolved = result
        return result
    }

    static func setLanguage(_ language: String?) {
        lock.lock()
        overriddenLanguage = language
        resolved = nil
        lock.unlock()
        let didChange = {
            UIApplication.shared.accessibilityLanguage = language != nil ? CYLLocalizationLanguage() : nil
            NotificationCenter.default.post(name: Notification.Name(CYLLocalizationLanguageDidChangeNotification), object: nil)
        }
        if Thread.isMainThread {
            didChange()
        } else {
            DispatchQueue.main.async(execute: didChange)
        }
    }
}
