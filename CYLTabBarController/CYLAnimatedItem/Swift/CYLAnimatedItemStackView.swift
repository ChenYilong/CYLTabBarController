//
//  CYLAnimatedItemStackView.swift
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if SWIFT_PACKAGE
// [EN] Swift Package Manager builds the Objective-C half (CYLAnimatedItemView) as its own module; CocoaPods and the Xcode
//      framework compile this file into that module.
// [CN] Swift Package Manager 把 Objective-C 部分（CYLAnimatedItemView）编译为独立模块；CocoaPods 与 Xcode framework 把本文件编译进该模块。
import CYLAnimatedItem
#endif

/**
 [EN] A centered vertical stack whose every element is a `CYLAnimatedItemView` (an animated icon and a title): an empty
      state, a placeholder, an onboarding card. The first item is the reserved one (the main icon and title); more items
      follow it: a hint, a button, a separator, an icon. A tap on an item performs its action (any string, e.g.
      "retry"), whose handler is given when the view is created or later; a tap anywhere else performs
      `backgroundAction`. Titles wrap to the view's width (set `titleLabel.numberOfLines` on an item, 0 for no limit).
      It is the generic form of CYLTableViewPlaceHolder's `CYLPlaceholderStackView`; scenarios and configuration files
      stay in that library. Objective-C: `@import CYLAnimatedItem;`, actions are `NSString`s.
 [CN] 每个元素都是 `CYLAnimatedItemView`（动效图标加标题）的居中竖向堆叠视图：空状态、占位图、引导卡片。第一个条目是保留条目（主图标与标题），
      其后可追加提示、按钮、分隔符、图标等条目。点击条目执行它的动作（任意字符串，例如 "retry"），动作的处理在创建时或之后指定；点击其他位置执行
      `backgroundAction`。标题按视图宽度换行（在条目上设置 `titleLabel.numberOfLines`，0 为不限行数）。它是 CYLTableViewPlaceHolder 中
      `CYLPlaceholderStackView` 的通用形式；场景与配置文件仍留在那个库中。Objective-C：`@import CYLAnimatedItem;`，动作为 `NSString`。
 */
@objc(CYLAnimatedItemStackView)
@objcMembers
open class CYLAnimatedItemStackView: UIView, UIGestureRecognizerDelegate {

    /**
     [EN] Runs on the main thread when an action is performed: a tap on an item, a tap on the background, or `performAction(_:)`.
     [CN] 执行动作时在主线程调用：点击条目、点击背景或调用 `performAction(_:)`。
     */
    public typealias ActionHandler = @convention(block) (CYLAnimatedItemStackView, String) -> Void

    // MARK: - Background 背景

    /**
     [EN] The background of the whole stack, the same rules as `CYLAnimatedItemView`: `.flat` (default) fills it with `itemBackgroundColor`;
          `.liquidGlass` draws Liquid Glass behind the items where the system draws it (`CYLAnimatedItemView.isLiquidGlassActive()`),
          flat elsewhere. Nothing is drawn until one of the `item…` background properties is set.
     [CN] 整个堆叠的背景，规则与 `CYLAnimatedItemView` 相同：`.flat`（默认）用 `itemBackgroundColor` 填充；`.liquidGlass` 在系统使用液态玻璃处
          于条目后面绘制液态玻璃，其他系统为扁平。设置任一 `item…` 背景属性之前不绘制任何背景。
     */
    public var itemBackgroundStyle: CYLAnimatedItemBackgroundStyle = .flat {
        didSet { if oldValue != itemBackgroundStyle { itemBackgroundDidChange() } }
    }

    /** [EN] The fill (flat) or the tint (glass). [CN] 填充色（扁平）或着色（玻璃）。 */
    public var itemBackgroundColor: UIColor? {
        didSet { if oldValue != itemBackgroundColor { itemBackgroundDidChange() } }
    }

    /**
     [EN] The corner radius: 0 is square, `cylAnimatedItemCornerRadiusCapsule` a capsule, any other value points limited to half the height;
          nil (the default) is a capsule for Liquid Glass and square for flat, as `CYLAnimatedItemView.itemCornerRadius`.
     [CN] 圆角半径：0 为直角，`cylAnimatedItemCornerRadiusCapsule` 为胶囊，其他值为点数且最大取半高；nil（默认）时液态玻璃为胶囊、扁平为直角，
          与 `CYLAnimatedItemView.itemCornerRadius` 相同。
     */
    public var itemCornerRadius: CGFloat? {
        didSet { if oldValue != itemCornerRadius { itemBackgroundDidChange() } }
    }

    /**
     [EN] The space between the OUTER border and the items, left and right only, added to `contentMargin` (top and bottom unchanged). nil (the default):
          `cylAnimatedItemLiquidGlassContentInset` where Liquid Glass is really drawn, 0 when flat; any number wins, including 0 on glass.
          Same rules as `CYLAnimatedItemView.itemContentHorizontalInset`.
     [CN] 外边框与条目之间的距离，仅左右，加在 `contentMargin` 上（上下不变）。nil（默认）：真正绘制液态玻璃时为 `cylAnimatedItemLiquidGlassContentInset`，
          扁平时为 0；任何数字都优先，包括液态玻璃上的 0。规则与 `CYLAnimatedItemView.itemContentHorizontalInset` 相同。
     */
    public var itemContentHorizontalInset: CGFloat? {
        didSet {
            guard oldValue != itemContentHorizontalInset else { return }
            updateMarginConstraints()
            setNeedsLayout()
        }
    }

    /**
     [EN] `itemContentHorizontalInset` for Objective-C: an `NSNumber` of points, nil for not set. [CN] 给 Objective-C 用的 `itemContentHorizontalInset`：点数的 `NSNumber`，nil 表示未设置。
     */
    public var itemContentHorizontalInsetNumber: NSNumber? {
        get { itemContentHorizontalInset.map { NSNumber(value: Double($0)) } }
        set { itemContentHorizontalInset = newValue.map { CGFloat($0.doubleValue) } }
    }

    /** [EN] The inset in use (see `itemContentHorizontalInset`). [CN] 实际使用的内缩（见 `itemContentHorizontalInset`）。 */
    public var resolvedItemContentHorizontalInset: CGFloat {
        CYLAnimatedItemBackgroundRenderer.resolvedContentHorizontalInset(itemContentHorizontalInset, style: itemBackgroundStyle)
    }

    /** [EN] The border width, 0 by default. [CN] 边框宽度，默认 0。 */
    public var itemBorderWidth: CGFloat = 0 {
        didSet { if oldValue != itemBorderWidth { itemBackgroundDidChange() } }
    }

    /** [EN] The border color. [CN] 边框颜色。 */
    public var itemBorderColor: UIColor? {
        didSet { if oldValue != itemBorderColor { itemBackgroundDidChange() } }
    }

    /**
     [EN] The share of the color's alpha that tints a Liquid Glass: nil (the default) is 0.75, so an opaque color tints the glass instead of
          covering it; 1 uses the color as it is (a selected tag keeps its full color, still glass). Not used by the flat style.
     [CN] 颜色透明度中用于给液态玻璃着色的比例：nil（默认）为 0.75，不透明的颜色是给玻璃着色而不是盖住它；1 表示按原色（选中的标签保持完整颜色，
          仍是玻璃）。扁平样式不使用。
     */
    public var itemGlassTintAlpha: CGFloat? {
        didSet { if oldValue != itemGlassTintAlpha { itemBackgroundDidChange() } }
    }

    /** [EN] The background really drawn (flat where the system draws no glass). [CN] 实际绘制的背景（系统不使用玻璃时为扁平）。 */
    public var resolvedItemBackgroundStyle: CYLAnimatedItemBackgroundStyle {
        CYLAnimatedItemBackgroundRenderer.resolvedStyle(itemBackgroundStyle)
    }

    /** [EN] The Liquid Glass layer behind the items while it is drawn; nil otherwise. [CN] 绘制时位于条目后面的液态玻璃层；否则为 nil。 */
    public var itemLiquidGlassView: UIView? { backgroundRenderer.glassView }

    private let backgroundRenderer = CYLAnimatedItemBackgroundRenderer()
    private var usesItemBackground = false

    private func itemBackgroundDidChange() {
        usesItemBackground = true
        layoutItemBackground()
        // [EN] The style decides the unset inset, hence the horizontal margin. [CN] 样式决定未设置时的内缩，也就决定左右边距。
        updateMarginConstraints()
        setNeedsLayout()
    }

    private func layoutItemBackground() {
        guard usesItemBackground else { return }
        backgroundRenderer.apply(on: self, style: itemBackgroundStyle, color: itemBackgroundColor, cornerRadius: itemCornerRadius,
                                 borderWidth: itemBorderWidth, borderColor: itemBorderColor, tintAlpha: itemGlassTintAlpha)
    }

    /**
     [EN] The vertical stack holding the items: centered, sized by its items, 16 pt between items by default.
     [CN] 容纳条目的竖向堆叠视图：居中，大小由条目决定，条目间距默认 16 pt。
     */
    public let stackView = UIStackView()

    /**
     [EN] Every item, top to bottom. [CN] 所有条目，自上而下。
     */
    public var itemViews: [CYLAnimatedItemView] { entries.map { $0.view } }

    /**
     [EN] The reserved first item (the main icon and title); nil while the stack is empty.
     [CN] 保留的第一个条目（主图标与标题）；堆叠为空时为 nil。
     */
    public var firstItemView: CYLAnimatedItemView? { entries.first?.view }

    /**
     [EN] The direction of the items: `.vertical` (default, a column) or `.horizontal` (one row). Wraps `stackView.axis`;
          `contentMargin` and each item's spacing before follow the axis.
     [CN] 条目的方向：`.vertical`（默认，一列）或 `.horizontal`（一行）。封装 `stackView.axis`；`contentMargin` 与每个条目之前的间距随方向变化。
     */
    public var axis: NSLayoutConstraint.Axis {
        get { stackView.axis }
        set {
            stackView.axis = newValue
            updateDividerLook()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /**
     [EN] The default space between items (16); an item's own spacing before replaces it. Wraps `stackView.spacing`.
     [CN] 条目之间的默认间距（16）；条目自己的前置间距优先。封装 `stackView.spacing`。
     */
    public var spacing: CGFloat {
        get { stackView.spacing }
        set {
            stackView.spacing = newValue
            refreshGaps()
        }
    }

    /**
     [EN] The default appearance of the items (icon tint per state, title attributes; `CYLAnimatedItemView.itemAppearance`), given
          to every item without one of its own, items appended later included; nil (default) gives none. Symbol images are
          templates, so their tint per state comes from here. Copied.
     [CN] 条目的默认外观（各状态的图标着色与标题属性；`CYLAnimatedItemView.itemAppearance`），交给每个没有自己外观的条目，包括之后追加的条目；
          nil（默认）不提供。SF Symbols 图片是模板图，各状态的着色由这里提供。会被复制。
     */
    @NSCopying public var itemAppearance: UITabBarItemAppearance? {
        didSet {
            entries.forEach { applyStackAppearance(to: $0) }
            updateDividerLook()
        }
    }

    /**
     [EN] The default `animationTint` of every item ("title" or "#RRGGBB" / "#RRGGBBAA"), existing and appended later; an item's own `animationTint`
          wins when it is set (non-empty), nil on the item inherits. Set back to nil it is removed from the items that did not set their own.
          Resolved inside the item against the item's own traits, with the truth table of `CYLAnimatedItemView.animationTint`. nil by default.
     [CN] 每个条目的默认 `animationTint`（"title" 或 "#RRGGBB" / "#RRGGBBAA"），包括之后追加的条目；条目自己的 `animationTint` 已设置（非空）时优先，
          条目上为 nil 则继承。改回 nil 时从没有自己设置的条目上移除。由条目用自己的 trait、按 `CYLAnimatedItemView.animationTint` 的真值表解析。默认 nil。
          [EN] Limits: the animation view is tinted only when `animationTint` is set or the rendering mode (automatic / alwaysTemplate / alwaysOriginal) asks; tab flows keep the
               file's own colors by default. `renderingMode=automatic` is the UNIFIED policy for every engine: a ONE-color file is tinted like "title", a multi-color file keeps its
               colors. One-color detection works for Lottie (fl/st colors within +-2/255) and GIF (first frame, 4-bit buckets, 98%); PAG, SVGA and Rive are UNDETECTABLE and are
               treated as multi-color (kept as they are). An explicit `tint=title` forces the template look on ANY engine, even a multi-color one (do not use it as a per-engine fix).
               One-color artwork whose color is not the icon color follows the item's effective icon color. A fixed `animationTint` is adapted (3:1) on drawn dark glass only, not on flat.
          [CN] 限制：只有设置了 `animationTint` 或渲染模式（automatic / alwaysTemplate / alwaysOriginal）要求时，动画视图才会着色；Tab 流程默认保持文件自己的颜色。
               `renderingMode=automatic` 是对所有引擎统一的策略：单色文件按 "title" 着色，多色文件保持原色。单色检测对 Lottie（fl/st 颜色在 +-2/255 内）与 GIF（首帧、4 位分桶、98%）有效；
               PAG、SVGA、Rive 无法检测，视为多色（保持原样）。显式 `tint=title` 会对任何引擎强制模板外观，即使是多色文件（不要把它当作按引擎的修补手段）。
               颜色不是图标颜色的单色素材跟随条目的有效图标颜色。固定的 `animationTint` 只在深色玻璃确实绘制时按 3:1 调整，扁平不调整。
     */
    public var animationTint: String? {
        didSet { if oldValue != animationTint { entries.forEach { applyInheritedValues(to: $0.view) } } }
    }

    /**
     [EN] The default `animationDarkTint` of every item, with the rules of `animationTint`. nil by default.
     [CN] 每个条目的默认 `animationDarkTint`，规则同 `animationTint`。默认 nil。
     */
    public var animationDarkTint: String? {
        didSet { if oldValue != animationDarkTint { entries.forEach { applyInheritedValues(to: $0.view) } } }
    }

    /**
     [EN] The default `animationRenderingMode` of every item (automatic, alwaysTemplate, alwaysOriginal), existing and appended later; an item's own
          non-automatic value wins. Applies only where the tint is unset. automatic by default.
     [CN] 每个条目的默认 `animationRenderingMode`（automatic、alwaysTemplate、alwaysOriginal），包括之后追加的条目；条目自己的非 automatic 值优先。
          只在着色未设置时生效。默认 automatic。
          [EN] Limits: the animation view is tinted only when `animationTint` is set or the rendering mode (automatic / alwaysTemplate / alwaysOriginal) asks; tab flows keep the
               file's own colors by default. `renderingMode=automatic` is the UNIFIED policy for every engine: a ONE-color file is tinted like "title", a multi-color file keeps its
               colors. One-color detection works for Lottie (fl/st colors within +-2/255) and GIF (first frame, 4-bit buckets, 98%); PAG, SVGA and Rive are UNDETECTABLE and are
               treated as multi-color (kept as they are). An explicit `tint=title` forces the template look on ANY engine, even a multi-color one (do not use it as a per-engine fix).
               One-color artwork whose color is not the icon color follows the item's effective icon color. A fixed `animationTint` is adapted (3:1) on drawn dark glass only, not on flat.
          [CN] 限制：只有设置了 `animationTint` 或渲染模式（automatic / alwaysTemplate / alwaysOriginal）要求时，动画视图才会着色；Tab 流程默认保持文件自己的颜色。
               `renderingMode=automatic` 是对所有引擎统一的策略：单色文件按 "title" 着色，多色文件保持原色。单色检测对 Lottie（fl/st 颜色在 +-2/255 内）与 GIF（首帧、4 位分桶、98%）有效；
               PAG、SVGA、Rive 无法检测，视为多色（保持原样）。显式 `tint=title` 会对任何引擎强制模板外观，即使是多色文件（不要把它当作按引擎的修补手段）。
               颜色不是图标颜色的单色素材跟随条目的有效图标颜色。固定的 `animationTint` 只在深色玻璃确实绘制时按 3:1 调整，扁平不调整。
     */
    public var animationRenderingMode: CYLAnimatedItemRenderingMode = .automatic {
        didSet { if oldValue != animationRenderingMode { entries.forEach { applyInheritedValues(to: $0.view) } } }
    }

    /**
     [EN] The color of the dividers, resolved by each divider with its own traits (a dynamic color follows light and dark; a fixed one is used as it
          is). nil (default): the EXPLICIT normal-state icon color of `itemAppearance` at alpha `cylAnimatedItemDividerAlpha` (0.6), else `UIColor.secondaryLabel`
          (about 3:1 on light and dark bars; re-resolved on every appearance change).
     [CN] 分隔条的颜色，由每条分隔条用自己的 trait 解析（动态颜色跟随浅色与深色；固定颜色原样使用）。nil（默认）：`itemAppearance` 普通状态的图标颜色
          加 `cylAnimatedItemDividerAlpha`（0.6）透明度，否则 `UIColor.secondaryLabel`（浅色与深色 Bar 上约 3:1；每次外观变化时重新解析）。
     */
    public var dividerColor: UIColor? {
        didSet { if oldValue != dividerColor { updateDividerLook() } }
    }

    /**
     [EN] The length of the dividers' line, `cylAnimatedItemDividerLength` (20) by default; the line is 1 pixel thick and centered in a slot of
          1 point by this length (swapped in a vertical stack).
     [CN] 分隔条线的长度，默认 `cylAnimatedItemDividerLength`（20）；线厚 1 像素，居中于 1 点乘该长度的槽中（竖向堆叠时对调）。
     */
    public var dividerLength: CGFloat = cylAnimatedItemDividerLength {
        didSet {
            dividerLength = max(0, dividerLength)
            if oldValue != dividerLength {
                updateDividerLook()
                invalidateIntrinsicContentSize()
            }
        }
    }

    /**
     [EN] Whether a divider is drawn between every two visible items (false by default). `setDividerAfter(_:_:)` overrides it for one gap.
          Never before the first or after the last visible item; a hidden item leaves no divider and no spacing.
     [CN] 是否在每两个可见条目之间绘制分隔条（默认 false）。`setDividerAfter(_:_:)` 可对单个间隙覆盖。第一个可见条目之前与最后一个可见条目之后从不绘制；
          隐藏的条目不留分隔条与间距。
     */
    public var showsDividers = false {
        didSet { if oldValue != showsDividers { refreshGaps() } }
    }

    /**
     [EN] The default space before a divider (between its owner item and the line); nil (default): `spacing`. A divider's own value wins.
     [CN] 分隔条之前的默认间距（所属条目与线之间）；nil（默认）：`spacing`。分隔条自己的值优先。
     */
    public var dividerSpacingBefore: CGFloat? {
        didSet { if oldValue != dividerSpacingBefore { refreshGaps() } }
    }

    /**
     [EN] The default space after a divider (between the line and the next visible item); nil (default): that item's `spacingBefore`, else `spacing`.
          A divider's own value wins.
     [CN] 分隔条之后的默认间距（线与下一个可见条目之间）；nil（默认）：该条目的 `spacingBefore`，否则 `spacing`。分隔条自己的值优先。
     */
    public var dividerSpacingAfter: CGFloat? {
        didSet { if oldValue != dividerSpacingAfter { refreshGaps() } }
    }

    /**
     [EN] Attaches a divider after the CURRENT LAST item (nothing happens on an empty stack): `append(camera); appendDivider(spacingBefore: 8,
          spacingAfter: 8); append(search)`. A nil spacing falls back to `dividerSpacingBefore` / `dividerSpacingAfter`, then as documented there.
          The gap is before + 1 + after (the next item's `spacingBefore` is never added on top: spacing 12 and a divider of 8 and 8 make 17).
     [CN] 在当前最后一个条目之后附加分隔条（空堆叠什么都不做）：`append(camera); appendDivider(spacingBefore: 8, spacingAfter: 8); append(search)`。
          间距为 nil 时依次回退到 `dividerSpacingBefore` / `dividerSpacingAfter`，再按那里的说明。间隙为 before + 1 + after（下一个条目的 `spacingBefore`
          从不叠加：spacing 为 12、分隔条 8 与 8 时间隙为 17）。
     */
    @nonobjc
    open func appendDivider(spacingBefore: CGFloat? = nil, spacingAfter: CGFloat? = nil) {
        guard let last = entries.last else { return }
        setDivider(after: last.view, spacingBefore: spacingBefore, spacingAfter: spacingAfter)
    }

    /**
     [EN] Puts a divider in the gap after `itemView` (with the spacings of `appendDivider`), even without `showsDividers`. The divider belongs to that
          item: it moves with it and goes when it is removed. Drawn only while the item is visible and a later visible item exists. Not in the stack: ignored.
     [CN] 在 `itemView` 之后的间隙放置分隔条（间距规则同 `appendDivider`），即使没有 `showsDividers`。分隔条属于该条目：随它移动，它被移除时一并消失。
          仅当该条目可见且后面有可见条目时绘制。条目不在堆叠中：忽略。
     */
    @nonobjc
    open func setDivider(after itemView: CYLAnimatedItemView, spacingBefore: CGFloat? = nil, spacingAfter: CGFloat? = nil) {
        guard let entry = entry(for: itemView) else { return }
        entry.dividerState = .on(before: spacingBefore, after: spacingAfter)
        refreshGaps()
    }

    /**
     [EN] Turns the gap after `itemView` off, also when `showsDividers` is true. Not in the stack: ignored.
     [CN] 关闭 `itemView` 之后的间隙分隔条，`showsDividers` 为 true 时也一样。条目不在堆叠中：忽略。
     */
    @objc(removeDividerAfterItemView:)
    open func removeDivider(after itemView: CYLAnimatedItemView) {
        guard let entry = entry(for: itemView) else { return }
        entry.dividerState = .off
        refreshGaps()
    }

    /**
     [EN] Whether a divider is configured after `itemView` (its own, else `showsDividers` unless removed). Whether it is drawn also depends on
          visibility (see `setDivider`). false for an item not in the stack.
     [CN] `itemView` 之后是否配置了分隔条（自己的，否则 `showsDividers`，除非已移除）。是否绘制还取决于可见性（见 `setDivider`）。条目不在堆叠中为 false。
     */
    @objc(hasDividerAfterItemView:)
    public func hasDivider(after itemView: CYLAnimatedItemView) -> Bool {
        guard let entry = entry(for: itemView) else { return false }
        return entry.hasDivider(showsDividers)
    }

    /**
     [EN] The dividers being drawn now, in order (not items: `itemViews` never holds them). They take no taps and VoiceOver skips them.
     [CN] 当前正在绘制的分隔条，按顺序（不是条目：`itemViews` 从不包含它们）。它们不接收点击，VoiceOver 跳过。
     */
    public var dividerViews: [UIView] { entries.compactMap { $0.dividerShown ? $0.divider : nil } }

    private func applyInheritedValues(to view: CYLAnimatedItemView) {
        view.inheritedAnimationTint = animationTint
        view.inheritedAnimationDarkTint = animationDarkTint
        view.inheritedAnimationRenderingMode = animationRenderingMode
    }

    /**
     [EN] The smallest space between the items and the view's edges (16 by default; 0 leaves no padding). [CN] 条目与视图边缘之间的最小间距（默认 16；0 表示没有内边距）。
     */
    public var contentMargin: CGFloat = 16 {
        didSet {
            contentMargin = max(0, contentMargin)
            invalidateIntrinsicContentSize()
            updateMarginConstraints()
            setNeedsLayout()
        }
    }

    /**
     [EN] The action of a tap anywhere outside a tappable item; nil (default) turns that off. VoiceOver reaches it through
          the first item when that item has no action of its own.
     [CN] 点击可点击条目以外任意位置时执行的动作；nil（默认）关闭。第一个条目没有自己的动作时，VoiceOver 通过它触发该动作。
     */
    public var backgroundAction: String? {
        didSet {
            if backgroundAction?.isEmpty == true { backgroundAction = nil; return }
            if backgroundAction != nil && backgroundTapRecognizer == nil {
                let recognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
                recognizer.delegate = self
                addGestureRecognizer(recognizer)
                backgroundTapRecognizer = recognizer
            }
            backgroundTapRecognizer?.isEnabled = backgroundAction != nil
            if let first = firstItemView { updateAccessibility(of: first) }
        }
    }

    /**
     [EN] Whether the stack runs an item's action when the item is tapped (true, default). false: each item handles its own
          tap (e.g. CYLTableViewPlaceHolder's components run their own tap handler), so the stack neither runs actions on
          item taps nor changes the items' `isUserInteractionEnabled`; it still performs the background tap (skipping items
          that `isItemViewInteractive(_:)` reports as interactive), `performAction(_:)` and the VoiceOver roles.
     [CN] 点击条目时堆叠视图是否执行其动作（true，默认）。false：每个条目自己处理点击（例如 CYLTableViewPlaceHolder 的组件运行自己的点击处理），
          堆叠视图既不在点击条目时执行动作，也不修改条目的 `isUserInteractionEnabled`；仍然处理背景点击（跳过 `isItemViewInteractive(_:)` 认为可交互的条目）、
          `performAction(_:)` 与 VoiceOver 角色。
     */
    public var dispatchesItemTaps = true {
        didSet {
            // [EN] A host that handles taps itself also keeps its own accessibility order. [CN] 自己处理点击的宿主也保持自己的无障碍顺序。
            shouldGroupAccessibilityChildren = dispatchesItemTaps
            updateInteractionOfItemViews()
        }
    }

    // MARK: - Private state 私有状态

    /// [EN] One item: its view, its action and the size fitted to the view's width. [CN] 一个条目：视图、动作与按视图宽度计算的尺寸约束。
    private final class Entry {
        let view: CYLAnimatedItemView
        var action: String?
        /// [EN] The space before the item (ignored for the first visible one). [CN] 条目之前的间距（第一个可见条目忽略）。
        var spacingBefore: CGFloat = 0
        /// [EN] The appearance the stack gave (the item's stored copy): the item's own appearance is any other. [CN] 堆叠视图给出的外观（条目保存的副本）：其他外观都是条目自己的。
        var givenAppearance: UITabBarItemAppearance?
        /// [EN] The divider after this item: unset (follows `showsDividers`), its own spacings, or removed. [CN] 此条目之后的分隔条：未设置（跟随 `showsDividers`）、自己的间距，或已移除。
        enum DividerState { case unset, on(before: CGFloat?, after: CGFloat?), off }
        var dividerState = DividerState.unset

        func hasDivider(_ showsDividers: Bool) -> Bool {
            switch dividerState {
            case .unset: return showsDividers
            case .on: return true
            case .off: return false
            }
        }

        var ownDividerSpacing: (before: CGFloat?, after: CGFloat?) {
            if case let .on(before, after) = dividerState { return (before, after) }
            return (nil, nil)
        }
        var divider: CYLAnimatedItemView?
        var dividerShown = false
        let width: NSLayoutConstraint
        let height: NSLayoutConstraint
        var observations: [NSKeyValueObservation] = []

        init(view: CYLAnimatedItemView) {
            self.view = view
            width = view.widthAnchor.constraint(equalToConstant: 0)
            height = view.heightAnchor.constraint(equalToConstant: 0)
            // [EN] Below required, so a stack narrower than an item compresses it instead of breaking constraints.
            // [CN] 低于 required：堆叠视图比条目窄时压缩条目，而不是破坏约束。
            width.priority = UILayoutPriority(UILayoutPriority.required.rawValue - 1)
            height.priority = width.priority
        }
    }

    private var entries: [Entry] = []
    private var handlers: [String: ActionHandler] = [:]
    private var backgroundTapRecognizer: UITapGestureRecognizer?
    private var marginConstraints: [NSLayoutConstraint] = []
    /// [EN] Set while the stack itself changes an item's accessibility, so its observations ignore that change.
    /// [CN] 堆叠视图自己修改条目的无障碍属性时设置，使其观察忽略该修改。
    private var updatingAccessibility = false

    // MARK: - Initializers 初始化

    /**
     [EN] A stack of `itemViews` (each with no action) and the handlers of `handlers`, keyed by action. An action without a
          handler does nothing. The label is `handlers:`, not `actions:`: a Swift subclass marked `@objcMembers` exposes
          inherited initializers to Objective-C, and `initWithItemViews:actions:` is taken by the Objective-C initializer.
     [CN] 由 `itemViews`（均无动作）组成的堆叠视图，以及按动作索引的 `handlers`。没有处理的动作什么都不做。参数标签是 `handlers:` 而不是 `actions:`：
          标记 `@objcMembers` 的 Swift 子类会把继承的构造器暴露给 Objective-C，而 `initWithItemViews:actions:` 已被 Objective-C 构造器占用。
     */
    @nonobjc
    public init(itemViews: [CYLAnimatedItemView], handlers: [String: ActionHandler]? = nil) {
        super.init(frame: .zero)
        setUp()
        handlers?.forEach { self.handlers[$0.key] = $0.value }
        itemViews.forEach { append($0, action: nil, spacingBefore: stackView.spacing) }
    }

    /**
     [EN] Objective-C: `-initWithItemViews:actions:`, the actions an `NSDictionary` of action names to blocks. Swift cannot
          cast such a dictionary to `[String: ActionHandler]`, so each block is converted here.
     [CN] Objective-C：`-initWithItemViews:actions:`，actions 是动作名称到 block 的 `NSDictionary`。Swift 无法把这种字典转换为
          `[String: ActionHandler]`，因此在这里逐个转换 block。
     */
    @objc(initWithItemViews:actions:)
    @available(swift, obsoleted: 1, message: "Use init(itemViews:handlers:)")
    public convenience init(objcItemViews itemViews: [CYLAnimatedItemView], actions: NSDictionary?) {
        var handlers: [String: ActionHandler] = [:]
        actions?.forEach { key, value in
            guard let action = key as? String else { return }
            handlers[action] = unsafeBitCast(value as AnyObject, to: ActionHandler.self)
        }
        self.init(itemViews: itemViews, handlers: handlers)
    }

    /**
     [EN] An empty stack without handlers. [CN] 没有处理的空堆叠视图。
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    /**
     [EN] An empty stack without handlers, from a storyboard or a nib. [CN] 来自 storyboard 或 nib 的空堆叠视图，没有处理。
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        // [EN] VoiceOver reads the items together, top to bottom, before what is behind the stack.
        // [CN] VoiceOver 自上而下连续朗读这些条目，再朗读堆叠视图后面的内容。
        shouldGroupAccessibilityChildren = true
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        updateMarginConstraints()
    }

    // MARK: - Items 条目

    /**
     [EN] Appends an item under the last one, `spacingBefore` points below it (ignored for the first item); a tap on it
          performs `action` when that is not nil. An item without an action does not take touches, so a tap on it reaches
          the background. An item already in the stack is left where it is.
     [CN] 在最后一个条目下方 `spacingBefore` 点处追加条目（第一个条目忽略该值）；`action` 不为 nil 时点击它执行该动作。没有动作的条目不接收触摸，
          点击会传给背景。已在堆叠中的条目保持原位。
     */
    @objc(appendItemView:action:spacingBefore:)
    open func append(_ itemView: CYLAnimatedItemView, action: String?, spacingBefore: CGFloat) {
        guard entry(for: itemView) == nil else { return }
        stackView.addArrangedSubview(itemView)
        let entry = Entry(view: itemView)
        entry.spacingBefore = max(0, spacingBefore)
        entries.append(entry)
        refreshGaps()
        applyInheritedValues(to: itemView)
        invalidateIntrinsicContentSize()
        itemView.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        observe(entry)
        setAction(action, for: itemView)
        applyStackAppearance(to: entry)
        fit(entry)
    }

    /// [EN] Gives the stack's appearance to an item that has none of its own. [CN] 把堆叠视图的外观交给没有自己外观的条目。
    private func applyStackAppearance(to entry: Entry) {
        let view = entry.view
        // [EN] Only an item without an appearance of its own (or still showing the one given here) takes the stack's. [CN] 只有自己没有外观（或仍显示这里给出的外观）的条目才使用堆叠视图的。
        guard view.itemAppearance == nil || view.itemAppearance === entry.givenAppearance else { return }
        guard itemAppearance != nil || entry.givenAppearance != nil else { return }
        view.applyInheritedItemAppearance(itemAppearance)
        entry.givenAppearance = view.itemAppearance
        // [EN] A subclass with its own colors puts them back (the hook is called after state changes too). [CN] 有自己颜色的子类把它们重新设置回去（状态变化之后也会调用该钩子）。
        view.itemStateDidChange()
    }

    /// [EN] Dividers and spacing after any change of the items: a divider sits right after an item when the gap to the next VISIBLE item has one;
    ///      the spaces around a divider are the stack's `spacing`, otherwise the next visible item's `spacingBefore`; a hidden item leaves none.
    /// [CN] 条目变化后更新分隔条与间距：到下一个可见条目的间隙有分隔条时，分隔条紧跟在条目之后；分隔条两侧的间距为堆叠视图的 `spacing`，否则为下一个可见条目的
    ///      `spacingBefore`；隐藏的条目不留间距。
    private func refreshGaps() {
        let visible = entries.filter { !$0.view.isHidden }
        for entry in entries {
            let isLastVisible = visible.last === entry
            let show = !entry.view.isHidden && !isLastVisible && entry.hasDivider(showsDividers)
            entry.dividerShown = show
            if show {
                let divider = entry.divider ?? makeDivider()
                entry.divider = divider
                var arranged = stackView.arrangedSubviews
                let at = arranged.firstIndex(of: entry.view).map { $0 + 1 } ?? arranged.count
                if !(at < arranged.count && arranged[at] === divider) {
                    if divider.superview != nil {
                        stackView.removeArrangedSubview(divider)
                        divider.removeFromSuperview()
                    }
                    arranged = stackView.arrangedSubviews
                    stackView.insertArrangedSubview(divider, at: (arranged.firstIndex(of: entry.view) ?? arranged.count - 1) + 1)
                }
            } else if let divider = entry.divider, divider.superview != nil {
                stackView.removeArrangedSubview(divider)
                divider.removeFromSuperview()
            }
        }
        for (index, entry) in entries.enumerated() {
            let next = entries[(index + 1)...].first { !$0.view.isHidden }
            if entry.dividerShown, let divider = entry.divider {
                // [EN] The exact gap: before + the line + after, on the owner item and on the divider. [CN] 精确的间隙：之前 + 线 + 之后，分别设在所属条目与分隔条上。
                let gap = dividerGap(of: entry, next: next)
                stackView.setCustomSpacing(gap.before, after: entry.view)
                stackView.setCustomSpacing(gap.after, after: divider)
            } else {
                stackView.setCustomSpacing(next?.spacingBefore ?? UIStackView.spacingUseDefault, after: entry.view)
            }
        }
        updateDividerLook()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// [EN] before = own ?? `dividerSpacingBefore` ?? `spacing`; after = own ?? `dividerSpacingAfter` ?? the next item's `spacingBefore` ?? `spacing`.
    /// [CN] before = 自己的 ?? `dividerSpacingBefore` ?? `spacing`；after = 自己的 ?? `dividerSpacingAfter` ?? 下一个条目的 `spacingBefore` ?? `spacing`。
    private func dividerGap(of entry: Entry, next: Entry?) -> (before: CGFloat, after: CGFloat) {
        let own = entry.ownDividerSpacing
        let before = own.before ?? dividerSpacingBefore ?? stackView.spacing
        let after = own.after ?? dividerSpacingAfter ?? next?.spacingBefore ?? stackView.spacing
        return (max(0, before), max(0, after))
    }

    /// [EN] A divider is an item view the stack makes and owns, in the item's internal divider mode; it gets the stack's values like any item.
    /// [CN] 分隔条是堆叠视图创建并拥有的条目视图，处于条目的内部分隔条模式；与其他条目一样接收堆叠视图的值。
    private func makeDivider() -> CYLAnimatedItemView {
        let divider = CYLAnimatedItemView(frame: .zero)
        divider.cylIsDivider = true
        return divider
    }

    private func updateDividerLook() {
        for entry in entries {
            guard let divider = entry.divider else { continue }
            divider.cylDividerIsVertical = axis == .horizontal
            divider.cylDividerLength = dividerLength
            divider.cylDividerColor = dividerColor
            applyInheritedValues(to: divider)
            if divider.itemAppearance == nil || divider.isItemAppearanceInherited { divider.applyInheritedItemAppearance(itemAppearance) }
        }
        invalidateIntrinsicContentSize()
    }

    /**
     [EN] Moves an item to `index` (clamped); an item not in the stack is ignored. The items' actions, spacing and accessibility stay.
     [CN] 把条目移到 `index`（超出范围时取边界）；不在堆叠中的条目被忽略。条目的动作、间距与无障碍保持不变。
     */
    @objc(moveItemView:toIndex:)
    open func move(_ itemView: CYLAnimatedItemView, to index: Int) {
        guard let from = entries.firstIndex(where: { $0.view === itemView }) else { return }
        let target = min(max(0, index), entries.count - 1)
        guard target != from else { return }
        let entry = entries.remove(at: from)
        entries.insert(entry, at: target)
        stackView.removeArrangedSubview(itemView)
        stackView.insertArrangedSubview(itemView, at: target)
        refreshGaps()
        entries.forEach { updateAccessibility(of: $0.view) }
    }

    /**
     [EN] Makes the stack hold exactly `itemViews`, in that order: missing ones are removed, new ones appended (no action, the default
          spacing), the others kept and moved.
     [CN] 让堆叠视图恰好容纳 `itemViews`，顺序一致：缺少的被移除，新的被追加（无动作、默认间距），其余保留并移动。
     */
    @objc(replaceItemViews:)
    open func replaceItemViews(_ itemViews: [CYLAnimatedItemView]) {
        entries.map { $0.view }.filter { view in !itemViews.contains { $0 === view } }.forEach { remove($0) }
        for (index, view) in itemViews.enumerated() {
            if entry(for: view) == nil {
                append(view, action: nil, spacingBefore: stackView.spacing)
            }
            move(view, to: index)
        }
    }

    /**
     [EN] Makes, appends and returns an item with the icon above the title and titles on as many lines as they need.
     [CN] 创建、追加并返回一个条目：图标在标题上方，标题按需多行显示。
     */
    @objc(appendItemWithTitle:image:animationURL:action:spacingBefore:)
    @discardableResult
    open func appendItem(title: String?, image: UIImage?, animationURL: URL?, action: String?,
                         spacingBefore: CGFloat) -> CYLAnimatedItemView {
        let itemView = CYLAnimatedItemView(frame: .zero)
        itemView.axis = .vertical
        itemView.titleLabel.numberOfLines = 0
        itemView.titleLabel.lineBreakMode = .byWordWrapping
        itemView.title = title
        itemView.image = image
        itemView.animationURL = animationURL
        append(itemView, action: action, spacingBefore: spacingBefore)
        return itemView
    }

    /**
     [EN] Removes an item from the stack (and from the view hierarchy). [CN] 从堆叠视图中移除条目（同时移出视图层级）。
     */
    @objc(removeItemView:)
    open func remove(_ itemView: CYLAnimatedItemView) {
        guard let index = entries.firstIndex(where: { $0.view === itemView }) else { return }
        let entry = entries.remove(at: index)
        entry.observations.forEach { $0.invalidate() }
        itemView.inheritedAnimationTint = nil
        itemView.inheritedAnimationDarkTint = nil
        itemView.inheritedAnimationRenderingMode = .automatic
        if itemView.itemAppearance === entry.givenAppearance { itemView.applyInheritedItemAppearance(nil) }
        itemView.removeTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        NSLayoutConstraint.deactivate([entry.width, entry.height])
        stackView.removeArrangedSubview(itemView)
        itemView.removeFromSuperview()
        if let divider = entry.divider, divider.superview != nil {
            stackView.removeArrangedSubview(divider)
            divider.removeFromSuperview()
        }
        refreshGaps()
        // [EN] A new first item may now carry the background action. [CN] 新的第一个条目可能需要承载背景动作。
        entries.forEach { updateAccessibility(of: $0.view) }
    }

    /**
     [EN] Sets or, with nil, removes the action of an item in the stack. [CN] 设置堆叠中某个条目的动作；传 nil 移除。
     */
    @objc(setAction:forItemView:)
    open func setAction(_ action: String?, for itemView: CYLAnimatedItemView) {
        guard let entry = entry(for: itemView) else { return }
        entry.action = (action?.isEmpty == false) ? action : nil
        updateInteraction(of: itemView)
    }

    /**
     [EN] Whether an item takes taps: its tap performs its action, a tap on it is not a background tap, and VoiceOver reads it
          as a button. By default: it has an action and it is enabled. Override for items with
          their own switch (CYLTableViewPlaceHolder's tap interaction), then call `updateInteractionOfItemViews()` after
          that switch changes.
     [CN] 条目是否接收点击：点击它执行其动作、点击它不算背景点击、VoiceOver 把它读作按钮。默认：有动作且可用。条目有自己的开关时
          （CYLTableViewPlaceHolder 的点击交互）重写本方法，并在开关变化后调用 `updateInteractionOfItemViews()`。
     */
    @objc(isItemViewInteractive:)
    open func isItemViewInteractive(_ itemView: CYLAnimatedItemView) -> Bool {
        action(for: itemView) != nil && itemView.isEnabled
    }

    /**
     [EN] Applies `isItemViewInteractive(_:)` again to every item (touches and VoiceOver role), after a change the stack cannot see.
     [CN] 在堆叠视图无法感知的变化之后，对所有条目重新应用 `isItemViewInteractive(_:)`（触摸与 VoiceOver 角色）。
     */
    @objc(updateInteractionOfItemViews)
    open func updateInteractionOfItemViews() {
        entries.forEach { updateInteraction(of: $0.view) }
    }

    /// [EN] Only an interactive item takes touches; the others let the background act.
    /// [CN] 只有可交互的条目接收触摸；其他条目让背景处理。
    private func updateInteraction(of itemView: CYLAnimatedItemView) {
        if dispatchesItemTaps { itemView.isUserInteractionEnabled = isItemViewInteractive(itemView) }
        updateAccessibility(of: itemView)
    }

    /**
     [EN] The action of an item; nil for none or an item not in the stack. [CN] 条目的动作；没有动作或条目不在堆叠中时为 nil。
     */
    @objc(actionForItemView:)
    public func action(for itemView: CYLAnimatedItemView) -> String? {
        entry(for: itemView)?.action
    }

    /**
     [EN] The first item whose tap performs `action`. [CN] 点击时执行 `action` 的第一个条目。
     */
    @objc(itemViewForAction:)
    public func itemView(for action: String) -> CYLAnimatedItemView? {
        entries.first { $0.action == action }?.view
    }

    private func entry(for itemView: CYLAnimatedItemView) -> Entry? {
        entries.first { $0.view === itemView }
    }

    /// [EN] Watches what changes an item's size or what VoiceOver reads. The item resets its accessibility traits when its
    ///      title, selection or enabled state changes, so they are applied again.
    /// [CN] 观察会改变条目尺寸或 VoiceOver 朗读内容的属性。条目在标题、选中或可用状态变化时会重置无障碍 traits，因此重新应用。
    private func observe(_ entry: Entry) {
        let view = entry.view
        let refit: (CYLAnimatedItemView) -> Void = { [weak self, weak entry] _ in
            guard let self = self, let entry = entry, !self.updatingAccessibility else { return }
            self.updateAccessibility(of: entry.view)
            self.fit(entry)
            self.invalidateIntrinsicContentSize()
        }
        let reread: (CYLAnimatedItemView) -> Void = { [weak self] view in
            guard let self = self, !self.updatingAccessibility else { return }
            self.updateAccessibility(of: view)
        }
        entry.observations = [
            view.observe(\.title) { v, _ in refit(v) },
            view.observe(\.isHidden) { [weak self] _, _ in self?.refreshGaps() },
            view.observe(\.image) { v, _ in refit(v) },
            view.observe(\.selectedImage) { v, _ in refit(v) },
            view.observe(\.animationURL) { v, _ in refit(v) },
            view.observe(\.iconSize) { v, _ in refit(v) },
            view.observe(\.axis) { v, _ in refit(v) },
            view.observe(\.spacing) { v, _ in refit(v) },
            view.observe(\.contentInsets) { v, _ in refit(v) },
            view.observe(\.accessoryView) { v, _ in refit(v) },
            view.observe(\.accessibilityLabel) { v, _ in reread(v) },
            view.observe(\.isSelected) { v, _ in reread(v) },
            view.observe(\.isEnabled) { [weak self] v, _ in
                guard let self = self, !self.updatingAccessibility else { return }
                self.updateInteraction(of: v)
            },
        ]
    }

    // MARK: - Actions 动作

    /**
     [EN] Sets or, with nil, removes the handler of an action. [CN] 设置动作的处理；传 nil 移除。
     */
    @objc(setHandler:forAction:)
    public func setHandler(_ handler: ActionHandler?, for action: String) {
        handlers[action] = handler
    }

    /**
     [EN] Runs the handler of `action`; false when it has none. [CN] 执行 `action` 的处理；没有处理时返回 false。
     */
    @objc(performAction:)
    @discardableResult
    public func performAction(_ action: String) -> Bool {
        guard let handler = handlers[action] else { return false }
        handler(self, action)
        return true
    }

    @objc(cyl_itemTapped:) private func itemTapped(_ itemView: CYLAnimatedItemView) {
        guard dispatchesItemTaps, isItemViewInteractive(itemView) else { return }
        if let action = action(for: itemView) { performAction(action) }
    }

    @objc(cyl_backgroundTapped:) private func backgroundTapped(_: UITapGestureRecognizer) {
        if let action = backgroundAction { performAction(action) }
    }

    /**
     [EN] The background recognizer ignores touches on an item with an action (that item handles its own tap).
     [CN] 背景手势忽略落在带动作条目上的触摸（该条目自己处理点击）。
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === backgroundTapRecognizer else { return true }
        var view = touch.view
        while let current = view, current !== self {
            if let item = current as? CYLAnimatedItemView, isItemViewInteractive(item) { return false }
            view = current.superview
        }
        return true
    }

    /**
     [EN] VoiceOver activation performs the background action. [CN] VoiceOver 激活时执行背景动作。
     */
    open override func accessibilityActivate() -> Bool {
        guard let action = backgroundAction else { return false }
        return performAction(action)
    }

    // MARK: - Accessibility 无障碍

    /// [EN] An item with an action is a button; one without is static text; one with nothing to read (no title, no label,
    ///      no action) is decoration and hidden from VoiceOver. The first item reads as a button for the background action.
    /// [CN] 带动作的条目是按钮；没有动作的是静态文字；没有可朗读内容（无标题、无标签、无动作）的是装饰，对 VoiceOver 隐藏。第一个条目可作为背景动作的按钮。
    private func updateAccessibility(of itemView: CYLAnimatedItemView) {
        updatingAccessibility = true
        defer { updatingAccessibility = false }
        let acts = isItemViewInteractive(itemView)
        let actsOnBackground = !acts && itemView === firstItemView && backgroundAction != nil
        var traits = itemView.accessibilityTraits
        traits.remove([.button, .staticText])
        traits.insert(acts || actsOnBackground ? .button : .staticText)
        itemView.accessibilityTraits = traits
        let reads = acts || actsOnBackground || !(itemView.accessibilityLabel ?? "").isEmpty
        itemView.isAccessibilityElement = reads
        itemView.accessibilityElementsHidden = !reads
    }

    // MARK: - Layout 布局

    /// [EN] `contentMargin` plus the content inset, left and right. [CN] 左右的 `contentMargin` 加内容内缩。
    private var horizontalMargin: CGFloat { contentMargin + resolvedItemContentHorizontalInset }

    private func updateMarginConstraints() {
        NSLayoutConstraint.deactivate(marginConstraints)
        marginConstraints = [
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: horizontalMargin),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: contentMargin),
        ]
        NSLayoutConstraint.activate(marginConstraints)
    }

    private var itemMaxWidth: CGFloat {
        bounds.width > 0 ? max(0, bounds.width - 2 * horizontalMargin) : 0
    }

    /// [EN] Sizes an item for the view's width, so a long title wraps instead of widening the stack.
    /// [CN] 按视图宽度计算条目尺寸，长标题换行而不是撑宽堆叠视图。
    private func fit(_ entry: Entry) {
        let maxWidth = itemMaxWidth
        guard maxWidth > 0 else {
            NSLayoutConstraint.deactivate([entry.width, entry.height])
            return
        }
        let size = entry.view.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        entry.width.constant = min(size.width, maxWidth)
        entry.height.constant = size.height
        NSLayoutConstraint.activate([entry.width, entry.height])
    }

    /**
     [EN] The stack hugs its items: each visible item at its own size (a hidden one counts for nothing, nor does its spacing), the spaces
          between them, and `contentMargin` around. It follows Dynamic Type through the items' sizes.
     [CN] 堆叠视图紧贴条目：每个可见条目取自己的尺寸（隐藏的条目及其间距不计），加上条目之间的间距与四周的 `contentMargin`。通过条目的尺寸跟随动态字体。
     */
    open override var intrinsicContentSize: CGSize {
        let limit = itemMaxWidth > 0 ? itemMaxWidth : CGFloat.greatestFiniteMagnitude
        let visible = entries.filter { !$0.view.isHidden }
        var main: CGFloat = 0
        var cross: CGFloat = 0
        let horizontal = axis == .horizontal
        for (index, entry) in visible.enumerated() {
            let size = entry.view.sizeThatFits(CGSize(width: limit, height: .greatestFiniteMagnitude))
            main += horizontal ? size.width : size.height
            cross = max(cross, horizontal ? size.height : size.width)
            if index > 0 {
                let previous = visible[index - 1]
                if previous.dividerShown {
                    let gap = dividerGap(of: previous, next: entry)
                    main += gap.before + 1 + gap.after
                    cross = max(cross, dividerLength)
                } else {
                    main += entry.spacingBefore
                }
            }
        }
        let margins = CGSize(width: 2 * horizontalMargin, height: 2 * contentMargin)
        return horizontal ? CGSize(width: main + margins.width, height: cross + margins.height)
                          : CGSize(width: cross + margins.width, height: main + margins.height)
    }

    open override func layoutSubviews() {
        entries.forEach(fit)
        super.layoutSubviews()
        layoutItemBackground()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // [EN] Dynamic Type changes the titles' heights. [CN] 动态字体会改变标题高度。
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
}
