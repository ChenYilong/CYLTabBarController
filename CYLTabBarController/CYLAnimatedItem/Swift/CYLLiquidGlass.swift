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
import CYLUtilsKit

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
     * [EN] For tests: forwards to `CYLUtils.liquidGlassActiveOverride`, the one copy of the rule (D2).
     * [CN] 供测试使用：转发到 `CYLUtils.liquidGlassActiveOverride`，规则的唯一一份（D2）。
     */
    nonisolated(unsafe) static var activeOverride: Bool? {
        get { CYLUtils.liquidGlassActiveOverride }
        set { CYLUtils.liquidGlassActiveOverride = newValue }
    }

    /**
     * [EN] Whether Liquid Glass is in use: asks `CYLUtils.isLiquidGlassActive()`.
     * [CN] 是否使用液态玻璃：询问 `CYLUtils.isLiquidGlassActive()`。
     */
    class func isActive() -> Bool {
        CYLUtils.isLiquidGlassActive()
    }
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
    required init?(coder _: NSCoder) {
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

/**
 * [EN] The one implementation of the background of an animated item (the flat color or Liquid Glass, the corner radius, the border),
 *      shared by `CYLAnimatedItemView` and `CYLAnimatedItemStackView`: both only keep the `item…` properties and call `apply`.
 *      `cylAnimatedItemCornerRadiusCapsule` is the capsule (half the height, following the size); any other value is points limited
 *      to half the height; unset is a capsule for Liquid Glass and square for flat.
 * [CN] 动效条目背景（纯色或液态玻璃、圆角、边框）的唯一实现，由 `CYLAnimatedItemView` 与 `CYLAnimatedItemStackView` 共用：二者只保存 `item…`
 *      属性并调用 `apply`。`cylAnimatedItemCornerRadiusCapsule` 为胶囊（半高，随尺寸变化）；其他值为点数，最大取半高；未设置时液态玻璃为胶囊、扁平为直角。
 */
final class CYLAnimatedItemBackgroundRenderer {

    private(set) var glassView: CYLLiquidGlassView?

    static func resolvedStyle(_ style: CYLAnimatedItemBackgroundStyle) -> CYLAnimatedItemBackgroundStyle {
        style == .liquidGlass && CYLAnimatedItemView.isLiquidGlassActive() ? .liquidGlass : .flat
    }

    /**
     * [EN] The tint a glass draws with: the host's color made translucent (its alpha times `glassTintAlpha`), so an opaque color such as a
     *      selected tag's green tints the glass instead of covering it (an opaque tint shows no glass at all). One rule for every host.
     * [CN] 玻璃使用的着色：宿主颜色变为半透明（其透明度乘以 `glassTintAlpha`），因此选中标签的绿色这样的不透明色是给玻璃着色，而不是盖住它（不透明的着色
     *      完全看不到玻璃）。所有宿主一个规则。
     */
    static let glassTintAlpha: CGFloat = 0.75

    /**
     * [EN] The tint of a glass whose host set no color: `CYLAnimatedItemView.defaultGlassTint` (a light frosted gray, 225, 222, 220 at alpha 0.10 in
     *      light mode, white at 0.04 in dark mode), low so that the interior stays clear and the lit edge shows, so `itemBackgroundStyle = .liquidGlass`
     *      alone is visible on a plain page. It is the tint as it is: it never takes the 0.75 share or `itemGlassTintAlpha`. Since 2026-11-26 the
     *      iOS values differ from the other platforms (Android, HarmonyOS, the mini program: 0.5 light, 0.14 dark) until they port the same default;
     *      the owner paused that port.
     * [CN] 宿主未设置颜色时玻璃的着色：`CYLAnimatedItemView.defaultGlassTint`（浅色模式为淡灰，225, 222, 220，透明度 0.10；深色模式为白色，透明度 0.04），
     *      透明度低，内部保持通透、亮边可见，因此只设置 `itemBackgroundStyle = .liquidGlass` 在纯色页面上也看得见。按原值使用：不乘 0.75 比例，也不受
     *      `itemGlassTintAlpha` 影响。自 2026-11-26 起 iOS 的数值与其他平台（Android、鸿蒙、小程序：浅色 0.5，深色 0.14）不同，直到它们移植同一默认值；
     *      所有者已暂停该移植。
     */
    static var defaultGlassTint: UIColor { CYLAnimatedItemView.defaultGlassTint }

    /**
     * [EN] nil, and a color that is fully transparent (alpha 0 after resolving a dynamic color for `traits`, e.g. `UIColor.clear`), both mean "no
     *      color": the default frosted tint. A host that clears its fill (a tag style's only "no color") gets the same visible glass.
     * [CN] nil 与完全透明的颜色（按 `traits` 解析动态色后透明度为 0，例如 `UIColor.clear`）都表示「没有颜色」：使用默认磨砂着色。把填充清除的宿主
     *      （标签样式唯一的「无颜色」）得到同样看得见的玻璃。
     */
    static func glassTint(_ color: UIColor?, traits: UITraitCollection = .current, tintAlpha: CGFloat? = nil) -> UIColor? {
        guard let color else { return defaultGlassTint }
        var alpha: CGFloat = 1
        color.resolvedColor(with: traits).getRed(nil, green: nil, blue: nil, alpha: &alpha)
        if alpha == 0 { return defaultGlassTint }
        return color.withAlphaComponent(alpha * (tintAlpha ?? glassTintAlpha))
    }

    /**
     * [EN] The content inset in use: `explicit` when set (0 included), else the glass constant where Liquid Glass is really drawn, 0 when flat.
     * [CN] 实际使用的内容内缩：已设置时为 `explicit`（包括 0），否则真正绘制液态玻璃时为玻璃常量，扁平时为 0。
     */
    static func resolvedContentHorizontalInset(_ explicit: CGFloat?, style: CYLAnimatedItemBackgroundStyle) -> CGFloat {
        explicit ?? (resolvedStyle(style) == .liquidGlass ? cylAnimatedItemLiquidGlassContentInset : 0)
    }

    func apply(on host: UIView, style: CYLAnimatedItemBackgroundStyle, color: UIColor?, cornerRadius: CGFloat?,
               borderWidth: CGFloat, borderColor: UIColor?, tintAlpha: CGFloat? = nil) {
        let resolved = Self.resolvedStyle(style)
        let height = host.bounds.height
        let radius: CGFloat
        if let requested = cornerRadius {
            radius = requested == cylAnimatedItemCornerRadiusCapsule ? height / 2 : min(max(requested, 0), height / 2)
        } else {
            radius = resolved == .liquidGlass ? height / 2 : 0
        }
        host.layer.cornerRadius = radius
        host.layer.borderWidth = borderWidth
        host.layer.borderColor = borderColor?.resolvedColor(with: host.traitCollection).cgColor
        var glassDrawn = false
        if resolved == .liquidGlass {
            let glass = glassView ?? CYLLiquidGlassView()
            glass.glassTintColor = Self.glassTint(color, traits: host.traitCollection, tintAlpha: tintAlpha)
            glass.cornerRadius = radius
            glass.frame = host.bounds
            if glass.superview == nil {
                host.insertSubview(glass, at: 0)
            }
            glassView = glass
            glassDrawn = glass.isGlassDrawn
        }
        if !glassDrawn {
            glassView?.removeFromSuperview()
            glassView = nil
        }
        host.backgroundColor = glassDrawn ? nil : color
    }
}
