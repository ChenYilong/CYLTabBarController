//
//  UIView+CYLTabBarControllerExtention.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] `UIView (CYLTabBarControllerExtention)`, `(CYLTabBarControllerExtentionDeprecated)` and `(CYLTabBarMetrics)`: how the
 *      library recognizes the views of UIKit's tab bar (tab buttons, their icon and title, the Liquid Glass platter and lens),
 *      finds them, and keeps per tab bar metrics. Translated from Objective-C (docs/Swift-Migration.md, step 25); every
 *      declared selector and Swift name is kept. Removed, as dead code nothing declared or called: the `-cyl_invokeSelector:…`
 *      methods (`NSInvocation` and C varargs, which Swift does not have), the transform-corner helpers (`-cyl_newTopLeft`…),
 *      `-cyl_otherImageViewViewInTabBarButton` and `-cyl_isTabEffectContentView`.
 * [CN] `UIView (CYLTabBarControllerExtention)`、`(CYLTabBarControllerExtentionDeprecated)` 与 `(CYLTabBarMetrics)`：本库如何识别
 *      UIKit TabBar 的视图（Tab 按钮及其图标与标题、液态玻璃 platter 与放大镜）、查找它们，并保存每个 TabBar 的尺寸信息。已从 Objective-C
 *      翻译（docs/Swift-Migration.md，第 25 步），保留所有已声明的 selector 与 Swift 名称。删除了没有声明、也没有调用方的死代码：
 *      `-cyl_invokeSelector:…` 方法（使用 Swift 没有的 `NSInvocation` 与 C 可变参数）、变换后的角点方法（`-cyl_newTopLeft`…）、
 *      `-cyl_otherImageViewViewInTabBarButton` 与 `-cyl_isTabEffectContentView`。
 */
enum CYLViewTabBarKeys {
    static let tabBarItemIconView = CYLUtilsKeys.key("cyl_isTabBarItemIconView")
    static let tabButtonCoverView = CYLUtilsKeys.key("cyl_isTabButtonCoverView")
    static let tabbarItemsCount = CYLUtilsKeys.key("cyl_tabbarItemsCount")
    static let tabBarItemWidth = CYLUtilsKeys.key("cyl_tabBarItemWidth")
    static let insertedForTabControl = CYLUtilsKeys.key("cyl_insertedForTabControl")
    static let portalViewClass: AnyClass? = NSClassFromString(["_", "UI", "Portal", "View"].joined())
    /**
     * [EN] Every view marked as inserted into a tab button, held weakly. [CN] 所有被标记为插入 Tab 按钮的视图（弱引用）。
     */
    static let insertedTabControlViews = NSHashTable<UIView>.weakObjects()
}

extension UIView {

    // MARK: Recognizing the views of the tab bar

    @objc(cyl_isPlusButton)
    public func cyl_isPlusButton() -> Bool {
        // [EN] A plus button of any registered context, not only the one registered last.
        // [CN] 任意已注册上下文的 PlusButton，而不只是最后注册的那一个。
        CYLPlusButton.isPlusButtonView(self)
    }

    @objc(cyl_isRightToLeftLayout)
    public func cyl_isRightToLeftLayout() -> Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    /**
     * [EN] A tab button: `UITab…BarButton` (#641), or any control on Liquid Glass and FlatDesign; before iOS 26 also a
     *      control whose class starts with "UITabBar".
     * [CN] Tab 按钮：`UITab…BarButton`（#641），或液态玻璃与扁平样式下的任意控件；iOS 26 以前还包括类名以 "UITabBar" 开头的控件。
     */
    @objc(cyl_isTabButton)
    public func cyl_isTabButton() -> Bool {
        let className = cyl_className
        if className.hasSuffix("BarButton") && className.hasPrefix("UITab") {
            return true
        }
        if !CYLConstants.isLiquidGlassActive() {
            return cyl_isKind(of: UIControl.self)
        }
        // [EN] UIControl, shared by FlatDesign and Liquid Glass. [CN] UIControl，扁平样式与液态玻璃共用。
        return self is UIControl
    }

    @objc(cyl_isPlatterView)
    public func cyl_isPlatterView() -> Bool {
        // [EN] Before iOS 26, or in UI compatibility mode, there is no platter. [CN] iOS 26 以前或 UI 兼容模式下没有 platter。
        guard CYLConstants.isLiquidGlassActive() else {
            return false
        }
        return cyl_className.hasSuffix("PlatterView") && cyl_className.hasPrefix("UIKit")
    }

    @objc(cyl_isPlatterPortalView)
    public func cyl_isPlatterPortalView() -> Bool {
        guard CYLConstants.isLiquidGlassActive(), let portalViewClass = CYLViewTabBarKeys.portalViewClass else {
            return false
        }
        return isKind(of: portalViewClass)
    }

    @objc(cyl_isPlatterContentView)
    public func cyl_isPlatterContentView() -> Bool {
        cyl_isVisibleLiquidGlassView { $0.contains("ContentView") && !$0.contains("Selected") }
    }

    @objc(cyl_isPlatterSelectedContentView)
    public func cyl_isPlatterSelectedContentView() -> Bool {
        cyl_isVisibleLiquidGlassView { $0.hasSuffix("SelectedContentView") }
    }

    @objc(cyl_isPlatterVisualProviderFloatingSelectedContentView)
    public func cyl_isPlatterVisualProviderFloatingSelectedContentView() -> Bool {
        cyl_isVisibleLiquidGlassView {
            $0.hasPrefix("_UITab") && $0.contains("VisualProvider") && $0.contains("_Floating") && $0.contains("SelectedContentView")
        }
    }

    @objc(cyl_isPlatterLiquidLensView)
    public func cyl_isPlatterLiquidLensView() -> Bool {
        cyl_isVisibleLiquidGlassView {
            $0.hasPrefix("_UI") && $0.contains("LiquidLens") && $0.contains("View") && !$0.contains("DestOutView")
                && !$0.contains("BackdropView")
        }
    }

    @objc(cyl_isPlatterLiquidLensClearGlassView)
    public func cyl_isPlatterLiquidLensClearGlassView() -> Bool {
        cyl_isVisibleLiquidGlassView { $0.hasPrefix("_UI") && $0.contains("LiquidLens") && $0.hasSuffix("ClearGlassView") }
    }

    @objc(cyl_isPlatterLiquidLensTabSelectionView)
    public func cyl_isPlatterLiquidLensTabSelectionView() -> Bool {
        cyl_isVisibleLiquidGlassView { $0.hasPrefix("_UITab") && $0.hasSuffix("SelectionView") }
    }

    @objc(cyl_isPlatterLiquidLensBackdropView)
    public func cyl_isPlatterLiquidLensBackdropView() -> Bool {
        cyl_isVisibleLiquidGlassView { $0.hasPrefix("_UI") && $0.contains("LiquidLens") && $0.hasSuffix("BackdropView") }
    }

    @objc(cyl_isPlatterDestOutView)
    public func cyl_isPlatterDestOutView() -> Bool {
        cyl_isVisibleLiquidGlassView {
            $0.hasPrefix("_UI") && $0.contains("LiquidLens") && $0.contains("View") && $0.contains("DestOutView")
        }
    }

    /**
     * [EN] YES for a view shown in place of a tab's icon (#601). [CN] 替换 Tab 图标显示的视图为 YES（#601）。
     */
    @objc(cyl_tabBarItemIconView)
    public var cyl_tabBarItemIconView: Bool {
        @objc(cyl_isTabBarItemIconView) get {
            (objc_getAssociatedObject(self, CYLViewTabBarKeys.tabBarItemIconView) as? NSNumber)?.boolValue ?? false
        }
        @objc(cyl_setTabBarItemIconView:) set {
            objc_setAssociatedObject(self, CYLViewTabBarKeys.tabBarItemIconView, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] YES for a cover added over a tab button (`-setSelectedCoverShow:`). [CN] 覆盖在 Tab 按钮上的视图为 YES。
     */
    @objc(cyl_tabButtonCoverView)
    public var cyl_tabButtonCoverView: Bool {
        @objc(cyl_isTabButtonCoverView) get {
            (objc_getAssociatedObject(self, CYLViewTabBarKeys.tabButtonCoverView) as? NSNumber)?.boolValue ?? false
        }
        @objc(cyl_setTabButtonCoverView:) set {
            objc_setAssociatedObject(self, CYLViewTabBarKeys.tabButtonCoverView, newValue ? NSNumber(value: true) : nil,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] A tab's icon: an image view of the tab bar that is not the selection indicator and not a view shown in place of
     *      the icon, or inside one (#601).
     * [CN] Tab 的图标：TabBar 中的图片视图，不是选中指示视图，也不是替换图标显示的视图或其子视图（#601）。
     */
    @objc(cyl_isTabImageView)
    public func cyl_isTabImageView() -> Bool {
        guard cyl_isKind(of: UIImageView.self) else {
            return false
        }
        var view: UIView? = self
        while let current = view, !(current is UIControl) {
            if current.cyl_tabBarItemIconView {
                return false
            }
            view = current.superview
        }
        return !cyl_className.hasSuffix("Indi" + "cat" + "orVi" + "ew")
    }

    @objc(cyl_isTabLabel)
    public func cyl_isTabLabel() -> Bool {
        // [EN] Before iOS 26, keep the original logic. [CN] iOS 26 以前保持原逻辑。
        if !CYLConstants.isLiquidGlassActive() {
            return cyl_isKind(of: UILabel.self)
        }
        let className = cyl_className
        if className.hasSuffix("Label") && className.contains("TabButton") && className.contains("_UI") {
            return true
        }
        return self is UILabel
    }

    @objc(cyl_isButtonLabel)
    public func cyl_isButtonLabel() -> Bool {
        cyl_className.hasSuffix("Label") && cyl_className.hasPrefix("UIButton")
    }

    @objc(cyl_isTabBadgeView)
    public func cyl_isTabBadgeView() -> Bool {
        type(of: self) != UIView.self && cyl_className.hasPrefix("_U" + "IB" + "adg")
    }

    @objc(cyl_isTabBackgroundView)
    public func cyl_isTabBackgroundView() -> Bool {
        type(of: self) != UIView.self && cyl_className.hasPrefix("_U" + "IB" + "arBac") && cyl_className.hasSuffix("nd")
    }

    /**
     * [EN] YES for the animation view of any animation library; NO without the `CYLTabBarItemAnimation` subspec (#604).
     * [CN] 任意动画库的动画视图为 YES；构建中没有 `CYLTabBarItemAnimation` 子库时为 NO（#604）。
     */
    @objc(cyl_isLottieAnimationView)
    public func cyl_isLottieAnimationView() -> Bool {
        CYLTabBarItemAnimationCore.service != nil && cyl_isTabBarItemAnimationView()
    }

    // MARK: Finding the views of a tab button

    @objc(cyl_imageView)
    public func cyl_imageView() -> UIImageView? {
        subviews.first { $0 is UIImageView } as? UIImageView
    }

    @objc(cyl_tabImageView)
    public func cyl_tabImageView() -> UIImageView? {
        if let imageViewInTabBarButton = cyl_imageViewInTabBarButton() {
            return imageViewInTabBarButton
        }
        return cyl_allSubviews().first { ($0 as? UIView)?.cyl_isTabImageView() ?? false } as? UIImageView
    }

    /**
     * [EN] `UITabBarSwappableImageView`, which exists only while the tab is selected. [CN] 只在 Tab 选中时存在。
     */
    @objc(cyl_swappableImageViewViewInTabBarButton)
    public func cyl_swappableImageViewViewInTabBarButton() -> UIImageView? {
        subviews.first {
            let className = NSStringFromClass(type(of: $0))
            return className.hasSuffix("ImageView") && className.hasPrefix("UITabB")
        } as? UIImageView
    }

    @objc(cyl_imageViewInTabBarButton)
    public func cyl_imageViewInTabBarButton() -> UIImageView? {
        // [EN] ① KVC first (iOS 13+); iOS 26's `_UITabButton` has no `imageView` key, where `valueForKey:` would throw.
        // [CN] ① 先用 KVC（iOS 13+）；iOS 26 的 `_UITabButton` 没有 `imageView` key，`valueForKey:` 会抛出异常。
        if cyl_className != "_UITabButton", let imageView = cyl_value(forKey: "imageView") as? UIImageView {
            return imageView
        }
        // [EN] ② The subviews: `UITabBar…SwappableImageView`, else the last image view that is not the selection indicator
        //      or a view shown in place of the icon (#601).
        // [CN] ② 遍历子视图：`UITabBar…SwappableImageView`，否则为最后一个既不是选中背景、也不是替换图标视图（#601）的图片视图。
        var imageView: UIImageView?
        for subview in subviews {
            let className = NSStringFromClass(type(of: subview))
            if className.hasPrefix("UITabBar") && className.hasSuffix("SwappableImageView") {
                return subview as? UIImageView
            }
            if let candidate = subview as? UIImageView, !candidate.cyl_tabBarItemIconView,
               !className.hasSuffix("SelectionIndicatorView"), !className.hasPrefix("UITabBar") {
                imageView = candidate
            }
        }
        return imageView
    }

    /**
     * [EN] This view and all its subviews, depth first. [CN] 本视图及其所有子视图（深度优先）。
     */
    @objc(cyl_allSubviews)
    public func cyl_allSubviews() -> [Any] {
        [self] + subviews.flatMap { $0.cyl_allSubviews() }
    }

    @objc(cyl_tabBadgeView)
    public func cyl_tabBadgeView() -> UIView? {
        cyl_allSubviews().first { ($0 as? UIView)?.cyl_isTabBadgeView() ?? false } as? UIView
    }

    @objc(cyl_tabLabel)
    public func cyl_tabLabel() -> UILabel? {
        cyl_allSubviews().first { ($0 as? UIView)?.cyl_isTabLabel() ?? false } as? UILabel
    }

    @objc(cyl_tabEffectView)
    public func cyl_tabEffectView() -> UIVisualEffectView? {
        subviews.first { type(of: $0) == UIVisualEffectView.self } as? UIVisualEffectView
    }

    @objc(cyl_tabShadowImageView)
    public func cyl_tabShadowImageView() -> UIImageView? {
        // [EN] The hairline in the tab bar's background view. [CN] TabBar 背景视图中的分割线。
        cyl_tabBackgroundView()?.subviews.first { $0.bounds.height <= 1 } as? UIImageView
    }

    @objc(cyl_tabBackgroundView)
    public func cyl_tabBackgroundView() -> UIView? {
        subviews.first { $0.cyl_isTabBackgroundView() }
    }

    /**
     * [EN] The `view` of a `UIBarButtonItem` or `UITabBarItem` (lazily created by UIKit once the item is shown); used by
     *      `CYLTabBar`, which declares it.
     * [CN] `UIBarButtonItem` 或 `UITabBarItem` 的 `view`（UIKit 在 item 显示后才创建）；由声明它的 `CYLTabBar` 使用。
     */
    @objc(cyl_contentView)
    func cyl_contentView() -> UIView? {
        responds(to: NSSelectorFromString("view")) ? cyl_value(forKey: "view") as? UIView : nil
    }

    // MARK: Adding views

    /**
     * [EN] Adds `view` to the Liquid Glass platter when there is one, else to this view, then brings it to the front. Use
     *      `-cyl_isViewAddedToPlatterView:` to check where it went.
     * [CN] 有液态玻璃 platter 时把 `view` 添加到 platter 上，否则添加到本视图，然后移到最前。用 `-cyl_isViewAddedToPlatterView:` 判断添加位置。
     */
    @objc(cyl_addPlatterViewThenBringSubviewToFront:)
    public func cyl_addPlatterViewThenBringSubview(toFront view: UIView) {
        let tabBar = cyl_tabBarController?.tabBar as? CYLTabBar
        if tabBar?.cyl_platterContentView != nil, let platterView = tabBar?.cyl_platterView {
            platterView.addSubview(view)
        } else {
            addSubview(view)
        }
        cyl_bringSubview(toFront: view)
    }

    @objc(cyl_isViewAddedToPlatterView:)
    public func cyl_isViewAdded(toPlatterView view: UIView) -> Bool {
        if let platterContentView = (cyl_tabBarController?.tabBar as? CYLTabBar)?.cyl_platterContentView {
            return view.superview == platterContentView
        }
        return view.superview == self
    }

    /**
     * [EN] Puts `view` right below the Liquid Glass platter when there is one, else on top of everything.
     * [CN] 有液态玻璃 platter 时把 `view` 放在 platter 下方，否则放在最上层。
     */
    @objc(cyl_bringSubviewToFront:)
    public func cyl_bringSubview(toFront view: UIView) {
        if let platterView = (cyl_tabBarController?.tabBar as? CYLTabBar)?.cyl_platterView {
            insertSubview(view, belowSubview: platterView)
        } else {
            cyl_bringSubview(toTop: view)
        }
    }

    @objc(cyl_bringSubviewToTop:)
    public func cyl_bringSubview(toTop view: UIView) {
        addSubview(view)
        bringSubviewToFront(view)
        view.layer.zPosition = .greatestFiniteMagnitude
    }

    // MARK: Snapshots

    @objc(cyl_takeSnapshot)
    public func cyl_takeSnapshot() -> UIImage? {
        guard let platterView = (cyl_tabBarController?.tabBar as? CYLTabBar)?.cyl_platterView else {
            return nil
        }
        return cyl_takeSnapshot(withoutViews: [platterView])
    }

    /**
     * [EN] A snapshot of this view with `hideViews` hidden; each one is restored afterwards (a view hidden already stays hidden).
     * [CN] 隐藏 `hideViews` 后的本视图快照；之后逐个恢复（原本就隐藏的视图保持隐藏）。
     */
    @objc(cyl_takeSnapshotWithoutViews:)
    public func cyl_takeSnapshot(withoutViews hideViews: [UIView]) -> UIImage? {
        let size = bounds.size
        guard size.width > 0 && size.height > 0 else {
            return nil
        }
        let viewsToRestore = hideViews.filter { !$0.isHidden }
        viewsToRestore.forEach { $0.cyl_setHidden(true) }
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
        viewsToRestore.forEach { $0.cyl_setHidden(false) }
        return image
    }

    // MARK: Views inserted into tab buttons

    /**
     * [EN] Marks this view as inserted into `control`'s tab button (weakly); nil removes the mark.
     * [CN] 把本视图标记为插入 `control` 的 Tab 按钮（弱引用）；nil 移除标记。
     */
    @objc(cyl_markAsInsertedForTabControl:)
    public func cyl_markAsInserted(forTabControl control: UIControl?) {
        cyl_setWeakAssociatedObject(control, forKey: CYLViewTabBarKeys.insertedForTabControl)
        if control != nil {
            CYLViewTabBarKeys.insertedTabControlViews.add(self)
        } else {
            CYLViewTabBarKeys.insertedTabControlViews.remove(self)
        }
    }

    @objc(cyl_insertedForTabControl)
    public var cyl_insertedForTabControl: UIControl? {
        cyl_weakAssociatedObject(forKey: CYLViewTabBarKeys.insertedForTabControl) as? UIControl
    }

    @objc(cyl_insertedTabControlViews)
    public class func cyl_insertedTabControlViews() -> [UIView] {
        CYLViewTabBarKeys.insertedTabControlViews.allObjects
    }

    // MARK: Deprecated

    @available(*, deprecated, message: "Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabBackgroundView]` instead.")
    @objc(cyl_tabBadgeBackgroundView)
    public func cyl_tabBadgeBackgroundView() -> UIView? {
        cyl_tabBackgroundView()
    }

    @available(*, deprecated, message: "Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabShadowImageView]` instead.")
    @objc(cyl_tabBadgeBackgroundSeparator)
    public func cyl_tabBadgeBackgroundSeparator() -> UIView? {
        cyl_tabShadowImageView()
    }

    /**
     * [EN] FIX: issue #653 — a fixed frame instead of width / height constraints (constraints inside a tab button break the
     *      iOS 27.1 vertical bar).
     * [CN] 使用固定 frame 而不是宽高约束（Tab 按钮中的约束会破坏 iOS 27.1 的竖向 TabBar）。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_tabBadgePointViewWithClolor:radius:)
    public class func cyl_tabBadgePointView(withClolor color: UIColor, radius: CGFloat) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2))
        view.translatesAutoresizingMaskIntoConstraints = true
        view.backgroundColor = color
        view.layer.cornerRadius = radius
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }

    // MARK: Per tab bar metrics (CYLTabBarMetrics)

    /**
     * [EN] The number of tab items of this tab bar (the global `CYLTabbarItemsCount` when unset); setting it updates the
     *      global too.
     * [CN] 本 TabBar 的 Tab 数量（未设置时为全局的 `CYLTabbarItemsCount`）；设置时同时更新全局值。
     */
    @objc(cyl_tabbarItemsCount)
    public var cyl_tabbarItemsCount: UInt {
        @objc(cyl_tabbarItemsCount) get {
            (objc_getAssociatedObject(self, CYLViewTabBarKeys.tabbarItemsCount) as? NSNumber)?.uintValue ?? CYLTabbarItemsCount
        }
        @objc(cyl_setTabbarItemsCount:) set {
            objc_setAssociatedObject(self, CYLViewTabBarKeys.tabbarItemsCount, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            CYLTabbarItemsCount = newValue
        }
    }

    /**
     * [EN] The width of a tab item of this tab bar (the global `CYLTabBarItemWidth` when unset); setting it updates the
     *      global too.
     * [CN] 本 TabBar 中 Tab 的宽度（未设置时为全局的 `CYLTabBarItemWidth`）；设置时同时更新全局值。
     */
    @objc(cyl_tabBarItemWidth)
    public var cyl_tabBarItemWidth: CGFloat {
        @objc(cyl_tabBarItemWidth) get {
            (objc_getAssociatedObject(self, CYLViewTabBarKeys.tabBarItemWidth) as? NSNumber).map { CGFloat($0.doubleValue) }
                ?? CYLTabBarItemWidth
        }
        @objc(cyl_setTabBarItemWidth:) set {
            objc_setAssociatedObject(self, CYLViewTabBarKeys.tabBarItemWidth, NSNumber(value: Double(newValue)),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            CYLTabBarItemWidth = newValue
        }
    }

    /**
     * [EN] The index of the plus button's slot in the `viewControllers` of the tab bar controller this view belongs to (a
     *      placeholder or the plus child view controller); without a slot, between the tabs as the plus button class says
     *      (`+indexForTabbarItemsCount:`); the global `CYLPlusButtonIndex` without a plus button.
     * [CN] PlusButton 的 slot（占位控制器或 PlusButton 子控制器）在本视图所属 TabBarController 的 `viewControllers` 中的下标；没有 slot 时
     *      按 PlusButton 类（`+indexForTabbarItemsCount:`）位于 Tab 之间；没有 PlusButton 时为全局的 `CYLPlusButtonIndex`。
     */
    @objc(cyl_plusButtonIndex)
    public func cyl_plusButtonIndex() -> UInt {
        guard let plusButton = CYLPlusButton(forOwner: self) else {
            return CYLPlusButtonIndex
        }
        if let slotIndex = cyl_plusSlotIndex() {
            return UInt(slotIndex)
        }
        return type(of: plusButton).index(forTabbarItemsCount: cyl_tabbarItemsCount)
    }

    @objc(cyl_plusButtonWidth)
    public func cyl_plusButtonWidth() -> CGFloat {
        CYLPlusButton.plusButtonWidth(forOwner: self)
    }

    // MARK: Private helpers

    private var cyl_className: String {
        NSStringFromClass(type(of: self))
    }

    /**
     * [EN] A Liquid Glass view whose class name matches, and that is visible. [CN] 类名匹配且可见的液态玻璃视图。
     */
    private func cyl_isVisibleLiquidGlassView(_ matches: (String) -> Bool) -> Bool {
        guard CYLConstants.isLiquidGlassActive() else {
            return false
        }
        return matches(cyl_className) && !isHidden
    }

    /**
     * [EN] A subclass of `aClass` (not the class itself) whose class name starts with "UITabBar".
     * [CN] `aClass` 的子类（不包括其本身），且类名以 "UITabBar" 开头。
     */
    private func cyl_isKind(of aClass: AnyClass) -> Bool {
        isKind(of: aClass) && !isMember(of: aClass) && cyl_className.hasPrefix("U" + "IT" + "a" + "bB" + "ar")
    }

    /**
     * [EN] The index of the plus button's slot in its tab bar controller's `viewControllers` (inserted by one rule in
     *      `-[CYLTabBarController setViewControllers:]`), or nil.
     * [CN] PlusButton 的 slot 在其 TabBarController 的 `viewControllers` 中的下标（只由 `-[CYLTabBarController setViewControllers:]`
     *      插入），没有时为 nil。
     */
    private func cyl_plusSlotIndex() -> Int? {
        guard let tabBarController = cyl_owningTabBarController() else {
            return nil
        }
        let plusChildViewController = CYLPlusButton.plusChildViewController(forOwner: tabBarController)
        return tabBarController.viewControllers?.firstIndex { viewController in
            let contentViewController = viewController.cyl_getViewControllerInsteadOfNavigation()
            return viewController.cyl_isPlaceholder || contentViewController.cyl_isPlaceholder
                || (plusChildViewController != nil
                    && (viewController === plusChildViewController || contentViewController === plusChildViewController))
        }
    }
}
