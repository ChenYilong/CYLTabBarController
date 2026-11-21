//
//  CYLTabBar+CYLTabBarControllerExtention.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

/**
 * [EN] The object at `index`, or nil when `array` is nil or `index` is out of range (negative, `NSNotFound` or too large).
 * [CN] 返回 `index` 处的对象；`array` 为 nil 或 `index` 越界（负数、`NSNotFound` 或过大）时返回 nil。
 */
private func CYLObjectAtIndex<Element>(_ array: [Element]?, _ index: Int) -> Element? {
    guard let array, index >= 0, index < array.count else { return nil }
    return array[index]
}

private func CYLKey(_ name: String) -> UnsafeRawPointer {
    CYLUtilsKeys.key(name)
}

/**
 * [EN] `UITabBar (CYLTabBarControllerExtention)`: the Liquid Glass view tree of the system tab bar (platter, content, selected content,
 *      lens, portal) and sizes. Translated from Objective-C (docs/Swift-Migration.md, step 41). The declarations stay in
 *      `CYLTabBar+CYLTabBarControllerExtention.h`; these members are internal `@objc` methods with the declared selectors.
 *
 *      CYLTabBar
 *      └── _UITabBarPlatterView
 *          ├── SelectedContentView   (state shell)
 *          ├── _UILiquidLensView     (visual)
 *          └── ContentView           (the real container of the _UITabButtons; the middle one can be a hidden placeholder)
 *      └── CYLPlusButtonSubclass
 * [CN] `UITabBar (CYLTabBarControllerExtention)`：系统 TabBar 的液态玻璃视图树（platter、content、选中 content、透镜、portal）与尺寸。已从
 *      Objective-C 翻译（docs/Swift-Migration.md，第 41 步）。声明仍在 `CYLTabBar+CYLTabBarControllerExtention.h` 中；这些成员是使用已声明 selector
 *      的 internal `@objc` 方法。结构如上：SelectedContentView 为状态壳，_UILiquidLensView 为视觉，ContentView 才是真正容器（中间的 _UITabButton
 *      可能是隐藏的占位）。
 */
extension UITabBar {

    func cylPlatterViewWidth() -> CGFloat {
        CGFloat((objc_getAssociatedObject(self, CYLKey("cyl_platterViewWidth")) as? NSNumber)?.doubleValue ?? 0)
    }

    func cylSetPlatterViewWidth(_ width: CGFloat) {
        objc_setAssociatedObject(self, CYLKey("cyl_platterViewWidth"), NSNumber(value: Double(width)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func cylPlatterViewSize() -> NSValue? {
        objc_getAssociatedObject(self, CYLKey("cyl_platterViewSize")) as? NSValue
    }

    func cylSetPlatterViewSize(_ size: NSValue?) {
        objc_setAssociatedObject(self, CYLKey("cyl_platterViewSize"), size, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] The tab bar's content view: its platter view, else the tab bar. Objective-C reaches it through
     *      `-[UIView cyl_contentView]`, which dispatches here for a tab bar (one selector, see that method).
     * [CN] TabBar 的内容视图：其 platter 视图，否则为 TabBar 本身。Objective-C 通过 `-[UIView cyl_contentView]` 访问，
     *      该方法对 TabBar 分派到这里（同一个 selector，见该方法）。
     */
    func cylContentView() -> UIView {
        cylPlatterView() ?? self
    }

    /// [EN] Weak, as the header declares. [CN] 与头文件声明一致，弱引用。
    func cylPlatterView() -> UIView? {
        cyl_weakAssociatedObject(forKey: CYLKey("cyl_platterView")) as? UIView
    }

    func cylSetPlatterView(_ view: UIView?) {
        cyl_setWeakAssociatedObject(view, forKey: CYLKey("cyl_platterView"))
    }

    func cylPlatterContentView() -> UIView? {
        cyl_weakAssociatedObject(forKey: CYLKey("cyl_platterContentView")) as? UIView
    }

    func cylSetPlatterContentView(_ view: UIView?) {
        cyl_setWeakAssociatedObject(view, forKey: CYLKey("cyl_platterContentView"))
    }

    func cylPortalLayer() -> CALayer? {
        cyl_weakAssociatedObject(forKey: CYLKey("cyl_portalLayer")) as? CALayer
    }

    func cylSetPortalLayer(_ layer: CALayer?) {
        cyl_setWeakAssociatedObject(layer, forKey: CYLKey("cyl_portalLayer"))
    }

    func cylPortalView() -> UIView? {
        objc_getAssociatedObject(self, CYLKey("cyl_portalView")) as? UIView
    }

    func cylSetPortalView(_ view: UIView?) {
        objc_setAssociatedObject(self, CYLKey("cyl_portalView"), view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] The tab buttons: the subviews, or with Liquid Glass (iOS 26 and later) the controls of the platter's content view, in visual order.
     * [CN] Tab 按钮：子视图；液态玻璃（iOS 26 及以后）下为 platter 的 content view 中的控件，按视觉顺序。
     */
    func cylTabBarSubviews() -> [UIView] {
        if !CYLConstants.isLiquidGlassActive() {
            return subviews
        }
        // [EN] Before iOS 26, keep the original logic. [CN] iOS 26 以前，保持原逻辑。
        let isIOS26 = (UIDevice.current.systemVersion as NSString).floatValue >= 26
        if !isIOS26 && !CYLConstants.isUsedLiquidGlass() {
            return subviews
        }
        guard let platterView = cylPlatterView(), platterView.cyl_isPlatterView() else {
            return subviews
        }
        // [EN] Record the platter size. [CN] 记录 platter 尺寸。
        cylSetPlatterViewWidth(platterView.bounds.width)
        cylSetPlatterViewSize(NSValue(cgSize: platterView.bounds.size))
        // [EN] In the platter, the ContentView that actually hosts the tab buttons. [CN] 在 platter 中找真正承载 Tab 按钮的 ContentView。
        let contentView = platterView.subviews.first { $0.cyl_isPlatterContentView() }
        return cylAllTabViews(from: contentView) ?? subviews
    }

    func cylPlatterSelectedContentViewsWithoutPlusButton() -> [UIControl] {
        (cylPlatterSelectedContentViews() ?? []).filter { !$0.cyl_isPlusControl() }
    }

    /**
     * [EN] The controls of `contentView`, in visual order: by x in a horizontal bar; by vertical centre in the iOS 27.1 vertical bar (FIX:
     *      issue #653: while the selection lens animates the touched button widens and its x moves, so sorting by x shifted every index).
     * [CN] `contentView` 中的控件，按视觉顺序：横向栏按 x；iOS 27.1 竖向栏按垂直中心（FIX: issue #653：选中玻璃动画时被按下的按钮变宽、x 变小，
     *      按 x 排序会导致索引错位）。
     */
    @objc(cyl_allTabViewsFrom:)
    func cylAllTabViews(from contentView: UIView?) -> [UIView]? {
        guard let contentView else { return nil }
        let itemViews = contentView.subviews.filter { $0 is UIControl }
        let isVerticalBar = contentView.bounds.height > contentView.bounds.width
        return itemViews.sorted { first, second in
            if isVerticalBar {
                let dy = first.frame.midY - second.frame.midY
                return abs(dy) >= 0.5 && dy < 0
            }
            return first.frame.minX < second.frame.minX
        }
    }

    func cylFullHeight() -> CGFloat {
        CYLGetTabBarFullH(cylBoundsSize().height)
    }

    func cylBoundsSize() -> CGSize {
        let size = bounds.size
        if !CYLConstants.isLiquidGlassActive() {
            return CGSize(width: size.width, height: bounds.height - safeAreaInsets.bottom)
        }
        let isIOS26 = (UIDevice.current.systemVersion as NSString).floatValue >= 26
        if isIOS26 && (cyl_tabBarController?.noNeedUIDesignCompatibility ?? false) {
            _ = cylTabBarSubviews()
            let platterSize = cylPlatterViewSize()?.cgSizeValue ?? .zero
            if platterSize.width > 0 {
                return platterSize
            }
        }
        return size
    }

    func cylBoundsWidthOffset() -> CGFloat {
        CYLConstants.isLiquidGlassActive() ? (CYLScreenWidth() - cylBoundsSize().width) * 0.5 : 0
    }

    func cylPlatterViews() -> [UIView] {
        []
    }

    func cylPlatterView(withIndex index: Int) -> UIView? {
        CYLObjectAtIndex(cylPlatterViews(), index)
    }

    func cylPlatterContentViews() -> [UIView] {
        cylTabBarSubviews()
    }

    func cylPlatterContentView(withIndex index: Int) -> UIView? {
        CYLObjectAtIndex(cylPlatterContentViews(), index)
    }

    private func platterSubview(where test: (UIView) -> Bool) -> UIView? {
        cylPlatterView()?.subviews.first(where: test)
    }

    func cylPlatterSelectedContentView() -> UIView? {
        platterSubview { $0.cyl_isPlatterSelectedContentView() }
    }

    func cylPlatterSelectedContentViews() -> [UIControl]? {
        guard let contentView = cylPlatterSelectedContentView() else { return nil }
        return (cylAllTabViews(from: contentView) ?? subviews).compactMap { $0 as? UIControl }
    }

    func cylPlatterLiquidLensView() -> UIView? {
        platterSubview { $0.cyl_isPlatterLiquidLensView() }
    }

    func cylPlatterVisualProviderFloatingSelectedContentView() -> UIView? {
        platterSubview { $0.cyl_isPlatterVisualProviderFloatingSelectedContentView() }
    }

    func cylPlatterLiquidLensViewContentView() -> UIView? {
        if let source = cylPortalView()?.cyl_value(forKey: "sourceView") as? UIView {
            return source
        }
        var contentView: UIView?
        for sub in cylPlatterView()?.subviews ?? [] where sub.cyl_isPlatterLiquidLensView() {
            if let first = sub.subviews.first {
                contentView = first
            }
        }
        return contentView
    }

    func cylPlatterLiquidLensClearGlassView() -> UIView? {
        cylPlatterLiquidLensViewSubViews()?.first { $0.cyl_isPlatterLiquidLensClearGlassView() }
    }

    func cylPlatterLiquidLensViewSubViews() -> [UIView]? {
        cylPlatterLiquidLensViewContentView()?.subviews
    }

    func cylPlatterDestOutView() -> UIView? {
        platterSubview { $0.cyl_isPlatterDestOutView() }
    }

    func cylPlatterSelectedContentViewWithoutPlusButton(withIndex index: Int) -> UIControl? {
        CYLObjectAtIndex(cylPlatterSelectedContentViewsWithoutPlusButton(), index)
    }

    func cylPlatterSelectedContentView(withIndex index: Int) -> UIControl? {
        CYLObjectAtIndex(cylPlatterSelectedContentViews(), index)
    }

    func cylPlatterPortalViews() -> [UIView] {
        []
    }

    func cylPlatterPortalView(withIndex index: Int) -> UIView? {
        CYLObjectAtIndex(cylPlatterPortalViews(), index)
    }
}

/**
 * [EN] `CYLTabBar (CYLTabBarControllerExtention)`: the tab buttons of a CYLTabBar in logical order, the selected control, the layers of
 *      Liquid Glass matched by index, and the plus button label check. Translated from Objective-C (docs/Swift-Migration.md, step 41).
 * [CN] `CYLTabBar (CYLTabBarControllerExtention)`：CYLTabBar 按逻辑顺序排列的 Tab 按钮、选中的控件、按下标对应的液态玻璃图层，以及 PlusButton
 *      Label 的判断。已从 Objective-C 翻译（docs/Swift-Migration.md，第 41 步）。
 */
/**
 * [EN] The animation methods of `CYLTabBar` that only `UIControl+CYLTabBarItemAnimation.h` (a private header) declares.
 * [CN] 只在私有头文件 `UIControl+CYLTabBarItemAnimation.h` 中声明的 `CYLTabBar` 动画方法。
 */
@objc protocol CYLTabBarAnimationPrivateAPI {
    @objc(cyl_playTabBarItemAnimationWithSelectedControl:URL:size:defaultSelected:contentMode:)
    func cylPlayTabBarItemAnimation(withSelectedControl control: UIControl?, url: URL?, size: CGSize, defaultSelected: Bool, contentMode: UIView.ContentMode)
    @objc(cyl_stopAllTabBarItemAnimations) func cylStopAllTabBarItemAnimations()
}

extension CYLTabBar {

    private var cylAnimationPrivate: CYLTabBarAnimationPrivateAPI {
        unsafeBitCast(self as AnyObject, to: CYLTabBarAnimationPrivateAPI.self)
    }

    /// [EN] `-tabBarController`: its delegate, else `cyl_tabBarController`; nil before it is attached although declared nonnull. [CN] `-tabBarController`：其 delegate，否则为 `cyl_tabBarController`；虽声明为非空，加入前可能为 nil。
    private var owningTabBarController: CYLTabBarController? {
        (delegate as? CYLTabBarController) ?? cyl_tabBarController
    }

    /**
     * [EN] The plus child view controller is bound to the CYLTabBarController (by its `context`), so it is asked of the controller that owns
     *      this tab bar (its `delegate`), and checked against THAT controller's `viewControllers`.
     * [CN] PlusButton 子控制器绑定的是 CYLTabBarController（通过它的 `context`），因此向拥有本 TabBar 的控制器（它的 `delegate`）询问，并对 **该**
     *      控制器的 `viewControllers` 做检查。
     */
    @objc(cyl_hasPlusChildViewController)
    public func cylHasPlusChildViewController() -> Bool {
        let tabBarController = self.owningTabBarController
        guard let plusChild = CYLPlusButton.plusChildViewController(forOwner: tabBarController ?? self) else { return false }
        let isAdded = tabBarController?.viewControllers?.contains(plusChild) ?? false
        return isAdded && plusChild.cyl_plusViewControllerEverAdded
    }

    @objc(cyl_originalTabBarButtons)
    public func cylOriginalTabBarButtons() -> [UIView] {
        cylTabBarButtons(fromTabBarSubviews: cylSortedSubviews())
    }

    /**
     * [EN] Orders tab bar buttons in logical (view controller) order: left-to-right for LTR, right-to-left for RTL. FIX: issue #653 — in the
     *      iOS 27.1 vertical bar the tab buttons are no longer inside this tab bar and are stacked top to bottom: they are ordered by their
     *      vertical centre in window coordinates (the plus button stays in this tab bar, so a shared coordinate space is needed).
     * [CN] 按逻辑顺序（与子控制器顺序一致）排序：LTR 下从左到右，RTL 下从右到左。FIX: issue #653 — 竖向栏中 Tab 按钮不在本 TabBar 内且从上到下
     *      排列：按窗口坐标系中的垂直中心排序（加号按钮仍在本 TabBar 上，需统一坐标系）。
     */
    private func cylTabBarButtonIsOrderedBefore() -> (UIView, UIView) -> Bool {
        let isRightToLeft = cyl_isRightToLeftLayout()
        if let platterView = cylPlatterView(), platterView.window != nil, platterView.window === window,
           !platterView.isDescendant(of: self), platterView.bounds.height > platterView.bounds.width {
            return { first, second in
                let firstY = first.convert(CGPoint(x: first.bounds.midX, y: first.bounds.midY), to: nil).y
                let secondY = second.convert(CGPoint(x: second.bounds.midX, y: second.bounds.midY), to: nil).y
                return abs(firstY - secondY) >= 0.5 && firstY < secondY
            }
        }
        return { first, second in
            isRightToLeft ? first.frame.origin.x > second.frame.origin.x : first.frame.origin.x < second.frame.origin.x
        }
    }

    private func cylSortedSubviews() -> [UIView] {
        let all = cylTabBarSubviews()
        if all.isEmpty { return all }
        return all.filter { $0.cyl_isTabButton() }.sorted(by: cylTabBarButtonIsOrderedBefore())
    }

    private func cylTabBarButtons(fromTabBarSubviews tabBarSubviews: [UIView]) -> [UIView] {
        var buttons: [UIView] = []
        for (index, view) in tabBarSubviews.enumerated() where view.cyl_isTabButton() {
            buttons.append(view)
            (view as? UIControl)?.cyl_tabBarChildViewControllerIndex = index
        }
        return buttons
    }

    @objc(cyl_visibleControls)
    public func cylVisibleControls() -> [UIControl]? {
        // [EN] Typed as the former Objective-C header declared it. [CN] 类型与原 Objective-C 头文件的声明一致。
        cylVisibleViews()?.compactMap { $0 as? UIControl }
    }

    private func cylVisibleViews() -> [UIView]? {
        var original = cylOriginalTabBarButtons()
        if let plusButton = CYLPlusButton(forOwner: self), !original.contains(where: { $0 === plusButton }) {
            original.append(plusButton)
        }
        if original.isEmpty { return nil }
        return original.filter { $0.cyl_isTabButton() || (($0 as? UIControl)?.cyl_isPlusControl() ?? false) }.sorted(by: cylTabBarButtonIsOrderedBefore())
    }

    /**
     * [EN] The controls that match the view controllers. FIX: placeholder count mismatch — the plus button view itself is never a view
     *      controller's control, so it is left out; the slot's own tab button stays.
     * [CN] 与子控制器匹配的控件集合。FIX：占位导致的数量不匹配——PlusButton 视图本身从不对应任何控制器，因此去掉；slot 自己的 Tab 按钮保留。
     */
    @objc(cyl_subTabBarButtons)
    public func cylSubTabBarButtons() -> [UIControl] {
        // [EN] Typed as the former Objective-C header declared it. [CN] 类型与原 Objective-C 头文件的声明一致。
        cylSubTabBarButtonViews().compactMap { $0 as? UIControl }
    }

    private func cylSubTabBarButtonViews() -> [UIView] {
        if CYLConstants.isLiquidGlassActive() {
            return cylTabBarSubviews()
        }
        return (cylVisibleControls() ?? []).filter { !CYLPlusButton.isPlusButtonView($0) }
    }

    /**
     * [EN] The controls that match the system-style tab bar items. [CN] 与系统风格 TabBarItem 匹配的控件集合。
     */
    @objc(cyl_subTabBarButtonsWithoutPlusButton)
    public func cylSubTabBarButtonsWithoutPlusButton() -> [UIControl] {
        // [EN] Typed as the former Objective-C header declared it. [CN] 类型与原 Objective-C 头文件的声明一致。
        cylSubTabBarButtonViewsWithoutPlusButton().compactMap { $0 as? UIControl }
    }

    private func cylSubTabBarButtonViewsWithoutPlusButton() -> [UIView] {
        (cylVisibleControls() ?? []).filter { !$0.cyl_isPlusControl() }
    }

    /**
     * [EN] FIX: placeholder count mismatch — `tabIndex` is an index in `viewControllers`. First the tab button of that view controller itself;
     *      otherwise the tab buttons in order, without the plus button view: they match `viewControllers` one to one in every style.
     * [CN] FIX：占位导致的数量不匹配——`tabIndex` 是 `viewControllers` 中的下标。先直接取该控制器的 Tab 按钮；否则按顺序取去掉 PlusButton 视图后的
     *      Tab 按钮：在所有样式下都与 `viewControllers` 一一对应。
     */
    @objc(cyl_tabBarButtonWithTabIndex:)
    public func cylTabBarButton(withTabIndex tabIndex: UInt) -> UIControl? {
        if let viewControllers = owningTabBarController?.viewControllers, Int(tabIndex) < viewControllers.count,
           let tabButton = viewControllers[Int(tabIndex)].tabBarItem.cyl_tabButton, tabButton.superview != nil,
           !CYLPlusButton.isPlusButtonView(tabButton) {
            return tabButton
        }
        return CYLObjectAtIndex(cylSubTabBarButtons(), Int(tabIndex))
    }

    @objc(cyl_visibleControlWithIndex:)
    public func cylVisibleControl(withIndex index: UInt) -> UIControl? {
        CYLObjectAtIndex(cylVisibleControls(), Int(index))
    }

    /**
     * FIX: issue #604 — any animation library, through the `CYLTabBarItemAnimation` subspec when it is in the build.
     * [EN] Plays the tab icon animation. [CN] 播放 Tab 图标动画；任意动画库，构建中包含 `CYLTabBarItemAnimation` 子库时由它处理。
     */
    @objc(cyl_animationLottieImageWithSelectedControl:lottieURL:size:defaultSelected:contentMode:)
    public func cylAnimationLottieImage(selectedControl: UIControl?, lottieURL: URL?, size: CGSize, defaultSelected: Bool, contentMode: UIView.ContentMode) {
        guard CYLTabBarItemAnimationCore.service != nil else { return }
        cylAnimationPrivate.cylPlayTabBarItemAnimation(withSelectedControl: selectedControl, url: lottieURL, size: size, defaultSelected: defaultSelected, contentMode: contentMode)
    }

    @objc(cyl_stopAnimationOfAllLottieView)
    public func cylStopAnimationOfAllLottieView() {
        guard CYLTabBarItemAnimationCore.service != nil else { return }
        cylAnimationPrivate.cylStopAllTabBarItemAnimations()
    }

    /**
     * [EN] From the control of the current layer, its index; the control at that index in the selected layer. The control is the anchor, the
     *      index only assists (a plus button can shift indexes).
     * [CN] 从当前图层的控件得到下标，再取选中图层中该下标的控件。以控件为锚点，下标仅辅助（PlusButton 可能导致下标变化）。
     */
    @objc(cyl_selectedContentControlFromContentControl:)
    public func cylSelectedContentControl(fromContentControl contentControl: UIControl?) -> UIControl? {
        guard let contentControl, let index = cylSubTabBarButtons().firstIndex(where: { $0 === contentControl }) else { return nil }
        return cylPlatterSelectedContentView(withIndex: index)
    }

    @objc(cyl_normalContentControlFromSelectedContentControl:)
    public func cylNormalContentControl(fromSelectedContentControl selectedContentControl: UIControl) -> UIControl? {
        guard let index = cylPlatterSelectedContentViews()?.firstIndex(where: { $0 === selectedContentControl }) else { return nil }
        return CYLObjectAtIndex(cylSubTabBarButtons(), index)
    }

    @objc(cyl_cachedXOffsetWithIndex:)
    public func cylCachedXOffset(withIndex index: CGFloat) -> CGFloat {
        guard CYLConstants.isLiquidGlassActive() else { return 0 }
        let boundsWidthOffset = (cylBoundsSize().width - CYLScreenWidth()) * 0.5
        return index < CGFloat(plusButtonIndex()) ? boundsWidthOffset : abs(boundsWidthOffset)
    }

    @objc(cyl_cachedWidthOffsetWithIndex:)
    public func cylCachedWidthOffset(withIndex _: CGFloat) -> CGFloat {
        guard CYLConstants.isLiquidGlassActive() else { return 0 }
        let originalWidth = cylBoundsSize().width / CGFloat(cyl_tabbarItemsCount)
        return abs(originalWidth - cyl_tabBarItemWidth)
    }

    /**
     * [EN] The selected control, else the first control of the selected layer, the content layer or the visible controls (only controls
     *      count: the first subview of a classic tab bar can be a background view). Still nil when the tab bar has no control yet.
     * [CN] 选中的控件；否则取选中图层、content 图层或可见控件中的第一个控件（只接受控件：经典 TabBar 的第一个子视图可能是背景视图）。TabBar
     *      还没有任何控件时仍为 nil。
     */
    @objc(cyl_selectedControl)
    public func cylSelectedControl() -> UIControl? {
        if let selected = objc_getAssociatedObject(self, CYLKey("cyl_selectedControl")) as? UIControl {
            return selected
        }
        let candidates: [[UIView]] = [cylPlatterSelectedContentViews() ?? [], cylPlatterContentViews(), cylVisibleControls() ?? []]
        for list in candidates {
            if let control = list.first as? UIControl {
                return control
            }
        }
        return nil
    }

    @objc(cyl_setSelectedControl:)
    public func cylSetSelectedControl(_ control: UIControl?) {
        objc_setAssociatedObject(self, CYLKey("cyl_selectedControl"), control, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    @objc(cyl_selectedIndex)
    public func cyl_selectedIndex() -> Int {
        cylSelectedControl()?.cyl_tabBarItemVisibleIndex ?? 0
    }

    @objc(cyl_shouldUpdateHiddenStatueForPlusButtonLabel)
    public func cylShouldUpdateHiddenStatueForPlusButtonLabel() -> Bool {
        cylShouldUpdateHiddenStatueForPlusButtonLabel(for: owningTabBarController)
    }

    /**
     * [EN] YES on Liquid Glass when the plus button's label must be hidden: it has a child view controller and a label with text that it
     *      draws itself (FIX: issue #636, #641 — not when the tab item shows the title), and the app keeps the lens on it
     *      (`-tabBarController:shouldShowPlatterLiquidLensViewForControl:`) while the plus button is not laid out centred. Selecting the plus
     *      child view controller again (a repeated tap or a swipe) must not show the unselected label, or the labels overlap.
     * [CN] 液态玻璃下需要隐藏 PlusButton 的 Label 时返回 YES：它有子控制器，且有自己绘制、带文字的 Label（FIX: issue #636, #641 — TabBarItem 显示标题
     *      时不需要），并且 App 让透镜停在它上面（`-tabBarController:shouldShowPlatterLiquidLensViewForControl:`）、PlusButton 不是居中布局。再次选中
     *      PlusButton 子控制器（重复点击或滑动）时不显示未选中状态的 Label，否则会重叠。
     */
    @objc(cyl_shouldUpdateHiddenStatueForPlusButtonLabelForTabBarController:)
    public func cylShouldUpdateHiddenStatueForPlusButtonLabel(for theTabBarController: CYLTabBarController?) -> Bool {
        guard CYLConstants.isLiquidGlassActive() else { return false }
        let tabBarController = theTabBarController ?? self.owningTabBarController
        // [EN] Its own tab bar when that is a CYLTabBar, otherwise this one. [CN] 控制器自己的 TabBar 是 CYLTabBar 时用它，否则用本 TabBar。
        let tabBar = (tabBarController?.tabBar as? CYLTabBar) ?? self
        // [EN] The plus button and its child view controller are bound to the controller (by its `context`), so ask it.
        // [CN] PlusButton 和它的子控制器绑定的是控制器（通过它的 `context`），所以向它询问。
        let plusOwner: Any = tabBarController ?? self
        guard CYLPlusButton.plusChildViewController(forOwner: plusOwner) != nil, let plusButton = CYLPlusButton(forOwner: plusOwner),
              !plusButton.cyl_showsTitleInTabBarItem(), let text = plusButton.cyl_tabLabel()?.text, !text.isEmpty else {
            return false
        }
        let selector = NSSelectorFromString("tabBarController:shouldShowPlatterLiquidLensViewForControl:")
        guard let tabBarController, tabBarController.responds(to: selector), let implementation = tabBarController.method(for: selector) else {
            return false
        }
        typealias Function = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Bool
        let showsLens = unsafeBitCast(implementation, to: Function.self)(tabBarController, selector, tabBarController, plusButton)
        return showsLens && !tabBar.isPlusButtonLayoutCentered()
    }
}

// MARK: - Swift names of the former Objective-C category 原 Objective-C 类别的 Swift 名称

/**
 [EN] The names Swift code used while `CYLTabBar (CYLTabBarControllerExtention)` was declared in Objective-C (the importer's names
      of its selectors). Since `CYLTabBar` is Swift (docs/Swift-Migration.md step 100) that header is gone, so these forward to
      the members above; `@nonobjc`, as the selectors already belong to those members.
 [CN] `CYLTabBar (CYLTabBarControllerExtention)` 以 Objective-C 声明时 Swift 代码使用的名称（导入器为其 selector 生成的名称）。`CYLTabBar` 改为 Swift
      （docs/Swift-Migration.md 第 100 步）后该头文件已删除，因此这些名称转发给上方的成员；标记 `@nonobjc`，因为 selector 已属于那些成员。
 */
extension CYLTabBar {
    /** [EN] The selected tab button. [CN] 选中的 Tab 按钮。 */
    @nonobjc public var cyl_selectedControl: UIControl! {
        get { cylSelectedControl() }
        set { cylSetSelectedControl(newValue) }
    }
    /** [EN] The visible tab buttons and the plus button, by x. [CN] 按 x 排序的可见 Tab 按钮与 PlusButton。 */
    @nonobjc public func cyl_visibleControls() -> [UIControl]? { cylVisibleControls() }
    /** [EN] The tab buttons and the plus button. [CN] Tab 按钮与 PlusButton。 */
    @nonobjc public func cyl_subTabBarButtons() -> [UIControl] { cylSubTabBarButtons() }
    /** [EN] The tab buttons without the plus button. [CN] 不含 PlusButton 的 Tab 按钮。 */
    @nonobjc public func cyl_subTabBarButtonsWithoutPlusButton() -> [UIControl] {
        cylSubTabBarButtonsWithoutPlusButton()
    }
    /** [EN] The tab button at a tab index. [CN] 某个 Tab 下标的 Tab 按钮。 */
    @nonobjc public func cyl_tabBarButton(withTabIndex tabIndex: UInt) -> UIControl! { cylTabBarButton(withTabIndex: tabIndex) }
    /** [EN] The normal content control of a selected content control. [CN] 选中内容控件对应的普通内容控件。 */
    @nonobjc public func cyl_normalContentControl(fromSelectedContentControl control: UIControl) -> UIControl? {
        cylNormalContentControl(fromSelectedContentControl: control)
    }
    /** [EN] The selected content control of a content control. [CN] 内容控件对应的选中内容控件。 */
    @nonobjc public func cyl_selectedContentControl(fromContentControl control: UIControl?) -> UIControl? {
        cylSelectedContentControl(fromContentControl: control)
    }
    /** [EN] Plays a tab's animation. [CN] 播放 Tab 的动画。 */
    @nonobjc public func cyl_animationLottieImage(withSelectedControl selectedControl: UIControl?, lottieURL: URL?, size: CGSize,
                                                  defaultSelected: Bool, contentMode: UIView.ContentMode) {
        cylAnimationLottieImage(selectedControl: selectedControl, lottieURL: lottieURL, size: size, defaultSelected: defaultSelected,
                                contentMode: contentMode)
    }
    /** [EN] Stops every tab animation. [CN] 停止所有 Tab 动画。 */
    @nonobjc public func cyl_stopAnimationOfAllLottieView() { cylStopAnimationOfAllLottieView() }
    /** [EN] UIKit's tab buttons. [CN] UIKit 的 Tab 按钮。 */
    @nonobjc public func cyl_originalTabBarButtons() -> [Any] { cylOriginalTabBarButtons() }
    /** [EN] Whether the plus child view controller exists. [CN] PlusButton 子控制器是否存在。 */
    @nonobjc public func cyl_hasPlusChildViewController() -> Bool { cylHasPlusChildViewController() }
    /** [EN] The cached x offset of an index. [CN] 某个下标缓存的 x 偏移。 */
    @nonobjc public func cyl_cachedXOffset(withIndex index: CGFloat) -> CGFloat { cylCachedXOffset(withIndex: index) }
    /** [EN] The cached width offset of an index. [CN] 某个下标缓存的宽度偏移。 */
    @nonobjc public func cyl_cachedWidthOffset(withIndex index: CGFloat) -> CGFloat { cylCachedWidthOffset(withIndex: index) }
    /** [EN] Whether the plus button label's hidden state should be updated. [CN] 是否需要更新 PlusButton 标签的隐藏状态。 */
    @nonobjc public func cyl_shouldUpdateHiddenStatueForPlusButtonLabel() -> Bool { cylShouldUpdateHiddenStatueForPlusButtonLabel() }
}

// MARK: - The public API of `UITabBar (CYLTabBarControllerExtention)`

/**
 [EN] `UITabBar (CYLTabBarControllerExtention)` as Objective-C and Swift callers saw it in CYLTabBar+CYLTabBarControllerExtention.h:
      the same selectors and Swift names, forwarding to the implementation above. Public Swift since docs/Swift-Migration.md
      step 119; views the header declared nonnull are implicitly unwrapped (`UIView!`), so existing Swift code compiles and a
      missing view does not trap on return.
 [CN] Objective-C 与 Swift 调用方在 CYLTabBar+CYLTabBarControllerExtention.h 中看到的 `UITabBar (CYLTabBarControllerExtention)`：selector 与 Swift
      名称不变，转发到上面的实现。自第 119 步起为公开的 Swift；头文件中声明为非空的视图改为隐式解包（`UIView!`），现有 Swift 代码可以编译，缺少视图时
      返回也不会崩溃。
 */
extension UITabBar {

    /** [EN] The full height of the bar. [CN] TabBar 的完整高度。 */
    @objc(cyl_fullHeight) open func cyl_fullHeight() -> CGFloat { cylFullHeight() }
    /** [EN] The size of the bar's bounds. [CN] TabBar bounds 的尺寸。 */
    @objc(cyl_boundsSize) open func cyl_boundsSize() -> CGSize { cylBoundsSize() }
    /** [EN] The width offset of the bar's bounds. [CN] TabBar bounds 的宽度偏移。 */
    @objc(cyl_boundsWidthOffset) open func cyl_boundsWidthOffset() -> CGFloat { cylBoundsWidthOffset() }
    /** [EN] The Liquid Glass platter views. [CN] 液态玻璃的 platter 视图。 */
    @objc(cyl_platterViews) open func cyl_platterViews() -> [Any] { cylPlatterViews() }
    /** [EN] The platter view at `index`. [CN] 第 `index` 个 platter 视图。 */
    @objc(cyl_platterViewWithIndex:) open func cyl_platterView(with index: Int) -> UIView! { cylPlatterView(withIndex: index) }
    /** [EN] The tab controls of the platter. [CN] platter 中的 Tab 控件。 */
    @objc(cyl_platterContentViews) open func cyl_platterContentViews() -> [UIControl] { cylPlatterContentViews().compactMap { $0 as? UIControl } }
    /** [EN] The tab control at `index`. [CN] 第 `index` 个 Tab 控件。 */
    @objc(cyl_platterContentViewWithIndex:) open func cyl_platterContentView(with index: Int) -> UIControl! {
        cylPlatterContentView(withIndex: index) as? UIControl
    }
    /** [EN] The controls of the selected layer. [CN] 选中图层中的控件。 */
    @objc(cyl_platterSelectedContentViews) open func cyl_platterSelectedContentViews() -> [UIControl]? { cylPlatterSelectedContentViews() }
    /** [EN] The floating selected content view of the visual provider. [CN] visual provider 中浮动的选中内容视图。 */
    @objc(cyl_platterVisualProviderFloatingSelectedContentView) open func cyl_platterVisualProviderFloatingSelectedContentView() -> UIView? {
        cylPlatterVisualProviderFloatingSelectedContentView()
    }
    /** [EN] The selected-layer control at `index`. [CN] 选中图层中第 `index` 个控件。 */
    @objc(cyl_platterSelectedContentViewWithIndex:) open func cyl_platterSelectedContentView(with index: Int) -> UIControl! {
        cylPlatterSelectedContentView(withIndex: index)
    }
    /** [EN] The selected-layer control at `index`, the plus button left out. [CN] 选中图层中第 `index` 个控件，不计 PlusButton。 */
    @objc(cyl_platterSelectedContentViewWithoutPlusButttonWithIndex:)
    open func cyl_platterSelectedContentViewWithoutPlusButtton(with index: Int) -> UIControl! {
        cylPlatterSelectedContentViewWithoutPlusButton(withIndex: index)
    }
    /** [EN] The portal views. [CN] portal 视图。 */
    @objc(cyl_platterPortalViews) open func cyl_platterPortalViews() -> [Any] { cylPlatterPortalViews() }
    /** [EN] The portal view at `index`. [CN] 第 `index` 个 portal 视图。 */
    @objc(cyl_platterPortalViewWithIndex:) open func cyl_platterPortalView(with index: Int) -> UIView! { cylPlatterPortalView(withIndex: index) }
    /** [EN] The Liquid Glass lens. [CN] 液态玻璃的放大镜。 */
    @objc(cyl_platterLiquidLensView) open func cyl_platterLiquidLensView() -> UIView? { cylPlatterLiquidLensView() }
    /** [EN] The lens's subviews. [CN] 放大镜的子视图。 */
    @objc(cyl_platterLiquidLensViewSubViews) open func cyl_platterLiquidLensViewSubViews() -> [UIView]? { cylPlatterLiquidLensViewSubViews() }
    /** [EN] The lens's content view. [CN] 放大镜的内容视图。 */
    @objc(cyl_platterLiquidLensViewContentView) open func cyl_platterLiquidLensViewContentView() -> UIView? { cylPlatterLiquidLensViewContentView() }
    /** [EN] The dest-out view of the platter. [CN] platter 的 dest-out 视图。 */
    @objc(cyl_platterDestOutView) open func cyl_platterDestOutView() -> UIView? { cylPlatterDestOutView() }
    /** [EN] The lens's clear glass view. [CN] 放大镜的透明玻璃视图。 */
    @objc(cyl_platterLiquidLensClearGlassView) open func cyl_platterLiquidLensClearGlassView() -> UIView? { cylPlatterLiquidLensClearGlassView() }
    /** [EN] The selected content view of the platter. [CN] platter 的选中内容视图。 */
    @objc(cyl_platterSelectedContentView) open func cyl_platterSelectedContentView() -> UIView? { cylPlatterSelectedContentView() }

    /** [EN] The platter view, kept weakly. [CN] platter 视图，弱引用。 */
    @objc open weak var cyl_platterView: UIView? {
        @objc(cyl_platterView) get { cylPlatterView() }
        @objc(cyl_setPlatterView:) set { cylSetPlatterView(newValue) }
    }
    /** [EN] The portal view, kept weakly. [CN] portal 视图，弱引用。 */
    @objc open weak var cyl_portalView: UIView? {
        @objc(cyl_portalView) get { cylPortalView() }
        @objc(cyl_setPortalView:) set { cylSetPortalView(newValue) }
    }
    /** [EN] The platter's content view, kept weakly. [CN] platter 的内容视图，弱引用。 */
    @objc open weak var cyl_platterContentView: UIView? {
        @objc(cyl_platterContentView) get { cylPlatterContentView() }
        @objc(cyl_setPlatterContentView:) set { cylSetPlatterContentView(newValue) }
    }
    /** [EN] The platter's width. [CN] platter 的宽度。 */
    @objc open var cyl_platterViewWidth: CGFloat {
        @objc(cyl_platterViewWidth) get { cylPlatterViewWidth() }
        @objc(cyl_setPlatterViewWidth:) set { cylSetPlatterViewWidth(newValue) }
    }
    /** [EN] The platter's size, boxed. [CN] platter 的尺寸（包装形式）。 */
    @objc open var cyl_platterViewSize: NSValue! {
        @objc(cyl_platterViewSize) get { cylPlatterViewSize() }
        @objc(cyl_setPlatterViewSize:) set { cylSetPlatterViewSize(newValue) }
    }
    /** [EN] The portal layer, kept weakly. [CN] portal 图层，弱引用。 */
    @objc open weak var cyl_portalLayer: CALayer? {
        @objc(cyl_portalLayer) get { cylPortalLayer() }
        @objc(cyl_setPortalLayer:) set { cylSetPortalLayer(newValue) }
    }
    /** [EN] The selected-layer controls without the plus button. [CN] 选中图层中的控件，不含 PlusButton。 */
    @objc(cyl_platterSelectedContentViewsWithoutPlusButton) open func cyl_platterSelectedContentViewsWithoutPlusButton() -> [UIControl] {
        cylPlatterSelectedContentViewsWithoutPlusButton()
    }
    /** [EN] The tab controls of the bar. [CN] TabBar 中的 Tab 控件。 */
    @objc(cyl_tabBarSubviews) open func cyl_tabBarSubviews() -> [UIControl] { cylTabBarSubviews().compactMap { $0 as? UIControl } }
}
