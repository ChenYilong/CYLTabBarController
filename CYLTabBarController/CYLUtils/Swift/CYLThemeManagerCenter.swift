//
//  CYLThemeManagerCenter.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The name of the default theme manager.
 * [CN] 默认主题管理器的名称。
 */
public let CYLThemeManagerNameDefault = "Default" // NOSONAR: kept API name

/**
 * [EN] Holds the theme managers by name. Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers get
 *      this class from `CYLSwiftInterface.h`; the Swift names are the ones Clang imported.
 * [CN] 按名称保存主题管理器。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方通过 `CYLSwiftInterface.h` 使用
 *      本类；Swift 名称与 Clang 原先导入的名称相同。
 */
@objc(CYLThemeManagerCenter)
public class CYLThemeManagerCenter: NSObject {

    private static let lock = NSLock()
    private static var managers: [CYLThemeManager] = []

    /**
     * [EN] The manager named `CYLThemeManagerNameDefault`.
     * [CN] 名为 `CYLThemeManagerNameDefault` 的管理器。
     */
    @objc public class var defaultThemeManager: CYLThemeManager {
        themeManager(withName: CYLThemeManagerNameDefault as NSString)
    }

    /**
     * [EN] Every manager made so far.
     * [CN] 目前已创建的所有管理器。
     */
    @objc public class var themeManagers: [CYLThemeManager] {
        lock.lock()
        defer { lock.unlock() }
        return managers
    }

    /**
     * [EN] The manager named `name`, made on first use.
     * [CN] 名为 `name` 的管理器，首次使用时创建。
     */
    @objc(themeManagerWithName:)
    public class func themeManager(withName name: NSCopying & NSObjectProtocol) -> CYLThemeManager {
        lock.lock()
        defer { lock.unlock() }
        if let manager = managers.first(where: { $0.name.isEqual(name) }) {
            return manager
        }
        let manager = CYLThemeManager(name: name)
        managers.append(manager)
        return manager
    }

    /**
     * [EN] Updates every manager for a trait collection; when no theme changes, resolves trait-dependent layer colors.
     * [CN] 按特征集合更新所有管理器；没有主题变化时，重新解析随特征变化的图层颜色。
     */
    @objc(updateThemesForTraitCollection:)
    public class func updateThemes(for traitCollection: UITraitCollection) {
        var themeChanged = false
        for manager in themeManagers {
            let identifier = manager.currentThemeIdentifier
            manager.updateTheme(for: traitCollection)
            let newIdentifier = manager.currentThemeIdentifier
            themeChanged = themeChanged || (identifier !== newIdentifier && !(identifier?.isEqual(newIdentifier) ?? false))
        }
        if !themeChanged {
            CYLThemeRuntime.refreshTraitDependentValues()
        }
    }
}
