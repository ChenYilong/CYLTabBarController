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
    @objc(_updateAdditionalSafeAreaInsetsWithAnimated:) func updateAdditionalSafeAreaInsets(animated: Bool)
    @objc(_cyl_refreshSystemTabBarVisibilityIfNeeded) func refreshSystemTabBarVisibilityIfNeeded()
    @objc(_showsMoreNavigationController) func showsMoreNavigationController() -> Bool
    @objc(_shouldShowsBottomBar) func shouldShowsBottomBar() -> Bool
    @objc(_addParallaxOverlayViewToViewController:) func addParallaxOverlayView(to viewController: UIViewController)
    @objc(_updateBottomBarShowHideIfNeeded) func updateBottomBarShowHideIfNeeded()
    @objc(tabBarFrame) func tabBarFrame() -> CGRect
    @objc(parallaxOverlayView) func parallaxOverlayView() -> UIView?
    @objc(setParallaxOverlayView:) func setParallaxOverlayView(_ view: UIView?)
    @objc(cylDidRefreshSystemTabBarVisibility) func didRefreshSystemTabBarVisibility() -> Bool
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
            if cylFlatDesignHost.showsMoreNavigationController(), moreNavigationController !== selectedViewController {
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
            self.cylFlatDesignHost.updateAdditionalSafeAreaInsets(animated: false)
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
        let showsTabBar = cylFlatDesignHost.shouldShowsBottomBar()
        if operation == .push {
            if !showsTabBar && !tabBar.isHidden, let fromVC {
                cylFlatDesignHost.addParallaxOverlayView(to: fromVC)
            }
        } else if showsTabBar && tabBar.isHidden, let toVC {
            cylFlatDesignHost.addParallaxOverlayView(to: toVC)
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
        host.updateBottomBarShowHideIfNeeded()
        // [EN] A refresh deferred while the bar was in the transition overlay is retried after the overlay is removed
        //      (cancellation included). [CN] TabBar 位于转场遮罩中时推迟的刷新，在遮罩移除后重试（包括取消）。
        host.refreshSystemTabBarVisibilityIfNeeded()
        if !host.didRefreshSystemTabBarVisibility() {
            DispatchQueue.main.async { [weak self] in
                self?.cylFlatDesignHost.refreshSystemTabBarVisibilityIfNeeded()
            }
        }
    }
}
