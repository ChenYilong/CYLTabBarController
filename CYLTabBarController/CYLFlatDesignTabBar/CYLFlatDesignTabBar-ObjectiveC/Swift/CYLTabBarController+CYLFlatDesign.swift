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
    @objc(cylRefreshingSystemTabBarVisibility) func refreshingSystemTabBarVisibility() -> Bool
    @objc(setCylRefreshingSystemTabBarVisibility:) func setRefreshingSystemTabBarVisibility(_ value: Bool)
    @objc(setCylDidRefreshSystemTabBarVisibility:) func setDidRefreshSystemTabBarVisibility(_ value: Bool)
    @objc(cylRefreshedSystemTabBarWindow) func refreshedSystemTabBarWindow() -> UIWindow?
    @objc(setCylRefreshedSystemTabBarWindow:) func setRefreshedSystemTabBarWindow(_ window: UIWindow?)
    @objc(cylWaitingForVisibilityTransition) func waitingForVisibilityTransition() -> Bool
    @objc(setCylWaitingForVisibilityTransition:) func setWaitingForVisibilityTransition(_ value: Bool)
    @objc(setTabBarIsAnimating:) func setTabBarIsAnimating(_ value: Bool)
    @objc(needsReloadItems) func needsReloadItems() -> Bool
    @objc(setNeedsReloadItems:) func setNeedsReloadItems(_ value: Bool)
    @objc(addOneChildViewController:idx:WithTitle:normalImageInfo:selectedImageInfo:titlePositionAdjustment:imagePositionAdjustment:imageInsets:lottieURL:lottieFilePath:lottieSizeValue:)
    func addOneChildViewController(_ viewController: UIViewController, idx: UInt, withTitle title: String?, normalImageInfo: Any?,
                                   selectedImageInfo: Any?, titlePositionAdjustment: UIOffset, imagePositionAdjustment: UIOffset,
                                   imageInsets: UIEdgeInsets, lottieURL: URL?, lottieFilePath: String?, lottieSizeValue: NSValue?)
    @objc(lastShowHideTabBar) func lastShowHideTabBar() -> Bool
    @objc(setLastShowHideTabBar:) func setLastShowHideTabBar(_ value: Bool)
    @objc(lastShowHideTabBarAnimated) func lastShowHideTabBarAnimated() -> Bool
    @objc(setLastShowHideTabBarAnimated:) func setLastShowHideTabBarAnimated(_ value: Bool)
    @objc(cyl_tabBarHidden) func tabBarHiddenRequest() -> Bool
    @objc(setCyl_tabBarHidden:) func setTabBarHiddenRequest(_ value: Bool)
    @objc(cylDelegateHasWillShowTabBar) func delegateHasWillShowTabBar() -> Bool
    @objc(setCylDelegateHasWillShowTabBar:) func setDelegateHasWillShowTabBar(_ value: Bool)
    @objc(cylDelegateHasDidShowTabBar) func delegateHasDidShowTabBar() -> Bool
    @objc(setCylDelegateHasDidShowTabBar:) func setDelegateHasDidShowTabBar(_ value: Bool)
    @objc(cylDelegateHasWillHideTabBar) func delegateHasWillHideTabBar() -> Bool
    @objc(setCylDelegateHasWillHideTabBar:) func setDelegateHasWillHideTabBar(_ value: Bool)
    @objc(cylDelegateHasDidHideTabBar) func delegateHasDidHideTabBar() -> Bool
    @objc(setCylDelegateHasDidHideTabBar:) func setDelegateHasDidHideTabBar(_ value: Bool)
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
            self.cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded()
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
            cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded()
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
        cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded()
        if !host.didRefreshSystemTabBarVisibility() {
            DispatchQueue.main.async { [weak self] in
                self?.cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded()
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
        return !isTabBarHidden && cylFlatDesignCheckHidesBottomBarWhenPushed()
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

    // MARK: - In-place update (docs/Swift-Migration.md, step 73; `CYLFlatDesignTabBarItemUpdating` in Core)

    /**
     * [EN] Sets what is given on the tab's FlatDesign item (each change posts `CYLFlatDesignTabBarItemDidChange`, and its button
     *      lays itself out again). A title is set only when it changes. NO when the tab has no FlatDesign item.
     * [CN] 设置该 Tab 扁平样式 item 的给定属性（每次变化都会发送 `CYLFlatDesignTabBarItemDidChange`，其按钮随之重新布局）。标题变化时才设置。
     *      该 Tab 没有扁平样式 item 时返回 NO。
     */
    @objc(cyl_flatDesignUpdateTabBarItemOfViewController:title:image:selectedImage:)
    func cylFlatDesignUpdateTabBarItem(of viewController: UIViewController, title: String?, image: UIImage?, selectedImage: UIImage?) -> Bool {
        guard let item = viewController.cyl_tabBarItem else {
            return false
        }
        if let title, item.title != title {
            item.title = title
        }
        if let image {
            item.image = image
        }
        if let selectedImage {
            item.selectedImage = selectedImage
        }
        return true
    }

    /// [EN] The tab's FlatDesign item plays `URL`. [CN] 该 Tab 的扁平样式 item 播放 `URL`。
    @objc(cyl_flatDesignSetAnimationURL:ofViewController:)
    func cylFlatDesignSetAnimationURL(_ URL: URL, of viewController: UIViewController) {
        viewController.cyl_tabBarItem?.lottieURL = URL
    }

    // MARK: - System tab bar visibility (docs/Swift-Migration.md, step 74)

    /**
     * FIX: issue #662 (iOS 27.1+)
     * [EN] 1.99.65 hides the system bar view in `-initWithFrame:` (enough on iOS 27.0). From iOS 27.1, UIKit still reserves the
     *      system bar's height in the children's safe area at first display: the `-setTabBarHidden:YES` sent from `viewDidLoad`
     *      happens before the controller is in a window and is not applied to UIKit's controller-level state (34 + 49 + 49 =
     *      132 instead of 83). UIKit's state is toggled once the selected child is in the window, without animating the bar;
     *      a transition in progress is waited for.
     * [CN] 1.99.65 只在 `-initWithFrame:` 里隐藏了系统 TabBar 视图（iOS 27.0 够用）。iOS 27.1 起，首次显示时 UIKit 仍为系统 TabBar 预留高度：
     *      `viewDidLoad` 里的 `-setTabBarHidden:YES` 发生在进入 window 之前，没有生效（132 而不是 83）。在选中的子控制器进入 window 后，无动画地刷新一次
     *      UIKit 的状态；有转场时等待其结束。
     */
    @objc(_cyl_refreshSystemTabBarVisibilityIfNeeded)
    func cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded() {
        guard #available(iOS 27.1, *) else {
            return
        }
        let host = cylFlatDesignHost
        guard !host.refreshingSystemTabBarVisibility(), cylFlatDesignTabBar != nil else {
            return
        }
        let selected = selectedViewController
        guard let window = viewIfLoaded?.window, !window.isHidden, selected?.viewIfLoaded?.window === window else {
            return
        }
        if host.didRefreshSystemTabBarVisibility() && host.refreshedSystemTabBarWindow() === window {
            return
        }
        if host.tabBarIsAnimating() || host.parallaxOverlayView() != nil {
            return
        }
        if let coordinator = selected?.transitionCoordinator ?? transitionCoordinator {
            if !host.waitingForVisibilityTransition() {
                host.setWaitingForVisibilityTransition(true)
                let registered = coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.cylFlatDesignHost.setWaitingForVisibilityTransition(false)
                    DispatchQueue.main.async {
                        self.cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded()
                    }
                }
                if !registered {
                    host.setWaitingForVisibilityTransition(false)
                }
            }
            return
        }
        host.setRefreshingSystemTabBarVisibility(true)
        host.setDidRefreshSystemTabBarVisibility(true)
        host.setRefreshedSystemTabBarWindow(window)
        UIView.performWithoutAnimation {
            super.setTabBarHidden(false, animated: false)
            // [EN] If the KVC replacement failed, UIKit's original bar lacks the always-hidden setter of CYLFlatDesignTabBarHideTabBar.
            // [CN] 若 KVC 替换失败，UIKit 原有的 TabBar 没有 CYLFlatDesignTabBarHideTabBar 的始终隐藏 setter。
            if !self.tabBar.isHidden { self.tabBar.isHidden = true }
            super.setTabBarHidden(true, animated: false)
            if !self.tabBar.isHidden { self.tabBar.isHidden = true }
        }
        host.setRefreshingSystemTabBarVisibility(false)
    }

    // MARK: - Hiding the tab bar (docs/Swift-Migration.md, step 75; `CYLFlatDesignTabBarHiding` in Core)

    /**
     * [EN] Whether the page on screen lets the tab bar show: `hidesBottomBarWhenPushed` of the navigation stack (or of the page),
     *      the More navigation controller included.
     * [CN] 当前页面是否允许显示 TabBar：导航栈（或页面）的 `hidesBottomBarWhenPushed`，包括 More 导航控制器。
     */
    @objc(_checkHidesBottomBarWhenPushed)
    func cylFlatDesignCheckHidesBottomBarWhenPushed() -> Bool {
        guard cylFlatDesignTabBar != nil else {
            return true
        }
        var selected = selectedViewController
        if cylFlatDesignShowsMoreNavigationController(),
           let moreIndex = (tabBar.items ?? []).firstIndex(where: { $0 === moreNavigationController.tabBarItem }),
           selectedIndex >= moreIndex || selectedIndex == NSNotFound {
            selected = moreNavigationController
        }
        if let navigationController = selected as? UINavigationController {
            let stack = navigationController.viewControllers
            let currentIndex = navigationController.topViewController.flatMap { top in stack.firstIndex { $0 === top } } ?? NSNotFound
            var showsBottomBarIndex = -1
            for (index, viewController) in stack.enumerated() {
                if viewController.hidesBottomBarWhenPushed {
                    showsBottomBarIndex = index - 1
                    break
                }
                showsBottomBarIndex = index
            }
            return currentIndex <= showsBottomBarIndex
        }
        return !(selected?.hidesBottomBarWhenPushed ?? false)
    }

    /// [EN] Sends a show / hide callback to the delegate. [CN] 向 delegate 发送显示 / 隐藏回调。
    private func cylFlatDesignSendTabBarCallback(_ selectorName: String, tabBar: UIView) {
        _ = (delegate as AnyObject?)?.perform(NSSelectorFromString(selectorName), with: self, with: tabBar)
    }

    /// [EN] The will-hide / will-show callback, when the delegate answers it. [CN] delegate 响应时发送 will-hide / will-show 回调。
    private func cylFlatDesignSendWillCallback(hidden: Bool, tabBar: UIView) {
        let host = cylFlatDesignHost
        if hidden, host.delegateHasWillHideTabBar() {
            cylFlatDesignSendTabBarCallback("tabBarController:willHideTabBar:", tabBar: tabBar)
        } else if !hidden, host.delegateHasWillShowTabBar() {
            cylFlatDesignSendTabBarCallback("tabBarController:willShowTabBar:", tabBar: tabBar)
        }
    }

    /// [EN] The did-hide / did-show callback, when the delegate answers it. [CN] delegate 响应时发送 did-hide / did-show 回调。
    private func cylFlatDesignSendDidCallback(hidden: Bool, tabBar: UIView) {
        let host = cylFlatDesignHost
        if hidden, host.delegateHasDidHideTabBar() {
            cylFlatDesignSendTabBarCallback("tabBarController:didHideTabBar:", tabBar: tabBar)
        } else if !hidden, host.delegateHasDidShowTabBar() {
            cylFlatDesignSendTabBarCallback("tabBarController:didShowTabBar:", tabBar: tabBar)
        }
    }

    /**
     * [EN] Shows or hides the FlatDesign tab bar (the system one stays hidden), optionally animated, with the delegate's
     *      will / did callbacks. FIX: issue #662 — the request is recorded before any early return, so `isTabBarHidden` always
     *      reports the newest one: a request during the animation is replayed when it ends (with its own `animated`), and one
     *      during a navigation transition is applied when the bar returns. `hidesBottomBarWhenPushed` wins. A delegate that
     *      re-enters with the opposite request wins too.
     * [CN] 显示或隐藏扁平样式 TabBar（系统 TabBar 保持隐藏），可选动画，并发送 delegate 的 will / did 回调。FIX: issue #662——在任何提前返回之前记录请求，
     *      `isTabBarHidden` 始终是最新请求：动画期间的请求在动画结束时重放（使用它自己的 animated），转场期间的请求在 TabBar 回来后应用。
     *      `hidesBottomBarWhenPushed` 优先。在回调中反向重入的 delegate 也以其请求为准。
     */
    @objc(cyl_flatDesignSetTabBarHidden:animated:)
    func cylFlatDesignSetTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard let flatTabBar = cylFlatDesignTabBar else {
            return
        }
        let host = cylFlatDesignHost
        // [EN] Hide the system tab bar; KVC may have left UIKit's original bar installed. [CN] 隐藏系统 TabBar；KVC 可能留下了 UIKit 原有的 TabBar。
        if #available(iOS 18.0, *) {
            super.setTabBarHidden(true, animated: animated)
        } else {
            tabBar.isHidden = true
        }
        if !tabBar.isHidden { tabBar.isHidden = true }
        host.setTabBarHiddenRequest(hidden)
        host.setLastShowHideTabBar(hidden)
        if host.tabBarIsAnimating() {
            host.setLastShowHideTabBarAnimated(animated)
            return
        }
        guard flatTabBar.superview === view else {
            return
        }
        // [EN] Compare with what is on screen, not with the recorded state: a request recorded during an animation is replayed
        //      here and must still be applied. [CN] 与屏幕上的实际状态比较，而不是与记录值比较：动画期间记录的请求会在这里重放，仍需生效。
        guard flatTabBar.isHidden != hidden, cylFlatDesignCheckHidesBottomBarWhenPushed() else {
            return
        }
        // FIX: issue #662 — a bar hidden before the first layout can still have a stale (zero-height) frame.
        // [CN] 首次布局前就隐藏的 TabBar 可能保留旧的（高度为 0 的）frame。
        if !hidden && flatTabBar.frame != host.tabBarFrame() {
            flatTabBar.frame = host.tabBarFrame()
        }
        guard animated else {
            cylFlatDesignSendWillCallback(hidden: hidden, tabBar: flatTabBar)
            // FIX: issue #662 — a delegate re-entered with the opposite request and already applied it. [CN] 代理已反向重入并生效。
            if host.tabBarHiddenRequest() != hidden {
                return
            }
            flatTabBar.isHidden = hidden
            cylFlatDesignUpdateAdditionalSafeAreaInsets(animated: animated)
            cylFlatDesignSendDidCallback(hidden: hidden, tabBar: flatTabBar)
            return
        }
        host.setTabBarIsAnimating(true)
        cylFlatDesignSendWillCallback(hidden: hidden, tabBar: flatTabBar)
        // FIX: issue #662 — a delegate may re-enter with the opposite request; it was recorded and queued, and it wins.
        // [CN] 代理回调里可能反向重入，以重入的最新请求为准。
        if host.tabBarHiddenRequest() != hidden {
            host.setTabBarIsAnimating(false)
            setTabBarHidden(host.lastShowHideTabBar(), animated: host.lastShowHideTabBarAnimated())
            return
        }
        let height = flatTabBar.frame.height
        flatTabBar.transform = hidden ? .identity : CGAffineTransform(translationX: 0, y: height)
        flatTabBar.isHidden = false
        UIView.animate(withDuration: Self.cylTabBarHideShowDuration, animations: {
            flatTabBar.transform = hidden ? CGAffineTransform(translationX: 0, y: height) : .identity
        }, completion: { _ in
            flatTabBar.transform = .identity
            flatTabBar.isHidden = hidden
            self.cylFlatDesignUpdateAdditionalSafeAreaInsets(animated: animated)
            let host = self.cylFlatDesignHost
            host.setTabBarIsAnimating(false)
            self.cylFlatDesignSendDidCallback(hidden: hidden, tabBar: flatTabBar)
            // [EN] A different request arrived during the animation (two within 0.2 s): replay it with its own `animated`.
            // [CN] 动画期间收到了不同的请求（两次间隔小于 0.2 秒）：按它自己的 animated 重放。
            if host.lastShowHideTabBar() != hidden {
                self.setTabBarHidden(host.lastShowHideTabBar(), animated: host.lastShowHideTabBarAnimated())
            }
            self.cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded()
        })
    }

    /// [EN] Remembers which show / hide callbacks the delegate answers. [CN] 记录 delegate 响应哪些显示 / 隐藏回调。
    @objc(cyl_flatDesignDelegateDidChange:)
    func cylFlatDesignDelegateDidChange(_ delegate: AnyObject?) {
        guard cylFlatDesignTabBar != nil else {
            return
        }
        let host = cylFlatDesignHost
        let answers = { (name: String) in delegate?.responds(to: NSSelectorFromString(name)) ?? false }
        host.setDelegateHasWillShowTabBar(answers("tabBarController:willShowTabBar:"))
        host.setDelegateHasDidShowTabBar(answers("tabBarController:didShowTabBar:"))
        host.setDelegateHasWillHideTabBar(answers("tabBarController:willHideTabBar:"))
        host.setDelegateHasDidHideTabBar(answers("tabBarController:didHideTabBar:"))
    }

    // MARK: - Adding a tab (docs/Swift-Migration.md, step 76; `CYLFlatDesignChildSetup` in Core)

    /**
     * [EN] Adds the FlatDesign item of the tab at `idx`, from the attributes read once for every style (FIX: issue #604).
     * [CN] 根据为所有样式统一读取一次的属性（FIX: issue #604），添加第 `idx` 个 Tab 的扁平样式 item。
     */
    @objc(setupChildViewController:idx:)
    func cylFlatDesignSetupChildViewController(_ viewController: UIViewController, idx: UInt) {
        guard cylFlatDesignTabBar != nil else {
            return
        }
        let setup = cylTabBarItemSetup(for: viewController, idx: idx)
        cylFlatDesignHost.addOneChildViewController(viewController, idx: setup.idx, withTitle: setup.title,
                                                    normalImageInfo: setup.normalImageInfo, selectedImageInfo: setup.selectedImageInfo,
                                                    titlePositionAdjustment: setup.titlePositionAdjustment,
                                                    imagePositionAdjustment: setup.imagePositionAdjustment, imageInsets: setup.imageInsets,
                                                    lottieURL: setup.animationURL, lottieFilePath: setup.animationFilePath,
                                                    lottieSizeValue: setup.animationSizeValue)
    }

    // MARK: - Selection (docs/Swift-Migration.md, step 77; `CYLFlatDesignSelection` in Core)

    /**
     * [EN] Selects the FlatDesign item of `selectedIndex` (UIKit's More item for a tab under "More").
     * [CN] 选中 `selectedIndex` 对应的扁平样式 item（收在「More」下的 Tab 选中 UIKit 的 More 项）。
     */
    @objc(tabChangedToSelectedIndex:viewController:selectedItem:)
    func cylFlatDesignTabChanged(toSelectedIndex selectedIndex: UInt, viewController: UIViewController?, selectedItem: CYLFlatDesignTabBarItem?) {
        guard let flatTabBar = cylFlatDesignTabBar, let items = cylFlatDesignHost.items() as? [CYLFlatDesignTabBarItem], !items.isEmpty else {
            return
        }
        var item: CYLFlatDesignTabBarItem?
        if cylFlatDesignShowsMoreNavigationController(),
           let moreIndex = (tabBar.items ?? []).firstIndex(where: { $0 === moreNavigationController.tabBarItem }),
           Int(selectedIndex) >= moreIndex {
            item = moreNavigationController.cyl_tabBarItem
        } else if Int(selectedIndex) < items.count {
            item = items[Int(selectedIndex)]
        }
        flatTabBar.selectedItem = item
    }

    /**
     * [EN] After `-setSelectedViewController:`: the stored index follows the view controller (any style, as before); in the
     *      FlatDesign style the plus button and the item follow too, and the bar's visibility is updated.
     * [CN] `-setSelectedViewController:` 之后：存储的下标跟随控制器（所有样式，与之前相同）；扁平样式下 PlusButton 与 item 也随之更新，并更新 TabBar 的可见性。
     */
    @objc(cyl_flatDesignDidSetSelectedViewController:)
    func cylFlatDesignDidSetSelectedViewController(_ selectedViewController: UIViewController) {
        guard let index = (viewControllers ?? []).firstIndex(where: { $0 === selectedViewController }) else {
            return
        }
        cylPrivate.cylSetSelectedIndexStorage(UInt(index))
        guard cylFlatDesignTabBar != nil else {
            return
        }
        if let plusChild = cylPrivate.cylContextPlusChildViewController(), selectedViewController.isEqual(plusChild) {
            cylPrivate.cylContextPlusButton()?.isSelected = true
        }
        cylFlatDesignTabChanged(toSelectedIndex: UInt(index), viewController: selectedViewController, selectedItem: nil)
        cylFlatDesignUpdateBottomBarShowHideIfNeeded()
    }

    /**
     * [EN] `-setSelectedIndex:` in the FlatDesign style. FIX: placeholder count mismatch — `selectedIndex` counts the slot, the
     *      system list (`super.viewControllers`) has no placeholder and has the plus child view controller at its end: super gets
     *      the index of the same view controller in its own list. The stored index is already the new one, so super would see no
     *      change and not show the tab: it is shown through super, as a tap does.
     * [CN] 扁平样式下的 `-setSelectedIndex:`。FIX：占位导致的数量不匹配——`selectedIndex` 计入了 slot，而系统列表（`super.viewControllers`）中没有占位控制器，
     *      PlusButton 子控制器位于末尾：传给 super 的是同一个控制器在系统列表中的下标。存储的下标已是新值，super 会认为没有变化而不显示该 Tab：这里与点击一样通过 super 显示。
     */
    @objc(cyl_flatDesignSetSelectedIndex:)
    func cylFlatDesignSetSelectedIndex(_ selectedIndex: UInt) {
        guard let flatTabBar = cylFlatDesignTabBar else {
            return
        }
        let viewControllers = self.viewControllers ?? []
        if UInt(self.selectedIndex) != selectedIndex {
            cylPrivate.cylSetSelectedIndexStorage(selectedIndex)
            let viewControllerToSelect = selectedIndex < UInt(viewControllers.count) ? viewControllers[Int(selectedIndex)] : nil
            if let viewControllerToSelect, let systemIndex = (super.viewControllers ?? []).firstIndex(where: { $0 === viewControllerToSelect }) {
                super.selectedIndex = systemIndex
            }
            guard let viewControllerToSelect else {
                return
            }
            super.selectedViewController = viewControllerToSelect
            cylPrivate.cylSetSelectedViewControllerStorage(viewControllerToSelect)
            let host = cylFlatDesignHost
            if host.needsReloadItems() {
                cylFlatDesignCaptureItems()
                flatTabBar.items = (host.items() as? [CYLFlatDesignTabBarItem]) ?? []
                host.setNeedsReloadItems(false)
            }
            cylFlatDesignTabChanged(toSelectedIndex: selectedIndex, viewController: nil, selectedItem: nil)
        }
        // FIX: issue #433 — the selected tab shows its selected title. [CN] 选中的 Tab 显示选中标题。
        cylSetNeedsUpdateTabBarItemSelectedTitles(self)
        cylFlatDesignUpdateBottomBarShowHideIfNeeded()
    }
}
