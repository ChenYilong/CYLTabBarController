//
//  UIColor+CYLTheme.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Gives the color of a theme color for a manager, its current theme identifier and its current theme. Translated from
 *      Objective-C with the rest of the theme module (docs/Swift-Migration.md).
 * [CN] 根据管理器、其当前主题标识与当前主题给出主题颜色的颜色。与主题模块其他部分一起从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
public typealias CYLThemeColorProvider = (CYLThemeManager, (NSCopying & NSObjectProtocol)?, NSObject?) -> UIColor

private final class CYLThemeColorInfo: NSObject {
    let name: String?
    let managerName: NSCopying & NSObjectProtocol
    let provider: CYLThemeColorProvider

    init(name: String?, managerName: NSCopying & NSObjectProtocol, provider: @escaping CYLThemeColorProvider) {
        self.name = name
        self.managerName = managerName
        self.provider = provider
    }
}

/**
 * [EN] Making, resolving and refreshing theme colors (internal).
 * [CN] 生成、解析与刷新主题颜色（内部使用）。
 */
enum CYLThemeColor {

    private static var infoKey: UInt8 = 0

    fileprivate static func info(of color: UIColor) -> CYLThemeColorInfo? {
        objc_getAssociatedObject(color, &infoKey) as? CYLThemeColorInfo
    }

    /**
     * [EN] The provider's color for the current theme of its manager; a theme color it returns is resolved too (8 levels).
     * [CN] provider 针对其管理器当前主题给出的颜色；它返回的主题颜色也会继续解析（最多 8 层）。
     */
    fileprivate static func resolve(_ managerName: NSCopying & NSObjectProtocol, _ provider: CYLThemeColorProvider) -> UIColor {
        let manager = CYLThemeManagerCenter.themeManager(withName: managerName)
        var color: UIColor? = provider(manager, manager.currentThemeIdentifier, manager.currentTheme)
        var depth = 0
        while depth < 8, let current = color, let nested = info(of: current) {
            let nestedManager = CYLThemeManagerCenter.themeManager(withName: nested.managerName)
            color = nested.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme)
            depth += 1
        }
        return color ?? .clear
    }

    fileprivate static func make(_ name: String?, _ managerName: NSCopying & NSObjectProtocol,
                                 _ provider: @escaping CYLThemeColorProvider) -> UIColor {
        let color = UIColor { traitCollection in
            resolve(managerName, provider).resolvedColor(with: traitCollection)
        }
        let info = CYLThemeColorInfo(name: name, managerName: managerName, provider: provider)
        objc_setAssociatedObject(color, &infoKey, info, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return color
    }

    static func refreshed(_ color: UIColor) -> UIColor {
        guard let info = info(of: color) else {
            return color
        }
        return make(info.name, info.managerName, info.provider)
    }

    static func managerName(of color: UIColor) -> (NSCopying & NSObjectProtocol)? {
        info(of: color)?.managerName
    }

    fileprivate static var defaultManagerName: NSCopying & NSObjectProtocol {
        CYLThemeManagerNameDefault as NSString
    }
}

/**
 * [EN] A color that follows a theme: its provider gives it again on every theme change. Translated from Objective-C
 *      (docs/Swift-Migration.md); Objective-C callers keep the declarations in `UIColor+CYLTheme.h`; the Swift names are
 *      the ones Clang imported.
 * [CN] 颜色跟随主题：每次切换主题时由 provider 重新给出。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方继续使用
 *      `UIColor+CYLTheme.h` 中的声明；Swift 名称与 Clang 原先导入的名称相同。
 */
extension UIColor {

    /**
     * [EN] A theme color of the default manager.
     * [CN] 默认管理器的主题颜色。
     */
    @objc(cyl_colorWithThemeProvider:)
    public class func cyl_color(themeProvider provider: @escaping CYLThemeColorProvider) -> UIColor {
        CYLThemeColor.make(nil, CYLThemeColor.defaultManagerName, provider)
    }

    /**
     * [EN] A named theme color of the default manager.
     * [CN] 默认管理器的具名主题颜色。
     */
    @objc(cyl_colorWithName:themeProvider:)
    public class func cyl_color(withName name: String?, themeProvider provider: @escaping CYLThemeColorProvider) -> UIColor {
        CYLThemeColor.make(name, CYLThemeColor.defaultManagerName, provider)
    }

    /**
     * [EN] A theme color of the manager named `managerName`.
     * [CN] 名为 `managerName` 的管理器的主题颜色。
     */
    @objc(cyl_colorWithThemeManagerName:provider:)
    public class func cyl_color(withThemeManagerName managerName: (NSCopying & NSObjectProtocol)?,
                                provider: @escaping CYLThemeColorProvider) -> UIColor {
        CYLThemeColor.make(nil, managerName ?? CYLThemeColor.defaultManagerName, provider)
    }

    /**
     * [EN] A named theme color of the manager named `managerName` (the default manager when nil).
     * [CN] 名为 `managerName` 的管理器（为 nil 时为默认管理器）的具名主题颜色。
     */
    @objc(cyl_colorWithName:themeManagerName:provider:)
    public class func cyl_color(withName name: String?, themeManagerName managerName: (NSCopying & NSObjectProtocol)?,
                                provider: @escaping CYLThemeColorProvider) -> UIColor {
        CYLThemeColor.make(name, managerName ?? CYLThemeColor.defaultManagerName, provider)
    }

    /**
     * [EN] The name given when the theme color was made.
     * [CN] 生成主题颜色时给出的名称。
     */
    @objc public var cyl_themeColorName: String? {
        CYLThemeColor.info(of: self)?.name
    }

    /**
     * [EN] Whether this is a theme color.
     * [CN] 是否为主题颜色。
     */
    @objc public var cyl_isThemeColor: Bool {
        CYLThemeColor.info(of: self) != nil
    }

    /**
     * [EN] The plain color the provider gives for the current theme (self when this is not a theme color).
     * [CN] provider 针对当前主题给出的普通颜色（不是主题颜色时返回自身）。
     */
    @objc(cyl_rawColor) public var cyl_raw: UIColor {
        guard let info = CYLThemeColor.info(of: self) else {
            return self
        }
        return CYLThemeColor.resolve(info.managerName, info.provider)
    }
}
