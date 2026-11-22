//
//  CYLTabBarController+CYLSelection.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] `CYLTabBarController (CYLSelectionStatus)` and the controller's own `-tabBarController:shouldSelectViewController:`.
 *      Translated from Objective-C (docs/Swift-Migration.md, step 61). A subclass that overrides
 *      `-tabBarController:shouldSelectViewController:` still calls super, as before: the selector is unchanged.
 * [CN] `CYLTabBarController (CYLSelectionStatus)` 以及控制器自身的 `-tabBarController:shouldSelectViewController:`。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 61 步）。重写 `-tabBarController:shouldSelectViewController:` 的子类仍与以前一样调用 super：selector 不变。
 */
extension CYLTabBarController {

    /// [EN] The selector's string: the macro `CYLTabBarItemAnimationPlayingNotification` is not imported into Swift.
    /// [CN] 该通知名的字符串：宏 `CYLTabBarItemAnimationPlayingNotification` 不会导入 Swift。
    private static let cylTabBarItemAnimationPlayingNotification = Notification.Name("CYLTabBarItemLottieAnimationPlayingNotification")

    /**
     * [EN] Updates the plus button's selection state before `viewController` is selected, and the plus button's label on a
     *      tab bar that hides it under the plus child view controller's tab. No effect in flat-design mode.
     * [CN] 在选中 viewController 之前更新 PlusButton 的选中状态，以及在 PlusButton 子控制器的 Tab 下隐藏其标签的 TabBar 上更新该标签。
     *      扁平化模式下无效。
     */
    @objc(updateSelectionStatusIfNeededForTabBarController:shouldSelectViewController:)
    open func updateSelectionStatusIfNeeded(for tabBarController: UITabBarController?, shouldSelect viewController: UIViewController) {
        guard tabBarStyleType != .flatDesign else {
            return
        }
        let should = viewController !== tabBarController?.selectedViewController
        updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController, shouldSelect: should)
        // [EN] Guard: only CYLTabBar has the plus button label check; `tabBarController` can have a system tab bar.
        // [CN] 只有 CYLTabBar 才有 PlusButton 标签的判断；`tabBarController` 的 TabBar 可能是系统 TabBar。
        guard let tabBar = tabBarController?.tabBar as? CYLTabBar, tabBar.cylShouldUpdateHiddenStatueForPlusButtonLabel() else {
            return
        }
        let plusChildViewController = cylPrivate.cylContextPlusChildViewController()
        let plusButton = cylPrivate.cylContextPlusButton()
        if should {
            plusButton?.setTabLabelHidden(viewController.isEqual(plusChildViewController))
        }
        if tabBarController?.selectedViewController?.isEqual(plusChildViewController) == true && !should {
            plusButton?.setTabLabelHidden(true)
        }
    }

    /**
     * [EN] Same as above, with an explicit `shouldSelect`: NO only locks the target tab button; YES clears the plus
     *      button's selected state and, for the plus child view controller's page, restarts the tab animations.
     * [CN] 同上，显式传入 shouldSelect：为 NO 时只锁定目标 Tab 按钮；为 YES 时清除 PlusButton 的选中状态，选中 PlusButton 子控制器的页面时重新开始
     *      Tab 动画。
     */
    @objc(updateSelectionStatusIfNeededForTabBarController:shouldSelectViewController:shouldSelect:)
    open func updateSelectionStatusIfNeeded(for _: UITabBarController?, shouldSelect viewController: UIViewController, shouldSelect: Bool) {
        guard tabBarStyleType != .flatDesign else {
            return
        }
        cylControlSetSelectionLockedEntryPoint(viewController.tabBarItem.cyl_tabButton, !shouldSelect)
        guard shouldSelect, hasPlusChildViewController() else {
            return
        }
        let target = viewController
        let plusButton = cylPrivate.cylContextPlusButton()
        if plusButton?.isSelected == true {
            plusButton?.isSelected = false
        }
        if let plusChildViewController = cylPrivate.cylContextPlusChildViewController(), target.cylIsEqual(to: plusChildViewController) {
            NotificationCenter.default.post(name: Self.cylTabBarItemAnimationPlayingNotification, object: self)
        }
    }

    /**
     * [EN] `UITabBarControllerDelegate`: one user tap on a tab, before the selection changes. Refuses a tab that needs login
     *      (issue #19), a custom action tab and a placeholder; otherwise smooths the switch (issue #618) and updates the
     *      plus button. A subclass that overrides it calls super first, and may still return NO.
     * [CN] `UITabBarControllerDelegate`：一次用户点击 Tab，在选中变化之前。拒绝需要登录的 Tab（issue #19）、自定义操作的 Tab 与占位；否则让切换平滑
     *      （issue #618）并更新 PlusButton。子类重写时先调用 super，之后仍可返回 NO。
     */
    // [EN] Called by the Objective-C `-tabBarController:shouldSelectViewController:` (a forwarder): Swift cannot define that
    //      UIKit selector on a class whose delegate conformance is declared in Objective-C.
    // [CN] 由 Objective-C 的 `-tabBarController:shouldSelectViewController:`（转发方法）调用：类的代理协议声明在 Objective-C 中时，Swift
    //      无法在该类上定义这个 UIKit selector。
    @objc(cyl_tabBarController:shouldSelectViewController:)
    func cylTabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // FIX: issue #152 — one user tap on a tab button, before the selection changes (also for a tab that needs login).
        // [CN] 一次用户点击 Tab 按钮，在选中变化之前（需要登录的 Tab 也算）。
        cylRecognizeTabBarItemTapWillSelect(viewController)
        // FIX: issue #19 — a tab that needs login, tapped while logged out: refused before anything changes.
        // [CN] 需要登录的 Tab 在未登录时被点击：在任何变化之前拒绝。
        if cyl_interceptLoginIfNeeded(for: viewController) {
            return false
        }
        // [EN] A custom action tab (CYLCustomTabAction): refuse the selection and run the action instead.
        // [CN] 使用自定义点击操作的 Tab（CYLCustomTabAction）：拒绝选中，改为执行对应操作。
        if cyl_performCustomTabActionIfNeeded(for: viewController) {
            return false
        }
        if tabBarStyleType != .flatDesign {
            if viewController.cyl_isPlaceholder {
                return false
            }
            if #available(iOS 18.0, *) {
                cylCrossDissolveTabSwitch(to: viewController)
            }
            updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController)
        }
        return viewController !== tabBarController.selectedViewController
    }

    /**
     * FIX: issue #618
     * [EN] Hides the flash of a tab switch. This runs before the selection is decided: a subclass calls super first and may
     *      still return NO (e.g. a tab that needs login). `+transitionFromView:toView:` removed `fromView` and inserted
     *      `toView` right away, so a refused selection left the selected tab's view out of the hierarchy, and the next tab
     *      switch could crash inside UIKit. A cross-dissolve of the container animates whatever UIKit changes in this run
     *      loop, and does nothing when the selection is refused.
     * [CN] 隐藏 Tab 切换时的闪烁。这里在是否切换确定之前执行：子类会先调用 super，之后仍可能返回 NO（如需要登录的 Tab）。
     *      `+transitionFromView:toView:` 会立即移除 `fromView` 并插入 `toView`，切换被拒绝时当前 Tab 的视图已不在视图层级中，下一次切换 Tab
     *      可能在 UIKit 内部崩溃。对容器做交叉溶解只为本次 runloop 中 UIKit 的视图变化做动画，切换被拒绝时不产生任何变化。
     */
    private func cylCrossDissolveTabSwitch(to viewController: UIViewController) {
        guard let fromView = selectedViewController?.view else {
            return
        }
        let toView: UIView = viewController.view
        guard fromView !== toView else {
            return
        }
        // [EN] Almost immediate. [CN] 几乎立即。
        UIView.transition(with: fromView.superview ?? view, duration: 0.01, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}
