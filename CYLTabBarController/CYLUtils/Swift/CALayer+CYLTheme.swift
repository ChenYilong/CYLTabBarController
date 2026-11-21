//
//  CALayer+CYLTheme.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Theme colors on a layer's color properties (`backgroundColor`, `borderColor`, `shadowColor`, any `CGColor` key),
 *      resolved again on theme and light / dark changes. Translated from Objective-C (docs/Swift-Migration.md);
 *      Objective-C callers keep the declarations in `CALayer+CYLTheme.h`.
 * [CN] 图层颜色属性（`backgroundColor`、`borderColor`、`shadowColor`、任意 `CGColor` key）上的主题颜色，在主题与浅色/深色变化时
 *      重新解析。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方继续使用 `CALayer+CYLTheme.h` 中的声明。
 */
extension CALayer {

    private static var cyl_themeLayerColorsKey: UInt8 = 0
    private static var cyl_themeTraitRegistrationKey: UInt8 = 0

    /**
     * [EN] Sets a theme color for the `CGColor` property `key`; nil removes it and clears the property.
     * [CN] 为 `CGColor` 属性 `key` 设置主题颜色；传 nil 则移除并清空该属性。
     */
    @objc(cyl_setThemeColor:forKey:)
    public func cyl_setThemeColor(_ color: UIColor?, forKey key: String) {
        guard !key.isEmpty else {
            return
        }
        guard let color else {
            cyl_themeLayerColors?.removeObject(forKey: key)
            setValue(nil, forKey: key)
            return
        }
        let colors = cyl_themeLayerColors ?? NSMutableDictionary()
        if cyl_themeLayerColors == nil {
            objc_setAssociatedObject(self, &CALayer.cyl_themeLayerColorsKey, colors, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        colors[key] = color
        applyThemeColor(color, forKey: key)
        if let view = cyl_themeView {
            CYLThemeRuntime.track(view)
            followTraitChanges(of: view)
        }
    }

    /**
     * [EN] The theme color set for `key`.
     * [CN] 为 `key` 设置的主题颜色。
     */
    @objc(cyl_themeColorForKey:)
    public func cyl_themeColor(forKey key: String) -> UIColor? {
        cyl_themeLayerColors?[key] as? UIColor
    }

    /**
     * [EN] Resolves this layer's theme colors again, and those of its sublayers that do not belong to a view.
     * [CN] 重新解析本图层的主题颜色，以及不属于视图的子图层的主题颜色。
     */
    @objc(cyl_updateThemeColors)
    public func cyl_updateThemeColors() {
        if let colors = cyl_themeLayerColors?.copy() as? NSDictionary {
            for case let (key as String, color as UIColor) in colors {
                applyThemeColor(color, forKey: key)
            }
        }
        for sublayer in sublayers ?? [] where !(sublayer.delegate is UIView) {
            sublayer.cyl_updateThemeColors()
        }
    }

    /**
     * [EN] The theme color of `backgroundColor`.
     * [CN] `backgroundColor` 的主题颜色。
     */
    @objc public var cyl_themeBackgroundColor: UIColor? {
        @objc(cyl_themeBackgroundColor) get { cyl_themeColor(forKey: "backgroundColor") }
        @objc(cyl_setThemeBackgroundColor:) set { cyl_setThemeColor(newValue, forKey: "backgroundColor") }
    }

    /**
     * [EN] The theme color of `borderColor`.
     * [CN] `borderColor` 的主题颜色。
     */
    @objc public var cyl_themeBorderColor: UIColor? {
        @objc(cyl_themeBorderColor) get { cyl_themeColor(forKey: "borderColor") }
        @objc(cyl_setThemeBorderColor:) set { cyl_setThemeColor(newValue, forKey: "borderColor") }
    }

    /**
     * [EN] The theme color of `shadowColor`.
     * [CN] `shadowColor` 的主题颜色。
     */
    @objc public var cyl_themeShadowColor: UIColor? {
        @objc(cyl_themeShadowColor) get { cyl_themeColor(forKey: "shadowColor") }
        @objc(cyl_setThemeShadowColor:) set { cyl_setThemeColor(newValue, forKey: "shadowColor") }
    }

    // MARK: - Private

    private var cyl_themeLayerColors: NSMutableDictionary? {
        objc_getAssociatedObject(self, &CALayer.cyl_themeLayerColorsKey) as? NSMutableDictionary
    }

    // [EN] The view this layer belongs to (its own delegate or a superlayer's). [CN] 本图层所属的视图（自身或上层图层的 delegate）。
    private var cyl_themeView: UIView? {
        var current: CALayer? = self
        while let layer = current {
            if let view = layer.delegate as? UIView {
                return view
            }
            current = layer.superlayer
        }
        return nil
    }

    private func applyThemeColor(_ color: UIColor, forKey key: String) {
        let traitCollection = cyl_themeView?.traitCollection ?? UITraitCollection.current
        setValue(color.resolvedColor(with: traitCollection).cgColor, forKey: key)
    }

    private func followTraitChanges(of view: UIView) {
        guard #available(iOS 17.0, *),
              objc_getAssociatedObject(self, &CALayer.cyl_themeTraitRegistrationKey) == nil else {
            return
        }
        // [EN] Theme colors are set on the main thread, as UIKit requires (the Objective-C version relied on it too).
        // [CN] 主题颜色在主线程上设置，这是 UIKit 的要求（Objective-C 版本同样依赖这一点）。
        let registration = MainActor.assumeIsolated {
            view.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: UIView, _) in
                self?.cyl_updateThemeColors()
            }
        }
        objc_setAssociatedObject(self, &CALayer.cyl_themeTraitRegistrationKey, registration, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
