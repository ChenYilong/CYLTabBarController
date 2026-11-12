//
//  UIView+CYLTheme.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Refreshing a view's theme values on a theme change. Translated from Objective-C (docs/Swift-Migration.md);
 *      Objective-C callers keep the declarations in `UIView+CYLTheme.h`. `-cyl_themeDidChangeByManager:identifier:theme:`
 *      is `open dynamic`: subclasses (Objective-C and Swift) override it and call super.
 * [CN] 主题切换时刷新视图的主题值。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方继续使用
 *      `UIView+CYLTheme.h` 中的声明。`-cyl_themeDidChangeByManager:identifier:theme:` 为 `open dynamic`：子类（Objective-C 与
 *      Swift）可重写并调用 super。
 */
extension UIView {

    /**
     * [EN] Registers properties (by getter name) whose theme colors, images or effects are set again on a theme change.
     * [CN] 注册属性（按 getter 名称），其主题颜色、图片或效果会在主题切换时重新设置。
     */
    @objc(cyl_registerThemeColorProperties:)
    public func cyl_registerThemeColorProperties(_ getters: [String]) { // NOSONAR: kept API name
        for getterName in getters {
            let setterName = CYLThemeViewKeys.setterName(for: getterName)
            guard responds(to: NSSelectorFromString(getterName)), responds(to: NSSelectorFromString(setterName)) else {
                NSLog("🔴 UIView (CYLTheme): %@ has no property %@ with the setter %@, it is not registered.",
                      NSStringFromClass(type(of: self)), getterName, setterName)
                continue
            }
            let properties = cyl_themeColorProperties ?? NSMutableDictionary()
            cyl_themeColorProperties = properties
            properties[getterName] = setterName
            CYLThemeRuntime.track(self)
        }
    }

    /**
     * [EN] Stops refreshing the given properties.
     * [CN] 停止刷新给出的属性。
     */
    @objc(cyl_unregisterThemeColorProperties:)
    public func cyl_unregisterThemeColorProperties(_ getters: [String]) { // NOSONAR: kept API name
        cyl_themeColorProperties?.removeObjects(forKeys: getters)
    }

    /**
     * [EN] Called on a theme change (manager nil: apply the current theme of every manager). Subclasses call super.
     * [CN] 主题切换时调用（manager 为 nil：应用所有管理器的当前主题）。子类需调用 super。
     */
    @objc(cyl_themeDidChangeByManager:identifier:theme:)
    open dynamic func cyl_themeDidChange(by manager: CYLThemeManager?, // NOSONAR: kept API name
                                         identifier _: (NSCopying & NSObjectProtocol)?,
                                         theme _: NSObject?) {
        if let properties = cyl_themeColorProperties {
            for case let (getterName as String, setterName as String) in properties {
                refreshThemeProperty(getterName, setterName, manager: manager)
            }
        }
        if CYLThemeViewKeys.refreshBuiltInValues(of: self, manager: manager) {
            CYLThemeRuntime.track(self)
        }
        layer.cyl_updateThemeColors()
        if self is UILabel || self is UITextView {
            setNeedsDisplay()
        }
        CYLThemeRuntime.refreshBarAppearances(of: self)
        cyl_themeDidChangeBlock?()
    }

    /**
     * [EN] Called after every theme change of this view.
     * [CN] 本视图每次主题切换后调用。
     */
    @objc public var cyl_themeDidChangeBlock: (@convention(block) () -> Void)? {
        get {
            guard let object = objc_getAssociatedObject(self, CYLThemeViewKeys.didChangeBlock) else {
                return nil
            }
            return unsafeBitCast(object as AnyObject, to: (@convention(block) () -> Void).self)
        }
        set {
            let object = newValue.map { unsafeBitCast($0, to: AnyObject.self) }
            objc_setAssociatedObject(self, CYLThemeViewKeys.didChangeBlock, object, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    /**
     * [EN] Applies the current theme to this view and its subviews.
     * [CN] 将当前主题应用到本视图及其子视图。
     */
    @objc(cyl_applyCurrentTheme)
    public func cyl_applyCurrentTheme() { // NOSONAR: kept API name
        applyThemeChange(by: nil, identifier: nil, theme: nil, enumeratesSubviews: true)
    }

    // MARK: - Internal (was UIView (CYLThemePrivate))

    var cyl_themeColorProperties: NSMutableDictionary? {
        get { objc_getAssociatedObject(self, CYLThemeViewKeys.colorProperties) as? NSMutableDictionary }
        set { objc_setAssociatedObject(self, CYLThemeViewKeys.colorProperties, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var cyl_themeChangeGeneration: UInt {
        get { (objc_getAssociatedObject(self, CYLThemeViewKeys.changeGeneration) as? NSNumber)?.uintValue ?? 0 }
        set {
            objc_setAssociatedObject(self, CYLThemeViewKeys.changeGeneration, NSNumber(value: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Refreshes this view (once per theme change) and, when asked, its subviews.
     * [CN] 刷新本视图（每次主题切换只刷新一次），需要时也刷新其子视图。
     */
    func applyThemeChange(by manager: CYLThemeManager?, identifier: (NSCopying & NSObjectProtocol)?, theme: NSObject?,
                          enumeratesSubviews: Bool) {
        let generation = CYLThemeRuntime.currentChangeGeneration
        if generation != 0 {
            if cyl_themeChangeGeneration == generation {
                return
            }
            cyl_themeChangeGeneration = generation
        }
        cyl_themeDidChange(by: manager, identifier: identifier, theme: theme)
        guard enumeratesSubviews else {
            return
        }
        for subview in subviews {
            subview.applyThemeChange(by: manager, identifier: identifier, theme: theme, enumeratesSubviews: true)
        }
    }

    private func refreshThemeProperty(_ getterName: String, _ setterName: String, manager: CYLThemeManager?) {
        let getter = NSSelectorFromString(getterName)
        if getter == #selector(getter: UIImageView.image), CYLThemeViewKeys.isSwappableImageView(self) {
            return
        }
        guard let value = perform(getter)?.takeUnretainedValue() else {
            return
        }
        let setter = NSSelectorFromString(setterName)
        if value is UIColor || value is UIImage || value is UIVisualEffect {
            if let refreshed = CYLThemeRuntime.refreshedValue(value, manager: manager) {
                perform(setter, with: refreshed)
            }
        } else {
            perform(setter, with: value)
        }
    }
}

/**
 * [EN] Keys and helpers of the view theme extension.
 * [CN] 视图主题扩展的 key 与辅助方法。
 */
private enum CYLThemeViewKeys {
    static let didChangeBlock = CYLUtilsKeys.key("cyl_themeDidChangeBlock")
    static let colorProperties = CYLUtilsKeys.key("cyl_themeColorProperties")
    static let changeGeneration = CYLUtilsKeys.key("cyl_themeChangeGeneration")
    static let buttonStates: [UIControl.State] = [.normal, .highlighted, .selected, [.selected, .highlighted], .disabled]

    static func setterName(for getterName: String) -> String {
        guard let first = getterName.first else {
            return getterName
        }
        return "set\(String(first).uppercased())\(getterName.dropFirst()):"
    }

    static func isSwappableImageView(_ view: UIView) -> Bool {
        guard let swappable = NSClassFromString("UITabBarSwappableImageView") else {
            return false
        }
        return view.isKind(of: swappable)
    }

    /**
     * [EN] Refreshes the theme values UIKit views hold themselves (image views, buttons, effect views); whether any is a
     *      theme value.
     * [CN] 刷新 UIKit 视图自身持有的主题值（图片视图、按钮、效果视图）；返回其中是否有主题值。
     */
    static func refreshBuiltInValues(of view: UIView, manager: CYLThemeManager?) -> Bool {
        var holdsThemeValues = false
        if let imageView = view as? UIImageView {
            guard !isSwappableImageView(imageView) else {
                return false
            }
            holdsThemeValues = imageView.image?.cyl_isThemeImage == true || imageView.highlightedImage?.cyl_isThemeImage == true
            if let image = CYLThemeRuntime.refreshedValue(imageView.image, manager: manager) as? UIImage {
                imageView.image = image
            }
            if let image = CYLThemeRuntime.refreshedValue(imageView.highlightedImage, manager: manager) as? UIImage {
                imageView.highlightedImage = image
            }
        } else if let button = view as? UIButton {
            let normalImage = button.image(for: .normal)
            let normalBackgroundImage = button.backgroundImage(for: .normal)
            for state in buttonStates {
                let image = button.image(for: state)
                if state == .normal || image !== normalImage {
                    holdsThemeValues = holdsThemeValues || image?.cyl_isThemeImage == true
                    if let refreshed = CYLThemeRuntime.refreshedValue(image, manager: manager) as? UIImage {
                        button.setImage(refreshed, for: state)
                    }
                }
                let backgroundImage = button.backgroundImage(for: state)
                if state == .normal || backgroundImage !== normalBackgroundImage {
                    holdsThemeValues = holdsThemeValues || backgroundImage?.cyl_isThemeImage == true
                    if let refreshed = CYLThemeRuntime.refreshedValue(backgroundImage, manager: manager) as? UIImage {
                        button.setBackgroundImage(refreshed, for: state)
                    }
                }
            }
        } else if let effectView = view as? UIVisualEffectView {
            holdsThemeValues = effectView.effect?.cyl_isThemeEffect == true
            if let effect = CYLThemeRuntime.refreshedValue(effectView.effect, manager: manager) as? UIVisualEffect {
                effectView.effect = effect
            }
        }
        return holdsThemeValues
    }
}
