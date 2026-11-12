//
//  UIVisualEffect+CYLTheme.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Gives the effect of a theme effect for a manager, its current theme identifier and its current theme. Translated from
 *      Objective-C with the rest of the theme module (docs/Swift-Migration.md).
 * [CN] 根据管理器、其当前主题标识与当前主题给出主题效果的效果。与主题模块其他部分一起从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
public typealias CYLThemeEffectProvider = (CYLThemeManager, (NSCopying & NSObjectProtocol)?, NSObject?) -> UIVisualEffect?

private final class CYLThemeEffectInfo: NSObject {
    let name: String?
    let managerName: NSCopying & NSObjectProtocol
    let provider: CYLThemeEffectProvider

    init(name: String?, managerName: NSCopying & NSObjectProtocol, provider: @escaping CYLThemeEffectProvider) {
        self.name = name
        self.managerName = managerName
        self.provider = provider
    }
}

/**
 * [EN] Making, resolving and refreshing theme effects (internal).
 * [CN] 生成、解析与刷新主题效果（内部使用）。
 */
enum CYLThemeEffect {

    private static var infoKey: UInt8 = 0

    fileprivate static func info(of effect: UIVisualEffect) -> CYLThemeEffectInfo? {
        objc_getAssociatedObject(effect, &infoKey) as? CYLThemeEffectInfo
    }

    /**
     * [EN] The provider's effect for the current theme of its manager; a theme effect it returns is resolved too (8 levels).
     * [CN] provider 针对其管理器当前主题给出的效果；它返回的主题效果也会继续解析（最多 8 层）。
     */
    fileprivate static func resolve(_ managerName: NSCopying & NSObjectProtocol, _ provider: CYLThemeEffectProvider) -> UIVisualEffect {
        let manager = CYLThemeManagerCenter.themeManager(withName: managerName)
        var effect: UIVisualEffect? = provider(manager, manager.currentThemeIdentifier, manager.currentTheme)
        var depth = 0
        while depth < 8, let current = effect, let nested = info(of: current) {
            let nestedManager = CYLThemeManagerCenter.themeManager(withName: nested.managerName)
            effect = nested.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme)
            depth += 1
        }
        return effect ?? UIVisualEffect()
    }

    fileprivate static func make(_ name: String?, _ managerName: NSCopying & NSObjectProtocol,
                                 _ provider: @escaping CYLThemeEffectProvider) -> UIVisualEffect {
        let effect = newObject(resolve(managerName, provider))
        let info = CYLThemeEffectInfo(name: name, managerName: managerName, provider: provider)
        objc_setAssociatedObject(effect, &infoKey, info, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return effect
    }

    static func refreshed(_ effect: UIVisualEffect) -> UIVisualEffect {
        guard let info = info(of: effect) else {
            return effect
        }
        return make(info.name, info.managerName, info.provider)
    }

    static func managerName(of effect: UIVisualEffect) -> (NSCopying & NSObjectProtocol)? {
        info(of: effect)?.managerName
    }

    /**
     * [EN] A new object equal to `effect` (an archived copy), so the effect view sees a change; `effect` itself when it
     *      cannot be copied.
     * [CN] 与 `effect` 相同的新对象（归档后的副本），让效果视图感知到变化；无法复制时返回 `effect` 本身。
     */
    private static func newObject(_ effect: UIVisualEffect) -> UIVisualEffect {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: effect, requiringSecureCoding: true),
              let copy = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIVisualEffect.self, from: data),
              copy !== effect else {
            return effect
        }
        return copy
    }

    fileprivate static var defaultManagerName: NSCopying & NSObjectProtocol {
        CYLThemeManagerNameDefault as NSString
    }
}

/**
 * [EN] A visual effect that follows a theme: its provider gives it again on every theme change. Translated from Objective-C
 *      (docs/Swift-Migration.md); Objective-C callers keep the declarations in `UIVisualEffect+CYLTheme.h`; the Swift names
 *      are the ones Clang imported.
 * [CN] 效果跟随主题：每次切换主题时由 provider 重新给出。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方继续使用
 *      `UIVisualEffect+CYLTheme.h` 中的声明；Swift 名称与 Clang 原先导入的名称相同。
 */
extension UIVisualEffect {

    /**
     * [EN] A theme effect of the default manager.
     * [CN] 默认管理器的主题效果。
     */
    @objc(cyl_effectWithThemeProvider:)
    public class func cyl_effect(themeProvider provider: @escaping CYLThemeEffectProvider) -> UIVisualEffect { // NOSONAR: kept API name
        CYLThemeEffect.make(nil, CYLThemeEffect.defaultManagerName, provider)
    }

    /**
     * [EN] A theme effect of the manager named `managerName` (the default manager when nil).
     * [CN] 名为 `managerName` 的管理器（为 nil 时为默认管理器）的主题效果。
     */
    @objc(cyl_effectWithThemeManagerName:provider:)
    public class func cyl_effect(withThemeManagerName managerName: (NSCopying & NSObjectProtocol)?, // NOSONAR: kept API name
                                provider: @escaping CYLThemeEffectProvider) -> UIVisualEffect {
        CYLThemeEffect.make(nil, managerName ?? CYLThemeEffect.defaultManagerName, provider)
    }

    /**
     * [EN] Whether this is a theme effect.
     * [CN] 是否为主题效果。
     */
    @objc public var cyl_isThemeEffect: Bool {
        CYLThemeEffect.info(of: self) != nil
    }

    /**
     * [EN] The plain effect the provider gives for the current theme (self when this is not a theme effect).
     * [CN] provider 针对当前主题给出的普通效果（不是主题效果时返回自身）。
     */
    @objc(cyl_rawEffect) public var cyl_raw: UIVisualEffect {
        guard let info = CYLThemeEffect.info(of: self) else {
            return self
        }
        return CYLThemeEffect.resolve(info.managerName, info.provider)
    }
}
