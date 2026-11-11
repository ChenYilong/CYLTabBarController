//
//  CYLDemoLocalization.swift
//  CYLTabBarController examples
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 2026/11/11.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation
import CYLTabBarController

/// [EN] The texts only the Swift examples show, read from the example-level `CYLDemo.bundle` (table `CYLDemo`), in the
///      language of `CYLLocalizationLanguage()`; English when the language has none; a key missing from the demo table
///      falls back to the library's `CYLLocalizedString()`. The Swift counterpart of the Objective-C `CYLDemoLocalizedString()`
///      in `CYLDemoLocalization.m`, named in Swift style (lowerCamelCase, SwiftLint / SonarCloud S100) (AGENTS.md, "Localization file structure").
/// [CN] 只有 Swift 示例显示的文字，从示例级的 `CYLDemo.bundle`（表 `CYLDemo`）读取，语言跟随 `CYLLocalizationLanguage()`；该语言没有时
///      使用英语；示例表中没有的键回退到库的 `CYLLocalizedString()`。是 `CYLDemoLocalization.m` 中 Objective-C 版
///      `CYLDemoLocalizedString()` 的 Swift 对应版本，按 Swift 规范使用小驼峰命名（AGENTS.md「Localization file structure」）。
func cylDemoLocalizedString(_ key: String) -> String {
    if key.isEmpty {
        return key
    }
    // [EN] A sentinel tells "not in the demo table" apart from a translation equal to the key.
    // [CN] 用哨兵值区分「示例表中没有」与「译文恰好等于键」。
    let missing = "<CYLDemoLocalizedString: missing>"
    let bundle = CYLDemoLocalizationBundle.languageBundle(for: CYLLocalizationLanguage())
    let value = bundle?.localizedString(forKey: key, value: missing, table: "CYLDemo") ?? missing
    if value.isEmpty || value == missing {
        return CYLLocalizedString(key)
    }
    return value
}

private enum CYLDemoLocalizationBundle {
    /// [EN] `CYLDemo.bundle` in the app, or nil. [CN] App 中的 `CYLDemo.bundle`，没有时为 nil。
    private static let demoBundle: Bundle? = {
        guard let url = Bundle.main.url(forResource: "CYLDemo", withExtension: "bundle") else {
            return nil
        }
        return Bundle(url: url)
    }()

    /// [EN] The `.lproj` of `language` in `CYLDemo.bundle`, else English. [CN] `CYLDemo.bundle` 中 `language` 的 `.lproj`，没有时为英语。
    static func languageBundle(for language: String) -> Bundle? {
        guard let demoBundle = demoBundle else {
            return nil
        }
        let path = demoBundle.path(forResource: language, ofType: "lproj") ?? demoBundle.path(forResource: "en", ofType: "lproj")
        return path.flatMap { Bundle(path: $0) }
    }
}
