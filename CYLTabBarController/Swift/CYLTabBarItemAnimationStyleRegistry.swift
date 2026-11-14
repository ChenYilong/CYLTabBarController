//
//  CYLTabBarItemAnimationStyleRegistry.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Core's style registry of tab icon animations (dark URLs, dark colors and colors of every appearance, #442, #216) and the
//      animation URL of a tab's attributes, translated from Objective-C (CYLConstants.m, UIControl+CYLTabBarItemAnimation.m;
//      docs/Swift-Migration.md, step 45). The C names are kept with `@_cdecl`.
// [CN] Core 的 Tab 图标动画风格注册表（深色 URL、深色颜色与所有外观的颜色，#442、#216）以及 Tab 属性中动画 URL 的读取，已从 Objective-C
//      翻译（CYLConstants.m、UIControl+CYLTabBarItemAnimation.m；docs/Swift-Migration.md，第 45 步）。C 名称通过 `@_cdecl` 保留。

/**
 * [EN] The registry behind `CYLTabBarItemAnimationDefaultStyleSource()`, keyed by the light URL's absolute string.
 * [CN] `CYLTabBarItemAnimationDefaultStyleSource()` 背后的注册表，以浅色 URL 的绝对字符串为键。
 */
final class CYLTabBarItemAnimationStyleRegistry: NSObject, CYLTabBarItemAnimationStyleSource {

    /** [EN] The shared registry. [CN] 共享注册表。 */
    static let shared = CYLTabBarItemAnimationStyleRegistry()

    private var darkURLs: [String: URL] = [:]
    private var darkColors: [String: [String: UIColor]] = [:]
    private var colors: [String: [String: UIColor]] = [:]

    private static func key(_ url: URL?) -> String? {
        guard let key = url?.absoluteString, !key.isEmpty else { return nil }
        return key
    }

    /** [EN] The colors whose key paths are non-empty strings; nil when none is left. [CN] 键路径为非空字符串的颜色；没有剩余时为 nil。 */
    private static func validColors(_ colors: NSDictionary?) -> [String: UIColor]? {
        var valid: [String: UIColor] = [:]
        for case let (keypath as String, color as UIColor) in colors ?? [:] where !keypath.isEmpty {
            valid[keypath] = color
        }
        return valid.isEmpty ? nil : valid
    }

    func registerDarkURL(_ darkURL: URL?, for url: URL?) {
        guard let key = Self.key(url) else { return }
        darkURLs[key] = darkURL
    }

    func registerDarkColors(_ colors: NSDictionary?, for url: URL?) {
        guard let key = Self.key(url) else { return }
        darkColors[key] = Self.validColors(colors)
    }

    func registerColors(_ colors: NSDictionary?, for url: URL?) {
        guard let key = Self.key(url) else { return }
        self.colors[key] = Self.validColors(colors)
    }

    // MARK: CYLTabBarItemAnimationStyleSource

    func hasStyleVariants() -> Bool {
        !darkURLs.isEmpty || !darkColors.isEmpty || !colors.isEmpty
    }

    func hasStyleVariant(for URL: URL?) -> Bool {
        guard let key = Self.key(URL) else { return false }
        return darkURLs[key] != nil || !(darkColors[key] ?? [:]).isEmpty || !(colors[key] ?? [:]).isEmpty
    }

    func url(_ URL: URL?, for traitCollection: UITraitCollection?) -> URL? {
        guard let URL else { return nil }
        if traitCollection?.userInterfaceStyle == .dark, let key = Self.key(URL) {
            return darkURLs[key] ?? URL
        }
        return URL
    }

    func darkColors(for URL: URL?) -> [String: UIColor]? {
        Self.key(URL).flatMap { darkColors[$0] }
    }

    func colors(for URL: URL?) -> [String: UIColor]? {
        Self.key(URL).flatMap { colors[$0] }
    }
}

// MARK: - Animation URL of a tab's attributes

enum CYLTabBarItemAnimationAttributes {

    /** [EN] A file URL for a path that exists (`+[CYLConstants cyl_getURLFromString:]`). [CN] 存在的路径对应的 file URL（`+[CYLConstants cyl_getURLFromString:]`）。 */
    static func fileURL(_ path: Any?) -> URL? {
        guard let path = path as? String, FileManager.default.fileExists(atPath: path) else { return nil }
        return URL(fileURLWithPath: path)
    }

    /**
     * [EN] Registers the Dark Mode version (#442) and the colors (#216) of `animationURL` from the tab's keys (the generic
     *      ones, or those of the library the tab's keys choose, #604). Nothing runs without any of them and nothing
     *      registered before.
     * [CN] 根据 Tab 的 key（通用 key，或 Tab 的 key 选择的动画库的 key，#604）注册 `animationURL` 的深色模式版本（#442）与颜色（#216）。
     *      都没有且此前也未注册时不做任何事。
     */
    static func registerDarkAnimation(_ animationURL: URL?, attributes: NSDictionary?) {
        guard let animationURL else { return }
        func value(_ key: String) -> Any? {
            cylTabBarItemAttributesAnimationValueEntryPoint(attributes, key as NSString)
        }
        let darkURL = (value(CYLTabBarAnimationDarkURL) as? URL) ?? fileURL((value(CYLTabBarAnimationDarkFilePath) as? String).flatMap { $0.isEmpty ? nil : $0 })
        let darkColors = (value(CYLTabBarAnimationDarkColors) as? NSDictionary).flatMap { $0.count > 0 ? $0 : nil }
        let colors = (value(CYLTabBarAnimationColors) as? NSDictionary).flatMap { $0.count > 0 ? $0 : nil }
        let registry = CYLTabBarItemAnimationStyleRegistry.shared
        if darkURL == nil, darkColors == nil, colors == nil, !registry.hasStyleVariant(for: animationURL) {
            return
        }
        registry.registerColors(colors, for: animationURL)
        // [EN] The dark version is played by the same library as the light one. [CN] 深色版本与浅色版本由同一个动画库播放。
        if let darkURL {
            CYLTabBarItemAnimationCore.service?.bindAnimationURL(darkURL, toAttributes: attributes as? [AnyHashable: Any] ?? [:])
        }
        registry.registerDarkURL(darkURL, for: animationURL)
        registry.registerDarkColors(darkColors, for: animationURL)
    }
}

// MARK: - The C entry points (declared in CYLTabBarItemAnimationService.h and UIControl+CYLTabBarItemAnimation.h)

@_cdecl("CYLTabBarItemAnimationDefaultStyleSource")
public func cylTabBarItemAnimationDefaultStyleSourceEntryPoint() -> CYLTabBarItemAnimationStyleSource {
    CYLTabBarItemAnimationStyleRegistry.shared
}

@_cdecl("CYLTabBarItemAnimationRegisterDarkStyle")
public func cylTabBarItemAnimationRegisterDarkStyleEntryPoint(_ url: NSURL, _ darkURL: NSURL?, _ darkColors: NSDictionary?) {
    CYLTabBarItemAnimationStyleRegistry.shared.registerDarkURL(darkURL as URL?, for: url as URL?)
    CYLTabBarItemAnimationStyleRegistry.shared.registerDarkColors(darkColors, for: url as URL?)
}

@_cdecl("CYLTabBarItemAnimationRegisterColors")
public func cylTabBarItemAnimationRegisterColorsEntryPoint(_ url: NSURL, _ colors: NSDictionary?) {
    CYLTabBarItemAnimationStyleRegistry.shared.registerColors(colors, for: url as URL?)
}

/**
 * [EN] Private (declared in CYLConstants.m): the dark URL alone, for the deprecated `+cyl_registerDarkLottieURL:forLottieURL:`.
 * [CN] 私有（声明于 CYLConstants.m）：只注册深色 URL，供已弃用的 `+cyl_registerDarkLottieURL:forLottieURL:` 使用。
 */
@_cdecl("CYLTabBarItemAnimationRegisterDarkURL")
public func cylTabBarItemAnimationRegisterDarkURLEntryPoint(_ url: NSURL?, _ darkURL: NSURL?) {
    CYLTabBarItemAnimationStyleRegistry.shared.registerDarkURL(darkURL as URL?, for: url as URL?)
}

/**
 * [EN] Private (declared in CYLConstants.m): the dark colors alone, for the deprecated `+cyl_registerLottieDarkColors:forLottieURL:`.
 * [CN] 私有（声明于 CYLConstants.m）：只注册深色颜色，供已弃用的 `+cyl_registerLottieDarkColors:forLottieURL:` 使用。
 */
@_cdecl("CYLTabBarItemAnimationRegisterDarkColors")
public func cylTabBarItemAnimationRegisterDarkColorsEntryPoint(_ url: NSURL?, _ darkColors: NSDictionary?) {
    CYLTabBarItemAnimationStyleRegistry.shared.registerDarkColors(darkColors, for: url as URL?)
}

/**
 * [EN] The animation file of a tab item (`…URL`, else `…FilePath`, written to `filePath`), bound to the library its keys
 *      choose, with its Dark Mode version (#442, #604).
 * [CN] Tab item 的动画文件（`…URL`，否则为 `…FilePath`，并写入 `filePath`），绑定到其 key 选择的动画库，并注册其深色模式版本（#442、#604）。
 */
@_cdecl("CYLTabBarItemAnimationURLFromAttributes")
public func cylTabBarItemAnimationURLFromAttributesEntryPoint(_ attributes: NSDictionary?,
                                                              _ filePath: AutoreleasingUnsafeMutablePointer<NSString?>?) -> NSURL? {
    let urlValue = cylTabBarItemAttributesAnimationValueEntryPoint(attributes, CYLTabBarAnimationURL as NSString)
    let path = cylTabBarItemAttributesAnimationValueEntryPoint(attributes, CYLTabBarAnimationFilePath as NSString) as? String
    filePath?.pointee = path as NSString?
    let animationURL = (urlValue as? URL) ?? CYLTabBarItemAnimationAttributes.fileURL(path)
    if let animationURL {
        CYLTabBarItemAnimationCore.service?.bindAnimationURL(animationURL, toAttributes: attributes as? [AnyHashable: Any] ?? [:])
    }
    CYLTabBarItemAnimationAttributes.registerDarkAnimation(animationURL, attributes: attributes)
    return animationURL as NSURL?
}
