//
//  CYLTabBarController+CYLLifeCycle.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The FlatDesign side of the life cycle, implemented in the FlatDesign subspec (CYLTabBarController+CYLFlatDesign.swift).
 *      Optional: without that subspec nothing answers.
 * [CN] 生命周期的扁平样式部分，由扁平样式子库实现。可选：没有该子库时无人响应。
 */
@objc protocol CYLFlatDesignLifeCycle {
    @objc(_cyl_refreshSystemTabBarVisibilityIfNeeded) optional func cylRefreshSystemTabBarVisibilityIfNeeded()
}

/**
 * FIX: issue #433
 * [EN] Applies the selected titles now, and once more on the next main-queue turn: in the classic style the button's action can
 *      run before UIKit has changed `selectedViewController`. C name kept for CYLTabBarController.m.
 * [CN] 立即应用选中标题，并在主队列的下一轮再应用一次：经典样式中按钮事件可能在 UIKit 修改 `selectedViewController` 之前执行。保留 C 名称。
 */
@_cdecl("CYLSetNeedsUpdateTabBarItemSelectedTitles")
func cylSetNeedsUpdateTabBarItemSelectedTitles(_ tabBarController: CYLTabBarController?) {
    guard let tabBarController else {
        return
    }
    cylApplyTabBarItemSelectedTitles(tabBarController)
    DispatchQueue.main.async { [weak tabBarController] in
        cylApplyTabBarItemSelectedTitles(tabBarController)
    }
}

/**
 * [EN] The life cycle and the tab change of `CYLTabBarController`, translated from Objective-C (docs/Swift-Migration.md, step 74).
 *      The UIKit overrides stay in CYLTabBarController.m as one-line forwarders to the `cyl_…` methods below (a public Swift
 *      override would put an extension of this class into the generated header before the class); these call `super`.
 * [CN] `CYLTabBarController` 的生命周期与 Tab 切换，已从 Objective-C 翻译（docs/Swift-Migration.md，第 74 步）。UIKit 重写保留在
 *      CYLTabBarController.m 中，只有一行，转发给下面的 `cyl_…` 方法（公开的 Swift 重写会把本类的扩展放到生成头文件中、类声明之前）；由这些方法调用 `super`。
 */
extension CYLTabBarController {

    private enum CYLLifeCycleState {
        /// [EN] The scroll hiding self-test runs once per launch. [CN] 滚动隐藏自测每次启动只运行一次。
        static var didStartScrollHideSelfTest = false
    }

    // MARK: - Appearance

    /**
     * [EN] Every style. FlatDesign: refresh the system tab bar's visibility. Scroll hiding (issue #13): appearing ends any hide
     *      session, so the tab bar is shown.
     * [CN] 所有样式。扁平样式：刷新系统 TabBar 的可见性。滚动隐藏（issue #13）：出现时结束隐藏会话，TabBar 恢复显示。
     */
    @objc(cyl_viewDidAppear:)
    func cylViewDidAppear(_ animated: Bool) {
        unsafeBitCast(self, to: CYLFlatDesignLifeCycle.self).cylRefreshSystemTabBarVisibilityIfNeeded?()
        cylTabBarMinimizeLifecycleEvent()
        // [EN] Scroll hiding self-test (issue #13), only when launched with `-CYLScrollHideSelfTest YES`: runs once.
        // [CN] 滚动隐藏自测（issue #13），仅在以 `-CYLScrollHideSelfTest YES` 启动时：只运行一次。
        if !CYLLifeCycleState.didStartScrollHideSelfTest && UserDefaults.standard.bool(forKey: "CYLScrollHideSelfTest") {
            CYLLifeCycleState.didStartScrollHideSelfTest = true
            cylStartScrollHideSelfTestWhenActive(attempt: 0)
        }
    }

    /**
     * [EN] Issue #13: the launch self-test starts once the app is active and the first page is laid out (at the first
     *      viewDidAppear the app can still be inactive, and scroll hiding refuses to hide an inactive window). Checks every
     *      0.5 s, for at most 20 s.
     * [CN] Issue #13：启动自测在 App 进入活跃状态、首个页面完成布局之后开始（第一次 viewDidAppear 时 App 可能仍未活跃，滚动隐藏不会隐藏非活跃窗口中的
     *      TabBar）。每 0.5 秒检查一次，最多 20 秒。
     */
    @objc(cyl_startScrollHideSelfTestWhenActiveWithAttempt:)
    func cylStartScrollHideSelfTestWhenActive(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else {
                return
            }
            let active = UIApplication.shared.applicationState == .active && self.view.window != nil
            if !active && attempt < 40 {
                self.cylStartScrollHideSelfTestWhenActive(attempt: attempt + 1)
                return
            }
            var page = self.selectedViewController
            if let navigationController = page as? UINavigationController {
                page = navigationController.topViewController
            }
            page?.view.layoutIfNeeded()
            page?.cyl_runScrollHideSelfTest()
        }
    }

    /**
     * [EN] Scroll hiding (issue #13): disappearing (a full-screen modal, a push over this controller, a tab of an outer controller)
     *      ends any hide session, so the tab bar is shown when this controller comes back.
     * [CN] 滚动隐藏（issue #13）：消失时（全屏模态页面、在本控制器之上 push、外层控制器切换 Tab）结束隐藏会话，回来时 TabBar 正常显示。
     */
    @objc(cyl_viewWillDisappear:)
    func cylViewWillDisappear(_ animated: Bool) {
        cylTabBarMinimizeLifecycleEvent()
    }

    @objc(cyl_viewDidDisappear:)
    func cylViewDidDisappear(_ animated: Bool) {
        cylTabBarMinimizeLifecycleEvent()
    }

    /**
     * [EN] Every style: this controller becomes the most recently active one (`+cyl_activeTabBarController`), which
     *      `-cyl_tabBarController` falls back to for an object that is not inside any tab bar controller.
     * [CN] 所有样式：本控制器成为最近活跃的控制器（`+cyl_activeTabBarController`），对象不在任何 TabBarController 内时，`-cyl_tabBarController` 会回退到它。
     */
    @objc(cyl_viewWillAppear:)
    func cylViewWillAppear(_ animated: Bool) {
        CYLTabBarController.cylMarkActive(self)
        // FIX: issue #216
        cylApplyLaunchTabBarThemeIfNeeded()
        cylSetNeedsUpdateSelectedBackgroundColors()
        // FIX: issue #152 — the long press, only when someone listens. [CN] 仅在有接收方时添加长按手势。
        cylInstallTabBarItemLongPressIfNeeded()
        // FIX: issue #433 — the selected tab shows its selected title. [CN] 选中的 Tab 显示选中标题。
        cylApplyTabBarItemSelectedTitles(self)
        // [EN] Scroll hiding (issue #13): appearing ends any hide session. [CN] 滚动隐藏（issue #13）：出现时结束隐藏会话。
        cylTabBarMinimizeLifecycleEvent()
    }

    // MARK: - Tab change (not FlatDesign)

    /**
     * [EN] The action of a tab button (not FlatDesign).
     * [CN] Tab 按钮的事件（非扁平样式）。
     */
    @objc(tabChangedToControl:)
    func cylTabChanged(to tappedControl: UIControl) {
        guard tabBarStyleType != .flatDesign else {
            return
        }
        let viewControllers = self.viewControllers ?? []
        // FIX: issue #19
        // [EN] This action runs after UIKit asked `-tabBarController:shouldSelectViewController:`, also when it was refused: a
        //      tab that needs login must not be marked selected or play its animation here.
        // [CN] 该事件在 UIKit 询问 `-tabBarController:shouldSelectViewController:` 之后执行，即使被拒绝也会执行：需要登录的 Tab 不能在这里被设为选中或播放动画。
        let tappedIndex = tappedControl.cyl_tabBarChildViewControllerIndex
        let tappedViewController = !tappedControl.cyl_isPlusControl() && tappedIndex >= 0 && tappedIndex < viewControllers.count
            ? viewControllers[tappedIndex] : nil
        if let tappedViewController, cylInterceptLoginIfNeeded(for: tappedViewController) {
            return
        }
        // [EN] A custom action tab (CYLCustomTabAction) runs the action instead (once per tap). Liquid Glass calls this from the
        //      gesture delegate when a touch begins, and checks the tap in `-tabBarController:shouldSelectViewController:`.
        // [CN] 使用自定义点击操作的 Tab（CYLCustomTabAction）改为执行对应操作（每次点击一次）。液态玻璃在手指按下时从手势代理调用本方法，点击本身在
        //      `-tabBarController:shouldSelectViewController:` 中检查。
        if !CYLConstants.isLiquidGlassActive(), let candidate = cylViewController(forTabControl: tappedControl),
           cylPerformCustomTabActionIfNeeded(for: candidate) {
            return
        }
        // FIX: issue #232
        // [EN] `-tabBarController:shouldSelectViewController:` returned NO for the tapped tab: the selected tab did not change.
        //      Leave the tab bar as it is, as for a tab that needs login (#19). The "More" tab selects
        //      `moreNavigationController`, which is not a refusal.
        // [CN] `-tabBarController:shouldSelectViewController:` 对被点击的 Tab 返回了 NO：选中的 Tab 没有变化。与需要登录的 Tab（#19）一样，保持 TabBar 不变。
        //      “更多”Tab 选中的是 `moreNavigationController`，不算被拒绝。
        if let tappedViewController, let selected = selectedViewController, selected !== moreNavigationController,
           tappedViewController !== selected {
            return
        }
        let control = cylTabButtonReplacingTappedControl(tappedControl)
        cylTabChanged(toSelectedViewController: nil, control: control)
        cylSetNeedsUpdateSelectedBackgroundColors()
    }

    @objc(tabChangedToSelectedViewController:control:)
    func cylTabChanged(toSelectedViewController viewController: UIViewController?, control: UIControl?) {
        guard tabBarStyleType != .flatDesign else {
            return
        }
        cylTabChanged(toSelectedIndex: UInt(selectedIndex), viewController: viewController, control: control)
    }

    /**
     * [EN] Called from three places: a tap on the selected tab (on iOS 26, hooked in through the gesture delegate), a tab
     *      selected by the user, and a tab selected in code.
     * [CN] 三个地方都要调用：选中状态下的重新点击（iOS 26 需要在手势代理方法中追加），用户切换 Tab，代码切换 Tab。
     */
    @objc(tabChangedToSelectedIndex:viewController:control:)
    func cylTabChanged(toSelectedIndex selectedIndex: UInt, viewController: UIViewController?, control: UIControl?) {
        guard tabBarStyleType != .flatDesign, cyl_tabBar is UITabBar else {
            return
        }
        if viewController?.cyl_isPlaceholder == true {
            return
        }
        let viewController = viewController ?? selectedViewController
        let control = control ?? viewController?.cyl_getViewControllerInsteadOfNavigation().cyl_tabButton ?? viewController?.cyl_tabButton
        if let viewController {
            cylUpdateSelectionStatusIfNeeded(for: nil, shouldSelect: viewController)
        }
        if let control {
            cylDidSelectControl(control)
        }
        // FIX: issue #433
        // [EN] Classic taps come here, not always through `-setSelectedViewController:`.
        // [CN] 经典样式的点击会到这里，不一定经过 `-setSelectedViewController:`。
        cylSetNeedsUpdateTabBarItemSelectedTitles(self)
        let isChildViewControllerPlusButton = control?.cyl_isChildViewControllerPlusButton() ?? false
        // [EN] Shared by Liquid Glass and the other styles: the Lottie playback lives here.
        // [CN] 液态玻璃与其他样式共用：Lottie 播放逻辑都在这里。
        if cylIsLottieEnabled(), !isChildViewControllerPlusButton, selectedViewController?.cyl_isPlaceholder != true,
           let control, let item = viewController?.tabBarItem {
            cylAddLottieImage(withControl: control, lottieURL: item.cyl_tabBarItemAnimationURL,
                                         lottieSizeValue: item.cyl_tabBarItemAnimationSizeValue, animation: true)
        }
    }

    /**
     * [EN] Adds the animation views of every tab (not FlatDesign), the selected one playing, on the next main-queue turn.
     * [CN] 在主队列的下一轮为每个 Tab 添加动画视图（非扁平样式），选中的 Tab 播放动画。
     */
    @objc(initLottieTabBar:)
    func cylInitLottieTabBar(_ tabBar: CYLTabBar) {
        guard tabBarStyleType != .flatDesign else {
            return
        }
        DispatchQueue.main.async {
            if CYLConstants.isLiquidGlassActive() {
                for (index, viewController) in (self.viewControllers ?? []).enumerated() {
                    guard let control = viewController.cyl_tabButton, let url = viewController.tabBarItem.cyl_tabBarItemAnimationURL,
                          viewController.cyl_embedInTabBarController, !control.cyl_isPlusControl() else {
                        continue
                    }
                    let defaultSelected = index == self.selectedIndex
                    self.cylAddLottieImage(withControl: control, lottieURL: url,
                                                      lottieSizeValue: viewController.tabBarItem.cyl_tabBarItemAnimationSizeValue,
                                                      animation: defaultSelected, defaultSelected: defaultSelected)
                    self.cylPrivate.cylSetTabBarItemAnimationViewAdded(true)
                }
            } else {
                for (index, tabButton) in tabBar.cylSubTabBarButtonsWithoutPlusButton().enumerated() {
                    // FIX: issue #423
                    // [EN] `index` counts the buttons without the plus button, `selectedIndex` the view controllers, which hold
                    //      the plus child view controller too: compare the button's own tab item; the position is a fallback.
                    // [CN] `index` 不含 PlusButton，`selectedIndex` 却包含 PlusButton 子控制器：改为比较按钮所属的 tabBarItem，按位置比较仅作兜底。
                    let defaultSelected: Bool
                    if let item = self.cylTabBarItem(forTabButton: tabButton) {
                        defaultSelected = item === self.selectedViewController?.tabBarItem
                    } else {
                        defaultSelected = index == self.selectedIndex
                    }
                    self.cylAddLottieImage(withControl: tabButton, animation: defaultSelected, defaultSelected: defaultSelected)
                    self.cylPrivate.cylSetTabBarItemAnimationViewAdded(true)
                }
            }
            // [EN] Icon views installed before the Lottie views (e.g. the icons of the theme chosen at launch) hide them now.
            // [CN] 在 Lottie 视图之前安装的图标视图（例如启动时所选主题的图标）现在将其隐藏。
            self.cylSetNeedsUpdateTabBarItemIconViews()
        }
    }

    // MARK: - The one-time layout block

    /**
     * FIX: issue #539
     * [EN] Sets the one-time layout block and re-arms it, so each block set here runs once at the end of the next
     *      `-viewDidLayoutSubviews`, in every style. `invokeOnce` stays ignored, as documented.
     * [CN] 设置只执行一次的布局 block 并重新启用，使每次设置的 block 都在下一次 `-viewDidLayoutSubviews` 末尾执行一次，适用于所有样式。
     *      `invokeOnce` 参数按文档说明仍被忽略。
     */
    @objc(setViewDidLayoutSubViewsBlockInvokeOnce:block:)
    func cylSetViewDidLayoutSubViewsBlockInvokeOnce(_ invokeOnce: Bool, block: @escaping CYLViewDidLayoutSubViewsBlock) {
        cylPrivate.cylSetInvokeOnceViewDidLayoutSubViewsBlock(true)
        viewDidLayoutSubviewsBlock = block
        cylRearmViewDidLayoutSubviewsBlockInvokeOnce()
    }

    /**
     * [EN] Lets the one-time layout block run once more, at the end of the next `-viewDidLayoutSubviews`: sets the "once" mode
     *      and clears the mark of the run before. Used whenever the tab buttons or their contents are set up again.
     * [CN] 让只执行一次的布局 block 在下一次 `-viewDidLayoutSubviews` 末尾再执行一次：设置“只执行一次”模式，并清除上一次执行的标记。Tab 按钮或其内容重新设置时调用。
     */
    @objc(cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce)
    func cylRearmViewDidLayoutSubviewsBlockInvokeOnce() {
        cylPrivate.cylSetInvokeOnceViewDidLayoutSubViewsBlock(true)
        objc_setAssociatedObject(self, CYLUtilsKeys.key("viewDidLayoutSubviews"), nil, .OBJC_ASSOCIATION_RETAIN)
        if isViewLoaded {
            view.setNeedsLayout()
        }
    }
}
