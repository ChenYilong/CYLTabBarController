//
//  CYLLiquidGlass.swift
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] The Liquid Glass of CYLAnimatedItemView (`itemBackgroundStyle = .liquidGlass`), internal to the component: outside code
//       only imports CYLAnimatedItem and sets the view's `item…` properties. CYLUtils.isLiquidGlassActive() forwards to
//       `CYLAnimatedItemView.isLiquidGlassActive()`.
//  [CN] CYLAnimatedItemView 的液态玻璃（`itemBackgroundStyle = .liquidGlass`），组件内部实现：外部代码只需引入 CYLAnimatedItem 并设置视图的
//       `item…` 属性。CYLUtils.isLiquidGlassActive() 转发到 `CYLAnimatedItemView.isLiquidGlassActive()`。
//

import UIKit

/**
 * [EN] Whether the system draws Liquid Glass, the one rule every CYLTabBarController component asks (the tab bar's
 *      `CYLUtils.isLiquidGlassActive()` forwards here, and so do the tags of CollectionViewClassifyMenu): iOS 27 and
 *      later always; iOS 26 unless the app sets `UIDesignRequiresCompatibility` in its Info.plist. Read once.
 * [CN] 系统是否使用液态玻璃，CYLTabBarController 各组件共用的唯一规则（TabBar 的 `CYLUtils.isLiquidGlassActive()` 转发到这里，
 *      CollectionViewClassifyMenu 的标签也是）：iOS 27 及以上总是；iOS 26 上 App 未在 Info.plist 中设置
 *      `UIDesignRequiresCompatibility` 时。只读取一次。
 */
final class CYLLiquidGlass {

    /**
     * [EN] For tests: replaces the system check of `isActive()` (`nil`, the default, asks the system).
     * [CN] 供测试使用：替代 `isActive()` 对系统的检查（默认 `nil`，询问系统）。
     */
    nonisolated(unsafe) static var activeOverride: Bool?

    /**
     * [EN] Whether Liquid Glass is in use (see the class comment).
     * [CN] 是否使用液态玻璃（见类注释）。
     */
    class func isActive() -> Bool {
        activeOverride ?? systemDrawsLiquidGlass
    }

    private static let systemDrawsLiquidGlass: Bool = {
        if #available(iOS 27.0, *) {
            return true
        }
        if #available(iOS 26.0, *) {
            let requiresCompatibility = Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool
            return !(requiresCompatibility ?? false)
        }
        return false
    }()
}

/**
 * [EN] A Liquid Glass background for any view: a `UIVisualEffectView` with a `UIGlassEffect`, tinted with
 *      `glassTintColor` and clipped to `cornerRadius`. Where `CYLLiquidGlass.isActive()` is false, or before iOS 26,
 *      it draws nothing (no effect), so the caller keeps its flat background. It takes no touches and is hidden from
 *      accessibility.
 * [CN] 任意视图的液态玻璃背景：带 `UIGlassEffect` 的 `UIVisualEffectView`，以 `glassTintColor` 着色并按 `cornerRadius` 裁剪。
 *      `CYLLiquidGlass.isActive()` 为 false 或 iOS 26 以前不绘制任何效果，调用方保持其扁平背景。不接收触摸，对辅助功能隐藏。
 */
final class CYLLiquidGlassView: UIVisualEffectView {

    /**
     * [EN] The tint of the glass, e.g. a tag's background color; `nil` for none.
     * [CN] 玻璃的着色，例如标签的背景色；`nil` 表示不着色。
     */
    var glassTintColor: UIColor? {
        didSet { applyEffect() }
    }

    /**
     * [EN] The corner radius the glass is clipped to.
     * [CN] 玻璃裁剪所用的圆角半径。
     */
    var cornerRadius: CGFloat {
        get { layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }

    /**
     * [EN] Whether the glass is drawn now (`CYLLiquidGlass.isActive()` and iOS 26 or later); when false the caller
     *      draws its flat background.
     * [CN] 现在是否绘制玻璃（`CYLLiquidGlass.isActive()` 且 iOS 26 及以上）；为 false 时由调用方绘制扁平背景。
     */
    private(set) var isGlassDrawn = false

    init() {
        super.init(effect: nil)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        clipsToBounds = true
        applyEffect()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /**
     * [EN] Applies the effect again, e.g. after `CYLLiquidGlass.activeOverride` changed.
     * [CN] 重新应用效果，例如 `CYLLiquidGlass.activeOverride` 改变之后。
     */
    func applyEffect() {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), CYLLiquidGlass.isActive() {
            let glass = UIGlassEffect()
            glass.tintColor = glassTintColor
            effect = glass
            isGlassDrawn = true
            return
        }
        #endif
        effect = nil
        isGlassDrawn = false
    }
}
