//
//  CYLTabBarController+CYLFlatDesign.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The private methods and state of `CYLTabBarController` (still Objective-C, FlatDesign only) that this file calls.
 *      Selectors only; the class implements them under `CYL_FLATDESIGN_AVAILABLE`.
 * [CN] 本文件调用的 `CYLTabBarController` 私有方法与状态（仍为 Objective-C，仅扁平样式）。只有 selector；该类在 `CYL_FLATDESIGN_AVAILABLE` 下实现它们。
 */
@objc private protocol CYLFlatDesignTabBarControllerHostAPI {
    @objc(_cyl_refreshSystemTabBarVisibilityIfNeeded) func refreshSystemTabBarVisibilityIfNeeded()
    @objc(_checkHidesBottomBarWhenPushed) func checkHidesBottomBarWhenPushed() -> Bool
    @objc(tabBarFrame) func tabBarFrame() -> CGRect
    @objc(parallaxOverlayView) func parallaxOverlayView() -> UIView?
    @objc(setParallaxOverlayView:) func setParallaxOverlayView(_ view: UIView?)
    @objc(cylDidRefreshSystemTabBarVisibility) func didRefreshSystemTabBarVisibility() -> Bool
    @objc(tabBarIsAnimating) func tabBarIsAnimating() -> Bool
    @objc(items) func items() -> NSMutableArray?
    @objc(setItems:) func setItems(_ items: NSMutableArray?)
}

/**
 * [EN] FlatDesign parts of `CYLTabBarController`: the size transition, the tab item action and the navigation transition
 *      callbacks (`UINavigationControllerExtensionDelegate`, called by selector from UINavigationController+CYLFlatDesignTabBarPrivate).
 *      Translated from Objective-C (docs/Swift-Migration.md, step 71). This file belongs to the FlatDesign subspec, so it is
 *      compiled only with it, like the `#if CYL_FLATDESIGN_AVAILABLE` blocks it replaces; every method still returns early
 *      unless the style is FlatDesign, so Liquid Glass and the classic style are never affected.
 * [CN] `CYLTabBarController` 的扁平样式部分：尺寸转场、Tab item 事件以及导航转场回调（`UINavigationControllerExtensionDelegate`，由
 *      UINavigationController+CYLFlatDesignTabBarPrivate 按 selector 调用）。已从 Objective-C 翻译（docs/Swift-Migration.md，第 71 步）。本文件属于
 *      扁平样式子库，只与它一起编译，与它取代的 `#if CYL_FLATDESIGN_AVAILABLE` 代码块相同；每个方法在非扁平样式时都会直接返回，液态玻璃与经典样式不受影响。
 */
extension CYLTabBarController {

    private var cylFlatDesignHost: CYLFlatDesignTabBarControllerHostAPI {
        unsafeBitCast(self, to: CYLFlatDesignTabBarControllerHostAPI.self)
    }

    /// [EN] The FlatDesign tab bar, when this controller uses it. [CN] 使用扁平样式时的扁平 TabBar。
    private var cylFlatDesignTabBar: CYLFlatDesignTabBar? {
        guard tabBarStyleType == .flatDesign else {
            return nil
        }
        return cyl_tabBar as? CYLFlatDesignTabBar
    }

    /// FIX: issue #662
    /// [EN] Sets only the bottom of `viewController.additionalSafeAreaInsets`. [CN] 只修改 `additionalSafeAreaInsets.bottom`。
    private static func cylSetAdditionalSafeAreaBottom(_ viewController: UIViewController, _ bottom: CGFloat) {
        var insets = viewController.additionalSafeAreaInsets
        guard insets.bottom != bottom else {
            return
        }
        insets.bottom = bottom
        viewController.additionalSafeAreaInsets = insets
    }

    /// [EN] The bottom inset applied to the selected child, and to the More navigation controller when it is not selected.
    /// [CN] 设置给选中子控制器的底部 inset；More 导航控制器未选中时也同步给它。
    private func cylFlatDesignApplyAdditionalSafeAreaInsets(_ insets: UIEdgeInsets) {
        UIView.performWithoutAnimation {
            selectedViewController?.additionalSafeAreaInsets = insets
            if cylFlatDesignShowsMoreNavigationController(), moreNavigationController !== selectedViewController {
                Self.cylSetAdditionalSafeAreaBottom(moreNavigationController, insets.bottom)
            }
        }
    }

    // MARK: - UIContentContainer

    /**
     * [EN] The FlatDesign part of `-viewWillTransitionToSize:withTransitionCoordinator:` (the override stays in Objective-C).
     * [CN] `-viewWillTransitionToSize:withTransitionCoordinator:` 的扁平样式部分（重写保留在 Objective-C 中）。
     */
    @objc(cyl_flatDesignViewWillTransitionToSize:withTransitionCoordinator:)
    func cylFlatDesignViewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard cylFlatDesignTabBar != nil, view.bounds.size != size else {
            return
        }
        coordinator.animate(alongsideTransition: { _ in
            self.cylFlatDesignUpdateAdditionalSafeAreaInsets(animated: false)
            self.selectedViewController?.view.setNeedsLayout()
            self.selectedViewController?.view.layoutIfNeeded()
        }, completion: { _ in
            self.cylFlatDesignHost.refreshSystemTabBarVisibilityIfNeeded()
        })
    }

    // MARK: - TabBarItem Action

    /**
     * FIX: issue #610
     * [EN] FlatDesign: reports a tapped tab button or plus button through `tabBarController:didSelectControl:`, as the other
     *      styles do. One place for every tap, each reported once: a tab button (`-[CYLFlatDesignTabBar _tabBarDidSelectButton:]`),
     *      a plus button with a child view controller (`-plusChildViewControllerButtonClicked:`, or the tab button under it)
     *      and one without (`-cyl_flatDesignPlusButtonTouchUpInside:`).
     * [CN] 扁平样式：与其他样式一样，通过 `tabBarController:didSelectControl:` 上报被点击的 Tab 按钮或 PlusButton。所有点击共用这一处，每次只上报一次。
     */
    @objc(cyl_flatDesignReportDidSelectControl:)
    func cylFlatDesignReportDidSelectControl(_ control: UIControl) {
        guard cylControlReportsTapsEntryPoint(control) else {
            return
        }
        cylSendDidSelectControl(control)
    }

    /**
     * [EN] The target of a FlatDesign plus button that has no child view controller (one with a child view controller is
     *      handled by `-plusChildViewControllerButtonClicked:`).
     * [CN] 没有子控制器的扁平样式 PlusButton 的事件（有子控制器的由 `-plusChildViewControllerButtonClicked:` 处理）。
     */
    @objc(cyl_flatDesignPlusButtonTouchUpInside:)
    func cylFlatDesignPlusButtonTouchUpInside(_ plusButton: UIControl) {
        cylFlatDesignReportDidSelectControl(plusButton)
    }

    /**
     * [EN] A FlatDesign tab item tapped (called by selector from `CYLFlatDesignTabBar`).
     * [CN] 扁平样式 Tab item 被点击（由 `CYLFlatDesignTabBar` 按 selector 调用）。
     */
    @objc(_cyltabBarItemClicked:)
    func cylFlatDesignTabBarItemClicked(_ tabBarItem: CYLFlatDesignTabBarItem) {
        guard let tabBar = cylFlatDesignTabBar, let viewControllers else {
            return
        }
        // FIX: issue #618
        // [EN] An item without a view controller (not found, or more items than view controllers) used to raise NSRangeException.
        // [CN] 没有对应控制器的 item（找不到，或 item 比控制器多）以前会抛出 NSRangeException。
        guard let index = (tabBar.items ?? []).firstIndex(where: { $0 === tabBarItem }), index < viewControllers.count else {
            return
        }
        let didSelectViewController = viewControllers[index]
        if didSelectViewController.cyl_isPlaceholder || didSelectViewController.cyl_getViewControllerInsteadOfNavigation().cyl_isPlaceholder {
            return
        }
        // FIX: issue #610 — already reported by `-[CYLFlatDesignTabBar _tabBarDidSelectButton:]`, which every tap goes through.
        // FIX: issue #152
        // [EN] One user tap on a tab button, before the selection changes, also without a delegate.
        // [CN] 一次用户点击 Tab 按钮，在选中变化之前；没有代理时同样计数。
        cylRecognizeTabBarItemTapWillSelect(didSelectViewController)
        if let shouldSelect = cylDelegate?.tabBarController?(self, shouldSelect: didSelectViewController), !shouldSelect {
            return
        }
        selectedViewController = didSelectViewController
        cylFlatDesignUpdateSelectionStatus(for: didSelectViewController)
        cylDelegate?.tabBarController?(self, didSelect: didSelectViewController)
    }

    /**
     * [EN] The plus button's selected state after `viewController` was selected (FlatDesign, plus child view controller only).
     * [CN] 选中 `viewController` 后 PlusButton 的选中状态（仅扁平样式、有 Plus 子控制器时）。
     */
    private func cylFlatDesignUpdateSelectionStatus(for selected: UIViewController?) {
        guard cylFlatDesignTabBar != nil, hasPlusChildViewController() else {
            return
        }
        let viewController = selected ?? selectedViewController
        let plusButton = cylPrivate.cylContextPlusButton()
        let isPlusChild: Bool
        if let viewController, let plusChild = cylPrivate.cylContextPlusChildViewController() {
            isPlusChild = viewController.cyl_isEqual(to: plusChild)
        } else {
            isPlusChild = false
        }
        plusButton?.isSelected = isPlusChild
        if isPlusChild {
            NotificationCenter.default.post(name: .CYLTabBarItemAnimationPlaying, object: self)
        }
    }

    // MARK: - UINavigationControllerExtensionDelegate

    @objc(cylflatdesign_navigationController:navigationBarDidChangeHeight:)
    func cylFlatDesignNavigationController(_ navigationController: UINavigationController, navigationBarDidChangeHeight height: CGFloat) {
        if navigationController === selectedViewController {
            cylFlatDesignHost.refreshSystemTabBarVisibilityIfNeeded()
        }
    }

    @objc(cylflatdesign_navigationController:didBeginTransitionFrom:to:operation:)
    func cylFlatDesignNavigationController(_ navigationController: UINavigationController, didBeginTransitionFrom fromVC: UIViewController?,
                                           to toVC: UIViewController?, operation: UINavigationController.Operation) {
        guard cylFlatDesignTabBar != nil else {
            return
        }
        // [EN] No user interaction during a transition or the interactive pop gesture. FIX: issue #652 (the bottom inset is left as is).
        // [CN] 转场或 pop 手势返回时禁止用户交互。FIX: issue #652（底部 inset 保持不变）。
        view.isUserInteractionEnabled = false
        cylFlatDesignApplyAdditionalSafeAreaInsets(selectedViewController?.additionalSafeAreaInsets ?? .zero)
    }

    @objc(cylflatdesign_navigationController:didUpdateInteractiveFrom:to:percentComplete:)
    func cylFlatDesignNavigationController(_ navigationController: UINavigationController, didUpdateInteractiveFrom fromVC: UIViewController?,
                                           to toVC: UIViewController?, percentComplete: CGFloat) {
        // [EN] Nothing to do. [CN] 无需处理。
    }

    @objc(cylflatdesign_navigationController:didUpdateInteractiveFrom:to:popGestureRecognizer:)
    func cylFlatDesignNavigationController(_ navigationController: UINavigationController, didUpdateInteractiveFrom fromVC: UIViewController?,
                                           to toVC: UIViewController?, popGestureRecognizer: UIGestureRecognizer) {
        // [EN] Nothing to do. [CN] 无需处理。
    }

    @objc(cylflatdesign_navigationController:willEndTransitionFrom:to:operation:cancelled:)
    func cylFlatDesignNavigationController(_ navigationController: UINavigationController, willEndTransitionFrom fromVC: UIViewController?,
                                           to toVC: UIViewController?, operation: UINavigationController.Operation, cancelled: Bool) {
        guard let tabBar = cylFlatDesignTabBar else {
            return
        }
        let showsTabBar = cylFlatDesignShouldShowsBottomBar()
        if operation == .push {
            if !showsTabBar && !tabBar.isHidden, let fromVC {
                cylFlatDesignAddParallaxOverlayView(to: fromVC)
            }
        } else if showsTabBar && tabBar.isHidden, let toVC {
            cylFlatDesignAddParallaxOverlayView(to: toVC)
        }
        var insets = selectedViewController?.additionalSafeAreaInsets ?? .zero
        insets.bottom = showsTabBar ? tabBarHeight : 0
        cylFlatDesignApplyAdditionalSafeAreaInsets(insets)
    }

    @objc(cylflatdesign_navigationController:didEndTransitionFrom:to:operation:cancelled:)
    func cylFlatDesignNavigationController(_ navigationController: UINavigationController, didEndTransitionFrom fromVC: UIViewController?,
                                           to toVC: UIViewController?, operation: UINavigationController.Operation, cancelled: Bool) {
        guard let tabBar = cylFlatDesignTabBar else {
            return
        }
        let host = cylFlatDesignHost
        view.isUserInteractionEnabled = true
        if let overlay = host.parallaxOverlayView() {
            overlay.removeFromSuperview()
            host.setParallaxOverlayView(nil)
        }
        if tabBar.superview !== view {
            tabBar.frame = host.tabBarFrame()
            view.addSubview(tabBar)
        }
        cylFlatDesignUpdateBottomBarShowHideIfNeeded()
        // [EN] A refresh deferred while the bar was in the transition overlay is retried after the overlay is removed
        //      (cancellation included). [CN] TabBar 位于转场遮罩中时推迟的刷新，在遮罩移除后重试（包括取消）。
        host.refreshSystemTabBarVisibilityIfNeeded()
        if !host.didRefreshSystemTabBarVisibility() {
            DispatchQueue.main.async { [weak self] in
                self?.cylFlatDesignHost.refreshSystemTabBarVisibilityIfNeeded()
            }
        }
    }

    // MARK: - Private (docs/Swift-Migration.md, step 72)

    /**
     * [EN] Whether UIKit shows its More item. Asks UIKit instead of counting: iPad and regular width show more than five items
     *      without a More tab. FIX: issue #662 (the guard used to be inverted, so FlatDesign never saw the More item).
     * [CN] UIKit 是否显示 More 项。以 UIKit 实际是否生成 More 项为准：iPad / regular 宽度下超过 5 个也不会出现 More。FIX: issue #662（判断条件曾写反）。
     */
    @objc(_showsMoreNavigationController)
    func cylFlatDesignShowsMoreNavigationController() -> Bool {
        guard cylFlatDesignTabBar != nil else {
            return false
        }
        return (tabBar.items ?? []).contains(moreNavigationController.tabBarItem)
    }

    /**
     * [EN] Builds the FlatDesign items from the view controllers (and UIKit's More item when it shows one).
     * [CN] 根据子控制器（以及 UIKit 显示的 More 项）生成扁平样式的 item。
     */
    @objc(_captureItems)
    func cylFlatDesignCaptureItems() {
        guard cylFlatDesignTabBar != nil else {
            return
        }
        let viewControllers = self.viewControllers ?? []
        let systemItems = tabBar.items ?? []
        let hasMoreItem = systemItems.contains(moreNavigationController.tabBarItem)
        var items: [CYLFlatDesignTabBarItem] = []
        if hasMoreItem {
            // [EN] Every system item but the last (More) has its view controller. [CN] 除最后一个（More）外，每个系统 item 都有对应的子控制器。
            for viewController in viewControllers.prefix(max(systemItems.count - 1, 0)) {
                guard let item = viewController.cyl_tabBarItem else {
                    continue
                }
                viewController.cylFlatDesignSetTabBarController(self)
                items.append(item)
                viewController.cyl_tabButton = item.tabBarButton
            }
            if let moreItem = moreNavigationController.cyl_tabBarItem {
                let systemMoreItem = moreNavigationController.tabBarItem
                // [EN] The Objective-C code compared the system title's length with `< 0`, so it never copied it; fixed here.
                // [CN] Objective-C 代码用 `< 0` 比较系统标题的长度，因此从未拷贝；此处已修正。
                if (moreItem.title ?? "").isEmpty, let title = systemMoreItem?.title, !title.isEmpty {
                    moreItem.title = title
                }
                if moreItem.image == nil, let image = systemMoreItem?.image {
                    moreItem.image = image
                }
                if moreItem.selectedImage == nil, let selectedImage = systemMoreItem?.selectedImage {
                    moreItem.selectedImage = selectedImage
                }
                items.append(moreItem)
            }
        } else {
            for (index, viewController) in viewControllers.enumerated() {
                guard let item = viewController.cyl_tabBarItem else {
                    continue
                }
                viewController.cylFlatDesignSetTabBarController(self)
                item.index = UInt(index)
                items.append(item)
                viewController.cyl_tabButton = item.tabBarButton
            }
        }
        guard !viewControllers.isEmpty, !items.isEmpty else {
            return
        }
        cylFlatDesignSyncSystemItems()
        cylFlatDesignHost.setItems(NSMutableArray(array: items))
    }

    /**
     * [EN] Copies each FlatDesign item's title, image, title position and title attributes to the system item.
     * [CN] 把每个扁平样式 item 的标题、图片、标题位置与标题属性同步到系统 item。
     */
    @objc(_syncSystemItems)
    func cylFlatDesignSyncSystemItems() {
        guard cylFlatDesignTabBar != nil else {
            return
        }
        for viewController in viewControllers ?? [] {
            guard let item = viewController.cyl_tabBarItem else {
                continue
            }
            let systemItem = viewController.tabBarItem!
            systemItem.title = item.title
            systemItem.image = item.image
            systemItem.titlePositionAdjustment = item.titlePositionAdjustment
            systemItem.setTitleTextAttributes(item.titleTextAttributes(for: .normal), for: .normal)
            systemItem.setTitleTextAttributes(item.titleTextAttributes(for: .selected), for: .selected)
        }
    }

    /// [EN] Whether the FlatDesign tab bar should show now. [CN] 扁平样式 TabBar 当前是否应显示。
    @objc(_shouldShowsBottomBar)
    func cylFlatDesignShouldShowsBottomBar() -> Bool {
        guard cylFlatDesignTabBar != nil else {
            return true
        }
        return !isTabBarHidden && cylFlatDesignHost.checkHidesBottomBarWhenPushed()
    }

    /// [EN] Shows or hides the FlatDesign tab bar for the page on screen. [CN] 根据当前页面显示或隐藏扁平样式 TabBar。
    @objc(_updateBottomBarShowHideIfNeeded)
    func cylFlatDesignUpdateBottomBarShowHideIfNeeded() {
        guard let tabBar = cylFlatDesignTabBar else {
            return
        }
        let showsTabBar = cylFlatDesignShouldShowsBottomBar()
        if !cylFlatDesignHost.tabBarIsAnimating() {
            tabBar.isHidden = !showsTabBar
        }
        cylFlatDesignUpdateAdditionalSafeAreaInsets(animated: false)
        // [EN] A tab was selected or a push / pop ended: track the new page's scroll view (issue #13).
        // [CN] 切换了 Tab 或 push / pop 结束：跟随新页面的滚动视图（issue #13）。
        cylUpdateTabBarMinimizeTracking()
    }

    /**
     * [EN] Puts the tab bar on an overlay of `viewController`'s view during a push or pop, so it moves with the page.
     * [CN] push / pop 时把 TabBar 放到 `viewController` 视图上的遮罩中，使其随页面移动。
     */
    @objc(_addParallaxOverlayViewToViewController:)
    func cylFlatDesignAddParallaxOverlayView(to viewController: UIViewController) {
        guard let tabBar = cylFlatDesignTabBar else {
            return
        }
        let host = cylFlatDesignHost
        let superview = viewController.view!
        let overlay = host.parallaxOverlayView() ?? _CYLFlatDesignTabBarParallaxOverlayView(frame: superview.bounds)
        host.setParallaxOverlayView(overlay)
        overlay.frame = superview.bounds
        superview.addSubview(overlay)
        superview.bringSubviewToFront(overlay)
        guard tabBar.superview !== overlay else {
            return
        }
        // FIX: issue #662 (PR #665)
        // [EN] This runs inside the navigation transition's animation block; re-parenting and re-positioning must not be animated,
        //      or the bar visibly slides into place. [CN] 此处在导航转场的动画 block 中执行；更换父视图与位置不能有动画，否则 TabBar 会明显滑入。
        UIView.performWithoutAnimation {
            overlay.addSubview(tabBar)
            if !host.tabBarIsAnimating() {
                tabBar.frame = cylFlatDesignTabBarFrame(inParallaxOverlayView: overlay)
            }
            tabBar.isHidden = false
        }
        #if DEBUG
        cylFlatDesignLogTabBarClippingInParallaxOverlay()
        #endif
    }

    /**
     * FIX: issue #662 (push / pop follow-up, PR #665)
     * [EN] `tabBarFrame` is in `self.view`'s coordinates, but during a push or pop the tab bar sits in the overlay inside the
     *      child's view, which can start below an opaque navigation bar and be shorter. Only the vertical position is
     *      converted; the horizontal one stays relative to the child's view, so the bar moves with it (the parallax effect).
     * [CN] `tabBarFrame` 是 `self.view` 坐标系中的值，但 push / pop 时 TabBar 位于子控制器视图内的遮罩中，该视图可能从不透明导航栏下方开始且更矮。
     *      只转换竖直位置；水平位置仍相对子控制器的视图，使 TabBar 随之移动（视差效果）。
     */
    private func cylFlatDesignTabBarFrame(inParallaxOverlayView overlayView: UIView) -> CGRect {
        var frame = cylFlatDesignHost.tabBarFrame()
        if let window = overlayView.window, window === view.window {
            frame.origin.y = view.convert(CGPoint(x: 0, y: frame.minY), to: overlayView).y
        }
        // [EN] Otherwise the two views cannot be related yet; keep the previous behavior. [CN] 否则两个视图尚无法换算，保持原行为。
        return frame
    }

    #if DEBUG
    /**
     * FIX: issue #662 (PR #665) — a DEBUG diagnostic, not a fix.
     * [EN] Logs the first ancestor that clips the tab bar vertically (clipsToBounds or a layer mask) while it rides the sliding
     *      page, once per transition (reported on iPhone Duo, folded).
     * [CN] 每次转场打印第一个在竖直方向裁切 TabBar 的祖先视图（clipsToBounds 或 layer.mask）（iPhone Duo 折叠状态下的反馈）。
     */
    private func cylFlatDesignLogTabBarClippingInParallaxOverlay() {
        guard let tabBar = cyl_tabBar, let window = tabBar.window else {
            return
        }
        let tabBarInWindow = tabBar.convert(tabBar.bounds, to: window)
        var ancestor = tabBar.superview
        while let current = ancestor, current !== window {
            defer { ancestor = current.superview }
            let maskLayer = current.layer.mask
            guard current.clipsToBounds || maskLayer != nil else {
                continue
            }
            let clipRect = maskLayer.map { current.layer.convert($0.frame, to: window.layer) } ?? current.convert(current.bounds, to: window)
            let visibleRect = tabBarInWindow.intersection(clipRect)
            if visibleRect.height < tabBarInWindow.height - 0.5 {
                NSLog("[CYL #662] tab bar clipped vertically by %@ (%@): tabBar=%@ clip=%@ visibleHeight=%.1f window=%@ windowSafe=%@",
                      NSStringFromClass(type(of: current)), maskLayer != nil ? "layer.mask" : "clipsToBounds",
                      NSCoder.string(for: tabBarInWindow), NSCoder.string(for: clipRect), visibleRect.height,
                      NSCoder.string(for: window.bounds), NSCoder.string(for: window.safeAreaInsets))
                return
            }
        }
    }
    #endif

    /**
     * [EN] The bottom of the selected child's additional safe area insets follows the FlatDesign tab bar (hidden: 0).
     * [CN] 选中子控制器 additionalSafeAreaInsets 的底部跟随扁平样式 TabBar（隐藏时为 0）。
     */
    @objc(_updateAdditionalSafeAreaInsetsWithAnimated:)
    func cylFlatDesignUpdateAdditionalSafeAreaInsets(animated: Bool) {
        guard let tabBar = cylFlatDesignTabBar else {
            return
        }
        let selected = selectedViewController
        var insets = selected?.additionalSafeAreaInsets ?? .zero
        insets.bottom = tabBar.isHidden ? 0 : tabBarHeight
        let apply = {
            selected?.additionalSafeAreaInsets = insets
            if self.cylFlatDesignShowsMoreNavigationController(), self.moreNavigationController !== selected {
                Self.cylSetAdditionalSafeAreaBottom(self.moreNavigationController, insets.bottom)
            }
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: apply)
        } else {
            apply()
        }
    }

    /// [EN] Replaces one FlatDesign item. [CN] 替换一个扁平样式 item。
    @objc(changeItem:toItem:)
    func cylFlatDesignChangeItem(_ item: CYLFlatDesignTabBarItem, toItem: CYLFlatDesignTabBarItem) {
        guard let tabBar = cylFlatDesignTabBar, let items = cylFlatDesignHost.items() else {
            return
        }
        let index = items.index(of: item)
        guard index != NSNotFound else {
            return
        }
        items.replaceObject(at: index, with: toItem)
        tabBar.items = items.compactMap { $0 as? CYLFlatDesignTabBarItem }
    }
}
