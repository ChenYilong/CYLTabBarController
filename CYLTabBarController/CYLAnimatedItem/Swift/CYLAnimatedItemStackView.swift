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
                let recognizer = UITapGestureRecognizer(target: self, action: #selector(cyl_backgroundTapped(_:)))
                recognizer.delegate = self
                addGestureRecognizer(recognizer)
                backgroundTapRecognizer = recognizer
            }
            backgroundTapRecognizer?.isEnabled = backgroundAction != nil
            if let first = firstItemView { updateAccessibility(of: first) }
        }
    }

    // MARK: - Private state 私有状态

    /// [EN] One item: its view, its action and the size fitted to the view's width. [CN] 一个条目：视图、动作与按视图宽度计算的尺寸约束。
    private final class Entry {
        let view: CYLAnimatedItemView
        var action: String?
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
     [EN] A stack of `itemViews` (each with no action) and the handlers of `actions`. An action without a handler does nothing.
     [CN] 由 `itemViews`（均无动作）组成的堆叠视图，以及 `actions` 中的处理。没有处理的动作什么都不做。
     */
    @nonobjc
    public init(itemViews: [CYLAnimatedItemView], actions: [String: ActionHandler]? = nil) {
        super.init(frame: .zero)
        setUp()
        actions?.forEach { handlers[$0.key] = $0.value }
        itemViews.forEach { append($0, action: nil, spacingBefore: stackView.spacing) }
    }

    /**
     [EN] Objective-C: `-initWithItemViews:actions:`, the actions an `NSDictionary` of action names to blocks. Swift cannot
          cast such a dictionary to `[String: ActionHandler]`, so each block is converted here.
     [CN] Objective-C：`-initWithItemViews:actions:`，actions 是动作名称到 block 的 `NSDictionary`。Swift 无法把这种字典转换为
          `[String: ActionHandler]`，因此在这里逐个转换 block。
     */
    @objc(initWithItemViews:actions:)
    @available(swift, obsoleted: 1, message: "Use init(itemViews:actions:)")
    public convenience init(objcItemViews itemViews: [CYLAnimatedItemView], actions: NSDictionary?) {
        var handlers: [String: ActionHandler] = [:]
        actions?.forEach { key, value in
            guard let action = key as? String else { return }
            handlers[action] = unsafeBitCast(value as AnyObject, to: ActionHandler.self)
        }
        self.init(itemViews: itemViews, actions: handlers)
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
        entries.append(entry)
        itemView.addTarget(self, action: #selector(cyl_itemTapped(_:)), for: .touchUpInside)
        observe(entry)
        setAction(action, for: itemView)
        fit(entry)
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
        itemView.removeTarget(self, action: #selector(cyl_itemTapped(_:)), for: .touchUpInside)
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
        // [EN] Only an item with an action takes touches; the others let the background act.
        // [CN] 只有带动作的条目接收触摸；其他条目让背景处理。
        itemView.isUserInteractionEnabled = entry.action != nil
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
            view.observe(\.isEnabled) { v, _ in reread(v) },
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

    @objc private func cyl_itemTapped(_ itemView: CYLAnimatedItemView) {
        if let action = action(for: itemView) { performAction(action) }
    }

    @objc private func cyl_backgroundTapped(_ recognizer: UITapGestureRecognizer) {
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
            if let item = current as? CYLAnimatedItemView, action(for: item) != nil { return false }
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
        let acts = action(for: itemView) != nil
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
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // [EN] Dynamic Type changes the titles' heights. [CN] 动态字体会改变标题高度。
        setNeedsLayout()
    }
}
