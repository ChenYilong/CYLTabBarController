//
//  CYLAnimatedItemStackView.swift
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
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
     [EN] The corner radius: 0 is square, `CYLAnimatedItemCornerRadiusCapsule` a capsule, any other value points limited to half the height;
          nil (the default) is a capsule for Liquid Glass and square for flat, as `CYLAnimatedItemView.itemCornerRadius`.
     [CN] 圆角半径：0 为直角，`CYLAnimatedItemCornerRadiusCapsule` 为胶囊，其他值为点数且最大取半高；nil（默认）时液态玻璃为胶囊、扁平为直角，
          与 `CYLAnimatedItemView.itemCornerRadius` 相同。
     */
    public var itemCornerRadius: CGFloat? {
        didSet { if oldValue != itemCornerRadius { itemBackgroundDidChange() } }
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
     [EN] The smallest space between the items and the view's edges (16 by default). [CN] 条目与视图边缘之间的最小间距（默认 16）。
     */
    /**
     [EN] The direction of the items: `.vertical` (default, a column) or `.horizontal` (one row). Wraps `stackView.axis`;
          `contentMargin` and each item's spacing before follow the axis.
     [CN] 条目的方向：`.vertical`（默认，一列）或 `.horizontal`（一行）。封装 `stackView.axis`；`contentMargin` 与每个条目之前的间距随方向变化。
     */
    public var axis: NSLayoutConstraint.Axis {
        get { stackView.axis }
        set {
            stackView.axis = newValue
            setNeedsLayout()
        }
    }

    /**
     [EN] The default space between items (16); an item's own spacing before replaces it. Wraps `stackView.spacing`.
     [CN] 条目之间的默认间距（16）；条目自己的前置间距优先。封装 `stackView.spacing`。
     */
    public var spacing: CGFloat {
        get { stackView.spacing }
        set { stackView.spacing = newValue }
    }

    /**
     [EN] The default appearance of the items (icon tint per state, title attributes; `CYLAnimatedItemView.itemAppearance`), given
          to every item without one of its own, items appended later included; nil (default) gives none. Symbol images are
          templates, so their tint per state comes from here. Copied.
     [CN] 条目的默认外观（各状态的图标着色与标题属性；`CYLAnimatedItemView.itemAppearance`），交给每个没有自己外观的条目，包括之后追加的条目；
          nil（默认）不提供。SF Symbols 图片是模板图，各状态的着色由这里提供。会被复制。
     */
    @NSCopying public var itemAppearance: UITabBarItemAppearance? {
        didSet { entries.forEach { applyStackAppearance(to: $0) } }
    }

    public var contentMargin: CGFloat = 16 {
        didSet {
            contentMargin = max(0, contentMargin)
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
        didSet { updateInteractionOfItemViews() }
    }

    // MARK: - Private state 私有状态

    /// [EN] One item: its view, its action and the size fitted to the view's width. [CN] 一个条目：视图、动作与按视图宽度计算的尺寸约束。
    private final class Entry {
        let view: CYLAnimatedItemView
        var action: String?
        /// [EN] The item shows the stack's `itemAppearance` (it had none of its own). [CN] 条目显示堆叠视图的 `itemAppearance`（它自己没有）。
        var usesStackAppearance = false
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
        let previous = stackView.arrangedSubviews.last
        stackView.addArrangedSubview(itemView)
        if let previous = previous { stackView.setCustomSpacing(max(0, spacingBefore), after: previous) }
        let entry = Entry(view: itemView)
        entry.usesStackAppearance = itemView.itemAppearance == nil
        entries.append(entry)
        itemView.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        observe(entry)
        setAction(action, for: itemView)
        applyStackAppearance(to: entry)
        fit(entry)
    }

    /// [EN] Gives the stack's appearance to an item that has none of its own. [CN] 把堆叠视图的外观交给没有自己外观的条目。
    private func applyStackAppearance(to entry: Entry) {
        guard entry.usesStackAppearance else { return }
        entry.view.itemAppearance = itemAppearance
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
        itemView.removeTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        NSLayoutConstraint.deactivate([entry.width, entry.height])
        stackView.removeArrangedSubview(itemView)
        itemView.removeFromSuperview()
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
        }
        let reread: (CYLAnimatedItemView) -> Void = { [weak self] view in
            guard let self = self, !self.updatingAccessibility else { return }
            self.updateAccessibility(of: view)
        }
        entry.observations = [
            view.observe(\.title) { v, _ in refit(v) },
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

    private func updateMarginConstraints() {
        NSLayoutConstraint.deactivate(marginConstraints)
        marginConstraints = [
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: contentMargin),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: contentMargin),
        ]
        NSLayoutConstraint.activate(marginConstraints)
    }

    private var itemMaxWidth: CGFloat {
        bounds.width > 0 ? max(0, bounds.width - 2 * contentMargin) : 0
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

    open override func layoutSubviews() {
        entries.forEach(fit)
        super.layoutSubviews()
        layoutItemBackground()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // [EN] Dynamic Type changes the titles' heights. [CN] 动态字体会改变标题高度。
        setNeedsLayout()
    }
}
